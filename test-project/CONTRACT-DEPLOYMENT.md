# QuikDB Nodes SDK Contract Deployment Guide

## Current Status

The test script (`test.js`) is attempting to connect to contracts at the following addresses:

```
NODE_STORAGE_ADDRESS    = 0x5FbDB2315678afecb367f032d93F642f64180aa3
USER_STORAGE_ADDRESS    = 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
RESOURCE_STORAGE_ADDRESS = 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0
```

These addresses appear to be from a local development environment (Hardhat/Foundry) rather than actual contracts deployed on Lisk Sepolia. When running the test script against the Lisk Sepolia network, we see that:

1. Contracts exist at these addresses, but they are not the intended contracts
2. Function calls revert with "execution reverted" errors
3. The contracts don't have the methods that the SDK expects

## Deployment Options

### Option 1: Deploy the contracts to Lisk Sepolia

1. Navigate to the smart contract directory:

   ```bash
   cd ../smart-contract
   ```

2. Use the deployment script to deploy to Lisk Sepolia:

   ```bash
   forge script script/DeployQuikDBToLisk.s.sol --rpc-url https://rpc.sepolia-api.lisk.com --broadcast --verify
   ```

   You'll need a funded account and the appropriate environment variables set up.

3. Note the deployed contract addresses from the output.

4. Update the test script with these addresses:
   ```javascript
   const NODE_STORAGE_ADDRESS = "0x..."; // New address from deployment
   const USER_STORAGE_ADDRESS = "0x..."; // New address from deployment
   const RESOURCE_STORAGE_ADDRESS = "0x..."; // New address from deployment
   ```

### Option 2: Use a local development environment for testing

1. Set up a local Anvil or Hardhat node:

   ```bash
   anvil
   # or
   npx hardhat node
   ```

2. Deploy the contracts locally:

   ```bash
   cd ../smart-contract
   forge script script/DeployQuikDBToLisk.s.sol --rpc-url http://localhost:8545 --broadcast
   ```

3. Update the test script to connect to the local network instead of Lisk Sepolia:
   ```javascript
   const provider = new ethers.JsonRpcProvider("http://localhost:8545");
   ```

### Option 3: Update the SDK to match existing contracts

If the contracts are already deployed on Lisk Sepolia with different interfaces:

1. Obtain the ABIs of the deployed contracts using a block explorer or by extracting them from the deployment artifacts.

2. Update the ABI files in the SDK:

   ```bash
   cp new-abis/NodeStorage.json ../sdk/src/abis/
   cp new-abis/UserStorage.json ../sdk/src/abis/
   cp new-abis/ResourceStorage.json ../sdk/src/abis/
   ```

3. Rebuild the SDK:

   ```bash
   cd ../sdk
   npm run build
   npm pack
   ```

4. Reinstall the updated SDK in your test project:
   ```bash
   cd ../test-project
   npm install ../sdk/quikdb-nodes-sdk-1.0.0.tgz
   ```

## Verifying Contract Deployment

After following one of the options above, run the test script again:

```bash
node test.js
```

If the contracts are correctly deployed and the SDK is properly configured, you should see successful function calls without revert errors.

## Additional Help

For more detailed guidance on deploying contracts to Lisk Sepolia, refer to:

- The smart contract README: `../smart-contract/README.md`
- The deployment scripts: `../smart-contract/script/`
