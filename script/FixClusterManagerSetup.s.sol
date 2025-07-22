// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/proxy/ClusterManager.sol";

contract FixClusterManagerSetup is Script {
    ClusterManager clusterManager = ClusterManager(payable(0x56d33ac20b19013910467a83D7Dc2509140CfBB9)); // ClusterManager address
    address clusterStorageAddress = 0x687efff2Aa8FC5d5C869A344fbc408f8EfB5a21A; // ClusterStorage address
    
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        console.log("=== Fixing ClusterManager Setup ===");
        console.log("ClusterManager address:", address(clusterManager));
        console.log("ClusterStorage address:", clusterStorageAddress);
        console.log("Caller address:", msg.sender);
        
        // Check current clusterStorage setting in ClusterManager
        try clusterManager.clusterStorage() returns (ClusterStorage currentStorage) {
            console.log("Current ClusterStorage in ClusterManager:", address(currentStorage));
            if (address(currentStorage) == clusterStorageAddress) {
                console.log("ClusterStorage is already correctly set in ClusterManager!");
                return;
            }
        } catch {
            console.log("ClusterStorage is not set in ClusterManager (address zero)");
        }
        
        // Set the ClusterStorage address in ClusterManager
        console.log("\nSetting ClusterStorage address in ClusterManager...");
        clusterManager.setClusterStorage(clusterStorageAddress);
        console.log("SUCCESS: ClusterStorage address set in ClusterManager!");
        
        // Verify the setting
        ClusterStorage newStorage = clusterManager.clusterStorage();
        console.log("Verification - New ClusterStorage address:", address(newStorage));
        
        if (address(newStorage) == clusterStorageAddress) {
            console.log("SUCCESS: ClusterManager is now properly configured!");
        } else {
            console.log("ERROR: ClusterStorage address not set correctly in ClusterManager");
        }
        
        console.log("\n=== ClusterManager Setup Complete ===");
        
        vm.stopBroadcast();
    }
}
