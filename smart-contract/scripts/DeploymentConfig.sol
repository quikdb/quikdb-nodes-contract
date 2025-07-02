// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title DeploymentConfig
 * @dev Configuration values for QuikDB deployment
 */
contract DeploymentConfig {
    // Important addresses
    address internal constant NODE_OPERATOR_ADDRESS =
        0x0000000000000000000000000000000000000002;
    address internal constant AUTH_SERVICE_ADDRESS =
        0x0000000000000000000000000000000000000003;
    address internal constant UPGRADER_ADDRESS =
        0x0000000000000000000000000000000000000004;

    // Network configuration (for reference)
    uint256 internal constant LISK_CHAIN_ID = 4202;
    string internal constant LISK_NETWORK_NAME = "Lisk Sepolia";
}
