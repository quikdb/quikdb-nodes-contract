// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title PerformanceStorage
 * @notice Storage contract for node performance metrics data
 * @dev This contract contains only storage layout and structs for the performance tracking system.
 *      It follows the proxy pattern where logic is separated from storage.
 */
contract PerformanceStorage is AccessControl {
    // Role for logic contracts that can modify storage
    bytes32 public constant LOGIC_ROLE = keccak256("LOGIC_ROLE");

    // Daily performance metrics structure
    struct DailyMetrics {
        string nodeId; // Node identifier
        uint256 date; // Date in UNIX timestamp (start of day)
        uint16 uptime; // Uptime percentage (0-10000, where 10000 = 100%)
        uint32 responseTime; // Average response time in milliseconds
        uint32 throughput; // Throughput in operations per second
        uint64 storageUsed; // Storage used in bytes
        uint16 networkLatency; // Average network latency in milliseconds
        uint16 errorRate; // Error rate (0-10000, where 10000 = 100%)
        uint8 dailyScore; // Overall daily performance score (0-100)
    }

    // Storage mappings
    mapping(string => mapping(uint256 => DailyMetrics)) public nodeMetrics; // nodeId => date => DailyMetrics
    mapping(string => mapping(uint256 => bool)) public metricExists; // nodeId => date => exists
    mapping(string => uint256[]) public nodeDates; // nodeId => dates[] for enumeration
    mapping(uint256 => string[]) public dateNodes; // date => nodeIds[] for enumeration

    // Additional useful mappings for efficient queries
    mapping(string => uint256) public nodeMetricCount; // nodeId => total metrics count
    mapping(string => uint256) public nodeLastMetricDate; // nodeId => latest date with metrics
    mapping(string => uint256) public nodeFirstMetricDate; // nodeId => earliest date with metrics

    // Statistics tracking
    uint256 public totalMetricsRecorded; // Total number of metrics recorded across all nodes
    uint256 public totalNodesWithMetrics; // Total number of unique nodes with at least one metric

    // Events
    event DailyMetricsRecorded(
        string indexed nodeId,
        uint256 indexed date,
        uint16 uptime,
        uint32 responseTime,
        uint32 throughput,
        uint64 storageUsed,
        uint16 networkLatency,
        uint16 errorRate,
        uint8 dailyScore,
        uint256 timestamp
    );

    event NodeFirstMetricRecorded(string indexed nodeId, uint256 indexed date, uint256 timestamp);

    event NodeMetricUpdated(
        string indexed nodeId,
        uint256 indexed date,
        uint8 oldScore,
        uint8 newScore,
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
     * @dev Get daily metrics for a node on a specific date
     * @param nodeId Node identifier
     * @param date Date in UNIX timestamp
     * @return DailyMetrics struct containing performance data
     */
    function getDailyMetrics(string calldata nodeId, uint256 date) external view returns (DailyMetrics memory) {
        require(metricExists[nodeId][date], "Metrics do not exist for this date");
        return nodeMetrics[nodeId][date];
    }

    /**
     * @dev Check if metrics exist for a node on a specific date
     * @param nodeId Node identifier
     * @param date Date in UNIX timestamp
     * @return Whether metrics exist
     */
    function doMetricsExist(string calldata nodeId, uint256 date) external view returns (bool) {
        return metricExists[nodeId][date];
    }

    /**
     * @dev Get all dates with metrics for a specific node
     * @param nodeId Node identifier
     * @return Array of dates (UNIX timestamps)
     */
    function getNodeMetricDates(string calldata nodeId) external view returns (uint256[] memory) {
        return nodeDates[nodeId];
    }

    /**
     * @dev Get all nodes with metrics for a specific date
     * @param date Date in UNIX timestamp
     * @return Array of node IDs
     */
    function getNodesForDate(uint256 date) external view returns (string[] memory) {
        return dateNodes[date];
    }

    /**
     * @dev Get metric count for a specific node
     * @param nodeId Node identifier
     * @return Number of metrics recorded for the node
     */
    function getNodeMetricCount(string calldata nodeId) external view returns (uint256) {
        return nodeMetricCount[nodeId];
    }

    /**
     * @dev Get the date range for a node's metrics
     * @param nodeId Node identifier
     * @return firstDate Earliest date with metrics
     * @return lastDate Latest date with metrics
     */
    function getNodeDateRange(string calldata nodeId) external view returns (uint256 firstDate, uint256 lastDate) {
        firstDate = nodeFirstMetricDate[nodeId];
        lastDate = nodeLastMetricDate[nodeId];
    }

    /**
     * @dev Get performance statistics
     * @return totalMetrics Total number of metrics recorded
     * @return totalNodes Total number of nodes with metrics
     */
    function getPerformanceStats() external view returns (uint256 totalMetrics, uint256 totalNodes) {
        totalMetrics = totalMetricsRecorded;
        totalNodes = totalNodesWithMetrics;
    }

    /**
     * @dev Get multiple daily metrics for a node within a date range
     * @param nodeId Node identifier
     * @param startDate Start date (inclusive)
     * @param endDate End date (inclusive)
     * @return metrics Array of DailyMetrics structs
     * @return dates Array of corresponding dates
     */
    function getNodeMetricsInRange(string calldata nodeId, uint256 startDate, uint256 endDate)
        external
        view
        returns (DailyMetrics[] memory metrics, uint256[] memory dates)
    {
        uint256[] memory allDates = nodeDates[nodeId];
        uint256 count = 0;

        // Count metrics in range
        for (uint256 i = 0; i < allDates.length; i++) {
            if (allDates[i] >= startDate && allDates[i] <= endDate) {
                count++;
            }
        }

        // Allocate arrays
        metrics = new DailyMetrics[](count);
        dates = new uint256[](count);

        // Fill arrays
        uint256 index = 0;
        for (uint256 i = 0; i < allDates.length; i++) {
            if (allDates[i] >= startDate && allDates[i] <= endDate) {
                dates[index] = allDates[i];
                metrics[index] = nodeMetrics[nodeId][allDates[i]];
                index++;
            }
        }
    }

    /**
     * @dev Record daily metrics for a node (called by logic contract)
     * @param nodeId Node identifier
     * @param metrics DailyMetrics struct with performance data
     */
    function recordDailyMetrics(string calldata nodeId, DailyMetrics calldata metrics) external onlyLogic {
        require(bytes(nodeId).length > 0, "Invalid node ID");
        require(metrics.date > 0, "Invalid date");
        require(bytes(metrics.nodeId).length > 0, "Invalid metrics node ID");
        require(
            keccak256(bytes(nodeId)) == keccak256(bytes(metrics.nodeId)), "Node ID mismatch in metrics"
        );

        uint256 date = metrics.date;
        bool isNewMetric = !metricExists[nodeId][date];
        bool isFirstMetricForNode = nodeMetricCount[nodeId] == 0;

        // Store metrics
        nodeMetrics[nodeId][date] = metrics;
        metricExists[nodeId][date] = true;

        // Update tracking data
        if (isNewMetric) {
            nodeDates[nodeId].push(date);
            dateNodes[date].push(nodeId);
            nodeMetricCount[nodeId]++;
            totalMetricsRecorded++;

            // Update date range tracking
            if (isFirstMetricForNode) {
                nodeFirstMetricDate[nodeId] = date;
                nodeLastMetricDate[nodeId] = date;
                totalNodesWithMetrics++;
                
                emit NodeFirstMetricRecorded(nodeId, date, block.timestamp);
            } else {
                if (date < nodeFirstMetricDate[nodeId]) {
                    nodeFirstMetricDate[nodeId] = date;
                }
                if (date > nodeLastMetricDate[nodeId]) {
                    nodeLastMetricDate[nodeId] = date;
                }
            }
        }

        emit DailyMetricsRecorded(
            nodeId,
            date,
            metrics.uptime,
            metrics.responseTime,
            metrics.throughput,
            metrics.storageUsed,
            metrics.networkLatency,
            metrics.errorRate,
            metrics.dailyScore,
            block.timestamp
        );
    }

    /**
     * @dev Update existing daily metrics for a node (called by logic contract)
     * @param nodeId Node identifier
     * @param date Date to update
     * @param metrics Updated DailyMetrics struct
     */
    function updateDailyMetrics(string calldata nodeId, uint256 date, DailyMetrics calldata metrics)
        external
        onlyLogic
    {
        require(metricExists[nodeId][date], "Metrics do not exist for this date");
        require(
            keccak256(bytes(nodeId)) == keccak256(bytes(metrics.nodeId)), "Node ID mismatch in metrics"
        );
        require(metrics.date == date, "Date mismatch in metrics");

        uint8 oldScore = nodeMetrics[nodeId][date].dailyScore;
        nodeMetrics[nodeId][date] = metrics;

        emit NodeMetricUpdated(nodeId, date, oldScore, metrics.dailyScore, block.timestamp);
        
        emit DailyMetricsRecorded(
            nodeId,
            date,
            metrics.uptime,
            metrics.responseTime,
            metrics.throughput,
            metrics.storageUsed,
            metrics.networkLatency,
            metrics.errorRate,
            metrics.dailyScore,
            block.timestamp
        );
    }
}
