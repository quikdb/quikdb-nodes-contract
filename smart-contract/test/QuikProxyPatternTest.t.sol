// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import "../src/proxy/QuikNodeLogic.sol";
import "../src/proxy/QuikUserLogic.sol";
import "../src/proxy/QuikResourceLogic.sol";
import "../src/proxy/QuikFacade.sol";
import "../src/storage/NodeStorage.sol";
import "../src/storage/UserStorage.sol";
import "../src/storage/ResourceStorage.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

contract QuikSplitContractsTest is Test {
    address admin = address(0x1);
    address nodeOperator = address(0x2);
    address user = address(0x3);

    // Storage contracts
    NodeStorage nodeStorage;
    UserStorage userStorage;
    ResourceStorage resourceStorage;

    // Logic implementation contracts
    QuikNodeLogic nodeLogicImpl;
    QuikUserLogic userLogicImpl;
    QuikResourceLogic resourceLogicImpl;
    QuikFacade facadeImpl;

    // Proxy contracts
    TransparentUpgradeableProxy nodeLogicProxy;
    TransparentUpgradeableProxy userLogicProxy;
    TransparentUpgradeableProxy resourceLogicProxy;
    TransparentUpgradeableProxy facadeProxy;

    // Proxy admin
    ProxyAdmin proxyAdmin;

    // Proxied contracts
    QuikNodeLogic nodeLogic;
    QuikUserLogic userLogic;
    QuikResourceLogic resourceLogic;
    QuikFacade facade;

    function setUp() public {
        vm.startPrank(admin);

        // Deploy storage contracts
        nodeStorage = new NodeStorage(admin);
        userStorage = new UserStorage(admin);
        resourceStorage = new ResourceStorage(admin);

        // Deploy implementation contracts
        nodeLogicImpl = new QuikNodeLogic();
        userLogicImpl = new QuikUserLogic();
        resourceLogicImpl = new QuikResourceLogic();
        facadeImpl = new QuikFacade();

        // Deploy ProxyAdmin
        proxyAdmin = new ProxyAdmin(admin);

        // Initialize proxies
        nodeLogicProxy = new TransparentUpgradeableProxy(
            address(nodeLogicImpl),
            address(proxyAdmin),
            abi.encodeWithSelector(
                QuikNodeLogic.initialize.selector,
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
                QuikUserLogic.initialize.selector,
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
                QuikResourceLogic.initialize.selector,
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
                QuikFacade.initialize.selector,
                address(nodeLogicProxy),
                address(userLogicProxy),
                address(resourceLogicProxy),
                admin
            )
        );

        // Get proxied contracts
        nodeLogic = QuikNodeLogic(address(nodeLogicProxy));
        userLogic = QuikUserLogic(address(userLogicProxy));
        resourceLogic = QuikResourceLogic(address(resourceLogicProxy));
        facade = QuikFacade(address(facadeProxy));

        // Set up storage contracts to use the proxies
        nodeStorage.setLogicContract(address(nodeLogicProxy));
        userStorage.setLogicContract(address(userLogicProxy));
        resourceStorage.setLogicContract(address(resourceLogicProxy));

        // Grant roles
        nodeLogic.grantRole(nodeLogic.NODE_OPERATOR_ROLE(), nodeOperator);
        userLogic.grantRole(userLogic.AUTH_SERVICE_ROLE(), admin);

        vm.stopPrank();
    }

    function testNodeRegistration() public {
        vm.startPrank(nodeOperator);

        string memory nodeId = "test-node-1";

        nodeLogic.registerNode(
            nodeId,
            nodeOperator,
            NodeStorage.NodeTier.STANDARD,
            NodeStorage.ProviderType.COMPUTE
        );

        NodeStorage.NodeInfo memory nodeInfo = nodeLogic.getNodeInfo(nodeId);

        assertEq(nodeInfo.nodeId, nodeId);
        assertEq(nodeInfo.nodeAddress, nodeOperator);
        assertEq(uint8(nodeInfo.tier), uint8(NodeStorage.NodeTier.STANDARD));
        assertEq(
            uint8(nodeInfo.providerType),
            uint8(NodeStorage.ProviderType.COMPUTE)
        );

        vm.stopPrank();
    }

    function testUserRegistration() public {
        vm.startPrank(admin);

        bytes32 profileHash = keccak256(abi.encodePacked("user-profile-data"));

        userLogic.registerUser(
            user,
            profileHash,
            UserStorage.UserType.CONSUMER
        );

        UserStorage.UserProfile memory profile = userLogic.getUserProfile(user);

        // No need to check userAddress as it's not in the struct
        assertEq(profile.profileHash, profileHash);
        assertEq(uint8(profile.userType), uint8(UserStorage.UserType.CONSUMER));

        vm.stopPrank();
    }

    function testFacade() public {
        vm.startPrank(nodeOperator);

        string memory nodeId = "test-node-2";

        nodeLogic.registerNode(
            nodeId,
            nodeOperator,
            NodeStorage.NodeTier.PREMIUM,
            NodeStorage.ProviderType.STORAGE
        );

        vm.stopPrank();

        vm.startPrank(admin);

        bytes32 profileHash = keccak256(
            abi.encodePacked("user-profile-data-2")
        );

        userLogic.registerUser(
            user,
            profileHash,
            UserStorage.UserType.PROVIDER
        );

        vm.stopPrank();

        // Test the facade's stats function
        (
            uint256 totalNodes,
            uint256 totalUsers,
            uint256 totalAllocations
        ) = facade.getTotalStats();

        assertEq(totalNodes, 1);
        assertEq(totalUsers, 1);
        assertEq(totalAllocations, 0);
    }
}
