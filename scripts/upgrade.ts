#!/usr/bin/env tsx
import { config } from 'dotenv';
import { execSync } from 'child_process';
import { writeFileSync, readFileSync, existsSync } from 'fs';
import { join } from 'path';

// Load environment variables from .env file
config();

interface UpgradeAddresses {
  timestamp: string;
  deployer: string;
  previousImplementations: Record<string, string>;
  newImplementations: Record<string, string>;
  proxyAddresses: Record<string, string>;
  status: 'success' | 'partial' | 'failed';
  errors: string[];
}

/**
 * QuikDB Upgrade Controller
 * 
 * Handles proxy upgrades for QuikDB contracts while preserving user-facing addresses
 */
class UpgradeController {
  private deployDir = join(process.cwd(), 'deployments');

  constructor() {
    if (!existsSync(this.deployDir)) {
      throw new Error('Deployments directory not found. Please deploy contracts first.');
    }
  }

  async upgradeProxies(broadcast: boolean = false): Promise<void> {
    console.log('🔄 QuikDB Proxy Upgrade');
    console.log('========================');
    
    // Check if we have existing deployment
    const latestFile = join(this.deployDir, 'latest.json');
    if (!existsSync(latestFile)) {
      throw new Error('No existing deployment found. Please deploy contracts first.');
    }

    // Load existing deployment addresses
    const latestData = JSON.parse(readFileSync(latestFile, 'utf8'));
    console.log('📋 Loaded existing deployment addresses');

    // Set environment variables for the Solidity script
    const upgradeEnv = {
      ...process.env,
      NODE_STORAGE: latestData.storage.nodeStorage,
      USER_STORAGE: latestData.storage.userStorage,
      RESOURCE_STORAGE: latestData.storage.resourceStorage,
      PROXY_ADMIN: latestData.proxies.proxyAdmin,
      NODE_LOGIC_PROXY: latestData.proxies.nodeLogic,
      USER_LOGIC_PROXY: latestData.proxies.userLogic,
      RESOURCE_LOGIC_PROXY: latestData.proxies.resourceLogic,
      FACADE_PROXY: latestData.proxies.facade
    };

    const command = broadcast 
      ? `forge script scripts/QuikDBUpgrade.sol:QuikDBUpgrade --broadcast --rpc-url ${process.env.RPC_URL}`
      : `forge script scripts/QuikDBUpgrade.sol:QuikDBUpgrade --rpc-url ${process.env.RPC_URL || 'http://localhost:8545'}`;
    
    try {
      console.log(`Running: ${command}`);
      
      const output = execSync(command, { 
        encoding: 'utf8',
        stdio: 'pipe',
        maxBuffer: 1024 * 1024 * 10,
        cwd: process.cwd(),
        env: upgradeEnv
      });
      
      console.log(output);
      
      // Parse upgrade output and save addresses
      const addresses = this.parseUpgradeOutput(output);
      this.saveUpgradeInfo(addresses);
      this.printSummary(addresses);
      
    } catch (error: any) {
      console.error('❌ Proxy upgrade failed:', error.message);
      if (error.stdout) {
        console.error('STDOUT:', error.stdout);
      }
      if (error.stderr) {
        console.error('STDERR:', error.stderr);
      }
      
      // Create a partial record with whatever information was available before the error
      if (error.stdout) {
        try {
          const partialAddresses = this.parseUpgradeOutput(error.stdout);
          partialAddresses.status = 'failed';
          partialAddresses.errors.push(error.message || 'Unknown error occurred during upgrade');
          this.saveUpgradeInfo(partialAddresses);
          this.printSummary(partialAddresses);
          console.log('\n❌ Upgrade failed but partial information was saved');
        } catch (parseError) {
          console.error('Failed to parse partial output:', parseError);
        }
      }
      
      process.exit(1);
    }
  }

  private parseUpgradeOutput(output: string): UpgradeAddresses {
    const addresses: UpgradeAddresses = {
      timestamp: new Date().toISOString(),
      deployer: '',
      previousImplementations: {},
      newImplementations: {},
      proxyAddresses: {},
      status: 'success',
      errors: []
    };

    try {
      // Parse deployer address
      const deployerMatch = output.match(/Deployer address: (0x[a-fA-F0-9]{40})/);
      if (deployerMatch) {
        addresses.deployer = deployerMatch[1];
      }

      // Parse new implementation contracts
      const nodeLogicImplMatch = output.match(/New NodeLogic Implementation deployed at: (0x[a-fA-F0-9]{40})/);
      if (nodeLogicImplMatch) addresses.newImplementations.nodeLogic = nodeLogicImplMatch[1];

      const userLogicImplMatch = output.match(/New UserLogic Implementation deployed at: (0x[a-fA-F0-9]{40})/);
      if (userLogicImplMatch) addresses.newImplementations.userLogic = userLogicImplMatch[1];

      const resourceLogicImplMatch = output.match(/New ResourceLogic Implementation deployed at: (0x[a-fA-F0-9]{40})/);
      if (resourceLogicImplMatch) addresses.newImplementations.resourceLogic = resourceLogicImplMatch[1];

      const facadeImplMatch = output.match(/New Facade Implementation deployed at: (0x[a-fA-F0-9]{40})/);
      if (facadeImplMatch) addresses.newImplementations.facade = facadeImplMatch[1];

      // Parse proxy addresses (these should remain the same)
      const nodeLogicProxyMatch = output.match(/NodeLogic Proxy: (0x[a-fA-F0-9]{40})/);
      if (nodeLogicProxyMatch) addresses.proxyAddresses.nodeLogic = nodeLogicProxyMatch[1];

      const userLogicProxyMatch = output.match(/UserLogic Proxy: (0x[a-fA-F0-9]{40})/);
      if (userLogicProxyMatch) addresses.proxyAddresses.userLogic = userLogicProxyMatch[1];

      const resourceLogicProxyMatch = output.match(/ResourceLogic Proxy: (0x[a-fA-F0-9]{40})/);
      if (resourceLogicProxyMatch) addresses.proxyAddresses.resourceLogic = resourceLogicProxyMatch[1];

      const facadeProxyMatch = output.match(/Facade Proxy: (0x[a-fA-F0-9]{40})/);
      if (facadeProxyMatch) addresses.proxyAddresses.facade = facadeProxyMatch[1];

      // Load previous implementation addresses from latest.json
      this.loadPreviousImplementations(addresses);

    } catch (error) {
      console.warn('⚠️  Warning: Could not parse all addresses from output');
      addresses.errors.push(`Parse error: ${(error as Error).message}`);
      addresses.status = 'partial';
    }

    return addresses;
  }

  private loadPreviousImplementations(addresses: UpgradeAddresses): void {
    try {
      const latestFile = join(this.deployDir, 'latest.json');
      const latestData = JSON.parse(readFileSync(latestFile, 'utf8'));
      
      if (latestData.implementations) {
        addresses.previousImplementations = latestData.implementations;
      }
    } catch (error) {
      console.warn('⚠️  Could not load previous implementation addresses');
    }
  }

  private saveUpgradeInfo(addresses: UpgradeAddresses): void {
    try {
      // Save to upgrades.json (append to array)
      const upgradeFile = join(this.deployDir, 'upgrades.json');
      let upgradeHistory: UpgradeAddresses[] = [];
      
      try {
        if (existsSync(upgradeFile)) {
          const existingData = JSON.parse(readFileSync(upgradeFile, 'utf8'));
          upgradeHistory = Array.isArray(existingData) ? existingData : [existingData];
        }
      } catch (error) {
        // File doesn't exist or is invalid, start fresh
      }
      
      upgradeHistory.push(addresses);
      writeFileSync(upgradeFile, JSON.stringify(upgradeHistory, null, 2));

      // Update latest.json with new implementation addresses
      this.updateLatestDeployment(addresses);

      console.log('📄 Upgrade info saved to:', upgradeFile);
      console.log('📄 Latest deployment updated with new implementations');
      
    } catch (error) {
      console.error('❌ Failed to save upgrade info:', (error as Error).message);
    }
  }

  private updateLatestDeployment(addresses: UpgradeAddresses): void {
    try {
      const latestFile = join(this.deployDir, 'latest.json');
      const latestData = JSON.parse(readFileSync(latestFile, 'utf8'));
      
      // Update implementation addresses while keeping everything else the same
      latestData.implementations = addresses.newImplementations;
      latestData.timestamp = addresses.timestamp;
      
      writeFileSync(latestFile, JSON.stringify(latestData, null, 2));
    } catch (error) {
      console.warn('⚠️  Could not update latest deployment file');
    }
  }

  private printSummary(addresses: UpgradeAddresses): void {
    console.log('\n🎉 Upgrade Summary');
    console.log('==================');
    console.log(`Timestamp: ${addresses.timestamp}`);
    console.log(`Deployer: ${addresses.deployer}`);
    console.log(`Status: ${addresses.status}`);

    console.log('\n📍 Proxy Addresses (UNCHANGED):');
    Object.entries(addresses.proxyAddresses).forEach(([name, address]) => {
      console.log(`  ${name}: ${address}`);
    });

    console.log('\n🔄 Implementation Changes:');
    Object.entries(addresses.newImplementations).forEach(([name, newAddress]) => {
      const oldAddress = addresses.previousImplementations[name] || 'N/A';
      console.log(`  ${name}:`);
      console.log(`    Previous: ${oldAddress}`);
      console.log(`    New:      ${newAddress}`);
    });

    if (addresses.errors.length > 0) {
      console.log('\n⚠️  Errors:');
      addresses.errors.forEach(error => console.log(`  - ${error}`));
    }

    console.log('\n✅ Users can continue using the same proxy addresses!');
    console.log('==================');
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

  const controller = new UpgradeController();
  await controller.upgradeProxies(broadcast);
}

// Handle script execution
if (require.main === module) {
  main().catch(error => {
    console.error('❌ Upgrade script failed:', error);
    process.exit(1);
  });
}

export { UpgradeController };
