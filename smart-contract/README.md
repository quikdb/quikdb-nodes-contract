## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
yarn build
```

### Test

```shell
yarn test
```

### Format

```shell
yarn format
```

### Clean

```shell
yarn clean
```

### Gas Snapshots

```shell
yarn snapshot
```

## QuikDB Deployment & Validation

### Prerequisites

```shell
yarn install
```

Create a `.env` file with your deployment configuration:
```shell
PRIVATE_KEY=your_private_key_here
RPC_URL=https://rpc.sepolia-api.lisk.com  # For Lisk Sepolia testnet
```

### Deployment Scripts

Deploy QuikDB smart contracts using the modern TypeScript deployment controller:

#### Lisk Testnet Deployment
```shell
yarn deploy:lsk:testnet       # Deploy to Lisk Sepolia testnet
```

#### Lisk Mainnet Deployment  
```shell
yarn deploy:lsk:mainnet       # Deploy to Lisk mainnet
```

#### Local/Simulation Deployment
```shell
yarn deploy:complete          # Local simulation (no broadcast)
```

### Validation Scripts

After deployment, validate the contracts are working correctly:

#### Lisk Testnet Validation
```shell
yarn validate:lsk:testnet     # Validate deployment on Lisk Sepolia
```

#### Lisk Mainnet Validation
```shell
yarn validate:lsk:mainnet     # Validate deployment on Lisk mainnet
```

#### Generic Validation
```shell
yarn validate                 # Shows available validation options
```

### Deployment Output

All deployments automatically:
- ✅ Save contract addresses to `deployments/addresses.json` (historical record)
- ✅ Save latest deployment to `deployments/latest.json` (current deployment)
- ✅ Create deployment logs with full transaction details
- ✅ Show deployment summary with all contract addresses
- ✅ Configure access control and proxy setup
- ✅ Provide blockchain explorer links for verification

### Validation Features

The validation script performs comprehensive testing:
- ✅ **Contract Connectivity** - Verifies all contracts are responsive
- ✅ **Node Operations** - Tests node registration, status updates, and listing
- ✅ **User Operations** - Tests user registration and profile management
- ✅ **Facade Operations** - Tests main contract interface and delegation
- ✅ **Access Control** - Verifies role-based permissions
- ✅ **Data Integrity** - Checks cross-contract consistency
- ✅ **Cleanup & Safety** - Handles existing test data gracefully
- ✅ **Blockchain Explorer Links** - Provides verification links for all contracts

### Blockchain Explorer Integration

After deployment and validation, you'll receive direct links to verify contracts on:
- **Lisk Sepolia**: https://sepolia-blockscout.lisk.com
- **Lisk Mainnet**: https://blockscout.lisk.com

Links include:
- All deployed contract addresses
- Deployer address with transaction history
- Test data for validation verification

### Main Contract Addresses

After deployment, use the **proxy addresses** for your applications:
- **QuikFacade Proxy** - Main entry point for the QuikDB system
- **QuikNodeLogic Proxy** - Node management interface
- **QuikUserLogic Proxy** - User management interface  
- **QuikResourceLogic Proxy** - Resource management interface

See `deployments/latest.json` for the complete list of deployed contract addresses.

### Help

```shell
yarn --help           # Yarn commands
forge --help          # Forge-specific options (advanced usage)
anvil --help          # Local node options
cast --help           # Ethereum interaction tool
```

### Available Yarn Scripts

View all available scripts:
```shell
yarn run
```

Key scripts include:
- `yarn build` - Compile contracts
- `yarn test` - Run tests
- `yarn deploy:lsk:testnet` - Deploy to Lisk Sepolia testnet
- `yarn deploy:lsk:mainnet` - Deploy to Lisk mainnet
- `yarn deploy:complete` - Local deployment simulation
- `yarn validate:lsk:testnet` - Validate Lisk Sepolia deployment
- `yarn validate:lsk:mainnet` - Validate Lisk mainnet deployment

### Architecture

The QuikDB system uses a modern proxy-based architecture:

**Storage Layer:**
- `NodeStorage` - Node data and metadata
- `UserStorage` - User profiles and authentication
- `ResourceStorage` - Resource allocation tracking

**Logic Layer (Upgradeable Proxies):**
- `NodeLogic` - Node management operations
- `UserLogic` - User management operations  
- `ResourceLogic` - Resource management operations
- `Facade` - Main entry point and unified interface

**Infrastructure:**
- `ProxyAdmin` - Proxy upgrade management
- Direct, reliable deployment with TypeScript controller
- Comprehensive validation with real contract operations
