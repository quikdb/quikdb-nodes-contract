/**
 * Example for using compute listing pagination functionality with mock data
 * 
 * This example demonstrates:
 * 1. Getting a paginated list of compute listings
 * 2. Filtering listings by different criteria
 * 3. Navigating through pages
 * 4. Using the MockResourceModule as a standalone module
 */
import { QuikDBNodesSDK } from "../src/QuikDBNodesSDK";
import { ComputeTier, StorageTier } from "../src/types/resource.types";
import { MockResourceModule } from "../src/modules/MockResourceModule";
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
  const resourceStorageAddress = "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0";

  // Create mock resource module for testing
  const resourceModule = new MockResourceModule(
    provider, 
    resourceStorageAddress,
    wallet
  );

  try {
    console.log("Example 1: Getting compute listings with pagination (default settings)");
    // Default pagination (first page, 10 items)
    const firstPage = await resourceModule.getComputeListings();
    console.log(`Total compute listings: ${firstPage.totalListings}`);
    console.log(`Total pages: ${firstPage.totalPages}`);
    console.log(`Current page: ${firstPage.currentPage + 1}`); // +1 for human-readable page number
    console.log(`Has next page: ${firstPage.hasNextPage}`);
    console.log(`Has previous page: ${firstPage.hasPreviousPage}`);
    console.log(`Listings on this page: ${firstPage.listings.length}`);
    console.log("Listing IDs:", firstPage.listings);

    if (firstPage.listings.length > 0) {
      // Get details for the first listing to show
      const firstListingId = firstPage.listings[0];
      const listingDetails = await resourceModule.getComputeListing(firstListingId);
      console.log(`Details for first listing ${firstListingId}:`);
      console.log(`  Node ID: ${listingDetails.nodeId}`);
      console.log(`  Tier: ${ComputeTier[listingDetails.tier]}`);
      console.log(`  CPU Cores: ${listingDetails.cpuCores}`);
      console.log(`  Memory: ${listingDetails.memoryGB} GB`);
      console.log(`  Storage: ${listingDetails.storageGB} GB`);
      console.log(`  Hourly Rate: ${ethers.formatEther(listingDetails.hourlyRate)} ETH`);
      console.log(`  Region: ${listingDetails.region}`);
      console.log(`  Active: ${listingDetails.isActive}`);
    }
    console.log();

    // Only proceed if there are multiple pages
    if (firstPage.hasNextPage) {
      console.log("Example 2: Getting the second page");
      const secondPage = await resourceModule.getComputeListings(1); // page 1 (second page)
      console.log(`Current page: ${secondPage.currentPage + 1}`);
      console.log(`Listings on this page: ${secondPage.listings.length}`);
      console.log("Listing IDs:", secondPage.listings);
      console.log();
    }

    console.log("Example 3: Custom page size (5 items per page)");
    const smallPage = await resourceModule.getComputeListings(0, 5);
    console.log(`Total pages with 5 items per page: ${smallPage.totalPages}`);
    console.log(`Listings on this page: ${smallPage.listings.length}`);
    console.log("Listing IDs:", smallPage.listings);
    console.log();

    console.log("Example 4: Filtering by tier (PREMIUM only)");
    const premiumListings = await resourceModule.getComputeListings(0, 10, {
      tier: ComputeTier.PREMIUM,
    });
    console.log(`Total premium listings: ${premiumListings.totalListings}`);
    console.log("Premium Listing IDs:", premiumListings.listings);
    console.log();

    console.log("Example 5: Filtering by region (us-east only)");
    const usEastListings = await resourceModule.getComputeListings(0, 10, {
      region: "us-east",
    });
    console.log(`Total us-east listings: ${usEastListings.totalListings}`);
    console.log("US East Listing IDs:", usEastListings.listings);
    console.log();

    console.log("Example 6: Filtering by active status (active only)");
    const activeListings = await resourceModule.getComputeListings(0, 10, {
      isActive: true,
    });
    console.log(`Total active listings: ${activeListings.totalListings}`);
    console.log("Active Listing IDs:", activeListings.listings);
    console.log();

    console.log("Example 7: Complex filtering (active premium listings with at least 16 CPU cores)");
    const complexFilteredListings = await resourceModule.getComputeListings(0, 10, {
      tier: ComputeTier.PREMIUM,
      isActive: true,
      minCpuCores: 16,
    });
    console.log(`Total matching listings: ${complexFilteredListings.totalListings}`);
    console.log("Matching Listing IDs:", complexFilteredListings.listings);
    
    // If results exist, show details for these premium filtered listings
    if (complexFilteredListings.listings.length > 0) {
      console.log("\nDetails for filtered premium listings:");
      for (const listingId of complexFilteredListings.listings) {
        const listing = await resourceModule.getComputeListing(listingId);
        console.log(`\nListing: ${listingId}`);
        console.log(`  CPU: ${listing.cpuCores} cores`);
        console.log(`  Memory: ${listing.memoryGB} GB`);
        console.log(`  Storage: ${listing.storageGB} GB`);
        console.log(`  Region: ${listing.region}`);
        console.log(`  Hourly Rate: ${ethers.formatEther(listing.hourlyRate)} ETH`);
      }
    } else {
      console.log("No listings match the complex filter criteria.");
    }

  } catch (error) {
    console.error("Error:", error);
  }
}

// Run the example
main().catch(console.error);
