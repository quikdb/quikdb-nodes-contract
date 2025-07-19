#!/usr/bin/env tsx
import { config } from 'dotenv';
import { execSync } from 'child_process';
import { writeFileSync, mkdirSync, existsSync } from 'fs';
import { join } from 'path';

// Load environment variables from .env file
config();

interface ContractAddresses {
  timestamp: string;
  deployer: string;
  storage: Record<string, string>;
  implementations: Record<string, string>;
  proxies: Record<string, string>;
  status: 'success' | 'partial' | 'failed';
  errors: string[];
}

/**
 * QuikDB Deployment Controller
 * 
 * Handles direct, reliable contract deployment with forge scripts
 */
class DeploymentController {
  private deployDir = join(process.cwd(), 'deployments');

  constructor() {
    if (!existsSync(this.deployDir)) {
      mkdirSync(this.deployDir, { recursive: true });
    }
  }

  async deployDirect(broadcast: boolean = false): Promise<void> {
    console.log('🚀 Direct QuikDB Deployment');
    console.log('============================');
    
    const command = broadcast 
      ? `forge script scripts/QuikDBDeployment.sol:QuikDBDeployment --broadcast --rpc-url ${process.env.RPC_URL}`
      : `forge script scripts/QuikDBDeployment.sol:QuikDBDeployment --rpc-url ${process.env.RPC_URL || 'http://localhost:8545'}`;
    
    try {
      console.log(`Running: ${command}`);
      
      const output = execSync(command, { 
        encoding: 'utf8',
        stdio: 'pipe',
        maxBuffer: 1024 * 1024 * 10,
        cwd: process.cwd(),
        env: { ...process.env }
      });
      
      console.log(output);
      
      // Parse deployment output and save addresses
      const addresses = this.parseDirectDeployOutput(output);
      this.saveAddresses(addresses);
      this.printSummary(addresses);
      
    } catch (error: any) {
      console.error('❌ Direct deployment failed:', error.message);
      if (error.stdout) {
        console.error('STDOUT:', error.stdout);
      }
      if (error.stderr) {
        console.error('STDERR:', error.stderr);
      }
      process.exit(1);
    }
  }

  private parseDirectDeployOutput(output: string): ContractAddresses {
    const lines = output.split('\n');
    const addresses: ContractAddresses = {
      timestamp: new Date().toISOString(),
      deployer: '',
      storage: {},
      implementations: {},
      proxies: {},
      status: 'success',
      errors: []
    };

    try {
      // Parse deployer address
      const deployerMatch = output.match(/Deployer address: (0x[a-fA-F0-9]{40})/);
      if (deployerMatch) {
        addresses.deployer = deployerMatch[1];
      }

      // Parse storage contracts
      const nodeStorageMatch = output.match(/NodeStorage deployed at: (0x[a-fA-F0-9]{40})/);
      if (nodeStorageMatch) addresses.storage.nodeStorage = nodeStorageMatch[1];

      const userStorageMatch = output.match(/UserStorage deployed at: (0x[a-fA-F0-9]{40})/);
      if (userStorageMatch) addresses.storage.userStorage = userStorageMatch[1];

      const resourceStorageMatch = output.match(/ResourceStorage deployed at: (0x[a-fA-F0-9]{40})/);
      if (resourceStorageMatch) addresses.storage.resourceStorage = resourceStorageMatch[1];

      // Parse implementation contracts
      const nodeLogicImplMatch = output.match(/NodeLogic Implementation deployed at: (0x[a-fA-F0-9]{40})/);
      if (nodeLogicImplMatch) addresses.implementations.nodeLogic = nodeLogicImplMatch[1];

      const userLogicImplMatch = output.match(/UserLogic Implementation deployed at: (0x[a-fA-F0-9]{40})/);
      if (userLogicImplMatch) addresses.implementations.userLogic = userLogicImplMatch[1];

      const resourceLogicImplMatch = output.match(/ResourceLogic Implementation deployed at: (0x[a-fA-F0-9]{40})/);
      if (resourceLogicImplMatch) addresses.implementations.resourceLogic = resourceLogicImplMatch[1];

      const facadeImplMatch = output.match(/Facade Implementation deployed at: (0x[a-fA-F0-9]{40})/);
      if (facadeImplMatch) addresses.implementations.facade = facadeImplMatch[1];

      // Parse proxy contracts
      const proxyAdminMatch = output.match(/ProxyAdmin deployed at: (0x[a-fA-F0-9]{40})/);
      if (proxyAdminMatch) addresses.proxies.proxyAdmin = proxyAdminMatch[1];

      const nodeLogicProxyMatch = output.match(/NodeLogic Proxy deployed at: (0x[a-fA-F0-9]{40})/);
      if (nodeLogicProxyMatch) addresses.proxies.nodeLogic = nodeLogicProxyMatch[1];

      const userLogicProxyMatch = output.match(/UserLogic Proxy deployed at: (0x[a-fA-F0-9]{40})/);
      if (userLogicProxyMatch) addresses.proxies.userLogic = userLogicProxyMatch[1];

      const resourceLogicProxyMatch = output.match(/ResourceLogic Proxy deployed at: (0x[a-fA-F0-9]{40})/);
      if (resourceLogicProxyMatch) addresses.proxies.resourceLogic = resourceLogicProxyMatch[1];

      const facadeProxyMatch = output.match(/Facade Proxy deployed at: (0x[a-fA-F0-9]{40})/);
      if (facadeProxyMatch) addresses.proxies.facade = facadeProxyMatch[1];

    } catch (error) {
      console.warn('⚠️  Warning: Could not parse all addresses from output');
      addresses.errors.push(`Parse error: ${(error as Error).message}`);
      addresses.status = 'partial';
    }

    return addresses;
  }

  private saveAddresses(addresses: ContractAddresses): void {
    try {
      // Save to addresses.json (append to array)
      const addressFile = join(this.deployDir, 'addresses.json');
      let addressHistory: ContractAddresses[] = [];
      
      try {
        const existingData = require(addressFile);
        addressHistory = Array.isArray(existingData) ? existingData : [existingData];
      } catch (error) {
        // File doesn't exist or is invalid, start fresh
      }
      
      addressHistory.push(addresses);
      writeFileSync(addressFile, JSON.stringify(addressHistory, null, 2));

      // Save to latest.json (single deployment)
      const latestFile = join(this.deployDir, 'latest.json');
      writeFileSync(latestFile, JSON.stringify(addresses, null, 2));

      console.log('📄 Addresses saved to:', addressFile);
      console.log('📄 Latest deployment:', latestFile);
      
    } catch (error) {
      console.error('❌ Failed to save addresses:', (error as Error).message);
    }
  }

  private printSummary(addresses: ContractAddresses): void {
    console.log('\n🎉 Deployment Summary');
    console.log('====================');
    console.log(`Timestamp: ${addresses.timestamp}`);
    console.log(`Deployer: ${addresses.deployer}`);
    console.log(`Status: ${addresses.status}`);
    console.log(`Gas Used: N/A`);

    console.log('\n📦 Storage Contracts:');
    Object.entries(addresses.storage).forEach(([name, address]) => {
      console.log(`  ${name}: ${address}`);
    });

    console.log('\n🧠 Implementation Contracts:');
    Object.entries(addresses.implementations).forEach(([name, address]) => {
      console.log(`  ${name}: ${address}`);
    });

    console.log('\n🔗 Proxy Contracts:');
    Object.entries(addresses.proxies).forEach(([name, address]) => {
      console.log(`  ${name}: ${address}`);
    });

    if (addresses.errors.length > 0) {
      console.log('\n⚠️  Errors:');
      addresses.errors.forEach(error => console.log(`  - ${error}`));
    }

    console.log('====================');
  }
}

// Main execution
async function main() {
  const args = process.argv.slice(2);
  const broadcast = args.includes('--broadcast');
  
  if (!process.env.PRIVATE_KEY) {
    console.error('❌ PRIVATE_KEY environment variable is required');
    process.exit(1);
  }

  if (broadcast && !process.env.RPC_URL) {
    console.error('❌ RPC_URL environment variable is required for broadcasting');
    process.exit(1);
  }

  const manager = new DeploymentController();
  await manager.deployDirect(broadcast);
}

// Handle script execution
if (require.main === module) {
  main().catch(error => {
    console.error('❌ Deployment script failed:', error);
    process.exit(1);
  });
}

export { DeploymentController };
