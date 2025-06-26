// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/proxy/QuikLogic.sol";
import "../src/proxy/QuikProxy.sol";
import "../src/storage/NodeStorage.sol";
import "../src/storage/UserStorage.sol";
import "../src/storage/ResourceStorage.sol";

/**
 * @title DeployQuikDBToLisk
 * @notice Specialized deployment script for QuikDB nodes contracts on Lisk blockchain
 * @dev This script handles the deployment to Lisk, including any Lisk-specific configurations
 */
contract DeployQuikDBToLisk is Script {
    // Configuration
    address public admin;
    address public nodeOperator;
    address public upgrader;

    // Deployed contract addresses - will be populated during deployment
    struct DeployedContracts {
        address nodeStorage;
        address userStorage;
        address resourceStorage;
        address logicImplementation;
        address proxyAdmin;
        address proxy;
    }

    DeployedContracts public deployed;

    function setUp() public {
        // Load configuration - in production, you might want to load these from environment variables
        // For example: admin = vm.envAddress("ADMIN_ADDRESS");

        // For this example, we'll use the deployer as the admin
        admin = msg.sender;

        // These should be replaced with actual addresses for production deployment
        nodeOperator = address(0x2); // Example address
        upgrader = address(0x4); // Example address
    }

    function run() public {
        // Start recording transactions to broadcast
        vm.startBroadcast();

        console.log("=== QuikDB Deployment to Lisk Blockchain ===");
        console.log(
            string.concat("Deployer/Admin address: ", vm.toString(admin))
        );

        // STEP 1: Deploy storage contracts
        console.log("Step 1: Deploying Storage Contracts...");

        NodeStorage nodeStorage = new NodeStorage(admin);
        deployed.nodeStorage = address(nodeStorage);
        console.log(
            string.concat(
                "NodeStorage deployed at: ",
                vm.toString(deployed.nodeStorage)
            )
        );

        UserStorage userStorage = new UserStorage(admin);
        deployed.userStorage = address(userStorage);
        console.log(
            string.concat(
                "UserStorage deployed at: ",
                vm.toString(deployed.userStorage)
            )
        );

        ResourceStorage resourceStorage = new ResourceStorage(admin);
        deployed.resourceStorage = address(resourceStorage);
        console.log(
            string.concat(
                "ResourceStorage deployed at: ",
                vm.toString(deployed.resourceStorage)
            )
        );

        // STEP 2: Deploy logic implementation
        console.log("Step 2: Deploying Logic Implementation...");
        QuikLogic logicImplementation = new QuikLogic();
        deployed.logicImplementation = address(logicImplementation);
        console.log(
            string.concat(
                "QuikLogic implementation deployed at: ",
                vm.toString(deployed.logicImplementation)
            )
        );

        // STEP 3: Deploy proxy admin
        console.log("Step 3: Deploying Proxy Admin...");
        QuikProxyAdmin proxyAdmin = new QuikProxyAdmin(admin);
        deployed.proxyAdmin = address(proxyAdmin);
        console.log(
            string.concat(
                "ProxyAdmin deployed at: ",
                vm.toString(deployed.proxyAdmin)
            )
        );

        // STEP 4: Prepare initialization data for logic contract
        console.log("Step 4: Preparing initialization data...");
        bytes memory initData = abi.encodeWithSelector(
            QuikLogic.initialize.selector,
            deployed.nodeStorage,
            deployed.userStorage,
            deployed.resourceStorage,
            admin
        );

        // STEP 5: Deploy proxy with implementation and initialization data
        console.log("Step 5: Deploying Transparent Proxy...");
        QuikProxy proxy = new QuikProxy(
            deployed.logicImplementation,
            deployed.proxyAdmin,
            initData
        );
        deployed.proxy = address(proxy);
        console.log(
            string.concat(
                "QuikProxy deployed at: ",
                vm.toString(deployed.proxy)
            )
        );

        // STEP 6: Configure storage contracts to point to proxy
        console.log("Step 6: Configuring storage contracts...");
        nodeStorage.setLogicContract(deployed.proxy);
        userStorage.setLogicContract(deployed.proxy);
        resourceStorage.setLogicContract(deployed.proxy);
        console.log(
            string.concat(
                "Storage contracts configured to use proxy at: ",
                vm.toString(deployed.proxy)
            )
        );

        // STEP 7: Set up access control
        console.log("Step 7: Setting up access control...");
        QuikLogic quikPlatform = QuikLogic(deployed.proxy);

        // Grant roles - make sure these are correct for your production deployment
        quikPlatform.grantRole(quikPlatform.NODE_OPERATOR_ROLE(), nodeOperator);
        console.log(
            string.concat(
                "NODE_OPERATOR_ROLE granted to: ",
                vm.toString(nodeOperator)
            )
        );

        quikPlatform.grantRole(quikPlatform.AUTH_SERVICE_ROLE(), admin);
        console.log(
            string.concat(
                "AUTH_SERVICE_ROLE granted to admin: ",
                vm.toString(admin)
            )
        );

        proxyAdmin.grantUpgraderRole(upgrader);
        console.log(
            string.concat("UPGRADER_ROLE granted to: ", vm.toString(upgrader))
        );

        // STEP 8: Verify deployment
        console.log("Step 8: Verifying deployment...");
        require(
            address(quikPlatform.nodeStorage()) == deployed.nodeStorage,
            "NodeStorage verification failed"
        );
        require(
            address(quikPlatform.userStorage()) == deployed.userStorage,
            "UserStorage verification failed"
        );
        require(
            address(quikPlatform.resourceStorage()) == deployed.resourceStorage,
            "ResourceStorage verification failed"
        );

        // STEP 9: Save deployment information to file (Optional - for reference)
        saveDeploymentInfo();

        console.log("=== Deployment to Lisk Complete! ===");

        // Stop recording transactions
        vm.stopBroadcast();
    }

    function saveDeploymentInfo() internal {
        // This would save deployment information to a JSON file
        // In a real deployment script, you might want to implement this
        // to save addresses and other details for future reference
        // Example structure (pseudo-code):
        /*
        string memory json = formatJson(
            "nodeStorage", deployed.nodeStorage,
            "userStorage", deployed.userStorage,
            "resourceStorage", deployed.resourceStorage,
            "logicImplementation", deployed.logicImplementation,
            "proxyAdmin", deployed.proxyAdmin,
            "proxy", deployed.proxy,
            "deploymentTimestamp", block.timestamp,
            "deploymentNetwork", "Lisk",
            "deploymentBlock", block.number
        );
        
        vm.writeFile("./deployments/lisk-deployment.json", json);
        console.log("Deployment information saved to ./deployments/lisk-deployment.json");
        */
    }
}
