// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title ApplicationStorage
 * @dev Storage contract for application deployment system
 * Contains only storage layout and structs - no logic functions
 */
contract ApplicationStorage is AccessControl {
    // Logic contract address
    address public logicContract;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

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

    // Modifier to restrict access to logic contract
    modifier onlyLogic() {
        require(msg.sender == logicContract, "Only logic contract");
        _;
    }

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

    /**
     * @dev Set the logic contract address
     */
    function setLogicContract(address _logicContract) external {
        logicContract = _logicContract;
    }

    /**
     * @dev Register a new application
     */
    function registerApplication(
        string calldata appId,
        address deployer,
        string[] calldata nodeIds,
        string calldata configHash
    ) external onlyLogic {
        applications[appId] = Application({
            appId: appId,
            deployer: deployer,
            status: 0, // pending
            deployedAt: block.timestamp,
            configHash: configHash
        });

        // Update deployer apps
        deployerApps[deployer].push(appId);

        // Update node apps and application nodes
        for (uint256 i = 0; i < nodeIds.length; i++) {
            nodeApps[nodeIds[i]].push(appId);
            applicationNodes[appId].push(nodeIds[i]);
        }

        emit ApplicationDeployed(appId, deployer, nodeIds, block.timestamp, configHash);
    }

    /**
     * @dev Update application status
     */
    function updateApplicationStatus(
        string calldata appId,
        uint8 newStatus
    ) external onlyLogic {
        Application storage app = applications[appId];
        uint8 oldStatus = app.status;
        app.status = newStatus;

        emit ApplicationStatusUpdated(appId, app.deployer, oldStatus, newStatus, block.timestamp);
    }

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
