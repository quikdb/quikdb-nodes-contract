// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import "../src/storage/NodeStorage.sol";
import "../src/storage/UserStorage.sol";
import "../src/storage/ResourceStorage.sol";
import "../src/proxy/QuikNodeLogic.sol";
import "../src/proxy/QuikUserLogic.sol";
import "../src/proxy/QuikResourceLogic.sol";
import "../src/proxy/QuikFacade.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "./DeploymentConfig.sol";

contract DeployQuikDBSplitLogicToLiskInStages is Script, DeploymentConfig {
    // Storage for contract addresses deployed in previous stages
    // These can be set manually between stages to continue deployment
    address public nodeStorageAddress;
    address public userStorageAddress;
    address public resourceStorageAddress;
    address public nodeLogicImplAddress;
    address public userLogicImplAddress;
    address public resourceLogicImplAddress;
    address public facadeImplAddress;
    address public proxyAdminAddress;
    address public nodeLogicProxyAddress;
    address public userLogicProxyAddress;
    address public resourceLogicProxyAddress;
    address public facadeProxyAddress;

    // This enum tracks which stage to execute
    enum DeploymentStage {
        DEPLOY_STORAGE,
        DEPLOY_LOGIC_IMPLS,
        DEPLOY_PROXY_ADMIN,
        DEPLOY_NODE_PROXY,
        DEPLOY_USER_PROXY,
        DEPLOY_RESOURCE_PROXY,
        DEPLOY_FACADE_PROXY,
        SETUP_STORAGE_CONTRACTS,
        SETUP_ACCESS_CONTROL
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);

        // Choose which stage to run (change this value to run different stages)
        DeploymentStage stage = DeploymentStage.DEPLOY_STORAGE;

        console.log(
            "=== QuikDB Split Logic Staged Deployment to Lisk Blockchain ==="
        );
        console.log("Deployer/Admin address:", deployerAddress);
        console.log("Running stage:", uint256(stage));

        vm.startBroadcast(deployerPrivateKey);

        if (stage == DeploymentStage.DEPLOY_STORAGE) {
            deployStorageContracts(deployerAddress);
        } else if (stage == DeploymentStage.DEPLOY_LOGIC_IMPLS) {
            deployLogicImplementations();
        } else if (stage == DeploymentStage.DEPLOY_PROXY_ADMIN) {
            deployProxyAdmin(deployerAddress);
        } else if (stage == DeploymentStage.DEPLOY_NODE_PROXY) {
            deployNodeProxy(deployerAddress);
        } else if (stage == DeploymentStage.DEPLOY_USER_PROXY) {
            deployUserProxy(deployerAddress);
        } else if (stage == DeploymentStage.DEPLOY_RESOURCE_PROXY) {
            deployResourceProxy(deployerAddress);
        } else if (stage == DeploymentStage.DEPLOY_FACADE_PROXY) {
            deployFacadeProxy(deployerAddress);
        } else if (stage == DeploymentStage.SETUP_STORAGE_CONTRACTS) {
            setupStorageContracts();
        } else if (stage == DeploymentStage.SETUP_ACCESS_CONTROL) {
            setupAccessControl(deployerAddress);
        }

        vm.stopBroadcast();
    }

    function deployStorageContracts(address deployerAddress) internal {
        console.log("Deploying Storage Contracts...");

        NodeStorage nodeStorage = new NodeStorage(deployerAddress);
        nodeStorageAddress = address(nodeStorage);
        console.log("NodeStorage deployed at:", nodeStorageAddress);

        UserStorage userStorage = new UserStorage(deployerAddress);
        userStorageAddress = address(userStorage);
        console.log("UserStorage deployed at:", userStorageAddress);

        ResourceStorage resourceStorage = new ResourceStorage(deployerAddress);
        resourceStorageAddress = address(resourceStorage);
        console.log("ResourceStorage deployed at:", resourceStorageAddress);
    }

    function deployLogicImplementations() internal {
        console.log("Deploying Logic Implementation Contracts...");

        QuikNodeLogic nodeLogicImpl = new QuikNodeLogic();
        nodeLogicImplAddress = address(nodeLogicImpl);
        console.log(
            "QuikNodeLogic implementation deployed at:",
            nodeLogicImplAddress
        );

        QuikUserLogic userLogicImpl = new QuikUserLogic();
        userLogicImplAddress = address(userLogicImpl);
        console.log(
            "QuikUserLogic implementation deployed at:",
            userLogicImplAddress
        );

        QuikResourceLogic resourceLogicImpl = new QuikResourceLogic();
        resourceLogicImplAddress = address(resourceLogicImpl);
        console.log(
            "QuikResourceLogic implementation deployed at:",
            resourceLogicImplAddress
        );

        QuikFacade facadeImpl = new QuikFacade();
        facadeImplAddress = address(facadeImpl);
        console.log(
            "QuikFacade implementation deployed at:",
            facadeImplAddress
        );
    }

    function deployProxyAdmin(address deployerAddress) internal {
        console.log("Deploying Proxy Admin...");

        ProxyAdmin proxyAdmin = new ProxyAdmin(deployerAddress);
        proxyAdminAddress = address(proxyAdmin);
        console.log("ProxyAdmin deployed at:", proxyAdminAddress);
    }

    function deployNodeProxy(address deployerAddress) internal {
        console.log("Deploying Node Logic Proxy...");

        // Set the addresses from previous deployments
        // nodeStorageAddress = 0x...; // Uncomment and set if continuing from a previous deployment
        // userStorageAddress = 0x...; // Uncomment and set if continuing from a previous deployment
        // resourceStorageAddress = 0x...; // Uncomment and set if continuing from a previous deployment
        // nodeLogicImplAddress = 0x...; // Uncomment and set if continuing from a previous deployment
        // proxyAdminAddress = 0x...; // Uncomment and set if continuing from a previous deployment

        bytes memory nodeLogicData = abi.encodeWithSelector(
            QuikNodeLogic.initialize.selector,
            nodeStorageAddress,
            userStorageAddress,
            resourceStorageAddress,
            deployerAddress
        );

        TransparentUpgradeableProxy nodeLogicProxy = new TransparentUpgradeableProxy(
                nodeLogicImplAddress,
                proxyAdminAddress,
                nodeLogicData
            );
        nodeLogicProxyAddress = address(nodeLogicProxy);
        console.log("QuikNodeLogic Proxy deployed at:", nodeLogicProxyAddress);
    }

    function deployUserProxy(address deployerAddress) internal {
        console.log("Deploying User Logic Proxy...");

        // Set the addresses from previous deployments
        // nodeStorageAddress = 0x...; // Uncomment and set if continuing from a previous deployment
        // userStorageAddress = 0x...; // Uncomment and set if continuing from a previous deployment
        // resourceStorageAddress = 0x...; // Uncomment and set if continuing from a previous deployment
        // userLogicImplAddress = 0x...; // Uncomment and set if continuing from a previous deployment
        // proxyAdminAddress = 0x...; // Uncomment and set if continuing from a previous deployment

        bytes memory userLogicData = abi.encodeWithSelector(
            QuikUserLogic.initialize.selector,
            nodeStorageAddress,
            userStorageAddress,
            resourceStorageAddress,
            deployerAddress
        );

        TransparentUpgradeableProxy userLogicProxy = new TransparentUpgradeableProxy(
                userLogicImplAddress,
                proxyAdminAddress,
                userLogicData
            );
        userLogicProxyAddress = address(userLogicProxy);
        console.log("QuikUserLogic Proxy deployed at:", userLogicProxyAddress);
    }

    function deployResourceProxy(address deployerAddress) internal {
        console.log("Deploying Resource Logic Proxy...");

        // Set the addresses from previous deployments
        // nodeStorageAddress = 0x...; // Uncomment and set if continuing from a previous deployment
        // userStorageAddress = 0x...; // Uncomment and set if continuing from a previous deployment
        // resourceStorageAddress = 0x...; // Uncomment and set if continuing from a previous deployment
        // resourceLogicImplAddress = 0x...; // Uncomment and set if continuing from a previous deployment
        // proxyAdminAddress = 0x...; // Uncomment and set if continuing from a previous deployment

        bytes memory resourceLogicData = abi.encodeWithSelector(
            QuikResourceLogic.initialize.selector,
            nodeStorageAddress,
            userStorageAddress,
            resourceStorageAddress,
            deployerAddress
        );

        TransparentUpgradeableProxy resourceLogicProxy = new TransparentUpgradeableProxy(
                resourceLogicImplAddress,
                proxyAdminAddress,
                resourceLogicData
            );
        resourceLogicProxyAddress = address(resourceLogicProxy);
        console.log(
            "QuikResourceLogic Proxy deployed at:",
            resourceLogicProxyAddress
        );
    }

    function deployFacadeProxy(address deployerAddress) internal {
        console.log("Deploying Facade Proxy...");

        // Set the addresses from previous deployments
        // nodeLogicProxyAddress = 0x...; // Uncomment and set if continuing from a previous deployment
        // userLogicProxyAddress = 0x...; // Uncomment and set if continuing from a previous deployment
        // resourceLogicProxyAddress = 0x...; // Uncomment and set if continuing from a previous deployment
        // facadeImplAddress = 0x...; // Uncomment and set if continuing from a previous deployment
        // proxyAdminAddress = 0x...; // Uncomment and set if continuing from a previous deployment

        bytes memory facadeData = abi.encodeWithSelector(
            QuikFacade.initialize.selector,
            nodeLogicProxyAddress,
            userLogicProxyAddress,
            resourceLogicProxyAddress,
            deployerAddress
        );

        TransparentUpgradeableProxy facadeProxy = new TransparentUpgradeableProxy(
                facadeImplAddress,
                proxyAdminAddress,
                facadeData
            );
        facadeProxyAddress = address(facadeProxy);
        console.log("QuikFacade Proxy deployed at:", facadeProxyAddress);
    }

    function setupStorageContracts() internal {
        console.log("Setting up storage contracts...");

        // Set the addresses from previous deployments
        // nodeStorageAddress = 0x...; // Uncomment and set if continuing from a previous deployment
        // userStorageAddress = 0x...; // Uncomment and set if continuing from a previous deployment
        // resourceStorageAddress = 0x...; // Uncomment and set if continuing from a previous deployment
        // nodeLogicProxyAddress = 0x...; // Uncomment and set if continuing from a previous deployment
        // userLogicProxyAddress = 0x...; // Uncomment and set if continuing from a previous deployment
        // resourceLogicProxyAddress = 0x...; // Uncomment and set if continuing from a previous deployment

        NodeStorage(nodeStorageAddress).setLogicContract(nodeLogicProxyAddress);
        UserStorage(userStorageAddress).setLogicContract(userLogicProxyAddress);
        ResourceStorage(resourceStorageAddress).setLogicContract(
            resourceLogicProxyAddress
        );
        console.log("Storage contracts configured to use proxies");
    }

    function setupAccessControl(address deployerAddress) internal {
        console.log("Setting up access control...");

        // Set the addresses from previous deployments
        // nodeLogicProxyAddress = 0x...; // Uncomment and set if continuing from a previous deployment
        // userLogicProxyAddress = 0x...; // Uncomment and set if continuing from a previous deployment
        // facadeProxyAddress = 0x...; // Uncomment and set if continuing from a previous deployment

        QuikNodeLogic nodeLogic = QuikNodeLogic(nodeLogicProxyAddress);
        nodeLogic.grantRole(
            nodeLogic.NODE_OPERATOR_ROLE(),
            NODE_OPERATOR_ADDRESS
        );
        console.log("NODE_OPERATOR_ROLE granted to:", NODE_OPERATOR_ADDRESS);

        QuikUserLogic userLogic = QuikUserLogic(userLogicProxyAddress);
        userLogic.grantRole(userLogic.AUTH_SERVICE_ROLE(), deployerAddress);
        console.log("AUTH_SERVICE_ROLE granted to admin:", deployerAddress);

        QuikFacade facade = QuikFacade(facadeProxyAddress);
        facade.grantRole(facade.UPGRADER_ROLE(), UPGRADER_ADDRESS);
        console.log("UPGRADER_ROLE granted to:", UPGRADER_ADDRESS);

        console.log("Access control setup complete!");
    }
}
