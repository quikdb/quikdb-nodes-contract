/**
 * Example for a compute provider node operator
 * This example demonstrates:
 * 1. Node registration
 * 2. Creating compute resource listings
 * 3. Updating node capacity and status
 */
import { QuikDBNodesSDK } from "../src/QuikDBNodesSDK";
import {
  NodeStatus,
  NodeTier,
  ProviderType,
  ComputeTier,
} from "../src/types/node.types";
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
    // Step 1: Register your node
    console.log("Step 1: Registering a new compute node");
    const nodeId = `compute-node-${Date.now()}`;
    const nodeAddress = await sdk.signer!.getAddress();

    console.log(`Registering node ID: ${nodeId}`);
    console.log(`Node operator address: ${nodeAddress}`);

    const registerTx = await sdk.node.registerNode(
      nodeId,
      nodeAddress,
      NodeTier.STANDARD, // STANDARD tier node
      ProviderType.COMPUTE // COMPUTE type provider
    );

    console.log(`Node registration submitted: ${registerTx.hash}`);
    const receipt = await registerTx.wait();
    console.log(`Transaction confirmed in block ${receipt?.blockNumber}`);

    // Step 2: Update node capacity
    console.log("\nStep 2: Setting node capacity");
    const capacityTx = await sdk.node.updateNodeCapacity(
      nodeId,
      8, // 8 CPU cores
      32, // 32 GB memory
      512, // 512 GB storage
      1000, // 1000 Mbps network
      1, // 1 GPU
      "NVIDIA RTX 3080" // GPU type
    );

    const capacityReceipt = await capacityTx.wait();
    console.log(
      `Capacity update completed in block: ${capacityReceipt.blockNumber}`
    );
    console.log("Node capacity updated successfully");

    // Step 3: Create a compute resource listing
    console.log("\nStep 3: Creating compute listing");
    const hourlyPrice = QuikDBUtils.toWei("0.02"); // 0.02 ETH per hour

    const listingId = await sdk.resource.createComputeListing(
      nodeId,
      ComputeTier.STANDARD,
      8, // CPU cores
      32, // Memory GB
      512, // Storage GB
      hourlyPrice.toString(),
      "us-west-1" // Region
    );

    console.log(`Compute listing created with ID: ${listingId}`);

    // Step 4: Add listing features (optional)
    console.log("\nStep 4: Adding listing features");
    await sdk.resource.updateComputeListingFeatures(listingId, [
      "GPU",
      "SSD",
      "ML-Optimized",
    ]);

    console.log("Features update submitted");
    console.log("Listing features updated successfully");

    // Step 5: Set the node status to ACTIVE
    console.log("\nStep 5: Setting node status to ACTIVE");
    const statusTx = await sdk.node.updateNodeStatus(nodeId, NodeStatus.ACTIVE);

    console.log(`Status update submitted: ${statusTx.hash}`);
    await statusTx.wait();
    console.log("Node is now ACTIVE");

    // Step 6: Verify your node information
    console.log("\nStep 6: Verifying node information");
    const nodeInfo = await sdk.node.getNodeInfo(nodeId);

    console.log("Node Information:");
    console.log(`- Node ID: ${nodeInfo.nodeId}`);
    console.log(`- Status: ${NodeStatus[nodeInfo.status]}`);
    console.log(`- Tier: ${NodeTier[nodeInfo.tier]}`);
    console.log(`- Provider Type: ${ProviderType[nodeInfo.providerType]}`);
    console.log("- Capacity:");
    console.log(`  - CPU Cores: ${nodeInfo.capacity.cpuCores}`);
    console.log(`  - Memory: ${nodeInfo.capacity.memoryGB} GB`);
    console.log(`  - Storage: ${nodeInfo.capacity.storageGB} GB`);
    console.log(
      `  - GPU: ${nodeInfo.capacity.gpuCount}x ${nodeInfo.capacity.gpuType}`
    );

    console.log(
      "\nYour compute node has been successfully registered and listed!"
    );
    console.log(
      "You can now receive compute job allocations from QuikDB users."
    );
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
