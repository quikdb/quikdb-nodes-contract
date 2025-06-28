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
}
