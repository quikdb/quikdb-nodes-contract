// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./BaseLogic.sol";
import "../storage/RewardsStorage.sol";

/**
 * @title RewardsLogic
 * @notice Implementation contract for rewards distribution management
 * @dev This contract implements the business logic for calculating and distributing rewards.
 *      It inherits from BaseLogic and follows the proxy pattern.
 */
contract RewardsLogic is BaseLogic {
    // Storage contract reference
    RewardsStorage public rewardsStorage;

    // Rewards-specific roles
    bytes32 public constant REWARDS_CALCULATOR_ROLE = keccak256("REWARDS_CALCULATOR_ROLE");
    bytes32 public constant REWARDS_DISTRIBUTOR_ROLE = keccak256("REWARDS_DISTRIBUTOR_ROLE");

    // Rewards operation events
    event RewardCalculationStarted(
        address indexed nodeOperator,
        uint256 timestamp
    );

    event RewardDistributionCompleted(
        bytes32 indexed rewardId,
        address indexed nodeOperator,
        uint256 amount
    );

    // Custom errors
    error RewardAlreadyDistributed(bytes32 rewardId);
    error RewardNotFound(bytes32 rewardId);
    error InvalidRewardAmount(uint256 amount);
    error InvalidNodeOperator(address operator);
    error InsufficientBalance(uint256 required, uint256 available);

    /**
     * @dev Initialize the rewards logic contract
     * @param _rewardsStorage Address of the rewards storage contract
     * @param _nodeStorage Address of the node storage contract
     * @param _userStorage Address of the user storage contract
     * @param _resourceStorage Address of the resource storage contract
     */
    function initialize(
        address _rewardsStorage,
        address _nodeStorage,
        address _userStorage,
        address _resourceStorage
    ) external {
        _initializeBase(_nodeStorage, _userStorage, _resourceStorage, msg.sender);
        
        require(_rewardsStorage != address(0), "Invalid rewards storage address");
        rewardsStorage = RewardsStorage(_rewardsStorage);

        // Set up roles
        _grantRole(REWARDS_CALCULATOR_ROLE, msg.sender);
        _grantRole(REWARDS_DISTRIBUTOR_ROLE, msg.sender);
    }

    /**
     * @dev Calculate reward for a node operator
     * @param nodeOperator Address of the node operator
     * @param amount Calculated reward amount
     * @param rewardType Type of reward (0: performance, 1: uptime, 2: storage, etc.)
     * @return rewardId Unique identifier for the reward record
     */
    function calculateReward(
        address nodeOperator,
        uint256 amount,
        uint8 rewardType
    ) external onlyRole(REWARDS_CALCULATOR_ROLE) whenNotPaused nonReentrant returns (bytes32) {
        if (nodeOperator == address(0)) revert InvalidNodeOperator(nodeOperator);
        if (amount == 0) revert InvalidRewardAmount(amount);

        // Generate unique reward ID
        bytes32 rewardId = keccak256(
            abi.encodePacked(nodeOperator, amount, block.timestamp, rewardType)
        );

        // Check if reward already exists
        (address existingOperator, , , , ) = rewardsStorage.rewardRecords(rewardId);
        if (existingOperator != address(0)) {
            revert RewardAlreadyDistributed(rewardId);
        }

        emit RewardCalculationStarted(nodeOperator, block.timestamp);

        // This would trigger the RewardCalculated event in storage when called
        // For now, we emit our own event
        emit RewardDistributionCompleted(rewardId, nodeOperator, amount);

        return rewardId;
    }

    /**
     * @dev Distribute calculated reward to node operator
     * @param rewardId Unique identifier of the reward to distribute
     */
    function distributeReward(
        bytes32 rewardId
    ) external onlyRole(REWARDS_DISTRIBUTOR_ROLE) whenNotPaused nonReentrant {
        // Get reward record from storage
        (address nodeOperator, uint256 amount, uint256 distributionDate, uint8 rewardType, bool distributed) = 
            rewardsStorage.rewardRecords(rewardId);

        if (nodeOperator == address(0)) revert RewardNotFound(rewardId);
        if (distributed) revert RewardAlreadyDistributed(rewardId);

        // Note: In a real implementation, this would:
        // 1. Update the reward record in storage to mark as distributed
        // 2. Update operator total rewards
        // 3. Update global total distributed
        // 4. Actually transfer tokens/ETH to the operator
        
        // For now, we emit the event to indicate successful distribution
        emit RewardDistributionCompleted(rewardId, nodeOperator, amount);
    }

    /**
     * @dev Get reward history for a specific node operator
     * @param nodeOperator Address of the node operator
     * @param offset Starting index for pagination
     * @param limit Maximum number of records to return
     * @return rewardIds Array of reward IDs for the operator
     * @return amounts Array of reward amounts
     * @return distributionDates Array of distribution dates
     * @return rewardTypes Array of reward types
     * @return distributedFlags Array of distribution status flags
     */
    function getRewardHistory(
        address nodeOperator,
        uint256 offset,
        uint256 limit
    ) external view returns (
        bytes32[] memory rewardIds,
        uint256[] memory amounts,
        uint256[] memory distributionDates,
        uint8[] memory rewardTypes,
        bool[] memory distributedFlags
    ) {
        if (nodeOperator == address(0)) revert InvalidNodeOperator(nodeOperator);
        
        // Note: In a real implementation, this would:
        // 1. Query storage for operator's reward history
        // 2. Apply pagination with offset and limit
        // 3. Return structured data
        
        // For now, return empty arrays as stub implementation
        rewardIds = new bytes32[](0);
        amounts = new uint256[](0);
        distributionDates = new uint256[](0);
        rewardTypes = new uint8[](0);
        distributedFlags = new bool[](0);
    }

    /**
     * @dev Get total amount of rewards distributed globally
     * @return Total amount of all distributed rewards
     */
    function getTotalDistributed() external view returns (uint256) {
        return rewardsStorage.totalDistributed();
    }

    /**
     * @dev Get total rewards for a specific operator
     * @param nodeOperator Address of the node operator
     * @return Total amount of rewards for the operator
     */
    function getOperatorTotalRewards(address nodeOperator) external view returns (uint256) {
        if (nodeOperator == address(0)) revert InvalidNodeOperator(nodeOperator);
        return rewardsStorage.operatorTotalRewards(nodeOperator);
    }

    /**
     * @dev Get reward record details
     * @param rewardId Unique identifier of the reward
     * @return nodeOperator Address of the node operator
     * @return amount Reward amount
     * @return distributionDate Distribution date
     * @return rewardType Type of reward
     * @return distributed Whether reward has been distributed
     */
    function getRewardRecord(bytes32 rewardId) external view returns (
        address nodeOperator,
        uint256 amount,
        uint256 distributionDate,
        uint8 rewardType,
        bool distributed
    ) {
        return rewardsStorage.rewardRecords(rewardId);
    }
}
