// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/utils/PausableUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/utils/ReentrancyGuardUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";

/**
 * @title UserNodeRegistry
 * @notice Unified upgradeable contract for managing users, nodes, and applications in QuikDB
 * @dev Simplified architecture that consolidates all core functionality into a single upgradeable contract
 *      - User registration and profile management
 *      - Node registration and metadata
 *      - Application deployment tracking
 *      - Performance metrics
 *      - Batch operations for gas efficiency
 *      - UUPS upgradeable pattern for future improvements
 */
contract UserNodeRegistry is 
    Initializable,
    OwnableUpgradeable, 
    PausableUpgradeable, 
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable {

    // ═══════════════════════════════════════════════════════════════
    // STRUCTS & ENUMS
    // ═══════════════════════════════════════════════════════════════

    enum UserType { CONSUMER, PROVIDER, MARKETPLACE_ADMIN, PLATFORM_ADMIN }
    enum NodeTier { BASIC, PREMIUM, ENTERPRISE }
    enum ProviderType { STORAGE, COMPUTE, HYBRID }
    enum NodeStatus { INACTIVE, ACTIVE, MAINTENANCE, SUSPENDED }
    enum AppStatus { PENDING, RUNNING, STOPPED, FAILED, SCALING }

    struct UserProfile {
        address userAddress;
        bytes32 profileHash;
        UserType userType;
        bool isActive;
        uint256 createdAt;
        uint256 totalSpent;
        uint256 totalEarned;
        uint256 reputationScore;
    }

    struct NodeData {
        address operator;
        bytes32 metadataHash;
        NodeTier tier;
        ProviderType providerType;
        NodeStatus status;
        uint256 registeredAt;
        uint256 lastActiveAt;
        uint256 hourlyRate;
        uint256 uptimePercentage;
        uint256 totalJobs;
        uint256 successfulJobs;
        uint256 totalEarnings;
        bool isListed;
    }

    struct ApplicationDeployment {
        bytes32 appHash;
        address deployer;
        address nodeOperator;
        AppStatus status;
        uint256 deployedAt;
        uint256 replicas;
        uint256 totalCost;
    }

    // ═══════════════════════════════════════════════════════════════
    // STATE VARIABLES
    // ═══════════════════════════════════════════════════════════════

    // User management
    mapping(address => UserProfile) public users;
    mapping(UserType => address[]) public usersByType;
    address[] public allUsers;

    // Node management  
    mapping(address => NodeData) public nodes;
    mapping(NodeTier => address[]) public nodesByTier;
    mapping(ProviderType => address[]) public nodesByType;
    mapping(NodeStatus => address[]) public nodesByStatus;
    address[] public allNodes;

    // Application deployments
    mapping(bytes32 => ApplicationDeployment) public deployments;
    mapping(address => bytes32[]) public userDeployments;
    mapping(address => bytes32[]) public nodeDeployments;
    bytes32[] public allDeployments;

    // Performance tracking
    mapping(address => uint256) public nodeMigrations;
    mapping(address => uint256) public nodeDowntime;

    // Counters
    uint256 public totalUsers;
    uint256 public totalNodes;
    uint256 public totalDeployments;

    // ═══════════════════════════════════════════════════════════════
    // EVENTS
    // ═══════════════════════════════════════════════════════════════

    event UserRegistered(address indexed user, UserType userType, bytes32 profileHash);
    event UsersRegisteredBatch(address[] users, UserType[] userTypes);
    
    event NodeRegistered(address indexed operator, NodeTier tier, ProviderType providerType);
    event NodesRegisteredBatch(address[] operators, NodeTier[] tiers);
    
    event NodeStatusUpdated(address indexed operator, NodeStatus oldStatus, NodeStatus newStatus);
    event NodePerformanceUpdated(address indexed operator, uint256 uptime, uint256 migrations);
    
    event ApplicationDeployed(bytes32 indexed appHash, address indexed deployer, address indexed nodeOperator);
    event ApplicationStatusUpdated(bytes32 indexed appHash, AppStatus oldStatus, AppStatus newStatus);

    // ═══════════════════════════════════════════════════════════════
    // CONSTRUCTOR & INITIALIZER
    // ═══════════════════════════════════════════════════════════════

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initialize the UserNodeRegistry (replaces constructor for upgradeable)
     * @param initialOwner Address that will have owner privileges
     */
    function initialize(address initialOwner) public initializer {
        require(initialOwner != address(0), "Owner cannot be zero address");
        
        // Initialize parent contracts
        __Ownable_init(initialOwner);
        __Pausable_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();
        
        // Initialize counters
        totalUsers = 0;
        totalNodes = 0;
        totalDeployments = 0;
    }

    // ═══════════════════════════════════════════════════════════════
    // USER MANAGEMENT
    // ═══════════════════════════════════════════════════════════════

    /**
     * @notice Register a single user
     * @param user Address of the user
     * @param profileHash IPFS hash of user profile data
     * @param userType Type of user (CONSUMER, PROVIDER, etc.)
     */
    function registerUser(
        address user,
        bytes32 profileHash,
        UserType userType
    ) external whenNotPaused {
        require(user != address(0), "Invalid user address");
        require(!users[user].isActive, "User already registered");

        users[user] = UserProfile({
            userAddress: user,
            profileHash: profileHash,
            userType: userType,
            isActive: true,
            createdAt: block.timestamp,
            totalSpent: 0,
            totalEarned: 0,
            reputationScore: 100 // Default reputation
        });

        usersByType[userType].push(user);
        allUsers.push(user);
        totalUsers++;

        emit UserRegistered(user, userType, profileHash);
    }

    /**
     * @notice Register multiple users in a single transaction
     * @param userAddresses Array of user addresses
     * @param profileHashes Array of profile hashes
     * @param userTypes Array of user types
     */
    function batchRegisterUsers(
        address[] calldata userAddresses,
        bytes32[] calldata profileHashes,
        UserType[] calldata userTypes
    ) external whenNotPaused {
        require(
            userAddresses.length == profileHashes.length && 
            userAddresses.length == userTypes.length,
            "Array length mismatch"
        );
        require(userAddresses.length > 0, "Empty arrays");

        for (uint256 i = 0; i < userAddresses.length; i++) {
            address user = userAddresses[i];
            require(user != address(0), "Invalid user address");
            require(!users[user].isActive, "User already registered");

            users[user] = UserProfile({
                userAddress: user,
                profileHash: profileHashes[i],
                userType: userTypes[i],
                isActive: true,
                createdAt: block.timestamp,
                totalSpent: 0,
                totalEarned: 0,
                reputationScore: 100
            });

            usersByType[userTypes[i]].push(user);
            allUsers.push(user);
        }

        totalUsers += userAddresses.length;
        emit UsersRegisteredBatch(userAddresses, userTypes);
    }

    // ═══════════════════════════════════════════════════════════════
    // NODE MANAGEMENT
    // ═══════════════════════════════════════════════════════════════

    /**
     * @notice Register a single node
     * @param operator Address of the node operator
     * @param metadataHash IPFS hash of node metadata
     * @param tier Node tier (BASIC, PREMIUM, ENTERPRISE)
     * @param providerType Provider type (STORAGE, COMPUTE, HYBRID)
     */
    function registerNode(
        address operator,
        bytes32 metadataHash,
        NodeTier tier,
        ProviderType providerType
    ) external whenNotPaused {
        require(operator != address(0), "Invalid operator address");
        require(nodes[operator].operator == address(0), "Node already registered");

        nodes[operator] = NodeData({
            operator: operator,
            metadataHash: metadataHash,
            tier: tier,
            providerType: providerType,
            status: NodeStatus.INACTIVE,
            registeredAt: block.timestamp,
            lastActiveAt: block.timestamp,
            hourlyRate: 0,
            uptimePercentage: 100,
            totalJobs: 0,
            successfulJobs: 0,
            totalEarnings: 0,
            isListed: false
        });

        nodesByTier[tier].push(operator);
        nodesByType[providerType].push(operator);
        nodesByStatus[NodeStatus.INACTIVE].push(operator);
        allNodes.push(operator);
        totalNodes++;

        emit NodeRegistered(operator, tier, providerType);
    }

    /**
     * @notice Register multiple nodes in a single transaction
     * @param operators Array of node operator addresses
     * @param metadataHashes Array of metadata hashes
     * @param tiers Array of node tiers
     * @param providerTypes Array of provider types
     */
    function batchRegisterNodes(
        address[] calldata operators,
        bytes32[] calldata metadataHashes,
        NodeTier[] calldata tiers,
        ProviderType[] calldata providerTypes
    ) external whenNotPaused {
        require(
            operators.length == metadataHashes.length && 
            operators.length == tiers.length &&
            operators.length == providerTypes.length,
            "Array length mismatch"
        );
        require(operators.length > 0, "Empty arrays");

        for (uint256 i = 0; i < operators.length; i++) {
            address operator = operators[i];
            require(operator != address(0), "Invalid operator address");
            require(nodes[operator].operator == address(0), "Node already registered");

            nodes[operator] = NodeData({
                operator: operator,
                metadataHash: metadataHashes[i],
                tier: tiers[i],
                providerType: providerTypes[i],
                status: NodeStatus.INACTIVE,
                registeredAt: block.timestamp,
                lastActiveAt: block.timestamp,
                hourlyRate: 0,
                uptimePercentage: 100,
                totalJobs: 0,
                successfulJobs: 0,
                totalEarnings: 0,
                isListed: false
            });

            nodesByTier[tiers[i]].push(operator);
            nodesByType[providerTypes[i]].push(operator);
            nodesByStatus[NodeStatus.INACTIVE].push(operator);
            allNodes.push(operator);
        }

        totalNodes += operators.length;
        emit NodesRegisteredBatch(operators, tiers);
    }

    /**
     * @notice Update node status
     * @param operator Node operator address
     * @param newStatus New status for the node
     */
    function updateNodeStatus(
        address operator,
        NodeStatus newStatus
    ) external whenNotPaused {
        require(nodes[operator].operator != address(0), "Node not registered");
        
        NodeStatus oldStatus = nodes[operator].status;
        nodes[operator].status = newStatus;
        nodes[operator].lastActiveAt = block.timestamp;

        emit NodeStatusUpdated(operator, oldStatus, newStatus);
    }

    /**
     * @notice Update node performance metrics
     * @param operator Node operator address
     * @param uptime Uptime percentage (0-100)
     * @param migrations Number of migrations performed
     */
    function updateNodePerformance(
        address operator,
        uint256 uptime,
        uint256 migrations
    ) external whenNotPaused {
        require(nodes[operator].operator != address(0), "Node not registered");
        require(uptime <= 100, "Invalid uptime percentage");

        nodes[operator].uptimePercentage = uptime;
        nodeMigrations[operator] += migrations;

        emit NodePerformanceUpdated(operator, uptime, migrations);
    }

    /**
     * @notice Set node listing status and pricing
     * @param operator Node operator address
     * @param isListed Whether the node is listed for hire
     * @param hourlyRate Hourly rate in wei
     */
    function setNodeListing(
        address operator,
        bool isListed,
        uint256 hourlyRate
    ) external whenNotPaused {
        require(nodes[operator].operator == operator || msg.sender == owner(), "Unauthorized");
        
        nodes[operator].isListed = isListed;
        nodes[operator].hourlyRate = hourlyRate;
    }

    // ═══════════════════════════════════════════════════════════════
    // APPLICATION DEPLOYMENT
    // ═══════════════════════════════════════════════════════════════

    /**
     * @notice Record a new application deployment
     * @param user Deploying user address
     * @param appHash Hash of the application deployment
     * @param nodeOperator Node operator handling the deployment
     * @param replicas Number of replicas
     */
    function recordDeployment(
        address user,
        bytes32 appHash,
        address nodeOperator,
        uint256 replicas
    ) external whenNotPaused {
        require(users[user].isActive, "User not registered");
        require(nodes[nodeOperator].operator != address(0), "Node not registered");
        require(deployments[appHash].deployer == address(0), "Deployment already exists");

        deployments[appHash] = ApplicationDeployment({
            appHash: appHash,
            deployer: user,
            nodeOperator: nodeOperator,
            status: AppStatus.PENDING,
            deployedAt: block.timestamp,
            replicas: replicas,
            totalCost: 0
        });

        userDeployments[user].push(appHash);
        nodeDeployments[nodeOperator].push(appHash);
        allDeployments.push(appHash);
        totalDeployments++;

        // Update node job count
        nodes[nodeOperator].totalJobs++;

        emit ApplicationDeployed(appHash, user, nodeOperator);
    }

    /**
     * @notice Update application deployment status
     * @param appHash Application hash
     * @param newStatus New status
     */
    function updateDeploymentStatus(
        bytes32 appHash,
        AppStatus newStatus
    ) external whenNotPaused {
        ApplicationDeployment storage deployment = deployments[appHash];
        require(deployment.deployer != address(0), "Deployment not found");
        
        AppStatus oldStatus = deployment.status;
        deployment.status = newStatus;

        // Update node success rate if deployment succeeded
        if (newStatus == AppStatus.RUNNING) {
            nodes[deployment.nodeOperator].successfulJobs++;
        }

        emit ApplicationStatusUpdated(appHash, oldStatus, newStatus);
    }

    // ═══════════════════════════════════════════════════════════════
    // VIEW FUNCTIONS
    // ═══════════════════════════════════════════════════════════════

    /**
     * @notice Get user profile data
     * @param user User address
     * @return UserProfile struct
     */
    function getUserProfile(address user) external view returns (UserProfile memory) {
        return users[user];
    }

    /**
     * @notice Get node data
     * @param operator Node operator address
     * @return NodeData struct
     */
    function getNodeData(address operator) external view returns (NodeData memory) {
        return nodes[operator];
    }

    /**
     * @notice Get deployment data
     * @param appHash Application hash
     * @return ApplicationDeployment struct
     */
    function getDeployment(bytes32 appHash) external view returns (ApplicationDeployment memory) {
        return deployments[appHash];
    }

    /**
     * @notice Get all users of a specific type
     * @param userType Type of users to retrieve
     * @return Array of user addresses
     */
    function getUsersByType(UserType userType) external view returns (address[] memory) {
        return usersByType[userType];
    }

    /**
     * @notice Get all nodes of a specific tier
     * @param tier Node tier
     * @return Array of node operator addresses
     */
    function getNodesByTier(NodeTier tier) external view returns (address[] memory) {
        return nodesByTier[tier];
    }

    /**
     * @notice Get all nodes of a specific type
     * @param providerType Provider type
     * @return Array of node operator addresses
     */
    function getNodesByType(ProviderType providerType) external view returns (address[] memory) {
        return nodesByType[providerType];
    }

    /**
     * @notice Get all nodes with a specific status
     * @param status Node status
     * @return Array of node operator addresses
     */
    function getNodesByStatus(NodeStatus status) external view returns (address[] memory) {
        return nodesByStatus[status];
    }

    /**
     * @notice Get user's deployments
     * @param user User address
     * @return Array of deployment hashes
     */
    function getUserDeployments(address user) external view returns (bytes32[] memory) {
        return userDeployments[user];
    }

    /**
     * @notice Get node's deployments
     * @param operator Node operator address
     * @return Array of deployment hashes
     */
    function getNodeDeployments(address operator) external view returns (bytes32[] memory) {
        return nodeDeployments[operator];
    }

    /**
     * @notice Get total statistics
     * @return totalUsers Total number of registered users
     * @return totalNodes Total number of registered nodes
     * @return totalDeployments Total number of deployments
     */
    function getTotalStats() external view returns (uint256, uint256, uint256) {
        return (totalUsers, totalNodes, totalDeployments);
    }

    /**
     * @notice Check if a user is registered
     * @param user User address
     * @return True if user is registered and active
     */
    function isUserRegistered(address user) external view returns (bool) {
        return users[user].isActive;
    }

    /**
     * @notice Check if a node is registered
     * @param operator Node operator address
     * @return True if node is registered
     */
    function isNodeRegistered(address operator) external view returns (bool) {
        return nodes[operator].operator != address(0);
    }

    // ═══════════════════════════════════════════════════════════════
    // ADMIN FUNCTIONS
    // ═══════════════════════════════════════════════════════════════

    /**
     * @notice Pause the contract (emergency use)
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause the contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Update user reputation score (admin only)
     * @param user User address
     * @param newScore New reputation score
     */
    function updateUserReputation(
        address user,
        uint256 newScore
    ) external onlyOwner {
        require(users[user].isActive, "User not registered");
        users[user].reputationScore = newScore;
    }

    /**
     * @notice Emergency withdrawal function (admin only)
     * @param token Token address (0x0 for ETH)
     * @param amount Amount to withdraw
     */
    function emergencyWithdraw(
        address token,
        uint256 amount
    ) external onlyOwner {
        if (token == address(0)) {
            payable(owner()).transfer(amount);
        } else {
            // ERC20 token withdrawal would go here
            // IERC20(token).transfer(owner(), amount);
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // UPGRADE FUNCTIONALITY
    // ═══════════════════════════════════════════════════════════════

    /**
     * @notice Authorization for UUPS upgrades (owner only)
     * @param newImplementation Address of the new implementation
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /**
     * @notice Returns the current implementation version
     * @return Version string
     */
    function version() external pure returns (string memory) {
        return "1.0.0";
    }
}
