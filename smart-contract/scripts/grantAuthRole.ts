#!/usr/bin/env tsx
import { config } from "dotenv";
import { ethers } from "ethers";
import { readFileSync } from "fs";

// Load environment variables
config();

async function grantAuthServiceRole() {
  console.log("🔐 Granting AUTH_SERVICE_ROLE");
  console.log("===============================");

  // Load deployment info
  const deploymentPath = "./deployments/latest.json";
  const deployment = JSON.parse(readFileSync(deploymentPath, "utf8"));

  // Setup provider and wallet
  const provider = new ethers.JsonRpcProvider(process.env.RPC_URL);
  const wallet = new ethers.Wallet(process.env.PRIVATE_KEY!, provider);

  console.log("Deployer address:", deployment.deployer);
  console.log("Current wallet address:", wallet.address);
  console.log("UserLogic proxy address:", deployment.proxies.userLogic);

  // Check if current wallet is the deployer (has admin role)
  if (wallet.address.toLowerCase() !== deployment.deployer.toLowerCase()) {
    console.error("❌ Current wallet is not the deployer. Cannot grant roles.");
    console.error(`   Deployer: ${deployment.deployer}`);
    console.error(`   Current:  ${wallet.address}`);
    console.error(
      "   You need to use the deployer's private key to grant roles."
    );
    process.exit(1);
  }

  // Load UserLogic ABI
  const userLogicArtifact = JSON.parse(
    readFileSync("./out/UserLogic.sol/UserLogic.json", "utf8")
  );

  // Connect to UserLogic contract
  const userLogic = new ethers.Contract(
    deployment.proxies.userLogic,
    userLogicArtifact.abi,
    wallet
  );

  // Calculate AUTH_SERVICE_ROLE
  const AUTH_SERVICE_ROLE = ethers.keccak256(
    ethers.toUtf8Bytes("AUTH_SERVICE_ROLE")
  );

  // Address to grant role to (the gRPC server's address)
  const grpcServerAddress = "0x6F1b6ac175E2cf9436D7478E6d08E22C415eb574";

  try {
    // Check if role is already granted
    const hasRole = await userLogic.hasRole(
      AUTH_SERVICE_ROLE,
      grpcServerAddress
    );

    if (hasRole) {
      console.log(
        "✅ AUTH_SERVICE_ROLE already granted to:",
        grpcServerAddress
      );
      return;
    }

    console.log("Granting AUTH_SERVICE_ROLE to:", grpcServerAddress);

    // Grant the role
    const tx = await userLogic.grantRole(AUTH_SERVICE_ROLE, grpcServerAddress);
    console.log("Transaction hash:", tx.hash);

    // Wait for confirmation
    const receipt = await tx.wait();
    console.log("✅ Role granted successfully! Block:", receipt.blockNumber);

    // Verify the role was granted
    const hasRoleAfter = await userLogic.hasRole(
      AUTH_SERVICE_ROLE,
      grpcServerAddress
    );
    console.log(
      "Role verification:",
      hasRoleAfter ? "✅ Success" : "❌ Failed"
    );
  } catch (error) {
    console.error("❌ Failed to grant role:", (error as Error).message);
    process.exit(1);
  }
}

// Run the script
if (require.main === module) {
  grantAuthServiceRole().catch((error) => {
    console.error("❌ Script failed:", error);
    process.exit(1);
  });
}
