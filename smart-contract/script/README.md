# QuikDB Deployment on Lisk Blockchain

This directory contains deployment scripts for the QuikDB nodes contract system on the Lisk blockchain. The contracts implement a transparent upgradeable proxy pattern to allow for future upgrades without losing state.

## Scripts Overview

1. `DeployQuikDBProxy.s.sol` - General deployment script for the QuikDB contracts
2. `DeployQuikDBToLisk.s.sol` - Specialized deployment script for the Lisk blockchain
3. `UpgradeQuikDBOnLisk.s.sol` - Script for upgrading the QuikDB contracts after initial deployment

## Contract Architecture

The system consists of:

- Storage contracts:

  - `NodeStorage.sol`: Manages node information and registrations
  - `UserStorage.sol`: Manages user profiles
  - `ResourceStorage.sol`: Manages compute and storage resources

- Proxy contracts:

  - `QuikProxy.sol`: The transparent proxy that delegates calls to the logic implementation
  - `QuikProxyAdmin.sol`: Admin contract for managing proxy upgrades

- Logic contract:
  - `QuikLogic.sol`: Contains the business logic that interacts with the storage contracts

## Deployment Instructions

### Prerequisites

1. Install Foundry if not already installed:

   ```
   curl -L https://foundry.paradigm.xyz | bash
   foundryup
   ```

2. Ensure you have the Lisk RPC URL:

   ```
   export LISK_RPC_URL=https://your-lisk-rpc-url
   ```

3. Set up your deployer private key:
   ```
   export PRIVATE_KEY=your_private_key
   ```

### Initial Deployment

To deploy the contracts to the Lisk blockchain:

1. Update the configuration in `DeployQuikDBToLisk.s.sol` with appropriate addresses for:

   - `admin`
   - `nodeOperator`
   - `upgrader`

2. Run the deployment script:

   ```
   forge script script/DeployQuikDBToLisk.s.sol:DeployQuikDBToLisk \
     --rpc-url $LISK_RPC_URL \
     --private-key $PRIVATE_KEY \
     --broadcast \
     --verify
   ```

3. Save the deployed contract addresses from the console output for future reference.

### Upgrading the Contracts

To upgrade the contracts after initial deployment:

1. Update `UpgradeQuikDBOnLisk.s.sol` with the saved addresses from the initial deployment:

   - `PROXY_ADDRESS`
   - `PROXY_ADMIN_ADDRESS`

2. Run the upgrade script:
   ```
   forge script script/UpgradeQuikDBOnLisk.s.sol:UpgradeQuikDBOnLisk \
     --rpc-url $LISK_RPC_URL \
     --private-key $PRIVATE_KEY \
     --broadcast
   ```

## Contract Verification

After deployment, verify your contracts on the Lisk blockchain explorer:

```
forge verify-contract \
  --chain-id lisk_chain_id \
  --compiler-version 0.8.20 \
  --constructor-args $(cast abi-encode "constructor(address)" "0xYourAdminAddress") \
  <DEPLOYED_ADDRESS> \
  src/proxy/QuikProxy.sol:QuikProxy
```

Repeat for each deployed contract, adjusting the constructor arguments as needed.

## Security Considerations

- Ensure the admin address is a secure multi-sig wallet for production deployments
- Carefully manage the UPGRADER_ROLE to prevent unauthorized upgrades
- Test thoroughly in a test environment before deploying to production
- Consider a timelock mechanism for upgrades in production environments

## Maintenance

After deployment, regular maintenance may include:

1. Monitoring contract usage and performance
2. Preparing and testing upgrades as needed
3. Executing upgrades through the proxy admin
4. Verifying new implementations are working correctly
