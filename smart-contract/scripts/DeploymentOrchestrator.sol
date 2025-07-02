// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./base/BaseDeployment.sol";
import "./stages/StorageDeployment.sol";
import "./stages/LogicDeployment.sol";
import "./stages/ProxyDeployment.sol";
import "./stages/ConfigurationSetup.sol";

/**
 * @title DeploymentOrchestrator
 * @notice Main orchestrator for the staged deployment of QuikDB system
 * @dev Coordinates all deployment stages and manages state between stages
 */
contract DeploymentOrchestrator is BaseDeployment {
    
    // =============================================================
    //                         ENUMS
    // =============================================================
    
    /// @notice Available deployment stages
    enum DeploymentStage {
        DEPLOY_STORAGE,           // Stage 1: Deploy storage contracts
        DEPLOY_LOGIC_IMPLS,       // Stage 2: Deploy logic implementations
        DEPLOY_PROXY_ADMIN,       // Stage 3: Deploy proxy admin
        DEPLOY_NODE_PROXY,        // Stage 4: Deploy node logic proxy
        DEPLOY_USER_PROXY,        // Stage 5: Deploy user logic proxy
        DEPLOY_RESOURCE_PROXY,    // Stage 6: Deploy resource logic proxy
        DEPLOY_FACADE_PROXY,      // Stage 7: Deploy facade proxy
        SETUP_STORAGE_CONTRACTS,  // Stage 8: Configure storage contracts
        SETUP_ACCESS_CONTROL,     // Stage 9: Setup access control
        VERIFY_DEPLOYMENT         // Stage 10: Verify complete deployment
    }
    
    // =============================================================
    //                         STORAGE
    // =============================================================
    
    /// @notice Deployment stage contracts
    StorageDeployment public storageDeployment;
    LogicDeployment public logicDeployment;
    ProxyDeployment public proxyDeployment;
    ConfigurationSetup public configurationSetup;
    
    /// @notice Current deployment stage
    DeploymentStage public currentStage;
    
    /// @notice Completed stages mapping
    mapping(DeploymentStage => bool) public stageCompleted;
    
    // =============================================================
    //                         EVENTS
    // =============================================================
    
    event StageExecuted(DeploymentStage stage, bool success);
    event DeploymentCompleted(address facade);
    
    // =============================================================
    //                       CONSTRUCTOR
    // =============================================================
    
    constructor() {
        currentStage = DeploymentStage.DEPLOY_STORAGE;
        
        // Deploy stage contract instances
        storageDeployment = new StorageDeployment();
        logicDeployment = new LogicDeployment();
        proxyDeployment = new ProxyDeployment();
        configurationSetup = new ConfigurationSetup();
    }
    
    // =============================================================
    //                    MAIN DEPLOYMENT
    // =============================================================
    
    /**
     * @notice Execute the complete deployment process
     * @dev Runs all stages in sequence
     */
    function deployComplete() external {
        (uint256 deployerPrivateKey, address deployerAddress) = getDeployerInfo();
        
        console.log("=== QUIKDB COMPLETE DEPLOYMENT STARTED ===");
        console.log("Deployer address:", deployerAddress);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Execute all stages in sequence
        executeStage(DeploymentStage.DEPLOY_STORAGE, deployerAddress);
        executeStage(DeploymentStage.DEPLOY_LOGIC_IMPLS, deployerAddress);
        executeStage(DeploymentStage.DEPLOY_PROXY_ADMIN, deployerAddress);
        executeStage(DeploymentStage.DEPLOY_NODE_PROXY, deployerAddress);
        executeStage(DeploymentStage.DEPLOY_USER_PROXY, deployerAddress);
        executeStage(DeploymentStage.DEPLOY_RESOURCE_PROXY, deployerAddress);
        executeStage(DeploymentStage.DEPLOY_FACADE_PROXY, deployerAddress);
        executeStage(DeploymentStage.SETUP_STORAGE_CONTRACTS, deployerAddress);
        executeStage(DeploymentStage.SETUP_ACCESS_CONTROL, deployerAddress);
        executeStage(DeploymentStage.VERIFY_DEPLOYMENT, deployerAddress);
        
        vm.stopBroadcast();
        
        console.log("=== QUIKDB COMPLETE DEPLOYMENT FINISHED ===");
        emit DeploymentCompleted(facadeProxyAddress);
    }
    
    /**
     * @notice Execute a specific deployment stage
     * @param stage The stage to execute
     */
    function deploySingleStage(DeploymentStage stage) external {
        (uint256 deployerPrivateKey, address deployerAddress) = getDeployerInfo();
        
        console.log("=== QUIKDB SINGLE STAGE DEPLOYMENT ===");
        console.log("Deployer address:", deployerAddress);
        console.log("Executing stage:", uint256(stage));
        
        vm.startBroadcast(deployerPrivateKey);
        executeStage(stage, deployerAddress);
        vm.stopBroadcast();
    }
    
    // =============================================================
    //                    STAGE EXECUTION
    // =============================================================
    
    /**
     * @notice Execute a specific deployment stage
     * @param stage The stage to execute
     * @param deployerAddress The deployer address
     */
    function executeStage(DeploymentStage stage, address deployerAddress) internal {
        console.log("Executing stage:", uint256(stage));
        
        bool success = false;
        
        if (stage == DeploymentStage.DEPLOY_STORAGE) {
            success = _deployStorage(deployerAddress);
        } else if (stage == DeploymentStage.DEPLOY_LOGIC_IMPLS) {
            success = _deployLogicImplementations();
        } else if (stage == DeploymentStage.DEPLOY_PROXY_ADMIN) {
            success = _deployProxyAdmin(deployerAddress);
        } else if (stage == DeploymentStage.DEPLOY_NODE_PROXY) {
            success = _deployNodeProxy(deployerAddress);
        } else if (stage == DeploymentStage.DEPLOY_USER_PROXY) {
            success = _deployUserProxy(deployerAddress);
        } else if (stage == DeploymentStage.DEPLOY_RESOURCE_PROXY) {
            success = _deployResourceProxy(deployerAddress);
        } else if (stage == DeploymentStage.DEPLOY_FACADE_PROXY) {
            success = _deployFacadeProxy(deployerAddress);
        } else if (stage == DeploymentStage.SETUP_STORAGE_CONTRACTS) {
            success = _setupStorageContracts();
        } else if (stage == DeploymentStage.SETUP_ACCESS_CONTROL) {
            success = _setupAccessControl(deployerAddress);
        } else if (stage == DeploymentStage.VERIFY_DEPLOYMENT) {
            success = _verifyDeployment();
        }
        
        if (success) {
            stageCompleted[stage] = true;
            currentStage = _getNextStage(stage);
        }
        
        emit StageExecuted(stage, success);
    }
    
    // =============================================================
    //                   STAGE IMPLEMENTATIONS
    // =============================================================
    
    function _deployStorage(address deployerAddress) internal returns (bool) {
        try storageDeployment.deployStorageContracts(deployerAddress) {
            (nodeStorageAddress, userStorageAddress, resourceStorageAddress) = 
                storageDeployment.getStorageAddresses();
            return true;
        } catch {
            console.log("ERROR: Storage deployment failed");
            return false;
        }
    }
    
    function _deployLogicImplementations() internal returns (bool) {
        try logicDeployment.deployLogicImplementations() {
            (nodeLogicImplAddress, userLogicImplAddress, resourceLogicImplAddress, facadeImplAddress) = 
                logicDeployment.getLogicAddresses();
            return true;
        } catch {
            console.log("ERROR: Logic implementations deployment failed");
            return false;
        }
    }
    
    function _deployProxyAdmin(address deployerAddress) internal returns (bool) {
        try proxyDeployment.deployProxyAdmin(deployerAddress) {
            (proxyAdminAddress,,,,) = proxyDeployment.getProxyAddresses();
            return true;
        } catch {
            console.log("ERROR: Proxy admin deployment failed");
            return false;
        }
    }
    
    function _deployNodeProxy(address deployerAddress) internal returns (bool) {
        try proxyDeployment.deployNodeProxy(
            deployerAddress,
            nodeStorageAddress,
            userStorageAddress,
            resourceStorageAddress,
            nodeLogicImplAddress,
            proxyAdminAddress
        ) {
            (,nodeLogicProxyAddress,,,) = proxyDeployment.getProxyAddresses();
            return true;
        } catch {
            console.log("ERROR: Node proxy deployment failed");
            return false;
        }
    }
    
    function _deployUserProxy(address deployerAddress) internal returns (bool) {
        try proxyDeployment.deployUserProxy(
            deployerAddress,
            nodeStorageAddress,
            userStorageAddress,
            resourceStorageAddress,
            userLogicImplAddress,
            proxyAdminAddress
        ) {
            (,,userLogicProxyAddress,,) = proxyDeployment.getProxyAddresses();
            return true;
        } catch {
            console.log("ERROR: User proxy deployment failed");
            return false;
        }
    }
    
    function _deployResourceProxy(address deployerAddress) internal returns (bool) {
        try proxyDeployment.deployResourceProxy(
            deployerAddress,
            nodeStorageAddress,
            userStorageAddress,
            resourceStorageAddress,
            resourceLogicImplAddress,
            proxyAdminAddress
        ) {
            (,,,resourceLogicProxyAddress,) = proxyDeployment.getProxyAddresses();
            return true;
        } catch {
            console.log("ERROR: Resource proxy deployment failed");
            return false;
        }
    }
    
    function _deployFacadeProxy(address deployerAddress) internal returns (bool) {
        try proxyDeployment.deployFacadeProxy(
            deployerAddress,
            nodeLogicProxyAddress,
            userLogicProxyAddress,
            resourceLogicProxyAddress,
            facadeImplAddress,
            proxyAdminAddress
        ) {
            (,,,,facadeProxyAddress) = proxyDeployment.getProxyAddresses();
            return true;
        } catch {
            console.log("ERROR: Facade proxy deployment failed");
            return false;
        }
    }
    
    function _setupStorageContracts() internal returns (bool) {
        try configurationSetup.setupStorageContracts(
            nodeStorageAddress,
            userStorageAddress,
            resourceStorageAddress,
            nodeLogicProxyAddress,
            userLogicProxyAddress,
            resourceLogicProxyAddress
        ) {
            return true;
        } catch {
            console.log("ERROR: Storage contracts setup failed");
            return false;
        }
    }
    
    function _setupAccessControl(address deployerAddress) internal returns (bool) {
        try configurationSetup.setupAccessControl(
            deployerAddress,
            nodeLogicProxyAddress,
            userLogicProxyAddress,
            facadeProxyAddress
        ) {
            return true;
        } catch {
            console.log("ERROR: Access control setup failed");
            return false;
        }
    }
    
    function _verifyDeployment() internal returns (bool) {
        try configurationSetup.verifyDeployment(
            nodeStorageAddress,
            userStorageAddress,
            resourceStorageAddress,
            nodeLogicProxyAddress,
            userLogicProxyAddress,
            resourceLogicProxyAddress,
            facadeProxyAddress
        ) returns (bool success) {
            return success;
        } catch {
            console.log("ERROR: Deployment verification failed");
            return false;
        }
    }
    
    // =============================================================
    //                        UTILITIES
    // =============================================================
    
    function _getNextStage(DeploymentStage stage) internal pure returns (DeploymentStage) {
        if (stage == DeploymentStage.VERIFY_DEPLOYMENT) {
            return DeploymentStage.VERIFY_DEPLOYMENT; // Stay at final stage
        }
        return DeploymentStage(uint256(stage) + 1);
    }
    
    /**
     * @notice Get deployment status
     * @return completedStages Number of completed stages
     * @return totalStages Total number of stages
     * @return isComplete Whether deployment is complete
     */
    function getDeploymentStatus() 
        external 
        view 
        returns (uint256 completedStages, uint256 totalStages, bool isComplete) 
    {
        totalStages = 10; // Total number of stages
        completedStages = 0;
        
        for (uint256 i = 0; i < totalStages; i++) {
            if (stageCompleted[DeploymentStage(i)]) {
                completedStages++;
            }
        }
        
        isComplete = completedStages == totalStages;
    }
    
    /**
     * @notice Get all deployed contract addresses
     * @return nodeStorage Address of NodeStorage contract
     * @return userStorage Address of UserStorage contract
     * @return resourceStorage Address of ResourceStorage contract
     * @return nodeLogicImpl Address of NodeLogic implementation
     * @return userLogicImpl Address of UserLogic implementation
     * @return resourceLogicImpl Address of ResourceLogic implementation
     * @return facadeImpl Address of Facade implementation
     * @return proxyAdmin Address of ProxyAdmin contract
     * @return nodeLogicProxy Address of NodeLogic proxy
     * @return userLogicProxy Address of UserLogic proxy
     * @return resourceLogicProxy Address of ResourceLogic proxy
     * @return facadeProxy Address of Facade proxy
     */
    function getAllAddresses() 
        external 
        view 
        returns (
            address nodeStorage,
            address userStorage,
            address resourceStorage,
            address nodeLogicImpl,
            address userLogicImpl,
            address resourceLogicImpl,
            address facadeImpl,
            address proxyAdmin,
            address nodeLogicProxy,
            address userLogicProxy,
            address resourceLogicProxy,
            address facadeProxy
        )
    {
        return (
            nodeStorageAddress,
            userStorageAddress,
            resourceStorageAddress,
            nodeLogicImplAddress,
            userLogicImplAddress,
            resourceLogicImplAddress,
            facadeImplAddress,
            proxyAdminAddress,
            nodeLogicProxyAddress,
            userLogicProxyAddress,
            resourceLogicProxyAddress,
            facadeProxyAddress
        );
    }
}
