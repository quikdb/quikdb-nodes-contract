// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/utils/PausableUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/utils/ReentrancyGuardUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "./UserNodeRegistry.sol";
import "./tokens/QuiksToken.sol";

/**
 * @title ReferralSystem
 * @notice Manages referral codes, tracking, and reward distribution for QuikDB
 * @dev Upgradeable contract with automated reward distribution and tier-based rewards.
 *      V2 changes: Rewards are distributed in USDT (via Web3Auth) instead of native LSK.
 *      QuiksToken is kept for referral code generation and user validation.
 *      - Generate unique referral codes for users
 *      - Track referral relationships and conversions
 *      - Automated USDT reward distribution with tier-based bonuses
 *      - Integration with UserNodeRegistry for user validation
 *      - UUPS upgradeable pattern
 */
contract ReferralSystem is
    Initializable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable {

    using SafeERC20 for IERC20;

    // ═══════════════════════════════════════════════════════════════
    // STRUCTS & ENUMS
    // ═══════════════════════════════════════════════════════════════

    enum ReferralStatus { PENDING, VERIFIED, REWARDED, EXPIRED }

    struct ReferralCode {
        bytes32 code;              // Unique referral code hash
        address referrer;          // User who owns this code
        uint256 createdAt;         // Timestamp of creation
        uint256 totalReferrals;    // Total applied referrals (including pending)
        uint256 verifiedReferrals; // Total verified/rewarded referrals (for tier calc)
        uint256 totalRewards;      // Total rewards earned (in reward token units)
        bool isActive;             // Whether code is still active
    }

    struct Referral {
        address referee;           // User who was referred
        address referrer;          // User who referred them
        bytes32 referralCode;      // Code used
        uint256 referredAt;        // Timestamp of referral
        ReferralStatus status;     // Current status
        uint256 rewardsEarned;     // Rewards earned by referrer
        uint256 tier;              // Reward tier (1-4)
    }

    struct RewardTier {
        uint256 fixedReward;       // Fixed reward amount (in reward token units)
        uint256 percentageBps;     // Percentage in basis points (100 = 1%)
        uint256 minReferrals;      // Min referrals to unlock
        bool isActive;             // Whether tier is active
    }

    // ═══════════════════════════════════════════════════════════════
    // STATE VARIABLES (V1 layout - DO NOT reorder for upgrade safety)
    // ═══════════════════════════════════════════════════════════════

    UserNodeRegistry public userRegistry;
    QuiksToken public quiksToken;

    // Referral code management
    mapping(bytes32 => ReferralCode) public referralCodes;
    mapping(address => bytes32) public userReferralCode;
    mapping(address => bytes32) public referredBy; // referee => referral code used

    // Referral tracking
    mapping(address => Referral[]) public userReferrals; // referrer => referrals
    mapping(address => bool) public hasBeenReferred;

    // Reward tiers (1-4)
    mapping(uint256 => RewardTier) public rewardTiers;

    // Statistics
    uint256 public totalReferralCodes;
    uint256 public totalSuccessfulReferrals;
    uint256 public totalRewardsDistributed;

    // Configuration
    uint256 public referralCodeExpiry; // Seconds until code expires
    uint256 public minimumVerificationDelay; // Seconds before reward eligible
    bool public autoRewardEnabled;

    // ═══════════════════════════════════════════════════════════════
    // V2 STATE VARIABLES (appended after V1 slots for upgrade safety)
    // ═══════════════════════════════════════════════════════════════

    /// @notice USDT token used for reward distribution (replaces LSK distribution)
    IERC20 public rewardToken;

    // ═══════════════════════════════════════════════════════════════
    // EVENTS
    // ═══════════════════════════════════════════════════════════════

    event ReferralCodeGenerated(
        address indexed referrer,
        bytes32 indexed code,
        uint256 timestamp
    );

    event ReferralRegistered(
        address indexed referee,
        address indexed referrer,
        bytes32 indexed referralCode,
        uint256 timestamp
    );

    event ReferralVerified(
        address indexed referee,
        address indexed referrer,
        bytes32 indexed referralCode,
        uint256 tier
    );

    event RewardDistributed(
        address indexed referrer,
        address indexed referee,
        uint256 amount,
        uint256 tier,
        uint256 timestamp
    );

    event RewardTierUpdated(
        uint256 indexed tier,
        uint256 fixedReward,
        uint256 percentageBps,
        uint256 minReferrals
    );

    event ReferralCodeDeactivated(
        address indexed referrer,
        bytes32 indexed code
    );

    event ConfigUpdated(
        uint256 referralCodeExpiry,
        uint256 minimumVerificationDelay,
        bool autoRewardEnabled
    );

    event RewardTokenUpdated(address indexed newToken);

    // ═══════════════════════════════════════════════════════════════
    // CONSTRUCTOR & INITIALIZER
    // ═══════════════════════════════════════════════════════════════

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initialize the ReferralSystem (V1)
     * @param _userRegistry Address of UserNodeRegistry contract
     * @param _quiksToken Address of QuiksToken contract
     * @param _owner Address that will have owner privileges
     */
    function initialize(
        address _userRegistry,
        address _quiksToken,
        address _owner
    ) public initializer {
        require(_userRegistry != address(0), "Invalid registry address");
        require(_quiksToken != address(0), "Invalid token address");
        require(_owner != address(0), "Invalid owner address");

        __Ownable_init(_owner);
        __Pausable_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();

        userRegistry = UserNodeRegistry(_userRegistry);
        quiksToken = QuiksToken(_quiksToken);

        // Default configuration
        referralCodeExpiry = 365 days;
        minimumVerificationDelay = 7 days;
        autoRewardEnabled = true;

        // Initialize default reward tiers
        _initializeDefaultTiers();
    }

    /**
     * @notice V2 reinitializer: set USDT as reward token and update tier amounts
     * @dev Call this after upgrading to V2 implementation.
     *      Switches reward distribution from QUIKS to USDT via Web3Auth.
     * @param _rewardToken Address of USDT token contract
     */
    function initializeV2(address _rewardToken) public reinitializer(2) {
        require(_rewardToken != address(0), "Invalid reward token");
        rewardToken = IERC20(_rewardToken);

        // Update reward tiers to USDT amounts (6 decimals)
        _initializeUSDTTiers();

        emit RewardTokenUpdated(_rewardToken);
    }

    // ═══════════════════════════════════════════════════════════════
    // CORE FUNCTIONS
    // ═══════════════════════════════════════════════════════════════

    /**
     * @notice Generate a unique referral code for a user
     * @return code The generated referral code hash
     */
    function generateReferralCode() external whenNotPaused returns (bytes32) {
        return _generateReferralCodeFor(msg.sender);
    }

    /**
     * @notice Generate a unique referral code for a user (owner-only)
     * @param user The user address to generate code for
     * @return code The generated referral code hash
     */
    function generateReferralCodeFor(address user)
        external
        onlyOwner
        whenNotPaused
        returns (bytes32)
    {
        return _generateReferralCodeFor(user);
    }

    /**
     * @dev Internal function to generate referral code
     */
    function _generateReferralCodeFor(address user)
        internal
        returns (bytes32)
    {
        require(userReferralCode[user] == bytes32(0), "User already has referral code");

        (address userAddress, bool isActive) = userRegistry.getUserStatus(user);
        require(isActive && userAddress != address(0), "User not registered");

        bytes32 code = keccak256(
            abi.encodePacked(
                user,
                block.timestamp,
                block.prevrandao,
                totalReferralCodes
            )
        );

        referralCodes[code] = ReferralCode({
            code: code,
            referrer: user,
            createdAt: block.timestamp,
            totalReferrals: 0,
            verifiedReferrals: 0,
            totalRewards: 0,
            isActive: true
        });

        userReferralCode[user] = code;
        totalReferralCodes++;

        emit ReferralCodeGenerated(user, code, block.timestamp);

        return code;
    }

    /**
     * @notice Apply a referral code during user registration
     * @param referee Address of the new user being referred
     * @param code Referral code to apply
     */
    function applyReferralCode(
        address referee,
        bytes32 code
    ) external onlyOwner whenNotPaused {
        _applyReferralCodeFor(referee, code);
    }

    /**
     * @dev Internal function to apply referral code
     */
    function _applyReferralCodeFor(
        address referee,
        bytes32 code
    ) internal {
        require(referee != address(0), "Invalid referee address");
        require(code != bytes32(0), "Invalid referral code");
        require(!hasBeenReferred[referee], "User already referred");

        ReferralCode storage refCode = referralCodes[code];
        require(refCode.isActive, "Referral code not active");
        require(refCode.referrer != referee, "Cannot refer yourself");

        if (referralCodeExpiry > 0) {
            require(
                block.timestamp <= refCode.createdAt + referralCodeExpiry,
                "Referral code expired"
            );
        }

        referredBy[referee] = code;
        hasBeenReferred[referee] = true;

        Referral memory newReferral = Referral({
            referee: referee,
            referrer: refCode.referrer,
            referralCode: code,
            referredAt: block.timestamp,
            status: ReferralStatus.PENDING,
            rewardsEarned: 0,
            tier: 1
        });

        userReferrals[refCode.referrer].push(newReferral);
        refCode.totalReferrals++;

        emit ReferralRegistered(referee, refCode.referrer, code, block.timestamp);
    }

    /**
     * @notice Verify a referral and determine reward tier (owner-only)
     * @param referee Address of the referred user
     */
    function verifyReferral(
        address referee
    ) external onlyOwner whenNotPaused nonReentrant {
        _verifyReferral(referee);
    }

    /**
     * @notice Manually claim rewards for verified referrals
     * @param refereeIndex Index of the referral in userReferrals array
     */
    function claimReferralReward(
        uint256 refereeIndex
    ) external whenNotPaused nonReentrant {
        address referrer = msg.sender;
        require(refereeIndex < userReferrals[referrer].length, "Invalid index");

        Referral storage referral = userReferrals[referrer][refereeIndex];
        require(referral.status == ReferralStatus.VERIFIED, "Referral not verified");

        _distributeReward(referrer, referral.referee, refereeIndex);
    }

    /**
     * @notice Batch verify multiple referrals (owner-only)
     * @param referees Array of referee addresses to verify
     */
    function batchVerifyReferrals(
        address[] calldata referees
    ) external onlyOwner whenNotPaused nonReentrant {
        require(referees.length > 0, "Empty array");
        require(referees.length <= 50, "Batch too large");

        for (uint256 i = 0; i < referees.length; i++) {
            _verifyReferral(referees[i]);
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // INTERNAL FUNCTIONS
    // ═══════════════════════════════════════════════════════════════

    /**
     * @notice Initialize default reward tiers (V1 - QUIKS, 18 decimals)
     */
    function _initializeDefaultTiers() internal {
        rewardTiers[1] = RewardTier({ fixedReward: 10 ether, percentageBps: 500, minReferrals: 0, isActive: true });
        rewardTiers[2] = RewardTier({ fixedReward: 15 ether, percentageBps: 700, minReferrals: 5, isActive: true });
        rewardTiers[3] = RewardTier({ fixedReward: 20 ether, percentageBps: 1000, minReferrals: 10, isActive: true });
        rewardTiers[4] = RewardTier({ fixedReward: 30 ether, percentageBps: 1500, minReferrals: 20, isActive: true });
    }

    /**
     * @notice Initialize USDT reward tiers (V2 - USDT, 6 decimals)
     * @dev USDT uses 6 decimals: 1 USDT = 1_000_000
     *      Tier 1: $5 USDT + 5% of referee spend
     *      Tier 2: $10 USDT + 7% of referee spend
     *      Tier 3: $15 USDT + 10% of referee spend
     *      Tier 4: $25 USDT + 15% of referee spend
     */
    function _initializeUSDTTiers() internal {
        rewardTiers[1] = RewardTier({ fixedReward: 5 * 1e6, percentageBps: 500, minReferrals: 0, isActive: true });
        rewardTiers[2] = RewardTier({ fixedReward: 10 * 1e6, percentageBps: 700, minReferrals: 5, isActive: true });
        rewardTiers[3] = RewardTier({ fixedReward: 15 * 1e6, percentageBps: 1000, minReferrals: 10, isActive: true });
        rewardTiers[4] = RewardTier({ fixedReward: 25 * 1e6, percentageBps: 1500, minReferrals: 20, isActive: true });
    }

    /**
     * @dev Internal verification logic
     */
    function _verifyReferral(address referee) internal {
        bytes32 code = referredBy[referee];
        require(code != bytes32(0), "No referral found");

        ReferralCode storage refCode = referralCodes[code];
        Referral[] storage referrals = userReferrals[refCode.referrer];

        bool found = false;
        for (uint256 i = 0; i < referrals.length; i++) {
            if (referrals[i].referee == referee &&
                referrals[i].status == ReferralStatus.PENDING) {

                require(
                    block.timestamp >= referrals[i].referredAt + minimumVerificationDelay,
                    "Verification delay not met"
                );

                (address userAddress, bool isActive) = userRegistry.getUserStatus(referee);
                require(isActive && userAddress != address(0), "Referee not active");

                refCode.verifiedReferrals++;

                uint256 tier = _calculateRewardTier(refCode.verifiedReferrals);
                referrals[i].tier = tier;
                referrals[i].status = ReferralStatus.VERIFIED;

                emit ReferralVerified(referee, refCode.referrer, code, tier);

                if (autoRewardEnabled) {
                    _distributeReward(refCode.referrer, referee, i);
                }

                found = true;
                break;
            }
        }

        require(found, "No pending referral found");
    }

    /**
     * @notice Calculate reward tier based on total referrals
     */
    function _calculateRewardTier(uint256 _totalReferrals) internal view returns (uint256) {
        if (_totalReferrals >= rewardTiers[4].minReferrals && rewardTiers[4].isActive) {
            return 4;
        } else if (_totalReferrals >= rewardTiers[3].minReferrals && rewardTiers[3].isActive) {
            return 3;
        } else if (_totalReferrals >= rewardTiers[2].minReferrals && rewardTiers[2].isActive) {
            return 2;
        }
        return 1;
    }

    /**
     * @notice Distribute USDT rewards to referrer via Web3Auth
     * @dev Uses SafeERC20 for USDT transfers (handles non-standard return values).
     *      Falls back to QUIKS if rewardToken is not set (V1 compatibility).
     */
    function _distributeReward(
        address referrer,
        address referee,
        uint256 referralIndex
    ) internal {
        Referral storage referral = userReferrals[referrer][referralIndex];
        require(referral.status == ReferralStatus.VERIFIED, "Not verified");

        uint256 tier = referral.tier;
        RewardTier memory rewardTier = rewardTiers[tier];
        require(rewardTier.isActive, "Reward tier not active");

        uint256 rewardAmount = rewardTier.fixedReward;

        if (address(rewardToken) != address(0)) {
            // V2: Distribute USDT rewards
            if (rewardTier.percentageBps > 0) {
                uint256 refereeBalance = rewardToken.balanceOf(referee);
                uint256 percentageReward = (refereeBalance * rewardTier.percentageBps) / 10000;
                rewardAmount += percentageReward;
            }

            require(
                rewardToken.balanceOf(address(this)) >= rewardAmount,
                "Insufficient USDT balance"
            );

            rewardToken.safeTransfer(referrer, rewardAmount);
        } else {
            // V1 fallback: Distribute QUIKS rewards
            if (rewardTier.percentageBps > 0) {
                uint256 refereeBalance = quiksToken.balanceOf(referee);
                uint256 percentageReward = (refereeBalance * rewardTier.percentageBps) / 10000;
                rewardAmount += percentageReward;
            }

            require(
                quiksToken.balanceOf(address(this)) >= rewardAmount,
                "Insufficient token balance"
            );

            require(
                quiksToken.transfer(referrer, rewardAmount),
                "Token transfer failed"
            );
        }

        // Update tracking
        referral.rewardsEarned = rewardAmount;
        referral.status = ReferralStatus.REWARDED;

        bytes32 code = referral.referralCode;
        referralCodes[code].totalRewards += rewardAmount;
        totalRewardsDistributed += rewardAmount;
        totalSuccessfulReferrals++;

        emit RewardDistributed(referrer, referee, rewardAmount, tier, block.timestamp);
    }

    // ═══════════════════════════════════════════════════════════════
    // VIEW FUNCTIONS
    // ═══════════════════════════════════════════════════════════════

    /**
     * @notice Get referral statistics for a user
     */
    function getReferralStats(address user) external view returns (
        bytes32 code,
        uint256 totalReferrals,
        uint256 totalRewards,
        uint256 pendingReferrals,
        uint256 verifiedReferrals,
        uint256 rewardedReferrals
    ) {
        code = userReferralCode[user];
        if (code != bytes32(0)) {
            ReferralCode memory refCode = referralCodes[code];
            totalReferrals = refCode.totalReferrals;
            totalRewards = refCode.totalRewards;

            Referral[] memory referrals = userReferrals[user];
            for (uint256 i = 0; i < referrals.length; i++) {
                if (referrals[i].status == ReferralStatus.PENDING) {
                    pendingReferrals++;
                } else if (referrals[i].status == ReferralStatus.VERIFIED) {
                    verifiedReferrals++;
                } else if (referrals[i].status == ReferralStatus.REWARDED) {
                    rewardedReferrals++;
                }
            }
        }
    }

    /**
     * @notice Get all referrals for a user
     */
    function getUserReferrals(address user) external view returns (Referral[] memory) {
        return userReferrals[user];
    }

    /**
     * @notice Get referral count for a user
     */
    function getUserReferralCount(address user) external view returns (uint256) {
        return userReferrals[user].length;
    }

    /**
     * @notice Check if referral code is valid
     */
    function isValidReferralCode(bytes32 code) external view returns (bool) {
        ReferralCode memory refCode = referralCodes[code];
        if (!refCode.isActive) return false;

        if (referralCodeExpiry > 0) {
            if (block.timestamp > refCode.createdAt + referralCodeExpiry) {
                return false;
            }
        }

        return true;
    }

    /**
     * @notice Get referral code for a user
     */
    function getUserReferralCode(address user) external view returns (bytes32) {
        return userReferralCode[user];
    }

    /**
     * @notice Check if user was referred and by whom
     */
    function getReferrerInfo(address referee) external view returns (
        address referrer,
        bytes32 code,
        uint256 referredAt,
        ReferralStatus status
    ) {
        code = referredBy[referee];
        if (code != bytes32(0)) {
            ReferralCode memory refCode = referralCodes[code];
            referrer = refCode.referrer;

            Referral[] memory referrals = userReferrals[referrer];
            for (uint256 i = 0; i < referrals.length; i++) {
                if (referrals[i].referee == referee) {
                    referredAt = referrals[i].referredAt;
                    status = referrals[i].status;
                    break;
                }
            }
        }
    }

    /**
     * @notice Get the reward token address (USDT)
     */
    function getRewardToken() external view returns (address) {
        return address(rewardToken);
    }

    // ═══════════════════════════════════════════════════════════════
    // ADMIN FUNCTIONS
    // ═══════════════════════════════════════════════════════════════

    /**
     * @notice Update the reward token address (e.g., switch USDT contract)
     * @param _newRewardToken New ERC20 token address for rewards
     */
    function setRewardToken(address _newRewardToken) external onlyOwner {
        require(_newRewardToken != address(0), "Invalid token address");
        rewardToken = IERC20(_newRewardToken);
        emit RewardTokenUpdated(_newRewardToken);
    }

    /**
     * @notice Update reward tier configuration
     */
    function updateRewardTier(
        uint256 tier,
        uint256 fixedReward,
        uint256 percentageBps,
        uint256 minReferrals,
        bool isActive
    ) external onlyOwner {
        require(tier >= 1 && tier <= 4, "Invalid tier");
        require(percentageBps <= 10000, "Percentage too high");

        rewardTiers[tier] = RewardTier({
            fixedReward: fixedReward,
            percentageBps: percentageBps,
            minReferrals: minReferrals,
            isActive: isActive
        });

        emit RewardTierUpdated(tier, fixedReward, percentageBps, minReferrals);
    }

    /**
     * @notice Deactivate a referral code
     */
    function deactivateReferralCode(bytes32 code) external onlyOwner {
        require(referralCodes[code].isActive, "Code already inactive");
        referralCodes[code].isActive = false;
        emit ReferralCodeDeactivated(referralCodes[code].referrer, code);
    }

    /**
     * @notice Update configuration
     */
    function updateConfig(
        uint256 _referralCodeExpiry,
        uint256 _minimumVerificationDelay,
        bool _autoRewardEnabled
    ) external onlyOwner {
        referralCodeExpiry = _referralCodeExpiry;
        minimumVerificationDelay = _minimumVerificationDelay;
        autoRewardEnabled = _autoRewardEnabled;

        emit ConfigUpdated(_referralCodeExpiry, _minimumVerificationDelay, _autoRewardEnabled);
    }

    /**
     * @notice Fund the contract with reward tokens (USDT) for distribution
     * @param amount Amount of reward tokens to transfer to contract
     */
    function fundRewards(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than 0");
        if (address(rewardToken) != address(0)) {
            rewardToken.safeTransferFrom(msg.sender, address(this), amount);
        } else {
            require(
                quiksToken.transferFrom(msg.sender, address(this), amount),
                "Token transfer failed"
            );
        }
    }

    /**
     * @notice Withdraw reward tokens from contract
     * @param amount Amount to withdraw
     */
    function withdrawTokens(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than 0");
        if (address(rewardToken) != address(0)) {
            require(
                rewardToken.balanceOf(address(this)) >= amount,
                "Insufficient balance"
            );
            rewardToken.safeTransfer(owner(), amount);
        } else {
            require(
                quiksToken.balanceOf(address(this)) >= amount,
                "Insufficient balance"
            );
            require(
                quiksToken.transfer(owner(), amount),
                "Token transfer failed"
            );
        }
    }

    /**
     * @notice Emergency withdraw any ERC20 token (for recovery)
     * @param token Address of the token to withdraw
     * @param amount Amount to withdraw
     */
    function emergencyWithdrawToken(address token, uint256 amount) external onlyOwner {
        require(token != address(0), "Invalid token");
        IERC20(token).safeTransfer(owner(), amount);
    }

    /**
     * @notice Pause contract
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Authorization for UUPS upgrades
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /**
     * @notice Returns the current implementation version
     */
    function version() external pure returns (string memory) {
        return "2.0.0";
    }
}
