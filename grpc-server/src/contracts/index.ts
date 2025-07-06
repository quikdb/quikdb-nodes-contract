/**
 * Contract interaction layer for QuikDB smart contracts
 */

import { ethers, Contract, JsonRpcProvider, Wallet } from 'ethers';
import * as fs from 'fs';
import * as path from 'path';
import { config } from '../config';
import { logger } from '../utils/logger';

// Contract interfaces
export interface ContractAddresses {
  nodeStorage: string;
  userStorage: string;
  resourceStorage: string;
  nodeLogic: string;
  userLogic: string;
  resourceLogic: string;
  facade: string;
  proxyAdmin: string;
}

export interface Contracts {
  nodeLogic: Contract;
  userLogic: Contract;
  resourceLogic: Contract;
  facade: Contract;
  nodeStorage: Contract;
  userStorage: Contract;
  resourceStorage: Contract;
}

// Contract manager class
export class ContractManager {
  private provider: JsonRpcProvider;
  private signer?: Wallet;
  private contracts: Contracts | null = null;
  private addresses: ContractAddresses | null = null;

  constructor() {
    this.provider = new JsonRpcProvider(config.blockchain.rpcUrl);
    
    if (config.blockchain.privateKey) {
      this.signer = new Wallet(config.blockchain.privateKey, this.provider);
      logger.info('Contract manager initialized with signer');
    } else {
      logger.warn('Contract manager initialized without signer - read-only mode');
    }
  }

  /**
   * Initialize contracts by loading addresses and ABIs
   */
  async initialize(): Promise<void> {
    try {
      await this.loadDeploymentAddresses();
      await this.initializeContracts();
      logger.info('Contract manager initialized successfully');
    } catch (error) {
      logger.error('Failed to initialize contract manager:', error);
      throw error;
    }
  }

  /**
   * Load deployment addresses from the smart-contract deployment files
   */
  private async loadDeploymentAddresses(): Promise<void> {
    try {
      // Look for deployment files in the smart-contract directory
      const smartContractDir = path.join(__dirname, '../../../smart-contract');
      const deploymentsDir = path.join(smartContractDir, 'deployments');
      
      // Try different deployment file formats
      const possibleFiles = [
        path.join(deploymentsDir, `${config.blockchain.networkName}.json`),
        path.join(deploymentsDir, 'latest.json'),
        path.join(deploymentsDir, 'addresses.json')
      ];

      let deploymentData: any = null;
      let usedFile = '';

      for (const file of possibleFiles) {
        if (fs.existsSync(file)) {
          deploymentData = JSON.parse(fs.readFileSync(file, 'utf8'));
          usedFile = file;
          break;
        }
      }

      if (!deploymentData) {
        throw new Error(`No deployment file found. Tried: ${possibleFiles.join(', ')}`);
      }

      logger.info(`Loaded deployment addresses from: ${usedFile}`);

      // Parse different deployment file formats
      if (Array.isArray(deploymentData)) {
        // addresses.json format - get the latest deployment
        const latestDeployment = deploymentData[deploymentData.length - 1];
        this.addresses = {
          nodeStorage: latestDeployment.storage?.nodeStorage || "",
          userStorage: latestDeployment.storage?.userStorage || "",
          resourceStorage: latestDeployment.storage?.resourceStorage || "",
          // Use proxy addresses for contract interactions
          nodeLogic: latestDeployment.proxies?.nodeLogic || latestDeployment.implementations?.nodeLogic || "",
          userLogic: latestDeployment.proxies?.userLogic || latestDeployment.implementations?.userLogic || "",
          resourceLogic: latestDeployment.proxies?.resourceLogic || latestDeployment.implementations?.resourceLogic || "",
          facade: latestDeployment.proxies?.facade || latestDeployment.implementations?.facade || "",
          proxyAdmin: latestDeployment.proxies?.proxyAdmin || ""
        };
      } else if (deploymentData.addresses) {
        // Standard format with addresses object
        this.addresses = deploymentData.addresses;
      } else if (deploymentData.storage || deploymentData.implementations || deploymentData.proxies) {
        // Direct deployment format (like latest.json)
        this.addresses = {
          nodeStorage: deploymentData.storage?.nodeStorage || "",
          userStorage: deploymentData.storage?.userStorage || "",
          resourceStorage: deploymentData.storage?.resourceStorage || "",
          // Use proxy addresses for contract interactions
          nodeLogic: deploymentData.proxies?.nodeLogic || deploymentData.implementations?.nodeLogic || "",
          userLogic: deploymentData.proxies?.userLogic || deploymentData.implementations?.userLogic || "",
          resourceLogic: deploymentData.proxies?.resourceLogic || deploymentData.implementations?.resourceLogic || "",
          facade: deploymentData.proxies?.facade || deploymentData.implementations?.facade || "",
          proxyAdmin: deploymentData.proxies?.proxyAdmin || ""
        };
      } else {
        // Direct format
        this.addresses = deploymentData;
      }

      // Validate addresses
      const requiredContracts = ['nodeStorage', 'userStorage', 'resourceStorage', 'nodeLogic', 'userLogic', 'resourceLogic', 'facade'];
      const missingContracts = [];

      if (!this.addresses) {
        throw new Error('Addresses object is null');
      }

      for (const contractName of requiredContracts) {
        const address = this.addresses[contractName as keyof ContractAddresses];
        if (!address || !ethers.isAddress(address)) {
          missingContracts.push(contractName);
        }
      }

      if (missingContracts.length > 0) {
        throw new Error(`Incomplete deployment: missing ${missingContracts.join(', ')}`);
      }

      logger.info('Contract addresses validated successfully');
      
    } catch (error) {
      logger.error('Failed to load deployment addresses:', error);
      throw error;
    }
  }

  /**
   * Initialize contract instances with ABIs
   */
  private async initializeContracts(): Promise<void> {
    if (!this.addresses) {
      throw new Error('Contract addresses not loaded');
    }

    try {
      // Load contract ABIs from artifacts
      const smartContractDir = path.join(__dirname, '../../../smart-contract');
      const artifactsDir = path.join(smartContractDir, 'out');
      
      const getContractABI = (contractName: string) => {
        const artifactPath = path.join(artifactsDir, `${contractName}.sol`, `${contractName}.json`);
        if (!fs.existsSync(artifactPath)) {
          throw new Error(`Contract artifact not found: ${artifactPath}`);
        }
        const artifact = JSON.parse(fs.readFileSync(artifactPath, 'utf8'));
        return artifact.abi;
      };

      // Connect to deployed contracts (use signer if available, otherwise provider for read-only)
      const connectionTarget = this.signer || this.provider;

      this.contracts = {
        nodeLogic: new Contract(this.addresses.nodeLogic, getContractABI("NodeLogic"), connectionTarget),
        userLogic: new Contract(this.addresses.userLogic, getContractABI("UserLogic"), connectionTarget),
        resourceLogic: new Contract(this.addresses.resourceLogic, getContractABI("ResourceLogic"), connectionTarget),
        facade: new Contract(this.addresses.facade, getContractABI("Facade"), connectionTarget),
        nodeStorage: new Contract(this.addresses.nodeStorage, getContractABI("NodeStorage"), connectionTarget),
        userStorage: new Contract(this.addresses.userStorage, getContractABI("UserStorage"), connectionTarget),
        resourceStorage: new Contract(this.addresses.resourceStorage, getContractABI("ResourceStorage"), connectionTarget)
      };

      logger.info('Contract instances created successfully');
      
    } catch (error) {
      logger.error('Failed to initialize contracts:', error);
      throw error;
    }
  }

  /**
   * Get all contract instances
   */
  getContracts(): Contracts {
    if (!this.contracts) {
      throw new Error('Contracts not initialized. Call initialize() first.');
    }
    return this.contracts;
  }

  /**
   * Get contract addresses
   */
  getAddresses(): ContractAddresses {
    if (!this.addresses) {
      throw new Error('Addresses not loaded. Call initialize() first.');
    }
    return this.addresses;
  }

  /**
   * Get the provider instance
   */
  getProvider(): JsonRpcProvider {
    return this.provider;
  }

  /**
   * Get the signer instance (if available)
   */
  getSigner(): Wallet | undefined {
    return this.signer;
  }

  /**
   * Check if the manager has write access (signer available)
   */
  hasWriteAccess(): boolean {
    return !!this.signer;
  }

  /**
   * Test contract connectivity
   */
  async testConnectivity(): Promise<void> {
    if (!this.contracts) {
      throw new Error('Contracts not initialized');
    }

    try {
      // Test basic read operations
      const nodeCount = await this.contracts.nodeStorage.getTotalNodes();
      const userCount = await this.contracts.userStorage.getTotalUsers();
      const stats = await this.contracts.facade.getTotalStats();

      logger.info('Contract connectivity test passed', {
        nodeCount: nodeCount.toString(),
        userCount: userCount.toString(),
        facadeStats: {
          nodes: stats[0].toString(),
          users: stats[1].toString(),
          allocations: stats[2].toString()
        }
      });

    } catch (error) {
      logger.error('Contract connectivity test failed:', error);
      throw error;
    }
  }
}

// Singleton instance
export const contractManager = new ContractManager();
