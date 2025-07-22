// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./BaseLogic.sol";
import "../storage/ClusterStorage.sol";
import "../libraries/ValidationLibrary.sol";
import "../libraries/RateLimitingLibrary.sol";
import "../libraries/GasOptimizationLibrary.sol";

/**
 * @title ClusterNodeAssignment
 * @notice Specialized contract for node assignment algorithms and validation
 * @dev This contract handles comprehensive node validation, address resolution,
 *      and node-to-cluster assignment logic. It provides efficient node validation
 *      for cluster operations and maintains node-address mappings.
 */
contract ClusterNodeAssignment is BaseLogic {
    using ValidationLibrary for *;
    using RateLimitingLibrary for *;
    using GasOptimizationLibrary for *;

    // Node ID to address mapping (for nodeId resolution)
    mapping(string => address) private nodeIdToAddress;
    mapping(address => string) private addressToNodeId;
    
    // Node-to-cluster relationship tracking
    mapping(string => string[]) private nodeToClusterIds; // nodeId => clusterIds
    mapping(string => mapping(string => bool)) private nodeInCluster; // clusterId => nodeId => exists
    
    // Node availability tracking
    mapping(string => bool) private nodeAvailableForClusters;
    mapping(address => bool) private addressAvailableForClusters;

    // Node assignment roles
    bytes32 public constant NODE_ASSIGNMENT_ROLE = keccak256("NODE_ASSIGNMENT_ROLE");
    bytes32 public constant CLUSTER_MANAGER_ROLE = keccak256("CLUSTER_MANAGER_ROLE");

    // Node validation constants
    uint256 public constant MAX_NODES_PER_VALIDATION = 100;
    uint256 public constant MAX_CLUSTERS_PER_NODE = 10;

    // Node assignment events
    event NodeMappingUpdated(string indexed nodeId, address indexed nodeAddress);
    event NodeAssignedToCluster(string indexed nodeId, string indexed clusterId);
    event NodeRemovedFromCluster(string indexed nodeId, string indexed clusterId);
    event NodeAvailabilityUpdated(string indexed nodeId, bool available);
    event BatchNodeValidationCompleted(uint256 totalNodes, uint256 validNodes, uint256 invalidNodes);

    // Node validation result structures
    struct NodeValidationResult {
        string nodeId;
        address nodeAddress;
        bool isValid;
        string validationError;
        NodeStorage.NodeStatus status;
    }

    struct BatchValidationResult {
        uint256 totalNodes;
        uint256 validNodes;
        uint256 invalidNodes;
        string[] validNodeIds;
        address[] validNodeAddresses;
        NodeValidationResult[] allResults;
    }

    struct NodeClusterInfo {
        string nodeId;
        address nodeAddress;
        string[] assignedClusters;
        bool availableForNewClusters;
        NodeStorage.NodeStatus status;
    }

    /**
     * @dev Initialize the cluster node assignment contract
     */
    function initialize(
        address _nodeStorage,
        address _userStorage,
        address _resourceStorage,
        address _admin
    ) external {
        _initializeBase(_nodeStorage, _userStorage, _resourceStorage, _admin);
        _grantRole(NODE_ASSIGNMENT_ROLE, _admin);
        _grantRole(CLUSTER_MANAGER_ROLE, _admin);
    }

    // =============================================================================
    // NODE VALIDATION FUNCTIONS
    // =============================================================================

    /**
     * @dev Validate nodes for cluster operations with comprehensive checks
     * @param nodeIds Array of node identifiers
     * @return nodeAddresses Array of corresponding node addresses
     */
    function _validateNodes(string[] memory nodeIds) internal view returns (address[] memory nodeAddresses) {
        require(address(nodeStorage) != address(0), "Node storage not set");
        require(nodeIds.length <= MAX_NODES_PER_VALIDATION, "Too many nodes to validate");
        
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
        require(nodeIds.length <= MAX_NODES_PER_VALIDATION, "Too many nodes to validate");
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
            
            // Check if node is available for new clusters
            if (!nodeAvailableForClusters[nodeId] && !addressAvailableForClusters[nodeInfo.nodeAddress]) {
                // Only continue if the node is explicitly marked as unavailable
                if (nodeToClusterIds[nodeId].length >= MAX_CLUSTERS_PER_NODE) continue;
            }
            
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
     * @dev Comprehensive batch node validation with detailed results
     * @param nodeIds Array of node identifiers to validate
     * @return result Detailed validation result with individual node status
     */
    function batchValidateNodes(string[] calldata nodeIds) 
        external 
        view 
        returns (BatchValidationResult memory result) 
    {
        require(nodeIds.length > 0, "No nodes provided");
        require(nodeIds.length <= MAX_NODES_PER_VALIDATION, "Too many nodes to validate");
        require(address(nodeStorage) != address(0), "Node storage not set");
        
        // Initialize result structure
        result = BatchValidationResult({
            totalNodes: nodeIds.length,
            validNodes: 0,
            invalidNodes: 0,
            validNodeIds: new string[](nodeIds.length),
            validNodeAddresses: new address[](nodeIds.length),
            allResults: new NodeValidationResult[](nodeIds.length)
        });
        
        for (uint256 i = 0; i < nodeIds.length; i++) {
            string calldata nodeId = nodeIds[i];
            NodeValidationResult memory nodeResult = NodeValidationResult({
                nodeId: nodeId,
                nodeAddress: address(0),
                isValid: false,
                validationError: "",
                status: NodeStorage.NodeStatus.INACTIVE
            });
            
            // Basic validation
            if (bytes(nodeId).length == 0) {
                nodeResult.validationError = "Empty node ID";
                result.allResults[i] = nodeResult;
                result.invalidNodes++;
                continue;
            }
            
            if (!nodeStorage.doesNodeExist(nodeId)) {
                nodeResult.validationError = "Node does not exist";
                result.allResults[i] = nodeResult;
                result.invalidNodes++;
                continue;
            }
            
            NodeStorage.NodeInfo memory nodeInfo = nodeStorage.getNodeInfo(nodeId);
            nodeResult.nodeAddress = nodeInfo.nodeAddress;
            nodeResult.status = nodeInfo.status;
            
            // Check node status
            if (nodeInfo.status != NodeStorage.NodeStatus.ACTIVE &&
                nodeInfo.status != NodeStorage.NodeStatus.LISTED) {
                nodeResult.validationError = "Node is not active or listed";
                result.allResults[i] = nodeResult;
                result.invalidNodes++;
                continue;
            }
            
            // Check valid registration
            if (nodeInfo.nodeAddress == address(0) || !nodeInfo.exists) {
                nodeResult.validationError = "Node not properly registered";
                result.allResults[i] = nodeResult;
                result.invalidNodes++;
                continue;
            }
            
            // Node is valid
            nodeResult.isValid = true;
            result.validNodeIds[result.validNodes] = nodeId;
            result.validNodeAddresses[result.validNodes] = nodeInfo.nodeAddress;
            result.allResults[i] = nodeResult;
            result.validNodes++;
        }
        
        // Resize valid arrays to actual count
        string[] memory finalValidNodeIds = new string[](result.validNodes);
        address[] memory finalValidNodeAddresses = new address[](result.validNodes);
        
        for (uint256 i = 0; i < result.validNodes; i++) {
            finalValidNodeIds[i] = result.validNodeIds[i];
            finalValidNodeAddresses[i] = result.validNodeAddresses[i];
        }
        
        result.validNodeIds = finalValidNodeIds;
        result.validNodeAddresses = finalValidNodeAddresses;
        
        return result;
    }

    // =============================================================================
    // NODE-ADDRESS MAPPING MANAGEMENT
    // =============================================================================

    /**
     * @dev Set node mapping for nodeId to address resolution
     * @param nodeId Node identifier
     * @param nodeAddress Node address
     */
    function setNodeMapping(string calldata nodeId, address nodeAddress) 
        external 
    {
        require(bytes(nodeId).length > 0, "Invalid nodeId");
        require(nodeAddress != address(0), "Invalid node address");
        
        // Clear existing mappings if they exist
        if (nodeIdToAddress[nodeId] != address(0)) {
            delete addressToNodeId[nodeIdToAddress[nodeId]];
        }
        if (bytes(addressToNodeId[nodeAddress]).length > 0) {
            delete nodeIdToAddress[addressToNodeId[nodeAddress]];
        }
        
        // Set new mappings
        nodeIdToAddress[nodeId] = nodeAddress;
        addressToNodeId[nodeAddress] = nodeId;
        
        emit NodeMappingUpdated(nodeId, nodeAddress);
    }

    /**
     * @dev Update node mappings for nodeId to address resolution (batch)
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
                emit NodeMappingUpdated(nodeId, nodeInfo.nodeAddress);
            }
        }
    }

    /**
     * @dev Batch update node mappings
     * @param nodeIds Array of node identifiers
     * @param nodeAddresses Array of corresponding node addresses
     */
    function batchSetNodeMappings(
        string[] calldata nodeIds,
        address[] calldata nodeAddresses
    ) external onlyRole(NODE_ASSIGNMENT_ROLE) {
        require(nodeIds.length == nodeAddresses.length, "Array length mismatch");
        require(nodeIds.length <= MAX_NODES_PER_VALIDATION, "Too many nodes");
        
        for (uint256 i = 0; i < nodeIds.length; i++) {
            if (bytes(nodeIds[i]).length > 0 && nodeAddresses[i] != address(0)) {
                nodeIdToAddress[nodeIds[i]] = nodeAddresses[i];
                addressToNodeId[nodeAddresses[i]] = nodeIds[i];
                emit NodeMappingUpdated(nodeIds[i], nodeAddresses[i]);
            }
        }
    }

    // =============================================================================
    // NODE-CLUSTER ASSIGNMENT TRACKING
    // =============================================================================

    /**
     * @dev Assign node to cluster (update tracking)
     * @param nodeId Node identifier
     * @param clusterId Cluster identifier
     */
    function assignNodeToCluster(string calldata nodeId, string calldata clusterId) 
        external 
        onlyRole(CLUSTER_MANAGER_ROLE) 
    {
        require(bytes(nodeId).length > 0, "Invalid nodeId");
        require(bytes(clusterId).length > 0, "Invalid clusterId");
        require(nodeToClusterIds[nodeId].length < MAX_CLUSTERS_PER_NODE, "Node assigned to too many clusters");
        
        // Check if already assigned
        if (nodeInCluster[clusterId][nodeId]) {
            return; // Already assigned
        }
        
        // Add to tracking
        nodeToClusterIds[nodeId].push(clusterId);
        nodeInCluster[clusterId][nodeId] = true;
        
        emit NodeAssignedToCluster(nodeId, clusterId);
    }

    /**
     * @dev Remove node from cluster (update tracking)
     * @param nodeId Node identifier
     * @param clusterId Cluster identifier
     */
    function removeNodeFromCluster(string calldata nodeId, string calldata clusterId) 
        external 
        onlyRole(CLUSTER_MANAGER_ROLE) 
    {
        require(bytes(nodeId).length > 0, "Invalid nodeId");
        require(bytes(clusterId).length > 0, "Invalid clusterId");
        
        // Check if assigned
        if (!nodeInCluster[clusterId][nodeId]) {
            return; // Not assigned
        }
        
        // Remove from tracking
        string[] storage clusters = nodeToClusterIds[nodeId];
        for (uint256 i = 0; i < clusters.length; i++) {
            if (keccak256(bytes(clusters[i])) == keccak256(bytes(clusterId))) {
                clusters[i] = clusters[clusters.length - 1];
                clusters.pop();
                break;
            }
        }
        nodeInCluster[clusterId][nodeId] = false;
        
        emit NodeRemovedFromCluster(nodeId, clusterId);
    }

    /**
     * @dev Set node availability for new clusters
     * @param nodeId Node identifier
     * @param available Whether node is available for new clusters
     */
    function setNodeAvailability(string calldata nodeId, bool available) 
        external 
        onlyRole(NODE_ASSIGNMENT_ROLE) 
    {
        require(bytes(nodeId).length > 0, "Invalid nodeId");
        
        nodeAvailableForClusters[nodeId] = available;
        
        // Also update address availability if we have mapping
        address nodeAddress = nodeIdToAddress[nodeId];
        if (nodeAddress != address(0)) {
            addressAvailableForClusters[nodeAddress] = available;
        }
        
        emit NodeAvailabilityUpdated(nodeId, available);
    }

    // =============================================================================
    // NODE INFORMATION QUERIES
    // =============================================================================

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
     * @dev Get clusters assigned to a node
     * @param nodeId Node identifier
     * @return clusterIds Array of cluster identifiers
     */
    function getNodeClusters(string calldata nodeId) external view returns (string[] memory clusterIds) {
        return nodeToClusterIds[nodeId];
    }

    /**
     * @dev Check if node is assigned to cluster
     * @param nodeId Node identifier
     * @param clusterId Cluster identifier
     * @return isAssigned Whether node is assigned to cluster
     */
    function isNodeInCluster(string calldata nodeId, string calldata clusterId) 
        external 
        view 
        returns (bool isAssigned) 
    {
        return nodeInCluster[clusterId][nodeId];
    }

    /**
     * @dev Get comprehensive node information for cluster assignment
     * @param nodeId Node identifier
     * @return nodeInfo Detailed node information for cluster assignment
     */
    function getNodeClusterInfo(string calldata nodeId) 
        external 
        view 
        returns (NodeClusterInfo memory nodeInfo) 
    {
        address nodeAddress = nodeIdToAddress[nodeId];
        bool available = nodeAvailableForClusters[nodeId] || addressAvailableForClusters[nodeAddress];
        
        NodeStorage.NodeStatus status = NodeStorage.NodeStatus.INACTIVE;
        if (address(nodeStorage) != address(0) && nodeStorage.doesNodeExist(nodeId)) {
            NodeStorage.NodeInfo memory info = nodeStorage.getNodeInfo(nodeId);
            status = info.status;
            if (nodeAddress == address(0)) {
                nodeAddress = info.nodeAddress;
            }
        }
        
        nodeInfo = NodeClusterInfo({
            nodeId: nodeId,
            nodeAddress: nodeAddress,
            assignedClusters: nodeToClusterIds[nodeId],
            availableForNewClusters: available && nodeToClusterIds[nodeId].length < MAX_CLUSTERS_PER_NODE,
            status: status
        });
        
        return nodeInfo;
    }

    /**
     * @dev Get available nodes for cluster assignment
     * @param maxResults Maximum number of results to return
     * @return availableNodeIds Array of available node identifiers
     * @return availableNodeAddresses Array of corresponding addresses
     */
    function getAvailableNodes(uint256 maxResults) 
        external 
        view 
        returns (string[] memory availableNodeIds, address[] memory availableNodeAddresses) 
    {
        require(maxResults > 0 && maxResults <= MAX_NODES_PER_VALIDATION, "Invalid max results");
        
        // This is a simplified implementation - in practice, you might need
        // more sophisticated indexing for large-scale operations
        string[] memory tempNodeIds = new string[](maxResults);
        address[] memory tempNodeAddresses = new address[](maxResults);
        uint256 count = 0;
        
        // Note: This would need optimization for production with proper indexing
        // For now, it serves as a template for the interface
        
        availableNodeIds = new string[](count);
        availableNodeAddresses = new address[](count);
        
        for (uint256 i = 0; i < count; i++) {
            availableNodeIds[i] = tempNodeIds[i];
            availableNodeAddresses[i] = tempNodeAddresses[i];
        }
        
        return (availableNodeIds, availableNodeAddresses);
    }

    // =============================================================================
    // ADMINISTRATIVE FUNCTIONS
    // =============================================================================

    /**
     * @dev Clear node mapping
     * @param nodeId Node identifier
     */
    function clearNodeMapping(string calldata nodeId) external onlyRole(ADMIN_ROLE) {
        address nodeAddress = nodeIdToAddress[nodeId];
        if (nodeAddress != address(0)) {
            delete nodeIdToAddress[nodeId];
            delete addressToNodeId[nodeAddress];
            emit NodeMappingUpdated(nodeId, address(0));
        }
    }

    /**
     * @dev Clear all cluster assignments for a node
     * @param nodeId Node identifier
     */
    function clearNodeClusterAssignments(string calldata nodeId) external onlyRole(ADMIN_ROLE) {
        string[] storage clusters = nodeToClusterIds[nodeId];
        for (uint256 i = 0; i < clusters.length; i++) {
            nodeInCluster[clusters[i]][nodeId] = false;
            emit NodeRemovedFromCluster(nodeId, clusters[i]);
        }
        delete nodeToClusterIds[nodeId];
    }

    // =============================================================================
    // ACCESS CONTROL
    // =============================================================================

    /**
     * @dev Override role check to provide custom error messages
     */
    function _checkRole(bytes32 role) internal view override {
        if (role == NODE_ASSIGNMENT_ROLE) {
            require(hasRole(role, msg.sender), "Not authorized for node assignment operations");
        } else if (role == CLUSTER_MANAGER_ROLE) {
            require(hasRole(role, msg.sender), "Not authorized for cluster management operations");
        } else {
            super._checkRole(role);
        }
    }

    /**
     * @dev Get contract name for circuit breaker logging
     */
    function _getContractName() internal pure override returns (string memory) {
        return "ClusterNodeAssignment";
    }
}
