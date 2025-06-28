import { QuikDBNodesSDK } from "../src/QuikDBNodesSDK";
import { NodeStatus, NodeTier, ProviderType } from "../src/types/node.types";
import { UserType } from "../src/types/user.types";
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
    privateKey: process.env.PRIVATE_KEY, // Using the private key from .env file
  });

  try {
    // Example 1: Get a node's information
    console.log("Example 1: Getting node information");
    const nodeId = "node-123";
    const nodeInfo = await sdk.node.getNodeInfo(nodeId);
    console.log(`Node Info for ${nodeId}:`);
    console.log(`  Address: ${nodeInfo.nodeAddress}`);
    console.log(`  Status: ${NodeStatus[nodeInfo.status]}`);
    console.log(`  Tier: ${NodeTier[nodeInfo.tier]}`);
    console.log(`  Provider Type: ${ProviderType[nodeInfo.providerType]}`);
    console.log(
      `  Registered: ${QuikDBUtils.formatTimestamp(nodeInfo.registeredAt)}`
    );
    console.log(
      `  Hourly Rate: ${QuikDBUtils.fromWei(nodeInfo.listing.hourlyRate)} ETH`
    );
    console.log(`  Verified: ${nodeInfo.extended.isVerified ? "Yes" : "No"}`);
    console.log();

    // Example 2: Register a new user
    console.log("Example 2: Registering a new user");
    const userAddress = "0x3456789012345678901234567890123456789012";
    const profileHash = QuikDBUtils.stringToBytes32("profile-data-hash");
    const userType = UserType.CONSUMER;

    const tx = await sdk.user.registerUser(userAddress, profileHash, userType);
    console.log(`User registration transaction sent: ${tx.hash}`);

    const receipt = await tx.wait();
    if (receipt) {
      console.log(`Transaction confirmed in block ${receipt.blockNumber}`);
    }
    console.log();

    // Example 3: Get user profile
    console.log("Example 3: Getting user profile");
    const userProfile = await sdk.user.getUserProfile(userAddress);
    console.log("User Profile:");
    console.log(`  User Type: ${UserType[userProfile.userType]}`);
    console.log(`  Active: ${userProfile.isActive}`);
    console.log(
      `  Created: ${QuikDBUtils.formatTimestamp(userProfile.createdAt)}`
    );
    console.log(`  Verified: ${userProfile.isVerified ? "Yes" : "No"}`);
    console.log();

    // Example 4: Create a compute listing
    console.log("Example 4: Creating a compute listing");
    const listingResult = await sdk.resource.createComputeListing(
      nodeId,
      3, // STANDARD tier
      8, // CPU cores
      32, // 32 GB memory
      512, // 512 GB storage
      QuikDBUtils.toWei("0.02").toString(), // 0.02 ETH per hour
      "us-west-1"
    );
    console.log(`Compute listing created with ID: ${listingResult}`);
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
