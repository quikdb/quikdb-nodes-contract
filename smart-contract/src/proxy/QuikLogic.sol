// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../interfaces/IResourceTrackingEvents.sol";
import "../storage/NodeStorage.sol";
import "../storage/UserStorage.sol";
import "../storage/ResourceStorage.sol";

/**
 * @title QuikLogic
 * @dev Main logic contract for the QUIK distributed computing platform
 * @notice This contract contains all business logic and can be upgraded via proxy pattern
 * @dev Interacts with separate storage contracts for data persistence
 */
contract QuikLogic is
    AccessControl,
    Pausable,
    ReentrancyGuard,
    IResourceTrackingEvents
{
    // Version for upgrade tracking
    uint256 public constant VERSION = 1;

    // Storage contract addresses
    NodeStorage public nodeStorage;
    UserStorage public userStorage;
    ResourceStorage public resourceStorage;

    // Roles
    bytes32 public constant ADMIN_ROLE = DEFAULT_ADMIN_ROLE;
    bytes32 public constant MARKETPLACE_ROLE = keccak256("MARKETPLACE_ROLE");
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");
    bytes32 public constant NODE_OPERATOR_ROLE =
        keccak256("NODE_OPERATOR_ROLE");
    bytes32 public constant AUTH_SERVICE_ROLE = keccak256("AUTH_SERVICE_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    // Events
    event LogicUpgraded(address indexed newLogic, uint256 version);
    event StorageContractUpdated(string contractType, address newAddress);

    // Node events
    event NodeRegistered(
        string indexed nodeId,
        address indexed nodeAddress,
        uint8 tier,
        uint8 providerType
    );
    event NodeStatusUpdated(string indexed nodeId, uint8 status);
    event NodeListed(
        string indexed nodeId,
        uint256 hourlyRate,
        uint256 availability
    );

    // User events
    event UserRegistered(
        address indexed userAddress,
        bytes32 profileHash,
        uint8 userType,
        uint256 timestamp
    );
    event UserProfileUpdated(
        address indexed userAddress,
        bytes32 profileHash,
        uint256 timestamp
    );

    // Resource events
    event ComputeListingCreated(
        bytes32 indexed listingId,
        string indexed nodeId,
        uint8 tier,
        uint256 hourlyRate
    );
    event StorageListingCreated(
        bytes32 indexed listingId,
        string indexed nodeId,
        uint8 tier,
        uint256 hourlyRate
    );
    event ComputeResourceAllocated(
        bytes32 indexed allocationId,
        address indexed buyer,
        bytes32 indexed listingId,
        uint256 duration
    );

    // Extended events for new functionality
    event NodeExtendedInfoUpdated(string indexed nodeId);

    event NodeAttributeUpdated(string indexed nodeId, string key, string value);

    event NodeCertificationAdded(
        string indexed nodeId,
        bytes32 indexed certificationId
    );

    event NodeVerificationUpdated(
        string indexed nodeId,
        bool isVerified,
        uint256 expiryDate
    );

    event NodeSecurityBondSet(string indexed nodeId, uint256 bondAmount);

    modifier onlyStorageContracts() {
        require(
            msg.sender == address(nodeStorage) ||
                msg.sender == address(userStorage) ||
                msg.sender == address(resourceStorage),
            "Only storage contracts"
        );
        _;
    }

    /**
     * @dev Initialize the logic contract with storage addresses
     * @param _nodeStorage Address of the node storage contract
     * @param _userStorage Address of the user storage contract
     * @param _resourceStorage Address of the resource storage contract
     * @param _admin Address of the admin
     */
    function initialize(
        address _nodeStorage,
        address _userStorage,
        address _resourceStorage,
        address _admin
    ) external {
        require(_admin != address(0), "Invalid admin address");
        require(_nodeStorage != address(0), "Invalid node storage address");
        require(_userStorage != address(0), "Invalid user storage address");
        require(
            _resourceStorage != address(0),
            "Invalid resource storage address"
        );

        // Set up roles
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(UPGRADER_ROLE, _admin);

        // Initialize storage contracts
        nodeStorage = NodeStorage(_nodeStorage);
        userStorage = UserStorage(_userStorage);
        resourceStorage = ResourceStorage(_resourceStorage);
    }

    // =============================================================================
    // NODE MANAGEMENT FUNCTIONS
    // =============================================================================

    /**
     * @dev Register a new node
     * @param nodeId Unique identifier for the node
     * @param nodeAddress Address of the node operator
     * @param tier Tier of the node
     * @param providerType Type of provider (compute/storage)
     */
    function registerNode(
        string calldata nodeId,
        address nodeAddress,
        NodeStorage.NodeTier tier,
        NodeStorage.ProviderType providerType
    ) external whenNotPaused onlyRole(NODE_OPERATOR_ROLE) {
        nodeStorage.registerNode(nodeId, nodeAddress, tier, providerType);

        emit NodeRegistered(
            nodeId,
            nodeAddress,
            uint8(tier),
            uint8(providerType)
        );
    }

    /**
     * @dev Update node status
     * @param nodeId Node identifier
     * @param status New status
     */
    function updateNodeStatus(
        string calldata nodeId,
        NodeStorage.NodeStatus status
    ) external whenNotPaused {
        address nodeAddress = nodeStorage.getNodeAddress(nodeId);
        require(
            msg.sender == nodeAddress || hasRole(ADMIN_ROLE, msg.sender),
            "Not authorized to update node"
        );

        nodeStorage.updateNodeStatus(nodeId, status);
        emit NodeStatusUpdated(nodeId, uint8(status));
    }

    /**
     * @dev List node for provider services
     * @param nodeId Node identifier
     * @param hourlyRate Hourly rate for services
     * @param availability Availability percentage (0-100)
     */
    function listNode(
        string calldata nodeId,
        uint256 hourlyRate,
        uint256 availability
    ) external whenNotPaused {
        address nodeAddress = nodeStorage.getNodeAddress(nodeId);
        require(msg.sender == nodeAddress, "Not node operator");
        require(availability <= 100, "Invalid availability");

        nodeStorage.listNode(nodeId, hourlyRate, availability);
        emit NodeListed(nodeId, hourlyRate, availability);
    }

    /**
     * @dev Get node information
     * @param nodeId Node identifier
     * @return Node information struct
     */
    function getNodeInfo(
        string calldata nodeId
    ) external view returns (NodeStorage.NodeInfo memory) {
        return nodeStorage.getNodeInfo(nodeId);
    }

    // =============================================================================
    // USER MANAGEMENT FUNCTIONS
    // =============================================================================

    /**
     * @dev Register a new user
     * @param userAddress Address of the user
     * @param profileHash Hash of encrypted profile data
     * @param userType Type of user
     */
    function registerUser(
        address userAddress,
        bytes32 profileHash,
        UserStorage.UserType userType
    ) external whenNotPaused onlyRole(AUTH_SERVICE_ROLE) {
        userStorage.registerUser(userAddress, profileHash, userType);

        emit UserRegistered(
            userAddress,
            profileHash,
            uint8(userType),
            block.timestamp
        );
    }

    /**
     * @dev Update user profile
     * @param userAddress Address of the user
     * @param profileHash New profile hash
     */
    function updateUserProfile(
        address userAddress,
        bytes32 profileHash
    ) external whenNotPaused {
        require(
            msg.sender == userAddress || hasRole(ADMIN_ROLE, msg.sender),
            "Not authorized to update profile"
        );

        userStorage.updateUserProfile(userAddress, profileHash);
        emit UserProfileUpdated(userAddress, profileHash, block.timestamp);
    }

    /**
     * @dev Get user profile
     * @param userAddress Address of the user
     * @return User profile struct
     */
    function getUserProfile(
        address userAddress
    ) external view returns (UserStorage.UserProfile memory) {
        return userStorage.getUserProfile(userAddress);
    }

    // =============================================================================
    // RESOURCE MANAGEMENT FUNCTIONS
    // =============================================================================

    /**
     * @dev Create a compute listing
     * @param nodeId Node identifier
     * @param tier Compute tier
     * @param cpuCores Number of CPU cores
     * @param memoryGB Memory in GB
     * @param storageGB Storage in GB
     * @param hourlyRate Hourly rate
     * @param region Geographic region
     * @return listingId Unique listing identifier
     */
    function createComputeListing(
        string calldata nodeId,
        ResourceStorage.ComputeTier tier,
        uint256 cpuCores,
        uint256 memoryGB,
        uint256 storageGB,
        uint256 hourlyRate,
        string calldata region
    ) external whenNotPaused returns (bytes32 listingId) {
        address nodeAddress = nodeStorage.getNodeAddress(nodeId);
        require(msg.sender == nodeAddress, "Not node operator");

        listingId = resourceStorage.createComputeListing(
            nodeId,
            nodeAddress,
            tier,
            cpuCores,
            memoryGB,
            storageGB,
            hourlyRate,
            region
        );

        emit ComputeListingCreated(listingId, nodeId, uint8(tier), hourlyRate);
        return listingId;
    }

    /**
     * @dev Create a storage listing
     * @param nodeId Node identifier
     * @param tier Storage tier
     * @param storageGB Storage capacity in GB
     * @param hourlyRate Hourly rate
     * @param region Geographic region
     * @return listingId Unique listing identifier
     */
    function createStorageListing(
        string calldata nodeId,
        ResourceStorage.StorageTier tier,
        uint256 storageGB,
        uint256 hourlyRate,
        string calldata region
    ) external whenNotPaused returns (bytes32 listingId) {
        address nodeAddress = nodeStorage.getNodeAddress(nodeId);
        require(msg.sender == nodeAddress, "Not node operator");

        listingId = resourceStorage.createStorageListing(
            nodeId,
            nodeAddress,
            tier,
            storageGB,
            hourlyRate,
            region
        );

        emit StorageListingCreated(listingId, nodeId, uint8(tier), hourlyRate);
        return listingId;
    }

    /**
     * @dev Purchase compute resources
     * @param listingId Listing identifier
     * @param duration Duration in hours
     * @return allocationId Resource allocation identifier
     */
    function purchaseCompute(
        bytes32 listingId,
        uint256 duration
    )
        external
        payable
        whenNotPaused
        nonReentrant
        returns (bytes32 allocationId)
    {
        ResourceStorage.ComputeListing memory listing = resourceStorage
            .getComputeListing(listingId);
        require(listing.isActive, "Listing not active");

        uint256 totalCost = listing.hourlyRate * duration;
        require(msg.value >= totalCost, "Insufficient payment");

        allocationId = resourceStorage.allocateCompute(
            listingId,
            msg.sender,
            duration,
            totalCost
        );

        // Refund excess payment
        if (msg.value > totalCost) {
            payable(msg.sender).transfer(msg.value - totalCost);
        }

        emit ComputeResourceAllocated(
            allocationId,
            msg.sender,
            listingId,
            duration
        );
        return allocationId;
    }

    // =============================================================================
    // ADMIN FUNCTIONS
    // =============================================================================

    /**
     * @dev Update storage contract address
     * @param contractType Type of storage contract ("node", "user", "resource")
     * @param newAddress New contract address
     */
    function updateStorageContract(
        string calldata contractType,
        address newAddress
    ) external onlyRole(ADMIN_ROLE) {
        require(newAddress != address(0), "Invalid address");

        if (keccak256(bytes(contractType)) == keccak256(bytes("node"))) {
            nodeStorage = NodeStorage(newAddress);
        } else if (keccak256(bytes(contractType)) == keccak256(bytes("user"))) {
            userStorage = UserStorage(newAddress);
        } else if (
            keccak256(bytes(contractType)) == keccak256(bytes("resource"))
        ) {
            resourceStorage = ResourceStorage(newAddress);
        } else {
            revert("Invalid contract type");
        }

        emit StorageContractUpdated(contractType, newAddress);
    }

    /**
     * @dev Emergency pause
     */
    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    /**
     * @dev Unpause
     */
    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    /**
     * @dev Withdraw contract balance
     */
    function withdraw() external onlyRole(ADMIN_ROLE) {
        payable(msg.sender).transfer(address(this).balance);
    }

    // =============================================================================
    // VIEW FUNCTIONS
    // =============================================================================

    /**
     * @dev Get total statistics
     * @return totalNodes Total number of nodes
     * @return totalUsers Total number of users
     * @return totalAllocations Total number of resource allocations
     */
    function getTotalStats()
        external
        view
        returns (
            uint256 totalNodes,
            uint256 totalUsers,
            uint256 totalAllocations
        )
    {
        totalNodes = nodeStorage.getTotalNodes();
        totalUsers = userStorage.getTotalUsers();
        totalAllocations = resourceStorage.getTotalAllocations();
    }

    // =============================================================================
    // EXTENDED NODE MANAGEMENT FUNCTIONS
    // =============================================================================

    /**
     * @dev Update node extended information
     * @param nodeId Node identifier
     * @param extended Extended information
     */
    function updateNodeExtendedInfo(
        string calldata nodeId,
        NodeStorage.NodeExtendedInfo calldata extended
    ) external whenNotPaused {
        address nodeAddress = nodeStorage.getNodeAddress(nodeId);
        require(
            msg.sender == nodeAddress || hasRole(ADMIN_ROLE, msg.sender),
            "Not authorized to update node"
        );

        nodeStorage.updateNodeExtendedInfo(nodeId, extended);
        emit NodeExtendedInfoUpdated(nodeId);
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
    ) external whenNotPaused {
        address nodeAddress = nodeStorage.getNodeAddress(nodeId);
        require(
            msg.sender == nodeAddress || hasRole(ADMIN_ROLE, msg.sender),
            "Not authorized to update node"
        );

        nodeStorage.setNodeCustomAttribute(nodeId, key, value);
        emit NodeAttributeUpdated(nodeId, key, value);
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
    ) external whenNotPaused {
        address nodeAddress = nodeStorage.getNodeAddress(nodeId);
        require(
            msg.sender == nodeAddress || hasRole(ADMIN_ROLE, msg.sender),
            "Not authorized to update node"
        );

        nodeStorage.addNodeCertification(nodeId, certificationId, details);
        emit NodeCertificationAdded(nodeId, certificationId);
    }

    /**
     * @dev Verify a node (admin only)
     * @param nodeId Node identifier
     * @param isVerified Verification status
     * @param expiryDate Verification expiry date
     */
    function verifyNode(
        string calldata nodeId,
        bool isVerified,
        uint256 expiryDate
    ) external onlyRole(ADMIN_ROLE) {
        NodeStorage.NodeInfo memory nodeInfo = nodeStorage.getNodeInfo(nodeId);

        // Update the verification status in extended info
        NodeStorage.NodeExtendedInfo memory extended = nodeInfo.extended;
        extended.isVerified = isVerified;
        extended.verificationExpiry = expiryDate;

        nodeStorage.updateNodeExtendedInfo(nodeId, extended);
        emit NodeVerificationUpdated(nodeId, isVerified, expiryDate);
    }

    /**
     * @dev Set security bond for a node
     * @param nodeId Node identifier
     * @param bondAmount Bond amount in wei
     */
    function setNodeSecurityBond(
        string calldata nodeId,
        uint256 bondAmount
    ) external payable whenNotPaused nonReentrant {
        address nodeAddress = nodeStorage.getNodeAddress(nodeId);
        require(msg.sender == nodeAddress, "Not node operator");
        require(msg.value >= bondAmount, "Insufficient bond payment");

        nodeStorage.setNodeSecurityBond(nodeId, bondAmount);

        // Refund excess payment
        if (msg.value > bondAmount) {
            payable(msg.sender).transfer(msg.value - bondAmount);
        }

        emit NodeSecurityBondSet(nodeId, bondAmount);
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
        return nodeStorage.getNodeCustomAttribute(nodeId, key);
    }

    /**
     * @dev Get node certifications
     * @param nodeId Node identifier
     * @return Array of certification IDs
     */
    function getNodeCertifications(
        string calldata nodeId
    ) external view returns (bytes32[] memory) {
        return nodeStorage.getNodeCertifications(nodeId);
    }

    /**
     * @dev Get extended statistics
     * @return totalNodes Total number of nodes
     * @return totalUsers Total number of users
     * @return totalAllocations Total number of resource allocations
     * @return verifiedNodes Number of verified nodes
     */
    function getExtendedStats()
        external
        view
        returns (
            uint256 totalNodes,
            uint256 totalUsers,
            uint256 totalAllocations,
            uint256 verifiedNodes
        )
    {
        (
            uint256 total,
            uint256 active,
            uint256 listed,
            uint256 verified
        ) = nodeStorage.getExtendedStats();
        totalNodes = total;
        totalUsers = userStorage.getTotalUsers();
        totalAllocations = resourceStorage.getTotalAllocations();
        verifiedNodes = verified;
    }
}
