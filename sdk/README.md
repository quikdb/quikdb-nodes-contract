# QuikDB Nodes SDK

A TypeScript SDK for interacting with QuikDB Nodes smart contracts on the Lisk blockchain. This SDK provides a simple and intuitive interface for developers to interact with NodeStorage, UserStorage, and ResourceStorage contracts.

## Features

- TypeScript support with full type definitions
- Modern ES module and CommonJS support
- Comprehensive API for all QuikDB Node operations
- Built on ethers.js v6 for reliable blockchain interactions
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

// Initialize the SDK
const sdk = new QuikDBNodesSDK({
  provider: "https://rpc.sepolia-api.lisk.com",
  nodeStorageAddress: "0xYourNodeStorageContractAddress",
  userStorageAddress: "0xYourUserStorageContractAddress",
  resourceStorageAddress: "0xYourResourceStorageContractAddress",
  privateKey: "0xYourPrivateKey", // Optional, for transactions
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

### Custom Signers and Providers

For advanced blockchain interactions:

```typescript
import { ethers } from "ethers";
import { QuikDBNodesSDK } from "quikdb-nodes-sdk";

// Use a custom provider (e.g., with WebSockets)
const wsProvider = new ethers.WebSocketProvider("wss://ws.lisk.io");
const sdk = new QuikDBNodesSDK({
  provider: wsProvider,
  // other config...
});

// Use MetaMask or other wallet providers
const provider = new ethers.BrowserProvider(window.ethereum);
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

### Starting a Local Blockchain for Testing

For integration testing or local development:

```bash
# Using Anvil (Foundry)
anvil --chain-id 31337

# Using Hardhat
npx hardhat node
```

Then deploy the contracts to your local blockchain:

```bash
# From the project root
cd smart-contract
forge script script/DeployQuikDBToLisk.s.sol --broadcast --rpc-url http://localhost:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

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
