// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./QuikNodeLogic.sol";
import "./QuikUserLogic.sol";
import "./QuikResourceLogic.sol";

/**
 * @title QuikFacade - Facade to coordinate between specialized logic contracts
 */
contract QuikFacade is AccessControl, Pausable, ReentrancyGuard {
    // Version for upgrade tracking
    uint256 public constant VERSION = 1;

    // Logic contract addresses
    address public nodeLogicAddress;
    address public userLogicAddress;
    address public resourceLogicAddress;

    // Roles
    bytes32 public constant ADMIN_ROLE = DEFAULT_ADMIN_ROLE;
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    // Events
    event LogicContractUpdated(string contractType, address newAddress);

    /**
     * @dev Initialize the facade contract
     */
    function initialize(
        address _nodeLogic,
        address _userLogic,
        address _resourceLogic,
        address _admin
    ) external {
        require(
            _admin != address(0) &&
                _nodeLogic != address(0) &&
                _userLogic != address(0) &&
                _resourceLogic != address(0),
            "Invalid address"
        );

        // Set up roles
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(UPGRADER_ROLE, _admin);

        // Initialize logic contracts
        nodeLogicAddress = _nodeLogic;
        userLogicAddress = _userLogic;
        resourceLogicAddress = _resourceLogic;
    }

    /**
     * @dev Update logic contract addresses
     */
    function updateLogicContract(
        string calldata contractType,
        address newAddress
    ) external onlyRole(ADMIN_ROLE) {
        require(newAddress != address(0), "Invalid address");
        bytes32 typeHash = keccak256(bytes(contractType));

        if (typeHash == keccak256(bytes("node"))) {
            nodeLogicAddress = newAddress;
        } else if (typeHash == keccak256(bytes("user"))) {
            userLogicAddress = newAddress;
        } else if (typeHash == keccak256(bytes("resource"))) {
            resourceLogicAddress = newAddress;
        } else {
            revert("Invalid type");
        }

        emit LogicContractUpdated(contractType, newAddress);
    }

    /**
     * @dev Emergency pause/unpause
     */
    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    /**
     * @dev Get total statistics across all domains
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
        (totalNodes, , , ) = QuikNodeLogic(nodeLogicAddress).getNodeStats();
        totalUsers = QuikUserLogic(userLogicAddress).getUserStats();
        totalAllocations = QuikResourceLogic(resourceLogicAddress)
            .getResourceStats();
    }

    /**
     * @dev Get extended statistics
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
        (totalNodes, , , verifiedNodes) = QuikNodeLogic(nodeLogicAddress)
            .getNodeStats();
        totalUsers = QuikUserLogic(userLogicAddress).getUserStats();
        totalAllocations = QuikResourceLogic(resourceLogicAddress)
            .getResourceStats();
    }
}
