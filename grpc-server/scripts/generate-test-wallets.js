/**
 * Generate test wallets for QuikDB gRPC testing
 */

const { ethers } = require("ethers");
const crypto = require("crypto");

/**
 * Generate a random 32-byte hash for profile_hash
 */
function generateProfileHash() {
  return "0x" + crypto.randomBytes(32).toString("hex");
}

/**
 * Generate test wallets with different user types
 */
function generateTestWallets(count = 5) {
  const wallets = [];
  const userTypes = ["CONSUMER", "PROVIDER", "HYBRID", "ENTERPRISE"];

  console.log("🔐 Generating Test Wallets for QuikDB");
  console.log("=====================================");

  for (let i = 0; i < count; i++) {
    // Generate a new random wallet
    const wallet = ethers.Wallet.createRandom();
    const userType = userTypes[i % userTypes.length];
    const userTypeNum = userTypes.indexOf(userType);

    const testWallet = {
      id: i + 1,
      address: wallet.address,
      privateKey: wallet.privateKey,
      mnemonic: wallet.mnemonic.phrase,
      userType: userType,
      userTypeNum: userTypeNum,
      profileHash: generateProfileHash(),
    };

    wallets.push(testWallet);

    console.log(`\n📝 Wallet ${i + 1} (${userType}):`);
    console.log(`   Address:      ${testWallet.address}`);
    console.log(`   Private Key:  ${testWallet.privateKey}`);
    console.log(`   Mnemonic:     ${testWallet.mnemonic}`);
    console.log(
      `   User Type:    ${testWallet.userType} (${testWallet.userTypeNum})`
    );
    console.log(`   Profile Hash: ${testWallet.profileHash}`);
  }

  console.log("\n🔧 Ready-to-use Test Data:");
  console.log("===========================");

  wallets.forEach((wallet, index) => {
    console.log(`\n// Test Wallet ${index + 1} - ${wallet.userType}`);
    console.log(`const testUser${index + 1} = {`);
    console.log(`  user_address: "${wallet.address}",`);
    console.log(`  profile_hash: "${wallet.profileHash}",`);
    console.log(`  user_type: ${wallet.userTypeNum}, // ${wallet.userType}`);
    console.log(`};`);
  });

  console.log("\n💡 Usage Examples:");
  console.log("==================");
  console.log("// Register a user:");
  console.log("await userClient.RegisterUser(testUser1);");
  console.log("");
  console.log("// Get user profile:");
  console.log(
    "await userClient.GetUserProfile({ user_address: testUser1.user_address });"
  );
  console.log("");
  console.log("// Update user profile:");
  console.log("await userClient.UpdateUserProfile({");
  console.log("  user_address: testUser1.user_address,");
  console.log(
    '  profile_hash: "0x' + crypto.randomBytes(32).toString("hex") + '"'
  );
  console.log("});");

  return wallets;
}

/**
 * Generate wallets for specific test scenarios
 */
function generateScenarioWallets() {
  console.log("\n🎯 Scenario-Specific Test Wallets:");
  console.log("==================================");

  const scenarios = [
    { name: "Registration Test", userType: "CONSUMER", userTypeNum: 0 },
    { name: "Profile Update Test", userType: "PROVIDER", userTypeNum: 1 },
    { name: "Duplicate Registration Test", userType: "HYBRID", userTypeNum: 2 },
    { name: "Enterprise User Test", userType: "ENTERPRISE", userTypeNum: 3 },
    { name: "Error Handling Test", userType: "CONSUMER", userTypeNum: 0 },
  ];

  scenarios.forEach((scenario, index) => {
    const wallet = ethers.Wallet.createRandom();
    console.log(`\n📋 ${scenario.name}:`);
    console.log(
      `const ${scenario.name.toLowerCase().replace(/\s+/g, "")}Wallet = {`
    );
    console.log(`  user_address: "${wallet.address}",`);
    console.log(`  profile_hash: "${generateProfileHash()}",`);
    console.log(
      `  user_type: ${scenario.userTypeNum}, // ${scenario.userType}`
    );
    console.log(`};`);
  });
}

/**
 * Generate updated profile hashes for testing updates
 */
function generateUpdatedProfileHashes(count = 3) {
  console.log("\n🔄 Updated Profile Hashes for Testing:");
  console.log("======================================");

  for (let i = 0; i < count; i++) {
    console.log(
      `const updatedProfileHash${i + 1} = "${generateProfileHash()}";`
    );
  }
}

// Run the generator
if (require.main === module) {
  console.log("🚀 QuikDB Test Wallet Generator");
  console.log("===============================\n");

  // Generate main test wallets
  const wallets = generateTestWallets(5);

  // Generate scenario-specific wallets
  generateScenarioWallets();

  // Generate updated profile hashes
  generateUpdatedProfileHashes(3);

  console.log("\n✅ Test wallet generation complete!");
  console.log("📁 Copy the wallet data above to use in your tests.");
  console.log(
    "⚠️  Remember: These are test wallets only. Never use them on mainnet!"
  );
}

module.exports = {
  generateTestWallets,
  generateScenarioWallets,
  generateUpdatedProfileHashes,
  generateProfileHash,
};
