// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../storage/NodeStorage.sol";
import "../storage/UserStorage.sol";
import "../storage/ResourceStorage.sol";

/**
 * @title QuikBaseLogic - Base contract with common functionality
 */
abstract contract QuikBaseLogic is AccessControl, Pausable, ReentrancyGuard {
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

    // Core events
    event LogicUpgraded(address indexed newLogic, uint256 version);
    event StorageContractUpdated(string contractType, address newAddress);

    modifier onlyStorageContracts() {
        require(
            msg.sender == address(nodeStorage) ||
                msg.sender == address(userStorage) ||
                msg.sender == address(resourceStorage),
            "Only storage"
        );
        _;
    }

    /**
     * @dev Initialize the base logic contract
     */
    function _initializeBase(
        address _nodeStorage,
        address _userStorage,
        address _resourceStorage,
        address _admin
    ) internal {
        require(
            _admin != address(0) &&
                _nodeStorage != address(0) &&
                _userStorage != address(0) &&
                _resourceStorage != address(0),
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

    // Common helper functions

    /**
     * @dev Check if caller is authorized to operate on a node
     */
    function _isNodeAuthorized(
        string calldata nodeId
    ) internal view returns (address nodeAddress) {
        nodeAddress = nodeStorage.getNodeAddress(nodeId);
        require(
            msg.sender == nodeAddress || hasRole(ADMIN_ROLE, msg.sender),
            "Not authorized"
        );
        return nodeAddress;
    }

    /**
     * @dev Verify node operator is caller
     */
    function _onlyNodeOperator(
        string calldata nodeId
    ) internal view returns (address) {
        address nodeAddress = nodeStorage.getNodeAddress(nodeId);
        require(msg.sender == nodeAddress, "Not node operator");
        return nodeAddress;
    }

    // Common admin functions

    /**
     * @dev Update storage contract address
     */
    function updateStorageContract(
        string calldata contractType,
        address newAddress
    ) external onlyRole(ADMIN_ROLE) {
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
    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    function withdraw() external onlyRole(ADMIN_ROLE) {
        payable(msg.sender).transfer(address(this).balance);
    }
}
