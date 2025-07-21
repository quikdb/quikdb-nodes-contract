// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./BaseLogic.sol";
import "../storage/RewardsStorage.sol";
import "../tokens/QuiksToken.sol";
import "../libraries/ValidationLibrary.sol";
import "../libraries/RateLimitingLibrary.sol";
import "../libraries/GasOptimizationLibrary.sol";

/**
 * @title RewardsLogic
 * @notice Implementation contract for rewards distribution management with production-grade validation
 * @dev This contract implements the complete business logic for calculating, validating,
 *      and distributing rewards with actual token/ETH transfers and slashing mechanisms.
 */
contract RewardsLogic is BaseLogic {
    using ValidationLibrary for *;
    using RateLimitingLibrary for *;
    using GasOptimizationLibrary for *;

    // Storage contract reference
    RewardsStorage public rewardsStorage;

    // Node ID to address mapping for rewards
    mapping(string => address) private nodeIdToAddress;
    mapping(address => string) private addressToNodeId;
    
    // Struct to reduce stack depth in batch operations
    struct BatchRewardParams {
        address[] nodeOperators;
        string[] nodeIds;
        uint256[] baseAmounts;
        uint8[] rewardTypes;
        uint256[] uptimeScores;
        uint256[] performanceScores;
        uint256[] qualityScores;
        string[] periods;
    }
    
    // Daily and monthly reward tracking for caps
    mapping(address => mapping(uint256 => uint256)) private dailyRewards; // operator => day => amount
    mapping(address => mapping(uint256 => uint256)) private monthlyRewards; // operator => month => amount

    // Reward token contract (if using ERC20 instead of ETH)
    IERC20 public rewardToken;
    
    // QuiksToken contract for minting rewards
    QuiksToken public quiksToken;
    
    // Production-grade constants (using ValidationLibrary values)
    uint256 public constant MIN_REWARD_AMOUNT = ValidationLibrary.MIN_REWARD_AMOUNT;
    uint256 public constant MAX_REWARD_AMOUNT = ValidationLibrary.MAX_REWARD_AMOUNT;
    uint256 public constant MAX_DAILY_REWARDS = ValidationLibrary.MAX_DAILY_REWARDS_PER_OPERATOR;
    uint256 public constant MAX_MONTHLY_REWARDS = ValidationLibrary.MAX_MONTHLY_REWARDS_PER_OPERATOR;
    uint256 public constant REWARD_INTERVAL = ValidationLibrary.MIN_REWARD_INTERVAL;
    uint256 public constant SLASHING_THRESHOLD = 70; // Performance below 70% triggers slashing
    uint256 public constant MAX_SLASHING_PERCENTAGE = 50; // Max 50% of pending rewards can be slashed
    
    // Performance weights for reward calculation (must sum to 100)
    uint256 public constant UPTIME_WEIGHT = 40; // 40%
    uint256 public constant PERFORMANCE_WEIGHT = 35; // 35%
    uint256 public constant QUALITY_WEIGHT = 25; // 25%

    // Rewards-specific roles
    bytes32 public constant REWARDS_CALCULATOR_ROLE = keccak256("REWARDS_CALCULATOR_ROLE");
    bytes32 public constant REWARDS_DISTRIBUTOR_ROLE = keccak256("REWARDS_DISTRIBUTOR_ROLE");
    bytes32 public constant SLASHING_ROLE = keccak256("SLASHING_ROLE");

    // Events
    event RewardCalculationStarted(
        address indexed nodeOperator,
        string indexed nodeId,
        uint256 timestamp
    );

    event RewardDistributionCompleted(
        bytes32 indexed rewardId,
        address indexed nodeOperator,
        uint256 amount,
        uint8 rewardType
    );

    event BatchRewardDistribution(
        uint256 totalAmount,
        uint256 successfulDistributions,
        uint256 failedDistributions
    );

    event RewardCalculationBatch(
        uint256 indexed batchId,
        uint256 successfulCalculations,
        uint256 failedCalculations
    );

    event OperatorSlashed(
        address indexed nodeOperator,
        uint256 slashedAmount,
        string reason,
        uint256 timestamp
    );

    event RewardTokenUpdated(
        address indexed oldToken,
        address indexed newToken
    );

    // Custom errors (supplementing ValidationLibrary errors)
    error RewardAlreadyDistributed(bytes32 rewardId);
    error RewardNotFound(bytes32 rewardId);
    error InvalidNodeOperator(address operator);
    error InsufficientBalance(uint256 required, uint256 available);
    error TransferFailed(address recipient, uint256 amount);
    error RewardTooRecent(uint256 lastRewardTime, uint256 interval);
    error SlashingThresholdNotMet(uint256 performance, uint256 threshold);
    error ExcessiveSlashing(uint256 requested, uint256 maximum);
    error DailyRewardLimitExceeded(address operator, uint256 amount);
    error MonthlyRewardLimitExceeded(address operator, uint256 amount);

    // Modifiers
    modifier validNodeOperator(address operator) {
        ValidationLibrary.validateAddress(operator);
        require(nodeStorage.isOperator(operator), "Address is not a node operator");
        _;
    }

    modifier validPerformanceScores(uint256 uptime, uint256 performance, uint256 quality) {
        ValidationLibrary.validatePerformanceScore(uptime);
        ValidationLibrary.validatePerformanceScore(performance);
        ValidationLibrary.validatePerformanceScore(quality);
        _;
    }

    /**
     * @dev Initialize the rewards logic contract
     */
    function initialize(
        address _rewardsStorage,
        address _nodeStorage,
        address _userStorage,
        address _resourceStorage,
        address _rewardToken
    ) external {
        _initializeBase(_nodeStorage, _userStorage, _resourceStorage, msg.sender);
        
        require(_rewardsStorage != address(0), "Invalid rewards storage address");
        rewardsStorage = RewardsStorage(_rewardsStorage);

        if (_rewardToken != address(0)) {
            // First try to set as QuiksToken
            quiksToken = QuiksToken(_rewardToken);
            
            // Also set as regular ERC20 for compatibility
            rewardToken = IERC20(_rewardToken);
        }

        // Set up roles
        _grantRole(REWARDS_CALCULATOR_ROLE, msg.sender);
        _grantRole(REWARDS_DISTRIBUTOR_ROLE, msg.sender);
        _grantRole(SLASHING_ROLE, msg.sender);
    }

    /**
     * @dev Calculate reward for a node operator with comprehensive production validation
     */
    function calculateReward(
        address nodeOperator,
        string calldata nodeId,
        uint256 baseAmount,
        uint8 rewardType,
        uint256 uptimeScore,
        uint256 performanceScore,
        uint256 qualityScore,
        string calldata period
    ) external 
        onlyRole(REWARDS_CALCULATOR_ROLE) 
        whenNotPaused 
        nonReentrant 
        rateLimit("calculateReward", RateLimitingLibrary.MAX_REWARD_DISTRIBUTIONS_PER_MINUTE, RateLimitingLibrary.MINUTE_WINDOW)
        circuitBreakerCheck("rewardCalculation")
        emergencyPauseCheck("RewardsLogic")
        returns (bytes32) 
    {
        // === PRODUCTION VALIDATION ===
        
        // Validate node operator address
        ValidationLibrary.validateAddress(nodeOperator);
        
        // Validate node ID format
        ValidationLibrary.validateId(nodeId);
        
        // Validate period string
        ValidationLibrary.validateStringLength(period, 1, ValidationLibrary.MAX_DESCRIPTION_LENGTH);
        
        // Validate performance scores (0-100 range)
        ValidationLibrary.validatePerformanceScore(uptimeScore);
        ValidationLibrary.validatePerformanceScore(performanceScore);
        ValidationLibrary.validatePerformanceScore(qualityScore);
        
        // Validate reward type (0-5 for enum values)
        ValidationLibrary.validateUint8(rewardType);
        require(rewardType <= 5, "Invalid reward type");
        
        // Validate base reward amount
        ValidationLibrary.validateRewardAmount(baseAmount);
        
        // === BUSINESS LOGIC VALIDATION ===
        
        // Validate node exists and is active
        require(nodeStorage.doesNodeExist(nodeId), "Node does not exist");
        NodeStorage.NodeInfo memory nodeInfo = nodeStorage.getNodeInfo(nodeId);
        require(
            nodeInfo.status == NodeStorage.NodeStatus.ACTIVE || 
            nodeInfo.status == NodeStorage.NodeStatus.LISTED,
            "Node is not active"
        );

        // Check minimum time between rewards
        uint256 lastRewardTime = rewardsStorage.operatorLastRewardTime(nodeOperator);
        if (block.timestamp < lastRewardTime + REWARD_INTERVAL) {
            revert RewardTooRecent(lastRewardTime, REWARD_INTERVAL);
        }

        // Calculate performance-based reward adjustment
        uint256 adjustedAmount = _calculatePerformanceAdjustedReward(
            baseAmount,
            uptimeScore,
            performanceScore,
            qualityScore
        );

        // Validate adjusted amount is still within bounds
        ValidationLibrary.validateRewardAmount(adjustedAmount);
        
        // === DAILY AND MONTHLY REWARD CAP VALIDATION ===
        
        uint256 currentDay = block.timestamp / 1 days;
        uint256 currentMonth = block.timestamp / 30 days;
        
        // Check daily reward limits
        uint256 todayRewards = dailyRewards[nodeOperator][currentDay];
        if (todayRewards + adjustedAmount > MAX_DAILY_REWARDS) {
            revert DailyRewardLimitExceeded(nodeOperator, adjustedAmount);
        }
        
        // Check monthly reward limits
        uint256 monthlyRewardAmount = monthlyRewards[nodeOperator][currentMonth];
        if (monthlyRewardAmount + adjustedAmount > MAX_MONTHLY_REWARDS) {
            revert MonthlyRewardLimitExceeded(nodeOperator, adjustedAmount);
        }
        
        // Update reward tracking
        dailyRewards[nodeOperator][currentDay] = todayRewards + adjustedAmount;
        monthlyRewards[nodeOperator][currentMonth] = monthlyRewardAmount + adjustedAmount;

        // Final validation for minimum threshold
        if (adjustedAmount < MIN_REWARD_AMOUNT) {
            revert ValidationLibrary.InvalidRewardAmount(adjustedAmount);
        }

        // Generate unique reward ID
        bytes32 rewardId = keccak256(
            abi.encodePacked(
                nodeOperator,
                nodeId,
                adjustedAmount,
                block.timestamp,
                rewardType,
                period
            )
        );

        // Create reward record in storage
        RewardsStorage.RewardRecord memory newRecord = RewardsStorage.RewardRecord({
            nodeOperator: nodeOperator,
            amount: adjustedAmount,
            distributionDate: 0, // Not distributed yet
            rewardType: rewardType,
            distributed: false,
            calculatedAt: block.timestamp,
            uptimeScore: uptimeScore,
            performanceScore: performanceScore,
            qualityScore: qualityScore,
            nodeId: nodeId,
            period: period
        });

        rewardsStorage.storeRewardRecord(rewardId, newRecord);

        // Update node mapping
        if (nodeIdToAddress[nodeId] == address(0)) {
            nodeIdToAddress[nodeId] = nodeOperator;
            addressToNodeId[nodeOperator] = nodeId;
        }

        emit RewardCalculationStarted(nodeOperator, nodeId, block.timestamp);
        return rewardId;
    }

    /**
     * @dev Distribute calculated reward with actual token/ETH transfer
     */
    function distributeReward(
        bytes32 rewardId
    ) external 
        onlyRole(REWARDS_DISTRIBUTOR_ROLE) 
        whenNotPaused 
        nonReentrant 
        rateLimit("distributeReward", RateLimitingLibrary.MAX_REWARD_DISTRIBUTIONS_PER_MINUTE, RateLimitingLibrary.MINUTE_WINDOW)
        circuitBreakerCheck("rewardDistribution")
        emergencyPauseCheck("RewardsLogic") {
        // Get reward record from storage
        RewardsStorage.RewardRecord memory record = rewardsStorage.getRewardRecord(rewardId);

        if (record.nodeOperator == address(0)) revert RewardNotFound(rewardId);
        if (record.distributed) revert RewardAlreadyDistributed(rewardId);

        // Validate sufficient balance for distribution
        _validateSufficientBalance(record.amount);

        // Perform actual transfer
        _performRewardTransfer(record.nodeOperator, record.amount);

        // Update storage to mark as distributed
        rewardsStorage.updateRewardDistribution(rewardId, true);

        emit RewardDistributionCompleted(rewardId, record.nodeOperator, record.amount, record.rewardType);
    }

    /**
     * @dev Gas-optimized batch distribute multiple rewards
     */
    function batchDistributeRewards(
        bytes32[] calldata rewardIds
    ) external 
        onlyRole(REWARDS_DISTRIBUTOR_ROLE) 
        whenNotPaused 
        nonReentrant 
        rateLimit("batchDistributeRewards", RateLimitingLibrary.MAX_REWARD_DISTRIBUTIONS_PER_MINUTE * 10, RateLimitingLibrary.MINUTE_WINDOW)
        circuitBreakerCheck("batchRewardDistribution")
        emergencyPauseCheck("RewardsLogic")
    {
        uint256 batchSize = rewardIds.length;
        
        // Validate batch operation
        GasOptimizationLibrary.validateBatchOperation(batchSize);
        
        // Generate batch ID for tracking
        uint256 batchId = GasOptimizationLibrary.generateBatchId(msg.sender, block.timestamp, batchSize);
        
        uint256 totalAmount = 0;
        uint256 successfulDistributions = 0;
        uint256 failedDistributions = 0;

        // Pre-allocate arrays for gas efficiency
        address[] memory operators = GasOptimizationLibrary.allocateAddressArray(batchSize);
        uint256[] memory amounts = new uint256[](batchSize);
        bool[] memory validRecords = new bool[](batchSize);

        // First pass: validate and calculate total amount (gas optimized)
        for (uint256 i = 0; i < batchSize; i++) {
            try rewardsStorage.getRewardRecord(rewardIds[i]) returns (RewardsStorage.RewardRecord memory record) {
                if (record.nodeOperator != address(0) && !record.distributed) {
                    operators[i] = record.nodeOperator;
                    amounts[i] = record.amount;
                    validRecords[i] = true;
                    totalAmount += record.amount;
                } else {
                    validRecords[i] = false;
                    failedDistributions++;
                }
            } catch {
                validRecords[i] = false;
                failedDistributions++;
            }
        }

        // Validate total balance once
        _validateSufficientBalance(totalAmount);

        // Second pass: distribute rewards (gas optimized)
        for (uint256 i = 0; i < batchSize; i++) {
            if (validRecords[i]) {
                try this._distributeSingleReward(rewardIds[i], operators[i], amounts[i]) {
                    successfulDistributions++;
                } catch {
                    failedDistributions++;
                }
            }
        }

        // Emit optimized batch event
        GasOptimizationLibrary.emitBatchEvent(batchId, successfulDistributions, totalAmount, "reward");
        
        emit BatchRewardDistribution(totalAmount, successfulDistributions, failedDistributions);
        
        // Require at least some distributions succeeded
        require(successfulDistributions > 0, "Batch distribution failed completely");
    }

    /**
     * @dev Internal function for single reward distribution (used by batch)
     */
    function _distributeSingleReward(bytes32 rewardId, address operator, uint256 amount) external {
        require(msg.sender == address(this), "Internal function only");
        
        // Perform actual transfer
        _performRewardTransfer(operator, amount);
        
        // Update storage to mark as distributed
        rewardsStorage.updateRewardDistribution(rewardId, true);
    }

    /**
     * @dev Batch calculate multiple rewards for gas efficiency
     */
    function batchCalculateRewards(
        BatchRewardParams calldata params
    ) external 
        onlyRole(REWARDS_CALCULATOR_ROLE) 
        whenNotPaused 
        nonReentrant 
        rateLimit("batchCalculateRewards", RateLimitingLibrary.MAX_REWARD_DISTRIBUTIONS_PER_MINUTE * 5, RateLimitingLibrary.MINUTE_WINDOW)
        circuitBreakerCheck("batchRewardCalculation")
        emergencyPauseCheck("RewardsLogic")
        returns (bytes32[] memory rewardIds) 
    {
        uint256 batchSize = params.nodeOperators.length;
        
        // Validate batch operation and array lengths
        GasOptimizationLibrary.validateBatchOperation(batchSize);
        require(
            params.nodeIds.length == batchSize &&
            params.baseAmounts.length == batchSize &&
            params.rewardTypes.length == batchSize &&
            params.uptimeScores.length == batchSize &&
            params.performanceScores.length == batchSize &&
            params.qualityScores.length == batchSize &&
            params.periods.length == batchSize,
            "Array length mismatch"
        );
        
        // Generate batch ID for tracking
        uint256 batchId = GasOptimizationLibrary.generateBatchId(msg.sender, block.timestamp, batchSize);
        
        rewardIds = new bytes32[](batchSize);
        uint256 successfulCalculations = 0;
        
        // Process each reward calculation
        for (uint256 i = 0; i < batchSize; i++) {
            try this._calculateSingleReward(
                params.nodeOperators[i],
                params.nodeIds[i],
                params.baseAmounts[i],
                params.rewardTypes[i],
                params.uptimeScores[i],
                params.performanceScores[i],
                params.qualityScores[i],
                params.periods[i]
            ) returns (bytes32 rewardId) {
                rewardIds[i] = rewardId;
                successfulCalculations++;
            } catch {
                rewardIds[i] = bytes32(0);
                // Continue with next calculation on failure
                continue;
            }
        }
        
        // Emit batch calculation event
        emit RewardCalculationBatch(batchId, successfulCalculations, batchSize - successfulCalculations);
        
        require(successfulCalculations > 0, "Batch calculation failed completely");
    }

    /**
     * @dev Internal function for single reward calculation (used by batch)
     */
    function _calculateSingleReward(
        address nodeOperator,
        string calldata nodeId,
        uint256 baseAmount,
        uint8 rewardType,
        uint256 uptimeScore,
        uint256 performanceScore,
        uint256 qualityScore,
        string calldata period
    ) external returns (bytes32) {
        require(msg.sender == address(this), "Internal function only");
        
        // Reuse existing calculation logic with minimal validation
        return _performRewardCalculation(
            nodeOperator,
            nodeId,
            baseAmount,
            rewardType,
            uptimeScore,
            performanceScore,
            qualityScore,
            period
        );
    }

    /**
     * @dev Apply slashing for poor performance
     */
    function slashOperator(
        address nodeOperator,
        uint256 slashAmount,
        string calldata reason,
        uint256 uptimeScore,
        uint256 performanceScore,
        uint256 qualityScore
    ) external 
        onlyRole(SLASHING_ROLE) 
        whenNotPaused 
        nonReentrant 
        validNodeOperator(nodeOperator)
        validPerformanceScores(uptimeScore, performanceScore, qualityScore)
    {
        // Calculate overall performance score
        uint256 overallScore = _calculateOverallPerformance(uptimeScore, performanceScore, qualityScore);
        
        if (overallScore >= SLASHING_THRESHOLD) {
            revert SlashingThresholdNotMet(overallScore, SLASHING_THRESHOLD);
        }

        // Validate slashing amount against operator's pending rewards
        uint256 operatorTotal = rewardsStorage.operatorTotalRewards(nodeOperator);
        uint256 maxSlashing = (operatorTotal * MAX_SLASHING_PERCENTAGE) / 100;
        
        if (slashAmount > maxSlashing) {
            revert ExcessiveSlashing(slashAmount, maxSlashing);
        }

        // Apply slashing in storage
        rewardsStorage.slashOperator(nodeOperator, slashAmount, reason);

        // Update performance metrics
        rewardsStorage.updatePerformanceMetrics(
            nodeOperator,
            0, // totalJobs - would be updated separately
            0, // successfulJobs - would be updated separately  
            0, // failedJobs - would be updated separately
            0, // avgResponseTime - would be updated separately
            uptimeScore
        );

        emit OperatorSlashed(nodeOperator, slashAmount, reason, block.timestamp);
    }

    /**
     * @dev Get reward history with pagination support
     */
    function getRewardHistory(
        address nodeOperator,
        uint256 offset,
        uint256 limit
    ) external view validNodeOperator(nodeOperator) returns (
        bytes32[] memory rewardIds,
        uint256[] memory amounts,
        uint256[] memory distributionDates,
        uint8[] memory rewardTypes,
        bool[] memory distributedFlags
    ) {
        // Get paginated reward IDs from storage
        bytes32[] memory paginatedIds = rewardsStorage.getOperatorRewardHistory(
            nodeOperator,
            offset,
            limit
        );

        uint256 length = paginatedIds.length;
        
        // Initialize return arrays
        rewardIds = new bytes32[](length);
        amounts = new uint256[](length);
        distributionDates = new uint256[](length);
        rewardTypes = new uint8[](length);
        distributedFlags = new bool[](length);

        // Populate arrays with reward data
        for (uint256 i = 0; i < length; i++) {
            bytes32 rewardId = paginatedIds[i];
            rewardIds[i] = rewardId;
            
            RewardsStorage.RewardRecord memory record = rewardsStorage.getRewardRecord(rewardId);
            
            amounts[i] = record.amount;
            distributionDates[i] = record.distributionDate;
            rewardTypes[i] = record.rewardType;
            distributedFlags[i] = record.distributed;
        }
    }

    /**
     * @dev Get node-specific reward history
     */
    function getNodeRewardHistory(
        string calldata nodeId,
        uint256 offset,
        uint256 limit
    ) external view returns (bytes32[] memory rewardIds) {
        return rewardsStorage.getNodeRewardHistory(nodeId, offset, limit);
    }

    /**
     * @dev Set reward token for ERC20 distributions
     */
    function setRewardToken(address _rewardToken) external onlyRole(ADMIN_ROLE) {
        address oldToken = address(rewardToken);
        rewardToken = IERC20(_rewardToken);
        emit RewardTokenUpdated(oldToken, _rewardToken);
    }

    /**
     * @dev Get comprehensive reward statistics
     */
    function getRewardStats() external view returns (
        uint256 totalDistributed,
        uint256 totalSlashed,
        uint256 totalRewards,
        uint256 pendingRewards
    ) {
        return rewardsStorage.getGlobalStats();
    }

    /**
     * @dev Withdraw contract balance (admin only)
     */
    function withdrawBalance(address recipient, uint256 amount) external onlyRole(ADMIN_ROLE) {
        require(recipient != address(0), "Invalid recipient");
        
        if (address(rewardToken) != address(0)) {
            require(rewardToken.transfer(recipient, amount), "Token transfer failed");
        } else {
            require(address(this).balance >= amount, "Insufficient balance");
            (bool success, ) = recipient.call{value: amount}("");
            require(success, "ETH transfer failed");
        }
    }

    // =============================================================================
    // INTERNAL HELPER FUNCTIONS
    // =============================================================================

    /**
     * @dev Calculate performance-adjusted reward amount
     */
    function _calculatePerformanceAdjustedReward(
        uint256 baseAmount,
        uint256 uptimeScore,
        uint256 performanceScore,
        uint256 qualityScore
    ) internal pure returns (uint256) {
        uint256 overallScore = _calculateOverallPerformance(uptimeScore, performanceScore, qualityScore);
        return (baseAmount * overallScore) / 100;
    }

    /**
     * @dev Calculate overall performance score with weights
     */
    function _calculateOverallPerformance(
        uint256 uptimeScore,
        uint256 performanceScore,
        uint256 qualityScore
    ) internal pure returns (uint256) {
        return (
            (uptimeScore * UPTIME_WEIGHT) +
            (performanceScore * PERFORMANCE_WEIGHT) +
            (qualityScore * QUALITY_WEIGHT)
        ) / 100;
    }

    /**
     * @dev Validate sufficient balance for reward distribution
     */
    function _validateSufficientBalance(uint256 amount) internal view {
        // Skip balance validation for QUIKS token since we mint new tokens
        if (address(quiksToken) != address(0)) {
            return;
        }
        
        uint256 available;
        
        if (address(rewardToken) != address(0)) {
            available = rewardToken.balanceOf(address(this));
        } else {
            available = address(this).balance;
        }
        
        if (available < amount) {
            revert InsufficientBalance(amount, available);
        }
    }

    /**
     * @dev Perform actual reward transfer (ETH, ERC20, or mint QUIKS)
     */
    function _performRewardTransfer(address recipient, uint256 amount) internal {
        if (address(quiksToken) != address(0)) {
            // Mint QUIKS tokens as reward
            try quiksToken.mintRewards(
                recipient, 
                amount, 
                "Node operator performance reward"
            ) {
                // Minting successful
            } catch {
                revert TransferFailed(recipient, amount);
            }
        } else if (address(rewardToken) != address(0)) {
            // ERC20 token transfer (fallback)
            bool success = rewardToken.transfer(recipient, amount);
            if (!success) revert TransferFailed(recipient, amount);
        } else {
            // ETH transfer (legacy fallback)
            (bool success, ) = recipient.call{value: amount}("");
            if (!success) revert TransferFailed(recipient, amount);
        }
    }

    /**
     * @dev Set node address mapping for nodeId resolution with validation
     */
    function setNodeMapping(string calldata nodeId, address nodeAddress) external onlyRole(ADMIN_ROLE) {
        ValidationLibrary.validateId(nodeId);
        ValidationLibrary.validateAddress(nodeAddress);
        
        nodeIdToAddress[nodeId] = nodeAddress;
        addressToNodeId[nodeAddress] = nodeId;
    }
    
    /**
     * @dev Get daily reward amount for an operator
     */
    function getDailyRewards(address operator, uint256 day) external view returns (uint256) {
        ValidationLibrary.validateAddress(operator);
        return dailyRewards[operator][day];
    }
    
    /**
     * @dev Get monthly reward amount for an operator
     */
    function getMonthlyRewards(address operator, uint256 month) external view returns (uint256) {
        ValidationLibrary.validateAddress(operator);
        return monthlyRewards[operator][month];
    }
    
    /**
     * @dev Get current day and month for reward tracking
     */
    function getCurrentRewardPeriods() external view returns (uint256 currentDay, uint256 currentMonth) {
        currentDay = block.timestamp / 1 days;
        currentMonth = block.timestamp / 30 days;
    }
    
    /**
     * @dev Get remaining daily reward capacity for an operator
     */
    function getRemainingDailyCapacity(address operator) external view returns (uint256) {
        ValidationLibrary.validateAddress(operator);
        uint256 currentDay = block.timestamp / 1 days;
        uint256 used = dailyRewards[operator][currentDay];
        return used >= MAX_DAILY_REWARDS ? 0 : MAX_DAILY_REWARDS - used;
    }
    
    /**
     * @dev Get remaining monthly reward capacity for an operator
     */
    function getRemainingMonthlyCapacity(address operator) external view returns (uint256) {
        ValidationLibrary.validateAddress(operator);
        uint256 currentMonth = block.timestamp / 30 days;
        uint256 used = monthlyRewards[operator][currentMonth];
        return used >= MAX_MONTHLY_REWARDS ? 0 : MAX_MONTHLY_REWARDS - used;
    }

    // =============================================================================
    // BATCH OPERATIONS AND PAGINATED QUERIES
    // =============================================================================

    /**
     * @dev Paginated reward history with gas optimization
     */
    function getRewardHistoryPaginated(
        address nodeOperator,
        uint256 offset,
        uint256 limit
    ) external validNodeOperator(nodeOperator) returns (
        bytes32[] memory rewardIds,
        uint256[] memory amounts,
        uint256[] memory distributionDates,
        uint8[] memory rewardTypes,
        bool[] memory distributedFlags,
        uint256 totalCount,
        bool hasMore
    ) {
        // Get all reward IDs for the operator
        bytes32[] memory allRewardIds = rewardsStorage.getOperatorRewardHistory(nodeOperator, 0, type(uint256).max);
        totalCount = allRewardIds.length;
        
        // Validate and adjust pagination
        uint256 adjustedLimit = GasOptimizationLibrary.validatePagination(offset, limit, totalCount);
        
        if (offset >= totalCount) {
            return (new bytes32[](0), new uint256[](0), new uint256[](0), new uint8[](0), new bool[](0), totalCount, false);
        }
        
        // Calculate actual length for this page
        uint256 pageLength = offset + adjustedLimit > totalCount ? totalCount - offset : adjustedLimit;
        
        // Pre-allocate arrays for gas efficiency
        rewardIds = new bytes32[](pageLength);
        amounts = new uint256[](pageLength);
        distributionDates = new uint256[](pageLength);
        rewardTypes = new uint8[](pageLength);
        distributedFlags = new bool[](pageLength);
        
        // Populate arrays efficiently
        for (uint256 i = 0; i < pageLength; i++) {
            bytes32 rewardId = allRewardIds[offset + i];
            rewardIds[i] = rewardId;
            
            RewardsStorage.RewardRecord memory record = rewardsStorage.getRewardRecord(rewardId);
            amounts[i] = record.amount;
            distributionDates[i] = record.distributionDate;
            rewardTypes[i] = record.rewardType;
            distributedFlags[i] = record.distributed;
        }
        
        hasMore = (offset + pageLength) < totalCount;
        
        // Emit pagination event for off-chain indexing
        emit GasOptimizationLibrary.PaginatedQuery(msg.sender, "getRewardHistory", offset, pageLength, totalCount);
    }

    /**
     * @dev Batch get reward records for gas efficiency
     */
    function batchGetRewardRecords(bytes32[] calldata rewardIds)
        external
        view
        returns (RewardsStorage.RewardRecord[] memory records)
    {
        uint256 length = rewardIds.length;
        GasOptimizationLibrary.checkArrayLength(length, 100); // Max 100 records per batch
        
        records = new RewardsStorage.RewardRecord[](length);
        
        for (uint256 i = 0; i < length; i++) {
            try rewardsStorage.getRewardRecord(rewardIds[i]) returns (RewardsStorage.RewardRecord memory record) {
                records[i] = record;
            } catch {
                // Return empty record for non-existent rewards
                records[i] = RewardsStorage.RewardRecord({
                    nodeOperator: address(0),
                    amount: 0,
                    distributionDate: 0,
                    rewardType: 0,
                    distributed: false,
                    calculatedAt: 0,
                    uptimeScore: 0,
                    performanceScore: 0,
                    qualityScore: 0,
                    nodeId: "",
                    period: ""
                });
            }
        }
    }

    // =============================================================================
    // INTERNAL HELPER FUNCTIONS (EXTRACTED FOR REUSE)
    // =============================================================================

    /**
     * @dev Internal reward calculation function (extracted for batch operations)
     */
    function _performRewardCalculation(
        address nodeOperator,
        string calldata nodeId,
        uint256 baseAmount,
        uint8 rewardType,
        uint256 uptimeScore,
        uint256 performanceScore,
        uint256 qualityScore,
        string calldata period
    ) internal returns (bytes32) {
        // Calculate performance-based reward adjustment
        uint256 adjustedAmount = _calculatePerformanceAdjustedReward(
            baseAmount,
            uptimeScore,
            performanceScore,
            qualityScore
        );

        // Validate adjusted amount
        ValidationLibrary.validateRewardAmount(adjustedAmount);
        
        // Check daily and monthly limits
        uint256 currentDay = block.timestamp / 1 days;
        uint256 currentMonth = block.timestamp / 30 days;
        
        uint256 todayRewards = dailyRewards[nodeOperator][currentDay];
        if (todayRewards + adjustedAmount > MAX_DAILY_REWARDS) {
            revert DailyRewardLimitExceeded(nodeOperator, adjustedAmount);
        }
        
        uint256 monthlyRewardAmount = monthlyRewards[nodeOperator][currentMonth];
        if (monthlyRewardAmount + adjustedAmount > MAX_MONTHLY_REWARDS) {
            revert MonthlyRewardLimitExceeded(nodeOperator, adjustedAmount);
        }
        
        // Update reward tracking
        dailyRewards[nodeOperator][currentDay] = todayRewards + adjustedAmount;
        monthlyRewards[nodeOperator][currentMonth] = monthlyRewardAmount + adjustedAmount;

        // Generate unique reward ID
        bytes32 rewardId = keccak256(
            abi.encodePacked(
                nodeOperator,
                nodeId,
                adjustedAmount,
                block.timestamp,
                rewardType,
                period
            )
        );

        // Create reward record
        RewardsStorage.RewardRecord memory newRecord = RewardsStorage.RewardRecord({
            nodeOperator: nodeOperator,
            amount: adjustedAmount,
            distributionDate: 0,
            rewardType: rewardType,
            distributed: false,
            calculatedAt: block.timestamp,
            uptimeScore: uptimeScore,
            performanceScore: performanceScore,
            qualityScore: qualityScore,
            nodeId: nodeId,
            period: period
        });

        rewardsStorage.storeRewardRecord(rewardId, newRecord);

        return rewardId;
    }

    /**
     * @dev Get contract name for circuit breaker logging
     */
    function _getContractName() internal pure override returns (string memory) {
        return "RewardsLogic";
    }
}
