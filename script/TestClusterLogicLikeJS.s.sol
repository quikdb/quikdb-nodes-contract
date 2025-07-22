// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/proxy/ClusterLogic.sol";

contract TestClusterLogicLikeJS is Script {
    ClusterLogic clusterLogic = ClusterLogic(payable(0x9335Fac8bEf39FcB7a19DCe4c8a2Ff3250dDdc53)); // ClusterLogic proxy
    
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        console.log("=== Testing ClusterLogic Contract (Like JavaScript CLI) ===");
        console.log("ClusterLogic address:", address(clusterLogic));
        console.log("Caller address:", msg.sender);
        
        // Check if ClusterStorage is properly set
        address clusterStorageAddr = address(clusterLogic.clusterStorage());
        console.log("ClusterStorage address in ClusterLogic:", clusterStorageAddr);
        
        // Check if ClusterManager is properly set
        address clusterManagerAddr = address(clusterLogic.clusterManager());
        console.log("ClusterManager address in ClusterLogic:", clusterManagerAddr);
        
        // Test cluster registration like the JS CLI does
        console.log("\n1. Testing registerCluster via ClusterLogic...");
        
        // Prepare the data for the first registerCluster method
        address[] memory nodeAddresses = new address[](1);
        nodeAddresses[0] = msg.sender;
        
        try clusterLogic.registerCluster(
            "test-cluster-js-001",
            nodeAddresses,
            ClusterStorage.ClusterStrategy.ROUND_ROBIN,
            1,
            true
        ) {
            console.log("SUCCESS: registerCluster worked via ClusterLogic!");
        } catch Error(string memory reason) {
            console.log("FAILED: registerCluster failed with reason:", reason);
        } catch {
            console.log("FAILED: registerCluster failed with unknown error");
        }
        
        console.log("\n=== ClusterLogic Test Complete ===");
        
        vm.stopBroadcast();
    }
}
