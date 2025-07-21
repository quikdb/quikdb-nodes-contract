// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title RewardsStorage
 * @dev Storage contract for rewards distribution system
 * Contains storage layout, structs, and essential storage management functions
 */
contract RewardsStorage is AccessControl {
    bytes32 public constant LOGIC_ROLE = keccak256("LOGIC_ROLE");

    /**
     * @dev Reward record structure
     */
    struct RewardRecord {
        address nodeOperator;
        uint256 amount;
        uint256 distributionDate;
        uint8 rewardType;
        bool distributed;
        uint256 calculatedAt;
        uint256 uptimeScore;
        uint256 performanceScore;
        uint256 qualityScore;
        string nodeId;
        string period;
    }

    /**
     * @dev Performance metrics for slashing calculations
     */
    struct PerformanceMetrics {
        uint256 totalJobs;
        uint256 successfulJobs;
        uint256 failedJobs;
        uint256 avgResponseTime;
        uint256 uptimePercentage;
        uint256 lastSlashTime;
        uint256 totalSlashed;
    }

    // Storage mappings
    mapping(bytes32 => RewardRecord) public rewardRecords;
    mapping(address => uint256) public operatorTotalRewards;
    mapping(address => uint256) public operatorTotalSlashed;
    mapping(address => PerformanceMetrics) public operatorPerformance;
    mapping(address => bytes32[]) public operatorRewardHistory;
    mapping(string => bytes32[]) public nodeRewardHistory;
    mapping(address => uint256) public operatorLastRewardTime;
    
    // Global statistics
    uint256 public totalDistributed;
    uint256 public totalSlashed;
    uint256 public totalRewards;
    uint256 public pendingRewards;

    // Reward type enumeration
    enum RewardType {
        PERFORMANCE,
        UPTIME,
        STORAGE_PROVIDED,
        COMPUTATION,
        NETWORK_CONTRIBUTION,
        BONUS
    }

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

    event RewardSlashed(
        address indexed nodeOperator,
        uint256 amount,
        string reason,
        uint256 timestamp
    );

    event PerformanceUpdated(
        address indexed nodeOperator,
        uint256 uptimePercentage,
        uint256 successfulJobs,
        uint256 totalJobs
    );

    modifier onlyLogic() {
        require(hasRole(LOGIC_ROLE, msg.sender), "Only logic contract");
        _;
    }

    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    /**
     * @dev Set the logic contract address
     */
    function setLogicContract(address logicContract) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(LOGIC_ROLE, logicContract);
    }

    /**
     * @dev Create a new reward record
     */
    function createReward(
        bytes32 rewardId,
        address nodeOperator,
        uint256 amount,
        uint8 rewardType,
        string calldata nodeId,
        string calldata period,
        uint256 uptimeScore,
        uint256 performanceScore,
        uint256 qualityScore
    ) external onlyLogic {
        require(rewardRecords[rewardId].nodeOperator == address(0), "Reward already exists");
        
        rewardRecords[rewardId] = RewardRecord({
            nodeOperator: nodeOperator,
            amount: amount,
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

        operatorRewardHistory[nodeOperator].push(rewardId);
        nodeRewardHistory[nodeId].push(rewardId);
        pendingRewards += amount;
        totalRewards += amount;

        emit RewardCalculated(rewardId, nodeOperator, amount, rewardType);
    }

    /**
     * @dev Mark reward as distributed and update totals
     */
    function distributeReward(bytes32 rewardId) external onlyLogic {
        RewardRecord storage reward = rewardRecords[rewardId];
        require(reward.nodeOperator != address(0), "Reward not found");
        require(!reward.distributed, "Reward already distributed");

        reward.distributed = true;
        reward.distributionDate = block.timestamp;

        operatorTotalRewards[reward.nodeOperator] += reward.amount;
        operatorLastRewardTime[reward.nodeOperator] = block.timestamp;
        totalDistributed += reward.amount;
        pendingRewards -= reward.amount;

        emit RewardDistributed(
            rewardId,
            reward.nodeOperator,
            reward.amount,
            reward.rewardType,
            block.timestamp
        );
    }

    /**
     * @dev Update operator performance metrics
     */
    function updatePerformanceMetrics(
        address nodeOperator,
        uint256 totalJobs,
        uint256 successfulJobs,
        uint256 failedJobs,
        uint256 avgResponseTime,
        uint256 uptimePercentage
    ) external onlyLogic {
        PerformanceMetrics storage metrics = operatorPerformance[nodeOperator];
        metrics.totalJobs = totalJobs;
        metrics.successfulJobs = successfulJobs;
        metrics.failedJobs = failedJobs;
        metrics.avgResponseTime = avgResponseTime;
        metrics.uptimePercentage = uptimePercentage;

        emit PerformanceUpdated(nodeOperator, uptimePercentage, successfulJobs, totalJobs);
    }

    /**
     * @dev Apply slashing to operator
     */
    function slashOperator(
        address nodeOperator,
        uint256 amount,
        string calldata reason
    ) external onlyLogic {
        operatorTotalSlashed[nodeOperator] += amount;
        operatorPerformance[nodeOperator].totalSlashed += amount;
        operatorPerformance[nodeOperator].lastSlashTime = block.timestamp;
        totalSlashed += amount;

        emit RewardSlashed(nodeOperator, amount, reason, block.timestamp);
    }

    /**
     * @dev Get operator reward history with pagination
     */
    function getOperatorRewardHistory(
        address nodeOperator,
        uint256 offset,
        uint256 limit
    ) external view returns (bytes32[] memory rewardIds) {
        bytes32[] storage allRewards = operatorRewardHistory[nodeOperator];
        
        if (offset >= allRewards.length) {
            return new bytes32[](0);
        }
        
        uint256 end = offset + limit;
        if (end > allRewards.length) {
            end = allRewards.length;
        }
        
        uint256 length = end - offset;
        rewardIds = new bytes32[](length);
        
        for (uint256 i = 0; i < length; i++) {
            rewardIds[i] = allRewards[offset + i];
        }
    }

    /**
     * @dev Get node reward history with pagination
     */
    function getNodeRewardHistory(
        string calldata nodeId,
        uint256 offset,
        uint256 limit
    ) external view returns (bytes32[] memory rewardIds) {
        bytes32[] storage allRewards = nodeRewardHistory[nodeId];
        
        if (offset >= allRewards.length) {
            return new bytes32[](0);
        }
        
        uint256 end = offset + limit;
        if (end > allRewards.length) {
            end = allRewards.length;
        }
        
        uint256 length = end - offset;
        rewardIds = new bytes32[](length);
        
        for (uint256 i = 0; i < length; i++) {
            rewardIds[i] = allRewards[offset + i];
        }
    }

    /**
     * @dev Get global reward statistics
     */
    function getGlobalStats() external view returns (
        uint256 _totalDistributed,
        uint256 _totalSlashed,
        uint256 _totalRewards,
        uint256 _pendingRewards
    ) {
        return (totalDistributed, totalSlashed, totalRewards, pendingRewards);
    }

    /**
     * @dev Get reward record details
     */
    function getRewardRecord(bytes32 rewardId) external view returns (RewardRecord memory) {
        return rewardRecords[rewardId];
    }

    /**
     * @dev Store a new reward record
     */
    function storeRewardRecord(bytes32 rewardId, RewardRecord calldata record) external onlyLogic {
        require(rewardRecords[rewardId].nodeOperator == address(0), "Reward record already exists");
        
        rewardRecords[rewardId] = record;
        operatorRewardHistory[record.nodeOperator].push(rewardId);
        nodeRewardHistory[record.nodeId].push(rewardId);
        
        totalRewards += record.amount; // Fix: Add amount instead of just incrementing
        if (!record.distributed) {
            pendingRewards += record.amount;
        }
        
        emit RewardCalculated(rewardId, record.nodeOperator, record.amount, record.rewardType);
    }

    /**
     * @dev Update reward distribution status
     */
    function updateRewardDistribution(bytes32 rewardId, bool distributed) external onlyLogic {
        require(rewardRecords[rewardId].nodeOperator != address(0), "Reward record does not exist");
        require(rewardRecords[rewardId].distributed != distributed, "Status already set");
        
        RewardRecord storage record = rewardRecords[rewardId];
        record.distributed = distributed;
        record.distributionDate = distributed ? block.timestamp : 0;
        
        if (distributed) {
            totalDistributed += record.amount;
            pendingRewards -= record.amount;
            operatorTotalRewards[record.nodeOperator] += record.amount;
            operatorLastRewardTime[record.nodeOperator] = block.timestamp; // Fix: Update last reward time
            emit RewardDistributed(rewardId, record.nodeOperator, record.amount, record.rewardType, block.timestamp);
        } else {
            totalDistributed -= record.amount;
            pendingRewards += record.amount;
            operatorTotalRewards[record.nodeOperator] -= record.amount;
        }
    }

    /**
     * @dev Get operator reward history (without pagination)
     */
    function getOperatorRewardHistory(address operator) external view returns (bytes32[] memory) {
        return operatorRewardHistory[operator];
    }

    /**
     * @dev Update operator total rewards
     */
    function updateOperatorTotalRewards(address operator, uint256 amount) external onlyLogic {
        operatorTotalRewards[operator] += amount;
    }
}
