# QuikDB Deployment Scripts

This directory contains a modular deployment system for the QuikDB smart contracts, organized into logical stages for better maintainability and flexibility.

## Architecture

### Base Contracts
- **`base/BaseDeployment.sol`** - Base contract with common deployment utilities and state management

### Stage Contracts
- **`stages/StorageDeployment.sol`** - Deploys storage contracts (NodeStorage, UserStorage, ResourceStorage)
- **`stages/LogicDeployment.sol`** - Deploys logic implementation contracts
- **`stages/ProxyDeployment.sol`** - Deploys proxy infrastructure and proxy contracts
- **`stages/ConfigurationSetup.sol`** - Handles final configuration and access control

### Orchestrator
- **`QuikDBDeploymentOrchestrator.sol`** - Main orchestrator that coordinates all deployment stages
- **`QuikDBSimpleDeployments.sol`** - Simplified entry points for common deployment scenarios

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

## Usage

### Complete Deployment
Deploy the entire QuikDB system in one transaction:
```bash
forge script script/QuikDBSimpleDeployments.sol:DeployCompleteQuikDB --broadcast --rpc-url $RPC_URL
```

### Staged Deployment
Deploy in logical groups:

1. **Storage Layer**:
```bash
forge script script/QuikDBSimpleDeployments.sol:DeployStorage --broadcast --rpc-url $RPC_URL
```

2. **Logic Layer**:
```bash
forge script script/QuikDBSimpleDeployments.sol:DeployLogic --broadcast --rpc-url $RPC_URL
```

3. **Proxy Layer**:
```bash
forge script script/QuikDBSimpleDeployments.sol:DeployProxies --broadcast --rpc-url $RPC_URL
```

4. **Configuration**:
```bash
forge script script/QuikDBSimpleDeployments.sol:SetupConfiguration --broadcast --rpc-url $RPC_URL
```

### Individual Stage Deployment
For fine-grained control, deploy individual stages:
```bash
# Deploy only storage contracts
forge script script/QuikDBDeploymentOrchestrator.sol --sig "deploySingleStage(uint8)" 0 --broadcast --rpc-url $RPC_URL

# Deploy only logic implementations
forge script script/QuikDBDeploymentOrchestrator.sol --sig "deploySingleStage(uint8)" 1 --broadcast --rpc-url $RPC_URL
```

## Environment Variables

Ensure these environment variables are set:
- `PRIVATE_KEY` - Deployer private key
- `RPC_URL` - Network RPC URL

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
