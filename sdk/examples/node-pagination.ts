/**
 * Example for using node pagination functionality with mock data
 *
 * This example demonstrates:
 * 1. Getting a paginated list of nodes using a mock implementation
 * 2. Filtering nodes by different criteria
 * 3. Navigating through pages
 * 4. Using the MockNodeModule as a standalone module instead of the real NodeModule
 *
 * This approach allows testing without requiring a live blockchain connection
 */
import { QuikDBNodesSDK } from "../src/QuikDBNodesSDK";
import { NodeStatus, NodeTier, ProviderType } from "../src/types/node.types";
import { MockNodeModule } from "../src/modules/MockNodeModule";
import { ethers } from "ethers";
import * as dotenv from "dotenv";
import * as path from "path";

// Load environment variables from .env file in examples directory
dotenv.config({ path: path.resolve(__dirname, ".env") });

async function main() {
  // Create a local provider
  const provider = new ethers.JsonRpcProvider("http://localhost:8545");

  // Use a wallet with a hardcoded private key for testing
  const wallet = new ethers.Wallet(
    "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80",
    provider
  );

  // Sample contract addresses (these don't need to be real for this example)
  const nodeStorageAddress = "0x5FbDB2315678afecb367f032d93F642f64180aa3";
  const userStorageAddress = "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512";
  const resourceStorageAddress = "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0";

  // Create mock node module for testing
  const mockNodeModule = new MockNodeModule(
    provider,
    nodeStorageAddress,
    wallet
  );

  // Initialize the SDK with standard configuration
  const sdk = new QuikDBNodesSDK({
    provider: provider,
    nodeStorageAddress: nodeStorageAddress,
    userStorageAddress: userStorageAddress,
    resourceStorageAddress: resourceStorageAddress,
    privateKey: wallet.privateKey,
  });

  // Use the mock node module methods directly instead of replacing sdk.node
  const nodeModule = mockNodeModule;

  try {
    // Register a test node if needed (uncomment to create test data)
    /*
    console.log("Creating a test node for demonstration purposes...");
    const nodeId = `test-node-${Date.now()}`;
    const nodeAddress = await sdk.signer!.getAddress();
    await nodeModule.registerNode(
      nodeId,
      nodeAddress,
      NodeTier.STANDARD,
      ProviderType.COMPUTE
    );
    console.log(`Test node created with ID: ${nodeId}`);
    */

    console.log("Example 1: Getting nodes with pagination (default settings)");
    // Default pagination (first page, 10 items)
    const firstPage = await nodeModule.getNodesList();
    console.log(`Total nodes: ${firstPage.totalNodes}`);
    console.log(`Total pages: ${firstPage.totalPages}`);
    console.log(`Current page: ${firstPage.currentPage + 1}`); // +1 for human-readable page number
    console.log(`Has next page: ${firstPage.hasNextPage}`);
    console.log(`Has previous page: ${firstPage.hasPreviousPage}`);
    console.log(`Nodes on this page: ${firstPage.nodes.length}`);
    console.log("Node IDs:", firstPage.nodes);

    if (firstPage.nodes.length === 0) {
      console.log(
        "No nodes found. The blockchain may be empty or the contract address may be incorrect."
      );
      console.log(
        "You can uncomment the test node creation code above to create sample data."
      );
    } else {
      // Get details for the first node to show
      const firstNodeId = firstPage.nodes[0];
      const nodeDetails = await nodeModule.getNodeInfo(firstNodeId);
      console.log(`Details for first node ${firstNodeId}:`);
      console.log(`  Status: ${NodeStatus[nodeDetails.status]}`);
      console.log(`  Tier: ${NodeTier[nodeDetails.tier]}`);
      console.log(`  Provider Type: ${ProviderType[nodeDetails.providerType]}`);
      console.log(
        `  Hourly Rate: ${ethers.formatEther(
          nodeDetails.listing.hourlyRate
        )} ETH`
      );
    }
    console.log();

    // Only proceed if there are multiple pages
    if (firstPage.hasNextPage) {
      console.log("Example 2: Getting the second page");
      const secondPage = await nodeModule.getNodesList(1); // page 1 (second page)
      console.log(`Current page: ${secondPage.currentPage + 1}`);
      console.log(`Nodes on this page: ${secondPage.nodes.length}`);
      console.log("Node IDs:", secondPage.nodes);
      console.log();
    }

    console.log("Example 3: Custom page size (5 items per page)");
    const smallPage = await nodeModule.getNodesList(0, 5);
    console.log(`Total pages with 5 items per page: ${smallPage.totalPages}`);
    console.log(`Nodes on this page: ${smallPage.nodes.length}`);
    console.log("Node IDs:", smallPage.nodes);
    console.log();

    console.log("Example 4: Filtering by node status (ACTIVE only)");
    const activeNodes = await nodeModule.getNodesList(0, 10, {
      status: NodeStatus.ACTIVE,
    });
    console.log(`Total active nodes: ${activeNodes.totalNodes}`);
    console.log("Active Node IDs:", activeNodes.nodes);
    console.log();

    console.log("Example 5: Filtering by node tier (PREMIUM only)");
    const premiumNodes = await nodeModule.getNodesList(0, 10, {
      tier: NodeTier.PREMIUM,
    });
    console.log(`Total premium nodes: ${premiumNodes.totalNodes}`);
    console.log("Premium Node IDs:", premiumNodes.nodes);
    console.log();

    console.log("Example 6: Filtering by provider type (COMPUTE only)");
    const computeNodes = await nodeModule.getNodesList(0, 10, {
      providerType: ProviderType.COMPUTE,
    });
    console.log(`Total compute nodes: ${computeNodes.totalNodes}`);
    console.log("Compute Node IDs:", computeNodes.nodes);
    console.log();

    console.log("Example 7: Complex filtering (active storage nodes)");
    const activeStorageNodes = await nodeModule.getNodesList(0, 10, {
      providerType: ProviderType.STORAGE,
      isActive: true,
    });
    console.log(`Total active storage nodes: ${activeStorageNodes.totalNodes}`);
    console.log("Active storage Node IDs:", activeStorageNodes.nodes);
  } catch (error) {
    console.error("Error:", error);
  }
}

// Run the example
main().catch(console.error);
