// Test script for QuikDB Nodes SDK
const { QuikDBNodesSDK } = require("quikdb-nodes-sdk");
const { ethers } = require("ethers");
require("dotenv").config(); // Load environment variables from .env file

// Contract addresses on Lisk Sepolia from .env file
const NODE_STORAGE_ADDRESS = process.env.NODE_STORAGE_ADDRESS || "0x77E5A4CF81479b6B2eD8e781FEc72883E6ff41EB";
const USER_STORAGE_ADDRESS = process.env.USER_STORAGE_ADDRESS || "0xdbe025cBE1b6a3073c86BA023A5970252a06F5da";
const RESOURCE_STORAGE_ADDRESS = process.env.RESOURCE_STORAGE_ADDRESS || "0x1a560207e7F96273eC13f67C9E49c4f6E7b4D29e";

// Test private key (NEVER use this in production!)
const TEST_PRIVATE_KEY = process.env.TEST_PRIVATE_KEY;

// Constants for role checking
const LOGIC_ROLE = ethers.keccak256(ethers.toUtf8Bytes("LOGIC_ROLE"));
const DEFAULT_ADMIN_ROLE =
  "0x0000000000000000000000000000000000000000000000000000000000000000";

async function checkAndVerifyProxy(provider, contractAddress) {
  const code = await provider.getCode(contractAddress);
  if (code === "0x")
    return {
      isProxy: false,
      implementation: null,
      error: "No contract at address",
    };

  try {
    // Check if it's a proxy by trying to call the implementation() function
    const contract = new ethers.Contract(
      contractAddress,
      ["function implementation() view returns (address)"],
      provider
    );
    const implementation = await contract.implementation();
    return { isProxy: true, implementation, error: null };
  } catch (error) {
    // Not a proxy or different proxy pattern
    return { isProxy: false, implementation: null, error: null };
  }
}

async function checkRoles(contract, walletAddress) {
  try {
    const hasLogicRole = await contract.hasRole(LOGIC_ROLE, walletAddress);
    const hasAdminRole = await contract.hasRole(
      DEFAULT_ADMIN_ROLE,
      walletAddress
    );
    return { hasLogicRole, hasAdminRole };
  } catch (error) {
    return { hasLogicRole: false, hasAdminRole: false, error: error.message };
  }
}

// Get the NodeStorage ABI from the SDK package
const NODE_STORAGE_ABI = [
  "function hasRole(bytes32 role, address account) view returns (bool)",
  "function grantRole(bytes32 role, address account)",
  "function registerNode(string memory _name, string memory _endpoint, string memory _nodeType, uint256 _maxCapacity) external returns (uint256)",
  "function listNode(uint256 _nodeId, uint256 _pricePerHour, uint256 _availableCapacity) external",
  "function getNodeInfo(uint256 _nodeId) external view returns (tuple(string name, string endpoint, string nodeType, uint256 maxCapacity, uint256 availableCapacity, uint256 pricePerHour, uint256 createdAt, uint256 lastUpdated, address operator, bool isActive, bool isListed))",
];

async function runTests() {
  console.log("============================================");
  console.log("🧪 QuikDB Nodes SDK Test Script");
  console.log("============================================\n");

  console.log("SETUP");
  console.log("--------------------------------------------");

  if (!TEST_PRIVATE_KEY || TEST_PRIVATE_KEY.includes("123456")) {
    console.log(
      "❌ Error: Please replace TEST_PRIVATE_KEY with your actual test wallet private key"
    );
    return;
  }

  console.log("1. Connecting to Lisk Sepolia...");

  const provider = new ethers.JsonRpcProvider(
    process.env.RPC_URL || "https://rpc.sepolia-api.lisk.com"
  );
  const wallet = new ethers.Wallet(TEST_PRIVATE_KEY, provider);

  try {
    const blockNumber = await provider.getBlockNumber();
    console.log(`✅ Connected to Lisk Sepolia (block: ${blockNumber})`);
    console.log(`📍 Using wallet: ${wallet.address}\n`);
  } catch (error) {
    console.log(`❌ Error connecting to Lisk Sepolia: ${error.message}`);
    console.log("Please check your network connection and RPC endpoint.");
    return;
  }

  console.log("2. Checking Contracts...");

  // Check NodeStorage contract and its proxy status
  const nodeStorageStatus = await checkAndVerifyProxy(
    provider,
    NODE_STORAGE_ADDRESS
  );
  console.log(`\nNodeStorage Contract (${NODE_STORAGE_ADDRESS}):`);
  if (nodeStorageStatus.error) {
    console.log(`❌ Error: ${nodeStorageStatus.error}`);
    return;
  }

  const targetAddress = nodeStorageStatus.isProxy
    ? nodeStorageStatus.implementation
    : NODE_STORAGE_ADDRESS;
  console.log(
    `${nodeStorageStatus.isProxy ? "✅ Proxy detected" : "✳️ Not a proxy"}`
  );
  if (nodeStorageStatus.isProxy) {
    console.log(`📍 Implementation: ${nodeStorageStatus.implementation}`);
  }

  // Create contract instance and check roles
  const nodeStorage = new ethers.Contract(
    NODE_STORAGE_ADDRESS,
    NODE_STORAGE_ABI,
    wallet
  );
  const roles = await checkRoles(nodeStorage, wallet.address);

  console.log("\n3. Checking Permissions...");
  console.log(`LOGIC_ROLE: ${roles.hasLogicRole ? "✅" : "❌"}`);
  console.log(`ADMIN_ROLE: ${roles.hasAdminRole ? "✅" : "❌"}`);

  if (!roles.hasLogicRole && !roles.hasAdminRole) {
    console.log(
      "\n⚠️ WARNING: Your wallet has neither LOGIC_ROLE nor ADMIN_ROLE."
    );
    console.log("You will not be able to make any state-changing calls.");
    console.log("Please have an admin grant you LOGIC_ROLE to proceed.");
    return;
  }

  console.log("\n4. Testing Node Registration...");
  try {
    if (roles.hasLogicRole) {
      const testNodeName = `Test Node ${Date.now()}`;
      console.log(`Attempting to register node: ${testNodeName}`);

      const tx = await nodeStorage.registerNode(
        testNodeName,
        "https://test-endpoint.example.com",
        "compute",
        ethers.parseEther("1.0") // 1.0 capacity units
      );

      console.log("Transaction sent, waiting for confirmation...");
      const receipt = await tx.wait();
      console.log(`✅ Node registered! Transaction: ${receipt.hash}`);

      // Verify the node was created
      const nodeId = receipt.events?.find((e) => e.event === "NodeRegistered")
        ?.args?.nodeId;
      if (nodeId) {
        const nodeInfo = await nodeStorage.getNodeInfo(nodeId);
        console.log("\nNode Info:");
        console.log(`- Name: ${nodeInfo.name}`);
        console.log(`- Endpoint: ${nodeInfo.endpoint}`);
        console.log(`- Type: ${nodeInfo.nodeType}`);
        console.log(`- Operator: ${nodeInfo.operator}`);
      }
    } else if (roles.hasAdminRole) {
      console.log("\n5. Granting LOGIC_ROLE...");
      const tx = await nodeStorage.grantRole(LOGIC_ROLE, wallet.address);
      await tx.wait();
      console.log("✅ LOGIC_ROLE granted! Please run the test again.");
    }
  } catch (error) {
    console.log(`\n❌ Error: ${error.message}`);
    if (error.message.includes("execution reverted")) {
      console.log("\nPossible issues:");
      console.log("1. The contract might be paused");
      console.log(
        "2. You might be calling through a proxy with an outdated implementation"
      );
      console.log("3. The contract might have additional role requirements");
      console.log(
        "\nPlease check CONTRACT-DEPLOYMENT.md and PROXY-CONTRACTS.md for troubleshooting steps."
      );
    }
  }
}

// Run the tests
runTests().catch(console.error);
