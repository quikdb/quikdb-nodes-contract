// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title QuiksToken
 * @notice The official QuikDB network utility token (QUIKS)
 * @dev ERC-20 token with additional features for the QuikDB ecosystem:
 *      - Role-based access control for minting and administration
 *      - Pausable functionality for emergency situations
 *      - Burnable tokens for deflationary mechanisms
 *      - EIP-2612 permit functionality for gasless approvals
 * 
 * Token Economics:
 * - Symbol: QUIKS
 * - Decimals: 18
 * - Total Supply: Managed through controlled minting
 * - Use Cases: Rewards, payments, staking, governance
 */
contract QuiksToken is ERC20, ERC20Burnable, ERC20Permit, AccessControl, Pausable {
    
    // ═══════════════════════════════════════════════════════════════
    // ROLES
    // ═══════════════════════════════════════════════════════════════
    
    /// @notice Role that can mint new tokens (rewards system)
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    
    /// @notice Role that can pause/unpause the contract
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    
    /// @notice Role that can manage other roles
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    // ═══════════════════════════════════════════════════════════════
    // EVENTS
    // ═══════════════════════════════════════════════════════════════
    
    /// @notice Emitted when tokens are minted for rewards
    event RewardsMinted(address indexed recipient, uint256 amount, string reason);
    
    /// @notice Emitted when token economics parameters are updated
    event TokenEconomicsUpdated(string parameter, uint256 oldValue, uint256 newValue);

    // ═══════════════════════════════════════════════════════════════
    // CONSTRUCTOR
    // ═══════════════════════════════════════════════════════════════
    
    /**
     * @notice Initialize the QUIKS token
     * @param initialSupply Initial token supply (in wei, 18 decimals)
     * @param admin Address that will have admin privileges
     * @param minter Address that will have minting privileges (rewards system)
     */
    constructor(
        uint256 initialSupply,
        address admin,
        address minter
    ) 
        ERC20("QuikDB Token", "QUIKS") 
        ERC20Permit("QuikDB Token")
    {
        require(admin != address(0), "Admin cannot be zero address");
        require(minter != address(0), "Minter cannot be zero address");
        
        // Grant roles
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ADMIN_ROLE, admin);
        _grantRole(PAUSER_ROLE, admin);
        _grantRole(MINTER_ROLE, minter);
        
        // Mint initial supply to admin
        if (initialSupply > 0) {
            _mint(admin, initialSupply);
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // MINTING FUNCTIONS
    // ═══════════════════════════════════════════════════════════════
    
    /**
     * @notice Mint tokens for rewards distribution
     * @param to Recipient address (node operator)
     * @param amount Amount to mint (in wei)
     * @param reason Reason for minting (for transparency)
     */
    function mintRewards(
        address to, 
        uint256 amount, 
        string calldata reason
    ) external whenNotPaused {
        require(to != address(0), "Cannot mint to zero address");
        require(amount > 0, "Amount must be greater than 0");
        require(bytes(reason).length > 0, "Reason cannot be empty");
        
        _mint(to, amount);
        emit RewardsMinted(to, amount, reason);
    }
    
    /**
     * @notice Mint tokens to a specific address (admin function)
     * @param to Recipient address
     * @param amount Amount to mint (in wei)
     */
    function mint(address to, uint256 amount) external whenNotPaused {
        require(to != address(0), "Cannot mint to zero address");
        require(amount > 0, "Amount must be greater than 0");
        
        _mint(to, amount);
    }

    // ═══════════════════════════════════════════════════════════════
    // PAUSE FUNCTIONS
    // ═══════════════════════════════════════════════════════════════
    
    /**
     * @notice Pause all token transfers (emergency function)
     */
    function pause() external {
        _pause();
    }
    
    /**
     * @notice Unpause token transfers
     */
    function unpause() external {
        _unpause();
    }

    // ═══════════════════════════════════════════════════════════════
    // OVERRIDES
    // ═══════════════════════════════════════════════════════════════
    
    /**
     * @notice Override _update to include pause functionality
     */
    function _update(
        address from,
        address to,
        uint256 value
    ) internal override whenNotPaused {
        super._update(from, to, value);
    }

    // ═══════════════════════════════════════════════════════════════
    // VIEW FUNCTIONS
    // ═══════════════════════════════════════════════════════════════
    
    /**
     * @notice Get token information
     * @return name Token name
     * @return symbol Token symbol
     * @return decimals Token decimals
     * @return totalSupply Current total supply
     */
    function getTokenInfo() external view returns (
        string memory name,
        string memory symbol,
        uint8 decimals,
        uint256 totalSupply
    ) {
        return (super.name(), super.symbol(), super.decimals(), super.totalSupply());
    }
    
    /**
     * @notice Check if an address has minting privileges
     * @param account Address to check
     * @return bool True if address can mint tokens
     */
    function canMint(address account) external view returns (bool) {
        return hasRole(MINTER_ROLE, account);
    }
    
    /**
     * @notice Check if the contract is currently paused
     * @return bool True if paused
     */
    function isPaused() external view returns (bool) {
        return paused();
    }

    // ═══════════════════════════════════════════════════════════════
    // UTILITY FUNCTIONS
    // ═══════════════════════════════════════════════════════════════
    
    /**
     * @notice Convert token amount to human readable format
     * @param amount Amount in wei
     * @return Human readable amount (with 18 decimals)
     */
    function toTokens(uint256 amount) external pure returns (uint256) {
        return amount / 1e18;
    }
    
    /**
     * @notice Convert human readable amount to wei
     * @param tokens Amount in tokens
     * @return Amount in wei
     */
    function toWei(uint256 tokens) external pure returns (uint256) {
        return tokens * 1e18;
    }
}
