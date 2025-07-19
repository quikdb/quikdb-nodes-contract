// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./BaseLogic.sol";

/**
 * @title NodeLogic - Node management logic
 */
contract NodeLogic is BaseLogic {
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

    /**
     * @dev Initialize the node logic contract
     */
    function initialize(
        address _nodeStorage,
        address _userStorage,
        address _resourceStorage,
        address _admin
    ) external {
        _initializeBase(_nodeStorage, _userStorage, _resourceStorage, _admin);
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
     */
    function updateNodeStatus(
        string calldata nodeId,
        NodeStorage.NodeStatus status
    ) external whenNotPaused {
        _isNodeAuthorized(nodeId);
        nodeStorage.updateNodeStatus(nodeId, status);
        emit NodeStatusUpdated(nodeId, uint8(status));
    }

    /**
     * @dev List node for provider services
     */
    function listNode(
        string calldata nodeId,
        uint256 hourlyRate,
        uint256 availability
    ) external whenNotPaused {
        _onlyNodeOperator(nodeId);
        require(availability <= 100, "Invalid availability");
        nodeStorage.listNode(nodeId, hourlyRate, availability);
        emit NodeListed(nodeId, hourlyRate, availability);
    }

    /**
     * @dev Get node information
     */
    function getNodeInfo(
        string calldata nodeId
    ) external view returns (NodeStorage.NodeInfo memory) {
        return nodeStorage.getNodeInfo(nodeId);
    }

    // =============================================================================
    // EXTENDED NODE MANAGEMENT FUNCTIONS
    // =============================================================================

    /**
     * @dev Update node extended information
     */
    function updateNodeExtendedInfo(
        string calldata nodeId,
        NodeStorage.NodeExtendedInfo calldata extended
    ) external whenNotPaused {
        _isNodeAuthorized(nodeId);
        nodeStorage.updateNodeExtendedInfo(nodeId, extended);
        emit NodeExtendedInfoUpdated(nodeId);
    }

    /**
     * @dev Set custom attribute for a node
     */
    function setNodeCustomAttribute(
        string calldata nodeId,
        string calldata key,
        string calldata value
    ) external whenNotPaused {
        _isNodeAuthorized(nodeId);
        nodeStorage.setNodeCustomAttribute(nodeId, key, value);
        emit NodeAttributeUpdated(nodeId, key, value);
    }

    /**
     * @dev Add certification to a node
     */
    function addNodeCertification(
        string calldata nodeId,
        bytes32 certificationId,
        string calldata details
    ) external whenNotPaused {
        _isNodeAuthorized(nodeId);
        nodeStorage.addNodeCertification(nodeId, certificationId, details);
        emit NodeCertificationAdded(nodeId, certificationId);
    }

    /**
     * @dev Verify a node (admin only)
     */
    function verifyNode(
        string calldata nodeId,
        bool isVerified,
        uint256 expiryDate
    ) external onlyRole(ADMIN_ROLE) {
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
    function setNodeSecurityBond(
        string calldata nodeId,
        uint256 bondAmount
    ) external payable whenNotPaused nonReentrant {
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
    // NODE VIEW FUNCTIONS
    // =============================================================================

    /**
     * @dev Get node custom attribute
     */
    function getNodeCustomAttribute(
        string calldata nodeId,
        string calldata key
    ) external view returns (string memory) {
        return nodeStorage.getNodeCustomAttribute(nodeId, key);
    }

    /**
     * @dev Get node certifications
     */
    function getNodeCertifications(
        string calldata nodeId
    ) external view returns (bytes32[] memory) {
        return nodeStorage.getNodeCertifications(nodeId);
    }

    /**
     * @dev Get total nodes stats
     */
    function getNodeStats()
        external
        view
        returns (
            uint256 totalNodes,
            uint256 activeNodes,
            uint256 listedNodes,
            uint256 verifiedNodes
        )
    {
        return nodeStorage.getExtendedStats();
    }
}
