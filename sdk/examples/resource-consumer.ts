/**
 * Example for a consumer/user of QuikDB resources
 * This example demonstrates:
 * 1. User registration
 * 2. Searching for available compute and storage resources
 * 3. Resource allocation and booking
 */
import { QuikDBNodesSDK } from "../src/QuikDBNodesSDK";
import { NodeTier, ProviderType } from "../src/types/node.types";
import { UserType } from "../src/types/user.types";
import { QuikDBUtils } from "../src/utils";

async function main() {
  // Initialize the SDK with consumer credentials
  const sdk = new QuikDBNodesSDK({
    provider: "https://rpc.lisk.io",
    nodeStorageAddress: "0x1234567890123456789012345678901234567890", // Replace with actual contract addresses
    userStorageAddress: "0x0987654321098765432109876543210987654321",
    resourceStorageAddress: "0x2468101214161820222426283032343638404244",
    privateKey: "0xYOUR_PRIVATE_KEY", // Replace with your private key
  });

  try {
    // Step 1: Register as a user/consumer
    console.log("Step 1: Registering as a QuikDB consumer");
    const userAddress = await sdk.signer!.getAddress();

    // Create a profile hash (in production this would link to IPFS or similar)
    const profileData = {
      name: "Example User",
      email: "user@example.com",
      preferences: {
        resourceTypes: ["compute", "storage"],
        regions: ["us-west-1", "eu-central-1"],
        minTier: "STANDARD",
      },
    };

    // In a real application, you would hash this data and store it off-chain
    const profileHash = QuikDBUtils.stringToBytes32(
      JSON.stringify(profileData)
    );

    const registerTx = await sdk.user.registerUser(
      userAddress,
      profileHash,
      UserType.CONSUMER // Register as a CONSUMER
    );

    console.log(`User registration submitted: ${registerTx.hash}`);
    const receipt = await registerTx.wait();
    console.log(`Transaction confirmed in block ${receipt.blockNumber}`);

    // Step 2: Search for available compute resources
    console.log("\nStep 2: Searching for available compute resources");
    const computeListings = await sdk.resource.getComputeListings();

    console.log(`Found ${computeListings.length} compute listings`);

    // Filter for high-performance compute resources
    const highPerfCompute = computeListings.filter(
      (listing) =>
        listing.isActive &&
        listing.tier >= NodeTier.STANDARD &&
        listing.cpuCores >= 8 &&
        listing.memoryGB >= 32
    );

    console.log(
      `Found ${highPerfCompute.length} high-performance compute resources`
    );

    if (highPerfCompute.length > 0) {
      // Find the cheapest high-performance option
      const cheapestOption = highPerfCompute.reduce((prev, current) => {
        const prevPrice = BigInt(prev.price);
        const currentPrice = BigInt(current.price);
        return prevPrice < currentPrice ? prev : current;
      });

      console.log("\nSelected compute resource:");
      console.log(`- Listing ID: ${cheapestOption.listingId}`);
      console.log(`- Node ID: ${cheapestOption.nodeId}`);
      console.log(`- CPU Cores: ${cheapestOption.cpuCores}`);
      console.log(`- Memory: ${cheapestOption.memoryGB} GB`);
      console.log(
        `- Price: ${QuikDBUtils.fromWei(cheapestOption.price)} ETH/hour`
      );
      console.log(`- Region: ${cheapestOption.region}`);
    }

    // Step 3: Search for available storage resources
    console.log("\nStep 3: Searching for available storage resources");
    const storageListings = await sdk.resource.getStorageListings();

    console.log(`Found ${storageListings.length} storage listings`);

    // Filter for SSD storage in specific regions
    const preferredStorage = storageListings.filter(
      (listing) =>
        listing.isActive &&
        listing.storageType === "SSD" &&
        (listing.region === "us-west-1" || listing.region === "eu-central-1")
    );

    console.log(`Found ${preferredStorage.length} preferred storage options`);

    if (preferredStorage.length > 0) {
      // Find the option with highest redundancy
      const mostRedundant = preferredStorage.reduce((prev, current) =>
        prev.redundancyFactor > current.redundancyFactor ? prev : current
      );

      console.log("\nSelected storage resource:");
      console.log(`- Listing ID: ${mostRedundant.listingId}`);
      console.log(`- Node ID: ${mostRedundant.nodeId}`);
      console.log(`- Capacity: ${mostRedundant.capacityGB} GB`);
      console.log(`- Redundancy: ${mostRedundant.redundancyFactor}x`);
      console.log(
        `- Price: ${QuikDBUtils.fromWei(mostRedundant.price)} ETH/GB/month`
      );
      console.log(`- Type: ${mostRedundant.storageType}`);
    }

    // Step 4: Book a compute resource (if available)
    if (highPerfCompute.length > 0) {
      console.log("\nStep 4: Booking a compute resource");
      const selectedListing = highPerfCompute[0];
      const jobDurationHours = 24; // 24 hours

      // Calculate total cost
      const hourlyRate = BigInt(selectedListing.price);
      const totalCost = hourlyRate * BigInt(jobDurationHours);

      console.log(`Booking compute resource for ${jobDurationHours} hours`);
      console.log(`Total cost: ${QuikDBUtils.fromWei(totalCost)} ETH`);

      // In a production app, you would now call a booking contract function
      console.log("Submitting booking transaction...");

      // This is a placeholder for the actual booking function that would be in the SDK
      // const bookingTx = await sdk.booking.bookComputeResource(
      //   selectedListing.listingId,
      //   jobDurationHours,
      //   { value: totalCost.toString() }
      // );

      console.log("Resource booked successfully!");
    }

    // Step 5: Allocate storage (if available)
    if (preferredStorage.length > 0) {
      console.log("\nStep 5: Allocating storage");
      const selectedStorage = preferredStorage[0];
      const storageGB = 100; // 100 GB
      const storageDurationMonths = 6; // 6 months

      // Calculate total cost
      const gbMonthRate = BigInt(selectedStorage.price);
      const totalStorageCost =
        gbMonthRate * BigInt(storageGB) * BigInt(storageDurationMonths);

      console.log(
        `Allocating ${storageGB} GB for ${storageDurationMonths} months`
      );
      console.log(`Total cost: ${QuikDBUtils.fromWei(totalStorageCost)} ETH`);

      // In a production app, you would now call a storage allocation contract function
      console.log("Submitting storage allocation transaction...");

      // This is a placeholder for the actual allocation function that would be in the SDK
      // const allocationTx = await sdk.storage.allocateStorage(
      //   selectedStorage.listingId,
      //   storageGB,
      //   storageDurationMonths,
      //   { value: totalStorageCost.toString() }
      // );

      console.log("Storage allocated successfully!");
    }

    console.log("\nResource allocation demo completed!");
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
