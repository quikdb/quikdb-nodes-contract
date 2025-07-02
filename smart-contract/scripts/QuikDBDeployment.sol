// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import "../src/storage/NodeStorage.sol";
import "../src/storage/UserStorage.sol";
import "../src/storage/ResourceStorage.sol";
import "../src/proxy/NodeLogic.sol";
import "../src/proxy/UserLogic.sol";
import "../src/proxy/ResourceLogic.sol";
import "../src/proxy/Facade.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

/**
 * @title QuikDBDeployment
 * @notice Direct deployment of all QuikDB contracts
 */
contract QuikDBDeployment is Script {
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("=== QUIKDB DEPLOYMENT STARTED ===");
        console.log("Deployer address:", deployer);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // 1. Deploy storage contracts
        console.log("=== DEPLOYING STORAGE CONTRACTS ===");
        NodeStorage nodeStorage = new NodeStorage(deployer);
        UserStorage userStorage = new UserStorage(deployer);
        ResourceStorage resourceStorage = new ResourceStorage(deployer);
        
        console.log("NodeStorage deployed at:", address(nodeStorage));
        console.log("UserStorage deployed at:", address(userStorage));
        console.log("ResourceStorage deployed at:", address(resourceStorage));
        
        // 2. Deploy logic implementation contracts
        console.log("=== DEPLOYING LOGIC IMPLEMENTATIONS ===");
        NodeLogic nodeLogicImpl = new NodeLogic();
        UserLogic userLogicImpl = new UserLogic();
        ResourceLogic resourceLogicImpl = new ResourceLogic();
        Facade facadeImpl = new Facade();
        
        console.log("NodeLogic Implementation deployed at:", address(nodeLogicImpl));
        console.log("UserLogic Implementation deployed at:", address(userLogicImpl));
        console.log("ResourceLogic Implementation deployed at:", address(resourceLogicImpl));
        console.log("Facade Implementation deployed at:", address(facadeImpl));
        
        // 3. Deploy ProxyAdmin
        console.log("=== DEPLOYING PROXY ADMIN ===");
        ProxyAdmin proxyAdmin = new ProxyAdmin(deployer);
        console.log("ProxyAdmin deployed at:", address(proxyAdmin));
        
        // 4. Deploy proxy contracts
        console.log("=== DEPLOYING PROXY CONTRACTS ===");
        
        // Initialize data for logic contracts
        bytes memory nodeLogicInitData = abi.encodeWithSelector(
            NodeLogic.initialize.selector,
            address(nodeStorage),
            address(userStorage),
            address(resourceStorage),
            deployer
        );
        
        bytes memory userLogicInitData = abi.encodeWithSelector(
            UserLogic.initialize.selector,
            address(nodeStorage),
            address(userStorage),
            address(resourceStorage),
            deployer
        );
        
        bytes memory resourceLogicInitData = abi.encodeWithSelector(
            ResourceLogic.initialize.selector,
            address(nodeStorage),
            address(userStorage),
            address(resourceStorage),
            deployer
        );
        
        // Deploy proxies
        TransparentUpgradeableProxy nodeLogicProxy = new TransparentUpgradeableProxy(
            address(nodeLogicImpl),
            address(proxyAdmin),
            nodeLogicInitData
        );
        
        TransparentUpgradeableProxy userLogicProxy = new TransparentUpgradeableProxy(
            address(userLogicImpl),
            address(proxyAdmin),
            userLogicInitData
        );
        
        TransparentUpgradeableProxy resourceLogicProxy = new TransparentUpgradeableProxy(
            address(resourceLogicImpl),
            address(proxyAdmin),
            resourceLogicInitData
        );
        
        // Initialize facade with logic contract addresses
        bytes memory facadeInitData = abi.encodeWithSelector(
            Facade.initialize.selector,
            address(nodeLogicProxy),
            address(userLogicProxy),
            address(resourceLogicProxy),
            deployer
        );
        
        TransparentUpgradeableProxy facadeProxy = new TransparentUpgradeableProxy(
            address(facadeImpl),
            address(proxyAdmin),
            facadeInitData
        );
        
        console.log("NodeLogic Proxy deployed at:", address(nodeLogicProxy));
        console.log("UserLogic Proxy deployed at:", address(userLogicProxy));
        console.log("ResourceLogic Proxy deployed at:", address(resourceLogicProxy));
        console.log("Facade Proxy deployed at:", address(facadeProxy));
        
        // 5. Configure storage contracts to accept logic contracts
        console.log("=== CONFIGURING STORAGE CONTRACTS ===");
        nodeStorage.setLogicContract(address(nodeLogicProxy));
        userStorage.setLogicContract(address(userLogicProxy));
        resourceStorage.setLogicContract(address(resourceLogicProxy));
        
        console.log("Storage contracts configured");
        
        // 6. Grant necessary roles for testing
        console.log("=== SETTING UP ROLES ===");
        
        // Grant NODE_OPERATOR_ROLE to deployer for testing
        bytes32 NODE_OPERATOR_ROLE = keccak256("NODE_OPERATOR_ROLE");
        NodeLogic nodeLogicContract = NodeLogic(address(nodeLogicProxy));
        nodeLogicContract.grantRole(NODE_OPERATOR_ROLE, deployer);
        
        // Grant AUTH_SERVICE_ROLE to deployer for user registration  
        bytes32 AUTH_SERVICE_ROLE = keccak256("AUTH_SERVICE_ROLE");
        UserLogic userLogicContract = UserLogic(address(userLogicProxy));
        userLogicContract.grantRole(AUTH_SERVICE_ROLE, deployer);
        
        console.log("Roles configured for testing");
        
        vm.stopBroadcast();
        
        console.log("=== DEPLOYMENT SUMMARY ===");
        console.log("Storage Contracts:");
        console.log("  NodeStorage:", address(nodeStorage));
        console.log("  UserStorage:", address(userStorage));
        console.log("  ResourceStorage:", address(resourceStorage));
        console.log("");
        console.log("Implementation Contracts:");
        console.log("  NodeLogic:", address(nodeLogicImpl));
        console.log("  UserLogic:", address(userLogicImpl));
        console.log("  ResourceLogic:", address(resourceLogicImpl));
        console.log("  Facade:", address(facadeImpl));
        console.log("");
        console.log("Proxy Contracts:");
        console.log("  ProxyAdmin:", address(proxyAdmin));
        console.log("  NodeLogic:", address(nodeLogicProxy));
        console.log("  UserLogic:", address(userLogicProxy));
        console.log("  ResourceLogic:", address(resourceLogicProxy));
        console.log("  Facade:", address(facadeProxy));
        
        console.log("=== QUIKDB DEPLOYMENT COMPLETED ===");
    }
}
