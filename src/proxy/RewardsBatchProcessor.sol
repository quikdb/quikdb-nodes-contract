// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./BaseLogic.sol";
import "./RewardsLogic.sol";
import "../storage/RewardsStorage.sol";
import "../libraries/ValidationLibrary.sol";
import "../libraries/RateLimitingLibrary.sol";
import "../libraries/GasOptimizationLibrary.sol";

/**
 * @title RewardsBatchProcessor
 * @notice Handles all batch operations for rewards distribution and calculation
 * @dev Extracted from RewardsLogic to reduce contract size and improve modularity
 */
contract RewardsBatchProcessor is BaseLogic {
    using ValidationLibrary for *;
    using RateLimitingLibrary for *;
    using GasOptimizationLibrary for *;

    // Reference to main RewardsLogic contract
    RewardsLogic public rewardsLogic;
    
    // Reference to RewardsStorage
    RewardsStorage public rewardsStorage;

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

    // Batch operation roles
    bytes32 public constant BATCH_PROCESSOR_ROLE = keccak256("BATCH_PROCESSOR_ROLE");
    bytes32 public constant REWARDS_CALCULATOR_ROLE = keccak256("REWARDS_CALCULATOR_ROLE");
    bytes32 public constant REWARDS_DISTRIBUTOR_ROLE = keccak256("REWARDS_DISTRIBUTOR_ROLE");

    // Events
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

    // Custom errors
    error InvalidRewardsLogicAddress(address provided);
    error BatchOperationFailed(uint256 batchId);
    error ArrayLengthMismatch(string paramName);

    /**
     * @dev Initialize the batch processor
     */
    function initialize(
        address _rewardsLogic,
        address _rewardsStorage,
        address _nodeStorage,
        address _userStorage,
        address _resourceStorage
    ) external {
        require(_rewardsLogic != address(0), "Invalid RewardsLogic address");
        require(_rewardsStorage != address(0), "Invalid RewardsStorage address");
        
        _initializeBase(_nodeStorage, _userStorage, _resourceStorage, msg.sender);
        
        rewardsLogic = RewardsLogic(payable(_rewardsLogic));
        rewardsStorage = RewardsStorage(_rewardsStorage);

        // Set up roles
        _grantRole(BATCH_PROCESSOR_ROLE, msg.sender);
        _grantRole(REWARDS_CALCULATOR_ROLE, msg.sender);
        _grantRole(REWARDS_DISTRIBUTOR_ROLE, msg.sender);
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
        emergencyPauseCheck("RewardsBatchProcessor")
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

        // Validate total balance through RewardsLogic
        _validateSufficientBalanceWithRewardsLogic(totalAmount);

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
        
        // Delegate to RewardsLogic for actual transfer
        try rewardsLogic.distributeReward(rewardId) {
            // Distribution successful
        } catch {
            revert("Distribution failed");
        }
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
        emergencyPauseCheck("RewardsBatchProcessor")
        returns (bytes32[] memory rewardIds) 
    {
        uint256 batchSize = params.nodeOperators.length;
        
        // Validate batch operation and array lengths
        GasOptimizationLibrary.validateBatchOperation(batchSize);
        _validateBatchArrayLengths(params, batchSize);
        
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
        
        // Delegate to RewardsLogic for calculation
        return rewardsLogic.calculateReward(
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

    /**
     * @dev Update RewardsLogic reference (admin only)
     */
    function setRewardsLogic(address _rewardsLogic) external onlyRole(ADMIN_ROLE) {
        require(_rewardsLogic != address(0), "Invalid address");
        rewardsLogic = RewardsLogic(payable(_rewardsLogic));
    }

    /**
     * @dev Update RewardsStorage reference (admin only)
     */
    function setRewardsStorage(address _rewardsStorage) external onlyRole(ADMIN_ROLE) {
        require(_rewardsStorage != address(0), "Invalid address");
        rewardsStorage = RewardsStorage(_rewardsStorage);
    }

    // =============================================================================
    // INTERNAL HELPER FUNCTIONS
    // =============================================================================

    /**
     * @dev Validate batch array lengths match
     */
    function _validateBatchArrayLengths(BatchRewardParams calldata params, uint256 expectedLength) internal pure {
        if (params.nodeIds.length != expectedLength) revert ArrayLengthMismatch("nodeIds");
        if (params.baseAmounts.length != expectedLength) revert ArrayLengthMismatch("baseAmounts");
        if (params.rewardTypes.length != expectedLength) revert ArrayLengthMismatch("rewardTypes");
        if (params.uptimeScores.length != expectedLength) revert ArrayLengthMismatch("uptimeScores");
        if (params.performanceScores.length != expectedLength) revert ArrayLengthMismatch("performanceScores");
        if (params.qualityScores.length != expectedLength) revert ArrayLengthMismatch("qualityScores");
        if (params.periods.length != expectedLength) revert ArrayLengthMismatch("periods");
    }

    /**
     * @dev Validate sufficient balance through RewardsLogic
     */
    function _validateSufficientBalanceWithRewardsLogic(uint256 amount) internal view {
        // We don't have direct access to balance validation, so we assume RewardsLogic will handle it
        // This is a simplified validation for the batch processor
        require(amount > 0, "Invalid total amount");
    }

    /**
     * @dev Get contract name for circuit breaker logging
     */
    function _getContractName() internal pure override returns (string memory) {
        return "RewardsBatchProcessor";
    }
}
