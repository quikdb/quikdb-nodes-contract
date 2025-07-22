// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./BaseLogic.sol";
import "../storage/ClusterStorage.sol";
import "../libraries/GasOptimizationLibrary.sol";
import "../libraries/RateLimitingLibrary.sol";

/**
 * @title ClusterAnalytics
 * @dev Specialized contract for cluster monitoring, reporting, and analytics
 * 
 * This contract provides read-only analytics functions for cluster data including:
 * - Paginated cluster listings with gas optimization
 * - Complex node-to-cluster relationship queries
 * - Health monitoring and scoring
 * - Efficient data retrieval for large datasets
 * - Rate-limited expensive operations
 * 
 * All functions are view-only for gas efficiency and focus on data retrieval
 * rather than state modification.
 */
contract ClusterAnalytics is BaseLogic {
    using RateLimitingLibrary for *;

    // =============================================================================
    // STATE VARIABLES
    // =============================================================================
    
    /// @dev Reference to cluster storage contract
    ClusterStorage public clusterStorage;
    
    // =============================================================================
    // EVENTS
    // =============================================================================
    
    /// @dev Emitted when pagination queries are executed for off-chain indexing
    event AnalyticsQuery(
        address indexed caller,
        string indexed queryType,
        uint256 offset,
        uint256 limit,
        uint256 totalResults,
        uint256 timestamp
    );
    
    /// @dev Emitted when health score queries are performed
    event HealthScoreQueried(
        string indexed clusterId,
        uint8 healthScore,
        address indexed caller,
        uint256 timestamp
    );
    
    // =============================================================================
    // CONSTRUCTOR
    // =============================================================================
    
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ANALYTICS_ROLE, msg.sender);
    }
    
    // =============================================================================
    // INITIALIZATION
    // =============================================================================
    
    /**
     * @dev Initialize contract with required storage references
     * @param _nodeStorage Address of the node storage contract
     * @param _userStorage Address of the user storage contract  
     * @param _resourceStorage Address of the resource storage contract
     * @param _admin Address of the admin account
     */
    function initialize(
        address _nodeStorage,
        address _userStorage,
        address _resourceStorage,
        address _admin
    ) external {
        // Initialize base logic with storage contracts
        _initializeBase(_nodeStorage, _userStorage, _resourceStorage, _admin);
        
        // Grant analytics role to admin
        _grantRole(ANALYTICS_ROLE, _admin);
    }
    
    // =============================================================================
    // ADMIN FUNCTIONS
    // =============================================================================
    
    /**
     * @dev Set the cluster storage contract
     * @param _clusterStorage Address of the cluster storage contract
     */
    function setClusterStorage(address _clusterStorage) 
        external 
    {
        require(_clusterStorage != address(0), "ClusterAnalytics: Invalid storage address");
        clusterStorage = ClusterStorage(_clusterStorage);
        
        emit StorageContractUpdated("ClusterStorage", _clusterStorage);
    }
    
    // =============================================================================
    // PAGINATED ANALYTICS FUNCTIONS
    // =============================================================================
    
    /**
     * @dev Paginated query for all cluster IDs with gas optimization
     * @param offset Starting index for pagination
     * @param limit Maximum number of results to return
     * @return clusterIds Array of cluster IDs for current page
     * @return totalCount Total number of clusters available
     * @return hasMore Whether more results are available beyond current page
     */
    function getAllClusterIdsPaginated(uint256 offset, uint256 limit)
        external
        rateLimit("getAllClusterIds", 50, 300) // Max 50 calls per 5 minutes
        returns (
            string[] memory clusterIds,
            uint256 totalCount,
            bool hasMore
        )
    {
        require(address(clusterStorage) != address(0), "ClusterAnalytics: Storage not set");
        
        string[] memory allClusterIds = clusterStorage.getAllClusterIds();
        totalCount = allClusterIds.length;
        
        // Validate and adjust pagination parameters
        uint256 adjustedLimit = GasOptimizationLibrary.validatePagination(offset, limit, totalCount);
        
        if (offset >= totalCount) {
            return (new string[](0), totalCount, false);
        }
        
        // Use gas-optimized array copying
        clusterIds = GasOptimizationLibrary.copyArray(allClusterIds, offset, adjustedLimit);
        hasMore = (offset + adjustedLimit) < totalCount;
        
        // Emit analytics event for off-chain indexing
        emit AnalyticsQuery(
            msg.sender,
            "getAllClusterIds",
            offset,
            adjustedLimit,
            totalCount,
            block.timestamp
        );
    }
    
    /**
     * @dev Get clusters by node address with pagination and advanced filtering
     * @param nodeAddress The node address to search for
     * @param offset Starting index for pagination
     * @param limit Maximum number of results to return
     * @return clusterIds Array of cluster IDs containing the specified node
     * @return totalCount Total number of clusters containing the node
     * @return hasMore Whether more results are available beyond current page
     */
    function getClustersByNodePaginated(address nodeAddress, uint256 offset, uint256 limit)
        external
        rateLimit("getClustersByNode", 30, 300) // Max 30 calls per 5 minutes
        returns (
            string[] memory clusterIds,
            uint256 totalCount,
            bool hasMore
        )
    {
        require(address(clusterStorage) != address(0), "ClusterAnalytics: Storage not set");
        GasOptimizationLibrary.validateAddress(nodeAddress);
        
        // Get all cluster IDs first
        string[] memory allClusterIds = clusterStorage.getAllClusterIds();
        string[] memory nodeClusters = new string[](allClusterIds.length);
        uint256 nodeClusterCount = 0;
        
        // Find clusters that contain this node
        for (uint256 i = 0; i < allClusterIds.length; i++) {
            try clusterStorage.getCluster(allClusterIds[i]) returns (ClusterStorage.NodeCluster memory cluster) {
                // Check if node is in this cluster
                for (uint256 j = 0; j < cluster.nodeAddresses.length; j++) {
                    if (cluster.nodeAddresses[j] == nodeAddress) {
                        nodeClusters[nodeClusterCount] = allClusterIds[i];
                        nodeClusterCount++;
                        break;
                    }
                }
            } catch {
                continue;
            }
        }
        
        // Resize array to actual count
        string[] memory finalNodeClusters = new string[](nodeClusterCount);
        for (uint256 i = 0; i < nodeClusterCount; i++) {
            finalNodeClusters[i] = nodeClusters[i];
        }
        
        totalCount = nodeClusterCount;
        uint256 adjustedLimit = GasOptimizationLibrary.validatePagination(offset, limit, totalCount);
        
        if (offset >= totalCount) {
            return (new string[](0), totalCount, false);
        }
        
        clusterIds = GasOptimizationLibrary.copyArray(finalNodeClusters, offset, adjustedLimit);
        hasMore = (offset + adjustedLimit) < totalCount;
        
        emit AnalyticsQuery(
            msg.sender,
            "getClustersByNode",
            offset,
            adjustedLimit,
            totalCount,
            block.timestamp
        );
    }
    
    // =============================================================================
    // CLUSTER HEALTH ANALYTICS
    // =============================================================================
    
    /**
     * @dev Get cluster health score with monitoring
     * @param clusterId The cluster ID to check
     * @return healthScore The health score (0-100)
     */
    function getClusterHealthScore(string calldata clusterId) 
        external 
        returns (uint8 healthScore) 
    {
        require(address(clusterStorage) != address(0), "ClusterAnalytics: Storage not set");
        require(bytes(clusterId).length > 0, "ClusterAnalytics: Invalid cluster ID");
        
        healthScore = clusterStorage.getClusterHealthScore(clusterId);
        
        emit HealthScoreQueried(clusterId, healthScore, msg.sender, block.timestamp);
    }
    
    /**
     * @dev Get health scores for multiple clusters efficiently
     * @param clusterIds Array of cluster IDs to check
     * @return healthScores Array of health scores corresponding to input clusters
     */
    function batchGetClusterHealthScores(string[] calldata clusterIds)
        external
        rateLimit("batchHealthScores", 20, 300) // Max 20 calls per 5 minutes
        returns (uint8[] memory healthScores)
    {
        require(address(clusterStorage) != address(0), "ClusterAnalytics: Storage not set");
        require(clusterIds.length > 0, "ClusterAnalytics: Empty cluster IDs array");
        require(clusterIds.length <= 100, "ClusterAnalytics: Too many cluster IDs");
        
        healthScores = new uint8[](clusterIds.length);
        
        for (uint256 i = 0; i < clusterIds.length; i++) {
            try clusterStorage.getClusterHealthScore(clusterIds[i]) returns (uint8 score) {
                healthScores[i] = score;
            } catch {
                healthScores[i] = 0; // Default to 0 for invalid clusters
            }
        }
        
        emit AnalyticsQuery(
            msg.sender,
            "batchHealthScores",
            0,
            clusterIds.length,
            clusterIds.length,
            block.timestamp
        );
    }
    
    // =============================================================================
    // ADVANCED ANALYTICS FUNCTIONS
    // =============================================================================
    
    /**
     * @dev Get cluster statistics and analytics
     * @return totalClusters Total number of clusters
     * @return averageHealthScore Average health score across all clusters
     * @return healthyClusterCount Number of clusters with health score >= 80
     * @return unhealthyClusterCount Number of clusters with health score < 50
     */
    function getClusterStatistics()
        external
        rateLimit("clusterStats", 10, 300) // Max 10 calls per 5 minutes
        returns (
            uint256 totalClusters,
            uint256 averageHealthScore,
            uint256 healthyClusterCount,
            uint256 unhealthyClusterCount
        )
    {
        require(address(clusterStorage) != address(0), "ClusterAnalytics: Storage not set");
        
        string[] memory allClusterIds = clusterStorage.getAllClusterIds();
        totalClusters = allClusterIds.length;
        
        if (totalClusters == 0) {
            return (0, 0, 0, 0);
        }
        
        uint256 totalHealthScore = 0;
        healthyClusterCount = 0;
        unhealthyClusterCount = 0;
        
        for (uint256 i = 0; i < allClusterIds.length; i++) {
            try clusterStorage.getClusterHealthScore(allClusterIds[i]) returns (uint8 score) {
                totalHealthScore += score;
                
                if (score >= 80) {
                    healthyClusterCount++;
                } else if (score < 50) {
                    unhealthyClusterCount++;
                }
            } catch {
                unhealthyClusterCount++; // Count invalid clusters as unhealthy
            }
        }
        
        averageHealthScore = totalHealthScore / totalClusters;
        
        emit AnalyticsQuery(
            msg.sender,
            "clusterStats",
            0,
            totalClusters,
            totalClusters,
            block.timestamp
        );
    }
    
    /**
     * @dev Get clusters filtered by health score range
     * @param minHealth Minimum health score (inclusive)
     * @param maxHealth Maximum health score (inclusive)
     * @param offset Starting index for pagination
     * @param limit Maximum number of results to return
     * @return clusterIds Array of cluster IDs within health score range
     * @return totalCount Total number of clusters in the health range
     * @return hasMore Whether more results are available beyond current page
     */
    function getClustersByHealthRange(
        uint8 minHealth,
        uint8 maxHealth,
        uint256 offset,
        uint256 limit
    )
        external
        rateLimit("clustersByHealth", 15, 300) // Max 15 calls per 5 minutes
        returns (
            string[] memory clusterIds,
            uint256 totalCount,
            bool hasMore
        )
    {
        require(address(clusterStorage) != address(0), "ClusterAnalytics: Storage not set");
        require(minHealth <= maxHealth, "ClusterAnalytics: Invalid health range");
        require(maxHealth <= 100, "ClusterAnalytics: Max health cannot exceed 100");
        
        string[] memory allClusterIds = clusterStorage.getAllClusterIds();
        string[] memory filteredClusters = new string[](allClusterIds.length);
        uint256 filteredCount = 0;
        
        // Filter clusters by health score range
        for (uint256 i = 0; i < allClusterIds.length; i++) {
            try clusterStorage.getClusterHealthScore(allClusterIds[i]) returns (uint8 score) {
                if (score >= minHealth && score <= maxHealth) {
                    filteredClusters[filteredCount] = allClusterIds[i];
                    filteredCount++;
                }
            } catch {
                // Skip invalid clusters
                continue;
            }
        }
        
        // Resize to actual count
        string[] memory finalFilteredClusters = new string[](filteredCount);
        for (uint256 i = 0; i < filteredCount; i++) {
            finalFilteredClusters[i] = filteredClusters[i];
        }
        
        totalCount = filteredCount;
        uint256 adjustedLimit = GasOptimizationLibrary.validatePagination(offset, limit, totalCount);
        
        if (offset >= totalCount) {
            return (new string[](0), totalCount, false);
        }
        
        clusterIds = GasOptimizationLibrary.copyArray(finalFilteredClusters, offset, adjustedLimit);
        hasMore = (offset + adjustedLimit) < totalCount;
        
        emit AnalyticsQuery(
            msg.sender,
            "clustersByHealth",
            offset,
            adjustedLimit,
            totalCount,
            block.timestamp
        );
    }
    
    // =============================================================================
    // UTILITY AND SUPPORT FUNCTIONS
    // =============================================================================
    
    /**
     * @dev Get cluster count efficiently
     * @return count Total number of clusters
     */
    function getClusterCount() external view returns (uint256 count) {
        require(address(clusterStorage) != address(0), "ClusterAnalytics: Storage not set");
        
        string[] memory allClusterIds = clusterStorage.getAllClusterIds();
        return allClusterIds.length;
    }
    
    /**
     * @dev Check if a specific node is part of any cluster
     * @param nodeAddress The node address to check
     * @return isActive Whether the node is part of at least one cluster
     * @return clusterCount Number of clusters the node belongs to
     */
    function getNodeClusterStatus(address nodeAddress)
        external
        view
        returns (bool isActive, uint256 clusterCount)
    {
        require(address(clusterStorage) != address(0), "ClusterAnalytics: Storage not set");
        GasOptimizationLibrary.validateAddress(nodeAddress);
        
        string[] memory allClusterIds = clusterStorage.getAllClusterIds();
        clusterCount = 0;
        
        for (uint256 i = 0; i < allClusterIds.length; i++) {
            try clusterStorage.getCluster(allClusterIds[i]) returns (ClusterStorage.NodeCluster memory cluster) {
                for (uint256 j = 0; j < cluster.nodeAddresses.length; j++) {
                    if (cluster.nodeAddresses[j] == nodeAddress) {
                        clusterCount++;
                        break;
                    }
                }
            } catch {
                continue;
            }
        }
        
        isActive = clusterCount > 0;
    }
    
    // =============================================================================
    // ACCESS CONTROL ROLES
    // =============================================================================
    
    bytes32 public constant ANALYTICS_ROLE = keccak256("ANALYTICS_ROLE");
}
