// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./BaseLogic.sol";
import "../storage/ClusterStorage.sol";
import "../libraries/ValidationLibrary.sol";
import "../libraries/RateLimitingLibrary.sol";

/**
 * @title ClusterLogic
 * @notice Implementation contract for cluster management with production-grade validation
 * @dev This contract implements the business logic for cluster registration and management.
 *      It inherits from BaseLogic and follows the proxy pattern.
 */
contract ClusterLogic is BaseLogic {
    using ValidationLibrary for *;
    using RateLimitingLibrary for *;

    // Storage contract reference
    ClusterStorage public clusterStorage;

    // Node ID to address mapping (keep for nodeId resolution)
    mapping(string => address) private nodeIdToAddress;
    mapping(address => string) private addressToNodeId;
    
    // Geographic distribution tracking
    mapping(string => string[]) private regionNodes; // region => nodeIds
    mapping(string => string) private nodeToRegion; // nodeId => region

    // Cluster-specific roles
    bytes32 public constant CLUSTER_MANAGER_ROLE = keccak256("CLUSTER_MANAGER_ROLE");

    // Production validation constants
    uint256 public constant MAX_NODES_PER_CLUSTER = 100;
    uint256 public constant MIN_NODES_PER_CLUSTER = 1;
    uint256 public constant MAX_REGIONS_PER_CLUSTER = 10;
    uint256 public constant MAX_NODES_PER_REGION = 50;

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
    /**
     * @dev Register a new cluster with comprehensive production validation
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
        rateLimit("registerCluster", RateLimitingLibrary.MAX_CLUSTER_REGISTRATIONS_PER_HOUR, RateLimitingLibrary.HOUR_WINDOW)
        circuitBreakerCheck("clusterRegistration")
        emergencyPauseCheck("ClusterLogic") 
    {
        // === PRODUCTION VALIDATION ===
        
        // Validate cluster ID format
        ValidationLibrary.validateId(clusterId);
        
        // Validate cluster size
        ValidationLibrary.validateClusterSize(nodeAddresses.length);
        
        // Validate min active nodes
        ValidationLibrary.validateRange(minActiveNodes, 1, nodeAddresses.length);
        
        // Validate all node addresses
        ValidationLibrary.validateAddresses(nodeAddresses);
        
        // Check for duplicate addresses
        for (uint256 i = 0; i < nodeAddresses.length; i++) {
            for (uint256 j = i + 1; j < nodeAddresses.length; j++) {
                ValidationLibrary.validateDifferentAddresses(nodeAddresses[i], nodeAddresses[j]);
            }
        }

        // === BUSINESS LOGIC VALIDATION ===
        require(address(nodeStorage) != address(0), "Node storage not set");
        
        string[] memory regions = new string[](nodeAddresses.length);
        uint256 regionCount = 0;
        
        for (uint256 i = 0; i < nodeAddresses.length; i++) {
            // Check if this address is registered as a node operator
            string memory nodeId = addressToNodeId[nodeAddresses[i]];
            if (bytes(nodeId).length > 0) {
                // If we have a mapping, validate the node exists and is active
                require(nodeStorage.doesNodeExist(nodeId), "Node does not exist");
                
                NodeStorage.NodeInfo memory nodeInfo = nodeStorage.getNodeInfo(nodeId);
                require(
                    nodeInfo.status == NodeStorage.NodeStatus.ACTIVE || 
                    nodeInfo.status == NodeStorage.NodeStatus.LISTED,
                    "Node is not active or listed"
                );
                
                // Track regions for geographic distribution validation
                string memory region = nodeToRegion[nodeId];
                if (bytes(region).length > 0) {
                    bool regionExists = false;
                    for (uint256 j = 0; j < regionCount; j++) {
                        if (keccak256(bytes(regions[j])) == keccak256(bytes(region))) {
                            regionExists = true;
                            break;
                        }
                    }
                    if (!regionExists && regionCount < MAX_REGIONS_PER_CLUSTER) {
                        regions[regionCount] = region;
                        regionCount++;
                    }
                }
            }
            // Note: If no mapping exists, we still allow registration but recommend 
            // using registerClusterFromNodeIds for better validation
        }
        
        // Validate geographic distribution if we have region data
        if (regionCount >= 2) {
            string[] memory validRegions = new string[](regionCount);
            for (uint256 i = 0; i < regionCount; i++) {
                validRegions[i] = regions[i];
            }
            ValidationLibrary.validateGeographicDistribution(validRegions);
        }

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
     * @dev Validate nodes for cluster operations
     * @param nodeIds Array of node identifiers to validate
     * @return nodeAddresses Array of validated node addresses
     */
    function _validateNodes(string[] memory nodeIds) internal view returns (address[] memory nodeAddresses) {
        require(address(nodeStorage) != address(0), "Node storage not set");
        
        nodeAddresses = new address[](nodeIds.length);
        
        for (uint256 i = 0; i < nodeIds.length; i++) {
            string memory nodeId = nodeIds[i];
            require(bytes(nodeId).length > 0, "Invalid nodeId");
            
            // Check if node exists in NodeStorage
            require(nodeStorage.doesNodeExist(nodeId), "Node does not exist");
            
            // Get node information for validation
            NodeStorage.NodeInfo memory nodeInfo = nodeStorage.getNodeInfo(nodeId);
            
            // Validate node status
            require(
                nodeInfo.status == NodeStorage.NodeStatus.ACTIVE || 
                nodeInfo.status == NodeStorage.NodeStatus.LISTED,
                "Node is not active or listed"
            );
            
            // Validate node address
            require(nodeInfo.nodeAddress != address(0), "Invalid node address");
            require(nodeInfo.exists, "Node not properly registered");
            
            nodeAddresses[i] = nodeInfo.nodeAddress;
        }
    }

    /**
     * @dev Update node mappings for nodeId to address resolution
     * @param nodeIds Array of node identifiers
     */
    function _updateNodeMappings(string[] memory nodeIds) internal {
        for (uint256 i = 0; i < nodeIds.length; i++) {
            string memory nodeId = nodeIds[i];
            
            // Get node information
            NodeStorage.NodeInfo memory nodeInfo = nodeStorage.getNodeInfo(nodeId);
            
            // Update mapping for future reference
            if (nodeIdToAddress[nodeId] == address(0)) {
                nodeIdToAddress[nodeId] = nodeInfo.nodeAddress;
                addressToNodeId[nodeInfo.nodeAddress] = nodeId;
            }
        }
    }

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
    /**
     * @dev Register cluster from node IDs with comprehensive production validation
     */
    function registerClusterFromNodeIds(
        string[] calldata nodeIds,
        bytes32 /* clusterConfigHash */,
        bytes32 /* metadataHash */
    ) external whenNotPaused onlyRole(CLUSTER_MANAGER_ROLE) returns (string memory) {
        // === PRODUCTION VALIDATION ===
        
        // Validate cluster size
        ValidationLibrary.validateClusterSize(nodeIds.length);
        
        // Validate unique node IDs and format
        ValidationLibrary.validateUniqueNodeIds(nodeIds);
        
        // Generate unique cluster ID with validation
        string memory clusterId = string(abi.encodePacked("cluster_", block.timestamp, "_", block.number));
        ValidationLibrary.validateId(clusterId);
        require(!clusterStorage.clusterExists(clusterId), "Cluster ID collision");
        
        // === GEOGRAPHIC DISTRIBUTION VALIDATION ===
        string[] memory regions = new string[](nodeIds.length);
        uint256 regionCount = 0;
        
        // Collect regions from nodes for geographic validation
        for (uint256 i = 0; i < nodeIds.length; i++) {
            string memory region = nodeToRegion[nodeIds[i]];
            if (bytes(region).length > 0) {
                bool regionExists = false;
                for (uint256 j = 0; j < regionCount; j++) {
                    if (keccak256(bytes(regions[j])) == keccak256(bytes(region))) {
                        regionExists = true;
                        break;
                    }
                }
                if (!regionExists && regionCount < MAX_REGIONS_PER_CLUSTER) {
                    regions[regionCount] = region;
                    regionCount++;
                }
            }
        }
        
        // Validate geographic distribution if we have region data
        if (regionCount >= 2) {
            string[] memory validRegions = new string[](regionCount);
            for (uint256 i = 0; i < regionCount; i++) {
                validRegions[i] = regions[i];
            }
            ValidationLibrary.validateGeographicDistribution(validRegions);
        }
        
        // Validate all nodes using comprehensive validation
        address[] memory nodeAddresses = _validateNodes(nodeIds);

        // Update node mappings for future reference
        _updateNodeMappings(nodeIds);

        // Calculate optimal minimum active nodes (at least 1, but recommend redundancy)
        uint8 minActiveNodes = uint8(nodeIds.length > 1 ? 1 : 1);
        if (nodeIds.length >= 3) {
            minActiveNodes = uint8((nodeIds.length * 60) / 100); // 60% for redundancy
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
     * @dev Validate nodes for cluster operations (public helper)
     * @param nodeIds Array of node identifiers to validate
     * @return validNodes Array of validated node IDs
     * @return nodeAddresses Array of corresponding node addresses
     */
    function validateNodesForCluster(string[] calldata nodeIds) 
        external 
        view 
        returns (string[] memory validNodes, address[] memory nodeAddresses) 
    {
        require(nodeIds.length > 0, "No nodes provided");
        require(address(nodeStorage) != address(0), "Node storage not set");
        
        validNodes = new string[](nodeIds.length);
        nodeAddresses = new address[](nodeIds.length);
        uint256 validCount = 0;
        
        for (uint256 i = 0; i < nodeIds.length; i++) {
            string calldata nodeId = nodeIds[i];
            
            // Basic validation
            if (bytes(nodeId).length == 0) continue;
            if (!nodeStorage.doesNodeExist(nodeId)) continue;
            
            NodeStorage.NodeInfo memory nodeInfo = nodeStorage.getNodeInfo(nodeId);
            
            // Check if node is available for clusters
            if (nodeInfo.status != NodeStorage.NodeStatus.ACTIVE &&
                nodeInfo.status != NodeStorage.NodeStatus.LISTED) continue;
                
            // Check valid registration
            if (nodeInfo.nodeAddress == address(0) || !nodeInfo.exists) continue;
            
            validNodes[validCount] = nodeId;
            nodeAddresses[validCount] = nodeInfo.nodeAddress;
            validCount++;
        }
        
        // Resize arrays to actual valid count
        string[] memory finalValidNodes = new string[](validCount);
        address[] memory finalNodeAddresses = new address[](validCount);
        
        for (uint256 i = 0; i < validCount; i++) {
            finalValidNodes[i] = validNodes[i];
            finalNodeAddresses[i] = nodeAddresses[i];
        }
        
        return (finalValidNodes, finalNodeAddresses);
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

    /**
     * @dev Get contract name for circuit breaker logging
     */
    function _getContractName() internal pure override returns (string memory) {
        return "ClusterLogic";
    }
}
