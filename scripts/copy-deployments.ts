#!/usr/bin/env tsx
import { copyFileSync, existsSync, mkdirSync } from 'fs';
import { join } from 'path';

/**
 * Script to copy deployments and ABIs to the library
 */

const contractsDir = process.cwd();
const libDir = join(process.cwd(), '..', 'quikdb-apis', 'libs', 'core', 'src');

// Ensure directories exist
const deploymentsDir = join(libDir, 'deployments');
const contractsLibDir = join(libDir, 'contracts');

if (!existsSync(deploymentsDir)) {
  mkdirSync(deploymentsDir, { recursive: true });
}

if (!existsSync(contractsLibDir)) {
  mkdirSync(contractsLibDir, { recursive: true });
}

// Copy deployment files
console.log('📄 Copying deployment files...');
const deploymentFiles = [
  'lisk-sepolia.json',
  'latest.json',
  'addresses.json'
];

for (const file of deploymentFiles) {
  const src = join(contractsDir, 'deployments', file);
  const dest = join(deploymentsDir, file);
  
  if (existsSync(src)) {
    copyFileSync(src, dest);
    console.log(`✅ Copied ${file}`);
  } else {
    console.log(`⚠️  ${file} not found`);
  }
}

// Copy contract ABIs
console.log('\n📄 Copying contract ABIs...');
const contracts = [
  'NodeLogic',
  'UserLogic', 
  'ResourceLogic',
  'RewardsLogic',
  'ApplicationLogic',
  'StorageAllocatorLogic',
  'ClusterLogic',
  'PerformanceLogic',
  'Facade'
];

for (const contract of contracts) {
  const srcPath = join(contractsDir, 'out', `${contract}.sol`);
  const destPath = join(contractsLibDir, `${contract}.sol`);
  
  if (existsSync(srcPath)) {
    // Copy the entire directory
    if (!existsSync(destPath)) {
      mkdirSync(destPath, { recursive: true });
    }
    
    const jsonFile = join(srcPath, `${contract}.json`);
    const destJsonFile = join(destPath, `${contract}.json`);
    
    if (existsSync(jsonFile)) {
      copyFileSync(jsonFile, destJsonFile);
      console.log(`✅ Copied ${contract}.json`);
    } else {
      console.log(`⚠️  ${contract}.json not found in ${srcPath}`);
    }
  } else {
    console.log(`⚠️  ${contract}.sol directory not found`);
  }
}

console.log('\n✅ All deployments and ABIs copied successfully!');
console.log('\n📝 Next steps:');
console.log('   1. Update contracts.ts imports');
console.log('   2. Test contract loading');
console.log('   3. Validate blockchain service integration');
