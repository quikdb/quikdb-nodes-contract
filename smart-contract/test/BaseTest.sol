// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import "../src/proxy/NodeLogic.sol";
import "../src/proxy/UserLogic.sol";
import "../src/proxy/ResourceLogic.sol";
import "../src/proxy/Facade.sol";
import "../src/storage/NodeStorage.sol";
import "../src/storage/UserStorage.sol";
import "../src/storage/ResourceStorage.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

/**
 * @title BaseTest
 * @notice Base test contract with common setup for all DB tests
 * @dev Inherit from this contract to get a fully deployed DB system
 */
abstract contract BaseTest is Test {
    // Test addresses
    address internal admin = address(0x1);
    address internal nodeOperator = address(0x2);
    address internal user = address(0x3);
    address internal authService = address(0x4);

    // Storage contracts
    NodeStorage internal nodeStorage;
    UserStorage internal userStorage;
    ResourceStorage internal resourceStorage;

    // Logic implementation contracts
    NodeLogic internal nodeLogicImpl;
    UserLogic internal userLogicImpl;
    ResourceLogic internal resourceLogicImpl;
    Facade internal facadeImpl;

    // Proxy contracts
    TransparentUpgradeableProxy internal nodeLogicProxy;
    TransparentUpgradeableProxy internal userLogicProxy;
    TransparentUpgradeableProxy internal resourceLogicProxy;
    TransparentUpgradeableProxy internal facadeProxy;

    // Proxy admin
    ProxyAdmin internal proxyAdmin;

    // Proxied contracts
    NodeLogic internal nodeLogic;
    UserLogic internal userLogic;
    ResourceLogic internal resourceLogic;
    Facade internal facade;

    function setUp() public virtual {
        _deployStorageContracts();
        _deployImplementationContracts();
        _deployProxyInfrastructure();
        _deployProxies();
        _configureContracts();
        _setupRoles();
    }

    // =============================================================
    //                     DEPLOYMENT HELPERS
    // =============================================================

    function _deployStorageContracts() internal {
        vm.startPrank(admin);
        nodeStorage = new NodeStorage(admin);
        userStorage = new UserStorage(admin);
        resourceStorage = new ResourceStorage(admin);
        vm.stopPrank();
    }

    function _deployImplementationContracts() internal {
        vm.startPrank(admin);
        nodeLogicImpl = new NodeLogic();
        userLogicImpl = new UserLogic();
        resourceLogicImpl = new ResourceLogic();
        facadeImpl = new Facade();
        vm.stopPrank();
    }

    function _deployProxyInfrastructure() internal {
        vm.startPrank(admin);
        proxyAdmin = new ProxyAdmin(admin);
        vm.stopPrank();
    }

    function _deployProxies() internal {
        vm.startPrank(admin);
        
        nodeLogicProxy = new TransparentUpgradeableProxy(
            address(nodeLogicImpl),
            address(proxyAdmin),
            abi.encodeWithSelector(
                NodeLogic.initialize.selector,
                address(nodeStorage),
                address(userStorage),
                address(resourceStorage),
                admin
            )
        );

        userLogicProxy = new TransparentUpgradeableProxy(
            address(userLogicImpl),
            address(proxyAdmin),
            abi.encodeWithSelector(
                UserLogic.initialize.selector,
                address(nodeStorage),
                address(userStorage),
                address(resourceStorage),
                admin
            )
        );

        resourceLogicProxy = new TransparentUpgradeableProxy(
            address(resourceLogicImpl),
            address(proxyAdmin),
            abi.encodeWithSelector(
                ResourceLogic.initialize.selector,
                address(nodeStorage),
                address(userStorage),
                address(resourceStorage),
                admin
            )
        );

        facadeProxy = new TransparentUpgradeableProxy(
            address(facadeImpl),
            address(proxyAdmin),
            abi.encodeWithSelector(
                Facade.initialize.selector,
                address(nodeLogicProxy),
                address(userLogicProxy),
                address(resourceLogicProxy),
                admin
            )
        );

        vm.stopPrank();
    }

    function _configureContracts() internal {
        vm.startPrank(admin);
        
        // Get proxied contracts
        nodeLogic = NodeLogic(payable(address(nodeLogicProxy)));
        userLogic = UserLogic(payable(address(userLogicProxy)));
        resourceLogic = ResourceLogic(payable(address(resourceLogicProxy)));
        facade = Facade(payable(address(facadeProxy)));

        // Set up storage contracts to use the proxies
        nodeStorage.setLogicContract(address(nodeLogicProxy));
        userStorage.setLogicContract(address(userLogicProxy));
        resourceStorage.setLogicContract(address(resourceLogicProxy));
        
        vm.stopPrank();
    }

    function _setupRoles() internal {
        vm.startPrank(admin);
        nodeLogic.grantRole(nodeLogic.NODE_OPERATOR_ROLE(), nodeOperator);
        userLogic.grantRole(userLogic.AUTH_SERVICE_ROLE(), authService);
        vm.stopPrank();
    }

    // =============================================================
    //                     TEST HELPERS
    // =============================================================

    function _registerTestNode(string memory nodeId) internal {
        vm.startPrank(nodeOperator);
        nodeLogic.registerNode(
            nodeId,
            nodeOperator,
            NodeStorage.NodeTier.STANDARD,
            NodeStorage.ProviderType.COMPUTE
        );
        vm.stopPrank();
    }

    function _registerTestUser(address userAddr, UserStorage.UserType userType) internal {
        vm.startPrank(authService);
        bytes32 profileHash = keccak256(abi.encodePacked("profile-", userAddr));
        userLogic.registerUser(userAddr, profileHash, userType);
        vm.stopPrank();
    }

    function _assertNodeExists(string memory nodeId, address expectedAddress) internal view {
        NodeStorage.NodeInfo memory nodeInfo = nodeLogic.getNodeInfo(nodeId);
        assertEq(nodeInfo.nodeId, nodeId);
        assertEq(nodeInfo.nodeAddress, expectedAddress);
    }

    function _assertUserExists(address userAddr, UserStorage.UserType expectedType) internal view {
        UserStorage.UserProfile memory profile = userLogic.getUserProfile(userAddr);
        assertEq(uint8(profile.userType), uint8(expectedType));
    }
}
