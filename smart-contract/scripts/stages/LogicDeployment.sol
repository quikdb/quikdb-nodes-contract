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
     * @notice Deploy all logic implementation contracts using CREATE2
     * @dev These are the implementation contracts that proxies will delegate to
     */
    function deployLogicImplementations() external {
        console.log("=== DEPLOYING LOGIC IMPLEMENTATIONS WITH CREATE2 ===");
        
        // Initialize deployment configuration if not already done
        if (address(create2Deployer) == address(0)) {
            initializeDeployment();
        }
        
        // Deploy QuikNodeLogic implementation with CREATE2
        bytes memory nodeLogicBytecode = type(QuikNodeLogic).creationCode;
        nodeLogicImplAddress = deployWithCreate2(nodeLogicSalt, nodeLogicBytecode);
        logDeployment("QuikNodeLogic Implementation", nodeLogicImplAddress);
        
        // Deploy QuikUserLogic implementation with CREATE2
        bytes memory userLogicBytecode = type(QuikUserLogic).creationCode;
        userLogicImplAddress = deployWithCreate2(userLogicSalt, userLogicBytecode);
        logDeployment("QuikUserLogic Implementation", userLogicImplAddress);
        
        // Deploy QuikResourceLogic implementation with CREATE2
        bytes memory resourceLogicBytecode = type(QuikResourceLogic).creationCode;
        resourceLogicImplAddress = deployWithCreate2(resourceLogicSalt, resourceLogicBytecode);
        logDeployment("QuikResourceLogic Implementation", resourceLogicImplAddress);
        
        // Deploy QuikFacade implementation with CREATE2
        bytes memory facadeBytecode = type(QuikFacade).creationCode;
        facadeImplAddress = deployWithCreate2(facadeSalt, facadeBytecode);
        logDeployment("QuikFacade Implementation", facadeImplAddress);
        
        logStageCompletion("CREATE2 LOGIC IMPLEMENTATIONS DEPLOYMENT");
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
