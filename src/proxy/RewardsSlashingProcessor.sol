// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "./BaseLogic.sol";
import "../storage/RewardsStorage.sol";

contract RewardsSlashingProcessor is BaseLogic {
    address public rewardsLogic;
    
    modifier onlyRewardsLogic() {
        require(msg.sender == rewardsLogic, "Only RewardsLogic can call this");
        _;
    }
    
    constructor() {
        // Empty constructor - use initialize function
    }
    
    function initialize(address _logic, address _facade, address _rewardsLogic) external {
        rewardsLogic = _rewardsLogic;
        // Note: BaseLogic initialization would be handled separately if needed
    }

    // Slash operator rewards for misconduct
    function slashOperator(address operatorId, uint256 amount, string memory reason) external onlyRewardsLogic {
        RewardsStorage rewardsStorage = RewardsStorage(address(this));
        
        // Simple validation - can be enhanced
        require(operatorId != address(0), "Invalid operator address");
        require(amount > 0, "Slash amount must be greater than zero");
        
        // Get current operator total rewards to ensure they exist in the system
        uint256 operatorTotal = rewardsStorage.operatorTotalRewards(operatorId);
        require(operatorTotal > 0, "Operator not found or has no rewards");
        
        uint256 operatorClaimed = rewardsStorage.operatorTotalSlashed(operatorId);
        uint256 availableRewards = operatorTotal - operatorClaimed;
        require(availableRewards >= amount, "Insufficient rewards to slash");
        
        // Apply slashing in storage (the storage contract will handle the internal updates)
        rewardsStorage.slashOperator(operatorId, amount, reason);
        
        emit OperatorSlashed(operatorId, amount, reason, block.timestamp);
    }

    // Batch slash multiple operators
    function batchSlashOperators(
        address[] memory operatorIds,
        uint256[] memory amounts,
        string[] memory reasons
    ) external onlyRewardsLogic {
        require(operatorIds.length == amounts.length, "Array length mismatch");
        require(operatorIds.length == reasons.length, "Array length mismatch");
        require(operatorIds.length > 0, "No operators to slash");
        
        for (uint256 i = 0; i < operatorIds.length; i++) {
            this.slashOperator(operatorIds[i], amounts[i], reasons[i]);
        }
    }

    // Get operator slashing history
    function getOperatorSlashingInfo(address operatorId) external view returns (
        uint256 slashCount,
        uint256 lastSlashTime,
        uint256 totalSlashed
    ) {
        RewardsStorage rewardsStorage = RewardsStorage(address(this));
        
        // Get slashing info from performance metrics
        (,,,,, lastSlashTime, totalSlashed) = rewardsStorage.operatorPerformance(operatorId);
        
        // Calculate slash count (not directly stored, so we approximate)
        slashCount = totalSlashed > 0 ? 1 : 0; // Simplified for now
    }

    // Calculate slashing penalty based on misconduct severity
    function calculateSlashingPenalty(
        address operatorId,
        uint256 severity,
        uint256 baseAmount
    ) external view returns (uint256 penalty) {
        require(severity > 0 && severity <= 10, "Severity must be between 1-10");
        
        RewardsStorage rewardsStorage = RewardsStorage(address(this));
        
        // Get operator's slashing history from performance metrics
        uint256 totalSlashed = rewardsStorage.operatorTotalSlashed(operatorId);
        
        // Calculate penalty multiplier based on severity and history
        uint256 severityMultiplier = severity * 10; // 10% per severity point
        uint256 historyMultiplier = totalSlashed > 0 ? 5 : 0; // 5% if previously slashed
        uint256 totalMultiplier = severityMultiplier + historyMultiplier;
        
        // Cap at 100% (full amount)
        if (totalMultiplier > 100) {
            totalMultiplier = 100;
        }
        
        penalty = (baseAmount * totalMultiplier) / 100;
        
        // Ensure minimum penalty of 1% for any misconduct
        if (penalty == 0 && baseAmount > 0) {
            penalty = baseAmount / 100;
        }
    }

    // Check if operator is eligible for rewards (not recently slashed)
    function isOperatorEligibleForRewards(address operatorId) external view returns (bool eligible) {
        RewardsStorage rewardsStorage = RewardsStorage(address(this));
        
        // Get slashing info from performance metrics
        (,,,,, uint256 lastSlashTime,) = rewardsStorage.operatorPerformance(operatorId);
        
        // If never slashed, always eligible
        if (lastSlashTime == 0) {
            return true;
        }
        
        // Must wait 24 hours after last slash before being eligible again
        uint256 cooldownPeriod = 24 * 60 * 60; // 24 hours
        eligible = (block.timestamp - lastSlashTime) >= cooldownPeriod;
    }

    // Get global slashing statistics
    function getGlobalSlashingStats() external view returns (
        uint256 totalSlashed,
        uint256 totalOperatorsSlashed,
        uint256 averageSlashAmount
    ) {
        RewardsStorage rewardsStorage = RewardsStorage(address(this));
        
        (, totalSlashed, ,) = rewardsStorage.getGlobalStats();
        
        // Note: For simplicity, we're not tracking totalOperatorsSlashed and averageSlashAmount
        // These could be added to storage if needed
        totalOperatorsSlashed = 0;
        averageSlashAmount = 0;
    }

    // Events
    event OperatorSlashed(address indexed operatorId, uint256 amount, string reason, uint256 timestamp);
}
