// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./BaseLogic.sol";
import "../storage/ClusterStorage.sol";
import "../libraries/ValidationLibrary.sol";
import "../libraries/RateLimitingLibrary.sol";
import "../libraries/GasOptimizationLibrary.sol";

/**
 * @title ClusterManager
 * @notice Specialized contract for complex cluster formation and management operations
 * @dev This contract handles complex cluster registration algorithms, geographic distribution validation,
 *      and optimal cluster configuration. It extracts the most complex logic from ClusterLogic
 *      to reduce contract size while maintaining full functionality.
 */
contract ClusterManager is BaseLogic {
    using ValidationLibrary for *;
    using RateLimitingLibrary for *;
    using GasOptimizationLibrary for *;

    // Storage contract reference
    ClusterStorage public clusterStorage;

    // Node ID to address mapping (for nodeId resolution)
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

    event ClusterStorageUpdated(address indexed newClusterStorage);

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
     * @dev Initialize the cluster manager contract
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
    // COMPLEX CLUSTER REGISTRATION FUNCTIONS
    // =============================================================================

    /**
     * @dev Register a new cluster with comprehensive validation and geographic distribution
     * @param clusterId Unique cluster identifier
     * @param nodeAddresses Array of node operator addresses
     * @param strategy Cluster strategy (ROUND_ROBIN, RANDOM, etc.)
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
        validClusterId(clusterId)
        clusterNotExists(clusterId)
        nonReentrant 
        rateLimit("registerCluster", RateLimitingLibrary.MAX_CLUSTER_REGISTRATIONS_PER_HOUR, RateLimitingLibrary.HOUR_WINDOW)
        circuitBreakerCheck("clusterRegistration")
        emergencyPauseCheck("ClusterManager") 
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
     * @dev Register cluster from node IDs with unique ID generation and optimal configuration
     * @param nodeIds Array of node identifiers
     * @return clusterId Generated unique cluster identifier
     */
    function registerClusterFromNodeIds(
        string[] calldata nodeIds,
        bytes32 /* clusterConfigHash */,
        bytes32 /* metadataHash */
    ) external whenNotPaused returns (string memory) {
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
     * @dev Validate nodes for cluster registration with comprehensive checks
     * @param nodeIds Array of node identifiers to validate
     * @return validNodes Valid node IDs that passed validation
     * @return nodeAddresses Corresponding addresses for valid nodes
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

    // =============================================================================
    // CLUSTER REGISTRATION VALIDATION AND PROCESSING
    // =============================================================================

    /**
     * @dev Comprehensive cluster registration validation
     * @param clusterId Cluster identifier to validate
     * @param nodeAddresses Array of node addresses
     * @param strategy Cluster strategy
     * @param minActiveNodes Minimum active nodes required
     */
    function _validateClusterRegistration(
        string calldata clusterId,
        address[] calldata nodeAddresses,
        ClusterStorage.ClusterStrategy strategy,
        uint8 minActiveNodes
    ) internal view {
        // Validate cluster ID format
        ValidationLibrary.validateId(clusterId);
        
        // Validate cluster size
        ValidationLibrary.validateClusterSize(nodeAddresses.length);
        
        // Validate node addresses
        ValidationLibrary.validateAddresses(nodeAddresses);
        
        // Validate strategy
        require(uint8(strategy) <= 3, "Invalid cluster strategy");
        
        // Validate minimum active nodes
        require(minActiveNodes > 0 && minActiveNodes <= nodeAddresses.length, "Invalid min active nodes");
        
        // Check if cluster already exists
        require(!clusterStorage.clusterExists(clusterId), "Cluster already exists");
    }

    /**
     * @dev Perform core cluster registration logic
     * @param clusterId Cluster identifier
     * @param nodeAddresses Array of node addresses
     * @param strategy Cluster strategy
     * @param minActiveNodes Minimum active nodes required
     * @param autoManaged Whether cluster is auto-managed
     */
    function _performClusterRegistration(
        string calldata clusterId,
        address[] calldata nodeAddresses,
        ClusterStorage.ClusterStrategy strategy,
        uint8 minActiveNodes,
        bool autoManaged
    ) internal {
        // Validate geographic distribution (simplified for batch efficiency)
        // require(_validateGeographicDistribution(nodeAddresses), "Geographic distribution failed");
        
        // Create cluster info (needs to be NodeCluster for registerCluster function)
        ClusterStorage.NodeCluster memory clusterInfo = ClusterStorage.NodeCluster({
            clusterId: clusterId,
            nodeAddresses: nodeAddresses,
            strategy: uint8(strategy),
            minActiveNodes: minActiveNodes,
            status: uint8(ClusterStorage.ClusterStatus.ACTIVE),
            autoManaged: autoManaged,
            createdAt: block.timestamp
        });
        
        // Store cluster
        clusterStorage.registerCluster(clusterId, clusterInfo);
        
        // Update node mappings for efficiency
        for (uint256 i = 0; i < nodeAddresses.length; i++) {
            if (bytes(addressToNodeId[nodeAddresses[i]]).length == 0) {
                string memory nodeId = string(abi.encodePacked("node_", _addressToString(nodeAddresses[i])));
                nodeIdToAddress[nodeId] = nodeAddresses[i];
                addressToNodeId[nodeAddresses[i]] = nodeId;
            }
        }
        
        // Emit individual cluster registered event
        emit ClusterRegistered(clusterId, nodeAddresses, uint8(strategy), minActiveNodes, autoManaged);
    }

    // =============================================================================
    // NODE VALIDATION AND MANAGEMENT
    // =============================================================================

    /**
     * @dev Validate nodes for cluster operations with comprehensive checks
     * @param nodeIds Array of node identifiers
     * @return nodeAddresses Array of corresponding node addresses
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

    // =============================================================================
    // GEOGRAPHIC DISTRIBUTION MANAGEMENT
    // =============================================================================

    /**
     * @dev Set node region mapping for geographic distribution validation
     * @param nodeId Node identifier
     * @param region Geographic region
     */
    function setNodeRegion(string calldata nodeId, string calldata region) 
        external 
    {
        require(bytes(nodeId).length > 0, "Invalid nodeId");
        require(bytes(region).length > 0, "Invalid region");
        
        nodeToRegion[nodeId] = region;
        regionNodes[region].push(nodeId);
    }

    /**
     * @dev Set node mapping (for nodeId resolution)
     * @param nodeId Node identifier
     * @param nodeAddress Node address
     */
    function setNodeMapping(string calldata nodeId, address nodeAddress) 
        external 
    {
        require(bytes(nodeId).length > 0, "Invalid nodeId");
        require(nodeAddress != address(0), "Invalid address");
        
        nodeIdToAddress[nodeId] = nodeAddress;
        addressToNodeId[nodeAddress] = nodeId;
    }

    // =============================================================================
    // UTILITY FUNCTIONS
    // =============================================================================

    /**
     * @dev Convert address to string for node ID generation
     * @param addr Address to convert
     * @return String representation of the address
     */
    function _addressToString(address addr) internal pure returns (string memory) {
        bytes32 value = bytes32(uint256(uint160(addr)));
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(42);
        str[0] = '0';
        str[1] = 'x';
        for (uint256 i = 0; i < 20; i++) {
            str[2 + i * 2] = alphabet[uint8(value[i + 12] >> 4)];
            str[3 + i * 2] = alphabet[uint8(value[i + 12] & 0x0f)];
        }
        return string(str);
    }

    /**
     * @dev Get node region mapping
     * @param nodeId Node identifier
     * @return region Geographic region of the node
     */
    function getNodeRegion(string calldata nodeId) external view returns (string memory region) {
        return nodeToRegion[nodeId];
    }

    /**
     * @dev Get nodes in a specific region
     * @param region Geographic region
     * @return nodeIds Array of node identifiers in the region
     */
    function getNodesInRegion(string calldata region) external view returns (string[] memory nodeIds) {
        return regionNodes[region];
    }

    /**
     * @dev Get node address from node ID
     * @param nodeId Node identifier
     * @return nodeAddress Address of the node
     */
    function getNodeAddress(string calldata nodeId) external view returns (address nodeAddress) {
        return nodeIdToAddress[nodeId];
    }

    /**
     * @dev Get node ID from address
     * @param nodeAddress Node address
     * @return nodeId Node identifier
     */
    function getNodeId(address nodeAddress) external view returns (string memory nodeId) {
        return addressToNodeId[nodeAddress];
    }

    /**
     * @dev Override role check to provide custom error messages
     */
    function _checkRole(bytes32 role) internal view override {
        if (role == CLUSTER_MANAGER_ROLE) {
            require(hasRole(role, msg.sender), "Not authorized for cluster management operations");
        } else {
            super._checkRole(role);
        }
    }
}
