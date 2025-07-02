// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../base/BaseDeployment.sol";
import "../../src/proxy/QuikNodeLogic.sol";
import "../../src/proxy/QuikUserLogic.sol";
import "../../src/proxy/QuikResourceLogic.sol";
import "../../src/proxy/QuikFacade.sol";

/**
 * @title LogicDeployment
 * @notice Deploys all logic implementation contracts for the QuikDB system
 * @dev Stage 2 of the deployment process - deploys the implementation contracts that will be used by proxies
 */
contract LogicDeployment is BaseDeployment {
    
    /**
     * @notice Deploy all logic implementation contracts
     * @dev These are the implementation contracts that proxies will delegate to
     */
    function deployLogicImplementations() external {
        console.log("=== DEPLOYING LOGIC IMPLEMENTATIONS ===");
        
        // Deploy QuikNodeLogic implementation
        QuikNodeLogic nodeLogicImpl = new QuikNodeLogic();
        nodeLogicImplAddress = address(nodeLogicImpl);
        logDeployment("QuikNodeLogic Implementation", nodeLogicImplAddress);
        
        // Deploy QuikUserLogic implementation
        QuikUserLogic userLogicImpl = new QuikUserLogic();
        userLogicImplAddress = address(userLogicImpl);
        logDeployment("QuikUserLogic Implementation", userLogicImplAddress);
        
        // Deploy QuikResourceLogic implementation
        QuikResourceLogic resourceLogicImpl = new QuikResourceLogic();
        resourceLogicImplAddress = address(resourceLogicImpl);
        logDeployment("QuikResourceLogic Implementation", resourceLogicImplAddress);
        
        // Deploy QuikFacade implementation
        QuikFacade facadeImpl = new QuikFacade();
        facadeImplAddress = address(facadeImpl);
        logDeployment("QuikFacade Implementation", facadeImplAddress);
        
        logStageCompletion("LOGIC IMPLEMENTATIONS DEPLOYMENT");
    }
    
    /**
     * @notice Get all deployed logic implementation addresses
     * @return nodeLogic Address of QuikNodeLogic implementation
     * @return userLogic Address of QuikUserLogic implementation
     * @return resourceLogic Address of QuikResourceLogic implementation
     * @return facade Address of QuikFacade implementation
     */
    function getLogicAddresses() 
        external 
        view 
        returns (address nodeLogic, address userLogic, address resourceLogic, address facade) 
    {
        return (nodeLogicImplAddress, userLogicImplAddress, resourceLogicImplAddress, facadeImplAddress);
    }
}
