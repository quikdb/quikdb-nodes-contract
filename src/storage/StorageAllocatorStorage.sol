// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

/**
 * @title StorageAllocatorStorage
 * @dev Storage contract for storage allocation system
 * Contains only storage layout and structs - no logic functions
 */
contract StorageAllocatorStorage {
    /**
     * @dev Storage allocation structure
     */
    struct StorageAllocation {
        string allocationId;
        address requester;
        uint256 sizeGB;
        uint8 status;
        uint256 allocatedAt;
    }

    // Storage mappings
    mapping(string => StorageAllocation) public allocations;
    mapping(string => string[]) internal allocationNodes; // nodeIds for each allocation
    mapping(string => string[]) internal nodeAllocations;
    mapping(address => string[]) internal requesterAllocations;

    // Events
    event StorageAllocated(
        string indexed allocationId,
        address indexed requester,
        uint256 sizeGB,
        string[] nodeIds,
        uint256 allocatedAt
    );

    event AllocationStatusUpdated(
        string indexed allocationId,
        address indexed requester,
        uint8 oldStatus,
        uint8 newStatus,
        uint256 timestamp
    );

    // Getter functions for array mappings
    function getAllocationNodes(string memory allocationId) external view returns (string[] memory) {
        return allocationNodes[allocationId];
    }

    function getNodeAllocations(string memory nodeId) external view returns (string[] memory) {
        return nodeAllocations[nodeId];
    }

    function getRequesterAllocations(address requester) external view returns (string[] memory) {
        return requesterAllocations[requester];
    }
}
