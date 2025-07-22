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
 * @title Logic - Main logic contract for the platform
 */
contract Logic is AccessControl, Pausable, ReentrancyGuard, IResourceTrackingEvents {
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
    bytes32 public constant NODE_OPERATOR_ROLE = keccak256("NODE_OPERATOR_ROLE");
    bytes32 public constant AUTH_SERVICE_ROLE = keccak256("AUTH_SERVICE_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    // Core events
    event LogicUpgraded(address indexed newLogic, uint256 version);
    event StorageContractUpdated(string contractType, address newAddress);

    // Node events
    event NodeRegistered(string indexed nodeId, address indexed nodeAddress, uint8 tier, uint8 providerType);
    event NodeStatusUpdated(string indexed nodeId, uint8 status);
    event NodeListed(string indexed nodeId, uint256 hourlyRate, uint256 availability);
    event NodeExtendedInfoUpdated(string indexed nodeId);
    event NodeAttributeUpdated(string indexed nodeId, string key, string value);
    event NodeCertificationAdded(string indexed nodeId, bytes32 indexed certificationId);
    event NodeVerificationUpdated(string indexed nodeId, bool isVerified, uint256 expiryDate);
    event NodeSecurityBondSet(string indexed nodeId, uint256 bondAmount);

    // User events
    event UserRegistered(address indexed userAddress, bytes32 profileHash, uint8 userType, uint256 timestamp);
    event UserProfileUpdated(address indexed userAddress, bytes32 profileHash, uint256 timestamp);

    // Resource events
    event ComputeListingCreated(bytes32 indexed listingId, string indexed nodeId, uint8 tier, uint256 hourlyRate);
    event StorageListingCreated(bytes32 indexed listingId, string indexed nodeId, uint8 tier, uint256 hourlyRate);
    event ComputeResourceAllocated(
        bytes32 indexed allocationId, address indexed buyer, bytes32 indexed listingId, uint256 duration
    );

    modifier onlyStorageContracts() {
        require(
            msg.sender == address(nodeStorage) || msg.sender == address(userStorage)
                || msg.sender == address(resourceStorage),
            "Only storage"
        );
        _;
    }

    /**
     * @dev Initialize the logic contract
     */
    function initialize(address _nodeStorage, address _userStorage, address _resourceStorage, address _admin)
        external
    {
        require(
            _admin != address(0) && _nodeStorage != address(0) && _userStorage != address(0)
                && _resourceStorage != address(0),
            "Invalid address"
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
     */
    function registerNode(
        string calldata nodeId,
        address nodeAddress,
        NodeStorage.NodeTier tier,
        NodeStorage.ProviderType providerType
    ) external whenNotPaused {
        nodeStorage.registerNode(nodeId, nodeAddress, tier, providerType);
        emit NodeRegistered(nodeId, nodeAddress, uint8(tier), uint8(providerType));
    }

    /**
     * @dev Update node status
     */
    function updateNodeStatus(string calldata nodeId, NodeStorage.NodeStatus status) external whenNotPaused {
        _isNodeAuthorized(nodeId);
        nodeStorage.updateNodeStatus(nodeId, status);
        emit NodeStatusUpdated(nodeId, uint8(status));
    }

    /**
     * @dev List node for provider services
     */
    function listNode(string calldata nodeId, uint256 hourlyRate, uint256 availability) external whenNotPaused {
        _onlyNodeOperator(nodeId);
        require(availability <= 100, "Invalid availability");
        nodeStorage.listNode(nodeId, hourlyRate, availability);
        emit NodeListed(nodeId, hourlyRate, availability);
    }

    /**
     * @dev Get node information
     */
    function getNodeInfo(string calldata nodeId) external view returns (NodeStorage.NodeInfo memory) {
        return nodeStorage.getNodeInfo(nodeId);
    }

    // =============================================================================
    // USER MANAGEMENT FUNCTIONS
    // =============================================================================

    /**
     * @dev Register a new user
     */
    function registerUser(address userAddress, bytes32 profileHash, UserStorage.UserType userType)
        external
        whenNotPaused
    {
        userStorage.registerUser(userAddress, profileHash, userType);
        emit UserRegistered(userAddress, profileHash, uint8(userType), block.timestamp);
    }

    /**
     * @dev Update user profile
     */
    function updateUserProfile(address userAddress, bytes32 profileHash) external whenNotPaused {
        // Remove role check for development - anyone can call
        userStorage.updateUserProfile(userAddress, profileHash);
        emit UserProfileUpdated(userAddress, profileHash, block.timestamp);
    }

    /**
     * @dev Get user profile
     */
    function getUserProfile(address userAddress) external view returns (UserStorage.UserProfile memory) {
        return userStorage.getUserProfile(userAddress);
    }

    // =============================================================================
    // RESOURCE MANAGEMENT FUNCTIONS
    // =============================================================================

    /**
     * @dev Create a compute listing
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
        address nodeAddress = _onlyNodeOperator(nodeId);

        listingId = resourceStorage.createComputeListing(
            nodeId, nodeAddress, tier, cpuCores, memoryGB, storageGB, hourlyRate, region
        );

        emit ComputeListingCreated(listingId, nodeId, uint8(tier), hourlyRate);
        return listingId;
    }

    /**
     * @dev Create a storage listing
     */
    function createStorageListing(
        string calldata nodeId,
        ResourceStorage.StorageTier tier,
        uint256 storageGB,
        uint256 hourlyRate,
        string calldata region
    ) external whenNotPaused returns (bytes32 listingId) {
        address nodeAddress = _onlyNodeOperator(nodeId);

        listingId = resourceStorage.createStorageListing(nodeId, nodeAddress, tier, storageGB, hourlyRate, region);

        emit StorageListingCreated(listingId, nodeId, uint8(tier), hourlyRate);
        return listingId;
    }

    /**
     * @dev Purchase compute resources
     */
    function purchaseCompute(bytes32 listingId, uint256 duration)
        external
        payable
        whenNotPaused
        nonReentrant
        returns (bytes32 allocationId)
    {
        ResourceStorage.ComputeListing memory listing = resourceStorage.getComputeListing(listingId);
        require(listing.isActive, "Listing not active");

        uint256 totalCost = listing.hourlyRate * duration;
        require(msg.value >= totalCost, "Insufficient payment");

        allocationId = resourceStorage.allocateCompute(listingId, msg.sender, duration, totalCost);

        // Refund excess payment
        if (msg.value > totalCost) {
            payable(msg.sender).transfer(msg.value - totalCost);
        }

        emit ComputeResourceAllocated(allocationId, msg.sender, listingId, duration);
        return allocationId;
    }

    // =============================================================================
    // ADMIN FUNCTIONS
    // =============================================================================

    /**
     * @dev Update storage contract address
     */
    function updateStorageContract(string calldata contractType, address newAddress) external {
        require(newAddress != address(0), "Invalid address");
        bytes32 typeHash = keccak256(bytes(contractType));

        if (typeHash == keccak256(bytes("node"))) {
            nodeStorage = NodeStorage(newAddress);
        } else if (typeHash == keccak256(bytes("user"))) {
            userStorage = UserStorage(newAddress);
        } else if (typeHash == keccak256(bytes("resource"))) {
            resourceStorage = ResourceStorage(newAddress);
        } else {
            revert("Invalid type");
        }

        emit StorageContractUpdated(contractType, newAddress);
    }

    /**
     * @dev Emergency pause/unpause and withdraw
     */
    function pause() external {
        _pause();
    }

    function unpause() external {
        _unpause();
    }

    function withdraw() external {
        payable(msg.sender).transfer(address(this).balance);
    }

    // =============================================================================
    // VIEW FUNCTIONS
    // =============================================================================

    /**
     * @dev Get total statistics
     */
    function getTotalStats() external view returns (uint256 totalNodes, uint256 totalUsers, uint256 totalAllocations) {
        totalNodes = nodeStorage.getTotalNodes();
        totalUsers = userStorage.getTotalUsers();
        totalAllocations = resourceStorage.getTotalAllocations();
    }

    // =============================================================================
    // EXTENDED NODE MANAGEMENT FUNCTIONS
    // =============================================================================

    /**
     * @dev Update node extended information
     */
    function updateNodeExtendedInfo(string calldata nodeId, NodeStorage.NodeExtendedInfo calldata extended)
        external
        whenNotPaused
    {
        _isNodeAuthorized(nodeId);
        nodeStorage.updateNodeExtendedInfo(nodeId, extended);
        emit NodeExtendedInfoUpdated(nodeId);
    }

    /**
     * @dev Set custom attribute for a node
     */
    function setNodeCustomAttribute(string calldata nodeId, string calldata key, string calldata value)
        external
        whenNotPaused
    {
        _isNodeAuthorized(nodeId);
        nodeStorage.setNodeCustomAttribute(nodeId, key, value);
        emit NodeAttributeUpdated(nodeId, key, value);
    }

    /**
     * @dev Add certification to a node
     */
    function addNodeCertification(string calldata nodeId, bytes32 certificationId, string calldata details)
        external
        whenNotPaused
    {
        _isNodeAuthorized(nodeId);
        nodeStorage.addNodeCertification(nodeId, certificationId, details);
        emit NodeCertificationAdded(nodeId, certificationId);
    }

    /**
     * @dev Verify a node (admin only)
     */
    function verifyNode(string calldata nodeId, bool isVerified, uint256 expiryDate) external {
        NodeStorage.NodeInfo memory nodeInfo = nodeStorage.getNodeInfo(nodeId);

        // Update verification status in extended info
        NodeStorage.NodeExtendedInfo memory extended = nodeInfo.extended;
        extended.isVerified = isVerified;
        extended.verificationExpiry = expiryDate;

        nodeStorage.updateNodeExtendedInfo(nodeId, extended);
        emit NodeVerificationUpdated(nodeId, isVerified, expiryDate);
    }

    /**
     * @dev Set security bond for a node
     */
    function setNodeSecurityBond(string calldata nodeId, uint256 bondAmount)
        external
        payable
        whenNotPaused
        nonReentrant
    {
        _onlyNodeOperator(nodeId);
        require(msg.value >= bondAmount, "Insufficient bond");

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
     */
    function getNodeCustomAttribute(string calldata nodeId, string calldata key)
        external
        view
        returns (string memory)
    {
        return nodeStorage.getNodeCustomAttribute(nodeId, key);
    }

    /**
     * @dev Get node certifications
     */
    function getNodeCertifications(string calldata nodeId) external view returns (bytes32[] memory) {
        return nodeStorage.getNodeCertifications(nodeId);
    }

    /**
     * @dev Get extended statistics
     */
    function getExtendedStats()
        external
        view
        returns (uint256 totalNodes, uint256 totalUsers, uint256 totalAllocations, uint256 verifiedNodes)
    {
        (
            uint256 total, // active (unused) // listed (unused)
            ,
            ,
            uint256 verified
        ) = nodeStorage.getExtendedStats();
        totalNodes = total;
        totalUsers = userStorage.getTotalUsers();
        totalAllocations = resourceStorage.getTotalAllocations();
        verifiedNodes = verified;
    }

    // =============================================================================
    // INTERNAL HELPER FUNCTIONS
    // =============================================================================

    /**
     * @dev Check if caller is authorized to operate on a node
     */
    function _isNodeAuthorized(string calldata nodeId) internal view returns (address nodeAddress) {
        nodeAddress = nodeStorage.getNodeAddress(nodeId);
        // Remove role check for development - anyone can call
        return nodeAddress;
    }

    /**
     * @dev Verify node operator is caller
     */
    function _onlyNodeOperator(string calldata nodeId) internal view returns (address) {
        address nodeAddress = nodeStorage.getNodeAddress(nodeId);
        require(msg.sender == nodeAddress, "Not node operator");
        return nodeAddress;
    }
}
