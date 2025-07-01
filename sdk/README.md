# QuikDB Nodes SDK

A TypeScript SDK for interacting with QuikDB Nodes smart contracts on the Lisk blockchain (Sepolia testnet). This SDK provides a simple and intuitive interface for developers to interact with NodeStorage, UserStorage, and ResourceStorage contracts deployed on the Lisk Sepolia blockchain.

[![npm version](https://img.shields.io/npm/v/quikdb-nodes-sdk.svg?style=flat-square)](https://www.npmjs.com/package/quikdb-nodes-sdk)
[![npm downloads](https://img.shields.io/npm/dm/quikdb-nodes-sdk.svg?style=flat-square)](https://www.npmjs.com/package/quikdb-nodes-sdk)
[![MIT License](https://img.shields.io/npm/l/quikdb-nodes-sdk.svg?style=flat-square)](https://opensource.org/licenses/MIT)

## Features

- TypeScript support with full type definitions
- Modern ES module and CommonJS support
- Comprehensive API for all QuikDB Node operations
- Built on ethers.js v6 for reliable blockchain interactions
- Direct connection to Lisk Sepolia blockchain
- Streamlined error handling and logging
- Extensive documentation and examples
- Integration with Lisk blockchain for decentralized resource management
- Support for both compute and storage resource providers
- Utility functions for common blockchain operations

## Installation

```bash
npm install quikdb-nodes-sdk
# or
yarn add quikdb-nodes-sdk
```

## Quick Start

```typescript
import { QuikDBNodesSDK } from "quikdb-nodes-sdk";
import { NodeStatus, NodeTier, ProviderType } from "quikdb-nodes-sdk/types";
import { QuikDBUtils } from "quikdb-nodes-sdk/utils";

// Initialize the SDK with Lisk Sepolia network
const sdk = new QuikDBNodesSDK({
  // Lisk Sepolia RPC endpoint
  provider: "https://rpc.sepolia-api.lisk.com",
  // Deployed contract addresses on Lisk Sepolia network
  nodeStorageAddress: "0x123456789AbCdEf123456789AbCdEf123456789A", // Replace with actual contract address
  userStorageAddress: "0x987654321FeDcBa987654321FeDcBa987654321F", // Replace with actual contract address
  resourceStorageAddress: "0xAbCdEf123456789AbCdEf123456789AbCdEf1234", // Replace with actual contract address
  // Optional private key for signing transactions
  privateKey: "0xYourPrivateKey",
});

// Get node information
async function getNodeInfo() {
  try {
    const nodeInfo = await sdk.node.getNodeInfo("node-123");
    console.log(`Node Status: ${NodeStatus[nodeInfo.status]}`);
    console.log(`Node Tier: ${NodeTier[nodeInfo.tier]}`);
    console.log(`Provider Type: ${ProviderType[nodeInfo.providerType]}`);
    console.log(
      `Hourly Rate: ${QuikDBUtils.formatPrice(nodeInfo.listing.hourlyRate)}`
    );
  } catch (error) {
    console.error("Error:", error.message);
  }
}

// Register a node
async function registerNode() {
  try {
    const tx = await sdk.node.registerNode(
      "new-node-123",
      "0xNodeOperatorAddress",
      NodeTier.STANDARD,
      ProviderType.COMPUTE
    );

    console.log(`Transaction hash: ${tx.hash}`);
    const receipt = await tx.wait();
    console.log(`Node registered in block ${receipt.blockNumber}`);

    // Update node capacity
    await sdk.node.updateNodeCapacity(
      "new-node-123",
      8, // 8 CPU cores
      32, // 32 GB memory
      512, // 512 GB storage
      1000, // 1000 Mbps network
      1, // 1 GPU
      "NVIDIA RTX 3080"
    );
  } catch (error) {
    console.error("Error:", error.message);
  }
}
```

## Architecture

The SDK is organized into modules, each handling a specific aspect of the QuikDB Nodes ecosystem:

- **NodeModule**: For node registration, status updates, and information retrieval
- **UserModule**: For user registration, profile management, and user data
- **ResourceModule**: For resource listings, allocations, and marketplace interactions

Each module provides a comprehensive set of methods to interact with the corresponding smart contract.

## Examples

The SDK includes several example implementations to help you get started:

### Connecting to Lisk Sepolia Blockchain

The SDK is designed to connect to the Lisk Sepolia blockchain. Here's how to properly configure your connection:

```typescript
import { QuikDBNodesSDK } from "quikdb-nodes-sdk";
import { ethers } from "ethers";

// Option 1: Connect using RPC URL string
const sdk = new QuikDBNodesSDK({
  provider: "https://rpc.sepolia-api.lisk.com",
  // Deployed contract addresses on Lisk Sepolia network
  nodeStorageAddress: "0x123456789AbCdEf123456789AbCdEf123456789A",
  userStorageAddress: "0x987654321FeDcBa987654321FeDcBa987654321F",
  resourceStorageAddress: "0xAbCdEf123456789AbCdEf123456789AbCdEf1234",
  privateKey: process.env.PRIVATE_KEY, // Load from environment variable
});

// Option 2: Connect using ethers provider with custom settings
const provider = new ethers.JsonRpcProvider(
  "https://rpc.sepolia-api.lisk.com",
  {
    name: "lisk-sepolia",
    chainId: 4202, // Lisk Sepolia chainId
  }
);

// Manually create wallet
const wallet = new ethers.Wallet(process.env.PRIVATE_KEY, provider);

const sdk = new QuikDBNodesSDK({
  provider: provider,
  nodeStorageAddress: "0x123456789AbCdEf123456789AbCdEf123456789A",
  userStorageAddress: "0x987654321FeDcBa987654321FeDcBa987654321F",
  resourceStorageAddress: "0xAbCdEf123456789AbCdEf123456789AbCdEf1234",
  signer: wallet, // Directly pass a signer
});
```

> Note: For development and testing purposes only, the SDK includes mock modules that can be imported from "quikdb-nodes-sdk/dist/mocks". These are not intended for production use.

### Using Pagination

The SDK supports pagination for fetching lists of nodes, users, and resources:

```typescript
// Get a paginated list of compute listings
const listings = await sdk.resource.getComputeListings(
  0, // page number (0-indexed)
  10, // page size
  {
    // optional filters
    region: "us-east",
    minCpuCores: 8,
    isActive: true,
  }
);

console.log(`Total listings: ${listings.totalListings}`);
console.log(
  `Current page: ${listings.currentPage + 1} of ${listings.totalPages}`
);

// Navigate to next page if available
if (listings.hasNextPage) {
  const nextPage = await sdk.resource.getComputeListings(1, 10, {
    region: "us-east",
  });
}
```

### Basic Usage

The [basic-usage.ts](./examples/basic-usage.ts) example demonstrates core functionality:

- Initializing the SDK
- Getting node information
- Registering a user
- Getting user profile
- Creating a compute listing

### Compute Provider

The [compute-provider.ts](./examples/compute-provider.ts) example shows how to:

- Register a compute node
- Update node capacity with CPU/GPU specifications
- Create a compute resource listing
- Add listing features
- Set the node to active status

### Storage Provider

The [storage-provider.ts](./examples/storage-provider.ts) example demonstrates:

- Registering a storage node
- Setting storage capacity
- Creating a storage listing with redundancy
- Setting extended node information
- Updating node metrics

### Resource Consumer

The [resource-consumer.ts](./examples/resource-consumer.ts) example shows how to:

- Register as a QuikDB consumer
- Search for available compute resources
- Search for available storage resources
- Filter resources by specification
- Book compute resources
- Allocate storage

## API Reference

### QuikDBNodesSDK

The main SDK class that provides access to all modules.

```typescript
constructor(config: {
  provider: string | ethers.Provider;
  nodeStorageAddress: string;
  userStorageAddress: string;
  resourceStorageAddress: string;
  privateKey?: string;
})
```

Properties:

- `node`: NodeModule instance
- `user`: UserModule instance
- `resource`: ResourceModule instance

Methods:

- `setSigner(signer: ethers.Signer): void` - Set a new signer for transactions
- `connect(provider: string | ethers.Provider): void` - Connect to a new provider

### NodeModule

Module for node registration, management, and information retrieval.

Key Methods:

- `getNodeInfo(nodeId: string): Promise<NodeInfo>` - Get information about a specific node
- `registerNode(nodeId: string, nodeAddress: string, tier: NodeTier, providerType: ProviderType): Promise<TransactionResponse>` - Register a new node
- `updateNodeStatus(nodeId: string, status: NodeStatus): Promise<TransactionResponse>` - Update node status
- `updateNodeCapacity(nodeId: string, cpuCores: number, memoryGB: number, storageGB: number, networkMbps: number, gpuCount: number, gpuType: string): Promise<TransactionResponse>` - Update node capacity
- `updateNodeListing(nodeId: string, isListed: boolean, hourlyRate: string, availability: number, region: string, supportedServices: string[], minJobDuration: number, maxJobDuration: number): Promise<TransactionResponse>` - Update node listing
- `updateNodeMetrics(nodeId: string, uptimePercentage: number, totalJobs: number, successfulJobs: number, totalEarnings: string, lastHeartbeat: number, avgResponseTime: number): Promise<TransactionResponse>` - Update node metrics
- `getTotalNodes(): Promise<number>` - Get total number of registered nodes

### UserModule

Module for user profile management and verification.

Key Methods:

- `getUserProfile(userAddress: string): Promise<UserProfile>` - Get user profile
- `registerUser(userAddress: string, profileHash: string, userType: UserType): Promise<TransactionResponse>` - Register a new user
- `updateUserStatus(userAddress: string, isActive: boolean): Promise<TransactionResponse>` - Update user status
- `updateUserProfile(userAddress: string, profileHash: string): Promise<TransactionResponse>` - Update user profile
- `getUserCount(): Promise<number>` - Get total number of registered users

### ResourceModule

Module for resource listings and allocations.

Key Methods:

- `getComputeListings(): Promise<ComputeListing[]>` - Get all compute listings
- `getStorageListings(): Promise<StorageListing[]>` - Get all storage listings
- `createComputeListing(nodeId: string, tier: number, cpuCores: number, memoryGB: number, storageGB: number, pricePerHour: string, region: string): Promise<string>` - Create a compute listing
- `createStorageListing(nodeId: string, tier: number, capacityGB: number, redundancyFactor: number, pricePerGBMonth: string, region: string, storageType: string): Promise<string>` - Create a storage listing
- `updateListingStatus(listingId: string, isActive: boolean): Promise<TransactionResponse>` - Update listing status
- `getTotalListings(): Promise<number>` - Get total number of resource listings

### QuikDBUtils

Static utility functions for common operations.

Key Methods:

- `toWei(ether: string | number): bigint` - Convert ether to wei
- `fromWei(wei: bigint | string): string` - Convert wei to ether
- `stringToBytes32(str: string): string` - Convert string to bytes32
- `bytes32ToString(bytes32: string): string` - Convert bytes32 to string
- `generateUniqueId(): string` - Generate unique ID
- `formatTimestamp(timestamp: number): string` - Format timestamp to readable string
- `calculateDurationHours(startTimestamp: number, endTimestamp: number): number` - Calculate duration in hours
- `formatPrice(weiAmount: string | bigint, decimals?: number): string` - Format a price with ETH units
- `calculateComputeCost(hourlyRate: string | bigint, hours: number): bigint` - Calculate compute resource cost
- `calculateStorageCost(pricePerGBMonth: string | bigint, sizeGB: number, months: number): bigint` - Calculate storage cost

## Production Use with Lisk Sepolia

### Connecting to the Production Lisk Sepolia Network

This SDK is specifically designed for use with the Lisk Sepolia blockchain. For production applications:

```typescript
import { QuikDBNodesSDK } from "quikdb-nodes-sdk";
import { ethers } from "ethers";
import * as dotenv from "dotenv";

// Load environment variables securely (in production)
dotenv.config();

// Create a production-ready SDK instance
const sdk = new QuikDBNodesSDK({
  // Lisk Sepolia RPC endpoint (consider using an API key provider for production)
  provider: process.env.LISK_SEPOLIA_RPC || "https://rpc.sepolia-api.lisk.com",

  // Deployed contract addresses (MUST be the addresses on Lisk Sepolia)
  nodeStorageAddress: process.env.NODE_STORAGE_ADDRESS,
  userStorageAddress: process.env.USER_STORAGE_ADDRESS,
  resourceStorageAddress: process.env.RESOURCE_STORAGE_ADDRESS,

  // Use secure wallet management for production
  privateKey: process.env.PRIVATE_KEY,
});
```

### Secure Deployment Practices

For production applications:

1. **Never hardcode private keys** - Always use environment variables
2. **Use secure RPC providers** - Consider using dedicated RPC endpoints with API keys
3. **Implement proper error handling** - Network issues can occur with blockchain interactions
4. **Consider rate limiting** - Prevent excessive contract calls
5. **Monitor gas prices** - To ensure transactions are processed efficiently
6. **Cache contract data** where appropriate to reduce blockchain calls

### IMPORTANT: Mock Modules Usage

Mock modules should **NEVER** be used in production applications. They are provided solely for:

- Unit testing
- Local development without a blockchain connection
- Demonstration and educational purposes

For production applications, always use the main SDK module with real Lisk Sepolia contract addresses.

## Advanced Usage

### Working with TypeScript Types

The SDK provides comprehensive TypeScript interfaces and enums for all contract types:

```typescript
import {
  NodeInfo,
  NodeStatus,
  NodeTier,
  ProviderType,
  NodeCapacity,
} from "quikdb-nodes-sdk/types";
import { UserProfile, UserType } from "quikdb-nodes-sdk/types";
import { ComputeListing, StorageListing } from "quikdb-nodes-sdk/types";

// Use enums for better readability
const selectedTier = NodeTier.PREMIUM;
const userRole = UserType.PROVIDER;

// Type checking for complex structures
function processNodeInfo(node: NodeInfo) {
  const capacity: NodeCapacity = node.capacity;
  console.log(`${capacity.cpuCores} CPU cores, ${capacity.memoryGB} GB memory`);
}
```

### Lisk Sepolia Blockchain Configuration

This SDK is specifically designed to interact with the Lisk Sepolia blockchain:

```typescript
import { ethers } from "ethers";
import { QuikDBNodesSDK } from "quikdb-nodes-sdk";
import * as dotenv from "dotenv";

// Load environment variables
dotenv.config();

// Lisk Sepolia network information
const LISK_SEPOLIA_RPC =
  process.env.LISK_SEPOLIA_RPC || "https://rpc.sepolia-api.lisk.com";
const LISK_SEPOLIA_CHAIN_ID = 4202; // Lisk Sepolia chain ID

// Connect to Lisk Sepolia
const provider = new ethers.JsonRpcProvider(LISK_SEPOLIA_RPC, {
  chainId: LISK_SEPOLIA_CHAIN_ID,
  name: "lisk-sepolia",
});

// Create wallet with private key
const wallet = new ethers.Wallet(process.env.PRIVATE_KEY || "", provider);

// Initialize the SDK with Lisk Sepolia connection
const sdk = new QuikDBNodesSDK({
  provider: provider,
  nodeStorageAddress: process.env.NODE_STORAGE_ADDRESS || "",
  userStorageAddress: process.env.USER_STORAGE_ADDRESS || "",
  resourceStorageAddress: process.env.RESOURCE_STORAGE_ADDRESS || "",
  signer: wallet,
});

// Now all interactions will happen on the Lisk Sepolia blockchain
```

### Custom Signers and Providers

For advanced blockchain interactions:

```typescript
import { ethers } from "ethers";
import { QuikDBNodesSDK } from "quikdb-nodes-sdk";

// Use a custom provider (e.g., with WebSockets)
const wsProvider = new ethers.WebSocketProvider(
  "wss://ws.sepolia-api.lisk.com"
);
const sdk = new QuikDBNodesSDK({
  provider: wsProvider,
  // other config...
});

// Use MetaMask or other wallet providers in a browser environment
const provider = new ethers.BrowserProvider(window.ethereum);
await provider.send("wallet_switchEthereumChain", [{ chainId: "0x106a" }]); // Switch to Lisk Sepolia (0x106a = 4202)
const signer = await provider.getSigner();
sdk.setSigner(signer);
```

### Advanced Error Handling

```typescript
try {
  await sdk.node.registerNode(/*...*/);
} catch (error) {
  if (error.code === "NETWORK_ERROR") {
    // Handle network issues
  } else if (error.reason?.includes("AlreadyRegistered")) {
    // Handle contract reverts
  } else if (error.message.includes("user rejected")) {
    // Handle user rejected transaction
  } else {
    console.error("General error:", error);
  }
}
```

## Testing

The SDK includes comprehensive unit and integration tests:

```bash
# Run unit tests
npm test

# Run tests with coverage
npm run test:coverage

# Run integration tests (requires local blockchain)
RUN_INTEGRATION_TESTS=true npm test
```

### Using the Lisk Sepolia Testnet

For development, testing, and production usage:

```bash
# Set up environment variables for connecting to Lisk Sepolia
export LISK_SEPOLIA_RPC="https://rpc.sepolia-api.lisk.com"
export LISK_SEPOLIA_CHAIN_ID=4202

# Deploy contracts to Lisk Sepolia (if needed)
cd smart-contract
forge script script/DeployQuikDBToLisk.s.sol --broadcast --rpc-url $LISK_SEPOLIA_RPC --chain-id $LISK_SEPOLIA_CHAIN_ID --private-key YOUR_PRIVATE_KEY
```

### Using Mock Modules for Local Development

For local development without blockchain connection, you can use the provided mock modules:

```typescript
// Import mock modules ONLY for testing/development
import {
  MockNodeModule,
  MockUserModule,
  MockResourceModule,
} from "quikdb-nodes-sdk/mocks";
import { ethers } from "ethers";

// Test setup with mock modules
const testProvider = new ethers.JsonRpcProvider();
const mockNode = new MockNodeModule(testProvider, "0xDummyAddress");

// Use mock module for testing
const result = await mockNode.getNodesList();
```

> ⚠️ **Warning**: Mock modules are provided for development and testing purposes only.
> Do not use them in production environments as they do not connect to any blockchain.

### NodeModule

Methods for interacting with `NodeStorage` contract:

- `getNodeInfo(nodeId: string): Promise<NodeInfo>`
- `registerNode(nodeId: string, nodeAddress: string, tier: NodeTier, providerType: ProviderType): Promise<TransactionResponse>`
- `updateNodeStatus(nodeId: string, status: NodeStatus): Promise<TransactionResponse>`
- `listNode(nodeId: string, hourlyRate: string, availability: number): Promise<TransactionResponse>`
- `updateNodeExtendedInfo(nodeId: string, extended: NodeExtendedInfo): Promise<TransactionResponse>`
- `setNodeCustomAttribute(nodeId: string, key: string, value: string): Promise<TransactionResponse>`
- `getNodeCustomAttribute(nodeId: string, key: string): Promise<string>`
- `addNodeCertification(nodeId: string, certificationId: string, details: string): Promise<TransactionResponse>`
- `getNodeCertifications(nodeId: string): Promise<string[]>`
- `getTotalNodes(): Promise<number>`
- `getNodesByTier(tier: NodeTier): Promise<string[]>`
- `getNodesByStatus(status: NodeStatus): Promise<string[]>`

### UserModule

Methods for interacting with `UserStorage` contract:

- `getUserProfile(userAddress: string): Promise<UserProfile>`
- `getUserInfo(userAddress: string): Promise<UserInfo>`
- `registerUser(userAddress: string, profileHash: string, userType: UserType): Promise<TransactionResponse>`
- `updateUserProfile(userAddress: string, profileHash: string): Promise<TransactionResponse>`
- `updateUserPreferences(userAddress: string, preferences: UserPreferences): Promise<TransactionResponse>`
- `getUserStats(userAddress: string): Promise<UserStats>`
- `getTotalUsers(): Promise<number>`
- `getUsersByType(userType: UserType): Promise<string[]>`

### ResourceModule

Methods for interacting with `ResourceStorage` contract:

- `createComputeListing(nodeId: string, tier: ComputeTier, cpuCores: number, memoryGB: number, storageGB: number, hourlyRate: string, region: string): Promise<string>`
- `createStorageListing(nodeId: string, tier: StorageTier, storageGB: number, hourlyRate: string, region: string): Promise<string>`
- `getComputeListing(listingId: string): Promise<ComputeListing>`
- `getStorageListing(listingId: string): Promise<StorageListing>`
- `purchaseCompute(listingId: string, duration: number, paymentAmount: string): Promise<string>`
- `getComputeAllocation(allocationId: string): Promise<ComputeAllocation>`
- `getTotalAllocations(): Promise<number>`

### Utilities

The SDK also includes utility functions in the `QuikDBUtils` class:

- `toWei(ether: string | number): bigint` - Convert ether amount to wei
- `fromWei(wei: bigint | string): string` - Convert wei to ether amount
- `stringToBytes32(str: string): string` - Convert string to bytes32
- `bytes32ToString(bytes32: string): string` - Convert bytes32 to string
- `generateUniqueId(): string` - Generate a unique identifier
- `formatTimestamp(timestamp: number): string` - Format a timestamp to human-readable date
- `calculateDurationHours(startTimestamp: number, endTimestamp: number): number` - Calculate duration in hours

## Enums

The SDK provides TypeScript enums to make working with contract constants easier:

```typescript
// Node-related enums
enum NodeStatus {
  PENDING,
  ACTIVE,
  INACTIVE,
  MAINTENANCE,
  SUSPENDED,
  DEREGISTERED,
  LISTED,
}

enum ProviderType {
  COMPUTE,
  STORAGE,
}

enum NodeTier {
  NANO,
  MICRO,
  BASIC,
  STANDARD,
  PREMIUM,
  ENTERPRISE,
}

// User-related enums
enum UserType {
  CONSUMER,
  PROVIDER,
  MARKETPLACE_ADMIN,
  PLATFORM_ADMIN,
}

// Resource-related enums
enum ComputeTier {
  NANO,
  MICRO,
  BASIC,
  STANDARD,
  PREMIUM,
  ENTERPRISE,
}

enum StorageTier {
  BASIC,
  FAST,
  PREMIUM,
  ARCHIVE,
}
```

## Examples

Check out the examples directory for more usage examples:

- Basic Usage
- Node Management
- User Registration
- Resource Marketplace

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
