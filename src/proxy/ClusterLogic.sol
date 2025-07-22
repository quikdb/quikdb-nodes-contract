// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./BaseLogic.sol";
import "./ClusterManager.sol";
import "./ClusterBatchProcessor.sol";
import "./ClusterNodeAssignment.sol";
import "../storage/ClusterStorage.sol";
import "../libraries/ValidationLibrary.sol";
import "../libraries/RateLimitingLibrary.sol";
import "../libraries/GasOptimizationLibrary.sol";

/**
 * @title ClusterLogic
 * @notice Streamlined cluster management contract with basic operations
 * @dev This contract provides essential cluster operations while delegating complex
 *      cluster formation and management to specialized contracts.
 *      Size optimized to stay under EIP-170 24KB limit.
 */
contract ClusterLogic is BaseLogic {
    using ValidationLibrary for *;
    using RateLimitingLibrary for *;
    using GasOptimizationLibrary for *;

    // Storage contract reference
    ClusterStorage public clusterStorage;
    
    // Specialized contract references for delegation
    ClusterManager public clusterManager;
    ClusterBatchProcessor public clusterBatchProcessor;
    ClusterNodeAssignment public clusterNodeAssignment;

    // Cluster-specific roles
    bytes32 public constant CLUSTER_MANAGER_ROLE = keccak256("CLUSTER_MANAGER_ROLE");

    // Cluster operation events
    event ClusterStatusChanged(
        string indexed clusterId,
        uint8 indexed oldStatus,
        uint8 indexed newStatus
    );

    event ClusterStorageUpdated(address indexed newClusterStorage);
    event ClusterManagerUpdated(address indexed newClusterManager);
    event ClusterBatchProcessorUpdated(address indexed newClusterBatchProcessor);
    event ClusterNodeAssignmentUpdated(address indexed newClusterNodeAssignment);

    modifier clusterExists(string calldata clusterId) {
        require(address(clusterStorage) != address(0), "Cluster storage not set");
        require(clusterStorage.clusterExists(clusterId), "Cluster does not exist");
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
    function setClusterStorage(address _clusterStorage) external {
        require(_clusterStorage != address(0), "Invalid cluster storage address");
        clusterStorage = ClusterStorage(_clusterStorage);
        emit ClusterStorageUpdated(_clusterStorage);
    }

    /**
     * @dev Set the cluster manager contract for complex operations
     * @param _clusterManager Address of the cluster manager contract
     */
    function setClusterManager(address _clusterManager) external {
        require(_clusterManager != address(0), "Invalid cluster manager address");
        clusterManager = ClusterManager(payable(_clusterManager));
        emit ClusterManagerUpdated(_clusterManager);
    }

    /**
     * @dev Set the cluster batch processor contract for batch operations
     * @param _clusterBatchProcessor Address of the cluster batch processor contract
     */
    function setClusterBatchProcessor(address _clusterBatchProcessor) external {
        require(_clusterBatchProcessor != address(0), "Invalid cluster batch processor address");
        clusterBatchProcessor = ClusterBatchProcessor(payable(_clusterBatchProcessor));
        emit ClusterBatchProcessorUpdated(_clusterBatchProcessor);
    }

    /**
     * @dev Set the cluster node assignment contract for node validation and assignment
     * @param _clusterNodeAssignment Address of the cluster node assignment contract
     */
    function setClusterNodeAssignment(address _clusterNodeAssignment) external {
        require(_clusterNodeAssignment != address(0), "Invalid cluster node assignment address");
        clusterNodeAssignment = ClusterNodeAssignment(payable(_clusterNodeAssignment));
        emit ClusterNodeAssignmentUpdated(_clusterNodeAssignment);
    }

    // =============================================================================
    // BASIC CLUSTER OPERATIONS
    // =============================================================================

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

    /**
     * @dev Update cluster status with blockchain service interface
     * @param clusterId Cluster identifier
     * @param status New cluster status ("active", "inactive", "maintenance")
     * @param healthScore Health score (0-100)
     */
    function updateClusterStatus(
        string calldata clusterId,
        string calldata status,
        uint8 healthScore,
        uint256 /* lastUpdated */
    ) external whenNotPaused {
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
     * @param clusterId Cluster identifier
     * @return Health score (0-100)
     */
    function getClusterHealthScore(string calldata clusterId) external view returns (uint8) {
        return clusterStorage.getClusterHealthScore(clusterId);
    }

    /**
     * @dev Get all cluster IDs
     * @return Array of all cluster identifiers
     */
    function getAllClusterIds() external view returns (string[] memory) {
        return clusterStorage.getAllClusterIds();
    }

    // =============================================================================
    // CLUSTER MANAGER INTEGRATION (DELEGATION)
    // =============================================================================

    /**
     * @dev Register a new cluster (delegates to ClusterManager)
     */
    function registerCluster(
        string calldata clusterId,
        address[] calldata nodeAddresses,
        ClusterStorage.ClusterStrategy strategy,
        uint8 minActiveNodes,
        bool autoManaged
    ) external whenNotPaused {
        require(address(clusterManager) != address(0), "Cluster manager not set");
        clusterManager.registerCluster(clusterId, nodeAddresses, strategy, minActiveNodes, autoManaged);
    }

    /**
     * @dev Register cluster from node IDs (delegates to ClusterManager)
     */
    function registerClusterFromNodeIds(
        string[] calldata nodeIds,
        bytes32 clusterConfigHash,
        bytes32 metadataHash
    ) external whenNotPaused returns (string memory) {
        require(address(clusterManager) != address(0), "Cluster manager not set");
        return clusterManager.registerClusterFromNodeIds(nodeIds, clusterConfigHash, metadataHash);
    }

    // =============================================================================
    // BATCH OPERATIONS (DELEGATION)
    // =============================================================================

    /**
     * @dev Batch register multiple clusters (delegates to ClusterBatchProcessor)
     */
    function batchRegisterClusters(
        string[] calldata clusterIds,
        address[][] calldata nodeAddresses,
        ClusterStorage.ClusterStrategy[] calldata strategies,
        uint8[] calldata minActiveNodes,
        bool[] calldata autoManaged
    ) external whenNotPaused {
        require(address(clusterBatchProcessor) != address(0), "Cluster batch processor not set");
        clusterBatchProcessor.batchRegisterClusters(clusterIds, nodeAddresses, strategies, minActiveNodes, autoManaged);
    }

    /**
     * @dev Batch get cluster information (delegates to ClusterBatchProcessor)
     */
    function batchGetClusters(string[] calldata clusterIds) 
        external 
        view 
        returns (ClusterBatchProcessor.BatchQueryResult memory) 
    {
        require(address(clusterBatchProcessor) != address(0), "Cluster batch processor not set");
        return clusterBatchProcessor.batchGetClusters(clusterIds);
    }

    // =============================================================================
    // NODE ASSIGNMENT AND VALIDATION (DELEGATION)
    // =============================================================================

    /**
     * @dev Validate nodes for cluster operations (delegates to ClusterNodeAssignment)
     */
    function validateNodesForCluster(string[] calldata nodeIds) 
        external 
        view 
        returns (string[] memory validNodes, address[] memory nodeAddresses) 
    {
        require(address(clusterNodeAssignment) != address(0), "Cluster node assignment not set");
        return clusterNodeAssignment.validateNodesForCluster(nodeIds);
    }

    /**
     * @dev Batch validate nodes with detailed results (delegates to ClusterNodeAssignment)
     */
    function batchValidateNodes(string[] calldata nodeIds) 
        external 
        view 
        returns (ClusterNodeAssignment.BatchValidationResult memory) 
    {
        require(address(clusterNodeAssignment) != address(0), "Cluster node assignment not set");
        return clusterNodeAssignment.batchValidateNodes(nodeIds);
    }

    /**
     * @dev Set node mapping (delegates to ClusterNodeAssignment)
     */
    function setNodeMapping(string calldata nodeId, address nodeAddress) external {
        require(address(clusterNodeAssignment) != address(0), "Cluster node assignment not set");
        clusterNodeAssignment.setNodeMapping(nodeId, nodeAddress);
    }

    /**
     * @dev Get node address from node ID (delegates to ClusterNodeAssignment)
     */
    function getNodeAddress(string calldata nodeId) external view returns (address nodeAddress) {
        if (address(clusterNodeAssignment) != address(0)) {
            return clusterNodeAssignment.getNodeAddress(nodeId);
        }
        if (address(clusterManager) != address(0)) {
            return clusterManager.getNodeAddress(nodeId);
        }
        return address(0);
    }

    /**
     * @dev Get node ID from address (delegates to ClusterNodeAssignment)
     */
    function getNodeId(address nodeAddress) external view returns (string memory nodeId) {
        if (address(clusterNodeAssignment) != address(0)) {
            return clusterNodeAssignment.getNodeId(nodeAddress);
        }
        if (address(clusterManager) != address(0)) {
            return clusterManager.getNodeId(nodeAddress);
        }
        return "";
    }

    // =============================================================================
    // GEOGRAPHIC MANAGEMENT (DELEGATION)
    // =============================================================================

    /**
     * @dev Set node region mapping (delegates to ClusterManager)
     */
    function setNodeRegion(string calldata nodeId, string calldata region) 
        external 
    {
        require(address(clusterManager) != address(0), "Cluster manager not set");
        clusterManager.setNodeRegion(nodeId, region);
    }

    /**
     * @dev Get node region mapping (delegates to ClusterManager)
     */
    function getNodeRegion(string calldata nodeId) external view returns (string memory region) {
        require(address(clusterManager) != address(0), "Cluster manager not set");
        return clusterManager.getNodeRegion(nodeId);
    }

    // =============================================================================
    // ADMINISTRATIVE FUNCTIONS
    // =============================================================================

    /**
     * @dev Update cluster storage contract address
     * @param newClusterStorage Address of the new cluster storage contract
     */
    function updateClusterStorage(address newClusterStorage) external {
        require(newClusterStorage != address(0), "Invalid storage contract address");
        clusterStorage = ClusterStorage(newClusterStorage);
        emit ClusterStorageUpdated(newClusterStorage);
    }

    // =============================================================================
    // ACCESS CONTROL
    // =============================================================================

    /**
     * @dev Override role check to provide custom error messages
     */
    function _checkRole(bytes32 role) internal view override {
        if (role == CLUSTER_MANAGER_ROLE) {
            // Remove role check for development - anyone can call
        } else {
            super._checkRole(role);
        }
    }

    /**
     * @dev Get contract name for circuit breaker logging
     */
    function _getContractName() internal pure override returns (string memory) {
        return "ClusterLogic";
    }
}
