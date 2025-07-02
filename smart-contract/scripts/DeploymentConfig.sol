// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title DeploymentConfig
 * @dev Configuration values for QuikDB deployment
 */
contract DeploymentConfig {
    // Role addresses - set to deployer initially, can be changed later
    // NOTE: These will be set to the deployer address during deployment
    // and can be updated later through proper role management
    address internal NODE_OPERATOR_ADDRESS;
    address internal AUTH_SERVICE_ADDRESS; 
    address internal UPGRADER_ADDRESS;

    // Network configuration (for reference)
    uint256 internal constant LISK_CHAIN_ID = 4202;
    string internal constant LISK_NETWORK_NAME = "Lisk Sepolia";
    
    /**
     * @notice Initialize role addresses with deployer address
     * @dev Called during deployment to set initial role holders
     */
    function initializeRoleAddresses(address deployerAddress) internal {
        NODE_OPERATOR_ADDRESS = deployerAddress;
        AUTH_SERVICE_ADDRESS = deployerAddress;
        UPGRADER_ADDRESS = deployerAddress;
    }
}
