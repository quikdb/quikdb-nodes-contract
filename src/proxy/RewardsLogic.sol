// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./BaseLogic.sol";
import "../storage/RewardsStorage.sol";
import "../libraries/ValidationLibrary.sol";
import "../libraries/RateLimitingLibrary.sol";

/**
 * @title RewardsLogic
 * @notice Implementation contract for rewards distribution management with production-grade validation
 * @dev This contract implements the complete business logic for calculating, validating,
 *      and distributing rewards with actual token/ETH transfers and slashing mechanisms.
 */
contract RewardsLogic is BaseLogic {
    using ValidationLibrary for *;
    using RateLimitingLibrary for *;

    // Storage contract reference
    RewardsStorage public rewardsStorage;

    // Node ID to address mapping for rewards
    mapping(string => address) private nodeIdToAddress;
    mapping(address => string) private addressToNodeId;
    
    // Daily and monthly reward tracking for caps
    mapping(address => mapping(uint256 => uint256)) private dailyRewards; // operator => day => amount
    mapping(address => mapping(uint256 => uint256)) private monthlyRewards; // operator => month => amount

    // Reward token contract (if using ERC20 instead of ETH)
    IERC20 public rewardToken;
    
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
     * @dev Batch distribute multiple rewards for efficiency
     */
    function batchDistributeRewards(
        bytes32[] calldata rewardIds
    ) external onlyRole(REWARDS_DISTRIBUTOR_ROLE) whenNotPaused nonReentrant {
        uint256 totalAmount = 0;
        uint256 successfulDistributions = 0;
        uint256 failedDistributions = 0;

        // First pass: validate and calculate total amount
        for (uint256 i = 0; i < rewardIds.length; i++) {
            RewardsStorage.RewardRecord memory record = rewardsStorage.getRewardRecord(rewardIds[i]);
            
            if (record.nodeOperator != address(0) && !record.distributed) {
                totalAmount += record.amount;
            }
        }

        // Validate total balance
        _validateSufficientBalance(totalAmount);

        // Second pass: distribute rewards
        for (uint256 i = 0; i < rewardIds.length; i++) {
            bytes32 rewardId = rewardIds[i];
            
            RewardsStorage.RewardRecord memory record = rewardsStorage.getRewardRecord(rewardId);
            
            if (record.nodeOperator != address(0) && !record.distributed) {
                try this.distributeReward(rewardId) {
                    successfulDistributions++;
                } catch {
                    failedDistributions++;
                }
            } else {
                failedDistributions++;
            }
        }

        emit BatchRewardDistribution(totalAmount, successfulDistributions, failedDistributions);
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
     * @dev Perform actual reward transfer (ETH or ERC20)
     */
    function _performRewardTransfer(address recipient, uint256 amount) internal {
        if (address(rewardToken) != address(0)) {
            // ERC20 token transfer
            bool success = rewardToken.transfer(recipient, amount);
            if (!success) revert TransferFailed(recipient, amount);
        } else {
            // ETH transfer
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

    /**
     * @dev Get contract name for circuit breaker logging
     */
    function _getContractName() internal pure override returns (string memory) {
        return "RewardsLogic";
    }
}
