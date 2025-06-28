import { ethers } from "ethers";
import { NodeModule } from "./modules/node";
import { UserModule } from "./modules/user";
import { ResourceModule } from "./modules/resource";

export interface SDKConfig {
  provider: string | ethers.Provider;
  nodeStorageAddress: string;
  userStorageAddress: string;
  resourceStorageAddress: string;
  privateKey?: string;
}

export class QuikDBNodesSDK {
  provider: ethers.Provider;
  signer?: ethers.Signer;
  node: NodeModule;
  user: UserModule;
  resource: ResourceModule;

  /**
   * Create a new SDK instance
   * @param config SDK configuration
   */
  constructor(config: SDKConfig) {
    // Initialize provider
    this.provider =
      typeof config.provider === "string"
        ? new ethers.JsonRpcProvider(config.provider)
        : config.provider;

    // Initialize signer if privateKey provided
    if (config.privateKey) {
      this.signer = new ethers.Wallet(config.privateKey, this.provider);
    }

    // Initialize modules
    this.node = new NodeModule(
      this.provider,
      config.nodeStorageAddress,
      this.signer
    );

    this.user = new UserModule(
      this.provider,
      config.userStorageAddress,
      this.signer
    );

    this.resource = new ResourceModule(
      this.provider,
      config.resourceStorageAddress,
      this.signer
    );
  }

  /**
   * Set a new signer for the SDK
   * @param signer Ethers signer
   */
  setSigner(signer: ethers.Signer): void {
    this.signer = signer;
    this.node.setSigner(signer);
    this.user.setSigner(signer);
    this.resource.setSigner(signer);
  }

  /**
   * Connect to a new provider
   * @param provider Ethers provider or RPC URL
   */
  connect(provider: string | ethers.Provider): void {
    this.provider =
      typeof provider === "string"
        ? new ethers.JsonRpcProvider(provider)
        : provider;

    // Reconnect signer if it exists
    if (this.signer) {
      this.signer = this.signer.connect(this.provider);
    }

    // Reconnect modules
    this.node.connect(this.provider);
    this.user.connect(this.provider);
    this.resource.connect(this.provider);
  }
}
