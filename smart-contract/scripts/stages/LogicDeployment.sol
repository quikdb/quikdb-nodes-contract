// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../base/BaseDeployment.sol";
import "../../src/proxy/NodeLogic.sol";
import "../../src/proxy/UserLogic.sol";
import "../../src/proxy/ResourceLogic.sol";
import "../../src/proxy/Facade.sol";

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
        
        // Deploy NodeLogic implementation with CREATE2
        bytes memory nodeLogicBytecode = type(NodeLogic).creationCode;
        nodeLogicImplAddress = deployWithCreate2(nodeLogicSalt, nodeLogicBytecode);
        logDeployment("NodeLogic Implementation", nodeLogicImplAddress);
        
        // Deploy UserLogic implementation with CREATE2
        bytes memory userLogicBytecode = type(UserLogic).creationCode;
        userLogicImplAddress = deployWithCreate2(userLogicSalt, userLogicBytecode);
        logDeployment("UserLogic Implementation", userLogicImplAddress);
        
        // Deploy ResourceLogic implementation with CREATE2
        bytes memory resourceLogicBytecode = type(ResourceLogic).creationCode;
        resourceLogicImplAddress = deployWithCreate2(resourceLogicSalt, resourceLogicBytecode);
        logDeployment("ResourceLogic Implementation", resourceLogicImplAddress);
        
        // Deploy Facade implementation with CREATE2
        bytes memory facadeBytecode = type(Facade).creationCode;
        facadeImplAddress = deployWithCreate2(facadeSalt, facadeBytecode);
        logDeployment("Facade Implementation", facadeImplAddress);
        
        logStageCompletion("CREATE2 LOGIC IMPLEMENTATIONS DEPLOYMENT");
    }
    
    /**
     * @notice Get all deployed logic implementation addresses
     * @return nodeLogic Address of NodeLogic implementation
     * @return userLogic Address of UserLogic implementation
     * @return resourceLogic Address of ResourceLogic implementation
     * @return facade Address of Facade implementation
     */
    function getLogicAddresses() 
        external 
        view 
        returns (address nodeLogic, address userLogic, address resourceLogic, address facade) 
    {
        return (nodeLogicImplAddress, userLogicImplAddress, resourceLogicImplAddress, facadeImplAddress);
    }
}
