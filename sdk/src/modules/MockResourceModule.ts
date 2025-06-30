import { ethers } from "ethers";
import { BaseModule, TransactionResponse } from "../types/common.types";
import {
  ComputeTier,
  StorageTier,
  ComputeListing,
  StorageListing,
  ComputeAllocation,
} from "../types/resource.types";

/**
 * Mock implementation of ResourceModule for testing without a blockchain
 *
 * This module provides all the functionality of the standard ResourceModule
 * but uses in-memory mock data instead of making actual blockchain calls.
 * This is useful for:
 * - Local development without a blockchain connection
 * - Writing tests that don't depend on external services
 * - Demonstrating SDK features without a real contract deployment
 */
export class MockResourceModule implements BaseModule {
  private mockComputeListings: Map<string, ComputeListing>;
  private mockStorageListings: Map<string, StorageListing>;
  private mockComputeAllocations: Map<string, ComputeAllocation>;
  private provider: ethers.Provider;
  private signer?: ethers.Signer;
  private contract: ethers.Contract; // Dummy contract to match interface

  constructor(
    provider: ethers.Provider,
    contractAddress: string,
    signer?: ethers.Signer
  ) {
    this.provider = provider;
    this.signer = signer;
    this.mockComputeListings = new Map<string, ComputeListing>();
    this.mockStorageListings = new Map<string, StorageListing>();
    this.mockComputeAllocations = new Map<string, ComputeAllocation>();

    // Initialize with some mock data
    this.generateMockData();

    // Create a dummy contract object to satisfy type requirements
    this.contract = new ethers.Contract(
      contractAddress,
      [], // Empty ABI since we're not using the contract
      provider
    );
  }

  /**
   * Generate some mock data for testing
   */
  private generateMockData() {
    // Generate 20 compute listings
    for (let i = 0; i < 20; i++) {
      const listingId = `compute-${i.toString().padStart(3, "0")}`;
      const nodeId = `node-${i % 10}`;

      // Create deterministic but varied data
      // For some entries, ensure we have premium listings with many CPU cores
      const tier = i % 5 === 0 ? ComputeTier.PREMIUM : i % 6;
      const cpuCores = i % 5 === 0 ? 32 + i * 4 : 2 + (i % 16);
      const memoryGB = i % 5 === 0 ? 64 + i * 8 : 2 + (i % 32);
      const storageGB = 20 + (i % 980);
      // Fix decimal precision for ethers.parseEther
      const hourlyRate = ethers
        .parseEther((0.001 + Math.floor(i % 100) / 10000).toFixed(18))
        .toString();
      const regions = [
        "us-east",
        "us-west",
        "eu-central",
        "ap-south",
        "sa-east",
      ];
      const region = regions[i % regions.length];
      const isActive = i % 4 !== 0; // 75% active

      // Current time minus 0-90 days
      const now = Math.floor(Date.now() / 1000);
      const createdAt = now - (i % 90) * 24 * 60 * 60;

      this.mockComputeListings.set(listingId, {
        listingId,
        nodeId,
        nodeAddress: ethers.Wallet.createRandom().address,
        tier,
        cpuCores,
        memoryGB,
        storageGB,
        hourlyRate,
        region,
        isActive,
        createdAt,
      });
    }

    // Generate 15 storage listings
    for (let i = 0; i < 15; i++) {
      const listingId = `storage-${i.toString().padStart(3, "0")}`;
      const nodeId = `node-${i % 10}`;

      // Create deterministic but varied data
      const tier = i % 4;
      const storageGB = 100 + (i % 10) * 100;
      // Fix decimal precision for ethers.parseEther
      const hourlyRate = ethers
        .parseEther((0.0005 + Math.floor(i % 100) / 20000).toFixed(18))
        .toString();
      const regions = [
        "us-east",
        "us-west",
        "eu-central",
        "ap-south",
        "sa-east",
      ];
      const region = regions[i % regions.length];
      const isActive = i % 3 !== 0; // 66% active

      // Current time minus 0-120 days
      const now = Math.floor(Date.now() / 1000);
      const createdAt = now - (i % 120) * 24 * 60 * 60;

      this.mockStorageListings.set(listingId, {
        listingId,
        nodeId,
        nodeAddress: ethers.Wallet.createRandom().address,
        tier,
        storageGB,
        hourlyRate,
        region,
        isActive,
        createdAt,
      });
    }

    // Generate some mock allocations
    for (let i = 0; i < 10; i++) {
      const allocationId = `alloc-${i.toString().padStart(3, "0")}`;
      const listingId = `compute-${(i % 20).toString().padStart(3, "0")}`;
      const userId = ethers.Wallet.createRandom().address;

      // Current time
      const now = Math.floor(Date.now() / 1000);
      const startTime = now - (i % 30) * 24 * 60 * 60;
      const duration = 24 * (1 + (i % 30)); // 1-30 days in hours
      const endTime = startTime + duration * 60 * 60;

      this.mockComputeAllocations.set(allocationId, {
        allocationId,
        listingId,
        buyerAddress: userId,
        startTime,
        endTime,
        totalCost: ethers
          .parseEther((0.01 * (1 + (i % 10))).toString())
          .toString(),
        status: now < endTime ? 1 : 2, // 1 = active, 2 = completed
        usageMetrics: {
          cpuUsagePercent: Math.floor(Math.random() * 100),
          memoryUsageGB: Math.floor(Math.random() * 16),
          storageUsageGB: Math.floor(Math.random() * 100),
          bandwidthUsageGB: Math.floor(Math.random() * 50),
          lastUpdated: now - Math.floor(Math.random() * 3600), // Last update between 0-1 hour ago
        },
      });
    }
  }

  /**
   * Connect to a new provider
   * @param provider Ethers provider
   */
  connect(provider: ethers.Provider): void {
    this.provider = provider;
  }

  /**
   * Set a new signer for transactions
   * @param signer Ethers signer
   */
  setSigner(signer: ethers.Signer): void {
    this.signer = signer;
  }

  /**
   * Create a compute listing
   * @param nodeId Node identifier
   * @param tier Compute tier
   * @param cpuCores Number of CPU cores
   * @param memoryGB Memory in GB
   * @param storageGB Storage in GB
   * @param hourlyRate Hourly rate
   * @param region Geographic region
   * @returns Listing ID
   */
  async createComputeListing(
    nodeId: string,
    tier: ComputeTier,
    cpuCores: number,
    memoryGB: number,
    storageGB: number,
    hourlyRate: string,
    region: string
  ): Promise<string> {
    if (!this.signer) {
      throw new Error("Signer required for this operation");
    }

    // Generate a new listing ID
    const listingId = `compute-${ethers
      .keccak256(ethers.toUtf8Bytes(`${nodeId}-${Date.now()}`))
      .slice(0, 10)}`;

    const now = Math.floor(Date.now() / 1000);

    // Create and store the new listing
    this.mockComputeListings.set(listingId, {
      listingId,
      nodeId,
      nodeAddress: await this.signer.getAddress(),
      tier,
      cpuCores,
      memoryGB,
      storageGB,
      hourlyRate,
      region,
      isActive: true,
      createdAt: now,
    });

    return listingId;
  }

  /**
   * Create a storage listing
   * @param nodeId Node identifier
   * @param tier Storage tier
   * @param storageGB Storage capacity in GB
   * @param hourlyRate Hourly rate
   * @param region Geographic region
   * @returns Listing ID
   */
  async createStorageListing(
    nodeId: string,
    tier: StorageTier,
    storageGB: number,
    hourlyRate: string,
    region: string
  ): Promise<string> {
    if (!this.signer) {
      throw new Error("Signer required for this operation");
    }

    // Generate a new listing ID
    const listingId = `storage-${ethers
      .keccak256(ethers.toUtf8Bytes(`${nodeId}-${Date.now()}`))
      .slice(0, 10)}`;

    const now = Math.floor(Date.now() / 1000);

    // Create and store the new listing
    this.mockStorageListings.set(listingId, {
      listingId,
      nodeId,
      nodeAddress: await this.signer.getAddress(),
      tier,
      storageGB,
      hourlyRate,
      region,
      isActive: true,
      createdAt: now,
    });

    return listingId;
  }

  /**
   * Get compute listing
   * @param listingId Listing identifier
   * @returns Compute listing details
   */
  async getComputeListing(listingId: string): Promise<ComputeListing> {
    const listing = this.mockComputeListings.get(listingId);
    if (!listing) {
      throw new Error(`Compute listing not found: ${listingId}`);
    }
    return listing;
  }

  /**
   * Get compute listings with pagination and filtering
   * @param page Page number (0-based)
   * @param pageSize Number of listings per page
   * @param filter Optional filter criteria
   * @returns Array of listing IDs and pagination info
   */
  async getComputeListings(
    page: number = 0,
    pageSize: number = 10,
    filter?: {
      tier?: ComputeTier;
      region?: string;
      isActive?: boolean;
      minCpuCores?: number;
      maxHourlyRate?: string;
    }
  ): Promise<{
    listings: string[];
    totalListings: number;
    totalPages: number;
    currentPage: number;
    hasNextPage: boolean;
    hasPreviousPage: boolean;
  }> {
    // Input validation
    if (page < 0) page = 0;
    if (pageSize <= 0) pageSize = 10;
    if (pageSize > 100) pageSize = 100; // Set a reasonable limit

    // Get all listings and convert to array
    let listings = Array.from(this.mockComputeListings.values());

    // Apply filters if provided
    if (filter) {
      if (filter.tier !== undefined) {
        listings = listings.filter((listing) => listing.tier === filter.tier);
      }

      if (filter.region !== undefined) {
        listings = listings.filter(
          (listing) =>
            listing.region.toLowerCase() === filter.region?.toLowerCase()
        );
      }

      if (filter.isActive !== undefined) {
        listings = listings.filter(
          (listing) => listing.isActive === filter.isActive
        );
      }

      if (filter.minCpuCores !== undefined) {
        listings = listings.filter(
          (listing) => listing.cpuCores >= filter.minCpuCores!
        );
      }

      if (filter.maxHourlyRate !== undefined) {
        const maxRate = BigInt(filter.maxHourlyRate);
        listings = listings.filter(
          (listing) => BigInt(listing.hourlyRate) <= maxRate
        );
      }
    }

    // Sort by creation date (newest first)
    listings.sort((a, b) => b.createdAt - a.createdAt);

    // Extract listing IDs
    const listingIds = listings.map((listing) => listing.listingId);

    // Calculate pagination
    const totalListings = listingIds.length;
    const totalPages = Math.ceil(totalListings / pageSize) || 1;
    const startIdx = page * pageSize;
    const endIdx = Math.min(startIdx + pageSize, totalListings);
    const pageListings = listingIds.slice(startIdx, endIdx);

    return {
      listings: pageListings,
      totalListings,
      totalPages,
      currentPage: page,
      hasNextPage: page < totalPages - 1,
      hasPreviousPage: page > 0,
    };
  }

  /**
   * Get storage listing
   * @param listingId Listing identifier
   * @returns Storage listing details
   */
  async getStorageListing(listingId: string): Promise<StorageListing> {
    const listing = this.mockStorageListings.get(listingId);
    if (!listing) {
      throw new Error(`Storage listing not found: ${listingId}`);
    }
    return listing;
  }

  /**
   * Get storage listings with pagination and filtering
   * @param page Page number (0-based)
   * @param pageSize Number of listings per page
   * @param filter Optional filter criteria
   * @returns Array of listing IDs and pagination info
   */
  async getStorageListings(
    page: number = 0,
    pageSize: number = 10,
    filter?: {
      tier?: StorageTier;
      region?: string;
      isActive?: boolean;
      minStorageGB?: number;
      maxHourlyRate?: string;
    }
  ): Promise<{
    listings: string[];
    totalListings: number;
    totalPages: number;
    currentPage: number;
    hasNextPage: boolean;
    hasPreviousPage: boolean;
  }> {
    // Input validation
    if (page < 0) page = 0;
    if (pageSize <= 0) pageSize = 10;
    if (pageSize > 100) pageSize = 100; // Set a reasonable limit

    // Get all listings and convert to array
    let listings = Array.from(this.mockStorageListings.values());

    // Apply filters if provided
    if (filter) {
      if (filter.tier !== undefined) {
        listings = listings.filter((listing) => listing.tier === filter.tier);
      }

      if (filter.region !== undefined) {
        listings = listings.filter(
          (listing) =>
            listing.region.toLowerCase() === filter.region?.toLowerCase()
        );
      }

      if (filter.isActive !== undefined) {
        listings = listings.filter(
          (listing) => listing.isActive === filter.isActive
        );
      }

      if (filter.minStorageGB !== undefined) {
        listings = listings.filter(
          (listing) => listing.storageGB >= filter.minStorageGB!
        );
      }

      if (filter.maxHourlyRate !== undefined) {
        const maxRate = BigInt(filter.maxHourlyRate);
        listings = listings.filter(
          (listing) => BigInt(listing.hourlyRate) <= maxRate
        );
      }
    }

    // Sort by creation date (newest first)
    listings.sort((a, b) => b.createdAt - a.createdAt);

    // Extract listing IDs
    const listingIds = listings.map((listing) => listing.listingId);

    // Calculate pagination
    const totalListings = listingIds.length;
    const totalPages = Math.ceil(totalListings / pageSize) || 1;
    const startIdx = page * pageSize;
    const endIdx = Math.min(startIdx + pageSize, totalListings);
    const pageListings = listingIds.slice(startIdx, endIdx);

    return {
      listings: pageListings,
      totalListings,
      totalPages,
      currentPage: page,
      hasNextPage: page < totalPages - 1,
      hasPreviousPage: page > 0,
    };
  }

  /**
   * Purchase compute resources
   * @param listingId Listing identifier
   * @param duration Duration in hours
   * @param paymentAmount Payment amount in wei
   * @returns Allocation ID
   */
  async purchaseCompute(
    listingId: string,
    duration: number,
    paymentAmount: string
  ): Promise<string> {
    if (!this.signer) {
      throw new Error("Signer required for this operation");
    }

    // Check if the listing exists
    const listing = this.mockComputeListings.get(listingId);
    if (!listing) {
      throw new Error(`Compute listing not found: ${listingId}`);
    }

    // Check if the listing is active
    if (!listing.isActive) {
      throw new Error(`Compute listing is not active: ${listingId}`);
    }

    // Generate a new allocation ID
    const allocationId = `alloc-${ethers
      .keccak256(ethers.toUtf8Bytes(`${listingId}-${Date.now()}`))
      .slice(0, 10)}`;

    const now = Math.floor(Date.now() / 1000);

    // Create and store the new allocation
    this.mockComputeAllocations.set(allocationId, {
      allocationId,
      buyerAddress: await this.signer.getAddress(),
      listingId,
      startTime: now,
      endTime: now + duration * 60 * 60,
      totalCost: paymentAmount,
      status: 1, // 1 = active
      usageMetrics: {
        cpuUsagePercent: 0,
        memoryUsageGB: 0,
        storageUsageGB: 0,
        bandwidthUsageGB: 0,
        lastUpdated: now,
      },
    });

    return allocationId;
  }

  /**
   * Get compute allocation
   * @param allocationId Allocation identifier
   * @returns Compute allocation details
   */
  async getComputeAllocation(allocationId: string): Promise<ComputeAllocation> {
    const allocation = this.mockComputeAllocations.get(allocationId);
    if (!allocation) {
      throw new Error(`Compute allocation not found: ${allocationId}`);
    }
    return allocation;
  }

  /**
   * Get total number of compute listings
   * @returns Total number of compute listings
   */
  async getTotalComputeListings(): Promise<number> {
    return this.mockComputeListings.size;
  }

  /**
   * Get total number of storage listings
   * @returns Total number of storage listings
   */
  async getTotalStorageListings(): Promise<number> {
    return this.mockStorageListings.size;
  }

  /**
   * Get compute listing ID by index
   * @param index Listing index
   * @returns Listing ID
   */
  async getComputeListingIdByIndex(index: number): Promise<string> {
    const listingIds = Array.from(this.mockComputeListings.keys());
    if (index < 0 || index >= listingIds.length) {
      throw new Error(`Compute listing index out of range: ${index}`);
    }
    return listingIds[index];
  }

  /**
   * Get storage listing ID by index
   * @param index Listing index
   * @returns Listing ID
   */
  async getStorageListingIdByIndex(index: number): Promise<string> {
    const listingIds = Array.from(this.mockStorageListings.keys());
    if (index < 0 || index >= listingIds.length) {
      throw new Error(`Storage listing index out of range: ${index}`);
    }
    return listingIds[index];
  }

  /**
   * Get all compute listing IDs
   * @returns Array of all compute listing IDs
   */
  async getAllComputeListingIds(): Promise<string[]> {
    return Array.from(this.mockComputeListings.keys());
  }

  /**
   * Get all storage listing IDs
   * @returns Array of all storage listing IDs
   */
  async getAllStorageListingIds(): Promise<string[]> {
    return Array.from(this.mockStorageListings.keys());
  }

  /**
   * Get total number of allocations
   * @returns Total number of allocations
   */
  async getTotalAllocations(): Promise<number> {
    return this.mockComputeAllocations.size;
  }

  /**
   * Update compute listing features (for compatibility with ResourceModule)
   * @param listingId Listing ID
   * @param features Array of feature strings
   */
  async updateComputeListingFeatures(
    listingId: string,
    features: string[]
  ): Promise<TransactionResponse> {
    if (!this.signer) {
      throw new Error("Signer required for this operation");
    }

    // Check if the listing exists
    const listing = this.mockComputeListings.get(listingId);
    if (!listing) {
      throw new Error(`Compute listing not found: ${listingId}`);
    }

    // Mock transaction response
    const mockTx = {
      hash: ethers.keccak256(
        ethers.toUtf8Bytes(`update-features-${listingId}-${Date.now()}`)
      ),
      confirmations: 1,
      from: await this.signer.getAddress(),
      to: "0x0000000000000000000000000000000000000000",
      data: "0x",
      value: BigInt(0),
      nonce: 0,
      gasLimit: BigInt(100000),
      gasPrice: BigInt(1000000000),
      chainId: 1337,
      blockNumber: 12345678,
      blockHash: ethers.keccak256(ethers.toUtf8Bytes(`block-${Date.now()}`)),
      index: 0,
      type: 0,
      wait: async () => ({
        status: 1,
        blockNumber: 12345678,
        blockHash: ethers.keccak256(ethers.toUtf8Bytes(`block-${Date.now()}`)),
        index: 0,
        logs: [],
        gasUsed: BigInt(50000),
        cumulativeGasUsed: BigInt(50000),
        type: 0,
        from: (await this.signer?.getAddress()) || "",
        to: "0x0000000000000000000000000000000000000000",
      }),
    } as unknown as TransactionResponse;

    return mockTx;
  }
}
