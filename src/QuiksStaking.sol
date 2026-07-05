// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/utils/ReentrancyGuardUpgradeable.sol";
import "./tokens/QuiksToken.sol";

/**
 * @title QuiksStaking
 * @notice Staking contract for QuikDB Node Affiliates
 * @dev Node Affiliates stake 5,000 QUIKS for 90 days to prove commitment.
 *      Owner can slash (burn) a staker's tokens after manual confirmation
 *      of 7+ days offline. Slashing is always manual — never automated.
 *
 * Flow:
 *   1. Node operator calls stake() — transfers 5,000 QUIKS in
 *   2. Owner calls approveAffiliate() after verifying node is live
 *   3. After 90 days, operator calls unstake() to retrieve tokens
 *   4. If node goes offline >7 days, owner calls slash() — tokens burned
 */
contract QuiksStaking is
    Initializable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable
{
    // ═══════════════════════════════════════════════════════════════
    // CONSTANTS
    // ═══════════════════════════════════════════════════════════════

    /// @notice Required stake amount for Node Affiliates
    uint256 public constant STAKE_AMOUNT = 5_000 * 1e18;

    /// @notice Lock period — tokens cannot be withdrawn before this
    uint256 public constant LOCK_PERIOD = 90 days;

    // ═══════════════════════════════════════════════════════════════
    // STATE
    // ═══════════════════════════════════════════════════════════════

    /// @notice The QUIKS token contract
    QuiksToken public quiksToken;

    struct StakeInfo {
        uint256 amount;      // always STAKE_AMOUNT while active
        uint256 stakedAt;    // block.timestamp when staked
        uint256 unlocksAt;   // stakedAt + LOCK_PERIOD
        bool slashed;        // true if slash() was called
    }

    /// @notice Stake info per staker address
    mapping(address => StakeInfo) public stakes;

    /// @notice Stakers approved as active Node Affiliates by owner
    mapping(address => bool) public approvedAffiliates;

    /// @notice Total QUIKS currently held by this contract
    uint256 public totalStaked;

    /// @notice Cumulative QUIKS burned via slash()
    uint256 public totalSlashed;

    // ═══════════════════════════════════════════════════════════════
    // EVENTS
    // ═══════════════════════════════════════════════════════════════

    event Staked(address indexed staker, uint256 amount, uint256 unlocksAt);
    event Unstaked(address indexed staker, uint256 amount);
    event Slashed(address indexed staker, uint256 amount, string reason);
    event AffiliateApproved(address indexed staker);
    event AffiliateRevoked(address indexed staker);

    // ═══════════════════════════════════════════════════════════════
    // INITIALIZER
    // ═══════════════════════════════════════════════════════════════

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initialize the staking contract
     * @param _quiksToken Address of the QuiksToken proxy
     * @param initialOwner Address that will have owner privileges
     */
    function initialize(address _quiksToken, address initialOwner) public initializer {
        require(_quiksToken != address(0), "Token cannot be zero address");
        require(initialOwner != address(0), "Owner cannot be zero address");

        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();

        quiksToken = QuiksToken(_quiksToken);
    }

    // ═══════════════════════════════════════════════════════════════
    // STAKER FUNCTIONS
    // ═══════════════════════════════════════════════════════════════

    /**
     * @notice Stake exactly STAKE_AMOUNT QUIKS to become a Node Affiliate candidate
     * @dev Caller must have approved this contract for STAKE_AMOUNT beforehand
     */
    function stake() external nonReentrant {
        require(stakes[msg.sender].amount == 0, "Already staking");

        bool ok = quiksToken.transferFrom(msg.sender, address(this), STAKE_AMOUNT);
        require(ok, "Token transfer failed");

        uint256 unlocksAt = block.timestamp + LOCK_PERIOD;
        stakes[msg.sender] = StakeInfo({
            amount: STAKE_AMOUNT,
            stakedAt: block.timestamp,
            unlocksAt: unlocksAt,
            slashed: false
        });
        totalStaked += STAKE_AMOUNT;

        emit Staked(msg.sender, STAKE_AMOUNT, unlocksAt);
    }

    /**
     * @notice Withdraw staked QUIKS after the 90-day lock period
     */
    function unstake() external nonReentrant {
        StakeInfo storage info = stakes[msg.sender];
        require(info.amount > 0, "No active stake");
        require(!info.slashed, "Stake was slashed");
        require(block.timestamp >= info.unlocksAt, "Lock period not expired");

        uint256 amount = info.amount;
        totalStaked -= amount;
        approvedAffiliates[msg.sender] = false;
        delete stakes[msg.sender];

        quiksToken.transfer(msg.sender, amount);
        emit Unstaked(msg.sender, amount);
    }

    // ═══════════════════════════════════════════════════════════════
    // OWNER FUNCTIONS
    // ═══════════════════════════════════════════════════════════════

    /**
     * @notice Approve a staker as an active Node Affiliate
     * @dev Call after verifying node is live and healthy
     * @param staker Address of the staker to approve
     */
    function approveAffiliate(address staker) external onlyOwner {
        require(stakes[staker].amount > 0, "Not staking");
        require(!stakes[staker].slashed, "Stake was slashed");
        approvedAffiliates[staker] = true;
        emit AffiliateApproved(staker);
    }

    /**
     * @notice Revoke a staker's Node Affiliate status (does not affect their stake)
     * @param staker Address of the affiliate to revoke
     */
    function revokeAffiliate(address staker) external onlyOwner {
        approvedAffiliates[staker] = false;
        emit AffiliateRevoked(staker);
    }

    /**
     * @notice Slash and burn a staker's tokens after confirmed 7+ days offline
     * @dev Tokens are permanently burned. Call only after manual confirmation.
     *      Slashing is irreversible — double-check before calling.
     * @param staker Address of the staker to slash
     * @param reason Human-readable reason (e.g. "offline 9 days confirmed 2026-07-04")
     */
    function slash(address staker, string calldata reason) external onlyOwner {
        StakeInfo storage info = stakes[staker];
        require(info.amount > 0, "No active stake");
        require(!info.slashed, "Already slashed");

        uint256 amount = info.amount;
        totalStaked -= amount;
        totalSlashed += amount;
        info.slashed = true;
        info.amount = 0;
        approvedAffiliates[staker] = false;

        // Burn — tokens gone permanently
        quiksToken.burn(amount);

        emit Slashed(staker, amount, reason);
    }

    // ═══════════════════════════════════════════════════════════════
    // VIEW FUNCTIONS
    // ═══════════════════════════════════════════════════════════════

    /**
     * @notice Get stake info for an address
     */
    function getStakeInfo(address staker) external view returns (StakeInfo memory) {
        return stakes[staker];
    }

    /**
     * @notice Check if an address is an active, approved, non-slashed affiliate
     */
    function isApprovedAffiliate(address staker) external view returns (bool) {
        return approvedAffiliates[staker]
            && stakes[staker].amount > 0
            && !stakes[staker].slashed;
    }

    /**
     * @notice Seconds remaining in the lock period for a staker (0 if unlocked or not staking)
     */
    function lockTimeRemaining(address staker) external view returns (uint256) {
        uint256 unlocksAt = stakes[staker].unlocksAt;
        if (unlocksAt == 0 || block.timestamp >= unlocksAt) return 0;
        return unlocksAt - block.timestamp;
    }

    /**
     * @notice Returns the current implementation version
     */
    function version() external pure returns (string memory) {
        return "1.0.0";
    }

    // ═══════════════════════════════════════════════════════════════
    // UPGRADE
    // ═══════════════════════════════════════════════════════════════

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
