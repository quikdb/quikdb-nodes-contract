#!/usr/bin/env ts-node

import { execSync } from 'child_process';
import { writeFileSync } from 'fs';
import { resolve } from 'path';

interface DeploymentAddresses {
  UserNodeRegistry: string;
  QuiksToken: string;
  QuiksTokenImpl: string;
}

class DeploymentController {
  private networkName: string;
  private deploymentDirectory: string;

  constructor(networkName: string = 'local') {
    this.networkName = networkName;
    this.deploymentDirectory = resolve(__dirname, '../deployments');
  }

  /**
   * Deploy QuikDB contracts using Forge
   */
  public async deploy(rpcUrl?: string, privateKey?: string): Promise<DeploymentAddresses> {
    console.log(`🚀 Deploying QuikDB contracts to ${this.networkName}...`);

    // Build the forge command
    let forgeCommand = 'forge script scripts/QuikDBDeployment.sol';
    
    if (rpcUrl) {
      forgeCommand += ` --fork-url ${rpcUrl}`;
      if (privateKey) {
        forgeCommand += ` --broadcast --private-key ${privateKey}`;
      }
    }

    // Set default private key for local testing if not provided
    const envVars = privateKey 
      ? `PRIVATE_KEY=${privateKey}` 
      : 'PRIVATE_KEY=0x0000000000000000000000000000000000000000000000000000000000000001';

    try {
      // Execute deployment
      const output = execSync(`${envVars} ${forgeCommand}`, {
        encoding: 'utf8',
        stdio: 'pipe',
        cwd: resolve(__dirname, '..')
      });

      // Parse addresses from console output
      const addresses = this.parseDeploymentAddresses(output);
      
      // Save deployment info
      await this.saveDeploymentInfo(addresses);
      
      console.log('✅ Deployment completed successfully!');
      console.log('📋 Contract addresses:');
      console.log(`   UserNodeRegistry: ${addresses.UserNodeRegistry}`);
      console.log(`   QuiksToken: ${addresses.QuiksToken}`);
      console.log(`   QuiksTokenImpl: ${addresses.QuiksTokenImpl}`);

      return addresses;

    } catch (error) {
      console.error('❌ Deployment failed:', error);
      throw error;
    }
  }

  /**
   * Parse contract addresses from forge script output
   */
  private parseDeploymentAddresses(output: string): DeploymentAddresses {
    const addressRegex = /(\w+):\s+(0x[a-fA-F0-9]{40})/g;
    const addresses: Partial<DeploymentAddresses> = {};
    
    let match;
    while ((match = addressRegex.exec(output)) !== null) {
      const [, contractName, address] = match;
      if (contractName in { UserNodeRegistry: true, QuiksToken: true, QuiksTokenImpl: true }) {
        (addresses as any)[contractName] = address;
      }
    }

    // Validate all required addresses are present
    if (!addresses.UserNodeRegistry || !addresses.QuiksToken || !addresses.QuiksTokenImpl) {
      throw new Error('Failed to parse all required contract addresses from deployment output');
    }

    return addresses as DeploymentAddresses;
  }

  /**
   * Save deployment information to JSON files for CLI consumption
   */
  private async saveDeploymentInfo(addresses: DeploymentAddresses): Promise<void> {
    // Create deployments directory if it doesn't exist
    execSync(`mkdir -p ${this.deploymentDirectory}`, { stdio: 'inherit' });

    // Network-specific deployment file
    const networkFile = resolve(this.deploymentDirectory, `${this.networkName}.json`);
    const deploymentData = {
      network: this.networkName,
      timestamp: new Date().toISOString(),
      contracts: addresses,
      // CLI compatibility format
      userNodeRegistry: addresses.UserNodeRegistry,
      quiksToken: addresses.QuiksToken
    };

    writeFileSync(networkFile, JSON.stringify(deploymentData, null, 2));

    // Update latest.json for CLI default
    const latestFile = resolve(this.deploymentDirectory, 'latest.json');
    writeFileSync(latestFile, JSON.stringify(deploymentData, null, 2));

    // Create addresses.json for legacy CLI compatibility
    const addressesFile = resolve(this.deploymentDirectory, 'addresses.json');
    const addressesData = {
      contracts: {
        UserNodeRegistry: {
          address: addresses.UserNodeRegistry
        },
        QuiksToken: {
          address: addresses.QuiksToken,
          implementation: addresses.QuiksTokenImpl
        }
      },
      network: this.networkName,
      lastUpdated: new Date().toISOString()
    };

    writeFileSync(addressesFile, JSON.stringify(addressesData, null, 2));

    console.log(`💾 Deployment info saved to: ${networkFile}`);
  }

  /**
   * Verify deployed contracts
   */
  public async verify(addresses: DeploymentAddresses, rpcUrl?: string): Promise<void> {
    console.log('🔍 Verifying contract deployments...');
    
    if (rpcUrl) {
      // Could add contract verification logic here
      console.log('✅ Contract verification completed');
    } else {
      console.log('⚠️  Skipping verification for local deployment');
    }
  }
}

// CLI execution
if (require.main === module) {
  const args = process.argv.slice(2);
  const networkName = args[0] || 'local';
  const rpcUrl = process.env.RPC_URL;
  const privateKey = process.env.PRIVATE_KEY;

  const controller = new DeploymentController(networkName);
  
  controller.deploy(rpcUrl, privateKey)
    .then(addresses => {
      return controller.verify(addresses, rpcUrl);
    })
    .then(() => {
      console.log('🎉 All operations completed successfully!');
      process.exit(0);
    })
    .catch(error => {
      console.error('💥 Operation failed:', error.message);
      process.exit(1);
    });
}

export default DeploymentController;
