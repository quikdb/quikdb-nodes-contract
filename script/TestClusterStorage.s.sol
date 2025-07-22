// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/storage/ClusterStorage.sol";

contract TestClusterStorage is Script {
    ClusterStorage clusterStorage = ClusterStorage(0x687efff2Aa8FC5d5C869A344fbc408f8EfB5a21A);
    
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        console.log("=== Testing ClusterStorage Contract ===");
        console.log("ClusterStorage address:", address(clusterStorage));
        console.log("Caller address:", msg.sender);
        
        // Test 1: Register a test cluster
        console.log("\n1. Testing registerCluster...");
        
        address[] memory nodeAddresses = new address[](1);
        nodeAddresses[0] = msg.sender;
        
        ClusterStorage.NodeCluster memory cluster = ClusterStorage.NodeCluster({
            clusterId: "test-cluster-002",
            nodeAddresses: nodeAddresses,
            strategy: uint8(ClusterStorage.ClusterStrategy.ROUND_ROBIN),
            minActiveNodes: 1,
            status: uint8(ClusterStorage.ClusterStatus.ACTIVE),
            autoManaged: true,
            createdAt: uint256(block.timestamp)
        });
        
        clusterStorage.registerCluster("test-cluster-002", cluster);
        console.log("SUCCESS: registerCluster worked - no access control restrictions!");
        
        // Test 2: Read the cluster back
        console.log("\n2. Testing getCluster...");
        ClusterStorage.NodeCluster memory retrievedCluster = clusterStorage.getCluster("test-cluster-002");
        console.log("SUCCESS: getCluster worked!");
        console.log("Retrieved cluster ID:", retrievedCluster.clusterId);
        console.log("Node addresses length:", retrievedCluster.nodeAddresses.length);
        console.log("First node address:", retrievedCluster.nodeAddresses[0]);
        console.log("Status:", retrievedCluster.status); // 1 = ACTIVE
        
        // Test 3: Update cluster status
        console.log("\n3. Testing updateClusterStatus...");
        clusterStorage.updateClusterStatus("test-cluster-002", uint8(ClusterStorage.ClusterStatus.MAINTENANCE));
        console.log("SUCCESS: updateClusterStatus worked!");
        
        // Verify the update
        ClusterStorage.NodeCluster memory updatedCluster = clusterStorage.getCluster("test-cluster-002");
        console.log("Updated status:", updatedCluster.status); // 2 = MAINTENANCE
        
        console.log("\n=== ClusterStorage Test Complete ===");
        console.log("SUCCESS: ALL OPERATIONS SUCCESSFUL!");
        console.log("ClusterStorage is working without access control restrictions!");
        
        vm.stopBroadcast();
    }
}
