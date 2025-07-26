# QuikDB Simplified Smart Contract Architecture

## Overview

This repository contains the simplified QuikDB smart contract architecture with only two core contracts:

- **UserNodeRegistry.sol** - Unified contract for managing users, nodes, and applications
- **QuiksToken.sol** - Official QuikDB network utility token (QUIKS) with owner-only access control

## Key Simplifications

### 🔒 Auth Model
- **Removed**: Complex role-based access control (RBAC) with multiple roles
- **Added**: Simple owner-only access control using OpenZeppelin's `Ownable`
- **Result**: Only the deployer can perform admin functions (minting, upgrades)

### 🏗️ Architecture
- **Removed**: Complex multi-contract system with storage/logic separation
- **Added**: Unified contracts with all functionality in single files
- **Result**: Reduced gas costs and simplified interactions

### 🪙 Token Features
- **Removed**: Role-based minting, pausing functionality, complex permissions
- **Added**: Owner-only minting, simple upgradeable token
- **Result**: Secure but simple token management

## Contracts

### UserNodeRegistry.sol
```solidity
contract UserNodeRegistry is Ownable, Pausable, ReentrancyGuard
```
- User registration and profile management
- Node registration and metadata
- Application deployment tracking
- Performance metrics
- Owner-only administrative functions

### QuiksToken.sol
```solidity
contract QuiksToken is 
    ERC20Upgradeable, 
    ERC20BurnableUpgradeable, 
    ERC20PermitUpgradeable, 
    OwnableUpgradeable,
    UUPSUpgradeable
```
- ERC-20 token with 18 decimals
- Owner-only minting capability
- Burnable tokens for deflationary mechanisms
- EIP-2612 permit functionality for gasless approvals
- UUPS upgradeable pattern for future improvements

## Deployment

### Quick Start
```bash
# Install dependencies
yarn install

# Compile contracts
yarn build

# Deploy locally (dry run)
yarn deploy

# Deploy to Lisk Sepolia
yarn deploy:lsk:testnet

# Deploy to Lisk Mainnet
yarn deploy:lsk:mainnet
```

### Environment Variables
```bash
PRIVATE_KEY=your_private_key_here
RPC_URL=https://rpc.sepolia-api.lisk.com  # for testnet
```

### Deployment Files
After deployment, contract addresses are saved to:
- `deployments/{network}.json` - Full deployment info
- `deployments/latest.json` - Latest deployment (CLI compatibility)
- `deployments/addresses.json` - Simple address mapping

## Usage

### Token Operations (Owner Only)
```solidity
// Mint tokens to an address
function mint(address to, uint256 amount) external onlyOwner

// Upgrade the token implementation
function upgradeToAndCall(address newImplementation, bytes calldata data) external onlyOwner
```

### Registry Operations (Owner Only)
```solidity
// Pause/unpause the registry
function pause() external onlyOwner
function unpause() external onlyOwner

// Emergency functions available to owner
```

## Security Model

### Access Control
- **Owner**: Deployer address with full administrative privileges
- **Users**: Can interact with public functions (transfers, registrations)
- **No Roles**: Simplified permission model without complex role management

### Upgrade Safety
- QuiksToken uses UUPS proxy pattern
- Only owner can authorize upgrades
- UserNodeRegistry is not upgradeable (deploy new version if needed)

## Gas Efficiency

### Optimizations
- Single contract architecture reduces cross-contract calls
- Removed complex role checks and modifiers
- Simplified storage patterns
- Batch operations where possible

### Estimated Gas Costs
- Token mint: ~50,000 gas
- User registration: ~80,000 gas
- Node registration: ~120,000 gas

## CLI Integration

The deployment creates files compatible with the QuikDB CLI:

```json
{
  "UserNodeRegistry": "0x...",
  "QuiksToken": "0x...",
  "QuiksTokenImpl": "0x..."
}
```

## Development

### Testing
```bash
# Run contract tests
yarn test

# Generate gas snapshot
yarn snapshot
```

### Verification
```bash
# Verify contracts on Etherscan/Blockscout
yarn deploy:lsk:testnet  # includes --verify flag
```

## Migration from Complex Architecture

If migrating from the previous complex architecture:

1. **No Data Migration**: Since this is a simplified deployment, no existing data needs to be migrated
2. **Address Updates**: Update CLI and frontend to use new contract addresses
3. **Permission Updates**: Remove role-based access code, use owner-only patterns
4. **Integration Updates**: Simplify contract interactions to use unified contracts

## Support

For questions about the simplified architecture:
- Check the contract documentation in `src/`
- Review deployment scripts in `scripts/`
- Examine test files for usage examples
