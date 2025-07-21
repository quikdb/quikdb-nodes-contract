// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "./BaseTest.sol";

/**
 * @title QuiksTokenTest
 * @notice Test suite for QUIKS token functionality
 * @dev Tests the QUIKS token creation, minting, and integration with rewards system
 */
contract QuiksTokenTest is BaseTest {

    address testUser = address(0x123);

    function setUp() public override {
        super.setUp();
        vm.deal(testUser, 10 ether);
    }

    /**
     * @notice Test QUIKS token basic functionality
     */
    function test_QuiksTokenBasicFunctionality() public {
        console.log("=================================================================");
        console.log("QUIKS TOKEN BASIC FUNCTIONALITY TEST");
        console.log("=================================================================");
        
        // Test token information
        (string memory name, string memory symbol, uint8 decimals, uint256 totalSupply) = quiksToken.getTokenInfo();
        console.log("Token name:", name);
        console.log("Token symbol:", symbol);
        console.log("Token decimals:", decimals);
        console.log("Total supply:", totalSupply / 1e18, "QUIKS tokens");
        
        assertEq(name, "QuikDB Token", "Token name should be QuikDB Token");
        assertEq(symbol, "QUIKS", "Token symbol should be QUIKS");
        assertEq(decimals, 18, "Token should have 18 decimals");
        assertEq(totalSupply, 1000000 * 1e18, "Initial supply should be 1 million tokens");
        
        // Test admin balance
        uint256 adminBalance = quiksToken.balanceOf(admin);
        console.log("Admin balance:", adminBalance / 1e18, "QUIKS tokens");
        assertEq(adminBalance, 1000000 * 1e18, "Admin should have initial supply");
        
        console.log("SUCCESS: Basic QUIKS token functionality working");
    }

    /**
     * @notice Test QUIKS token minting for rewards
     */
    function test_QuiksTokenRewardMinting() public {
        console.log("\n=================================================================");
        console.log("QUIKS TOKEN REWARD MINTING TEST");
        console.log("=================================================================");
        
        // Check that RewardsLogic has minter role
        bool canMint = quiksToken.canMint(address(rewardsLogicProxy));
        console.log("RewardsLogic can mint:", canMint);
        assertTrue(canMint, "RewardsLogic should have minter role");
        
        // Test minting rewards through RewardsLogic
        uint256 rewardAmount = 50 * 1e18; // 50 QUIKS tokens
        uint256 initialBalance = quiksToken.balanceOf(testUser);
        console.log("Test user initial balance:", initialBalance / 1e18, "QUIKS tokens");
        
        // Admin calls mintRewards through the proxy (simulating reward distribution)
        vm.prank(admin);
        quiksToken.mintRewards(testUser, rewardAmount, "Node operator performance reward");
        
        uint256 finalBalance = quiksToken.balanceOf(testUser);
        console.log("Test user final balance:", finalBalance / 1e18, "QUIKS tokens");
        console.log("Reward amount minted:", rewardAmount / 1e18, "QUIKS tokens");
        
        assertEq(finalBalance - initialBalance, rewardAmount, "Correct amount should be minted");
        
        // Check total supply increased
        (, , , uint256 newTotalSupply) = quiksToken.getTokenInfo();
        uint256 expectedTotalSupply = 1000000 * 1e18 + rewardAmount;
        console.log("New total supply:", newTotalSupply / 1e18, "QUIKS tokens");
        assertEq(newTotalSupply, expectedTotalSupply, "Total supply should increase by reward amount");
        
        console.log("SUCCESS: QUIKS token reward minting working");
    }

    /**
     * @notice Test QUIKS token integration with RewardsLogic
     */
    function test_QuiksTokenRewardsIntegration() public {
        console.log("\n=================================================================");
        console.log("QUIKS TOKEN REWARDS INTEGRATION TEST");
        console.log("=================================================================");
        
        // Register test user and node
        vm.prank(authService);
        userLogic.registerUser(testUser, keccak256("test-profile"), UserStorage.UserType.PROVIDER);
        
        vm.prank(nodeOperator);
        nodeLogic.registerNode("test-node-001", testUser, NodeStorage.NodeTier.STANDARD, NodeStorage.ProviderType.COMPUTE);
        
        // Activate the node for performance recording
        vm.prank(testUser); // testUser is the node owner
        nodeLogic.updateNodeStatus("test-node-001", NodeStorage.NodeStatus.ACTIVE);
        
        // Fast-forward time to meet reward interval requirements
        vm.warp(block.timestamp + 3601);
        
        // Calculate reward for test user
        uint256 baseAmount = 25 * 1e18; // 25 QUIKS tokens
        uint8 rewardType = 1; // Performance reward
        uint256 uptimeScore = 95;
        uint256 performanceScore = 90;
        uint256 qualityScore = 92;
        string memory period = "2025-07-21";
        
        console.log("Calculating reward for test user...");
        console.log("Base amount:", baseAmount / 1e18, "QUIKS tokens");
        console.log("Performance scores - Uptime: 95%, Performance: 90%, Quality: 92%");
        
        uint256 initialBalance = quiksToken.balanceOf(testUser);
        console.log("Test user initial QUIKS balance:", initialBalance / 1e18, "tokens");
        
        // Admin calculates reward
        vm.prank(admin);
        bytes32 rewardId = rewardsLogic.calculateReward(
            testUser,
            "test-node-001",
            baseAmount,
            rewardType,
            uptimeScore,
            performanceScore,
            qualityScore,
            period
        );
        
        console.log("Reward calculated with ID:", vm.toString(rewardId));
        
        // Fast-forward time again to meet distribution requirements
        vm.warp(block.timestamp + 3601);
        
        // Distribute the reward (this should mint QUIKS tokens)
        vm.prank(admin);
        rewardsLogic.distributeReward(rewardId);
        
        console.log("Reward distributed - QUIKS tokens should be minted");
        
        // Check that tokens were minted to the user
        uint256 finalBalance = quiksToken.balanceOf(testUser);
        console.log("Test user final QUIKS balance:", finalBalance / 1e18, "tokens");
        
        // Calculate expected amount (performance-adjusted)
        uint256 performanceMultiplier = (uptimeScore * 40 + performanceScore * 35 + qualityScore * 25) / 100;
        uint256 expectedAmount = (baseAmount * performanceMultiplier) / 100;
        console.log("Expected reward amount:", expectedAmount / 1e18, "QUIKS tokens");
        console.log("Performance multiplier:", performanceMultiplier, "%");
        
        assertEq(finalBalance - initialBalance, expectedAmount, "Correct performance-adjusted QUIKS amount should be minted");
        
        // Verify reward record
        RewardsStorage.RewardRecord memory record = rewardsStorage.getRewardRecord(rewardId);
        assertTrue(record.distributed, "Reward should be marked as distributed");
        assertEq(record.nodeOperator, testUser, "Reward should be for test user");
        assertEq(record.amount, expectedAmount, "Reward amount should match");
        
        console.log("SUCCESS: QUIKS token fully integrated with rewards system");
        console.log("Economic flow: Performance -> Reward Calculation -> QUIKS Token Minting -> User Balance");
    }

    /**
     * @notice Test QUIKS token total supply management
     */
    function test_QuiksTokenSupplyManagement() public {
        console.log("\n=================================================================");
        console.log("QUIKS TOKEN SUPPLY MANAGEMENT TEST");
        console.log("=================================================================");
        
        // Record initial state
        (, , , uint256 initialSupply) = quiksToken.getTokenInfo();
        console.log("Initial total supply:", initialSupply / 1e18, "QUIKS tokens");
        
        // Mint multiple rewards to simulate network activity
        uint256[] memory rewardAmounts = new uint256[](3);
        rewardAmounts[0] = 10 * 1e18;  // 10 QUIKS
        rewardAmounts[1] = 25 * 1e18;  // 25 QUIKS  
        rewardAmounts[2] = 15 * 1e18;  // 15 QUIKS
        
        address[] memory recipients = new address[](3);
        recipients[0] = address(0x201);
        recipients[1] = address(0x202);
        recipients[2] = address(0x203);
        
        uint256 totalMinted = 0;
        
        console.log("Minting rewards for multiple node operators:");
        for (uint256 i = 0; i < rewardAmounts.length; i++) {
            vm.prank(admin);
            quiksToken.mintRewards(
                recipients[i], 
                rewardAmounts[i], 
                string(abi.encodePacked("Reward for operator ", vm.toString(i + 1)))
            );
            
            totalMinted += rewardAmounts[i];
            console.log("  Operator minted tokens:", rewardAmounts[i] / 1e18);
        }
        
        console.log("Total minted:", totalMinted / 1e18, "QUIKS tokens");
        
        // Check final supply
        (, , , uint256 finalSupply) = quiksToken.getTokenInfo();
        uint256 expectedSupply = initialSupply + totalMinted;
        
        console.log("Final total supply:", finalSupply / 1e18, "QUIKS tokens");
        console.log("Expected supply:", expectedSupply / 1e18, "QUIKS tokens");
        
        assertEq(finalSupply, expectedSupply, "Total supply should increase by total minted amount");
        
        // Verify individual balances
        for (uint256 i = 0; i < recipients.length; i++) {
            uint256 balance = quiksToken.balanceOf(recipients[i]);
            assertEq(balance, rewardAmounts[i], "Each recipient should have correct balance");
            console.log("  Recipient balance:", balance / 1e18);
        }
        
        console.log("SUCCESS: QUIKS token supply management working correctly");
        console.log("Network token economics: Rewards create new tokens -> Healthy inflation for growth");
    }
}
