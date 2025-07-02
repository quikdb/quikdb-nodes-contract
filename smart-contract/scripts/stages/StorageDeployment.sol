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
     * @notice Deploy all storage contracts using CREATE2 for deterministic addresses
     * @param deployerAddress Address that will own the storage contracts
     */
    function deployStorageContracts(address deployerAddress) external {
        console.log("=== DEPLOYING STORAGE CONTRACTS WITH CREATE2 ===");
        
        // Initialize deployment configuration if not already done
        if (address(create2Deployer) == address(0)) {
            initializeDeployment();
        }
        
        // Deploy NodeStorage with CREATE2
        bytes memory nodeStorageBytecode = abi.encodePacked(
            type(NodeStorage).creationCode,
            abi.encode(deployerAddress)
        );
        nodeStorageAddress = deployWithCreate2(nodeStorageSalt, nodeStorageBytecode);
        logDeployment("NodeStorage", nodeStorageAddress);
        
        // Deploy UserStorage with CREATE2
        bytes memory userStorageBytecode = abi.encodePacked(
            type(UserStorage).creationCode,
            abi.encode(deployerAddress)
        );
        userStorageAddress = deployWithCreate2(userStorageSalt, userStorageBytecode);
        logDeployment("UserStorage", userStorageAddress);
        
        // Deploy ResourceStorage with CREATE2
        bytes memory resourceStorageBytecode = abi.encodePacked(
            type(ResourceStorage).creationCode,
            abi.encode(deployerAddress)
        );
        resourceStorageAddress = deployWithCreate2(resourceStorageSalt, resourceStorageBytecode);
        logDeployment("ResourceStorage", resourceStorageAddress);
        
        logStageCompletion("CREATE2 STORAGE DEPLOYMENT");
    }
    
    /**
     * @notice Predict storage contract addresses before deployment
     * @param deployerAddress Address that will own the storage contracts
     * @return nodeStorage Predicted NodeStorage address
     * @return userStorage Predicted UserStorage address
     * @return resourceStorage Predicted ResourceStorage address
     */
    function predictStorageAddresses(address deployerAddress)
        external
        view
        returns (address nodeStorage, address userStorage, address resourceStorage)
    {
        bytes memory nodeStorageBytecode = abi.encodePacked(
            type(NodeStorage).creationCode,
            abi.encode(deployerAddress)
        );
        nodeStorage = predictCreate2Address(nodeStorageSalt, nodeStorageBytecode);
        
        bytes memory userStorageBytecode = abi.encodePacked(
            type(UserStorage).creationCode,
            abi.encode(deployerAddress)
        );
        userStorage = predictCreate2Address(userStorageSalt, userStorageBytecode);
        
        bytes memory resourceStorageBytecode = abi.encodePacked(
            type(ResourceStorage).creationCode,
            abi.encode(deployerAddress)
        );
        resourceStorage = predictCreate2Address(resourceStorageSalt, resourceStorageBytecode);
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
