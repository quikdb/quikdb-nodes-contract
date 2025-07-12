/**
 * Simple test wallet generator for QuikDB gRPC testing
 * No external dependencies required
 */

const crypto = require("crypto");

/**
 * Generate a random Ethereum-like address
 */
function generateAddress() {
  const randomBytes = crypto.randomBytes(20);
  return "0x" + randomBytes.toString("hex");
}

/**
 * Generate a random 32-byte hash for profile_hash
 */
function generateProfileHash() {
  return "0x" + crypto.randomBytes(32).toString("hex");
}

/**
 * Generate ready-to-use test wallets for gRPC testing
 */
function generateTestWallets() {
  const userTypes = [
    { name: "CONSUMER", value: 0 },
    { name: "PROVIDER", value: 1 },
    { name: "HYBRID", value: 2 },
    { name: "ENTERPRISE", value: 3 },
  ];

  console.log("🔐 QuikDB Test Wallets Generator");
  console.log("================================\n");

  console.log("// Copy these test wallets to your client.ts file:");
  console.log("// ================================================\n");

  userTypes.forEach((userType, index) => {
    const address = generateAddress();
    const profileHash = generateProfileHash();

    console.log(`// Test User ${index + 1} - ${userType.name}`);
    console.log(`const testUser${index + 1} = {`);
    console.log(`  user_address: "${address}",`);
    console.log(`  profile_hash: "${profileHash}",`);
    console.log(`  user_type: ${userType.value}, // ${userType.name}`);
    console.log(`};\n`);
  });

  console.log("// Updated profile hashes for testing updates:");
  console.log("// ===========================================");
  for (let i = 1; i <= 3; i++) {
    console.log(`const updatedProfileHash${i} = "${generateProfileHash()}";`);
  }

  console.log("\n// Usage Examples:");
  console.log("// ===============");
  console.log("// 1. Register a user:");
  console.log("//    await userClient.RegisterUser(testUser1);");
  console.log("//");
  console.log("// 2. Get user profile:");
  console.log(
    "//    await userClient.GetUserProfile({ user_address: testUser1.user_address });"
  );
  console.log("//");
  console.log("// 3. Update user profile:");
  console.log("//    await userClient.UpdateUserProfile({");
  console.log("//      user_address: testUser1.user_address,");
  console.log("//      profile_hash: updatedProfileHash1");
  console.log("//    });");

  console.log("\n✅ Test wallets generated successfully!");
  console.log(
    "📋 Copy the code above and paste it into your client test file."
  );
  console.log("⚠️  Note: These are random test addresses for testing only.");
}

// Run the generator
if (require.main === module) {
  generateTestWallets();
}

module.exports = {
  generateAddress,
  generateProfileHash,
  generateTestWallets,
};
