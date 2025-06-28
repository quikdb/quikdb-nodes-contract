/**
 * Example for a storage provider node operator
 * This example demonstrates:
 * 1. Node registration as a storage provider
 * 2. Creating storage resource listings
 * 3. Managing storage node metrics
 */
import { QuikDBNodesSDK } from "../src/QuikDBNodesSDK";
import { NodeStatus, NodeTier, ProviderType } from "../src/types/node.types";
import { QuikDBUtils } from "../src/utils";
import dotenv from "dotenv";
import path from "path";

// Load environment variables from .env file in examples directory
dotenv.config({ path: path.resolve(__dirname, ".env") });

async function main() {
  // Initialize the SDK with values from environment variables
  const sdk = new QuikDBNodesSDK({
    provider: process.env.RPC_URL || "https://rpc.lisk.io",
    nodeStorageAddress:
      process.env.NODE_STORAGE_ADDRESS ||
      "0x1234567890123456789012345678901234567890",
    userStorageAddress:
      process.env.USER_STORAGE_ADDRESS ||
      "0x0987654321098765432109876543210987654321",
    resourceStorageAddress:
      process.env.RESOURCE_STORAGE_ADDRESS ||
      "0x2468101214161820222426283032343638404244",
    privateKey: process.env.PRIVATE_KEY, // Private key from .env file
  });

  try {
    // Step 1: Register your storage node
    console.log("Step 1: Registering a new storage node");
    const nodeId = `storage-node-${Date.now()}`;
    const nodeAddress = await sdk.signer!.getAddress();

    console.log(`Registering node ID: ${nodeId}`);
    console.log(`Node operator address: ${nodeAddress}`);

    const registerTx = await sdk.node.registerNode(
      nodeId,
      nodeAddress,
      NodeTier.STANDARD, // STANDARD tier node
      ProviderType.STORAGE // STORAGE type provider
    );

    console.log(`Node registration submitted: ${registerTx.hash}`);
    const receipt = await registerTx.wait();
    console.log(`Transaction confirmed in block ${receipt.blockNumber}`);

    // Step 2: Update node capacity (focused on storage)
    console.log("\nStep 2: Setting node capacity");
    const capacityTx = await sdk.node.updateNodeCapacity(
      nodeId,
      4, // 4 CPU cores
      16, // 16 GB memory
      8192, // 8 TB (8192 GB) storage
      500, // 500 Mbps network
      0, // No GPUs
      "" // No GPU type
    );

    console.log(`Capacity update submitted: ${capacityTx.hash}`);
    await capacityTx.wait();
    console.log("Node capacity updated successfully");

    // Step 3: Create a storage resource listing
    console.log("\nStep 3: Creating storage listing");
    const pricePerGBMonth = QuikDBUtils.toWei("0.0001"); // 0.0001 ETH per GB per month

    const listingId = await sdk.resource.createStorageListing(
      nodeId,
      NodeTier.STANDARD,
      8192, // Capacity in GB
      3, // Redundancy factor (3x replication)
      pricePerGBMonth.toString(),
      "eu-central-1", // Region
      "SSD" // Storage type
    );

    console.log(`Storage listing created with ID: ${listingId}`);

    // Step 4: Set extended node information
    console.log("\nStep 4: Setting extended node information");
    const hardwareFingerprint = QuikDBUtils.generateRandomId();

    const extendedInfoTx = await sdk.node.updateNodeExtendedInfo(
      nodeId,
      hardwareFingerprint,
      450, // Carbon footprint score (lower is better)
      ["GDPR", "ISO27001"], // Compliance certifications
      850, // Security score out of 1000
      "Professional storage provider with 5+ years experience",
      ["Encryption-at-rest", "Hot-swappable-drives"],
      QuikDBUtils.toWei("2.0").toString(), // 2.0 ETH bond amount
      true, // Verified
      Math.floor(Date.now() / 1000) + 365 * 24 * 60 * 60, // Verification expiry (1 year)
      "encrypted:contact-info-hash" // Encrypted contact information
    );

    console.log(`Extended info update submitted: ${extendedInfoTx.hash}`);
    await extendedInfoTx.wait();
    console.log("Extended node information updated successfully");

    // Step 5: Set the node status to ACTIVE
    console.log("\nStep 5: Setting node status to ACTIVE");
    const statusTx = await sdk.node.updateNodeStatus(nodeId, NodeStatus.ACTIVE);

    console.log(`Status update submitted: ${statusTx.hash}`);
    await statusTx.wait();
    console.log("Node is now ACTIVE");

    // Step 6: Update node metrics periodically (simulating a real node)
    console.log("\nStep 6: Updating node metrics");
    const metricsTx = await sdk.node.updateNodeMetrics(
      nodeId,
      9980, // 99.80% uptime
      0, // No jobs yet (new node)
      0, // No successful jobs yet
      "0", // No earnings yet
      Math.floor(Date.now() / 1000), // Current timestamp as last heartbeat
      120 // 120ms average response time
    );

    console.log(`Metrics update submitted: ${metricsTx.hash}`);
    await metricsTx.wait();
    console.log("Node metrics updated successfully");

    // Step 7: Verify your node information
    console.log("\nStep 7: Verifying node information");
    const nodeInfo = await sdk.node.getNodeInfo(nodeId);

    console.log("Node Information:");
    console.log(`- Node ID: ${nodeInfo.nodeId}`);
    console.log(`- Status: ${NodeStatus[nodeInfo.status]}`);
    console.log(`- Tier: ${NodeTier[nodeInfo.tier]}`);
    console.log(`- Provider Type: ${ProviderType[nodeInfo.providerType]}`);
    console.log("- Capacity:");
    console.log(`  - Storage: ${nodeInfo.capacity.storageGB} GB`);
    console.log(`  - Network: ${nodeInfo.capacity.networkMbps} Mbps`);

    console.log(
      "\nYour storage node has been successfully registered and listed!"
    );
    console.log("You can now receive storage allocations from QuikDB users.");
  } catch (error) {
    console.error("Error:", error.message);
  }
}

// Run the example
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
