// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import "../src/storage/NodeStorage.sol";
import "../src/storage/UserStorage.sol";
import "../src/storage/ResourceStorage.sol";
import "../src/storage/RewardsStorage.sol";
import "../src/storage/ApplicationStorage.sol";
import "../src/storage/StorageAllocatorStorage.sol";
import "../src/storage/ClusterStorage.sol";
import "../src/storage/PerformanceStorage.sol";
import "../src/proxy/NodeLogic.sol";
import "../src/proxy/UserLogic.sol";
import "../src/proxy/ResourceLogic.sol";
import "../src/proxy/RewardsLogic.sol";
import "../src/proxy/ApplicationLogic.sol";
import "../src/proxy/StorageAllocatorLogic.sol";
import "../src/proxy/ClusterLogic.sol";
import "../src/proxy/ClusterManager.sol";
import "../src/proxy/ClusterBatchProcessor.sol";
import "../src/proxy/ClusterNodeAssignment.sol";
import "../src/proxy/ClusterAnalytics.sol";
import "../src/proxy/RewardsBatchProcessor.sol";
import "../src/proxy/RewardsSlashingProcessor.sol";
import "../src/proxy/RewardsQueryHelper.sol";
import "../src/proxy/RewardsAdmin.sol";
import "../src/proxy/PerformanceLogic.sol";
import "../src/proxy/Facade.sol";
import "../src/tokens/QuiksToken.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

/**
 * @title QuikDBDeployment
 * @notice CREATE2 deterministic deployment of all QuikDB contracts
 * @dev Uses CREATE2 for predictable addresses across networks
 */
contract QuikDBDeployment is Script {
    // CREATE2 salt for deterministic addresses - Updated for modular architecture
    bytes32 public constant SALT = keccak256("QuikDB.v9.2025.CREATE2.MODULAR.Jan22");

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("=== QUIKDB CREATE2 DEPLOYMENT STARTED ===");
        console.log("Deployer address:", deployer);
        console.log("CREATE2 Salt:", vm.toString(SALT));

        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy storage contracts using CREATE2
        console.log("=== DEPLOYING STORAGE CONTRACTS (CREATE2) ===");
        NodeStorage nodeStorage = new NodeStorage{salt: SALT}(deployer);
        UserStorage userStorage = new UserStorage{salt: SALT}(deployer);
        ResourceStorage resourceStorage = new ResourceStorage{salt: SALT}(deployer);
        RewardsStorage rewardsStorage = new RewardsStorage{salt: SALT}(deployer);
        ApplicationStorage applicationStorage = new ApplicationStorage{salt: SALT}();
        StorageAllocatorStorage storageAllocatorStorage = new StorageAllocatorStorage{salt: SALT}(deployer);
        ClusterStorage clusterStorage = new ClusterStorage{salt: SALT}(deployer);
        PerformanceStorage performanceStorage = new PerformanceStorage{salt: SALT}(deployer);

        console.log("NodeStorage deployed at:", address(nodeStorage));
        console.log("UserStorage deployed at:", address(userStorage));
        console.log("ResourceStorage deployed at:", address(resourceStorage));
        console.log("RewardsStorage deployed at:", address(rewardsStorage));
        console.log("ApplicationStorage deployed at:", address(applicationStorage));
        console.log("StorageAllocatorStorage deployed at:", address(storageAllocatorStorage));
        console.log("ClusterStorage deployed at:", address(clusterStorage));
        console.log("PerformanceStorage deployed at:", address(performanceStorage));

        // 2. Deploy QUIKS token using CREATE2
        console.log("=== DEPLOYING QUIKS TOKEN (CREATE2) ===");
        uint256 initialSupply = 1000000 * 1e18; // 1 million QUIKS tokens
        QuiksToken quiksToken = new QuiksToken{salt: SALT}(
            initialSupply,
            deployer,     // admin role
            deployer      // initial minter role (will be updated to rewardsLogic later)
        );
        console.log("QUIKS Token deployed at:", address(quiksToken));
        console.log("Initial supply:", initialSupply / 1e18, "QUIKS tokens");

        // 3. Deploy logic implementation contracts using CREATE2
        console.log("=== DEPLOYING LOGIC IMPLEMENTATIONS (CREATE2) ===");
        NodeLogic nodeLogicImpl = new NodeLogic{salt: SALT}();
        UserLogic userLogicImpl = new UserLogic{salt: SALT}();
        ResourceLogic resourceLogicImpl = new ResourceLogic{salt: SALT}();
        RewardsLogic rewardsLogicImpl = new RewardsLogic{salt: SALT}();
        ApplicationLogic applicationLogicImpl = new ApplicationLogic{salt: SALT}();
        StorageAllocatorLogic storageAllocatorLogicImpl = new StorageAllocatorLogic{salt: SALT}();
        ClusterLogic clusterLogicImpl = new ClusterLogic{salt: SALT}();
        PerformanceLogic performanceLogicImpl = new PerformanceLogic{salt: SALT}();
        Facade facadeImpl = new Facade{salt: SALT}();

        console.log("NodeLogic Implementation deployed at:", address(nodeLogicImpl));
        console.log("UserLogic Implementation deployed at:", address(userLogicImpl));
        console.log("ResourceLogic Implementation deployed at:", address(resourceLogicImpl));
        console.log("RewardsLogic Implementation deployed at:", address(rewardsLogicImpl));
        console.log("ApplicationLogic Implementation deployed at:", address(applicationLogicImpl));
        console.log("StorageAllocatorLogic Implementation deployed at:", address(storageAllocatorLogicImpl));
        console.log("ClusterLogic Implementation deployed at:", address(clusterLogicImpl));
        console.log("PerformanceLogic Implementation deployed at:", address(performanceLogicImpl));
        console.log("Facade Implementation deployed at:", address(facadeImpl));

        // 4. Deploy extracted/modular contracts using CREATE2
        console.log("=== DEPLOYING EXTRACTED CONTRACTS (CREATE2) ===");
        ClusterManager clusterManagerImpl = new ClusterManager{salt: SALT}();
        ClusterBatchProcessor clusterBatchProcessorImpl = new ClusterBatchProcessor{salt: SALT}();
        ClusterNodeAssignment clusterNodeAssignmentImpl = new ClusterNodeAssignment{salt: SALT}();
        ClusterAnalytics clusterAnalyticsImpl = new ClusterAnalytics{salt: SALT}();
        RewardsBatchProcessor rewardsBatchProcessorImpl = new RewardsBatchProcessor{salt: SALT}();
        RewardsSlashingProcessor rewardsSlashingProcessorImpl = new RewardsSlashingProcessor{salt: SALT}();
        RewardsQueryHelper rewardsQueryHelperImpl = new RewardsQueryHelper{salt: SALT}();
        RewardsAdmin rewardsAdminImpl = new RewardsAdmin{salt: SALT}();

        console.log("ClusterManager deployed at:", address(clusterManagerImpl));
        console.log("ClusterBatchProcessor deployed at:", address(clusterBatchProcessorImpl));
        console.log("ClusterNodeAssignment deployed at:", address(clusterNodeAssignmentImpl));
        console.log("ClusterAnalytics deployed at:", address(clusterAnalyticsImpl));
        console.log("RewardsBatchProcessor deployed at:", address(rewardsBatchProcessorImpl));
        console.log("RewardsSlashingProcessor deployed at:", address(rewardsSlashingProcessorImpl));
        console.log("RewardsQueryHelper deployed at:", address(rewardsQueryHelperImpl));
        console.log("RewardsAdmin deployed at:", address(rewardsAdminImpl));

        // 5. Deploy ProxyAdmin using CREATE2
        console.log("=== DEPLOYING PROXY ADMIN (CREATE2) ===");
        ProxyAdmin proxyAdmin = new ProxyAdmin{salt: SALT}(deployer);
        console.log("ProxyAdmin deployed at:", address(proxyAdmin));

        // 6. Deploy proxy contracts using CREATE2
        console.log("=== DEPLOYING PROXY CONTRACTS (CREATE2) ===");

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

        bytes memory rewardsLogicInitData = abi.encodeWithSelector(
            RewardsLogic.initialize.selector,
            address(rewardsStorage),
            address(nodeStorage),
            address(userStorage),
            address(resourceStorage),
            address(quiksToken),
            deployer
        );

        bytes memory applicationLogicInitData = abi.encodeWithSelector(
            ApplicationLogic.initialize.selector,
            address(applicationStorage),
            address(nodeStorage),
            address(userStorage),
            address(resourceStorage)
        );

        bytes memory storageAllocatorLogicInitData = abi.encodeWithSelector(
            StorageAllocatorLogic.initialize.selector,
            address(storageAllocatorStorage),
            address(nodeStorage),
            address(userStorage),
            address(resourceStorage)
        );

        bytes memory clusterLogicInitData = abi.encodeWithSelector(
            ClusterLogic.initialize.selector,
            address(nodeStorage),
            address(userStorage),
            address(resourceStorage),
            deployer
        );

        bytes memory performanceLogicInitData = abi.encodeWithSelector(
            PerformanceLogic.initialize.selector,
            address(nodeStorage),
            address(userStorage),
            address(resourceStorage),
            deployer
        );

        // Deploy proxies using CREATE2 with different salts for each
        TransparentUpgradeableProxy nodeLogicProxy = new TransparentUpgradeableProxy{
            salt: keccak256(abi.encodePacked(SALT, "NodeLogicProxy"))
        }(address(nodeLogicImpl), deployer, nodeLogicInitData);

        TransparentUpgradeableProxy userLogicProxy = new TransparentUpgradeableProxy{
            salt: keccak256(abi.encodePacked(SALT, "UserLogicProxy"))
        }(address(userLogicImpl), deployer, userLogicInitData);

        TransparentUpgradeableProxy resourceLogicProxy = new TransparentUpgradeableProxy{
            salt: keccak256(abi.encodePacked(SALT, "ResourceLogicProxy"))
        }(address(resourceLogicImpl), deployer, resourceLogicInitData);

        TransparentUpgradeableProxy rewardsLogicProxy = new TransparentUpgradeableProxy{
            salt: keccak256(abi.encodePacked(SALT, "RewardsLogicProxy"))
        }(address(rewardsLogicImpl), deployer, rewardsLogicInitData);

        TransparentUpgradeableProxy applicationLogicProxy = new TransparentUpgradeableProxy{
            salt: keccak256(abi.encodePacked(SALT, "ApplicationLogicProxy"))
        }(address(applicationLogicImpl), deployer, applicationLogicInitData);

        TransparentUpgradeableProxy storageAllocatorLogicProxy = new TransparentUpgradeableProxy{
            salt: keccak256(abi.encodePacked(SALT, "StorageAllocatorLogicProxy"))
        }(address(storageAllocatorLogicImpl), deployer, storageAllocatorLogicInitData);

        TransparentUpgradeableProxy clusterLogicProxy = new TransparentUpgradeableProxy{
            salt: keccak256(abi.encodePacked(SALT, "ClusterLogicProxy"))
        }(address(clusterLogicImpl), deployer, clusterLogicInitData);

        TransparentUpgradeableProxy performanceLogicProxy = new TransparentUpgradeableProxy{
            salt: keccak256(abi.encodePacked(SALT, "PerformanceLogicProxy"))
        }(address(performanceLogicImpl), deployer, performanceLogicInitData);

        // Initialize facade with logic contract addresses
        bytes memory facadeInitData = abi.encodeWithSelector(
            Facade.initialize.selector,
            address(nodeLogicProxy),
            address(userLogicProxy),
            address(resourceLogicProxy),
            deployer
        );

        TransparentUpgradeableProxy facadeProxy = new TransparentUpgradeableProxy{
            salt: keccak256(abi.encodePacked(SALT, "FacadeProxy"))
        }(address(facadeImpl), deployer, facadeInitData);

        console.log("NodeLogic Proxy deployed at:", address(nodeLogicProxy));
        console.log("UserLogic Proxy deployed at:", address(userLogicProxy));
        console.log("ResourceLogic Proxy deployed at:", address(resourceLogicProxy));
        console.log("RewardsLogic Proxy deployed at:", address(rewardsLogicProxy));
        console.log("ApplicationLogic Proxy deployed at:", address(applicationLogicProxy));
        console.log("StorageAllocatorLogic Proxy deployed at:", address(storageAllocatorLogicProxy));
        console.log("ClusterLogic Proxy deployed at:", address(clusterLogicProxy));
        console.log("PerformanceLogic Proxy deployed at:", address(performanceLogicProxy));
        console.log("Facade Proxy deployed at:", address(facadeProxy));

        // 7. Initialize extracted contracts
        console.log("=== INITIALIZING EXTRACTED CONTRACTS ===");
        
        // Initialize ClusterLogic extracted contracts - using correct parameter counts
        clusterManagerImpl.initialize(
            address(clusterStorage),
            address(nodeStorage), 
            address(userStorage),
            address(resourceStorage)
        );
        clusterBatchProcessorImpl.initialize(
            address(nodeStorage),
            address(userStorage),
            address(resourceStorage),
            deployer
        );
        clusterNodeAssignmentImpl.initialize(
            address(nodeStorage),
            address(userStorage),
            address(resourceStorage),
            deployer
        );
        clusterAnalyticsImpl.initialize(
            address(nodeStorage),
            address(userStorage),
            address(resourceStorage),
            deployer
        );
        
        // Initialize RewardsLogic extracted contracts - using correct parameter counts
        rewardsBatchProcessorImpl.initialize(
            address(rewardsStorage),
            address(nodeStorage),
            address(userStorage),
            address(resourceStorage),
            deployer
        );
        rewardsSlashingProcessorImpl.initialize(
            address(rewardsStorage),
            address(nodeStorage),
            address(userStorage)
        );
        rewardsQueryHelperImpl.initialize(
            address(rewardsStorage)
        );
        rewardsAdminImpl.initialize(
            address(nodeStorage),
            address(userStorage), 
            address(resourceStorage),
            deployer,
            address(rewardsStorage),
            address(rewardsLogicProxy),
            address(quiksToken)
        );
        
        console.log("Extracted contracts initialized");

        // 8. Connect extracted contracts to main logic contracts
        console.log("=== CONNECTING EXTRACTED CONTRACTS ===");
        
        ClusterLogic clusterLogicContract = ClusterLogic(payable(address(clusterLogicProxy)));
        
        // Deployer should already have DEFAULT_ADMIN_ROLE from initialization
        // Set up cluster logic connections
        clusterLogicContract.setClusterManager(address(clusterManagerImpl));
        clusterLogicContract.setClusterBatchProcessor(address(clusterBatchProcessorImpl));
        clusterLogicContract.setClusterNodeAssignment(address(clusterNodeAssignmentImpl));
        // Note: ClusterAnalytics doesn't have a setter in ClusterLogic yet, may need to add it
        
        // Set up rewards logic connections
        RewardsLogic rewardsLogicContract = RewardsLogic(payable(address(rewardsLogicProxy)));
        
        // Deployer should already have DEFAULT_ADMIN_ROLE from initialization
        rewardsLogicContract.setAdminContract(address(rewardsAdminImpl));        // Use RewardsAdmin to set up the other processors
        rewardsAdminImpl.setBatchProcessor(address(rewardsBatchProcessorImpl));
        rewardsAdminImpl.setSlashingProcessor(address(rewardsSlashingProcessorImpl));
        rewardsAdminImpl.setQueryHelper(address(rewardsQueryHelperImpl));
        
        console.log("Main logic contracts configured with extracted contracts");

        // 9. Configure storage contracts to accept logic contracts
        console.log("=== CONFIGURING STORAGE CONTRACTS ===");
        nodeStorage.setLogicContract(address(nodeLogicProxy));
        userStorage.setLogicContract(address(userLogicProxy));
        resourceStorage.setLogicContract(address(resourceLogicProxy));

        // Configure new storage contracts
        clusterLogicContract.setClusterStorage(address(clusterStorage));

        PerformanceLogic performanceLogicContract = PerformanceLogic(payable(address(performanceLogicProxy)));
        performanceLogicContract.setPerformanceStorage(address(performanceStorage));

        // Grant LOGIC_ROLE to extracted contracts for storage access
        bytes32 clusterLogicRole = clusterStorage.LOGIC_ROLE();
        bytes32 rewardsLogicRole = rewardsStorage.LOGIC_ROLE();
        
        // ClusterLogic extracted contracts
        clusterStorage.grantRole(clusterLogicRole, address(clusterManagerImpl));
        clusterStorage.grantRole(clusterLogicRole, address(clusterBatchProcessorImpl));
        clusterStorage.grantRole(clusterLogicRole, address(clusterNodeAssignmentImpl));
        clusterStorage.grantRole(clusterLogicRole, address(clusterAnalyticsImpl));
        
        // RewardsLogic extracted contracts  
        rewardsStorage.grantRole(rewardsLogicRole, address(rewardsBatchProcessorImpl));
        rewardsStorage.grantRole(rewardsLogicRole, address(rewardsSlashingProcessorImpl));
        rewardsStorage.grantRole(rewardsLogicRole, address(rewardsQueryHelperImpl));
        rewardsStorage.grantRole(rewardsLogicRole, address(rewardsAdminImpl));

        console.log("Storage contracts configured");

        // 10. Grant necessary roles for testing
        console.log("=== SETTING UP ROLES ===");

        // Grant NODE_OPERATOR_ROLE to deployer for testing
        bytes32 NODE_OPERATOR_ROLE = keccak256("NODE_OPERATOR_ROLE");
        NodeLogic nodeLogicContract = NodeLogic(payable(address(nodeLogicProxy)));
        nodeLogicContract.grantRole(NODE_OPERATOR_ROLE, deployer);

        // Grant AUTH_SERVICE_ROLE to deployer for user registration
        bytes32 AUTH_SERVICE_ROLE = keccak256("AUTH_SERVICE_ROLE");
        UserLogic userLogicContract = UserLogic(payable(address(userLogicProxy)));
        userLogicContract.grantRole(AUTH_SERVICE_ROLE, deployer);

        // Grant MINTER_ROLE to RewardsLogic for QUIKS token
        bytes32 MINTER_ROLE = keccak256("MINTER_ROLE");
        quiksToken.grantRole(MINTER_ROLE, address(rewardsLogicProxy));
        console.log("Granted MINTER_ROLE to RewardsLogic for QUIKS token");

        console.log("Roles configured for testing");

        vm.stopBroadcast();

        console.log("=== DEPLOYMENT SUMMARY ===");
        console.log("Storage Contracts:");
        console.log("  NodeStorage:", address(nodeStorage));
        console.log("  UserStorage:", address(userStorage));
        console.log("  ResourceStorage:", address(resourceStorage));
        console.log("  RewardsStorage:", address(rewardsStorage));
        console.log("  ApplicationStorage:", address(applicationStorage));
        console.log("  StorageAllocatorStorage:", address(storageAllocatorStorage));
        console.log("  ClusterStorage:", address(clusterStorage));
        console.log("  PerformanceStorage:", address(performanceStorage));
        console.log("");
        console.log("Implementation Contracts:");
        console.log("  NodeLogic:", address(nodeLogicImpl));
        console.log("  UserLogic:", address(userLogicImpl));
        console.log("  ResourceLogic:", address(resourceLogicImpl));
        console.log("  RewardsLogic:", address(rewardsLogicImpl));
        console.log("  ApplicationLogic:", address(applicationLogicImpl));
        console.log("  StorageAllocatorLogic:", address(storageAllocatorLogicImpl));
        console.log("  ClusterLogic:", address(clusterLogicImpl));
        console.log("  PerformanceLogic:", address(performanceLogicImpl));
        console.log("  Facade:", address(facadeImpl));
        console.log("");
        console.log("Extracted/Modular Contracts:");
        console.log("  ClusterManager:", address(clusterManagerImpl));
        console.log("  ClusterBatchProcessor:", address(clusterBatchProcessorImpl));
        console.log("  ClusterNodeAssignment:", address(clusterNodeAssignmentImpl));
        console.log("  ClusterAnalytics:", address(clusterAnalyticsImpl));
        console.log("  RewardsBatchProcessor:", address(rewardsBatchProcessorImpl));
        console.log("  RewardsSlashingProcessor:", address(rewardsSlashingProcessorImpl));
        console.log("  RewardsQueryHelper:", address(rewardsQueryHelperImpl));
        console.log("  RewardsAdmin:", address(rewardsAdminImpl));
        console.log("");
        console.log("Proxy Contracts:");
        console.log("  ProxyAdmin:", address(proxyAdmin));
        console.log("  NodeLogic:", address(nodeLogicProxy));
        console.log("  UserLogic:", address(userLogicProxy));
        console.log("  ResourceLogic:", address(resourceLogicProxy));
        console.log("  RewardsLogic:", address(rewardsLogicProxy));
        console.log("  ApplicationLogic:", address(applicationLogicProxy));
        console.log("  StorageAllocatorLogic:", address(storageAllocatorLogicProxy));
        console.log("  ClusterLogic:", address(clusterLogicProxy));
        console.log("  PerformanceLogic:", address(performanceLogicProxy));
        console.log("  Facade:", address(facadeProxy));

        console.log("=== QUIKDB DEPLOYMENT COMPLETED ===");
    }
}
