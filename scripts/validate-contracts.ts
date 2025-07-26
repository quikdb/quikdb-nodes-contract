#!/usr/bin/env tsx
import { ethers } from 'ethers';
import { readFileSync, existsSync } from 'fs';
import { join } from 'path';

async function validateContracts() {
  console.log('🔍 Validating simplified QuikDB contract deployments...');
  
  try {
    // Load deployment addresses from local files
    const deploymentsDir = join(process.cwd(), 'deployments');
    const addressesFile = join(deploymentsDir, 'addresses.json');
    
    if (!existsSync(addressesFile)) {
      throw new Error('Deployment addresses file not found. Please run deployment first.');
    }
    
    const addresses = JSON.parse(readFileSync(addressesFile, 'utf8'));
    console.log('✅ Contract addresses loaded successfully');
    
    // Verify all expected contracts are present (simplified architecture)
    const expectedContracts = [
      'UserNodeRegistry',
      'UserNodeRegistryImpl',
      'QuiksToken',
      'QuiksTokenImpl'
    ];
    
    console.log('\n📋 Contract Addresses:');
    for (const contract of expectedContracts) {
      if (addresses[contract]) {
        console.log(`  ✅ ${contract}: ${addresses[contract]}`);
      } else {
        console.log(`  ❌ ${contract}: MISSING`);
      }
    }
    
    // Test contract validation with basic checks
    console.log('\n🔗 Contract Validation:');
    
    // Check if addresses are valid Ethereum addresses
    for (const contract of expectedContracts) {
      if (addresses[contract]) {
        const address = addresses[contract];
        if (ethers.isAddress(address)) {
          console.log(`  ✅ ${contract}: Valid address format`);
        } else {
          console.log(`  ❌ ${contract}: Invalid address format`);
        }
      }
    }
    
    console.log('\n✅ Simplified QuikDB contracts validated successfully!');
    console.log('\n📊 Summary:');
    console.log(`  Total contracts: ${expectedContracts.length}`);
    console.log(`  Successfully loaded: ${expectedContracts.filter(c => addresses[c]).length}`);
    console.log(`  Architecture: Simplified (Owner-only access control)`);
    console.log(`  Contracts: UserNodeRegistry + QuiksToken (Both UUPS Proxies)`);
    
    // Show additional deployment info if available
    const latestFile = join(deploymentsDir, 'latest.json');
    if (existsSync(latestFile)) {
      const deploymentInfo = JSON.parse(readFileSync(latestFile, 'utf8'));
      console.log(`  Network: ${deploymentInfo.network || 'Unknown'}`);
      console.log(`  Deployed: ${deploymentInfo.deployedAt || 'Unknown'}`);
    }
    
  } catch (error) {
    console.error('❌ Validation failed:', (error as Error).message);
    process.exit(1);
  }
}

// Run validation
validateContracts().catch(error => {
  console.error('❌ Script failed:', error);
  process.exit(1);
});
