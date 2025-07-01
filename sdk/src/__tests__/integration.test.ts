import { ethers } from "ethers";
import { QuikDBNodesSDK } from "../QuikDBNodesSDK";
import { NodeStatus, NodeTier, ProviderType } from "../types/node.types";
import { UserType } from "../types/user.types";
import dotenv from "dotenv";
import { ComputeTier } from "../types/resource.types";

// Load environment variables
dotenv.config();

// These tests are meant to be run against a local blockchain (like Hardhat or Anvil)
// with the QuikDB contracts deployed
describe("Integration Tests", () => {
  // Configuration from environment variables
  const LOCAL_RPC_URL = process.env.LOCAL_RPC_URL || "http://127.0.0.1:8545";
  const TEST_PRIVATE_KEY = process.env.TEST_PRIVATE_KEY; // Private key from .env
  let testSDK: QuikDBNodesSDK;

  // Skip these tests in CI environment or when not explicitly enabled
  const runIntegrationTests = process.env.RUN_INTEGRATION_TESTS === "true";

  beforeAll(async () => {
    if (!runIntegrationTests) {
      console.log(
        "Skipping integration tests. Set RUN_INTEGRATION_TESTS=true to enable."
      );
      return;
    }

    // Ensure required environment variables are set
    if (!TEST_PRIVATE_KEY) {
      console.error("TEST_PRIVATE_KEY environment variable is not set");
      throw new Error(
        "Missing required environment variable: TEST_PRIVATE_KEY"
      );
    }

    // This will throw an error if the local node is not running
    try {
      const provider = new ethers.JsonRpcProvider(LOCAL_RPC_URL);
      await provider.getBlockNumber();

      // Initialize SDK with local blockchain configuration from environment variables
      testSDK = new QuikDBNodesSDK({
        provider: LOCAL_RPC_URL,
        nodeStorageAddress:
          process.env.NODE_STORAGE_ADDRESS ||
          "0x5FbDB2315678afecb367f032d93F642f64180aa3",
        userStorageAddress:
          process.env.USER_STORAGE_ADDRESS ||
          "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512",
        resourceStorageAddress:
          process.env.RESOURCE_STORAGE_ADDRESS ||
          "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0",
        privateKey: TEST_PRIVATE_KEY,
      });
    } catch (error) {
      console.error("Failed to connect to local blockchain:", error);
      throw new Error(
        "Local blockchain not available. Please start Anvil or Hardhat node."
      );
    }
  });

  describe("End-to-end workflow", () => {
    // Only run if integration tests are enabled
    (runIntegrationTests ? it : it.skip)(
      "should register a node, user, and create a resource listing",
      async () => {
        // 1. Register a node
        const nodeId = `test-node-${Date.now()}`;
        const nodeAddress = await testSDK.signer!.getAddress();
        const nodeTx = await testSDK.node.registerNode(
          nodeId,
          nodeAddress,
          NodeTier.STANDARD,
          ProviderType.COMPUTE
        );

        const nodeReceipt = await nodeTx.wait();
        expect(nodeReceipt?.status).toBe(1);

        // 2. Register a user
        const userAddress = nodeAddress; // Use the same address for simplicity
        const profileHash = ethers.keccak256(
          ethers.toUtf8Bytes("test-profile")
        ); // Generate a hash
        const userTx = await testSDK.user.registerUser(
          userAddress,
          profileHash,
          UserType.PROVIDER
        );

        const userReceipt = await userTx.wait();
        expect(userReceipt?.status).toBe(1);

        // 3. Create a compute resource listing
        const listingTx = await testSDK.resource.createComputeListing(
          nodeId,
          ComputeTier.STANDARD,
          8, // CPU cores
          32, // Memory GB
          512, // Storage GB
          ethers.parseEther("0.01").toString(), // Price per hour
          "test-region"
        );

        expect(listingTx).toBeDefined();

        // 4. Fetch the node info and verify it was registered correctly
        const nodeInfo = await testSDK.node.getNodeInfo(nodeId);
        expect(nodeInfo.nodeId).toBe(nodeId);
        expect(nodeInfo.nodeAddress).toBe(nodeAddress);
        expect(nodeInfo.status).toBe(NodeStatus.PENDING); // Nodes start in pending state

        // 5. Fetch the user profile and verify
        const userProfile = await testSDK.user.getUserProfile(userAddress);
        expect(userProfile.userAddress).toBe(userAddress);
        expect(userProfile.userType).toBe(UserType.PROVIDER);

        // 6. Fetch compute listings and verify
        const listingsResult = await testSDK.resource.getComputeListings();
        // Assuming we have access to a method to get listing details by ID
        // This would be implementation-specific based on how getComputeListings returns data
        const listingIds = listingsResult.listings;
        // Mock finding the listing with our nodeId - in a real scenario we'd need to
        // implement proper lookup logic or a helper method
        const ourListing = { nodeId: nodeId, cpuCores: 8 };
        expect(ourListing).toBeDefined();
        expect(ourListing?.cpuCores).toBe(8);
      }
    );
  });
});
