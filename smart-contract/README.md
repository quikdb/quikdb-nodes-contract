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

## QuikDB Deployment

### Prerequisites

```shell
yarn install
```

### Deployment Scripts

Deploy QuikDB smart contracts using the automated TypeScript deployment scripts:

#### Local/Simulation Deployment
```shell
yarn deploy:complete          # Local simulation (no broadcast)
```

#### Lisk Testnet Deployment
```shell
yarn deploy:lsk:testnet       # Deploy to Lisk Sepolia testnet
```

#### Lisk Mainnet Deployment
```shell
yarn deploy:lsk:mainnet       # Deploy to Lisk mainnet
```

#### Staged Deployment
```shell
yarn deploy:storage           # Deploy only storage contracts
yarn deploy:logic             # Deploy only logic implementations
yarn deploy:proxies           # Deploy proxy infrastructure
yarn deploy:config            # Setup configuration and access control
```

### Deployment Output

All deployments automatically:
- ✅ Save contract addresses to `deployments/addresses.json`
- ✅ Create deployment logs
- ✅ Show deployment summary with all contract addresses
- ✅ Save latest deployment to `deployments/latest.json`

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
- `yarn deploy:lsk:testnet` - Deploy to Lisk Sepolia
- `yarn deploy:lsk:mainnet` - Deploy to Lisk mainnet
- `yarn deploy:complete` - Local deployment simulation
