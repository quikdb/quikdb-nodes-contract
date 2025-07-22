// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./BaseLogic.sol";
import "../storage/ApplicationStorage.sol";

/**
 * @title ApplicationLogic
 * @notice Implementation contract for application deployment management
 * @dev This contract implements the business logic for registering and managing applications.
 *      It inherits from BaseLogic and follows the proxy pattern.
 */
contract ApplicationLogic is BaseLogic {
    // Storage contract reference
    ApplicationStorage public applicationStorage;

    // Application-specific roles
    bytes32 public constant APPLICATION_DEPLOYER_ROLE = keccak256("APPLICATION_DEPLOYER_ROLE");
    bytes32 public constant APPLICATION_MANAGER_ROLE = keccak256("APPLICATION_MANAGER_ROLE");

    // Application operation events
    event ApplicationRegistered(
        string indexed appId,
        address indexed deployer,
        uint256 nodeCount,
        uint256 timestamp
    );

    event ApplicationStatusChanged(
        string indexed appId,
        address indexed deployer,
        uint8 oldStatus,
        uint8 newStatus
    );

    // Custom errors
    error ApplicationAlreadyExists(string appId);
    error ApplicationNotFound(string appId);
    error InvalidApplicationId(string appId);
    error InvalidDeployer(address deployer);
    error InvalidStatus(uint8 status);
    error EmptyNodeList();
    error UnauthorizedDeployer(address deployer, string appId);

    /**
     * @dev Initialize the application logic contract
     * @param _applicationStorage Address of the application storage contract
     * @param _nodeStorage Address of the node storage contract
     * @param _userStorage Address of the user storage contract
     * @param _resourceStorage Address of the resource storage contract
     */
    function initialize(
        address _applicationStorage,
        address _nodeStorage,
        address _userStorage,
        address _resourceStorage
    ) external {
        _initializeBase(_nodeStorage, _userStorage, _resourceStorage, msg.sender);
        
        require(_applicationStorage != address(0), "Invalid application storage address");
        applicationStorage = ApplicationStorage(_applicationStorage);

        // Set up roles
        _grantRole(APPLICATION_DEPLOYER_ROLE, msg.sender);
        _grantRole(APPLICATION_MANAGER_ROLE, msg.sender);
    }

    /**
     * @dev Register a new application
     * @param appId Unique identifier for the application
     * @param deployer Address of the deployer
     * @param nodeIds Array of node IDs where the application will be deployed
     */
    function registerApplication(
        string calldata appId,
        address deployer,
        string[] calldata nodeIds,
        string calldata configHash
    ) external whenNotPaused nonReentrant {
        if (bytes(appId).length == 0) revert InvalidApplicationId(appId);
        if (deployer == address(0)) revert InvalidDeployer(deployer);
        if (nodeIds.length == 0) revert EmptyNodeList();

        // Check if application already exists
        (string memory existingAppId, , , , ) = applicationStorage.applications(appId);
        if (bytes(existingAppId).length > 0) {
            revert ApplicationAlreadyExists(appId);
        }

        // Register application in storage
        applicationStorage.registerApplication(appId, deployer, nodeIds, configHash);

        emit ApplicationRegistered(appId, deployer, nodeIds.length, block.timestamp);
    }

    /**
     * @dev Update application status
     * @param appId Unique identifier for the application
     * @param newStatus New status value
     */
    function updateStatus(
        string calldata appId,
        uint8 newStatus
    ) external whenNotPaused nonReentrant {
        if (bytes(appId).length == 0) revert InvalidApplicationId(appId);

        // Check if application exists
        (string memory existingAppId, address deployer, uint8 currentStatus, , ) = 
            applicationStorage.applications(appId);
        if (bytes(existingAppId).length == 0) {
            revert ApplicationNotFound(appId);
        }

        // Validate status transition (basic validation)
        if (newStatus > 4) revert InvalidStatus(newStatus); // 0-4 are valid statuses

        // Update status in storage
        applicationStorage.updateApplicationStatus(appId, newStatus);

        emit ApplicationStatusChanged(appId, deployer, currentStatus, newStatus);
    }

    /**
     * @dev Get application details
     * @param appId Unique identifier for the application
     * @return appId_ Application ID
     * @return deployer Address of the deployer
     * @return nodeIds Array of node IDs
     * @return status Current status
     * @return deployedAt Deployment timestamp
     * @return configHash Configuration hash
     */
    function getApplication(
        string calldata appId
    ) external view returns (
        string memory appId_,
        address deployer,
        string[] memory nodeIds,
        uint8 status,
        uint256 deployedAt,
        string memory configHash
    ) {
        if (bytes(appId).length == 0) revert InvalidApplicationId(appId);

        (appId_, deployer, status, deployedAt, configHash) = applicationStorage.applications(appId);
        nodeIds = applicationStorage.getApplicationNodes(appId);
    }

    /**
     * @dev Get applications deployed by a specific deployer
     * @param deployer Address of the deployer
     * @return appIds Array of application IDs deployed by the deployer
     */
    function getDeployerApps(
        address deployer
    ) external view returns (string[] memory appIds) {
        if (deployer == address(0)) revert InvalidDeployer(deployer);

        return applicationStorage.getDeployerApps(deployer);
    }

    /**
     * @dev Get applications deployed on a specific node
     * @param nodeId Node identifier
     * @return appIds Array of application IDs deployed on the node
     */
    function getNodeApps(
        string calldata nodeId
    ) external view returns (string[] memory appIds) {
        if (bytes(nodeId).length == 0) revert InvalidApplicationId(nodeId);

        return applicationStorage.getNodeApps(nodeId);
    }

    /**
     * @dev Check if an application exists
     * @param appId Unique identifier for the application
     * @return exists True if application exists, false otherwise
     */
    function applicationExists(string calldata appId) external view returns (bool exists) {
        if (bytes(appId).length == 0) return false;
        
        (string memory existingAppId, , , , ) = applicationStorage.applications(appId);
        return bytes(existingAppId).length > 0;
    }

    /**
     * @dev Check if a deployer owns a specific application
     * @param deployer Address of the deployer
     * @param appId Application identifier
     * @return owns True if deployer owns the application
     */
    function isDeployerOwner(
        address deployer,
        string calldata appId
    ) external view returns (bool owns) {
        if (deployer == address(0) || bytes(appId).length == 0) return false;

        (, address appDeployer, , , ) = applicationStorage.applications(appId);
        return appDeployer == deployer;
    }
}
