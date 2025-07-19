// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./BaseTest.sol";

/**
 * @title RewardsLogicTest
 * @notice Test suite for RewardsLogic contract functionality
 */
contract RewardsLogicTest is BaseTest {
    
    function testRewardsLogic_CalculateReward() public {
        vm.startPrank(rewardsCalculator);
        
        bytes32 rewardId = rewardsLogic.calculateReward(
            nodeOperator,
            1000, // 1000 wei reward
            0     // Performance reward type
        );
        
        assertTrue(rewardId != bytes32(0), "Reward ID should be generated");
        vm.stopPrank();
    }
    
    function testRewardsLogic_CalculateReward_OnlyAuthorized() public {
        vm.startPrank(user); // Unauthorized user
        
        vm.expectRevert();
        rewardsLogic.calculateReward(
            nodeOperator,
            1000,
            0
        );
        
        vm.stopPrank();
    }
    
    function testRewardsLogic_CalculateReward_InvalidOperator() public {
        vm.startPrank(rewardsCalculator);
        
        vm.expectRevert();
        rewardsLogic.calculateReward(
            address(0), // Invalid operator
            1000,
            0
        );
        
        vm.stopPrank();
    }
    
    function testRewardsLogic_CalculateReward_InvalidAmount() public {
        vm.startPrank(rewardsCalculator);
        
        vm.expectRevert();
        rewardsLogic.calculateReward(
            nodeOperator,
            0, // Invalid amount
            0
        );
        
        vm.stopPrank();
    }
    
    function testRewardsLogic_GetTotalDistributed() public view {
        uint256 total = rewardsLogic.getTotalDistributed();
        // Should return 0 initially (from storage)
        assertEq(total, 0, "Initial total distributed should be 0");
    }
    
    function testRewardsLogic_GetOperatorTotalRewards() public view {
        uint256 total = rewardsLogic.getOperatorTotalRewards(nodeOperator);
        // Should return 0 initially (from storage)
        assertEq(total, 0, "Initial operator total should be 0");
    }
    
    function testRewardsLogic_GetOperatorTotalRewards_InvalidOperator() public {
        vm.expectRevert();
        rewardsLogic.getOperatorTotalRewards(address(0));
    }
    
    function testRewardsLogic_GetRewardHistory() public view {
        (
            bytes32[] memory rewardIds,
            uint256[] memory amounts,
            uint256[] memory distributionDates,
            uint8[] memory rewardTypes,
            bool[] memory distributedFlags
        ) = rewardsLogic.getRewardHistory(nodeOperator, 0, 10);
        
        // Should return empty arrays initially (stub implementation)
        assertEq(rewardIds.length, 0, "Should return empty reward IDs");
        assertEq(amounts.length, 0, "Should return empty amounts");
        assertEq(distributionDates.length, 0, "Should return empty dates");
        assertEq(rewardTypes.length, 0, "Should return empty types");
        assertEq(distributedFlags.length, 0, "Should return empty flags");
    }
    
    function testRewardsLogic_GetRewardHistory_InvalidOperator() public {
        vm.expectRevert();
        rewardsLogic.getRewardHistory(address(0), 0, 10);
    }
}
