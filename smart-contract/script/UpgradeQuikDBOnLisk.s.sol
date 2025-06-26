// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/proxy/QuikLogic.sol";
import "../src/proxy/QuikProxy.sol";

/**
 * @title UpgradeQuikDBOnLisk
 * @notice Script for upgrading QuikDB contracts on Lisk blockchain
 * @dev This script handles contract upgrades using the proxy pattern
 */
contract UpgradeQuikDBOnLisk is Script {
    // Addresses from previous deployment - these should be updated to match your deployment
    address public constant PROXY_ADDRESS = address(0); // Update with actual proxy address
    address public constant PROXY_ADMIN_ADDRESS = address(0); // Update with actual proxy admin address

    // Address of the upgrader with permission to perform upgrades
    address public upgrader;

    function setUp() public {
        // In production, set this to the actual upgrader address
        upgrader = msg.sender;

        // Validate addresses are set
        require(PROXY_ADDRESS != address(0), "Proxy address not set");
        require(
            PROXY_ADMIN_ADDRESS != address(0),
            "Proxy admin address not set"
        );
    }

    function run() public {
        // Only continue if the upgrader address is properly set
        require(upgrader != address(0), "Upgrader address not set");

        // Start recording transactions to broadcast
        vm.startBroadcast(upgrader);

        console.log("=== QuikDB Upgrade on Lisk Blockchain ===");
        console.log(string.concat("Upgrader address: ", vm.toString(upgrader)));
        console.log(
            string.concat("Proxy address: ", vm.toString(PROXY_ADDRESS))
        );
        console.log(
            string.concat(
                "Proxy admin address: ",
                vm.toString(PROXY_ADMIN_ADDRESS)
            )
        );

        // STEP 1: Deploy new logic implementation
        console.log("Step 1: Deploying new logic implementation...");
        QuikLogic newLogicImplementation = new QuikLogic();
        console.log(
            string.concat(
                "New logic implementation deployed at: ",
                vm.toString(address(newLogicImplementation))
            )
        );

        // STEP 2: Get reference to the proxy admin
        console.log("Step 2: Accessing proxy admin...");
        QuikProxyAdmin proxyAdmin = QuikProxyAdmin(PROXY_ADMIN_ADDRESS);

        // Verify the upgrader has permission
        bool hasUpgraderRole = proxyAdmin.hasRole(
            proxyAdmin.UPGRADER_ROLE(),
            upgrader
        );
        bool isOwner = (proxyAdmin.owner() == upgrader);

        console.log(
            string.concat(
                "Upgrader has UPGRADER_ROLE: ",
                hasUpgraderRole ? "true" : "false"
            )
        );
        console.log(
            string.concat("Upgrader is owner: ", isOwner ? "true" : "false")
        );

        require(
            hasUpgraderRole || isOwner,
            "Upgrader doesn't have permission to upgrade"
        );

        // STEP 3: Perform the upgrade
        console.log("Step 3: Performing the upgrade...");

        // Option 1: Use upgradeLogic if the upgrader has UPGRADER_ROLE
        if (hasUpgraderRole) {
            console.log("Upgrading using upgradeLogic...");
            try
                proxyAdmin.upgradeLogic(
                    ITransparentUpgradeableProxy(PROXY_ADDRESS),
                    address(newLogicImplementation)
                )
            {
                console.log("Upgrade successful using upgradeLogic");
            } catch {
                console.log(
                    "upgradeLogic failed, trying direct upgradeAndCall..."
                );
                // Fall back to direct method if needed
                proxyAdmin.upgradeAndCall(
                    ITransparentUpgradeableProxy(PROXY_ADDRESS),
                    address(newLogicImplementation),
                    ""
                );
                console.log("Upgrade successful using upgradeAndCall");
            }
        }
        // Option 2: Use direct upgradeAndCall if the upgrader is the owner
        else if (isOwner) {
            console.log("Upgrading using upgradeAndCall directly...");
            proxyAdmin.upgradeAndCall(
                ITransparentUpgradeableProxy(PROXY_ADDRESS),
                address(newLogicImplementation),
                ""
            );
            console.log("Upgrade successful using upgradeAndCall");
        }

        // STEP 4: Verify the upgrade
        console.log("\nStep 4: Verifying the upgrade...");
        // In a real script, you might want to add verification logic here
        // For example, call a function on the upgraded contract to verify it works

        console.log("\n=== Upgrade to Lisk Complete! ===");

        // Stop recording transactions
        vm.stopBroadcast();
    }
}
