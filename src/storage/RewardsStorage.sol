// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

/**
 * @title RewardsStorage
 * @dev Storage contract for rewards distribution system
 * Contains only storage layout and structs - no logic functions
 */
contract RewardsStorage {
    /**
     * @dev Reward record structure
     */
    struct RewardRecord {
        address nodeOperator;
        uint256 amount;
        uint256 distributionDate;
        uint8 rewardType;
        bool distributed;
    }

    // Storage mappings
    mapping(bytes32 => RewardRecord) public rewardRecords;
    mapping(address => uint256) public operatorTotalRewards;
    uint256 public totalDistributed;

    // Events
    event RewardDistributed(
        bytes32 indexed rewardId,
        address indexed nodeOperator,
        uint256 amount,
        uint8 rewardType,
        uint256 distributionDate
    );

    event RewardCalculated(
        bytes32 indexed rewardId,
        address indexed nodeOperator,
        uint256 amount,
        uint8 rewardType
    );
}
