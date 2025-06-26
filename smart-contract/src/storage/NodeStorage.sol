// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title NodeStorage
 * @dev Storage contract for node-related data
 * @notice This contract is immutable and stores all node data permanently
 */
contract NodeStorage is AccessControl {
    bytes32 public constant LOGIC_ROLE = keccak256("LOGIC_ROLE");

    // Node status enumeration
    enum NodeStatus {
        PENDING, // Node registered but not verified
        ACTIVE, // Node verified and operational
        INACTIVE, // Node offline or not accepting jobs
        MAINTENANCE, // Node under maintenance
        SUSPENDED, // Node temporarily suspended
        DEREGISTERED, // Node permanently removed
        LISTED // Node actively listed for provider services
    }

    // Provider type enumeration
    enum ProviderType {
        COMPUTE, // Compute provider for computational workloads
        STORAGE // Storage provider for data storage services
    }

    // Node tier enumeration
    enum NodeTier {
        NANO, // Nano tier - very minimal requirements
        MICRO, // Micro tier - minimal requirements
        BASIC, // Basic tier - minimum requirements
        STANDARD, // Standard tier - general purpose
        PREMIUM, // Premium tier - high performance
        ENTERPRISE // Enterprise tier - maximum performance
    }

    // Node capacity structure
    struct NodeCapacity {
        uint256 cpuCores; // Number of CPU cores
        uint256 memoryGB; // Memory in GB
        uint256 storageGB; // Storage in GB
        uint256 networkMbps; // Network speed in Mbps
        uint256 gpuCount; // Number of GPUs (optional)
        string gpuType; // GPU type/model
    }

    // Node metrics structure
    struct NodeMetrics {
        uint256 uptimePercentage; // Uptime percentage (0-10000 for 0.00%-100.00%)
        uint256 totalJobs; // Total jobs completed
        uint256 successfulJobs; // Successfully completed jobs
        uint256 totalEarnings; // Total earnings in wei
        uint256 lastHeartbeat; // Last heartbeat timestamp
        uint256 avgResponseTime; // Average response time in ms
    }

    // Node listing information
    struct NodeListing {
        bool isListed; // Whether node is actively listed
        uint256 hourlyRate; // Hourly rate in wei
        uint256 availability; // Availability percentage (0-100)
        string region; // Geographic region
        string[] supportedServices; // List of supported services
        uint256 minJobDuration; // Minimum job duration in hours
        uint256 maxJobDuration; // Maximum job duration in hours
    }

    // Extended node information (for new features)
    struct NodeExtendedInfo {
        string hardwareFingerprint; // Unique hardware identifier
        uint256 carbonFootprint; // Carbon footprint score
        string[] compliance; // Compliance certifications (SOC2, ISO27001, etc.)
        uint256 securityScore; // Security assessment score (0-10000)
        string operatorBio; // Operator description/bio
        string[] specialCapabilities; // Special hardware/software capabilities
        uint256 bondAmount; // Security bond amount
        bool isVerified; // Professional verification status
        uint256 verificationExpiry; // When verification expires
        string contactInfo; // Encrypted contact information
    }

    // Complete node information
    struct NodeInfo {
        string nodeId;
        address nodeAddress;
        NodeStatus status;
        ProviderType providerType;
        NodeTier tier;
        NodeCapacity capacity;
        NodeMetrics metrics;
        NodeListing listing;
        uint256 registeredAt;
        uint256 lastUpdated;
        bool exists;
        // New fields can be added here for future versions
        NodeExtendedInfo extended; // New extended information
        bytes32[] certifications; // Node certifications
        string[] connectedNetworks; // Networks this node is connected to
    }

    // Storage mappings
    mapping(string => NodeInfo) private nodes;
    mapping(address => string[]) private operatorNodes;
    mapping(NodeTier => string[]) private nodesByTier;
    mapping(ProviderType => string[]) private nodesByProvider;
    mapping(NodeStatus => string[]) private nodesByStatus;

    // New storage mappings for extended data
    mapping(string => mapping(string => string)) private nodeCustomAttributes; // nodeId -> key -> value
    mapping(string => bytes32[]) private nodeCertifications; // nodeId -> certifications
    mapping(string => string[]) private nodeNetworks; // nodeId -> connected networks
    mapping(string => uint256) private nodeSecurityBonds; // nodeId -> bond amount
    mapping(bytes32 => string) private certificationDetails; // certificationId -> details

    // Statistics
    uint256 private totalNodes;
    uint256 private activeNodes;
    uint256 private listedNodes;
    uint256 private verifiedNodes; // New counter for verified nodes

    // Node existence mapping for quick lookups
    mapping(string => bool) private nodeExists;
    mapping(address => bool) private isNodeOperator;

    // Events
    event NodeDataUpdated(string indexed nodeId, string dataType);

    modifier onlyLogic() {
        require(hasRole(LOGIC_ROLE, msg.sender), "Only logic contract");
        _;
    }

    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    /**
     * @dev Set the logic contract address
     * @param logicContract Address of the logic contract
     */
    function setLogicContract(
        address logicContract
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(LOGIC_ROLE, logicContract);
    }

    /**
     * @dev Register a new node
     * @param nodeId Unique identifier for the node
     * @param nodeAddress Address of the node operator
     * @param tier Tier of the node
     * @param providerType Type of provider
     */
    function registerNode(
        string calldata nodeId,
        address nodeAddress,
        NodeTier tier,
        ProviderType providerType
    ) external onlyLogic {
        require(!nodeExists[nodeId], "Node already exists");
        require(nodeAddress != address(0), "Invalid node address");

        NodeInfo storage node = nodes[nodeId];
        node.nodeId = nodeId;
        node.nodeAddress = nodeAddress;
        node.status = NodeStatus.PENDING;
        node.tier = tier;
        node.providerType = providerType;
        node.registeredAt = block.timestamp;
        node.lastUpdated = block.timestamp;
        node.exists = true;

        // Update mappings
        nodeExists[nodeId] = true;
        isNodeOperator[nodeAddress] = true;
        operatorNodes[nodeAddress].push(nodeId);
        nodesByTier[tier].push(nodeId);
        nodesByProvider[providerType].push(nodeId);
        nodesByStatus[NodeStatus.PENDING].push(nodeId);

        totalNodes++;

        emit NodeDataUpdated(nodeId, "registered");
    }

    /**
     * @dev Update node status
     * @param nodeId Node identifier
     * @param status New status
     */
    function _updateNodeStatus(
        string calldata nodeId,
        NodeStatus status
    ) internal {
        require(nodeExists[nodeId], "Node does not exist");

        NodeInfo storage node = nodes[nodeId];
        NodeStatus oldStatus = node.status;
        node.status = status;
        node.lastUpdated = block.timestamp;

        // Update status tracking
        _removeFromStatusArray(nodeId, oldStatus);
        nodesByStatus[status].push(nodeId);

        // Update active nodes count
        if (status == NodeStatus.ACTIVE && oldStatus != NodeStatus.ACTIVE) {
            activeNodes++;
        } else if (
            status != NodeStatus.ACTIVE && oldStatus == NodeStatus.ACTIVE
        ) {
            activeNodes--;
        }

        emit NodeDataUpdated(nodeId, "status");
    }

    function updateNodeStatus(
        string calldata nodeId,
        NodeStatus status
    ) external onlyLogic {
        _updateNodeStatus(nodeId, status);
    }

    /**
     * @dev Update node capacity
     * @param nodeId Node identifier
     * @param capacity New capacity information
     */
    function updateNodeCapacity(
        string calldata nodeId,
        NodeCapacity calldata capacity
    ) external onlyLogic {
        require(nodeExists[nodeId], "Node does not exist");

        nodes[nodeId].capacity = capacity;
        nodes[nodeId].lastUpdated = block.timestamp;

        emit NodeDataUpdated(nodeId, "capacity");
    }

    /**
     * @dev Update node metrics
     * @param nodeId Node identifier
     * @param metrics New metrics information
     */
    function updateNodeMetrics(
        string calldata nodeId,
        NodeMetrics calldata metrics
    ) external onlyLogic {
        require(nodeExists[nodeId], "Node does not exist");

        nodes[nodeId].metrics = metrics;
        nodes[nodeId].lastUpdated = block.timestamp;

        emit NodeDataUpdated(nodeId, "metrics");
    }

    /**
     * @dev List node for provider services
     * @param nodeId Node identifier
     * @param hourlyRate Hourly rate
     * @param availability Availability percentage
     */
    function listNode(
        string calldata nodeId,
        uint256 hourlyRate,
        uint256 availability
    ) external onlyLogic {
        require(nodeExists[nodeId], "Node does not exist");

        NodeInfo storage node = nodes[nodeId];
        require(
            node.status == NodeStatus.ACTIVE,
            "Node must be active to list"
        );

        bool wasListed = node.listing.isListed;
        _updateNodeStatus(nodeId, NodeStatus.LISTED);
        node.listing.isListed = true;
        node.listing.hourlyRate = hourlyRate;
        node.listing.availability = availability;
        node.lastUpdated = block.timestamp;

        if (node.status != NodeStatus.LISTED) {
            _updateNodeStatus(nodeId, NodeStatus.LISTED);
        }

        if (!wasListed) {
            listedNodes++;
        }

        emit NodeDataUpdated(nodeId, "listing");
    }

    /**
     * @dev Unlist node from provider services
     * @param nodeId Node identifier
     */
    function unlistNode(string calldata nodeId) external onlyLogic {
        require(nodeExists[nodeId], "Node does not exist");

        NodeInfo storage node = nodes[nodeId];
        if (node.listing.isListed) {
            node.listing.isListed = false;
            node.lastUpdated = block.timestamp;
            listedNodes--;

            if (node.status == NodeStatus.LISTED) {
                _updateNodeStatus(nodeId, NodeStatus.ACTIVE);
            }

            emit NodeDataUpdated(nodeId, "unlisted");
        }
    }

    // =============================================================================
    // VIEW FUNCTIONS
    // =============================================================================

    /**
     * @dev Get complete node information
     * @param nodeId Node identifier
     * @return Node information struct
     */
    function getNodeInfo(
        string calldata nodeId
    ) external view returns (NodeInfo memory) {
        require(nodeExists[nodeId], "Node does not exist");
        return nodes[nodeId];
    }

    /**
     * @dev Get node address
     * @param nodeId Node identifier
     * @return Address of the node operator
     */
    function getNodeAddress(
        string calldata nodeId
    ) external view returns (address) {
        require(nodeExists[nodeId], "Node does not exist");
        return nodes[nodeId].nodeAddress;
    }

    /**
     * @dev Get node status
     * @param nodeId Node identifier
     * @return Current node status
     */
    function getNodeStatus(
        string calldata nodeId
    ) external view returns (NodeStatus) {
        require(nodeExists[nodeId], "Node does not exist");
        return nodes[nodeId].status;
    }

    /**
     * @dev Get nodes by operator
     * @param operator Address of the node operator
     * @return Array of node IDs
     */
    function getNodesByOperator(
        address operator
    ) external view returns (string[] memory) {
        return operatorNodes[operator];
    }

    /**
     * @dev Get nodes by tier
     * @param tier Node tier
     * @return Array of node IDs
     */
    function getNodesByTier(
        NodeTier tier
    ) external view returns (string[] memory) {
        return nodesByTier[tier];
    }

    /**
     * @dev Get nodes by provider type
     * @param providerType Provider type
     * @return Array of node IDs
     */
    function getNodesByProvider(
        ProviderType providerType
    ) external view returns (string[] memory) {
        return nodesByProvider[providerType];
    }

    /**
     * @dev Get nodes by status
     * @param status Node status
     * @return Array of node IDs
     */
    function getNodesByStatus(
        NodeStatus status
    ) external view returns (string[] memory) {
        return nodesByStatus[status];
    }

    /**
     * @dev Check if node exists
     * @param nodeId Node identifier
     * @return Whether the node exists
     */
    function doesNodeExist(
        string calldata nodeId
    ) external view returns (bool) {
        return nodeExists[nodeId];
    }

    /**
     * @dev Check if address is a node operator
     * @param operator Address to check
     * @return Whether the address is a node operator
     */
    function isOperator(address operator) external view returns (bool) {
        return isNodeOperator[operator];
    }

    /**
     * @dev Get total statistics
     * @return total Total number of nodes
     * @return active Number of active nodes
     * @return listed Number of listed nodes
     */
    function getStats()
        external
        view
        returns (uint256 total, uint256 active, uint256 listed)
    {
        return (totalNodes, activeNodes, listedNodes);
    }

    /**
     * @dev Get total nodes count
     * @return Total number of nodes
     */
    function getTotalNodes() external view returns (uint256) {
        return totalNodes;
    }

    // =============================================================================
    // INTERNAL FUNCTIONS
    // =============================================================================

    /**
     * @dev Remove node from status array
     * @param nodeId Node identifier
     * @param status Status to remove from
     */
    function _removeFromStatusArray(
        string calldata nodeId,
        NodeStatus status
    ) internal {
        string[] storage statusArray = nodesByStatus[status];
        for (uint256 i = 0; i < statusArray.length; i++) {
            if (keccak256(bytes(statusArray[i])) == keccak256(bytes(nodeId))) {
                statusArray[i] = statusArray[statusArray.length - 1];
                statusArray.pop();
                break;
            }
        }
    }

    // =============================================================================
    // EXTENDED DATA MANAGEMENT FUNCTIONS
    // =============================================================================

    /**
     * @dev Update node extended information
     * @param nodeId Node identifier
     * @param extended Extended information struct
     */
    function updateNodeExtendedInfo(
        string calldata nodeId,
        NodeExtendedInfo calldata extended
    ) external onlyLogic {
        require(nodeExists[nodeId], "Node does not exist");

        NodeInfo storage node = nodes[nodeId];
        bool wasVerified = node.extended.isVerified;

        node.extended = extended;
        node.lastUpdated = block.timestamp;

        // Update verified nodes counter
        if (extended.isVerified && !wasVerified) {
            verifiedNodes++;
        } else if (!extended.isVerified && wasVerified) {
            verifiedNodes--;
        }

        emit NodeDataUpdated(nodeId, "extended_info");
    }

    /**
     * @dev Set custom attribute for a node
     * @param nodeId Node identifier
     * @param key Attribute key
     * @param value Attribute value
     */
    function setNodeCustomAttribute(
        string calldata nodeId,
        string calldata key,
        string calldata value
    ) external onlyLogic {
        require(nodeExists[nodeId], "Node does not exist");

        nodeCustomAttributes[nodeId][key] = value;
        nodes[nodeId].lastUpdated = block.timestamp;

        emit NodeDataUpdated(nodeId, "custom_attribute");
    }

    /**
     * @dev Add certification to a node
     * @param nodeId Node identifier
     * @param certificationId Certification identifier
     * @param details Certification details
     */
    function addNodeCertification(
        string calldata nodeId,
        bytes32 certificationId,
        string calldata details
    ) external onlyLogic {
        require(nodeExists[nodeId], "Node does not exist");

        nodeCertifications[nodeId].push(certificationId);
        certificationDetails[certificationId] = details;
        nodes[nodeId].lastUpdated = block.timestamp;

        emit NodeDataUpdated(nodeId, "certification_added");
    }

    /**
     * @dev Remove certification from a node
     * @param nodeId Node identifier
     * @param certificationId Certification identifier
     */
    function removeNodeCertification(
        string calldata nodeId,
        bytes32 certificationId
    ) external onlyLogic {
        require(nodeExists[nodeId], "Node does not exist");

        bytes32[] storage certs = nodeCertifications[nodeId];
        for (uint256 i = 0; i < certs.length; i++) {
            if (certs[i] == certificationId) {
                certs[i] = certs[certs.length - 1];
                certs.pop();
                break;
            }
        }

        nodes[nodeId].lastUpdated = block.timestamp;
        emit NodeDataUpdated(nodeId, "certification_removed");
    }

    /**
     * @dev Add connected network to a node
     * @param nodeId Node identifier
     * @param network Network identifier
     */
    function addNodeNetwork(
        string calldata nodeId,
        string calldata network
    ) external onlyLogic {
        require(nodeExists[nodeId], "Node does not exist");

        nodeNetworks[nodeId].push(network);
        nodes[nodeId].lastUpdated = block.timestamp;

        emit NodeDataUpdated(nodeId, "network_added");
    }

    /**
     * @dev Set security bond for a node
     * @param nodeId Node identifier
     * @param bondAmount Bond amount in wei
     */
    function setNodeSecurityBond(
        string calldata nodeId,
        uint256 bondAmount
    ) external onlyLogic {
        require(nodeExists[nodeId], "Node does not exist");

        nodeSecurityBonds[nodeId] = bondAmount;
        nodes[nodeId].extended.bondAmount = bondAmount;
        nodes[nodeId].lastUpdated = block.timestamp;

        emit NodeDataUpdated(nodeId, "security_bond");
    }

    // =============================================================================
    // EXTENDED VIEW FUNCTIONS
    // =============================================================================

    /**
     * @dev Get node custom attribute
     * @param nodeId Node identifier
     * @param key Attribute key
     * @return Attribute value
     */
    function getNodeCustomAttribute(
        string calldata nodeId,
        string calldata key
    ) external view returns (string memory) {
        require(nodeExists[nodeId], "Node does not exist");
        return nodeCustomAttributes[nodeId][key];
    }

    /**
     * @dev Get all node certifications
     * @param nodeId Node identifier
     * @return Array of certification IDs
     */
    function getNodeCertifications(
        string calldata nodeId
    ) external view returns (bytes32[] memory) {
        require(nodeExists[nodeId], "Node does not exist");
        return nodeCertifications[nodeId];
    }

    /**
     * @dev Get certification details
     * @param certificationId Certification identifier
     * @return Certification details
     */
    function getCertificationDetails(
        bytes32 certificationId
    ) external view returns (string memory) {
        return certificationDetails[certificationId];
    }

    /**
     * @dev Get node connected networks
     * @param nodeId Node identifier
     * @return Array of network identifiers
     */
    function getNodeNetworks(
        string calldata nodeId
    ) external view returns (string[] memory) {
        require(nodeExists[nodeId], "Node does not exist");
        return nodeNetworks[nodeId];
    }

    /**
     * @dev Get node security bond
     * @param nodeId Node identifier
     * @return Bond amount in wei
     */
    function getNodeSecurityBond(
        string calldata nodeId
    ) external view returns (uint256) {
        require(nodeExists[nodeId], "Node does not exist");
        return nodeSecurityBonds[nodeId];
    }

    /**
     * @dev Get nodes by verification status
     * @param verified Whether to get verified or unverified nodes
     * @return Array of node IDs
     */
    function getNodesByVerification(
        bool verified
    ) external view returns (string[] memory) {
        // This is a simple implementation - for production, consider indexing
        string[] memory allNodes = new string[](totalNodes);
        uint256 count = 0;

        // Note: This is inefficient for large datasets
        // Consider maintaining separate verified/unverified indexes
        for (uint256 i = 0; i < totalNodes; i++) {
            // This would need to iterate through all nodes
            // Better to maintain separate mappings for efficient lookup
        }

        // For now, return empty array - implement proper indexing in production
        string[] memory result = new string[](0);
        return result;
    }

    /**
     * @dev Get extended statistics
     * @return total Total number of nodes
     * @return active Number of active nodes
     * @return listed Number of listed nodes
     * @return verified Number of verified nodes
     */
    function getExtendedStats()
        external
        view
        returns (
            uint256 total,
            uint256 active,
            uint256 listed,
            uint256 verified
        )
    {
        return (totalNodes, activeNodes, listedNodes, verifiedNodes);
    }
}
