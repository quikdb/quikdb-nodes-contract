import { ethers } from "ethers";
import { BaseModule, TransactionResponse } from "../types/common.types";
import {
  NodeInfo,
  NodeStatus,
  NodeTier,
  ProviderType,
  NodeExtendedInfo,
} from "../types/node.types";
import { mockNodes, getMockNodeInfo } from "../../examples/mock-data";

/**
 * Mock implementation of NodeModule for testing without a blockchain
 *
 * This module provides all the functionality of the standard NodeModule
 * but uses in-memory mock data instead of making actual blockchain calls.
 * This is useful for:
 * - Local development without a blockchain connection
 * - Writing tests that don't depend on external services
 * - Demonstrating SDK features without a real contract deployment
 *
 * Usage:
 * ```typescript
 * // Create a mock node module
 * const mockNodeModule = new MockNodeModule(provider, contractAddress, signer);
 *
 * // Use it directly
 * const nodes = await mockNodeModule.getNodesList();
 *
 * // Or use it in the SDK (careful with types)
 * const sdk = new QuikDBNodesSDK({ ... });
 * const nodeModule = mockNodeModule; // Use the mock instance
 * ```
 */
export class MockNodeModule implements BaseModule {
  private mockNodes: typeof mockNodes;
  private provider: ethers.Provider;
  private signer?: ethers.Signer;
  // Add a contract property to satisfy the NodeModule interface
  private contract: ethers.Contract;

  constructor(
    provider: ethers.Provider,
    contractAddress: string,
    signer?: ethers.Signer
  ) {
    this.provider = provider;
    this.signer = signer;
    this.mockNodes = [...mockNodes]; // Use a copy of mock nodes

    // Create a dummy contract object to satisfy type requirements
    this.contract = new ethers.Contract(
      contractAddress,
      [], // Empty ABI since we're not using the contract
      provider
    );
  }

  connect(provider: ethers.Provider): void {
    this.provider = provider;
  }

  setSigner(signer: ethers.Signer): void {
    this.signer = signer;
  }

  async getNodeInfo(nodeId: string): Promise<NodeInfo> {
    // Check if the node exists in our mock data
    const node = this.mockNodes.find((n) => n.nodeId === nodeId);

    // Get mock node info and explicitly cast it to NodeInfo to ensure type compatibility
    const mockInfo = node
      ? getMockNodeInfo(node.nodeId)
      : getMockNodeInfo(nodeId);

    return mockInfo as unknown as NodeInfo;
  }

  async registerNode(
    nodeId: string,
    nodeAddress: string,
    tier: NodeTier,
    providerType: ProviderType
  ): Promise<TransactionResponse> {
    if (!this.signer) {
      throw new Error("Signer required for this operation");
    }

    // Add to mock nodes
    this.mockNodes.push({
      nodeId,
      address: nodeAddress,
      status: NodeStatus.PENDING,
      tier,
      providerType,
      registeredAt: Math.floor(Date.now() / 1000),
    });

    // Return mock transaction response
    return this.mockTransactionResponse(`register-${nodeId}`);
  }

  async updateNodeStatus(
    nodeId: string,
    status: NodeStatus
  ): Promise<TransactionResponse> {
    if (!this.signer) {
      throw new Error("Signer required for this operation");
    }

    // Update mock node status
    const node = this.mockNodes.find((n) => n.nodeId === nodeId);
    if (node) {
      node.status = status;
    }

    // Return mock transaction response
    return this.mockTransactionResponse(`status-${nodeId}`);
  }

  async listNode(
    nodeId: string,
    hourlyRate: string,
    availability: number
  ): Promise<TransactionResponse> {
    if (!this.signer) {
      throw new Error("Signer required for this operation");
    }

    // Update node status to ACTIVE when listed
    const node = this.mockNodes.find((n) => n.nodeId === nodeId);
    if (node) {
      node.status = NodeStatus.ACTIVE;
    }

    // Return mock transaction response
    return this.mockTransactionResponse(`list-${nodeId}`);
  }

  async getNodesList(
    page: number = 0,
    pageSize: number = 10,
    filter?: {
      status?: NodeStatus;
      tier?: NodeTier;
      providerType?: ProviderType;
      isActive?: boolean;
    }
  ): Promise<{
    nodes: string[];
    totalNodes: number;
    totalPages: number;
    currentPage: number;
    hasNextPage: boolean;
    hasPreviousPage: boolean;
  }> {
    // Input validation
    if (page < 0) page = 0;
    if (pageSize <= 0) pageSize = 10;
    if (pageSize > 100) pageSize = 100; // Set a reasonable limit

    // Apply filters if provided
    let filteredNodes = [...this.mockNodes];

    if (filter) {
      try {
        // Validate filter values
        if (
          filter.status !== undefined &&
          (filter.status < 0 || filter.status > 7)
        ) {
          console.warn(`Invalid node status filter: ${filter.status}`);
          filter.status = undefined;
        }

        if (filter.tier !== undefined && (filter.tier < 0 || filter.tier > 5)) {
          console.warn(`Invalid node tier filter: ${filter.tier}`);
          filter.tier = undefined;
        }

        if (
          filter.providerType !== undefined &&
          (filter.providerType < 0 || filter.providerType > 2)
        ) {
          console.warn(`Invalid provider type filter: ${filter.providerType}`);
          filter.providerType = undefined;
        }

        // Apply filters
        if (filter.status !== undefined) {
          filteredNodes = filteredNodes.filter(
            (node) => node.status === filter.status
          );
        }

        if (filter.tier !== undefined) {
          filteredNodes = filteredNodes.filter(
            (node) => node.tier === filter.tier
          );
        }

        if (filter.providerType !== undefined) {
          filteredNodes = filteredNodes.filter(
            (node) => node.providerType === filter.providerType
          );
        }

        if (filter.isActive !== undefined) {
          filteredNodes = filteredNodes.filter(
            (node) =>
              (filter.isActive && node.status === NodeStatus.ACTIVE) ||
              (!filter.isActive && node.status !== NodeStatus.ACTIVE)
          );
        }
      } catch (error) {
        console.error("Error applying filters:", error);
      }
    }

    // Extract node IDs
    const nodeIds = filteredNodes.map((node) => node.nodeId);
    const totalNodes = nodeIds.length;

    // Calculate pagination parameters
    const totalPages = Math.ceil(totalNodes / pageSize) || 1; // At least 1 page
    const startIdx = page * pageSize;
    const endIdx = Math.min(startIdx + pageSize, totalNodes);

    // Get the requested page of nodes
    const pageNodeIds = nodeIds.slice(startIdx, endIdx);

    return {
      nodes: pageNodeIds,
      totalNodes,
      totalPages,
      currentPage: page,
      hasNextPage: page < totalPages - 1,
      hasPreviousPage: page > 0,
    };
  }

  // Additional methods follow the same pattern - implement as needed
  async updateNodeExtendedInfo(
    nodeId: string,
    extended: NodeExtendedInfo
  ): Promise<TransactionResponse> {
    return this.mockTransactionResponse(`extended-${nodeId}`);
  }

  async setNodeCustomAttribute(
    nodeId: string,
    key: string,
    value: string
  ): Promise<TransactionResponse> {
    return this.mockTransactionResponse(`attribute-${nodeId}-${key}`);
  }

  async getNodeCustomAttribute(nodeId: string, key: string): Promise<string> {
    return `Mock attribute value for ${nodeId}:${key}`;
  }

  async addNodeCertification(
    nodeId: string,
    certificationId: string,
    details: string
  ): Promise<TransactionResponse> {
    return this.mockTransactionResponse(
      `certification-${nodeId}-${certificationId}`
    );
  }

  async getNodeCertifications(nodeId: string): Promise<string[]> {
    // Generate some mock certifications based on the node ID
    const nodeNumber = parseInt(nodeId.split("-").pop() || "0");
    const certifications = [];

    for (let i = 0; i < (nodeNumber % 5) + 1; i++) {
      certifications.push(`CERT-${i}-${nodeId}`);
    }

    return certifications;
  }

  async getTotalNodes(): Promise<number> {
    return this.mockNodes.length;
  }

  async getNodesByTier(tier: NodeTier): Promise<string[]> {
    return this.mockNodes
      .filter((node) => node.tier === tier)
      .map((node) => node.nodeId);
  }

  async getNodesByStatus(status: NodeStatus): Promise<string[]> {
    return this.mockNodes
      .filter((node) => node.status === status)
      .map((node) => node.nodeId);
  }

  async getAllNodeIds(): Promise<string[]> {
    return this.mockNodes.map((node) => node.nodeId);
  }

  async updateNodeCapacity(
    nodeId: string,
    cpuCores: number,
    memoryGB: number,
    storageGB: number,
    networkMbps: number,
    gpuCount: number,
    gpuType: string
  ): Promise<TransactionResponse> {
    return this.mockTransactionResponse(`capacity-${nodeId}`);
  }

  // Helper method to generate mock transaction responses
  private mockTransactionResponse(operationId: string): TransactionResponse {
    // Create a more compliant mock transaction response
    const mockTx = {
      hash: ethers.keccak256(
        ethers.toUtf8Bytes(`${operationId}-${Date.now()}`)
      ),
      confirmations: 1,
      from: "0x0000000000000000000000000000000000000000",
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
        from: "0x0000000000000000000000000000000000000000",
        to: "0x0000000000000000000000000000000000000000",
      }),
    } as unknown as TransactionResponse;

    return mockTx;
  }
}
