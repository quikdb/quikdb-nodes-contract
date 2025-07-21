// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import "../src/proxy/NodeLogic.sol";
import "../src/proxy/UserLogic.sol";
import "../src/proxy/ResourceLogic.sol";
import "../src/proxy/PerformanceLogic.sol";
import "../src/proxy/ClusterLogic.sol";
import "../src/proxy/RewardsLogic.sol";
import "../src/proxy/ApplicationLogic.sol";
import "../src/proxy/StorageAllocatorLogic.sol";
import "../src/proxy/Facade.sol";
import "../src/storage/NodeStorage.sol";
import "../src/storage/UserStorage.sol";
import "../src/storage/ResourceStorage.sol";
import "../src/storage/PerformanceStorage.sol";
import "../src/storage/ClusterStorage.sol";
import "../src/storage/RewardsStorage.sol";
import "../src/storage/ApplicationStorage.sol";
import "../src/storage/StorageAllocatorStorage.sol";
import "../src/storage/DeploymentStorage.sol";
import "../src/storage/LogAccessStorage.sol";
import "../src/tokens/QuiksToken.sol";
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
    address internal performanceRecorder = address(0x5);
    address internal clusterManager = address(0x6);
    address internal rewardsCalculator = address(0x7);
    address internal applicationDeployer = address(0x8);
    address internal storageAllocator = address(0x9);

    // Storage contracts
    NodeStorage internal nodeStorage;
    UserStorage internal userStorage;
    ResourceStorage internal resourceStorage;
    PerformanceStorage internal performanceStorage;
    ClusterStorage internal clusterStorage;
    RewardsStorage internal rewardsStorage;
    ApplicationStorage internal applicationStorage;
    StorageAllocatorStorage internal storageAllocatorStorage;
    DeploymentStorage internal deploymentStorage;
    LogAccessStorage internal logAccessStorage;

    // Logic implementation contracts
    NodeLogic internal nodeLogicImpl;
    UserLogic internal userLogicImpl;
    ResourceLogic internal resourceLogicImpl;
    PerformanceLogic internal performanceLogicImpl;
    ClusterLogic internal clusterLogicImpl;
    RewardsLogic internal rewardsLogicImpl;
    ApplicationLogic internal applicationLogicImpl;
    StorageAllocatorLogic internal storageAllocatorLogicImpl;
    Facade internal facadeImpl;

    // Proxy contracts
    TransparentUpgradeableProxy internal nodeLogicProxy;
    TransparentUpgradeableProxy internal userLogicProxy;
    TransparentUpgradeableProxy internal resourceLogicProxy;
    TransparentUpgradeableProxy internal performanceLogicProxy;
    TransparentUpgradeableProxy internal clusterLogicProxy;
    TransparentUpgradeableProxy internal rewardsLogicProxy;
    TransparentUpgradeableProxy internal applicationLogicProxy;
    TransparentUpgradeableProxy internal storageAllocatorLogicProxy;
    TransparentUpgradeableProxy internal facadeProxy;

    // Proxy admin
    ProxyAdmin internal proxyAdmin;

    // Token contracts
    QuiksToken internal quiksToken;

    // Proxied contracts
    NodeLogic internal nodeLogic;
    UserLogic internal userLogic;
    // ResourceLogic internal resourceLogic; // Moved to ResourceLogic.t.sol
    PerformanceLogic internal performanceLogic;
    ClusterLogic internal clusterLogic;
    RewardsLogic internal rewardsLogic;
    ApplicationLogic internal applicationLogic;
    StorageAllocatorLogic internal storageAllocatorLogic;
    Facade internal facade;

    function setUp() public virtual {
        _deployStorageContracts();
        _deployTokenContracts();
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
        performanceStorage = new PerformanceStorage(admin);
        clusterStorage = new ClusterStorage(admin);
        rewardsStorage = new RewardsStorage(admin);
        applicationStorage = new ApplicationStorage();
        storageAllocatorStorage = new StorageAllocatorStorage(admin);
        deploymentStorage = new DeploymentStorage(admin);
        logAccessStorage = new LogAccessStorage();
        vm.stopPrank();
    }

    function _deployTokenContracts() internal {
        vm.startPrank(admin);
        // Deploy QUIKS token with initial supply for testing
        uint256 initialSupply = 1000000 * 1e18; // 1 million QUIKS tokens
        quiksToken = new QuiksToken(
            initialSupply,
            admin,          // admin role
            admin           // minter role (will be updated to rewardsLogic later)
        );
        console.log("QUIKS Token deployed at:", address(quiksToken));
        console.log("Initial supply:", initialSupply / 1e18, "QUIKS tokens");
        vm.stopPrank();
    }

    function _deployImplementationContracts() internal {
        vm.startPrank(admin);
        nodeLogicImpl = new NodeLogic();
        userLogicImpl = new UserLogic();
        resourceLogicImpl = new ResourceLogic();
        performanceLogicImpl = new PerformanceLogic();
        clusterLogicImpl = new ClusterLogic();
        rewardsLogicImpl = new RewardsLogic();
        applicationLogicImpl = new ApplicationLogic();
        storageAllocatorLogicImpl = new StorageAllocatorLogic();
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

        performanceLogicProxy = new TransparentUpgradeableProxy(
            address(performanceLogicImpl),
            address(proxyAdmin),
            abi.encodeWithSelector(
                PerformanceLogic.initialize.selector,
                address(nodeStorage),
                address(userStorage),
                address(resourceStorage),
                admin
            )
        );

        clusterLogicProxy = new TransparentUpgradeableProxy(
            address(clusterLogicImpl),
            address(proxyAdmin),
            abi.encodeWithSelector(
                ClusterLogic.initialize.selector,
                address(nodeStorage),
                address(userStorage),
                address(resourceStorage),
                admin
            )
        );

        rewardsLogicProxy = new TransparentUpgradeableProxy(
            address(rewardsLogicImpl),
            address(proxyAdmin),
            abi.encodeWithSelector(
                RewardsLogic.initialize.selector,
                address(rewardsStorage),
                address(nodeStorage),
                address(userStorage),
                address(resourceStorage),
                address(quiksToken) // Use QUIKS token for rewards
            )
        );

        applicationLogicProxy = new TransparentUpgradeableProxy(
            address(applicationLogicImpl),
            address(proxyAdmin),
            abi.encodeWithSelector(
                ApplicationLogic.initialize.selector,
                address(applicationStorage),
                address(nodeStorage),
                address(userStorage),
                address(resourceStorage)
            )
        );

        storageAllocatorLogicProxy = new TransparentUpgradeableProxy(
            address(storageAllocatorLogicImpl),
            address(proxyAdmin),
            abi.encodeWithSelector(
                StorageAllocatorLogic.initialize.selector,
                address(storageAllocatorStorage),
                address(nodeStorage),
                address(userStorage),
                address(resourceStorage)
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
        // resourceLogic = ResourceLogic(payable(address(resourceLogicProxy))); // Moved to ResourceLogic.t.sol
        performanceLogic = PerformanceLogic(payable(address(performanceLogicProxy)));
        clusterLogic = ClusterLogic(payable(address(clusterLogicProxy)));
        rewardsLogic = RewardsLogic(payable(address(rewardsLogicProxy)));
        applicationLogic = ApplicationLogic(payable(address(applicationLogicProxy)));
        storageAllocatorLogic = StorageAllocatorLogic(payable(address(storageAllocatorLogicProxy)));
        facade = Facade(payable(address(facadeProxy)));

        // Set up storage contracts to use the proxies
        nodeStorage.setLogicContract(address(nodeLogicProxy));
        userStorage.setLogicContract(address(userLogicProxy));
        resourceStorage.setLogicContract(address(resourceLogicProxy));
        performanceStorage.setLogicContract(address(performanceLogicProxy));
        clusterStorage.setLogicContract(address(clusterLogicProxy));
        rewardsStorage.setLogicContract(address(rewardsLogicProxy));
        applicationStorage.setLogicContract(address(applicationLogicProxy));
        deploymentStorage.setLogicContract(address(applicationLogicProxy));

        // Set performance storage in the logic contract
        performanceLogic.setPerformanceStorage(address(performanceStorage));

        // Set cluster storage in the logic contract
        clusterLogic.setClusterStorage(address(clusterStorage));
        
        // Configure DeploymentStorage with UserStorage reference
        deploymentStorage.setUserStorage(address(userStorage));

        vm.stopPrank();
    }

    function _setupRoles() internal {
        vm.startPrank(admin);
        nodeLogic.grantRole(nodeLogic.NODE_OPERATOR_ROLE(), nodeOperator);
        userLogic.grantRole(userLogic.AUTH_SERVICE_ROLE(), authService);
        performanceLogic.grantRole(performanceLogic.PERFORMANCE_RECORDER_ROLE(), performanceRecorder);
        clusterLogic.grantRole(clusterLogic.CLUSTER_MANAGER_ROLE(), clusterManager);
        rewardsLogic.grantRole(rewardsLogic.REWARDS_CALCULATOR_ROLE(), rewardsCalculator);
        rewardsLogic.grantRole(rewardsLogic.REWARDS_DISTRIBUTOR_ROLE(), rewardsCalculator);
        applicationLogic.grantRole(applicationLogic.APPLICATION_DEPLOYER_ROLE(), applicationDeployer);
        applicationLogic.grantRole(applicationLogic.APPLICATION_MANAGER_ROLE(), applicationDeployer);
        storageAllocatorLogic.grantRole(storageAllocatorLogic.STORAGE_ALLOCATOR_ROLE(), storageAllocator);
        storageAllocatorLogic.grantRole(storageAllocatorLogic.STORAGE_MANAGER_ROLE(), storageAllocator);
        
        // Grant LOGIC_ROLE to applicationLogic for LogAccessStorage
        logAccessStorage.grantRole(logAccessStorage.LOGIC_ROLE(), address(applicationLogicProxy));
        
        // Grant LOGIC_ROLE to admin (deployer) for DeploymentStorage and LogAccessStorage  
        bytes32 deploymentLogicRole = deploymentStorage.LOGIC_ROLE();
        bytes32 logAccessLogicRole = logAccessStorage.LOGIC_ROLE();
        bytes32 rewardsLogicRole = rewardsStorage.LOGIC_ROLE();
        deploymentStorage.grantRole(deploymentLogicRole, admin);
        logAccessStorage.grantRole(logAccessLogicRole, admin);
        rewardsStorage.grantRole(rewardsLogicRole, admin);
        
        // Grant MINTER_ROLE to RewardsLogic for QUIKS token
        quiksToken.grantRole(quiksToken.MINTER_ROLE(), address(rewardsLogicProxy));
        console.log("Granted MINTER_ROLE to RewardsLogic for QUIKS token");
        
        // Check if QUIKS token is properly set in RewardsLogic
        console.log("Checking QUIKS token integration...");
        try rewardsLogic.quiksToken() returns (QuiksToken token) {
            if (address(token) != address(0)) {
                console.log("RewardsLogic has QUIKS token set at:", address(token));
            } else {
                console.log("RewardsLogic QUIKS token is address(0)");
            }
        } catch {
            console.log("Failed to query QUIKS token from RewardsLogic");
        }
        
        vm.stopPrank();
    }

    // =============================================================
    //                     TEST HELPERS
    // =============================================================

    function _registerTestNode(string memory nodeId) internal {
        vm.startPrank(nodeOperator);
        nodeLogic.registerNode(nodeId, nodeOperator, NodeStorage.NodeTier.STANDARD, NodeStorage.ProviderType.COMPUTE);
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
