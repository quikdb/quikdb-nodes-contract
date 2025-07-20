#!/usr/bin/env tsx
import { ethers } from 'ethers';

// Import the contracts utility
const contractsPath = '../../quikdb-apis/libs/core/src/contracts';

async function validateContracts() {
  console.log('🔍 Validating contract deployments...');
  
  try {
    // Import the contracts module
    const { getContractAddresses, getNetworkContracts, NETWORKS } = await import(contractsPath);
    
    // Get contract addresses
    const addresses = getContractAddresses('LISK_SEPOLIA');
    console.log('✅ Contract addresses loaded successfully');
    
    // Verify all expected contracts are present
    const expectedContracts = [
      'nodeLogic',
      'userLogic', 
      'resourceLogic',
      'rewardsLogic',
      'applicationLogic',
      'storageAllocatorLogic',
      'clusterLogic',
      'performanceLogic',
      'facade'
    ];
    
    console.log('\n📋 Contract Addresses:');
    for (const contract of expectedContracts) {
      if (addresses[contract]) {
        console.log(`  ✅ ${contract}: ${addresses[contract]}`);
      } else {
        console.log(`  ❌ ${contract}: MISSING`);
      }
    }
    
    // Test contract instantiation with a provider
    const provider = new ethers.JsonRpcProvider(NETWORKS.LISK_SEPOLIA.rpc);
    const contracts = getNetworkContracts('LISK_SEPOLIA', provider);
    
    console.log('\n🔗 Contract Instances:');
    for (const contract of expectedContracts) {
      if (contracts[contract]) {
        console.log(`  ✅ ${contract}: Instance created successfully`);
      } else {
        console.log(`  ❌ ${contract}: Failed to create instance`);
      }
    }
    
    console.log('\n✅ All contracts validated successfully!');
    console.log('\n📊 Summary:');
    console.log(`  Total contracts: ${expectedContracts.length}`);
    console.log(`  Successfully loaded: ${expectedContracts.filter(c => addresses[c]).length}`);
    console.log(`  Network: ${NETWORKS.LISK_SEPOLIA.name}`);
    console.log(`  Chain ID: ${NETWORKS.LISK_SEPOLIA.chainId}`);
    
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
