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
  signer?: ethers.Signer; // Alternative to privateKey
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
    // Initialize provider with Lisk Sepolia network settings
    if (typeof config.provider === "string") {
      // Default to Lisk Sepolia if string provider is given
      this.provider = new ethers.JsonRpcProvider(config.provider, {
        chainId: 4202, // Lisk Sepolia chain ID
        name: "lisk-sepolia",
      });
    } else {
      this.provider = config.provider;
    }

    // Initialize signer if provided directly or through privateKey
    if (config.signer) {
      this.signer = config.signer;
    } else if (config.privateKey) {
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
   * @param chainId Optional chain ID (defaults to Lisk Sepolia 4202)
   */
  connect(provider: string | ethers.Provider, chainId: number = 4202): void {
    if (typeof provider === "string") {
      this.provider = new ethers.JsonRpcProvider(provider, {
        chainId: chainId,
        name: chainId === 4202 ? "lisk-sepolia" : `chain-${chainId}`,
      });
    } else {
      this.provider = provider;
    }

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
