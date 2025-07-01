# QuikDB Nodes SDK Test Project

This project demonstrates how to use the QuikDB Nodes SDK to interact with the QuikDB Nodes contracts deployed on Lisk Sepolia.

## Setup

1. Create a `.env` file based on the `.env.example` file:

   ```bash
   cp .env.example .env
   ```

2. Edit the `.env` file and replace `your_private_key_here` with your actual test wallet private key. Make sure this wallet has test ETH on Lisk Sepolia.

   **WARNING: Never use a wallet with real funds for testing purposes!**

3. Verify the contract addresses in the `.env` file match your actual deployment.

## Running the Test

Execute the test script to verify connectivity with the QuikDB Nodes contracts:

```bash
npm test
```

This will:

1. Connect to the Lisk Sepolia network
2. Check if the contracts exist and are accessible
3. Verify if your wallet has the necessary permissions
4. Attempt to register a test node if permissions are granted

## Troubleshooting

If you encounter issues:

1. Make sure your wallet has sufficient test ETH
2. Verify that the contract addresses are correct
3. Check if your wallet has the necessary roles (LOGIC_ROLE or ADMIN_ROLE)
4. Refer to `CONTRACT-DEPLOYMENT.md` for more detailed deployment instructions

## Additional Documentation

- `CONTRACT-DEPLOYMENT.MD`: Information about deploying the contracts
- `PROXY-CONTRACTS.MD`: Details about the proxy pattern used in the contracts
