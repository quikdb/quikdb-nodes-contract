#!/usr/bin/env tsx
import { config } from 'dotenv';
import { DeploymentController } from './DeploymentController';

// Load environment variables from .env file
config();

/**
 * Main deployment script for QuikDB contracts
 * 
 * Usage:
 *   tsx scripts/deploy.ts [--broadcast]
 *   
 * Examples:
 *   tsx scripts/deploy.ts                    # Dry run (no broadcasting)
 *   tsx scripts/deploy.ts --broadcast        # Deploy to network
 */

async function main() {
  const args = process.argv.slice(2);
  const broadcast = args.includes('--broadcast');
  
  // Validate required environment variables
  if (!process.env.PRIVATE_KEY) {
    console.error('❌ PRIVATE_KEY environment variable is required');
    console.error('   Set it in your .env file or export it in your shell');
    process.exit(1);
  }

  if (broadcast && !process.env.RPC_URL) {
    console.error('❌ RPC_URL environment variable is required for broadcasting');
    console.error('   Examples:');
    console.error('     export RPC_URL=https://rpc.sepolia-api.lisk.com     # Lisk Sepolia');
    console.error('     export RPC_URL=https://rpc.api.lisk.com             # Lisk Mainnet');
    console.error('     export RPC_URL=http://localhost:8545                # Local node');
    process.exit(1);
  }

  try {
    const controller = new DeploymentController();
    await controller.deployDirect(broadcast);
    
    console.log('\n✅ Deployment completed successfully!');
    
    if (broadcast) {
      console.log('\n📝 Next steps:');
      console.log('   1. Verify contracts on block explorer');
      console.log('   2. Run validation: yarn validate:lsk:testnet');
      console.log('   3. Test contract functionality');
    } else {
      console.log('\n📝 This was a dry run. To deploy to network, use: --broadcast');
    }
    
  } catch (error) {
    console.error('❌ Deployment failed:', (error as Error).message);
    process.exit(1);
  }
}

// Handle script execution
if (require.main === module) {
  main().catch(error => {
    console.error('❌ Deployment script failed:', error);
    process.exit(1);
  });
}
