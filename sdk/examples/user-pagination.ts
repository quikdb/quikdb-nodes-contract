/**
 * Example for using user pagination functionality with mock data
 *
 * This example demonstrates:
 * 1. Getting a paginated list of users using a mock implementation
 * 2. Filtering users by different criteria
 * 3. Navigating through pages
 * 4. Using the MockUserModule as a standalone module instead of the real UserModule
 *
 * This approach allows testing without requiring a live blockchain connection
 */
import { QuikDBNodesSDK } from "../src/QuikDBNodesSDK";
import { UserType } from "../src/types/user.types";
import { MockUserModule } from "../src/modules/MockUserModule";
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

  // Create mock user module for testing
  const mockUserModule = new MockUserModule(
    provider,
    userStorageAddress,
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

  // Use the mock user module methods directly
  const userModule = mockUserModule;

  try {
    // Create a test user if needed (uncomment to create test data)
    /*
    console.log("Creating a test user for demonstration purposes...");
    const testUserAddress = ethers.Wallet.createRandom().address;
    await userModule.registerUser(
      testUserAddress,
      "test-profile-hash",
      UserType.CONSUMER
    );
    console.log(`Test user created with address: ${testUserAddress}`);
    */

    console.log("Example 1: Getting users with pagination (default settings)");
    // Default pagination (first page, 10 items)
    const firstPage = await userModule.getUsersList();
    console.log(`Total users: ${firstPage.totalUsers}`);
    console.log(`Total pages: ${firstPage.totalPages}`);
    console.log(`Current page: ${firstPage.currentPage + 1}`); // +1 for human-readable page number
    console.log(`Has next page: ${firstPage.hasNextPage}`);
    console.log(`Has previous page: ${firstPage.hasPreviousPage}`);
    console.log(`Users on this page: ${firstPage.users.length}`);
    
    if (firstPage.users.length === 0) {
      console.log(
        "No users found. The blockchain may be empty or the contract address may be incorrect."
      );
      console.log(
        "You can uncomment the test user creation code above to create sample data."
      );
    } else {
      // Get details for the first user to show
      const firstUserAddress = firstPage.users[0];
      const userDetails = await userModule.getUserInfo(firstUserAddress);
      console.log(`Details for user ${firstUserAddress}:`);
      console.log(`  User Type: ${UserType[userDetails.profile.userType]}`);
      console.log(`  Is Active: ${userDetails.profile.isActive}`);
      console.log(`  Is Verified: ${userDetails.profile.isVerified}`);
      console.log(`  Reputation Score: ${userDetails.profile.reputationScore}`);
      console.log(`  Registered: ${new Date(userDetails.profile.createdAt * 1000).toLocaleString()}`);
    }
    console.log();

    // Only proceed if there are multiple pages
    if (firstPage.hasNextPage) {
      console.log("Example 2: Getting the second page");
      const secondPage = await userModule.getUsersList(1); // page 1 (second page)
      console.log(`Current page: ${secondPage.currentPage + 1}`);
      console.log(`Users on this page: ${secondPage.users.length}`);
      console.log("User addresses on page 2:", secondPage.users);
      console.log();
    }

    console.log("Example 3: Custom page size (5 items per page)");
    const smallPage = await userModule.getUsersList(0, 5);
    console.log(`Total pages with 5 items per page: ${smallPage.totalPages}`);
    console.log(`Users on this page: ${smallPage.users.length}`);
    console.log("User addresses:", smallPage.users);
    console.log();

    console.log("Example 4: Filtering by user type (PROVIDER only)");
    const providerUsers = await userModule.getUsersList(0, 10, {
      userType: UserType.PROVIDER,
    });
    console.log(`Total provider users: ${providerUsers.totalUsers}`);
    console.log("Provider user addresses:", providerUsers.users);
    console.log();

    console.log("Example 5: Filtering by active status (active users only)");
    const activeUsers = await userModule.getUsersList(0, 10, {
      isActive: true,
    });
    console.log(`Total active users: ${activeUsers.totalUsers}`);
    console.log("Active user addresses:", activeUsers.users);
    console.log();

    // Get current timestamp
    const now = Math.floor(Date.now() / 1000);
    const thirtyDaysAgo = now - (30 * 24 * 60 * 60); // 30 days ago

    console.log("Example 6: Filtering by registration date (registered in the last 30 days)");
    const recentUsers = await userModule.getUsersList(0, 10, {
      registeredAfter: thirtyDaysAgo,
    });
    console.log(`Total users registered in the last 30 days: ${recentUsers.totalUsers}`);
    console.log("Recently registered user addresses:", recentUsers.users);
    console.log();

    console.log("Example 7: Filtering by reputation score (above 75)");
    const highRepUsers = await userModule.getUsersList(0, 10, {
      reputationScoreAbove: 75,
    });
    console.log(`Total users with reputation score above 75: ${highRepUsers.totalUsers}`);
    console.log("High reputation user addresses:", highRepUsers.users);
    console.log();

    console.log("Example 8: Complex filtering (active providers with high reputation)");
    const premiumProviders = await userModule.getUsersList(0, 10, {
      userType: UserType.PROVIDER,
      isActive: true,
      reputationScoreAbove: 75,
    });
    console.log(`Total active providers with high reputation: ${premiumProviders.totalUsers}`);
    console.log("Premium provider user addresses:", premiumProviders.users);
  } catch (error) {
    console.error("Error:", error);
  }
}

// Run the example
main().catch(console.error);
