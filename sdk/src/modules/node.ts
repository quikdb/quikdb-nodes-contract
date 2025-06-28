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
    return await this.contract.getNodeInfo(nodeId);
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
    return await this.contract.getTotalNodes();
  }

  /**
   * Get nodes by tier
   * @param tier Node tier
   * @returns Array of node IDs
   */
  async getNodesByTier(tier: NodeTier): Promise<string[]> {
    return await this.contract.getNodesByTier(tier);
  }

  /**
   * Get nodes by status
   * @param status Node status
   * @returns Array of node IDs
   */
  async getNodesByStatus(status: NodeStatus): Promise<string[]> {
    return await this.contract.getNodesByStatus(status);
  }
}
