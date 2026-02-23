// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/ReferralSystem.sol";
import "../src/UserNodeRegistry.sol";
import "../src/tokens/QuiksToken.sol";
import "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

/**
 * @title MockUSDT
 * @notice Simple ERC20 mock with 6 decimals for testing USDT rewards
 */
contract MockUSDT is ERC20 {
    constructor() ERC20("Tether USD", "USDT") {}

    function decimals() public pure override returns (uint8) {
        return 6;
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

/**
 * @title ReferralSystemTest
 * @notice Comprehensive test suite for ReferralSystem V2 contract (USDT rewards via Web3Auth)
 */
contract ReferralSystemTest is Test {
    ReferralSystem public referralSystem;
    UserNodeRegistry public userRegistry;
    QuiksToken public quiksToken;
    MockUSDT public usdt;

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
    event RewardTokenUpdated(address indexed newToken);

    function setUp() public {
        // Deploy UserNodeRegistry
        UserNodeRegistry userRegistryImpl = new UserNodeRegistry();
        ERC1967Proxy userRegistryProxy = new ERC1967Proxy(
            address(userRegistryImpl),
            abi.encodeWithSelector(UserNodeRegistry.initialize.selector, owner)
        );
        userRegistry = UserNodeRegistry(address(userRegistryProxy));

        // Deploy QuiksToken (kept for referral system)
        QuiksToken quiksTokenImpl = new QuiksToken();
        ERC1967Proxy quiksTokenProxy = new ERC1967Proxy(
            address(quiksTokenImpl),
            abi.encodeWithSelector(
                QuiksToken.initialize.selector,
                "Quiks Token",
                "QUIKS",
                1000000 ether,
                owner
            )
        );
        quiksToken = QuiksToken(address(quiksTokenProxy));

        // Deploy MockUSDT
        usdt = new MockUSDT();

        // Deploy ReferralSystem (V1 initialize)
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

        // Call initializeV2 to switch to USDT rewards
        vm.prank(owner);
        referralSystem.initializeV2(address(usdt));

        // Fund ReferralSystem with USDT for rewards
        usdt.mint(owner, 1000000 * 1e6); // 1M USDT
        vm.startPrank(owner);
        usdt.approve(address(referralSystem), 100000 * 1e6);
        referralSystem.fundRewards(100000 * 1e6); // 100k USDT for rewards
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
    // V2 CONFIGURATION TESTS
    // ═══════════════════════════════════════════════════════════════

    function testRewardTokenIsUSDT() public view {
        assertEq(referralSystem.getRewardToken(), address(usdt), "Reward token should be USDT");
    }

    function testVersionIsV2() public view {
        assertEq(
            keccak256(abi.encodePacked(referralSystem.version())),
            keccak256(abi.encodePacked("2.0.0"))
        );
    }

    function testUSDTRewardTiers() public view {
        // Tier 1: $5 USDT
        (uint256 fixedReward1,,,) = referralSystem.rewardTiers(1);
        assertEq(fixedReward1, 5 * 1e6, "Tier 1 should be 5 USDT");

        // Tier 2: $10 USDT
        (uint256 fixedReward2,,,) = referralSystem.rewardTiers(2);
        assertEq(fixedReward2, 10 * 1e6, "Tier 2 should be 10 USDT");

        // Tier 3: $15 USDT
        (uint256 fixedReward3,,,) = referralSystem.rewardTiers(3);
        assertEq(fixedReward3, 15 * 1e6, "Tier 3 should be 15 USDT");

        // Tier 4: $25 USDT
        (uint256 fixedReward4,,,) = referralSystem.rewardTiers(4);
        assertEq(fixedReward4, 25 * 1e6, "Tier 4 should be 25 USDT");
    }

    function testSetRewardToken() public {
        MockUSDT newUsdt = new MockUSDT();

        vm.expectEmit(true, false, false, false);
        emit RewardTokenUpdated(address(newUsdt));

        vm.prank(owner);
        referralSystem.setRewardToken(address(newUsdt));

        assertEq(referralSystem.getRewardToken(), address(newUsdt));
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
        vm.prank(referrer);
        bytes32 code = referralSystem.generateReferralCode();

        vm.expectEmit(true, true, true, false);
        emit ReferralRegistered(referee1, referrer, code, block.timestamp);

        vm.prank(owner);
        referralSystem.applyReferralCode(referee1, code);

        assertTrue(referralSystem.hasBeenReferred(referee1), "Referee should be marked as referred");
        assertEq(referralSystem.referredBy(referee1), code, "Referral code should match");
        assertEq(referralSystem.totalSuccessfulReferrals(), 0, "Total referrals should be 0 until verified");
    }

    function testCannotApplyInvalidCode() public {
        bytes32 invalidCode = bytes32(uint256(12345));
        vm.prank(owner);
        vm.expectRevert("Referral code not active");
        referralSystem.applyReferralCode(referee1, invalidCode);
    }

    function testCannotReferSelf() public {
        vm.prank(referrer);
        bytes32 code = referralSystem.generateReferralCode();

        vm.expectRevert("Cannot refer yourself");
        vm.prank(owner);
        referralSystem.applyReferralCode(referrer, code);
    }

    // ═══════════════════════════════════════════════════════════════
    // USDT REWARD DISTRIBUTION TESTS
    // ═══════════════════════════════════════════════════════════════

    function testVerifyReferralDistributesUSDT() public {
        vm.prank(referrer);
        bytes32 code = referralSystem.generateReferralCode();

        vm.prank(owner);
        referralSystem.applyReferralCode(referee1, code);

        // Fast forward past verification delay
        vm.warp(block.timestamp + 8 days);

        uint256 referrerUSDTBefore = usdt.balanceOf(referrer);

        vm.prank(owner);
        referralSystem.verifyReferral(referee1);

        uint256 referrerUSDTAfter = usdt.balanceOf(referrer);
        // Tier 1: $5 USDT (5 * 1e6)
        assertEq(referrerUSDTAfter - referrerUSDTBefore, 5 * 1e6, "Should receive 5 USDT tier 1 reward");
    }

    function testCannotVerifyBeforeDelay() public {
        vm.prank(referrer);
        bytes32 code = referralSystem.generateReferralCode();

        vm.prank(owner);
        referralSystem.applyReferralCode(referee1, code);

        vm.expectRevert("Verification delay not met");
        vm.prank(owner);
        referralSystem.verifyReferral(referee1);
    }

    function testUSDTRewardTierProgression() public {
        vm.prank(referrer);
        bytes32 code = referralSystem.generateReferralCode();

        // Register and apply 25 referees
        address[] memory referees = new address[](25);
        for (uint i = 0; i < 25; i++) {
            referees[i] = address(uint160(1000 + i));
            _registerUser(referees[i], UserNodeRegistry.UserType.CONSUMER);
            vm.prank(owner);
            referralSystem.applyReferralCode(referees[i], code);
        }

        vm.warp(block.timestamp + 8 days);

        // Verify all and track USDT rewards
        uint256 referrerBalanceBefore = usdt.balanceOf(referrer);

        for (uint i = 0; i < 21; i++) {
            vm.prank(owner);
            referralSystem.verifyReferral(referees[i]);
        }

        uint256 totalRewards = usdt.balanceOf(referrer) - referrerBalanceBefore;

        // Expected: Tier1(4*$5) + Tier2(5*$10) + Tier3(10*$15) + Tier4(2*$25) = 20+50+150+50 = $270 USDT
        assertEq(totalRewards, 270 * 1e6, "Total USDT rewards: Tier1(4*5) + Tier2(5*10) + Tier3(10*15) + Tier4(2*25) = 270");
    }

    // ═══════════════════════════════════════════════════════════════
    // MANUAL CLAIM TESTS
    // ═══════════════════════════════════════════════════════════════

    function testManualClaimUSDTReward() public {
        // Disable auto-reward
        vm.prank(owner);
        referralSystem.updateConfig(365 days, 7 days, false);

        vm.prank(referrer);
        bytes32 code = referralSystem.generateReferralCode();

        vm.prank(owner);
        referralSystem.applyReferralCode(referee1, code);

        vm.warp(block.timestamp + 8 days);
        vm.prank(owner);
        referralSystem.verifyReferral(referee1);

        uint256 balanceBefore = usdt.balanceOf(referrer);
        vm.prank(referrer);
        referralSystem.claimReferralReward(0);
        uint256 balanceAfter = usdt.balanceOf(referrer);

        assertEq(balanceAfter - balanceBefore, 5 * 1e6, "Should receive 5 USDT on claim");
    }

    // ═══════════════════════════════════════════════════════════════
    // BATCH OPERATIONS TESTS
    // ═══════════════════════════════════════════════════════════════

    function testBatchVerifyDistributesUSDT() public {
        vm.prank(referrer);
        bytes32 code = referralSystem.generateReferralCode();

        address[] memory referees = new address[](3);
        referees[0] = referee1;
        referees[1] = referee2;
        referees[2] = referee3;

        for (uint i = 0; i < 3; i++) {
            vm.prank(owner);
            referralSystem.applyReferralCode(referees[i], code);
        }

        vm.warp(block.timestamp + 8 days);

        uint256 balanceBefore = usdt.balanceOf(referrer);
        vm.prank(owner);
        referralSystem.batchVerifyReferrals(referees);
        uint256 balanceAfter = usdt.balanceOf(referrer);

        // 3x Tier 1 ($5 each) = $15 USDT
        assertEq(balanceAfter - balanceBefore, 15 * 1e6, "Should receive 3x $5 = $15 USDT");
    }

    // ═══════════════════════════════════════════════════════════════
    // FUND & WITHDRAW TESTS
    // ═══════════════════════════════════════════════════════════════

    function testFundWithUSDT() public {
        uint256 contractBalanceBefore = usdt.balanceOf(address(referralSystem));

        vm.startPrank(owner);
        usdt.approve(address(referralSystem), 1000 * 1e6);
        referralSystem.fundRewards(1000 * 1e6);
        vm.stopPrank();

        uint256 contractBalanceAfter = usdt.balanceOf(address(referralSystem));
        assertEq(contractBalanceAfter - contractBalanceBefore, 1000 * 1e6, "Contract should receive 1000 USDT");
    }

    function testWithdrawUSDT() public {
        uint256 ownerBalanceBefore = usdt.balanceOf(owner);

        vm.prank(owner);
        referralSystem.withdrawTokens(1000 * 1e6);

        uint256 ownerBalanceAfter = usdt.balanceOf(owner);
        assertEq(ownerBalanceAfter - ownerBalanceBefore, 1000 * 1e6, "Should withdraw 1000 USDT");
    }

    function testEmergencyWithdrawToken() public {
        // Mint some random ERC20 to the contract
        MockUSDT randomToken = new MockUSDT();
        randomToken.mint(address(referralSystem), 500 * 1e6);

        uint256 ownerBalanceBefore = randomToken.balanceOf(owner);

        vm.prank(owner);
        referralSystem.emergencyWithdrawToken(address(randomToken), 500 * 1e6);

        uint256 ownerBalanceAfter = randomToken.balanceOf(owner);
        assertEq(ownerBalanceAfter - ownerBalanceBefore, 500 * 1e6, "Should recover random token");
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

    // ═══════════════════════════════════════════════════════════════
    // ADMIN FUNCTION TESTS
    // ═══════════════════════════════════════════════════════════════

    function testUpdateRewardTier() public {
        vm.prank(owner);
        referralSystem.updateRewardTier(1, 20 * 1e6, 1000, 0, true);

        (uint256 fixedReward, uint256 percentageBps,,) = referralSystem.rewardTiers(1);
        assertEq(fixedReward, 20 * 1e6, "Fixed reward should be updated to 20 USDT");
        assertEq(percentageBps, 1000, "Percentage should be updated");
    }

    function testDeactivateReferralCode() public {
        vm.prank(referrer);
        bytes32 code = referralSystem.generateReferralCode();

        vm.prank(owner);
        referralSystem.deactivateReferralCode(code);

        assertFalse(referralSystem.isValidReferralCode(code), "Code should be invalid");
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

        vm.warp(block.timestamp + 366 days);

        assertFalse(referralSystem.isValidReferralCode(code), "Code should be expired");

        vm.expectRevert("Referral code expired");
        vm.prank(owner);
        referralSystem.applyReferralCode(referee1, code);
    }

    function testInsufficientUSDTBalance() public {
        // Withdraw all USDT
        uint256 balance = usdt.balanceOf(address(referralSystem));
        vm.prank(owner);
        referralSystem.withdrawTokens(balance);

        // Setup referral
        vm.prank(referrer);
        bytes32 code = referralSystem.generateReferralCode();

        vm.prank(owner);
        referralSystem.applyReferralCode(referee1, code);

        vm.warp(block.timestamp + 8 days);

        vm.expectRevert("Insufficient USDT balance");
        vm.prank(owner);
        referralSystem.verifyReferral(referee1);
    }
}
