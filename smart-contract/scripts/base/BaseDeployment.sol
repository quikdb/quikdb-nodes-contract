// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import "../DeploymentConfig.sol";
import "./Create2Deployer.sol";
import "../utils/AddressPredictor.sol";

/**
 * @title BaseDeployment
 * @notice Base contract for all QuikDB deployment scripts with CREATE2 support
 * @dev Provides common functionality and state management for staged deployments
 */
abstract contract BaseDeployment is Script, DeploymentConfig {
    using AddressPredictor for *;
    // =============================================================
    //                         STORAGE
    // =============================================================
    
    /// @notice CREATE2 deployer instance
    Create2Deployer public create2Deployer;
    
    /// @notice Storage contract addresses
    address public nodeStorageAddress;
    address public userStorageAddress;
    address public resourceStorageAddress;
    
    /// @notice Logic implementation addresses
    address public nodeLogicImplAddress;
    address public userLogicImplAddress;
    address public resourceLogicImplAddress;
    address public facadeImplAddress;
    
    /// @notice Proxy infrastructure addresses
    address public proxyAdminAddress;
    
    /// @notice Proxy contract addresses
    address public nodeLogicProxyAddress;
    address public userLogicProxyAddress;
    address public resourceLogicProxyAddress;
    address public facadeProxyAddress;
    
    /// @notice Deployment salts for deterministic addresses
    bytes32 public nodeStorageSalt;
    bytes32 public userStorageSalt;
    bytes32 public resourceStorageSalt;
    bytes32 public nodeLogicSalt;
    bytes32 public userLogicSalt;
    bytes32 public resourceLogicSalt;
    bytes32 public facadeSalt;
    bytes32 public proxyAdminSalt;

    // =============================================================
    //                         EVENTS
    // =============================================================
    
    event ContractDeployed(string contractName, address contractAddress);
    event DeploymentStageCompleted(string stageName);
    
    // =============================================================
    //                      DEPLOYMENT UTILS
    // =============================================================
    
    /**
     * @notice Initialize deployment configuration with CREATE2 support
     * @dev Should be called at the start of deployment to set role addresses and salts
     */
    function initializeDeployment() internal {
        (, address deployerAddress) = getDeployerInfo();
        initializeRoleAddresses(deployerAddress);
        _initializeSalts();
        _deployCreate2Deployer();
        console.log("Deployment initialized with deployer as all role holders:", deployerAddress);
        console.log("CREATE2 Deployer deployed at:", address(create2Deployer));
    }
    
    /**
     * @notice Initialize salts for deterministic deployments
     */
    function _initializeSalts() private {
        (
            nodeStorageSalt,
            userStorageSalt,
            resourceStorageSalt,
            nodeLogicSalt,
            userLogicSalt,
            resourceLogicSalt,
            facadeSalt,
            proxyAdminSalt
        ) = AddressPredictor.getQuikDBSalts();
    }
    
    /**
     * @notice Deploy the CREATE2 deployer contract
     */
    function _deployCreate2Deployer() private {
        create2Deployer = new Create2Deployer();
    }
    
    /**
     * @notice Deploy a contract using CREATE2
     * @param salt The salt for deterministic deployment
     * @param bytecode The creation bytecode
     * @return deployed The deployed contract address
     */
    function deployWithCreate2(
        bytes32 salt,
        bytes memory bytecode
    ) internal returns (address deployed) {
        deployed = create2Deployer.deploy(salt, bytecode);
        return deployed;
    }
    
    /**
     * @notice Predict the address of a CREATE2 deployment
     * @param salt The salt to use
     * @param bytecode The creation bytecode
     * @return predicted The predicted address
     */
    function predictCreate2Address(
        bytes32 salt,
        bytes memory bytecode
    ) internal view returns (address predicted) {
        return create2Deployer.predictAddress(
            address(create2Deployer),
            salt,
            bytecode
        );
    }
    
    /**
     * @notice Get deployer private key and address from environment
     * @return privateKey The deployer's private key
     * @return deployerAddress The deployer's address
     */
    function getDeployerInfo() internal view returns (uint256 privateKey, address deployerAddress) {
        privateKey = vm.envUint("PRIVATE_KEY");
        deployerAddress = vm.addr(privateKey);
    }
    
    /**
     * @notice Log contract deployment
     * @param name Contract name
     * @param addr Contract address
     */
    function logDeployment(string memory name, address addr) internal {
        console.log(string.concat(name, " deployed at:"), addr);
        emit ContractDeployed(name, addr);
    }
    
    /**
     * @notice Log stage completion
     * @param stageName Name of completed stage
     */
    function logStageCompletion(string memory stageName) internal {
        console.log(string.concat("=== ", stageName, " COMPLETED ==="));
        emit DeploymentStageCompleted(stageName);
    }
    
    /**
     * @notice Validate required addresses are set
     * @param addresses Array of addresses to validate
     * @param names Array of address names for error messages
     */
    function validateAddresses(address[] memory addresses, string[] memory names) internal pure {
        require(addresses.length == names.length, "Array length mismatch");
        
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), string.concat(names[i], " address not set"));
        }
    }
}
