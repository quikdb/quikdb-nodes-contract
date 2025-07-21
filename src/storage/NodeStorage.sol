// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "../interfaces/IUserStorage.sol";

/**
 * @title NodeStorage
 * @dev Storage contract for node-related data
 * @notice This contract is immutable and stores all node data permanently
 * @dev Includes cross-contract verification with UserStorage for wallet consistency
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

    // Gas-optimized node capacity with better packing
    struct OptimizedNodeCapacity {
        uint32 cpuCores; // 4 bytes - up to 4B cores
        uint32 ramGB; // 4 bytes - up to 4TB RAM  
        uint32 storageGB; // 4 bytes - up to 4TB storage
        uint32 gpuCount; // 4 bytes - up to 4B GPUs
        // Total: 16 bytes (fits in 1 slot)
        uint64 registeredAt; // 8 bytes
        uint64 lastUpdated; // 8 bytes  
        // Second slot: 16 bytes
        string gpuType; // Dynamic, separate storage
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

    // Gas-optimized node metrics with better packing
    struct OptimizedNodeMetrics {
        uint16 uptimePercentage; // 2 bytes - 0-65535 (0.00%-655.35%)
        uint32 totalJobs; // 4 bytes - up to 4B jobs
        uint32 successfulJobs; // 4 bytes - up to 4B jobs
        uint16 avgResponseTime; // 2 bytes - up to 65s response time
        // Total: 12 bytes
        uint32 padding; // 4 bytes padding to align to 16 bytes
        uint64 totalEarnings; // 8 bytes - scaled by 1e12 for precision
        uint64 lastHeartbeat; // 8 bytes - timestamp
        // Second slot: 16 bytes
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

    // Gas-optimized node listing with better packing
    struct OptimizedNodeListing {
        bool isListed; // 1 byte
        uint8 availability; // 1 byte - 0-100%
        uint16 minJobDuration; // 2 bytes - up to 65k hours
        uint16 maxJobDuration; // 2 bytes - up to 65k hours
        uint16 padding; // 2 bytes padding
        // Total: 8 bytes
        uint64 hourlyRate; // 8 bytes - scaled rate
        // Second part: 8 bytes, total 16 bytes
        string region; // Dynamic storage
        string[] supportedServices; // Dynamic storage
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

    // Cross-contract references for wallet verification
    IUserStorage public userStorage;
    
    // Wallet activity tracking for audit trails
    mapping(address => uint256) private walletLastActivity;           // wallet to last activity timestamp
    mapping(address => uint256) private walletOperationCount;         // wallet to total operations count
    mapping(address => bytes32[]) private walletRecentOperations;     // wallet to recent operation hashes (last 10)
    
    // Rate limiting for wallet operations
    mapping(address => uint256) private walletHourlyOperations;       // wallet to operations in current hour
    mapping(address => uint256) private walletHourlyResetTime;        // wallet to hour reset timestamp
    
    // Wallet-based node statistics
    mapping(address => uint256) private walletActiveNodes;            // wallet to active node count
    mapping(address => uint256) private walletTotalEarnings;          // wallet to total earnings from nodes
    
    // Security parameters
    uint256 private constant MAX_OPERATIONS_PER_HOUR = 15;           // Rate limit for operations per wallet
    uint256 private constant MAX_RECENT_OPERATIONS = 10;             // Maximum recent operations to track
    uint256 private constant MAX_NODES_PER_OPERATOR = 50;            // Maximum nodes per operator

    // Statistics
    uint256 private totalNodes;
    uint256 private activeNodes;
    uint256 private listedNodes;
    uint256 private verifiedNodes; // New counter for verified nodes

    // Node existence mapping for quick lookups
    mapping(string => bool) private nodeExists;
    mapping(address => bool) private isNodeOperator;

    // Enhanced events with wallet address indexing
    event NodeDataUpdated(string indexed nodeId, string dataType);
    
    event WalletOperationPerformed(
        address indexed walletAddress,
        bytes32 indexed operationHash,
        string operationType,
        string nodeId,
        uint256 timestamp
    );
    
    event WalletRateLimitExceeded(
        address indexed walletAddress,
        uint256 operationCount,
        uint256 timestamp
    );
    
    event NodeOperatorRegistered(
        address indexed operatorAddress,
        string indexed nodeId,
        uint256 timestamp
    );

    modifier onlyLogic() {
        require(hasRole(LOGIC_ROLE, msg.sender), "Only logic contract");
        _;
    }

    // Wallet verification modifier
    modifier onlyRegisteredUser(address userAddress) {
        require(address(userStorage) != address(0), "UserStorage not set");
        require(userStorage.isUserRegistered(userAddress), "User not registered");
        _;
    }

    // Rate limiting modifier
    modifier rateLimited(address walletAddress) {
        _checkRateLimit(walletAddress);
        _;
    }

    // Wallet address validation modifier
    modifier validWalletAddress(address walletAddress) {
        require(walletAddress != address(0), "Invalid wallet address");
        require(walletAddress != address(this), "Cannot use contract address");
        _;
    }

    // Node operator limits modifier
    modifier withinNodeLimits(address operatorAddress) {
        require(
            operatorNodes[operatorAddress].length < MAX_NODES_PER_OPERATOR,
            "Maximum nodes per operator exceeded"
        );
        _;
    }

    constructor(address admin) {
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
     * @dev Set the UserStorage contract address for cross-contract verification
     * @param userStorageAddress Address of the UserStorage contract
     */
    function setUserStorage(address userStorageAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(userStorageAddress != address(0), "Invalid UserStorage address");
        userStorage = IUserStorage(userStorageAddress);
    }

    /**
     * @dev Register a new node
     * @param nodeId Unique identifier for the node
     * @param nodeAddress Address of the node operator
     * @param tier Tier of the node
     * @param providerType Type of provider
     */
    function registerNode(string calldata nodeId, address nodeAddress, NodeTier tier, ProviderType providerType)
        external
        onlyLogic
    {
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
    function _updateNodeStatus(string calldata nodeId, NodeStatus status) internal {
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
        } else if (status != NodeStatus.ACTIVE && oldStatus == NodeStatus.ACTIVE) {
            activeNodes--;
        }

        emit NodeDataUpdated(nodeId, "status");
    }

    function updateNodeStatus(string calldata nodeId, NodeStatus status) external onlyLogic {
        _updateNodeStatus(nodeId, status);
    }

    /**
     * @dev Update node capacity
     * @param nodeId Node identifier
     * @param capacity New capacity information
     */
    function updateNodeCapacity(string calldata nodeId, NodeCapacity calldata capacity) external onlyLogic {
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
    function updateNodeMetrics(string calldata nodeId, NodeMetrics calldata metrics) external onlyLogic {
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
    function listNode(string calldata nodeId, uint256 hourlyRate, uint256 availability) external onlyLogic {
        require(nodeExists[nodeId], "Node does not exist");

        NodeInfo storage node = nodes[nodeId];
        require(node.status == NodeStatus.ACTIVE, "Node must be active to list");

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
    function getNodeInfo(string calldata nodeId) external view returns (NodeInfo memory) {
        require(nodeExists[nodeId], "Node does not exist");
        return nodes[nodeId];
    }

    /**
     * @dev Get node address
     * @param nodeId Node identifier
     * @return Address of the node operator
     */
    function getNodeAddress(string calldata nodeId) external view returns (address) {
        require(nodeExists[nodeId], "Node does not exist");
        return nodes[nodeId].nodeAddress;
    }

    /**
     * @dev Get node status
     * @param nodeId Node identifier
     * @return Current node status
     */
    function getNodeStatus(string calldata nodeId) external view returns (NodeStatus) {
        require(nodeExists[nodeId], "Node does not exist");
        return nodes[nodeId].status;
    }

    /**
     * @dev Get nodes by operator
     * @param operator Address of the node operator
     * @return Array of node IDs
     */
    function getNodesByOperator(address operator) external view returns (string[] memory) {
        return operatorNodes[operator];
    }

    /**
     * @dev Get nodes by tier
     * @param tier Node tier
     * @return Array of node IDs
     */
    function getNodesByTier(NodeTier tier) external view returns (string[] memory) {
        return nodesByTier[tier];
    }

    /**
     * @dev Get nodes by provider type
     * @param providerType Provider type
     * @return Array of node IDs
     */
    function getNodesByProvider(ProviderType providerType) external view returns (string[] memory) {
        return nodesByProvider[providerType];
    }

    /**
     * @dev Get nodes by status
     * @param status Node status
     * @return Array of node IDs
     */
    function getNodesByStatus(NodeStatus status) external view returns (string[] memory) {
        return nodesByStatus[status];
    }

    /**
     * @dev Check if node exists
     * @param nodeId Node identifier
     * @return Whether the node exists
     */
    function doesNodeExist(string calldata nodeId) external view returns (bool) {
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
    function getStats() external view returns (uint256 total, uint256 active, uint256 listed) {
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
    function _removeFromStatusArray(string calldata nodeId, NodeStatus status) internal {
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
    function updateNodeExtendedInfo(string calldata nodeId, NodeExtendedInfo calldata extended) external onlyLogic {
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
    function setNodeCustomAttribute(string calldata nodeId, string calldata key, string calldata value)
        external
        onlyLogic
    {
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
    function addNodeCertification(string calldata nodeId, bytes32 certificationId, string calldata details)
        external
        onlyLogic
    {
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
    function removeNodeCertification(string calldata nodeId, bytes32 certificationId) external onlyLogic {
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
    function addNodeNetwork(string calldata nodeId, string calldata network) external onlyLogic {
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
    function setNodeSecurityBond(string calldata nodeId, uint256 bondAmount) external onlyLogic {
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
    function getNodeCustomAttribute(string calldata nodeId, string calldata key)
        external
        view
        returns (string memory)
    {
        require(nodeExists[nodeId], "Node does not exist");
        return nodeCustomAttributes[nodeId][key];
    }

    /**
     * @dev Get all node certifications
     * @param nodeId Node identifier
     * @return Array of certification IDs
     */
    function getNodeCertifications(string calldata nodeId) external view returns (bytes32[] memory) {
        require(nodeExists[nodeId], "Node does not exist");
        return nodeCertifications[nodeId];
    }

    /**
     * @dev Get certification details
     * @param certificationId Certification identifier
     * @return Certification details
     */
    function getCertificationDetails(bytes32 certificationId) external view returns (string memory) {
        return certificationDetails[certificationId];
    }

    /**
     * @dev Get node connected networks
     * @param nodeId Node identifier
     * @return Array of network identifiers
     */
    function getNodeNetworks(string calldata nodeId) external view returns (string[] memory) {
        require(nodeExists[nodeId], "Node does not exist");
        return nodeNetworks[nodeId];
    }

    /**
     * @dev Get node security bond
     * @param nodeId Node identifier
     * @return Bond amount in wei
     */
    function getNodeSecurityBond(string calldata nodeId) external view returns (uint256) {
        require(nodeExists[nodeId], "Node does not exist");
        return nodeSecurityBonds[nodeId];
    }

    /**
     * @dev Get nodes by verification status
     * @dev Note: This function is not fully implemented - returns empty array
     * @return Array of node IDs (currently empty)
     */
    function getNodesByVerification(bool /* verified */ ) external pure returns (string[] memory) {
        // This is a simple implementation - for production, consider indexing
        // Note: Variables commented out to avoid compiler warnings
        // string[] memory allNodes = new string[](totalNodes);
        // uint256 count = 0;

        // Note: This is inefficient for large datasets
        // Consider maintaining separate verified/unverified indexes
        // For now, return empty array as this function is not fully implemented
        return new string[](0);

        // TODO: Implement proper verification-based node filtering
        // This would require maintaining additional indexes for efficiency
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
        returns (uint256 total, uint256 active, uint256 listed, uint256 verified)
    {
        return (totalNodes, activeNodes, listedNodes, verifiedNodes);
    }

    // =============================================================================
    // WALLET CONSISTENCY AND AUDIT TRAIL FUNCTIONS
    // =============================================================================

    /**
     * @dev Get wallet activity statistics
     * @param walletAddress The wallet address to query
     * @return lastActivity Timestamp of last activity
     * @return operationCount Total operations performed
     * @return activeNodesCount Number of active nodes
     * @return totalEarnings Total earnings from nodes
     */
    function getWalletActivity(address walletAddress) 
        external 
        view 
        returns (
            uint256 lastActivity,
            uint256 operationCount,
            uint256 activeNodesCount,
            uint256 totalEarnings
        ) 
    {
        return (
            walletLastActivity[walletAddress],
            walletOperationCount[walletAddress],
            walletActiveNodes[walletAddress],
            walletTotalEarnings[walletAddress]
        );
    }

    /**
     * @dev Check if wallet can perform operations (rate limit check)
     * @param walletAddress The wallet address to check
     * @return canOperate Whether the wallet can perform operations
     * @return operationsLeft Number of operations left in current hour
     */
    function checkWalletRateLimit(address walletAddress) 
        external 
        view 
        returns (bool canOperate, uint256 operationsLeft) 
    {
        // Check if hour has reset
        if (block.timestamp >= walletHourlyResetTime[walletAddress] + 1 hours) {
            return (true, MAX_OPERATIONS_PER_HOUR);
        }
        
        uint256 currentOperations = walletHourlyOperations[walletAddress];
        canOperate = currentOperations < MAX_OPERATIONS_PER_HOUR;
        operationsLeft = canOperate ? MAX_OPERATIONS_PER_HOUR - currentOperations : 0;
        
        return (canOperate, operationsLeft);
    }

    /**
     * @dev Verify wallet is registered and can operate nodes
     * @param walletAddress The wallet address to verify
     * @return isRegistered Whether wallet is registered in UserStorage
     * @return isVerified Whether wallet is verified in UserStorage
     * @return canOperate Whether wallet can operate nodes
     */
    function verifyWalletStatus(address walletAddress) 
        external 
        view 
        returns (bool isRegistered, bool isVerified, bool canOperate) 
    {
        if (address(userStorage) == address(0)) {
            return (false, false, false);
        }
        
        isRegistered = userStorage.isUserRegistered(walletAddress);
        isVerified = userStorage.isUserVerified(walletAddress);
        canOperate = isRegistered; // Can operate if registered
        
        return (isRegistered, isVerified, canOperate);
    }

    // =============================================================================
    // INTERNAL HELPER FUNCTIONS
    // =============================================================================

    /**
     * @dev Internal function to check and enforce rate limiting
     * @param walletAddress The wallet address to check
     */
    function _checkRateLimit(address walletAddress) internal {
        uint256 currentTime = block.timestamp;
        uint256 resetTime = walletHourlyResetTime[walletAddress];
        
        // Reset counter if hour has passed
        if (currentTime >= resetTime + 1 hours) {
            walletHourlyOperations[walletAddress] = 0;
            walletHourlyResetTime[walletAddress] = currentTime;
        }
        
        require(
            walletHourlyOperations[walletAddress] < MAX_OPERATIONS_PER_HOUR,
            "Rate limit exceeded for wallet"
        );
        
        walletHourlyOperations[walletAddress]++;
        
        // Emit rate limit warning if close to limit
        if (walletHourlyOperations[walletAddress] >= MAX_OPERATIONS_PER_HOUR - 2) {
            emit WalletRateLimitExceeded(
                walletAddress,
                walletHourlyOperations[walletAddress],
                currentTime
            );
        }
    }

    /**
     * @dev Internal function to update wallet activity tracking
     * @param walletAddress The wallet address
     * @param operationType Type of operation performed
     * @param nodeId Related node ID
     */
    function _updateWalletActivity(
        address walletAddress,
        string memory operationType,
        string memory nodeId
    ) internal {
        walletLastActivity[walletAddress] = block.timestamp;
        walletOperationCount[walletAddress]++;
        
        // Generate operation hash for tracking
        bytes32 operationHash = keccak256(
            abi.encodePacked(
                walletAddress,
                operationType,
                nodeId,
                block.timestamp,
                walletOperationCount[walletAddress]
            )
        );
        
        // Add to recent operations (maintain only last MAX_RECENT_OPERATIONS)
        bytes32[] storage recentOps = walletRecentOperations[walletAddress];
        if (recentOps.length >= MAX_RECENT_OPERATIONS) {
            // Shift array left to remove oldest operation
            for (uint256 i = 0; i < MAX_RECENT_OPERATIONS - 1; i++) {
                recentOps[i] = recentOps[i + 1];
            }
            recentOps[MAX_RECENT_OPERATIONS - 1] = operationHash;
        } else {
            recentOps.push(operationHash);
        }
        
        emit WalletOperationPerformed(
            walletAddress,
            operationHash,
            operationType,
            nodeId,
            block.timestamp
        );
    }
}
