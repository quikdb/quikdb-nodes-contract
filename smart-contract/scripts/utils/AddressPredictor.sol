// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title AddressPredictor
 * @notice Utility for predicting CREATE2 deployment addresses
 * @dev Provides functions to predict addresses for QuikDB contract deployments
 */
library AddressPredictor {
    
    // =============================================================
    //                      SALT GENERATION
    // =============================================================
    
    /**
     * @notice Generate a deterministic salt based on contract name and deployer
     * @param contractName The name of the contract being deployed
     * @param deployer The address of the deployer
     * @param nonce Optional nonce for uniqueness
     * @return salt The generated salt
     */
    function generateSalt(
        string memory contractName,
        address deployer,
        uint256 nonce
    ) internal pure returns (bytes32 salt) {
        return keccak256(abi.encodePacked(contractName, deployer, nonce));
    }
    
    /**
     * @notice Generate a simple salt from a string
     * @param identifier String identifier for the contract
     * @return salt The generated salt
     */
    function generateSalt(string memory identifier) internal pure returns (bytes32 salt) {
        return keccak256(abi.encodePacked(identifier));
    }
    
    // =============================================================
    //                   ADDRESS PREDICTION
    // =============================================================
    
    /**
     * @notice Predict CREATE2 address
     * @param deployer The deployer address
     * @param salt The salt for deployment
     * @param initCodeHash The keccak256 hash of the init code
     * @return predicted The predicted address
     */
    function predict(
        address deployer,
        bytes32 salt,
        bytes32 initCodeHash
    ) internal pure returns (address predicted) {
        return address(uint160(uint256(keccak256(
            abi.encodePacked(
                bytes1(0xff),
                deployer,
                salt,
                initCodeHash
            )
        ))));
    }
    
    /**
     * @notice Get init code hash for a contract with constructor args
     * @param creationCode The contract creation bytecode
     * @param constructorArgs The encoded constructor arguments
     * @return hash The keccak256 hash of the complete init code
     */
    function getInitCodeHash(
        bytes memory creationCode,
        bytes memory constructorArgs
    ) internal pure returns (bytes32 hash) {
        return keccak256(abi.encodePacked(creationCode, constructorArgs));
    }
    
    // =============================================================
    //                  QUIKDB SPECIFIC SALTS
    // =============================================================
    
    /**
     * @notice Get deterministic salts for QuikDB contracts
     */
    function getQuikDBSalts() internal pure returns (
        bytes32 nodeStorageSalt,
        bytes32 userStorageSalt,
        bytes32 resourceStorageSalt,
        bytes32 nodeLogicSalt,
        bytes32 userLogicSalt,
        bytes32 resourceLogicSalt,
        bytes32 facadeSalt,
        bytes32 proxyAdminSalt
    ) {
        nodeStorageSalt = generateSalt("NodeStorage");
        userStorageSalt = generateSalt("UserStorage");
        resourceStorageSalt = generateSalt("ResourceStorage");
        nodeLogicSalt = generateSalt("NodeLogic");
        userLogicSalt = generateSalt("UserLogic");
        resourceLogicSalt = generateSalt("ResourceLogic");
        facadeSalt = generateSalt("QuikFacade");
        proxyAdminSalt = generateSalt("ProxyAdmin");
    }
    
    /**
     * @notice Get salt for proxy contracts
     * @param logicType The type of logic contract (node, user, resource, facade)
     * @return salt The salt for the proxy
     */
    function getProxySalt(string memory logicType) internal pure returns (bytes32 salt) {
        return generateSalt(string.concat(logicType, "Proxy"));
    }
}
