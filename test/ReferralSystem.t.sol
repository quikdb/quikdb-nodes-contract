// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/ReferralSystem.sol";
import "../src/UserNodeRegistry.sol";
import "../src/tokens/QuiksToken.sol";
import "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/**
 * @title ReferralSystemTest
 * @notice Comprehensive test suite for ReferralSystem contract
 */
contract ReferralSystemTest is Test {
    ReferralSystem public referralSystem;
    UserNodeRegistry public userRegistry;
    QuiksToken public quiksToken;
    
    address public owner = address(1);
    address public referrer = address(2);
    address public referee1 = address(3);
    address public referee2 = address(4);
    address public referee3 = address(5);
    
    // Events to test
    event ReferralCodeGenerated(address indexed referrer, bytes32 indexed code, uint256 timestamp);
    event ReferralRegistered(address indexed referee, address indexed referrer, bytes32 indexed referralCode, uint256 timestamp);
    event ReferralVerified(address indexed referee, address indexed referrer, bytes32 indexed referralCode, uint256 tier);
    event RewardDistributed(address indexed referrer, address indexed referee, uint256 amount, uint256 tier, uint256 timestamp);
    
    function setUp() public {
        // Deploy UserNodeRegistry
        UserNodeRegistry userRegistryImpl = new UserNodeRegistry();
        ERC1967Proxy userRegistryProxy = new ERC1967Proxy(
            address(userRegistryImpl),
            abi.encodeWithSelector(UserNodeRegistry.initialize.selector, owner)
        );
        userRegistry = UserNodeRegistry(address(userRegistryProxy));
        
        // Deploy QuiksToken
        QuiksToken quiksTokenImpl = new QuiksToken();
        ERC1967Proxy quiksTokenProxy = new ERC1967Proxy(
            address(quiksTokenImpl),
            abi.encodeWithSelector(
                QuiksToken.initialize.selector,
                "Quiks Token",
                "QUIKS",
                1000000 ether, // 1M initial supply
                owner
            )
        );
        quiksToken = QuiksToken(address(quiksTokenProxy));
        
        // Deploy ReferralSystem
        ReferralSystem referralSystemImpl = new ReferralSystem();
        ERC1967Proxy referralSystemProxy = new ERC1967Proxy(
            address(referralSystemImpl),
            abi.encodeWithSelector(
                ReferralSystem.initialize.selector,
                address(userRegistry),
                address(quiksToken),
                owner
            )
        );
        referralSystem = ReferralSystem(address(referralSystemProxy));
        
        // Fund ReferralSystem with QUIKS tokens
        vm.startPrank(owner);
        quiksToken.approve(address(referralSystem), 100000 ether);
        referralSystem.fundRewards(100000 ether); // 100k QUIKS for rewards
        vm.stopPrank();
        
        // Register users in UserNodeRegistry
        _registerUser(referrer, UserNodeRegistry.UserType.PROVIDER);
        _registerUser(referee1, UserNodeRegistry.UserType.CONSUMER);
        _registerUser(referee2, UserNodeRegistry.UserType.CONSUMER);
        _registerUser(referee3, UserNodeRegistry.UserType.CONSUMER);
    }
    
    function _registerUser(address user, UserNodeRegistry.UserType userType) internal {
        vm.prank(owner);
        userRegistry.registerUser(user, bytes32(uint256(uint160(user))), userType);
    }
    

    
    // ═══════════════════════════════════════════════════════════════
    // REFERRAL CODE GENERATION TESTS
    // ═══════════════════════════════════════════════════════════════
    
    function testGenerateReferralCode() public {
        vm.startPrank(referrer);
        
        vm.expectEmit(true, false, false, false);
        emit ReferralCodeGenerated(referrer, bytes32(0), block.timestamp);
        
        bytes32 code = referralSystem.generateReferralCode();
        
        assertTrue(code != bytes32(0), "Code should not be zero");
        assertEq(referralSystem.getUserReferralCode(referrer), code, "User code should match");
        assertEq(referralSystem.totalReferralCodes(), 1, "Total codes should be 1");
        
        vm.stopPrank();
    }
    
    function testCannotGenerateDuplicateCode() public {
        vm.startPrank(referrer);
        
        referralSystem.generateReferralCode();
        
        vm.expectRevert("User already has referral code");
        referralSystem.generateReferralCode();
        
        vm.stopPrank();
    }
    
    function testCannotGenerateCodeIfNotRegistered() public {
        address unregistered = address(999);
        
        vm.prank(unregistered);
        vm.expectRevert("User not registered");
        referralSystem.generateReferralCode();
    }
    
    // ═══════════════════════════════════════════════════════════════
    // REFERRAL APPLICATION TESTS
    // ═══════════════════════════════════════════════════════════════
    
    function testApplyReferralCode() public {
        // Generate code
        vm.prank(referrer);
        bytes32 code = referralSystem.generateReferralCode();
        
        // Apply code (owner-only function)
        vm.expectEmit(true, true, true, false);
        emit ReferralRegistered(referee1, referrer, code, block.timestamp);
        
        vm.prank(owner);
        referralSystem.applyReferralCode(referee1, code);
        
        assertTrue(referralSystem.hasBeenReferred(referee1), "Referee should be marked as referred");
        assertEq(referralSystem.referredBy(referee1), code, "Referral code should match");
        // Note: totalSuccessfulReferrals only increments after verification + reward distribution
        assertEq(referralSystem.totalSuccessfulReferrals(), 0, "Total referrals should be 0 until verified");
    }
    
    function testCannotApplyInvalidCode() public {
        bytes32 invalidCode = bytes32(uint256(12345));
        
        vm.prank(owner);
        vm.expectRevert("Referral code not active");
        referralSystem.applyReferralCode(referee1, invalidCode);
    }
    
    function testCannotApplyCodeTwice() public {
        vm.prank(referrer);
        bytes32 code = referralSystem.generateReferralCode();
        
        vm.prank(owner);
        referralSystem.applyReferralCode(referee1, code);
        
        vm.expectRevert("User already referred");
        vm.prank(owner);
        referralSystem.applyReferralCode(referee1, code);
    }
    
    function testCannotReferSelf() public {
        vm.prank(referrer);
        bytes32 code = referralSystem.generateReferralCode();
        
        vm.expectRevert("Cannot refer yourself");
        vm.prank(owner);
        referralSystem.applyReferralCode(referrer, code);
    }
    
    // ═══════════════════════════════════════════════════════════════
    // REFERRAL VERIFICATION TESTS
    // ═══════════════════════════════════════════════════════════════
    
    function testVerifyReferral() public {
        // Setup referral
        vm.prank(referrer);
        bytes32 code = referralSystem.generateReferralCode();
        
        vm.prank(owner);
        referralSystem.applyReferralCode(referee1, code);
        
        // Fast forward past verification delay
        vm.warp(block.timestamp + 8 days);
        
        // Verify
        uint256 referrerBalanceBefore = quiksToken.balanceOf(referrer);
        
        vm.expectEmit(true, true, true, false);
        emit ReferralVerified(referee1, referrer, code, 1);
        
        vm.expectEmit(true, true, false, false);
        emit RewardDistributed(referrer, referee1, 10 ether, 1, block.timestamp);
        
        vm.prank(owner);
        referralSystem.verifyReferral(referee1);
        
        uint256 referrerBalanceAfter = quiksToken.balanceOf(referrer);
        assertEq(referrerBalanceAfter - referrerBalanceBefore, 10 ether, "Should receive tier 1 reward");
    }
    
    function testCannotVerifyBeforeDelay() public {
        vm.prank(referrer);
        bytes32 code = referralSystem.generateReferralCode();
        
        vm.prank(owner);
        referralSystem.applyReferralCode(referee1, code);
        
        // Try to verify immediately
        vm.expectRevert("Verification delay not met");
        vm.prank(owner);
        referralSystem.verifyReferral(referee1);
    }
    
    function testRewardTierProgression() public {
        vm.prank(referrer);
        bytes32 code = referralSystem.generateReferralCode();
        
        address[] memory referees = new address[](25);
        for (uint i = 0; i < 25; i++) {
            referees[i] = address(uint160(1000 + i));
            _registerUser(referees[i], UserNodeRegistry.UserType.CONSUMER);
            
            vm.prank(owner);
            referralSystem.applyReferralCode(referees[i], code);
        }
        
        // Fast forward
        vm.warp(block.timestamp + 8 days);
        
        // Get referrer's code
        bytes32 referrerCode = referralSystem.getUserReferralCode(referrer);
        
        // Verify referrals in sequence to test tier progression (AFTER increment fix)
        // 1st-4th verifications: increment 0→1, 1→2, 2→3, 3→4 → Tier 1 (10 QUIKS each)
        vm.prank(owner);
        referralSystem.verifyReferral(referees[0]);
        vm.prank(owner);
        referralSystem.verifyReferral(referees[1]);
        vm.prank(owner);
        referralSystem.verifyReferral(referees[2]);
        vm.prank(owner);
        referralSystem.verifyReferral(referees[3]);
        
        // 5th verification: increment 4→5 → Tier 2 (15 QUIKS) - matches documentation!
        vm.prank(owner);
        referralSystem.verifyReferral(referees[4]);
        
        // 6th-9th verifications: increment 5→6, 6→7, 7→8, 8→9 → Tier 2 (15 QUIKS each)
        vm.prank(owner);
        referralSystem.verifyReferral(referees[5]);
        vm.prank(owner);
        referralSystem.verifyReferral(referees[6]);
        vm.prank(owner);
        referralSystem.verifyReferral(referees[7]);
        vm.prank(owner);
        referralSystem.verifyReferral(referees[8]);
        
        // 10th verification: increment 9→10 → Tier 3 (20 QUIKS)
        vm.prank(owner);
        referralSystem.verifyReferral(referees[9]);
        
        // 11th-19th verifications: increment 10→11 through 18→19 → Tier 3 (20 QUIKS each)
        for (uint i = 10; i < 19; i++) {
            vm.prank(owner);
            referralSystem.verifyReferral(referees[i]);
        }
        
        // 20th verification: increment 19→20 → Tier 4 (30 QUIKS)
        vm.prank(owner);
        referralSystem.verifyReferral(referees[19]);
        
        // Check total rewards: 4*10 + 5*15 + 10*20 + 1*30 = 40 + 75 + 200 + 30 = 345 QUIKS
        (,, uint256 totalRewards,,,) = referralSystem.getReferralStats(referrer);
        assertEq(totalRewards, 345 ether, "Total rewards: Tier1(4*10) + Tier2(5*15) + Tier3(10*20) + Tier4(1*30) = 345 QUIKS");
    }
    
    // ═══════════════════════════════════════════════════════════════
    // MANUAL CLAIM TESTS
    // ═══════════════════════════════════════════════════════════════
    
    function testManualClaimReward() public {
        // Disable auto-reward
        vm.prank(owner);
        referralSystem.updateConfig(365 days, 7 days, false);
        
        // Setup referral
        vm.prank(referrer);
        bytes32 code = referralSystem.generateReferralCode();
        
        vm.prank(owner);
        referralSystem.applyReferralCode(referee1, code);
        
        // Fast forward and verify
        vm.warp(block.timestamp + 8 days);
        vm.prank(owner);
        referralSystem.verifyReferral(referee1);
        
        // Check balance before claim
        uint256 balanceBefore = quiksToken.balanceOf(referrer);
        
        // Claim reward
        vm.prank(referrer);
        referralSystem.claimReferralReward(0);
        
        uint256 balanceAfter = quiksToken.balanceOf(referrer);
        assertEq(balanceAfter - balanceBefore, 10 ether, "Should receive reward on claim");
    }
    
    // ═══════════════════════════════════════════════════════════════
    // BATCH OPERATIONS TESTS
    // ═══════════════════════════════════════════════════════════════
    
    function testBatchVerifyReferrals() public {
        vm.prank(referrer);
        bytes32 code = referralSystem.generateReferralCode();
        
        // Apply multiple referrals
        address[] memory referees = new address[](3);
        referees[0] = referee1;
        referees[1] = referee2;
        referees[2] = referee3;
        
        for (uint i = 0; i < 3; i++) {
            vm.prank(owner);
            referralSystem.applyReferralCode(referees[i], code);
        }
        
        // Fast forward
        vm.warp(block.timestamp + 8 days);
        
        // Batch verify
        uint256 balanceBefore = quiksToken.balanceOf(referrer);
        vm.prank(owner);
        referralSystem.batchVerifyReferrals(referees);
        uint256 balanceAfter = quiksToken.balanceOf(referrer);
        
        assertEq(balanceAfter - balanceBefore, 30 ether, "Should receive 3x 10 QUIKS");
    }
    
    // ═══════════════════════════════════════════════════════════════
    // VIEW FUNCTION TESTS
    // ═══════════════════════════════════════════════════════════════
    
    function testGetReferralStats() public {
        vm.prank(referrer);
        bytes32 code = referralSystem.generateReferralCode();
        
        vm.prank(owner);
        referralSystem.applyReferralCode(referee1, code);
        
        (bytes32 returnedCode, uint256 totalReferrals, uint256 totalRewards, uint256 pending,, ) = 
            referralSystem.getReferralStats(referrer);
        
        assertEq(returnedCode, code, "Code should match");
        assertEq(totalReferrals, 1, "Should have 1 referral");
        assertEq(pending, 1, "Should have 1 pending");
        assertEq(totalRewards, 0, "No rewards yet");
    }
    
    function testIsValidReferralCode() public {
        vm.prank(referrer);
        bytes32 code = referralSystem.generateReferralCode();
        
        assertTrue(referralSystem.isValidReferralCode(code), "Code should be valid");
        
        bytes32 invalidCode = bytes32(uint256(12345));
        assertFalse(referralSystem.isValidReferralCode(invalidCode), "Invalid code should be false");
    }
    
    function testGetReferrerInfo() public {
        vm.prank(referrer);
        bytes32 code = referralSystem.generateReferralCode();
        
        vm.prank(owner);
        referralSystem.applyReferralCode(referee1, code);
        
        (address returnedReferrer, bytes32 returnedCode, uint256 referredAt, ReferralSystem.ReferralStatus status) = 
            referralSystem.getReferrerInfo(referee1);
        
        assertEq(returnedReferrer, referrer, "Referrer should match");
        assertEq(returnedCode, code, "Code should match");
        assertTrue(referredAt > 0, "ReferredAt should be set");
        assertTrue(status == ReferralSystem.ReferralStatus.PENDING, "Status should be PENDING");
    }
    
    // ═══════════════════════════════════════════════════════════════
    // ADMIN FUNCTION TESTS
    // ═══════════════════════════════════════════════════════════════
    
    function testUpdateRewardTier() public {
        vm.prank(owner);
        referralSystem.updateRewardTier(1, 20 ether, 1000, 0, true);
        
        (uint256 fixedReward, uint256 percentageBps, uint256 minReferrals, bool isActive) = 
            referralSystem.rewardTiers(1);
        
        assertEq(fixedReward, 20 ether, "Fixed reward should be updated");
        assertEq(percentageBps, 1000, "Percentage should be updated");
    }
    
    function testDeactivateReferralCode() public {
        vm.prank(referrer);
        bytes32 code = referralSystem.generateReferralCode();
        
        vm.prank(owner);
        referralSystem.deactivateReferralCode(code);
        
        assertFalse(referralSystem.isValidReferralCode(code), "Code should be invalid");
    }
    
    function testUpdateConfig() public {
        vm.prank(owner);
        referralSystem.updateConfig(180 days, 14 days, false);
        
        assertEq(referralSystem.referralCodeExpiry(), 180 days);
        assertEq(referralSystem.minimumVerificationDelay(), 14 days);
        assertFalse(referralSystem.autoRewardEnabled());
    }
    
    function testWithdrawTokens() public {
        uint256 ownerBalanceBefore = quiksToken.balanceOf(owner);
        
        vm.prank(owner);
        referralSystem.withdrawTokens(1000 ether);
        
        uint256 ownerBalanceAfter = quiksToken.balanceOf(owner);
        assertEq(ownerBalanceAfter - ownerBalanceBefore, 1000 ether, "Should withdraw tokens");
    }
    
    function testPauseUnpause() public {
        vm.prank(owner);
        referralSystem.pause();
        assertTrue(referralSystem.paused(), "Should be paused");
        
        vm.prank(referrer);
        vm.expectRevert();
        referralSystem.generateReferralCode();
        
        vm.prank(owner);
        referralSystem.unpause();
        assertFalse(referralSystem.paused(), "Should be unpaused");
    }
    
    // ═══════════════════════════════════════════════════════════════
    // EDGE CASE TESTS
    // ═══════════════════════════════════════════════════════════════
    
    function testExpiredReferralCode() public {
        vm.prank(referrer);
        bytes32 code = referralSystem.generateReferralCode();
        
        // Fast forward past expiry
        vm.warp(block.timestamp + 366 days);
        
        assertFalse(referralSystem.isValidReferralCode(code), "Code should be expired");
        
        vm.expectRevert("Referral code expired");
        vm.prank(owner);
        referralSystem.applyReferralCode(referee1, code);
    }
    
    function testInsufficientTokenBalance() public {
        // Withdraw all tokens
        uint256 balance = quiksToken.balanceOf(address(referralSystem));
        vm.prank(owner);
        referralSystem.withdrawTokens(balance);
        
        // Setup referral
        vm.prank(referrer);
        bytes32 code = referralSystem.generateReferralCode();
        
        vm.prank(owner);
        referralSystem.applyReferralCode(referee1, code);
        
        // Fast forward
        vm.warp(block.timestamp + 8 days);
        
        // Try to verify
        vm.expectRevert("Insufficient token balance");
        vm.prank(owner);
        referralSystem.verifyReferral(referee1);
    }
}
