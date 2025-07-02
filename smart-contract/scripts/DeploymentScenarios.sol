// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import "./DeploymentOrchestrator.sol";

/**
 * @title DeployStorage
 * @notice Deploy only storage contracts (Stage 1)
 */
contract DeployStorage is Script {
    function run() external {
        DeploymentOrchestrator orchestrator = new DeploymentOrchestrator();
        orchestrator.deploySingleStage(DeploymentOrchestrator.DeploymentStage.DEPLOY_STORAGE);
    }
}

/**
 * @title DeployLogic
 * @notice Deploy only logic implementation contracts (Stage 2)
 */
contract DeployLogic is Script {
    function run() external {
        DeploymentOrchestrator orchestrator = new DeploymentOrchestrator();
        orchestrator.deploySingleStage(DeploymentOrchestrator.DeploymentStage.DEPLOY_LOGIC_IMPLS);
    }
}

/**
 * @title DeployProxies
 * @notice Deploy proxy admin and all proxy contracts (Stages 3-7)
 */
contract DeployProxies is Script {
    function run() external {
        DeploymentOrchestrator orchestrator = new DeploymentOrchestrator();
        
        // Deploy proxy admin first
        orchestrator.deploySingleStage(DeploymentOrchestrator.DeploymentStage.DEPLOY_PROXY_ADMIN);
        
        // Then deploy all proxies
        orchestrator.deploySingleStage(DeploymentOrchestrator.DeploymentStage.DEPLOY_NODE_PROXY);
        orchestrator.deploySingleStage(DeploymentOrchestrator.DeploymentStage.DEPLOY_USER_PROXY);
        orchestrator.deploySingleStage(DeploymentOrchestrator.DeploymentStage.DEPLOY_RESOURCE_PROXY);
        orchestrator.deploySingleStage(DeploymentOrchestrator.DeploymentStage.DEPLOY_FACADE_PROXY);
    }
}

/**
 * @title SetupConfiguration
 * @notice Setup storage contracts and access control (Stages 8-9)
 */
contract SetupConfiguration is Script {
    function run() external {
        DeploymentOrchestrator orchestrator = new DeploymentOrchestrator();
        
        orchestrator.deploySingleStage(DeploymentOrchestrator.DeploymentStage.SETUP_STORAGE_CONTRACTS);
        orchestrator.deploySingleStage(DeploymentOrchestrator.DeploymentStage.SETUP_ACCESS_CONTROL);
    }
}

/**
 * @title DeployComplete
 * @notice Deploy the complete QuikDB system in one go
 */
contract DeployComplete is Script {
    function run() external {
        DeploymentOrchestrator orchestrator = new DeploymentOrchestrator();
        orchestrator.deployComplete();
    }
}
