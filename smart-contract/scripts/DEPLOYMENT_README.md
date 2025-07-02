# QuikDB Deployment Scripts

This directory contains a modular deployment system for the QuikDB smart contracts, organized into logical stages for better maintainability and flexibility.

> **🔧 Yarn Workflow**: All build, test, and deployment tasks should be performed using yarn scripts (see `package.json`). Direct forge commands are not recommended for normal usage.

## Architecture

### Base Contracts
- **`base/BaseDeployment.sol`** - Base contract with common deployment utilities and state management

### Stage Contracts
- **`stages/StorageDeployment.sol`** - Deploys storage contracts (NodeStorage, UserStorage, ResourceStorage)
- **`stages/LogicDeployment.sol`** - Deploys logic implementation contracts
- **`stages/ProxyDeployment.sol`** - Deploys proxy infrastructure and proxy contracts
- **`stages/ConfigurationSetup.sol`** - Handles final configuration and access control

### Orchestrator
- **`DeploymentOrchestrator.sol`** - Main orchestrator that coordinates all deployment stages
- **`DeploymentScenarios.sol`** - Simplified entry points for common deployment scenarios

### TypeScript Deployment
- **`deploy.ts`** - TypeScript deployment script that wraps Forge and automatically saves contract addresses

## Deployment Stages

1. **DEPLOY_STORAGE** - Deploy storage contracts
2. **DEPLOY_LOGIC_IMPLS** - Deploy logic implementation contracts
3. **DEPLOY_PROXY_ADMIN** - Deploy proxy admin contract
4. **DEPLOY_NODE_PROXY** - Deploy node logic proxy
5. **DEPLOY_USER_PROXY** - Deploy user logic proxy
6. **DEPLOY_RESOURCE_PROXY** - Deploy resource logic proxy
7. **DEPLOY_FACADE_PROXY** - Deploy facade proxy
8. **SETUP_STORAGE_CONTRACTS** - Configure storage contracts
9. **SETUP_ACCESS_CONTROL** - Setup access control roles
10. **VERIFY_DEPLOYMENT** - Verify complete deployment

## Quick Start

### Prerequisites
1. Install dependencies: `yarn install`
2. Set environment variables:
   - `PRIVATE_KEY` - Deployer private key
   - `RPC_URL` - Network RPC URL (optional, defaults provided for Lisk networks)

### Build and Test
```bash
yarn build    # Compile all contracts
yarn test     # Run test suite
yarn clean    # Clean build artifacts
```

### Deploy to Lisk Networks
```bash
yarn deploy:lsk:testnet   # Deploy to Lisk Sepolia testnet
yarn deploy:lsk:mainnet   # Deploy to Lisk mainnet
```

### Deploy Locally or Custom Networks
```bash
yarn deploy:complete                    # Local simulation
yarn deploy:broadcast                   # Local with broadcast
RPC_URL=<your-rpc> yarn deploy:broadcast # Custom network
```

## Usage

### TypeScript Deployment (Recommended)

#### Lisk Networks
Deploy to Lisk Sepolia testnet:
```bash
yarn deploy:lsk:testnet
```

Deploy to Lisk mainnet:
```bash
yarn deploy:lsk:mainnet
```

#### Local/Custom Networks
```bash
yarn deploy:complete                    # Local simulation
yarn deploy:broadcast                   # Local with broadcast
RPC_URL=<your-rpc> yarn deploy:broadcast # Custom network
```

#### Staged Deployment
```bash
yarn deploy:storage    # Deploy storage contracts only
yarn deploy:logic      # Deploy logic implementations only  
yarn deploy:proxies    # Deploy proxy contracts only
yarn deploy:config     # Setup configuration only
```

**Benefits of TypeScript Deployment:**
- ✅ Automatically saves contract addresses to `deployments/addresses.json`
- ✅ Handles terminal errors gracefully
- ✅ Provides deployment summary with gas usage
- ✅ Maintains deployment history (last 10 deployments)

### Building and Testing

#### Build All Contracts
```bash
yarn build
```

#### Run Tests
```bash
yarn test
```

#### Clean Build Artifacts
```bash
yarn clean
```

### Deployment Status and Verification

View deployment history and addresses:
```bash
cat deployments/latest.json      # Latest deployment
cat deployments/addresses.json   # All deployment history
```

## Environment Variables

Ensure these environment variables are set:
- `PRIVATE_KEY` - Deployer private key (required)
- `RPC_URL` - Network RPC URL (optional for yarn scripts, they have defaults)

## Network Configuration

### Lisk Networks
- **Lisk Sepolia (Testnet)**: `https://rpc.sepolia-api.lisk.com`
- **Lisk Mainnet**: `https://rpc.api.lisk.com`

### Contract Addresses

#### Lisk Sepolia Testnet (Latest Deployment)
```json
{
  "deployer": "0xaBeBC6283d1b32298D67c745da88DAD288A35c06",
  "timestamp": "2025-07-02T06:07:50.536Z",
  "proxies": {
    "facade": "0x114C61A1d7D95340D7ACb83aB9AAe26A5dcAc2AD",
    "nodeLogic": "0x010D285126f497cEaBA16B2c3e3B1258a19c1679",
    "userLogic": "0x9B135fB590b5545DD43517142d9B0E44eA222f1d",
    "resourceLogic": "0xfF1Ef0c1933DA7d90bf5BB6e20ed8e0331ad3e53"
  }
}
```

**Main Entry Point**: `0x114C61A1d7D95340D7ACb83aB9AAe26A5dcAc2AD` (QuikFacade Proxy)

## Configuration

Update `QuikDBConfig.sol` with network-specific addresses:
- `NODE_OPERATOR_ADDRESS` - Address for node operator role
- `UPGRADER_ADDRESS` - Address for upgrader role

## Features

### Error Handling
- Comprehensive validation of required addresses
- Try-catch blocks for graceful error handling
- Detailed logging of success/failure states

### State Management
- Automatic state tracking between stages
- Address validation to prevent deployment errors
- Stage completion tracking

### Verification
- Built-in deployment verification
- Contract configuration validation
- Role assignment verification

### Modularity
- Separate contracts for each deployment concern
- Reusable base functionality
- Clean separation of responsibilities

## Gas Optimization

The modular approach allows for:
- Smaller individual transactions
- Better gas estimation per stage
- Ability to retry failed stages without redeploying successful ones

## Security Considerations

- All contracts inherit from `BaseDeployment` for consistent security patterns
- Address validation prevents zero-address assignments
- Role-based access control setup is automated and verified
- Deployment verification ensures proper configuration

## Troubleshooting

If a stage fails:
1. Check the console logs for specific error messages
2. Verify all required addresses are set for the stage
3. Ensure sufficient gas limit for the transaction
4. Check that previous stages completed successfully

## Legacy Compatibility

The original `DeployQuikDBSplitLogicToLiskInStages.s.sol` has been refactored into this modular system while maintaining the same deployment logic and outcomes.
