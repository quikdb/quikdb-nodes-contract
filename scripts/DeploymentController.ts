#!/usr/bin/env tsx

/**
 * @title DeploymentController
 * @notice TypeScript controller for QuikDB simplified contract deployment
 * @dev Manages running the forge script and saving resulting addresses
 */

import { exec } from 'child_process';
import { promisify } from 'util';
import { writeFileSync, existsSync, mkdirSync } from 'fs';
import { join } from 'path';

const execAsync = promisify(exec);

interface DeploymentConfig {
  network: string;
  rpcUrl?: string;
  privateKey: string;
  verify?: boolean;
}

interface DeployedAddresses {
  UserNodeRegistry: string;
  UserNodeRegistryImpl: string;
  QuiksToken: string;
  QuiksTokenImpl: string;
  deployedAt: string;
  deployer: string;
  network: string;
}

class DeploymentController {
  private config: DeploymentConfig;

  constructor(config: DeploymentConfig) {
    this.config = config;
  }

  /**
   * Execute the deployment
   */
  async deploy(): Promise<DeployedAddresses> {
    console.log(`🚀 Starting QuikDB deployment on ${this.config.network}`);
    
    try {
      // Build the forge script command
      let command = `forge script scripts/QuikDBDeployment.sol --private-key ${this.config.privateKey} --broadcast`;
      
      if (this.config.rpcUrl) {
        command += ` --rpc-url ${this.config.rpcUrl}`;
      }

      console.log('📦 Executing deployment...');
      const { stdout, stderr } = await execAsync(command);
      
      if (stderr && !stderr.includes('Compiler run successful')) {
        console.error('Deployment error:', stderr);
        throw new Error(stderr);
      }

      // Parse the deployment output
      const addresses = this.parseDeploymentOutput(stdout);
      
      // Save deployment info
      await this.saveDeploymentInfo(addresses);
      
      console.log('✅ Deployment completed successfully!');
      console.log('📋 Deployed contracts:');
      console.log(`   UserNodeRegistry: ${addresses.UserNodeRegistry}`);
      console.log(`   UserNodeRegistryImpl: ${addresses.UserNodeRegistryImpl}`);
      console.log(`   QuiksToken: ${addresses.QuiksToken}`);
      console.log(`   QuiksTokenImpl: ${addresses.QuiksTokenImpl}`);
      
      return addresses;
      
    } catch (error) {
      console.error('❌ Deployment failed:', error);
      throw error;
    }
  }

  /**
   * Parse deployment output to extract contract addresses
   */
  private parseDeploymentOutput(output: string): DeployedAddresses {
    const lines = output.split('\n');
    const addresses: Partial<DeployedAddresses> = {};

    for (const line of lines) {
      if (line.includes('UserNodeRegistry:') && !line.includes('UserNodeRegistryImpl:')) {
        addresses.UserNodeRegistry = line.split(':')[1].trim();
      } else if (line.includes('UserNodeRegistryImpl:')) {
        addresses.UserNodeRegistryImpl = line.split(':')[1].trim();
      } else if (line.includes('QuiksToken:') && !line.includes('QuiksTokenImpl:')) {
        addresses.QuiksToken = line.split(':')[1].trim();
      } else if (line.includes('QuiksTokenImpl:')) {
        addresses.QuiksTokenImpl = line.split(':')[1].trim();
      }
    }

    if (!addresses.UserNodeRegistry || !addresses.UserNodeRegistryImpl || !addresses.QuiksToken || !addresses.QuiksTokenImpl) {
      throw new Error('Failed to parse deployment addresses from output');
    }

    return {
      ...addresses as Required<Pick<DeployedAddresses, 'UserNodeRegistry' | 'UserNodeRegistryImpl' | 'QuiksToken' | 'QuiksTokenImpl'>>,
      deployedAt: new Date().toISOString(),
      deployer: 'auto-deployed',
      network: this.config.network
    };
  }

  /**
   * Save deployment information to files
   */
  private async saveDeploymentInfo(addresses: DeployedAddresses): Promise<void> {
    const deploymentsDir = join(process.cwd(), 'deployments');
    
    // Ensure deployments directory exists
    if (!existsSync(deploymentsDir)) {
      mkdirSync(deploymentsDir, { recursive: true });
    }

    console.log('💾 Saving deployment addresses to files...');

    // Save network-specific deployment
    const networkFile = join(deploymentsDir, `${this.config.network}.json`);
    writeFileSync(networkFile, JSON.stringify(addresses, null, 2));
    console.log(`   ✅ ${this.config.network}.json`);

    // Save latest deployment (for CLI compatibility)
    const latestFile = join(deploymentsDir, 'latest.json');
    writeFileSync(latestFile, JSON.stringify(addresses, null, 2));
    console.log(`   ✅ latest.json`);

    // Save addresses only (for simple access)
    const addressesFile = join(deploymentsDir, 'addresses.json');
    const simpleAddresses = {
      UserNodeRegistry: addresses.UserNodeRegistry,
      UserNodeRegistryImpl: addresses.UserNodeRegistryImpl,
      QuiksToken: addresses.QuiksToken,
      QuiksTokenImpl: addresses.QuiksTokenImpl
    };
    writeFileSync(addressesFile, JSON.stringify(simpleAddresses, null, 2));
    console.log(`   ✅ addresses.json`);

    console.log(`📁 All deployment files saved to deployments/ directory`);
  }
}

/**
 * Main execution
 */
async function main() {
  const network = process.argv[2] || 'local';
  const privateKey = process.env.PRIVATE_KEY || '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80';

  // Network configurations
  const networkConfigs: Record<string, Partial<DeploymentConfig>> = {
    local: {
      network: 'local',
      rpcUrl: 'http://127.0.0.1:8545'
    },
    'lisk-sepolia': {
      network: 'lisk-sepolia',
      rpcUrl: process.env.RPC_URL || 'https://rpc.sepolia-api.lisk.com',
      verify: true
    },
    'lisk-mainnet': {
      network: 'lisk-mainnet',
      rpcUrl: process.env.RPC_URL || 'https://rpc.api.lisk.com',
      verify: true
    }
  };

  const networkConfig = networkConfigs[network];
  if (!networkConfig) {
    console.error(`❌ Unknown network: ${network}`);
    console.log('Available networks:', Object.keys(networkConfigs).join(', '));
    process.exit(1);
  }

  const config: DeploymentConfig = {
    ...networkConfig,
    privateKey
  } as DeploymentConfig;

  const controller = new DeploymentController(config);
  
  try {
    await controller.deploy();
    console.log('🎉 All done!');
  } catch (error) {
    console.error('💥 Fatal error:', error);
    process.exit(1);
  }
}

// Run if called directly
if (require.main === module) {
  main().catch(console.error);
}
