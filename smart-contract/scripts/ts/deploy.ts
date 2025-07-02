import { spawn } from 'child_process';
import { promises as fs } from 'fs';
import path from 'path';
import { config } from 'dotenv';

// Load environment variables
config();

interface DeploymentAddresses {
  network: string;
  timestamp: string;
  deployer: string;
  storage: {
    nodeStorage?: string;
    userStorage?: string;
    resourceStorage?: string;
  };
  implementations: {
    nodeLogic?: string;
    userLogic?: string;
    resourceLogic?: string;
    facade?: string;
  };
  proxies: {
    proxyAdmin?: string;
    nodeLogic?: string;
    userLogic?: string;
    resourceLogic?: string;
    facade?: string;
  };
  gasUsed?: string;
  deploymentStatus: 'success' | 'partial' | 'failed';
  errors?: string[];
}

interface DeploymentConfig {
  stage: 'storage' | 'logic' | 'proxies' | 'config' | 'complete';
  rpcUrl?: string;
  broadcast: boolean;
  verify: boolean;
}

class QuikDBDeployer {
  private config: DeploymentConfig;
  private addressesFile: string;
  private logsDir: string;

  constructor(config: DeploymentConfig) {
    this.config = config;
    this.addressesFile = path.join(process.cwd(), 'deployments', 'addresses.json');
    this.logsDir = path.join(process.cwd(), 'deployments', 'logs');
  }

  async deploy(): Promise<void> {
    console.log(`🚀 Starting QuikDB deployment - Stage: ${this.config.stage}`);
    
    // Ensure directories exist
    await this.ensureDirectories();
    
    try {
      switch (this.config.stage) {
        case 'storage':
          await this.deployStorage();
          break;
        case 'logic':
          await this.deployLogic();
          break;
        case 'proxies':
          await this.deployProxies();
          break;
        case 'config':
          await this.setupConfiguration();
          break;
        case 'complete':
          await this.deployComplete();
          break;
        default:
          throw new Error(`Unknown deployment stage: ${this.config.stage}`);
      }
    } catch (error) {
      console.error('❌ Deployment failed:', error);
      await this.logError(error as Error);
      process.exit(1);
    }
  }

  private async deployStorage(): Promise<void> {
    console.log('📦 Deploying storage contracts...');
    await this.runForgeScript('DeploymentScenarios.sol:DeployStorage');
  }

  private async deployLogic(): Promise<void> {
    console.log('🧠 Deploying logic implementations...');
    await this.runForgeScript('DeploymentScenarios.sol:DeployLogic');
  }

  private async deployProxies(): Promise<void> {
    console.log('🔗 Deploying proxy contracts...');
    await this.runForgeScript('DeploymentScenarios.sol:DeployProxies');
  }

  private async setupConfiguration(): Promise<void> {
    console.log('⚙️ Setting up configuration...');
    await this.runForgeScript('DeploymentScenarios.sol:SetupConfiguration');
  }

  private async deployComplete(): Promise<void> {
    console.log('🚀 Deploying complete QuikDB system...');
    await this.runForgeScript('DeploymentScenarios.sol:DeployComplete');
  }

  private async runForgeScript(contractPath: string): Promise<void> {
    const args = [
      'script',
      `script/${contractPath}`,
      '--json'
    ];

    if (this.config.rpcUrl) {
      args.push('--rpc-url', this.config.rpcUrl);
    }

    if (this.config.broadcast) {
      args.push('--broadcast');
    }

    if (this.config.verify) {
      args.push('--verify');
    }

    return new Promise((resolve, reject) => {
      const forge = spawn('forge', args, {
        stdio: ['inherit', 'pipe', 'pipe'],
        env: { ...process.env }
      });

      let stdout = '';
      let stderr = '';

      forge.stdout.on('data', (data: Buffer) => {
        const output = data.toString();
        stdout += output;
        console.log(output);
      });

      forge.stderr.on('data', (data: Buffer) => {
        const output = data.toString();
        stderr += output;
        console.error(output);
      });

      forge.on('close', async (code: number | null) => {
        if (code === 0) {
          console.log('✅ Forge script completed successfully');
          await this.parseAndSaveAddresses(stdout, stderr);
          resolve();
        } else {
          console.error(`❌ Forge script failed with code ${code}`);
          await this.logError(new Error(`Forge script failed: ${stderr}`));
          reject(new Error(`Forge script failed with code ${code}`));
        }
      });

      forge.on('error', (error: Error) => {
        console.error('❌ Failed to start forge process:', error);
        reject(error);
      });
    });
  }

  private async parseAndSaveAddresses(stdout: string, stderr: string): Promise<void> {
    const addresses: Partial<DeploymentAddresses> = {
      network: this.config.rpcUrl ? 'custom' : 'local',
      timestamp: new Date().toISOString(),
      deployer: '', // Will be extracted from logs
      storage: {},
      implementations: {},
      proxies: {},
      deploymentStatus: 'success',
      errors: []
    };

    // Parse addresses from the output
    const lines = stdout.split('\n');
    
    for (const line of lines) {
      // Storage contracts
      if (line.includes('NodeStorage deployed at:')) {
        addresses.storage!.nodeStorage = this.extractAddress(line);
      } else if (line.includes('UserStorage deployed at:')) {
        addresses.storage!.userStorage = this.extractAddress(line);
      } else if (line.includes('ResourceStorage deployed at:')) {
        addresses.storage!.resourceStorage = this.extractAddress(line);
      }
      
      // Implementation contracts
      else if (line.includes('QuikNodeLogic Implementation deployed at:')) {
        addresses.implementations!.nodeLogic = this.extractAddress(line);
      } else if (line.includes('QuikUserLogic Implementation deployed at:')) {
        addresses.implementations!.userLogic = this.extractAddress(line);
      } else if (line.includes('QuikResourceLogic Implementation deployed at:')) {
        addresses.implementations!.resourceLogic = this.extractAddress(line);
      } else if (line.includes('QuikFacade Implementation deployed at:')) {
        addresses.implementations!.facade = this.extractAddress(line);
      }
      
      // Proxy contracts
      else if (line.includes('ProxyAdmin deployed at:')) {
        addresses.proxies!.proxyAdmin = this.extractAddress(line);
      } else if (line.includes('QuikNodeLogic Proxy deployed at:')) {
        addresses.proxies!.nodeLogic = this.extractAddress(line);
      } else if (line.includes('QuikUserLogic Proxy deployed at:')) {
        addresses.proxies!.userLogic = this.extractAddress(line);
      } else if (line.includes('QuikResourceLogic Proxy deployed at:')) {
        addresses.proxies!.resourceLogic = this.extractAddress(line);
      } else if (line.includes('QuikFacade Proxy deployed at:')) {
        addresses.proxies!.facade = this.extractAddress(line);
      }
      
      // Deployer address
      else if (line.includes('Deployer address:')) {
        addresses.deployer = this.extractAddress(line);
      }
      
      // Gas used
      else if (line.includes('Gas used:')) {
        addresses.gasUsed = line.split('Gas used:')[1]?.trim();
      }
      
      // Check for errors
      else if (line.includes('ERROR:')) {
        if (!addresses.errors) addresses.errors = [];
        addresses.errors.push(line.trim());
        addresses.deploymentStatus = 'partial';
      }
    }

    // Check if any errors in stderr
    if (stderr.trim()) {
      if (!addresses.errors) addresses.errors = [];
      addresses.errors.push(stderr.trim());
      addresses.deploymentStatus = 'failed';
    }

    await this.saveAddresses(addresses as DeploymentAddresses);
    await this.saveDeploymentLog(stdout, stderr);
  }

  private extractAddress(line: string): string {
    // Extract Ethereum address (0x followed by 40 hex characters)
    const match = line.match(/0x[a-fA-F0-9]{40}/);
    return match ? match[0] : '';
  }

  private async saveAddresses(addresses: DeploymentAddresses): Promise<void> {
    try {
      // Load existing addresses if they exist
      let existingAddresses: DeploymentAddresses[] = [];
      try {
        const data = await fs.readFile(this.addressesFile, 'utf-8');
        existingAddresses = JSON.parse(data);
      } catch {
        // File doesn't exist, start fresh
      }

      // Add new deployment
      existingAddresses.push(addresses);

      // Keep only last 10 deployments
      if (existingAddresses.length > 10) {
        existingAddresses = existingAddresses.slice(-10);
      }

      await fs.writeFile(this.addressesFile, JSON.stringify(existingAddresses, null, 2));
      console.log(`📄 Addresses saved to: ${this.addressesFile}`);

      // Also save latest deployment as separate file for easy access
      const latestFile = path.join(path.dirname(this.addressesFile), 'latest.json');
      await fs.writeFile(latestFile, JSON.stringify(addresses, null, 2));
      console.log(`📄 Latest deployment saved to: ${latestFile}`);

      // Print summary
      this.printDeploymentSummary(addresses);
    } catch (error) {
      console.error('❌ Failed to save addresses:', error);
    }
  }

  private async saveDeploymentLog(stdout: string, stderr: string): Promise<void> {
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const logFile = path.join(this.logsDir, `deployment-${timestamp}.log`);
    
    const logContent = [
      `=== QuikDB Deployment Log - ${new Date().toISOString()} ===`,
      `Stage: ${this.config.stage}`,
      `RPC URL: ${this.config.rpcUrl || 'local'}`,
      `Broadcast: ${this.config.broadcast}`,
      `Verify: ${this.config.verify}`,
      '',
      '=== STDOUT ===',
      stdout,
      '',
      '=== STDERR ===',
      stderr,
      ''
    ].join('\n');

    await fs.writeFile(logFile, logContent);
    console.log(`📄 Deployment log saved to: ${logFile}`);
  }

  private async logError(error: Error): Promise<void> {
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const errorFile = path.join(this.logsDir, `error-${timestamp}.log`);
    
    const errorContent = [
      `=== QuikDB Deployment Error - ${new Date().toISOString()} ===`,
      `Stage: ${this.config.stage}`,
      `Error: ${error.message}`,
      `Stack: ${error.stack}`,
      ''
    ].join('\n');

    await fs.writeFile(errorFile, errorContent);
    console.log(`📄 Error log saved to: ${errorFile}`);
  }

  private printDeploymentSummary(addresses: DeploymentAddresses): void {
    console.log('\n🎉 Deployment Summary:');
    console.log('========================');
    console.log(`Network: ${addresses.network}`);
    console.log(`Deployer: ${addresses.deployer}`);
    console.log(`Status: ${addresses.deploymentStatus}`);
    console.log(`Gas Used: ${addresses.gasUsed || 'N/A'}`);
    
    if (Object.keys(addresses.storage).length > 0) {
      console.log('\n📦 Storage Contracts:');
      Object.entries(addresses.storage).forEach(([name, addr]) => {
        if (addr) console.log(`  ${name}: ${addr}`);
      });
    }
    
    if (Object.keys(addresses.implementations).length > 0) {
      console.log('\n🧠 Implementation Contracts:');
      Object.entries(addresses.implementations).forEach(([name, addr]) => {
        if (addr) console.log(`  ${name}: ${addr}`);
      });
    }
    
    if (Object.keys(addresses.proxies).length > 0) {
      console.log('\n🔗 Proxy Contracts:');
      Object.entries(addresses.proxies).forEach(([name, addr]) => {
        if (addr) console.log(`  ${name}: ${addr}`);
      });
    }
    
    if (addresses.errors && addresses.errors.length > 0) {
      console.log('\n⚠️ Errors:');
      addresses.errors.forEach(error => console.log(`  ${error}`));
    }
    console.log('========================\n');
  }

  private async ensureDirectories(): Promise<void> {
    const deploymentsDir = path.dirname(this.addressesFile);
    await fs.mkdir(deploymentsDir, { recursive: true });
    await fs.mkdir(this.logsDir, { recursive: true });
  }
}

// CLI Interface
async function main(): Promise<void> {
  const args = process.argv.slice(2);
  const stageArg = args.find((arg: string) => arg.startsWith('--stage='));
  const rpcUrlArg = args.find((arg: string) => arg.startsWith('--rpc-url='));
  const broadcast = args.includes('--broadcast');
  const verify = args.includes('--verify');

  const stage = stageArg?.split('=')[1] as DeploymentConfig['stage'] || 'complete';
  const rpcUrl = rpcUrlArg?.split('=')[1];

  if (!['storage', 'logic', 'proxies', 'config', 'complete'].includes(stage)) {
    console.error('❌ Invalid stage. Must be one of: storage, logic, proxies, config, complete');
    process.exit(1);
  }

  const config: DeploymentConfig = {
    stage,
    rpcUrl,
    broadcast,
    verify
  };

  const deployer = new QuikDBDeployer(config);
  await deployer.deploy();
}

// Only run if this is the main module
if (require.main === module) {
  main().catch(console.error);
}

export { QuikDBDeployer, DeploymentConfig, DeploymentAddresses };
