// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../base/BaseDeployment.sol";
import "../../src/storage/NodeStorage.sol";
import "../../src/storage/UserStorage.sol";
import "../../src/storage/ResourceStorage.sol";

/**
 * @title StorageDeployment
 * @notice Deploys all storage contracts for the QuikDB system
 * @dev Stage 1 of the deployment process
 */
contract StorageDeployment is BaseDeployment {
    
    /**
     * @notice Deploy all storage contracts
     * @param deployerAddress Address that will own the storage contracts
     */
    function deployStorageContracts(address deployerAddress) external {
        console.log("=== DEPLOYING STORAGE CONTRACTS ===");
        
        // Deploy NodeStorage
        NodeStorage nodeStorage = new NodeStorage(deployerAddress);
        nodeStorageAddress = address(nodeStorage);
        logDeployment("NodeStorage", nodeStorageAddress);
        
        // Deploy UserStorage
        UserStorage userStorage = new UserStorage(deployerAddress);
        userStorageAddress = address(userStorage);
        logDeployment("UserStorage", userStorageAddress);
        
        // Deploy ResourceStorage
        ResourceStorage resourceStorage = new ResourceStorage(deployerAddress);
        resourceStorageAddress = address(resourceStorage);
        logDeployment("ResourceStorage", resourceStorageAddress);
        
        logStageCompletion("STORAGE DEPLOYMENT");
    }
    
    /**
     * @notice Get all deployed storage addresses
     * @return nodeStorage Address of NodeStorage contract
     * @return userStorage Address of UserStorage contract  
     * @return resourceStorage Address of ResourceStorage contract
     */
    function getStorageAddresses() 
        external 
        view 
        returns (address nodeStorage, address userStorage, address resourceStorage) 
    {
        return (nodeStorageAddress, userStorageAddress, resourceStorageAddress);
    }
}
