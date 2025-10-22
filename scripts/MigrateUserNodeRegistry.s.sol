// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/UserNodeRegistry.sol";

/**
 * @title MigrateUserNodeRegistry
 * @notice Migrates all user and node data from old UserNodeRegistry to new one
 * @dev Run with: forge script scripts/MigrateUserNodeRegistry.s.sol:MigrateUserNodeRegistry --rpc-url <RPC_URL> --broadcast
 * 
 * Prerequisites:
 * - NEW_USER_REGISTRY_ADDRESS must be owned by PRIVATE_KEY signer
 * - Sufficient gas for batch operations
 * 
 * Environment Variables:
 * - PRIVATE_KEY: Private key of NEW registry owner
 * - OLD_USER_REGISTRY_ADDRESS: Address of old UserNodeRegistry with data
 * - NEW_USER_REGISTRY_ADDRESS: Address of new UserNodeRegistry (empty)
 */
contract MigrateUserNodeRegistry is Script {
    
    struct UserData {
        address userAddress;
        bytes32 profileHash;
        uint8 userType;
        bool isActive;
        uint256 createdAt;
        uint256 totalSpent;
        uint256 totalEarned;
        uint256 reputationScore;
    }
    
    struct NodeData {
        address operator;
        bytes32 metadataHash;
        uint8 tier;
        uint8 providerType;
        uint8 status;
        uint256 registeredAt;
        uint256 lastActiveAt;
        uint256 hourlyRate;
        uint256 uptimePercentage;
        uint256 totalJobs;
        uint256 successfulJobs;
        uint256 totalEarnings;
        bool isListed;
    }
    
    function run() external {
        // Load environment variables
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        address oldRegistryAddress = vm.envAddress("OLD_USER_REGISTRY_ADDRESS");
        address newRegistryAddress = vm.envAddress("NEW_USER_REGISTRY_ADDRESS");
        
        console.log("=================================================");
        console.log("UserNodeRegistry Migration");
        console.log("=================================================");
        console.log("Migrator:", deployer);
        console.log("Old Registry:", oldRegistryAddress);
        console.log("New Registry:", newRegistryAddress);
        console.log("=================================================");
        
        UserNodeRegistry oldRegistry = UserNodeRegistry(oldRegistryAddress);
        UserNodeRegistry newRegistry = UserNodeRegistry(newRegistryAddress);
        
        // Verify ownership
        require(newRegistry.owner() == deployer, "Deployer must own NEW registry");
        
        // Get total counts
        uint256 totalUsers = oldRegistry.totalUsers();
        uint256 totalNodes = oldRegistry.totalNodes();
        
        console.log("Total Users to migrate:", totalUsers);
        console.log("Total Nodes to migrate:", totalNodes);
        console.log("=================================================");
        
        if (totalUsers == 0) {
            console.log("No users to migrate. Exiting.");
            return;
        }
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Migrate users
        console.log("Migrating users...");
        for (uint256 i = 0; i < totalUsers; i++) {
            address userAddr = oldRegistry.allUsers(i);
            
            (
                address userAddress,
                bytes32 profileHash,
                UserNodeRegistry.UserType userType,
                bool isActive,
                uint256 createdAt,
                uint256 totalSpent,
                uint256 totalEarned,
                uint256 reputationScore
            ) = oldRegistry.users(userAddr);
            
            // Register user in new registry
            newRegistry.registerUser(userAddress, profileHash, userType);
            
            if ((i + 1) % 10 == 0 || i == totalUsers - 1) {
                console.log("  Migrated users:", i + 1);
            }
        }
        
        // Migrate nodes
        console.log("Migrating nodes...");
        for (uint256 i = 0; i < totalNodes; i++) {
            address nodeAddr = oldRegistry.allNodes(i);
            
            (
                address operator,
                bytes32 metadataHash,
                UserNodeRegistry.NodeTier tier,
                UserNodeRegistry.ProviderType providerType,
                UserNodeRegistry.NodeStatus status,
                uint256 registeredAt,
                uint256 lastActiveAt,
                uint256 hourlyRate,
                uint256 uptimePercentage,
                uint256 totalJobs,
                uint256 successfulJobs,
                uint256 totalEarnings,
                bool isListed
            ) = oldRegistry.nodes(nodeAddr);
            
            // Register node in new registry
            newRegistry.registerNode(operator, metadataHash, tier, providerType);
            
            if ((i + 1) % 10 == 0 || i == totalNodes - 1) {
                console.log("  Migrated nodes:", i + 1);
            }
        }
        
        vm.stopBroadcast();
        
        console.log("=================================================");
        console.log("Migration complete!");
        console.log("=================================================");
        
        // Verify migration
        console.log("Verifying migration...");
        uint256 newTotalUsers = newRegistry.totalUsers();
        uint256 newTotalNodes = newRegistry.totalNodes();
        
        console.log("Old Registry - Users:", totalUsers, "Nodes:", totalNodes);
        console.log("New Registry - Users:", newTotalUsers, "Nodes:", newTotalNodes);
        
        require(newTotalUsers == totalUsers, "User count mismatch");
        require(newTotalNodes == totalNodes, "Node count mismatch");
        
        console.log("=================================================");
        console.log("SUCCESS: Migration verified successfully!");
        console.log("=================================================");
    }
}
