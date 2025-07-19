// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title ClusterStorage
 * @notice Storage contract for cluster data
 * @dev This contract contains only storage layout and structs for the cluster system.
 *      It follows the proxy pattern where logic is separated from storage.
 */
contract ClusterStorage is AccessControl {
    // Role for logic contracts that can modify storage
    bytes32 public constant LOGIC_ROLE = keccak256("LOGIC_ROLE");

    // Cluster strategy enumeration
    enum ClusterStrategy {
        ROUND_ROBIN, // Distribute workload in round-robin fashion
        LOAD_BALANCED, // Distribute based on current load
        GEOGRAPHIC, // Route based on geographic proximity
        PERFORMANCE, // Route based on performance metrics
        FAILOVER // Primary-backup failover strategy
    }

    // Cluster status enumeration
    enum ClusterStatus {
        INACTIVE, // Cluster is not active
        ACTIVE, // Cluster is active and accepting work
        MAINTENANCE, // Cluster is under maintenance
        DEGRADED, // Cluster is partially operational
        FAILED // Cluster has failed
    }

    // Node cluster structure
    struct NodeCluster {
        string clusterId; // Unique identifier for the cluster
        address[] nodeAddresses; // Array of node operator addresses in the cluster
        uint8 strategy; // Load balancing/routing strategy (maps to ClusterStrategy enum)
        uint8 minActiveNodes; // Minimum number of active nodes required
        uint8 status; // Current cluster status (maps to ClusterStatus enum)
        bool autoManaged; // Whether the cluster is automatically managed
        uint256 createdAt; // Timestamp when cluster was created
    }

    // Storage mappings
    mapping(string => NodeCluster) public clusters; // clusterId => NodeCluster
    mapping(string => bool) public clusterExists; // clusterId => exists
    uint256 public clusterCount; // Total number of clusters

    // Events
    event ClusterRegistered(
        string indexed clusterId,
        address[] nodeAddresses,
        uint8 strategy,
        uint8 minActiveNodes,
        bool autoManaged,
        uint256 timestamp
    );

    event ClusterStatusUpdated(
        string indexed clusterId, 
        uint8 indexed oldStatus, 
        uint8 indexed newStatus, 
        uint256 timestamp
    );

    // Access control modifier
    modifier onlyLogic() {
        require(hasRole(LOGIC_ROLE, msg.sender), "Caller is not Logic contract");
        _;
    }

    /**
     * @dev Constructor sets up the contract with the deployer as the default admin
     * @param admin Address to be granted the default admin role
     */
    constructor(address admin) {
        require(admin != address(0), "Invalid admin address");
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    /**
     * @dev Set the logic contract address
     * @param logicContract Address of the logic contract
     */
    function setLogicContract(address logicContract) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(LOGIC_ROLE, logicContract);
    }

    /**
     * @dev Register a new cluster
     * @param clusterId Unique identifier for the cluster
     * @param cluster NodeCluster struct with cluster data
     */
    function registerCluster(string calldata clusterId, NodeCluster calldata cluster) external onlyLogic {
        require(!clusterExists[clusterId], "Cluster already exists");
        require(bytes(clusterId).length > 0, "Invalid cluster ID");
        
        clusters[clusterId] = cluster;
        clusterExists[clusterId] = true;
        clusterCount++;
        
        emit ClusterRegistered(
            clusterId,
            cluster.nodeAddresses,
            cluster.strategy,
            cluster.minActiveNodes,
            cluster.autoManaged,
            block.timestamp
        );
    }

    /**
     * @dev Update cluster status
     * @param clusterId Cluster identifier
     * @param newStatus New status for the cluster
     */
    function updateClusterStatus(string calldata clusterId, uint8 newStatus) external onlyLogic {
        require(clusterExists[clusterId], "Cluster does not exist");
        
        uint8 oldStatus = clusters[clusterId].status;
        clusters[clusterId].status = newStatus;
        
        emit ClusterStatusUpdated(clusterId, oldStatus, newStatus, block.timestamp);
    }

    /**
     * @dev Get cluster information
     * @param clusterId Cluster identifier
     * @return NodeCluster struct containing cluster data
     */
    function getCluster(string calldata clusterId) external view returns (NodeCluster memory) {
        require(clusterExists[clusterId], "Cluster does not exist");
        return clusters[clusterId];
    }
}
