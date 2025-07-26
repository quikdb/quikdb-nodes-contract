// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "openzeppelin-contracts-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";

/**
 * @title QuiksToken
 * @notice The official QuikDB network utility token (QUIKS)
 * @dev Upgradeable ERC-20 token with simple owner-only access control:
 *      - Owner-only minting functionality
 *      - Burnable tokens for deflationary mechanisms
 *      - EIP-2612 permit functionality for gasless approvals
 *      - UUPS upgradeable pattern for future improvements
 * 
 * Token Economics:
 * - Symbol: QUIKS
 * - Decimals: 18
 * - Total Supply: Managed through owner-controlled minting
 * - Use Cases: Rewards, payments, staking, governance
 */
contract QuiksToken is 
    Initializable,
    ERC20Upgradeable, 
    ERC20BurnableUpgradeable, 
    ERC20PermitUpgradeable, 
    OwnableUpgradeable,
    UUPSUpgradeable {

    // ═══════════════════════════════════════════════════════════════
    // EVENTS
    // ═══════════════════════════════════════════════════════════════
    
    /// @notice Emitted when tokens are minted
    event TokensMinted(address indexed recipient, uint256 amount);

    // ═══════════════════════════════════════════════════════════════
    // CONSTRUCTOR & INITIALIZER
    // ═══════════════════════════════════════════════════════════════
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }
    
    /**
     * @notice Initialize the QUIKS token (replaces constructor for upgradeable)
     * @param name Token name
     * @param symbol Token symbol
     * @param initialSupply Initial token supply (in wei, 18 decimals)
     * @param initialOwner Address that will have owner privileges
     */
    function initialize(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        address initialOwner
    ) public initializer {
        require(initialOwner != address(0), "Owner cannot be zero address");
        
        // Initialize parent contracts
        __ERC20_init(name, symbol);
        __ERC20Burnable_init();
        __ERC20Permit_init(name);
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
        
        // Mint initial supply to owner
        if (initialSupply > 0) {
            _mint(initialOwner, initialSupply);
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // MINTING FUNCTIONS
    // ═══════════════════════════════════════════════════════════════
    
    /**
     * @notice Mint tokens to a specific address (owner only)
     * @param to Recipient address
     * @param amount Amount to mint (in wei)
     */
    function mint(address to, uint256 amount) external onlyOwner {
        require(to != address(0), "Cannot mint to zero address");
        require(amount > 0, "Amount must be greater than 0");
        
        _mint(to, amount);
        emit TokensMinted(to, amount);
    }

    // ═══════════════════════════════════════════════════════════════
    // OVERRIDES
    // ═══════════════════════════════════════════════════════════════
    
    /**
     * @notice Authorization for UUPS upgrades (owner only)
     * @param newImplementation Address of the new implementation
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
    
    /**
     * @notice Returns the current implementation version
     * @return Version string
     */
    function version() external pure returns (string memory) {
        return "1.0.0";
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
