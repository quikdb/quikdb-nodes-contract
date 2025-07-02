#!/usr/bin/env tsx
import { execSync } from 'child_process';
import { writeFileSync, readFileSync, mkdirSync, existsSync } from 'fs';
import { join } from 'path';

interface ContractAddresses {
  timestamp: string;
  deployer: string;
  storage: Record<string, string>;
  implementations: Record<string, string>;
  proxies: Record<string, string>;
  gasUsed?: string;
  status: 'success' | 'partial' | 'failed';
  errors: string[];
}

class DeploymentManager {
  private deployDir = join(process.cwd(), 'deployments');
  private addressFile = join(this.deployDir, 'addresses.json');

  constructor() {
    if (!existsSync(this.deployDir)) {
      mkdirSync(this.deployDir, { recursive: true });
    }
  }

  async deploy(stage: string = 'complete', broadcast: boolean = false): Promise<void> {
    console.log(`🚀 Deploying QuikDB - Stage: ${stage}`);
    
    const contractName = this.getContractName(stage);
    const command = this.buildForgeCommand(contractName, broadcast);
    
    try {
      console.log(`Running: ${command}`);
      const output = execSync(command, { 
        encoding: 'utf8',
        stdio: 'pipe',
        maxBuffer: 1024 * 1024 * 10 // 10MB buffer
      });
      
      console.log(output);
      
      const addresses = this.parseAddresses(output);
      this.saveAddresses(addresses);
      this.printSummary(addresses);
      
    } catch (error: any) {
      console.error('❌ Deployment failed:', error.message);
      if (error.stdout) {
        console.log('STDOUT:', error.stdout);
        const addresses = this.parseAddresses(error.stdout);
        addresses.status = 'failed';
        addresses.errors.push(error.message);
        this.saveAddresses(addresses);
      }
      throw error;
    }
  }

  private getContractName(stage: string): string {
    const contractMap: Record<string, string> = {
      'storage': 'DeployStorage',
      'logic': 'DeployLogic', 
      'proxies': 'DeployProxies',
      'config': 'SetupConfiguration',
      'complete': 'DeployComplete'
    };
    
    return contractMap[stage] || 'DeployComplete';
  }

  private buildForgeCommand(contractName: string, broadcast: boolean): string {
    let cmd = `forge script script/DeploymentScenarios.sol:${contractName}`;
    
    if (broadcast) {
      cmd += ' --broadcast';
    }
    
    // Add RPC URL if provided
    if (process.env.RPC_URL) {
      cmd += ` --rpc-url ${process.env.RPC_URL}`;
    }
    
    return cmd;
  }

  private parseAddresses(output: string): ContractAddresses {
    const addresses: ContractAddresses = {
      timestamp: new Date().toISOString(),
      deployer: '',
      storage: {},
      implementations: {},
      proxies: {},
      status: 'success',
      errors: []
    };

    const lines = output.split('\n');
    
    for (const line of lines) {
      const addr = this.extractAddress(line);
      if (!addr) continue;

      // Storage contracts
      if (line.includes('NodeStorage deployed at:')) {
        addresses.storage.nodeStorage = addr;
      } else if (line.includes('UserStorage deployed at:')) {
        addresses.storage.userStorage = addr;
      } else if (line.includes('ResourceStorage deployed at:')) {
        addresses.storage.resourceStorage = addr;
      }
      
      // Implementation contracts
      else if (line.includes('QuikNodeLogic Implementation deployed at:')) {
        addresses.implementations.nodeLogic = addr;
      } else if (line.includes('QuikUserLogic Implementation deployed at:')) {
        addresses.implementations.userLogic = addr;
      } else if (line.includes('QuikResourceLogic Implementation deployed at:')) {
        addresses.implementations.resourceLogic = addr;
      } else if (line.includes('QuikFacade Implementation deployed at:')) {
        addresses.implementations.facade = addr;
      }
      
      // Proxy contracts
      else if (line.includes('ProxyAdmin deployed at:')) {
        addresses.proxies.proxyAdmin = addr;
      } else if (line.includes('QuikNodeLogic Proxy deployed at:')) {
        addresses.proxies.nodeLogic = addr;
      } else if (line.includes('QuikUserLogic Proxy deployed at:')) {
        addresses.proxies.userLogic = addr;
      } else if (line.includes('QuikResourceLogic Proxy deployed at:')) {
        addresses.proxies.resourceLogic = addr;
      } else if (line.includes('QuikFacade Proxy deployed at:')) {
        addresses.proxies.facade = addr;
      }
      
      // Deployer address
      else if (line.includes('Deployer address:')) {
        addresses.deployer = addr;
      }
    }

    // Extract gas used
    const gasMatch = output.match(/Gas used: (\d+)/);
    if (gasMatch) {
      addresses.gasUsed = gasMatch[1];
    }

    // Check for errors
    if (output.includes('ERROR:')) {
      addresses.status = 'partial';
      const errorLines = lines.filter(line => line.includes('ERROR:'));
      addresses.errors.push(...errorLines);
    }

    return addresses;
  }

  private extractAddress(line: string): string {
    const match = line.match(/0x[a-fA-F0-9]{40}/);
    return match ? match[0] : '';
  }

  private saveAddresses(addresses: ContractAddresses): void {
    // Load existing deployments
    let allDeployments: ContractAddresses[] = [];
    
    if (existsSync(this.addressFile)) {
      try {
        const data = readFileSync(this.addressFile, 'utf8');
        allDeployments = JSON.parse(data);
      } catch (error) {
        console.warn('⚠️ Could not read existing addresses file');
      }
    }

    // Add new deployment
    allDeployments.push(addresses);
    
    // Keep only last 10 deployments
    if (allDeployments.length > 10) {
      allDeployments = allDeployments.slice(-10);
    }

    // Save all deployments
    writeFileSync(this.addressFile, JSON.stringify(allDeployments, null, 2));
    console.log(`📄 Addresses saved to: ${this.addressFile}`);

    // Save latest separately
    const latestFile = join(this.deployDir, 'latest.json');
    writeFileSync(latestFile, JSON.stringify(addresses, null, 2));
    console.log(`📄 Latest deployment: ${latestFile}`);
  }

  private printSummary(addresses: ContractAddresses): void {
    console.log('\n🎉 Deployment Summary');
    console.log('====================');
    console.log(`Timestamp: ${addresses.timestamp}`);
    console.log(`Deployer: ${addresses.deployer}`);
    console.log(`Status: ${addresses.status}`);
    console.log(`Gas Used: ${addresses.gasUsed || 'N/A'}`);
    
    if (Object.keys(addresses.storage).length > 0) {
      console.log('\n📦 Storage Contracts:');
      for (const [name, addr] of Object.entries(addresses.storage)) {
        console.log(`  ${name}: ${addr}`);
      }
    }
    
    if (Object.keys(addresses.implementations).length > 0) {
      console.log('\n🧠 Implementation Contracts:');
      for (const [name, addr] of Object.entries(addresses.implementations)) {
        console.log(`  ${name}: ${addr}`);
      }
    }
    
    if (Object.keys(addresses.proxies).length > 0) {
      console.log('\n🔗 Proxy Contracts:');
      for (const [name, addr] of Object.entries(addresses.proxies)) {
        console.log(`  ${name}: ${addr}`);
      }
    }
    
    if (addresses.errors.length > 0) {
      console.log('\n⚠️ Errors:');
      for (const error of addresses.errors) {
        console.log(`  ${error}`);
      }
    }
    
    console.log('====================\n');
  }
}

// CLI
async function main() {
  const args = process.argv.slice(2);
  const stage = args.find(arg => arg.startsWith('--stage='))?.split('=')[1] || 'complete';
  const broadcast = args.includes('--broadcast');

  const deployer = new DeploymentManager();
  await deployer.deploy(stage, broadcast);
}

if (require.main === module) {
  main().catch(console.error);
}
