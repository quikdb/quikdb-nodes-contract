// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import "../DeploymentConfig.sol";

/**
 * @title BaseDeployment
 * @notice Base contract for all QuikDB deployment scripts
 * @dev Provides common functionality and state management for staged deployments
 */
abstract contract BaseDeployment is Script, DeploymentConfig {
    // =============================================================
    //                         STORAGE
    // =============================================================
    
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

    // =============================================================
    //                         EVENTS
    // =============================================================
    
    event ContractDeployed(string contractName, address contractAddress);
    event DeploymentStageCompleted(string stageName);
    
    // =============================================================
    //                      DEPLOYMENT UTILS
    // =============================================================
    
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
