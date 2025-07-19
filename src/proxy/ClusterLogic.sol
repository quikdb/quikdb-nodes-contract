// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./BaseLogic.sol";
import "../storage/ClusterStorage.sol";

/**
 * @title ClusterLogic
 * @notice Implementation contract for cluster management
 * @dev This contract implements the business logic for cluster registration and management.
 *      It inherits from BaseLogic and follows the proxy pattern.
 */
contract ClusterLogic is BaseLogic {
    // Storage contract reference
    ClusterStorage public clusterStorage;

    // Cluster-specific roles
    bytes32 public constant CLUSTER_MANAGER_ROLE = keccak256("CLUSTER_MANAGER_ROLE");

    // Cluster operation events
    event ClusterRegistered(
        string indexed clusterId,
        address[] nodeAddresses,
        uint8 strategy,
        uint8 minActiveNodes,
        bool autoManaged
    );

    event ClusterStatusChanged(
        string indexed clusterId,
        uint8 indexed oldStatus,
        uint8 indexed newStatus
    );

    event ClusterStorageUpdated(address indexed newClusterStorage);

    modifier clusterExists(string calldata clusterId) {
        require(address(clusterStorage) != address(0), "Cluster storage not set");
        require(clusterStorage.clusterExists(clusterId), "Cluster does not exist");
        _;
    }

    modifier clusterNotExists(string calldata clusterId) {
        require(address(clusterStorage) != address(0), "Cluster storage not set");
        require(!clusterStorage.clusterExists(clusterId), "Cluster already exists");
        _;
    }

    modifier validClusterId(string calldata clusterId) {
        require(bytes(clusterId).length > 0, "Invalid cluster ID");
        _;
    }

    /**
     * @dev Initialize the cluster logic contract
     */
    function initialize(
        address _nodeStorage,
        address _userStorage,
        address _resourceStorage,
        address _admin
    ) external {
        _initializeBase(_nodeStorage, _userStorage, _resourceStorage, _admin);
        _grantRole(CLUSTER_MANAGER_ROLE, _admin);
    }

    /**
     * @dev Set the cluster storage contract (called after deployment)
     * @param _clusterStorage Address of the cluster storage contract
     */
    function setClusterStorage(address _clusterStorage) external onlyRole(ADMIN_ROLE) {
        require(_clusterStorage != address(0), "Invalid cluster storage address");
        clusterStorage = ClusterStorage(_clusterStorage);
        emit ClusterStorageUpdated(_clusterStorage);
    }

    // =============================================================================
    // CLUSTER MANAGEMENT FUNCTIONS
    // =============================================================================

    /**
     * @dev Register a new cluster
     * @param clusterId Unique identifier for the cluster
     * @param nodeAddresses Array of node operator addresses in the cluster
     * @param strategy Load balancing/routing strategy
     * @param minActiveNodes Minimum number of active nodes required
     * @param autoManaged Whether the cluster is automatically managed
     */
    function registerCluster(
        string calldata clusterId,
        address[] calldata nodeAddresses,
        ClusterStorage.ClusterStrategy strategy,
        uint8 minActiveNodes,
        bool autoManaged
    ) 
        external 
        whenNotPaused 
        onlyRole(CLUSTER_MANAGER_ROLE) 
        validClusterId(clusterId)
        clusterNotExists(clusterId)
        nonReentrant 
    {
        require(nodeAddresses.length > 0, "No node addresses provided");
        require(minActiveNodes > 0, "Invalid min active nodes");
        require(minActiveNodes <= nodeAddresses.length, "Invalid min active nodes");

        // Create cluster struct
        ClusterStorage.NodeCluster memory cluster = ClusterStorage.NodeCluster({
            clusterId: clusterId,
            nodeAddresses: nodeAddresses,
            strategy: uint8(strategy),
            minActiveNodes: minActiveNodes,
            status: uint8(ClusterStorage.ClusterStatus.INACTIVE), // Default to inactive
            autoManaged: autoManaged,
            createdAt: block.timestamp
        });

        // Store cluster via storage contract
        clusterStorage.registerCluster(clusterId, cluster);

        // Emit event with provided data
        emit ClusterRegistered(clusterId, nodeAddresses, uint8(strategy), minActiveNodes, autoManaged);
    }

    /**
     * @dev Update cluster status
     * @param clusterId Cluster identifier
     * @param newStatus New status for the cluster
     */
    function updateStatus(
        string calldata clusterId,
        ClusterStorage.ClusterStatus newStatus
    ) 
        external 
        whenNotPaused 
        onlyRole(CLUSTER_MANAGER_ROLE) 
        validClusterId(clusterId)
        clusterExists(clusterId)
        nonReentrant 
    {
        // Get current cluster info
        ClusterStorage.NodeCluster memory currentCluster = clusterStorage.getCluster(clusterId);
        uint8 oldStatus = currentCluster.status;

        // Update status via storage contract
        clusterStorage.updateClusterStatus(clusterId, uint8(newStatus));

        emit ClusterStatusChanged(clusterId, oldStatus, uint8(newStatus));
    }

    /**
     * @dev Get cluster information
     * @param clusterId Cluster identifier
     * @return NodeCluster struct containing cluster data
     */
    function getCluster(string calldata clusterId)
        external
        view
        validClusterId(clusterId)
        clusterExists(clusterId)
        returns (ClusterStorage.NodeCluster memory)
    {
        return clusterStorage.getCluster(clusterId);
    }

    /**
     * @dev Get total number of clusters
     * @return Total cluster count
     */
    function getClusterCount() external view returns (uint256) {
        require(address(clusterStorage) != address(0), "Cluster storage not set");
        return clusterStorage.clusterCount();
    }

    // =============================================================================
    // ADMIN FUNCTIONS
    // =============================================================================

    /**
     * @dev Update cluster storage contract address
     * @param newClusterStorage Address of the new cluster storage contract
     */
    function updateClusterStorage(address newClusterStorage) external onlyRole(ADMIN_ROLE) {
        require(newClusterStorage != address(0), "Invalid storage contract address");
        clusterStorage = ClusterStorage(newClusterStorage);
        emit ClusterStorageUpdated(newClusterStorage);
    }

    // =============================================================================
    // INTERNAL HELPER FUNCTIONS
    // =============================================================================

    /**
     * @dev Override role check to provide custom error messages
     */
    function _checkRole(bytes32 role) internal view override {
        if (role == CLUSTER_MANAGER_ROLE) {
            require(hasRole(role, msg.sender), "Not authorized to update cluster status");
        } else {
            super._checkRole(role);
        }
    }
}
