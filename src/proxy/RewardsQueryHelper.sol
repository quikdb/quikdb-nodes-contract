// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "./BaseLogic.sol";
import "../storage/RewardsStorage.sol";
import "../libraries/ValidationLibrary.sol";
import "../libraries/GasOptimizationLibrary.sol";

/**
 * @title RewardsQueryHelper - Read-only contract for reward data retrieval and analytics
 * @dev Handles all complex query, pagination, and analytics operations for rewards
 */
contract RewardsQueryHelper is BaseLogic {
    using ValidationLibrary for address;
    using GasOptimizationLibrary for uint256;

    // Reference to RewardsStorage for data access
    RewardsStorage public rewardsStorage;
    
    // Constants (copied from RewardsLogic for consistency)
    uint256 public constant MAX_DAILY_REWARDS = ValidationLibrary.MAX_DAILY_REWARDS_PER_OPERATOR;
    uint256 public constant MAX_MONTHLY_REWARDS = ValidationLibrary.MAX_MONTHLY_REWARDS_PER_OPERATOR;
    
    // Storage for tracking operator daily/monthly rewards (read from main contract)
    mapping(address => mapping(uint256 => uint256)) public dailyRewards;
    mapping(address => mapping(uint256 => uint256)) public monthlyRewards;

    // Constructor
    constructor() {
        // Empty constructor - use initialize function
    }
    
    /**
     * @dev Initialize the query helper contract
     */
    function initialize(address _rewardsStorage) external {
        require(_rewardsStorage != address(0), "Invalid rewards storage address");
        rewardsStorage = RewardsStorage(_rewardsStorage);
    }

    // =============================================================================
    // REWARD HISTORY AND PAGINATION
    // =============================================================================

    /**
     * @dev Get reward history with pagination support
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
        ValidationLibrary.validateAddress(nodeOperator);
        
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
     * @dev Paginated reward history with gas optimization
     */
    function getRewardHistoryPaginated(
        address nodeOperator,
        uint256 offset,
        uint256 limit
    ) external view returns (
        bytes32[] memory rewardIds,
        uint256[] memory amounts,
        uint256[] memory distributionDates,
        uint8[] memory rewardTypes,
        bool[] memory distributedFlags,
        uint256 totalCount,
        bool hasMore
    ) {
        ValidationLibrary.validateAddress(nodeOperator);
        
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

    // =============================================================================
    // BATCH RECORD OPERATIONS
    // =============================================================================

    /**
     * @dev Batch get reward records for multiple reward IDs
     */
    function batchGetRewardRecords(bytes32[] calldata rewardIds) external view returns (
        RewardsStorage.RewardRecord[] memory records
    ) {
        require(rewardIds.length > 0, "No reward IDs provided");
        require(rewardIds.length <= 50, "Too many reward IDs (max 50)");
        
        records = new RewardsStorage.RewardRecord[](rewardIds.length);
        
        for (uint256 i = 0; i < rewardIds.length; i++) {
            records[i] = rewardsStorage.getRewardRecord(rewardIds[i]);
        }
    }

    /**
     * @dev Batch get reward records for multiple operators with pagination
     */
    function batchGetOperatorRewards(
        address[] calldata operators,
        uint256 offset,
        uint256 limit
    ) external view returns (
        address[] memory operatorAddresses,
        bytes32[][] memory rewardIds,
        uint256[] memory totalCounts
    ) {
        require(operators.length > 0, "No operators provided");
        require(operators.length <= 10, "Too many operators (max 10)");
        
        operatorAddresses = new address[](operators.length);
        rewardIds = new bytes32[][](operators.length);
        totalCounts = new uint256[](operators.length);
        
        for (uint256 i = 0; i < operators.length; i++) {
            ValidationLibrary.validateAddress(operators[i]);
            operatorAddresses[i] = operators[i];
            
            // Get paginated reward IDs for this operator
            rewardIds[i] = rewardsStorage.getOperatorRewardHistory(operators[i], offset, limit);
            
            // Get total count (for pagination info)
            bytes32[] memory allIds = rewardsStorage.getOperatorRewardHistory(operators[i], 0, type(uint256).max);
            totalCounts[i] = allIds.length;
        }
    }

    // =============================================================================
    // DAILY AND MONTHLY ANALYTICS
    // =============================================================================

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
     * @dev Get daily rewards for multiple days for an operator
     */
    function getDailyRewardsBatch(address operator, uint256[] calldata daysList) external view returns (uint256[] memory rewards) {
        ValidationLibrary.validateAddress(operator);
        require(daysList.length <= 31, "Too many days (max 31)");
        
        rewards = new uint256[](daysList.length);
        for (uint256 i = 0; i < daysList.length; i++) {
            rewards[i] = dailyRewards[operator][daysList[i]];
        }
    }

    /**
     * @dev Get monthly rewards for multiple months for an operator
     */
    function getMonthlyRewardsBatch(address operator, uint256[] calldata months) external view returns (uint256[] memory rewards) {
        ValidationLibrary.validateAddress(operator);
        require(months.length <= 12, "Too many months (max 12)");
        
        rewards = new uint256[](months.length);
        for (uint256 i = 0; i < months.length; i++) {
            rewards[i] = monthlyRewards[operator][months[i]];
        }
    }

    // =============================================================================
    // CAPACITY AND PERIOD ANALYTICS
    // =============================================================================

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
     * @dev Get capacity information for multiple operators
     */
    function getBatchCapacityInfo(address[] calldata operators) external view returns (
        address[] memory operatorAddresses,
        uint256[] memory dailyCapacities,
        uint256[] memory monthlyCapacities,
        uint256[] memory dailyUsed,
        uint256[] memory monthlyUsed
    ) {
        require(operators.length > 0, "No operators provided");
        require(operators.length <= 20, "Too many operators (max 20)");
        
        uint256 currentDay = block.timestamp / 1 days;
        uint256 currentMonth = block.timestamp / 30 days;
        
        operatorAddresses = new address[](operators.length);
        dailyCapacities = new uint256[](operators.length);
        monthlyCapacities = new uint256[](operators.length);
        dailyUsed = new uint256[](operators.length);
        monthlyUsed = new uint256[](operators.length);
        
        for (uint256 i = 0; i < operators.length; i++) {
            ValidationLibrary.validateAddress(operators[i]);
            operatorAddresses[i] = operators[i];
            
            uint256 dailyUsedAmount = dailyRewards[operators[i]][currentDay];
            uint256 monthlyUsedAmount = monthlyRewards[operators[i]][currentMonth];
            
            dailyUsed[i] = dailyUsedAmount;
            monthlyUsed[i] = monthlyUsedAmount;
            dailyCapacities[i] = dailyUsedAmount >= MAX_DAILY_REWARDS ? 0 : MAX_DAILY_REWARDS - dailyUsedAmount;
            monthlyCapacities[i] = monthlyUsedAmount >= MAX_MONTHLY_REWARDS ? 0 : MAX_MONTHLY_REWARDS - monthlyUsedAmount;
        }
    }

    // =============================================================================
    // COMPREHENSIVE ANALYTICS
    // =============================================================================

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
     * @dev Get operator performance summary
     */
    function getOperatorSummary(address operator) external view returns (
        uint256 totalRewards,
        uint256 totalSlashed,
        uint256 rewardCount,
        uint256 lastRewardTime,
        uint256 currentDayUsed,
        uint256 currentMonthUsed,
        uint256 dailyCapacityRemaining,
        uint256 monthlyCapacityRemaining
    ) {
        ValidationLibrary.validateAddress(operator);
        
        // Get basic totals
        totalRewards = rewardsStorage.operatorTotalRewards(operator);
        totalSlashed = rewardsStorage.operatorTotalSlashed(operator);
        lastRewardTime = rewardsStorage.operatorLastRewardTime(operator);
        
        // Get reward count
        bytes32[] memory allRewards = rewardsStorage.getOperatorRewardHistory(operator, 0, type(uint256).max);
        rewardCount = allRewards.length;
        
        // Get current period usage
        uint256 currentDay = block.timestamp / 1 days;
        uint256 currentMonth = block.timestamp / 30 days;
        currentDayUsed = dailyRewards[operator][currentDay];
        currentMonthUsed = monthlyRewards[operator][currentMonth];
        
        // Calculate remaining capacities
        dailyCapacityRemaining = currentDayUsed >= MAX_DAILY_REWARDS ? 0 : MAX_DAILY_REWARDS - currentDayUsed;
        monthlyCapacityRemaining = currentMonthUsed >= MAX_MONTHLY_REWARDS ? 0 : MAX_MONTHLY_REWARDS - currentMonthUsed;
    }

    /**
     * @dev Get historical usage analytics for an operator
     */
    function getOperatorHistoricalUsage(
        address operator,
        uint256 dayStart,
        uint256 dayEnd
    ) external view returns (
        uint256[] memory daysList,
        uint256[] memory dailyAmounts,
        uint256 totalAmount,
        uint256 averageDaily
    ) {
        ValidationLibrary.validateAddress(operator);
        require(dayStart <= dayEnd, "Invalid day range");
        require(dayEnd - dayStart <= 365, "Range too large (max 365 days)");
        
        uint256 dayCount = dayEnd - dayStart + 1;
        daysList = new uint256[](dayCount);
        dailyAmounts = new uint256[](dayCount);
        
        for (uint256 i = 0; i < dayCount; i++) {
            uint256 day = dayStart + i;
            daysList[i] = day;
            dailyAmounts[i] = dailyRewards[operator][day];
            totalAmount += dailyAmounts[i];
        }
        
        averageDaily = dayCount > 0 ? totalAmount / dayCount : 0;
    }

    // =============================================================================
    // UTILITY FUNCTIONS
    // =============================================================================

    /**
     * @dev Update daily/monthly reward tracking (called by main RewardsLogic contract)
     */
    function updateRewardTracking(
        address operator,
        uint256 amount,
        uint256 day,
        uint256 month
    ) external {
        // Only allow the main RewardsLogic contract to call this
        // This would need to be implemented with proper access control
        dailyRewards[operator][day] += amount;
        monthlyRewards[operator][month] += amount;
    }

    /**
     * @dev Get contract name for identification
     */
    function _getContractName() internal pure override returns (string memory) {
        return "RewardsQueryHelper";
    }
}
