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

    // Node ID to address mapping (keep for nodeId resolution)
    mapping(string => address) private nodeIdToAddress;
    mapping(address => string) private addressToNodeId;

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

    // =============================================================================
    // MISSING BLOCKCHAIN SERVICE METHODS
    // =============================================================================

    /**
     * @dev Register cluster with blockchain service interface (alternative signature)
     */
    function registerClusterFromNodeIds(
        string[] calldata nodeIds,
        bytes32 /* clusterConfigHash */,
        bytes32 /* metadataHash */
    ) external whenNotPaused onlyRole(CLUSTER_MANAGER_ROLE) returns (string memory) {
        require(nodeIds.length > 0, "No nodes provided");
        require(nodeIds.length <= 100, "Too many nodes"); // Reasonable limit
        
        // Generate unique cluster ID
        string memory clusterId = string(abi.encodePacked("cluster_", block.timestamp, "_", block.number));
        require(!clusterStorage.clusterExists(clusterId), "Cluster ID collision");
        
        // Validate all nodeIds and convert to addresses
        address[] memory nodeAddresses = new address[](nodeIds.length);
        for (uint i = 0; i < nodeIds.length; i++) {
            require(bytes(nodeIds[i]).length > 0, "Invalid nodeId");
            
            // Validate that the node exists in NodeStorage
            require(address(nodeStorage) != address(0), "Node storage not set");
            require(nodeStorage.doesNodeExist(nodeIds[i]), "Node does not exist");
            
            // Get the actual node address from storage
            address nodeAddr = nodeStorage.getNodeAddress(nodeIds[i]);
            require(nodeAddr != address(0), "Invalid node address");
            nodeAddresses[i] = nodeAddr;
            
            // Store mapping for future reference
            if (nodeIdToAddress[nodeIds[i]] == address(0)) {
                nodeIdToAddress[nodeIds[i]] = nodeAddr;
                addressToNodeId[nodeAddr] = nodeIds[i];
            }
        }

        // Create and store cluster
        ClusterStorage.NodeCluster memory cluster = ClusterStorage.NodeCluster({
            clusterId: clusterId,
            nodeAddresses: nodeAddresses,
            strategy: uint8(ClusterStorage.ClusterStrategy.ROUND_ROBIN),
            minActiveNodes: uint8(nodeIds.length > 1 ? 1 : 1),
            status: uint8(ClusterStorage.ClusterStatus.ACTIVE),
            autoManaged: true,
            createdAt: block.timestamp
        });
        
        clusterStorage.registerCluster(clusterId, cluster);

        emit ClusterRegistered(
            clusterId, 
            nodeAddresses, 
            uint8(ClusterStorage.ClusterStrategy.ROUND_ROBIN), 
            uint8(nodeIds.length > 1 ? 1 : 1), 
            true
        );

        return clusterId;
    }

    /**
     * @dev Update cluster status with blockchain service interface
     */
    function updateClusterStatus(
        string calldata clusterId,
        string calldata status,
        uint8 healthScore,
        uint256 /* lastUpdated */
    ) external whenNotPaused onlyRole(CLUSTER_MANAGER_ROLE) {
        require(bytes(clusterId).length > 0, "Invalid clusterId");
        require(clusterStorage.clusterExists(clusterId), "Cluster does not exist");
        require(healthScore <= 100, "Invalid health score");
        
        // Convert string status to enum
        ClusterStorage.ClusterStatus newStatus = ClusterStorage.ClusterStatus.ACTIVE;
        if (keccak256(abi.encodePacked(status)) == keccak256(abi.encodePacked("inactive"))) {
            newStatus = ClusterStorage.ClusterStatus.INACTIVE;
        } else if (keccak256(abi.encodePacked(status)) == keccak256(abi.encodePacked("maintenance"))) {
            newStatus = ClusterStorage.ClusterStatus.MAINTENANCE;
        }
        
        // Get current status from storage
        ClusterStorage.NodeCluster memory currentCluster = clusterStorage.getCluster(clusterId);
        uint8 oldStatus = currentCluster.status;
        
        // Update cluster status and health score in storage
        clusterStorage.updateClusterStatus(clusterId, uint8(newStatus));
        clusterStorage.updateClusterHealthScore(clusterId, healthScore);
        
        emit ClusterStatusChanged(clusterId, oldStatus, uint8(newStatus));
    }
    
    /**
     * @dev Get cluster health score
     */
    function getClusterHealthScore(string calldata clusterId) external view returns (uint8) {
        return clusterStorage.getClusterHealthScore(clusterId);
    }
    
    /**
     * @dev Get all cluster IDs
     */
    function getAllClusterIds() external view returns (string[] memory) {
        return clusterStorage.getAllClusterIds();
    }
    
    /**
     * @dev Set node mapping (for nodeId resolution)
     */
    function setNodeMapping(string calldata nodeId, address nodeAddress) external onlyRole(ADMIN_ROLE) {
        require(bytes(nodeId).length > 0, "Invalid nodeId");
        require(nodeAddress != address(0), "Invalid node address");
        
        nodeIdToAddress[nodeId] = nodeAddress;
        addressToNodeId[nodeAddress] = nodeId;
    }
}
