import { ethers } from "ethers";
import { BaseModule, TransactionResponse } from "../types/common.types";
import {
  ComputeTier,
  StorageTier,
  ComputeListing,
  StorageListing,
  ComputeAllocation,
} from "../types/resource.types";
import ResourceStorageJSON from "../abis/ResourceStorage.json";
const ResourceStorageABI = ResourceStorageJSON.abi;

export class ResourceModule implements BaseModule {
  updateComputeListingFeatures(listingId: string, arg1: string[]) {
    throw new Error("Method not implemented.");
  }
  private provider: ethers.Provider;
  private contract: ethers.Contract;
  private signer?: ethers.Signer;

  /**
   * Initialize the Resource module
   * @param provider Ethers provider
   * @param contractAddress Address of the ResourceStorage contract
   * @param signer Optional signer for transactions
   */
  constructor(
    provider: ethers.Provider,
    contractAddress: string,
    signer?: ethers.Signer
  ) {
    this.provider = provider;
    this.contract = new ethers.Contract(
      contractAddress,
      ResourceStorageABI,
      provider
    );

    if (signer) {
      this.signer = signer;
      this.contract = this.contract.connect(signer) as ethers.Contract;
    }
  }

  /**
   * Connect to a new provider
   * @param provider Ethers provider
   */
  connect(provider: ethers.Provider): void {
    this.provider = provider;
    this.contract = this.contract.connect(provider) as ethers.Contract;

    if (this.signer) {
      this.signer = this.signer.connect(provider);
      this.contract = this.contract.connect(this.signer) as ethers.Contract;
    }
  }

  /**
   * Set a new signer for transactions
   * @param signer Ethers signer
   */
  setSigner(signer: ethers.Signer): void {
    this.signer = signer;
    this.contract = this.contract.connect(signer) as ethers.Contract;
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

    const tx = await this.contract.createComputeListing(
      nodeId,
      tier,
      cpuCores,
      memoryGB,
      storageGB,
      hourlyRate,
      region
    );

    // Wait for transaction confirmation to get the event
    const receipt = await tx.wait();
    // Find event and extract listingId
    // This is a simplified approach and may need adjustment based on actual event structure
    const event = receipt.logs
      .filter(
        (log: { topics: string[] }) =>
          log.topics[0] ===
          ethers.id("ComputeListingCreated(bytes32,string,uint8,uint256)")
      )
      .map((log: { topics: ReadonlyArray<string>; data: string }) =>
        this.contract.interface.parseLog(log)
      )[0];

    return event.args.listingId;
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

    const tx = await this.contract.createStorageListing(
      nodeId,
      tier,
      storageGB,
      hourlyRate,
      region
    );

    // Wait for transaction confirmation to get the event
    const receipt = await tx.wait();
    // Find event and extract listingId
    const event = receipt.logs
      .filter(
        (log: { topics: string[] }) =>
          log.topics[0] ===
          ethers.id("StorageListingCreated(bytes32,string,uint8,uint256)")
      )
      .map((log: { topics: ReadonlyArray<string>; data: string }) =>
        this.contract.interface.parseLog(log)
      )[0];

    return event.args.listingId;
  }

  /**
   * Get compute listing
   * @param listingId Listing identifier
   * @returns Compute listing details
   */
  async getComputeListing(listingId: string): Promise<ComputeListing> {
    return await this.contract.getComputeListing(listingId);
  }

  /**
   * Get storage listing
   * @param listingId Listing identifier
   * @returns Storage listing details
   */
  async getStorageListing(listingId: string): Promise<StorageListing> {
    return await this.contract.getStorageListing(listingId);
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

    const tx = await this.contract.purchaseCompute(listingId, duration, {
      value: paymentAmount,
    });

    // Wait for transaction confirmation to get the event
    const receipt = await tx.wait();
    // Find event and extract allocationId
    const event = receipt.logs
      .filter(
        (log: { topics: string[] }) =>
          log.topics[0] ===
          ethers.id("ComputeResourceAllocated(bytes32,address,bytes32,uint256)")
      )
      .map((log: { topics: ReadonlyArray<string>; data: string }) =>
        this.contract.interface.parseLog(log)
      )[0];

    return event.args.allocationId;
  }

  /**
   * Get compute allocation
   * @param allocationId Allocation identifier
   * @returns Compute allocation details
   */
  async getComputeAllocation(allocationId: string): Promise<ComputeAllocation> {
    return await this.contract.getComputeAllocation(allocationId);
  }

  /**
   * Get total number of allocations
   * @returns Total number of allocations
   */
  async getTotalAllocations(): Promise<number> {
    return await this.contract.getTotalAllocations();
  }

  /**
   * Get compute listings with pagination and filtering
   * @param page Page number (0-based)
   * @param pageSize Number of listings per page
   * @param filter Optional filter criteria (tier, region, isActive)
   * @returns Array of compute listing IDs and pagination info
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

    let totalListings: number;
    let listings: string[] = [];

    try {
      // Get all listing IDs - implementation depends on contract capabilities
      try {
        // Try to get all listing IDs directly if the method exists
        listings = await this.getAllComputeListingIds();
      } catch (error) {
        console.warn("Failed to get all compute listing IDs directly:", error);

        // Fallback to estimating from total count if available
        try {
          const totalCount = await this.getTotalComputeListings();

          // Build list of IDs by index - depends on contract supporting index-based access
          for (let i = 0; i < totalCount; i++) {
            try {
              const listingId = await this.getComputeListingIdByIndex(i);
              listings.push(listingId);
            } catch (err) {
              console.warn(`Failed to get compute listing at index ${i}:`, err);
            }
          }
        } catch (countError) {
          console.warn("Failed to get total compute listings:", countError);
          listings = [];
        }
      }

      // Apply filters if provided
      if (filter) {
        const filteredListings = [];

        for (const listingId of listings) {
          try {
            const listing = await this.getComputeListing(listingId);
            let matches = true;

            // Apply tier filter
            if (filter.tier !== undefined && listing.tier !== filter.tier) {
              matches = false;
            }

            // Apply region filter (case insensitive)
            if (
              filter.region !== undefined &&
              listing.region.toLowerCase() !== filter.region.toLowerCase()
            ) {
              matches = false;
            }

            // Apply active status filter
            if (
              filter.isActive !== undefined &&
              listing.isActive !== filter.isActive
            ) {
              matches = false;
            }

            // Apply CPU cores filter
            if (
              filter.minCpuCores !== undefined &&
              listing.cpuCores < filter.minCpuCores
            ) {
              matches = false;
            }

            // Apply hourly rate filter
            if (filter.maxHourlyRate !== undefined) {
              const maxRate = BigInt(filter.maxHourlyRate);
              const listingRate = BigInt(listing.hourlyRate);
              if (listingRate > maxRate) {
                matches = false;
              }
            }

            if (matches) {
              filteredListings.push(listingId);
            }
          } catch (error) {
            console.warn(
              `Failed to get details for listing ${listingId}:`,
              error
            );
          }
        }

        listings = filteredListings;
      }

      totalListings = listings.length;

      // Calculate pagination parameters
      const totalPages = Math.ceil(totalListings / pageSize) || 1; // At least 1 page
      const startIdx = page * pageSize;
      const endIdx = Math.min(startIdx + pageSize, totalListings);

      // Get the requested page of listings
      const pageListings = listings.slice(startIdx, endIdx);

      return {
        listings: pageListings,
        totalListings,
        totalPages,
        currentPage: page,
        hasNextPage: page < totalPages - 1,
        hasPreviousPage: page > 0,
      };
    } catch (error) {
      console.error("Error in getComputeListings:", error);
      // Return empty results with proper pagination structure
      return {
        listings: [],
        totalListings: 0,
        totalPages: 1,
        currentPage: 0,
        hasNextPage: false,
        hasPreviousPage: false,
      };
    }
  }

  /**
   * Update a listing's status (active/inactive)
   * @param listingId ID of the listing to update
   * @param isActive New status for the listing
   * @returns Transaction response
   */
  async updateListingStatus(
    listingId: string,
    isActive: boolean
  ): Promise<TransactionResponse> {
    if (!this.signer) {
      throw new Error("Signer required for this operation");
    }

    return await this.contract.updateListingStatus(listingId, isActive);
  }

  /**
   * Get the total number of resource listings across all types
   * @returns Total number of listings
   */
  async getTotalListings(): Promise<number> {
    // Count both compute and storage listings
    const computeCount = await this.getTotalComputeListings();
    const storageCount = await this.getTotalStorageListings();

    return computeCount + storageCount;
  }

  /**
   * Get the total number of compute listings
   * @private
   * @returns Total number of compute listings
   */
  private async getTotalComputeListings(): Promise<number> {
    try {
      return await this.contract.getTotalComputeListings();
    } catch (error) {
      console.error("Error in getTotalComputeListings:", error);
      return 0;
    }
  }

  /**
   * Get the total number of storage listings
   * @private
   * @returns Total number of storage listings
   */
  private async getTotalStorageListings(): Promise<number> {
    try {
      return await this.contract.getTotalStorageListings();
    } catch (error) {
      console.error("Error in getTotalStorageListings:", error);
      return 0;
    }
  }

  /**
   * Get compute listing ID by index
   * @param index Listing index
   * @returns Listing ID
   */
  async getComputeListingIdByIndex(index: number): Promise<string> {
    try {
      // Try to call contract method if it exists
      return await this.contract.getComputeListingIdByIndex(index);
    } catch (error) {
      throw new Error(
        `Failed to get compute listing ID at index ${index}: ${error}`
      );
    }
  }

  /**
   * Get all compute listing IDs
   * @returns Array of all compute listing IDs
   */
  async getAllComputeListingIds(): Promise<string[]> {
    try {
      // Try to call contract method if it exists
      return await this.contract.getAllComputeListingIds();
    } catch (error) {
      throw new Error(`Failed to get all compute listing IDs: ${error}`);
    }
  }

  /**
   * Get storage listings with pagination and filtering
   * @param page Page number (0-based)
   * @param pageSize Number of listings per page
   * @param filter Optional filter criteria (tier, region, isActive)
   * @returns Array of storage listing IDs and pagination info
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

    let totalListings: number;
    let listings: string[] = [];

    try {
      // Get all listing IDs - implementation depends on contract capabilities
      try {
        // Try to get all listing IDs directly if the method exists
        listings = await this.getAllStorageListingIds();
      } catch (error) {
        console.warn("Failed to get all storage listing IDs directly:", error);

        // Fallback to estimating from total count if available
        try {
          const totalCount = await this.getTotalStorageListings();

          // Build list of IDs by index - depends on contract supporting index-based access
          for (let i = 0; i < totalCount; i++) {
            try {
              const listingId = await this.getStorageListingIdByIndex(i);
              listings.push(listingId);
            } catch (err) {
              console.warn(`Failed to get storage listing at index ${i}:`, err);
            }
          }
        } catch (countError) {
          console.warn("Failed to get total storage listings:", countError);
          listings = [];
        }
      }

      // Apply filters if provided
      if (filter) {
        const filteredListings = [];

        for (const listingId of listings) {
          try {
            const listing = await this.getStorageListing(listingId);
            let matches = true;

            // Apply tier filter
            if (filter.tier !== undefined && listing.tier !== filter.tier) {
              matches = false;
            }

            // Apply region filter (case insensitive)
            if (
              filter.region !== undefined &&
              listing.region.toLowerCase() !== filter.region.toLowerCase()
            ) {
              matches = false;
            }

            // Apply active status filter
            if (
              filter.isActive !== undefined &&
              listing.isActive !== filter.isActive
            ) {
              matches = false;
            }

            // Apply storage capacity filter
            if (
              filter.minStorageGB !== undefined &&
              listing.storageGB < filter.minStorageGB
            ) {
              matches = false;
            }

            // Apply hourly rate filter
            if (filter.maxHourlyRate !== undefined) {
              const maxRate = BigInt(filter.maxHourlyRate);
              const listingRate = BigInt(listing.hourlyRate);
              if (listingRate > maxRate) {
                matches = false;
              }
            }

            if (matches) {
              filteredListings.push(listingId);
            }
          } catch (error) {
            console.warn(
              `Failed to get details for listing ${listingId}:`,
              error
            );
          }
        }

        listings = filteredListings;
      }

      totalListings = listings.length;

      // Calculate pagination parameters
      const totalPages = Math.ceil(totalListings / pageSize) || 1; // At least 1 page
      const startIdx = page * pageSize;
      const endIdx = Math.min(startIdx + pageSize, totalListings);

      // Get the requested page of listings
      const pageListings = listings.slice(startIdx, endIdx);

      return {
        listings: pageListings,
        totalListings,
        totalPages,
        currentPage: page,
        hasNextPage: page < totalPages - 1,
        hasPreviousPage: page > 0,
      };
    } catch (error) {
      console.error("Error in getStorageListings:", error);
      // Return empty results with proper pagination structure
      return {
        listings: [],
        totalListings: 0,
        totalPages: 1,
        currentPage: 0,
        hasNextPage: false,
        hasPreviousPage: false,
      };
    }
  }

  /**
   * Get storage listing ID by index
   * @param index Listing index
   * @returns Listing ID
   */
  async getStorageListingIdByIndex(index: number): Promise<string> {
    try {
      // Try to call contract method if it exists
      return await this.contract.getStorageListingIdByIndex(index);
    } catch (error) {
      throw new Error(
        `Failed to get storage listing ID at index ${index}: ${error}`
      );
    }
  }

  /**
   * Get all storage listing IDs
   * @returns Array of all storage listing IDs
   */
  async getAllStorageListingIds(): Promise<string[]> {
    try {
      // Try to call contract method if it exists
      return await this.contract.getAllStorageListingIds();
    } catch (error) {
      throw new Error(`Failed to get all storage listing IDs: ${error}`);
    }
  }

  /**
   * Get compute listing details by ID
   * @param listingId The ID of the compute listing
   * @returns Compute listing details
   */
  async getComputeListingById(listingId: string): Promise<ComputeListing> {
    try {
      const listing = await this.contract.getComputeListingById(listingId);
      return {
        listingId,
        nodeId: listing.nodeId,
        nodeAddress:
          listing.nodeAddress || "0x0000000000000000000000000000000000000000",
        resourceType: 0, // compute type
        tier: listing.tier,
        cpuCores: listing.capacity.cpuCores,
        memoryGB: listing.capacity.memoryGB,
        storageGB: listing.capacity.storageGB,
        hourlyRate: listing.price,
        region: listing.region,
        isActive: listing.isActive,
        createdAt: listing.createdAt || Math.floor(Date.now() / 1000),
      };
    } catch (error) {
      console.error(`Error fetching compute listing ${listingId}:`, error);
      throw new Error(`Failed to fetch compute listing: ${error}`);
    }
  }
}
