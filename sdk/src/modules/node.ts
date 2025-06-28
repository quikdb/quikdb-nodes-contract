import { ethers } from "ethers";
import { BaseModule, TransactionResponse } from "../types/common.types";
import {
  NodeInfo,
  NodeStatus,
  NodeTier,
  ProviderType,
  NodeExtendedInfo,
} from "../types/node.types";
import NodeStorageABI from "../abis/NodeStorage.json";

export class NodeModule implements BaseModule {
  updateNodeCapacity(
    nodeId: string,
    arg1: number,
    arg2: number,
    arg3: number,
    arg4: number,
    arg5: number,
    arg6: string
  ) {
    throw new Error("Method not implemented.");
  }
  private provider: ethers.Provider;
  private contract: ethers.Contract;
  private signer?: ethers.Signer;

  /**
   * Initialize the Node module
   * @param provider Ethers provider
   * @param contractAddress Address of the NodeStorage contract
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
      NodeStorageABI.abi,
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
   * Get node information
   * @param nodeId Node identifier
   * @returns Node information
   */
  async getNodeInfo(nodeId: string): Promise<NodeInfo> {
    try {
      return await this.contract.getNodeInfo(nodeId);
    } catch (error: any) {
      console.warn(`Error fetching info for node ${nodeId}:`, error);
      throw new Error(
        `Failed to get node info for ${nodeId}: ${
          error.message || "Unknown error"
        }`
      );
    }
  }

  /**
   * Register a new node
   * @param nodeId Unique identifier for the node
   * @param nodeAddress Address of the node operator
   * @param tier Tier of the node
   * @param providerType Type of provider (compute/storage)
   * @returns Transaction response
   */
  async registerNode(
    nodeId: string,
    nodeAddress: string,
    tier: NodeTier,
    providerType: ProviderType
  ): Promise<TransactionResponse> {
    if (!this.signer) {
      throw new Error("Signer required for this operation");
    }

    return await this.contract.registerNode(
      nodeId,
      nodeAddress,
      tier,
      providerType
    );
  }

  /**
   * Update node status
   * @param nodeId Node identifier
   * @param status New status
   * @returns Transaction response
   */
  async updateNodeStatus(
    nodeId: string,
    status: NodeStatus
  ): Promise<TransactionResponse> {
    if (!this.signer) {
      throw new Error("Signer required for this operation");
    }

    return await this.contract.updateNodeStatus(nodeId, status);
  }

  /**
   * List node for provider services
   * @param nodeId Node identifier
   * @param hourlyRate Hourly rate for services
   * @param availability Availability percentage (0-100)
   * @returns Transaction response
   */
  async listNode(
    nodeId: string,
    hourlyRate: string,
    availability: number
  ): Promise<TransactionResponse> {
    if (!this.signer) {
      throw new Error("Signer required for this operation");
    }

    return await this.contract.listNode(nodeId, hourlyRate, availability);
  }

  /**
   * Get a paginated list of nodes
   * @param page Page number (0-based)
   * @param pageSize Number of nodes per page
   * @param filter Optional filter criteria (status, tier, etc)
   * @returns Array of node IDs and pagination info
   */
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

    let totalNodes: number;
    let nodes: string[] = [];

    try {
      // Apply filters if provided
      if (filter) {
        try {
          if (filter.status !== undefined) {
            try {
              nodes = await this.getNodesByStatus(filter.status);
            } catch (error) {
              console.warn(
                `Failed to get nodes by status ${filter.status}:`,
                error
              );
              nodes = [];
            }
          } else if (filter.tier !== undefined) {
            try {
              nodes = await this.getNodesByTier(filter.tier);
            } catch (error) {
              console.warn(
                `Failed to get nodes by tier ${filter.tier}:`,
                error
              );
              nodes = [];
            }
          } else {
            // Get all node IDs if no specific filter
            nodes = await this.getAllNodeIds();
          }

          // Further filter by provider type or active status if needed
          if (
            filter.providerType !== undefined ||
            filter.isActive !== undefined
          ) {
            const filteredNodes = [];

            for (const nodeId of nodes) {
              try {
                const nodeInfo = await this.getNodeInfo(nodeId);
                let matches = true;

                if (
                  filter.providerType !== undefined &&
                  nodeInfo.providerType !== filter.providerType
                ) {
                  matches = false;
                }

                if (
                  filter.isActive !== undefined &&
                  ((filter.isActive && nodeInfo.status !== NodeStatus.ACTIVE) ||
                    (!filter.isActive && nodeInfo.status === NodeStatus.ACTIVE))
                ) {
                  matches = false;
                }

                if (matches) {
                  filteredNodes.push(nodeId);
                }
              } catch (error) {
                console.warn(`Failed to get info for node ${nodeId}:`, error);
                // Skip this node
              }
            }

            nodes = filteredNodes;
          }

          totalNodes = nodes.length;
        } catch (filterError) {
          console.error("Error applying filters:", filterError);
          nodes = [];
          totalNodes = 0;
        }
      } else {
        // Get all node IDs if no filter
        try {
          nodes = await this.getAllNodeIds();
        } catch (error) {
          console.error("Failed to get all node IDs:", error);
          nodes = [];
        }
        totalNodes = nodes.length;
      }

      // Calculate pagination parameters
      const totalPages = Math.ceil(totalNodes / pageSize) || 1; // Minimum 1 page
      const startIdx = page * pageSize;
      const endIdx = Math.min(startIdx + pageSize, totalNodes);

      // Get the requested page of nodes
      const pageNodes = nodes.slice(startIdx, endIdx);

      return {
        nodes: pageNodes,
        totalNodes,
        totalPages,
        currentPage: page,
        hasNextPage: page < totalPages - 1,
        hasPreviousPage: page > 0,
      };
    } catch (error) {
      console.error("Error in getNodesList:", error);
      // Return empty results with proper pagination structure
      return {
        nodes: [],
        totalNodes: 0,
        totalPages: 1,
        currentPage: 0,
        hasNextPage: false,
        hasPreviousPage: false,
      };
    }
  }

  /**
   * Update node extended information
   * @param nodeId Node identifier
   * @param extended Extended information
   * @returns Transaction response
   */
  async updateNodeExtendedInfo(
    nodeId: string,
    extended: NodeExtendedInfo
  ): Promise<TransactionResponse> {
    if (!this.signer) {
      throw new Error("Signer required for this operation");
    }

    return await this.contract.updateNodeExtendedInfo(nodeId, extended);
  }

  /**
   * Set custom attribute for a node
   * @param nodeId Node identifier
   * @param key Attribute key
   * @param value Attribute value
   * @returns Transaction response
   */
  async setNodeCustomAttribute(
    nodeId: string,
    key: string,
    value: string
  ): Promise<TransactionResponse> {
    if (!this.signer) {
      throw new Error("Signer required for this operation");
    }

    return await this.contract.setNodeCustomAttribute(nodeId, key, value);
  }

  /**
   * Get node custom attribute
   * @param nodeId Node identifier
   * @param key Attribute key
   * @returns Attribute value
   */
  async getNodeCustomAttribute(nodeId: string, key: string): Promise<string> {
    return await this.contract.getNodeCustomAttribute(nodeId, key);
  }

  /**
   * Add certification to a node
   * @param nodeId Node identifier
   * @param certificationId Certification identifier
   * @param details Certification details
   * @returns Transaction response
   */
  async addNodeCertification(
    nodeId: string,
    certificationId: string,
    details: string
  ): Promise<TransactionResponse> {
    if (!this.signer) {
      throw new Error("Signer required for this operation");
    }

    return await this.contract.addNodeCertification(
      nodeId,
      ethers.encodeBytes32String(certificationId),
      details
    );
  }

  /**
   * Get node certifications
   * @param nodeId Node identifier
   * @returns Array of certification IDs
   */
  async getNodeCertifications(nodeId: string): Promise<string[]> {
    const certifications = await this.contract.getNodeCertifications(nodeId);
    // Convert bytes32 values to strings
    return certifications.map((cert: string) =>
      ethers.decodeBytes32String(cert)
    );
  }

  /**
   * Get total number of nodes
   * @returns Total number of nodes
   */
  async getTotalNodes(): Promise<number> {
    try {
      const result = await this.contract.getTotalNodes();
      return Number(result);
    } catch (error) {
      console.warn("Failed to get total nodes directly:", error);
      console.log("Falling back to node count estimation...");

      // Fallback: Try to estimate based on available nodes
      try {
        // Try to get nodes by different statuses and aggregate
        const pendingNodes = await this.getNodesByStatus(NodeStatus.PENDING);
        const activeNodes = await this.getNodesByStatus(NodeStatus.ACTIVE);
        const inactiveNodes = await this.getNodesByStatus(NodeStatus.INACTIVE);
        const suspendedNodes = await this.getNodesByStatus(
          NodeStatus.SUSPENDED
        );

        const uniqueNodeIds = new Set([
          ...pendingNodes,
          ...activeNodes,
          ...inactiveNodes,
          ...suspendedNodes,
        ]);

        return uniqueNodeIds.size;
      } catch (fallbackError) {
        console.warn("Fallback estimation failed:", fallbackError);
        // Last resort: Return a default value
        return 0;
      }
    }
  }

  /**
   * Get nodes by tier
   * @param tier Node tier
   * @returns Array of node IDs
   */
  async getNodesByTier(tier: NodeTier): Promise<string[]> {
    try {
      return await this.contract.getNodesByTier(tier);
    } catch (error: any) {
      console.warn(`Error getting nodes by tier ${tier}:`, error);
      return [];
    }
  }

  /**
   * Get nodes by status
   * @param status Node status
   * @returns Array of node IDs
   */
  async getNodesByStatus(status: NodeStatus): Promise<string[]> {
    try {
      return await this.contract.getNodesByStatus(status);
    } catch (error: any) {
      console.warn(`Error getting nodes by status ${status}:`, error);
      return [];
    }
  }
  /**
   * Get all node IDs
   * @returns Array of all node IDs
   */
  async getAllNodeIds(): Promise<string[]> {
    // Try multiple strategies to get all node IDs
    try {
      // Strategy 1: Direct method if it exists
      try {
        return await this.contract.getAllNodeIds();
      } catch (error) {
        console.log(
          "Direct getAllNodeIds method not available, trying alternative approaches..."
        );
      }

      // Strategy 2: Get nodes by index
      try {
        const total = await this.getTotalNodes();
        if (total > 0) {
          const nodeIds: string[] = [];

          for (let i = 0; i < total; i++) {
            try {
              const nodeId = await this.contract.getNodeIdByIndex(i);
              nodeIds.push(nodeId);
            } catch (e) {
              console.warn(`Failed to get node at index ${i}, continuing...`);
            }
          }

          if (nodeIds.length > 0) {
            return nodeIds;
          }
        }
      } catch (error) {
        console.log(
          "Index-based node retrieval failed, trying next approach..."
        );
      }

      // Strategy 3: Combine nodes from different statuses
      const pendingNodes = await this.getNodesByStatus(
        NodeStatus.PENDING
      ).catch(() => []);
      const activeNodes = await this.getNodesByStatus(NodeStatus.ACTIVE).catch(
        () => []
      );
      const inactiveNodes = await this.getNodesByStatus(
        NodeStatus.INACTIVE
      ).catch(() => []);
      const suspendedNodes = await this.getNodesByStatus(
        NodeStatus.SUSPENDED
      ).catch(() => []);

      // Combine and deduplicate
      const uniqueNodeIds = [
        ...new Set([
          ...pendingNodes,
          ...activeNodes,
          ...inactiveNodes,
          ...suspendedNodes,
        ]),
      ];

      if (uniqueNodeIds.length > 0) {
        return uniqueNodeIds;
      }

      // Strategy 4: Look for recent events as a last resort
      console.log("Using empty array as fallback for node IDs");
      return [];
    } catch (error) {
      console.error("Failed to retrieve node IDs:", error);
      return [];
    }
  }
}
