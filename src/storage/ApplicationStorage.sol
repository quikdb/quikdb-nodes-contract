// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

/**
 * @title ApplicationStorage
 * @dev Storage contract for application deployment system
 * Contains only storage layout and structs - no logic functions
 */
contract ApplicationStorage {
    /**
     * @dev Application structure
     */
    struct Application {
        string appId;
        address deployer;
        uint8 status;
        uint256 deployedAt;
        string configHash;
    }

    // Storage mappings
    mapping(string => Application) public applications;
    mapping(string => string[]) internal applicationNodes; // nodeIds for each application
    mapping(address => string[]) internal deployerApps;
    mapping(string => string[]) internal nodeApps;

    // Events
    event ApplicationDeployed(
        string indexed appId,
        address indexed deployer,
        string[] nodeIds,
        uint256 deployedAt,
        string configHash
    );

    event ApplicationStatusUpdated(
        string indexed appId,
        address indexed deployer,
        uint8 oldStatus,
        uint8 newStatus,
        uint256 timestamp
    );

    // Getter functions for array mappings
    function getApplicationNodes(string memory appId) external view returns (string[] memory) {
        return applicationNodes[appId];
    }

    function getDeployerApps(address deployer) external view returns (string[] memory) {
        return deployerApps[deployer];
    }

    function getNodeApps(string memory nodeId) external view returns (string[] memory) {
        return nodeApps[nodeId];
    }
}
