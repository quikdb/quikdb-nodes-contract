// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Create2Deployer
 * @notice Utility contract for deploying contracts using CREATE2 for deterministic addresses
 * @dev Provides functionality to predict and deploy contracts with deterministic addresses
 */
contract Create2Deployer {
    
    // =============================================================
    //                         EVENTS
    // =============================================================
    
    event ContractDeployed(address indexed deployed, bytes32 indexed salt, address indexed deployer);
    
    // =============================================================
    //                      ADDRESS PREDICTION
    // =============================================================
    
    /**
     * @notice Predict the address of a contract deployed via CREATE2
     * @param deployer The address that will deploy the contract
     * @param salt The salt used for CREATE2 deployment
     * @param bytecode The creation bytecode of the contract
     * @return predicted The predicted address
     */
    function predictAddress(
        address deployer,
        bytes32 salt,
        bytes memory bytecode
    ) public pure returns (address predicted) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                deployer,
                salt,
                keccak256(bytecode)
            )
        );
        return address(uint160(uint256(hash)));
    }
    
    /**
     * @notice Get the creation bytecode for a contract with constructor arguments
     * @param contractBytecode The contract's creation bytecode
     * @param constructorArgs The ABI-encoded constructor arguments
     * @return The complete creation bytecode
     */
    function getCreationBytecode(
        bytes memory contractBytecode,
        bytes memory constructorArgs
    ) public pure returns (bytes memory) {
        return abi.encodePacked(contractBytecode, constructorArgs);
    }
    
    // =============================================================
    //                      DEPLOYMENT
    // =============================================================
    
    /**
     * @notice Deploy a contract using CREATE2
     * @param salt The salt for deterministic address generation
     * @param bytecode The creation bytecode of the contract
     * @return deployed The address of the deployed contract
     */
    function deploy(
        bytes32 salt,
        bytes memory bytecode
    ) public returns (address deployed) {
        assembly {
            deployed := create2(
                0, // value
                add(bytecode, 0x20), // bytecode starts after length prefix
                mload(bytecode), // bytecode length
                salt
            )
        }
        
        require(deployed != address(0), "CREATE2: deployment failed");
        
        emit ContractDeployed(deployed, salt, msg.sender);
        return deployed;
    }
    
    /**
     * @notice Deploy a contract using CREATE2 with value
     * @param salt The salt for deterministic address generation
     * @param bytecode The creation bytecode of the contract
     * @param value The amount of ether to send to the contract
     * @return deployed The address of the deployed contract
     */
    function deployWithValue(
        bytes32 salt,
        bytes memory bytecode,
        uint256 value
    ) public payable returns (address deployed) {
        require(msg.value >= value, "Insufficient value sent");
        
        assembly {
            deployed := create2(
                value,
                add(bytecode, 0x20), // bytecode starts after length prefix
                mload(bytecode), // bytecode length
                salt
            )
        }
        
        require(deployed != address(0), "CREATE2: deployment failed");
        
        emit ContractDeployed(deployed, salt, msg.sender);
        return deployed;
    }
    
    /**
     * @notice Check if a contract is deployed at the predicted address
     * @param predicted The predicted address
     * @return True if a contract exists at the address
     */
    function isDeployed(address predicted) public view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(predicted)
        }
        return size > 0;
    }
}
