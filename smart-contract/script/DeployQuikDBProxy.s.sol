// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/proxy/QuikLogic.sol";
import "../src/proxy/QuikProxy.sol";
import "../src/storage/NodeStorage.sol";
import "../src/storage/UserStorage.sol";
import "../src/storage/ResourceStorage.sol";

/**
 * @title DeployQuikDBProxy
 * @notice Deployment script for QuikDB nodes contracts on Lisk blockchain
 * @dev This script deploys the entire contract suite including storage contracts,
 *      the logic implementation, and the proxy admin & proxy contract
 */
contract DeployQuikDBProxy is Script {
    // Admin address that will control the contracts
    address public admin;

    // Storage contract instances
    NodeStorage public nodeStorage;
    UserStorage public userStorage;
    ResourceStorage public resourceStorage;

    // Logic implementation
    QuikLogic public logicImplementation;

    // Proxy admin for managing the proxy
    QuikProxyAdmin public proxyAdmin;

    // Main proxy contract
    QuikProxy public proxy;

    // Interface to interact with the proxy
    QuikLogic public quikPlatform;

    function setUp() public {
        // The admin address should be set to your desired admin wallet
        // For the production deployment, you should use a secure multi-sig wallet
        admin = msg.sender;
    }

    function run() public {
        // Start broadcasting transactions
        vm.startBroadcast();
        console.log("Deploying QuikDB nodes contracts to Lisk blockchain...");
        console.log(
            string.concat("Deployer/Admin address: ", vm.toString(admin))
        );

        // Step 1: Deploy storage contracts
        console.log("Deploying storage contracts...");
        nodeStorage = new NodeStorage(admin);
        console.log(
            string.concat(
                "NodeStorage deployed at: ",
                vm.toString(address(nodeStorage))
            )
        );

        userStorage = new UserStorage(admin);
        console.log(
            string.concat(
                "UserStorage deployed at: ",
                vm.toString(address(userStorage))
            )
        );

        resourceStorage = new ResourceStorage(admin);
        console.log(
            string.concat(
                "ResourceStorage deployed at: ",
                vm.toString(address(resourceStorage))
            )
        );

        // Step 2: Deploy logic implementation
        console.log("Deploying logic implementation...");
        logicImplementation = new QuikLogic();
        console.log(
            string.concat(
                "QuikLogic implementation deployed at: ",
                vm.toString(address(logicImplementation))
            )
        );

        // Step 3: Deploy proxy admin
        console.log("Deploying proxy admin...");
        proxyAdmin = new QuikProxyAdmin(admin);
        console.log(
            string.concat(
                "ProxyAdmin deployed at: ",
                vm.toString(address(proxyAdmin))
            )
        );

        // Step 4: Prepare initialization data for the logic contract
        bytes memory initData = abi.encodeWithSelector(
            QuikLogic.initialize.selector,
            address(nodeStorage),
            address(userStorage),
            address(resourceStorage),
            admin
        );

        // Step 5: Deploy transparent proxy with the implementation and initialization data
        console.log("Deploying transparent proxy...");
        proxy = new QuikProxy(
            address(logicImplementation),
            address(proxyAdmin),
            initData
        );
        console.log(
            string.concat(
                "QuikProxy deployed at: ",
                vm.toString(address(proxy))
            )
        );

        // Step 6: Set up interface to interact with proxy
        quikPlatform = QuikLogic(address(proxy));

        // Step 7: Configure storage contracts to point to proxy as the logic contract
        console.log("Configuring storage contracts...");
        nodeStorage.setLogicContract(address(proxy));
        userStorage.setLogicContract(address(proxy));
        resourceStorage.setLogicContract(address(proxy));

        // Step 8: Set up initial roles (optional)
        // Uncomment and modify the following lines to set up initial roles
        /*
        address nodeOperator = 0x...; // Replace with actual address
        address authService = 0x...;  // Replace with actual address
        address upgrader = 0x...;     // Replace with actual address
        
        quikPlatform.grantRole(quikPlatform.NODE_OPERATOR_ROLE(), nodeOperator);
        quikPlatform.grantRole(quikPlatform.AUTH_SERVICE_ROLE(), authService);
        proxyAdmin.grantUpgraderRole(upgrader);
        */

        // Verify the setup
        console.log("Verifying deployment...");
        assert(
            address(quikPlatform.nodeStorage()) == address(nodeStorage),
            "NodeStorage not properly configured"
        );
        assert(
            address(quikPlatform.userStorage()) == address(userStorage),
            "UserStorage not properly configured"
        );
        assert(
            address(quikPlatform.resourceStorage()) == address(resourceStorage),
            "ResourceStorage not properly configured"
        );

        console.log("Deployment complete!");

        // Stop broadcasting transactions
        vm.stopBroadcast();
    }
}
