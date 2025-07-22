// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/proxy/ClusterLogic.sol";

contract FixClusterLogicSetup is Script {
    ClusterLogic clusterLogic = ClusterLogic(payable(0x9335Fac8bEf39FcB7a19DCe4c8a2Ff3250dDdc53)); // ClusterLogic proxy
    address clusterStorageAddress = 0x687efff2Aa8FC5d5C869A344fbc408f8EfB5a21A; // ClusterStorage address
    
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        console.log("=== Fixing ClusterLogic Setup ===");
        console.log("ClusterLogic proxy address:", address(clusterLogic));
        console.log("ClusterStorage address:", clusterStorageAddress);
        console.log("Caller address:", msg.sender);
        
        // Check current clusterStorage setting
        try clusterLogic.clusterStorage() returns (ClusterStorage currentStorage) {
            console.log("Current ClusterStorage in ClusterLogic:", address(currentStorage));
            if (address(currentStorage) == clusterStorageAddress) {
                console.log("ClusterStorage is already correctly set!");
                return;
            }
        } catch {
            console.log("ClusterStorage is not set (address zero)");
        }
        
        // Set the ClusterStorage address in ClusterLogic
        console.log("\nSetting ClusterStorage address in ClusterLogic...");
        clusterLogic.setClusterStorage(clusterStorageAddress);
        console.log("SUCCESS: ClusterStorage address set in ClusterLogic!");
        
        // Verify the setting
        ClusterStorage newStorage = clusterLogic.clusterStorage();
        console.log("Verification - New ClusterStorage address:", address(newStorage));
        
        if (address(newStorage) == clusterStorageAddress) {
            console.log("SUCCESS: ClusterLogic is now properly configured!");
        } else {
            console.log("ERROR: ClusterStorage address not set correctly");
        }
        
        console.log("\n=== ClusterLogic Setup Complete ===");
        
        vm.stopBroadcast();
    }
}
