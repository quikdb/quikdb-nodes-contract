/**
 * Simplified Deployment Validation Script for QuikDB
 * 
 * This script validates that the simplified QuikDB contracts are working correctly
 * by testing basic functionality of UserNodeRegistry and QuiksToken.
 * 
 * Usage: npx tsx scripts/validateDeployment.ts [network] [rpc-url]
 * Example: npx tsx scripts/validateDeployment.ts lisk-sepolia https://rpc.sepolia-api.lisk.com
 */

import { ethers, Contract, JsonRpcProvider, Wallet } from "ethers";
import * as fs from "fs";
import * as path from "path";
import { config } from "dotenv";

config();

// Network configuration
const NETWORK_CONFIG = {
    'lisk-sepolia': {
        explorerUrl: 'https://sepolia-blockscout.lisk.com',
        chainId: 4202,
        name: 'Lisk Sepolia Testnet',
        rpcUrl: 'https://rpc.sepolia-api.lisk.com'
    },
    'lisk-mainnet': {
        explorerUrl: 'https://blockscout.lisk.com',
        chainId: 1135,
        name: 'Lisk Mainnet',
        rpcUrl: 'https://rpc.api.lisk.com'
    },
    'local': {
        explorerUrl: 'http://localhost:8545',
        chainId: 31337,
        name: 'Local Hardhat',
        rpcUrl: 'http://127.0.0.1:8545'
    }
};

// Simplified contract addresses interface
interface ContractAddresses {
    UserNodeRegistry: string;
    QuiksToken: string;
    QuiksTokenImpl: string;
}

// Contract instances
interface Contracts {
    userNodeRegistry: Contract;
    quiksToken: Contract;
}

// Validation results
interface ValidationResults {
    successes: string[];
    failures: string[];
    warnings: string[];
}

// Test case interface
interface TestCase {
    name: string;
    test: () => Promise<void>;
}

// Global variables
let provider: JsonRpcProvider;
let signer: Wallet;
let contracts: Contracts = {} as Contracts;
let CONTRACT_ADDRESSES: ContractAddresses = {} as ContractAddresses;
let results: ValidationResults = { successes: [], failures: [], warnings: [] };

/**
 * Load deployment addresses from the deployments directory
 */
async function loadDeploymentAddresses(network: string): Promise<void> {
    try {
        const deploymentsDir = path.join(__dirname, "..", "deployments");
        
        // Try network-specific file first, then latest.json, then addresses.json
        const possibleFiles = [
            path.join(deploymentsDir, `${network}.json`),
            path.join(deploymentsDir, "latest.json"),
            path.join(deploymentsDir, "addresses.json")
        ];
        
        let deploymentFile = '';
        for (const file of possibleFiles) {
            if (fs.existsSync(file)) {
                deploymentFile = file;
                break;
            }
        }
        
        if (!deploymentFile) {
            throw new Error(`No deployment file found for network '${network}'. Please deploy contracts first.`);
        }
        
        const deploymentData = JSON.parse(fs.readFileSync(deploymentFile, "utf8"));
        
        // Handle different deployment file formats
        if (deploymentData.UserNodeRegistry && deploymentData.QuiksToken) {
            // Simple addresses.json format
            CONTRACT_ADDRESSES = deploymentData;
        } else if (deploymentData.contracts) {
            // Nested format
            CONTRACT_ADDRESSES = deploymentData.contracts;
        } else {
            throw new Error("Invalid deployment file format");
        }
        
        console.log("✅ Loaded deployment addresses from:", deploymentFile);
        console.log("📋 Contract addresses:");
        console.log(`   UserNodeRegistry: ${CONTRACT_ADDRESSES.UserNodeRegistry}`);
        console.log(`   QuiksToken: ${CONTRACT_ADDRESSES.QuiksToken}`);
        console.log(`   QuiksTokenImpl: ${CONTRACT_ADDRESSES.QuiksTokenImpl}`);
        
        // Validate addresses
        const requiredContracts = ['UserNodeRegistry', 'QuiksToken', 'QuiksTokenImpl'];
        const missingContracts = [];
        
        for (const contractName of requiredContracts) {
            const address = CONTRACT_ADDRESSES[contractName as keyof ContractAddresses];
            if (!address || !ethers.isAddress(address)) {
                missingContracts.push(contractName);
            }
        }
        
        if (missingContracts.length > 0) {
            throw new Error(`Missing or invalid addresses for: ${missingContracts.join(', ')}`);
        }
        
    } catch (error) {
        console.error("❌ Failed to load deployment addresses:", (error as Error).message);
        process.exit(1);
    }
}

/**
 * Initialize contract instances
 */
async function initializeContracts(): Promise<void> {
    try {
        // Simplified ABI for basic testing (only the functions we need to test)
        const userNodeRegistryABI = [
            "function owner() view returns (address)",
            "function totalUsers() view returns (uint256)",
            "function totalNodes() view returns (uint256)",
            "function paused() view returns (bool)"
        ];
        
        const quiksTokenABI = [
            "function name() view returns (string)",
            "function symbol() view returns (string)",
            "function decimals() view returns (uint8)",
            "function totalSupply() view returns (uint256)",
            "function owner() view returns (address)",
            "function balanceOf(address) view returns (uint256)"
        ];
        
        // Create contract instances
        contracts.userNodeRegistry = new Contract(
            CONTRACT_ADDRESSES.UserNodeRegistry,
            userNodeRegistryABI,
            provider
        );
        
        contracts.quiksToken = new Contract(
            CONTRACT_ADDRESSES.QuiksToken,
            quiksTokenABI,
            provider
        );
        
        console.log("✅ Contract instances initialized");
        
    } catch (error) {
        console.error("❌ Failed to initialize contracts:", (error as Error).message);
        process.exit(1);
    }
}

/**
 * Test UserNodeRegistry basic functionality
 */
async function testUserNodeRegistry(): Promise<void> {
    try {
        console.log("\n🔍 Testing UserNodeRegistry...");
        
        // Test basic view functions
        const owner = await contracts.userNodeRegistry.owner();
        const totalUsers = await contracts.userNodeRegistry.totalUsers();
        const totalNodes = await contracts.userNodeRegistry.totalNodes();
        const isPaused = await contracts.userNodeRegistry.paused();
        
        console.log(`   Owner: ${owner}`);
        console.log(`   Total Users: ${totalUsers.toString()}`);
        console.log(`   Total Nodes: ${totalNodes.toString()}`);
        console.log(`   Paused: ${isPaused}`);
        
        // Validate owner address
        if (!ethers.isAddress(owner)) {
            throw new Error("Invalid owner address");
        }
        
        results.successes.push("UserNodeRegistry basic functions work correctly");
        
    } catch (error) {
        results.failures.push(`UserNodeRegistry test failed: ${(error as Error).message}`);
    }
}

/**
 * Test QuiksToken basic functionality
 */
async function testQuiksToken(): Promise<void> {
    try {
        console.log("\n🪙 Testing QuiksToken...");
        
        // Test basic ERC20 view functions
        const name = await contracts.quiksToken.name();
        const symbol = await contracts.quiksToken.symbol();
        const decimals = await contracts.quiksToken.decimals();
        const totalSupply = await contracts.quiksToken.totalSupply();
        const owner = await contracts.quiksToken.owner();
        
        console.log(`   Name: ${name}`);
        console.log(`   Symbol: ${symbol}`);
        console.log(`   Decimals: ${decimals}`);
        console.log(`   Total Supply: ${ethers.formatEther(totalSupply)} ${symbol}`);
        console.log(`   Owner: ${owner}`);
        
        // Validate token parameters
        if (symbol !== "QUIKS") {
            results.warnings.push("Token symbol is not 'QUIKS'");
        }
        
        if (decimals !== 18) {
            results.warnings.push("Token decimals is not 18");
        }
        
        if (!ethers.isAddress(owner)) {
            throw new Error("Invalid owner address");
        }
        
        // Test balance query (should not revert)
        const zeroBalance = await contracts.quiksToken.balanceOf(ethers.ZeroAddress);
        console.log(`   Zero address balance: ${zeroBalance.toString()}`);
        
        results.successes.push("QuiksToken basic functions work correctly");
        
    } catch (error) {
        results.failures.push(`QuiksToken test failed: ${(error as Error).message}`);
    }
}

/**
 * Test contract addresses are valid
 */
async function testContractAddresses(): Promise<void> {
    try {
        console.log("\n📍 Testing contract addresses...");
        
        for (const [name, address] of Object.entries(CONTRACT_ADDRESSES)) {
            console.log(`   ${name}: ${address}`);
            
            // Check if address has code
            const code = await provider.getCode(address);
            if (code === "0x") {
                throw new Error(`No code found at ${name} address: ${address}`);
            } else {
                console.log(`   ✅ ${name} has contract code`);
            }
        }
        
        results.successes.push("All contract addresses are valid and have code");
        
    } catch (error) {
        results.failures.push(`Contract address validation failed: ${(error as Error).message}`);
    }
}

/**
 * Run all validation tests
 */
async function runValidation(): Promise<void> {
    const testCases: TestCase[] = [
        { name: "Contract Addresses", test: testContractAddresses },
        { name: "UserNodeRegistry", test: testUserNodeRegistry },
        { name: "QuiksToken", test: testQuiksToken }
    ];
    
    console.log("🚀 Starting simplified QuikDB contract validation...");
    console.log(`📡 Network: ${provider._getConnection().url}`);
    console.log(`🆔 Chain ID: ${await provider.getNetwork().then(n => n.chainId)}`);
    
    for (const testCase of testCases) {
        try {
            await testCase.test();
        } catch (error) {
            console.error(`❌ Test '${testCase.name}' failed:`, (error as Error).message);
        }
    }
}

/**
 * Print validation results
 */
function printResults(): void {
    console.log("\n" + "=".repeat(80));
    console.log("📊 VALIDATION RESULTS");
    console.log("=".repeat(80));
    
    if (results.successes.length > 0) {
        console.log("\n✅ SUCCESSES:");
        results.successes.forEach(success => console.log(`   ✅ ${success}`));
    }
    
    if (results.warnings.length > 0) {
        console.log("\n⚠️  WARNINGS:");
        results.warnings.forEach(warning => console.log(`   ⚠️  ${warning}`));
    }
    
    if (results.failures.length > 0) {
        console.log("\n❌ FAILURES:");
        results.failures.forEach(failure => console.log(`   ❌ ${failure}`));
    }
    
    console.log("\n📈 SUMMARY:");
    console.log(`   Successes: ${results.successes.length}`);
    console.log(`   Warnings: ${results.warnings.length}`);
    console.log(`   Failures: ${results.failures.length}`);
    
    if (results.failures.length === 0) {
        console.log("\n🎉 All validations passed! Contracts are working correctly.");
    } else {
        console.log("\n💥 Some validations failed. Please check the deployment.");
        process.exit(1);
    }
}

/**
 * Main execution function
 */
async function main(): Promise<void> {
    try {
        // Parse command line arguments
        const args = process.argv.slice(2);
        const network = args[0] || 'local';
        const rpcUrl = args[1] || process.env.RPC_URL || NETWORK_CONFIG[network as keyof typeof NETWORK_CONFIG]?.rpcUrl;
        
        if (!rpcUrl) {
            console.error("❌ No RPC URL provided. Use: npx tsx scripts/validateDeployment.ts [network] [rpc-url]");
            process.exit(1);
        }
        
        console.log(`🌐 Connecting to network: ${network}`);
        console.log(`📡 RPC URL: ${rpcUrl}`);
        
        // Initialize provider
        provider = new JsonRpcProvider(rpcUrl);
        
        // Test connection
        await provider.getBlockNumber();
        console.log("✅ Connected to blockchain");
        
        // Load deployment addresses
        await loadDeploymentAddresses(network);
        
        // Initialize contracts
        await initializeContracts();
        
        // Run validation tests
        await runValidation();
        
        // Print results
        printResults();
        
    } catch (error) {
        console.error("💥 Validation script failed:", (error as Error).message);
        process.exit(1);
    }
}

// Run the validation
if (require.main === module) {
    main().catch(error => {
        console.error("💥 Script failed:", error);
        process.exit(1);
    });
}

export default main;
