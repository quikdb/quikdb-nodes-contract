// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./BaseLogic.sol";
import "../storage/StorageAllocatorStorage.sol";

/**
 * @title StorageAllocatorLogic
 * @notice Implementation contract for storage allocation management
 * @dev This contract implements the business logic for allocating and managing storage.
 *      It inherits from BaseLogic and follows the proxy pattern.
 */
contract StorageAllocatorLogic is BaseLogic {
    // Storage contract reference
    StorageAllocatorStorage public storageAllocatorStorage;

    // Storage-specific roles
    bytes32 public constant STORAGE_ALLOCATOR_ROLE = keccak256("STORAGE_ALLOCATOR_ROLE");
    bytes32 public constant STORAGE_MANAGER_ROLE = keccak256("STORAGE_MANAGER_ROLE");

    // Storage operation events
    event AllocationRequested(
        string indexed allocationId,
        address indexed requester,
        uint256 sizeGB,
        uint256 timestamp
    );

    event AllocationCompleted(
        string indexed allocationId,
        address indexed requester,
        uint256 nodeCount,
        uint256 totalSizeGB
    );

    event AllocationReleased(
        string indexed allocationId,
        address indexed requester,
        uint256 timestamp
    );

    // Custom errors
    error AllocationAlreadyExists(string allocationId);
    error AllocationNotFound(string allocationId);
    error InvalidAllocationId(string allocationId);
    error InvalidRequester(address requester);
    error InvalidSizeGB(uint256 sizeGB);
    error InvalidStatus(uint8 status);
    error EmptyNodeList();
    error UnauthorizedRequester(address requester, string allocationId);
    error InsufficientStorageCapacity(uint256 requested, uint256 available);

    /**
     * @dev Initialize the storage allocator logic contract
     * @param _storageAllocatorStorage Address of the storage allocator storage contract
     * @param _nodeStorage Address of the node storage contract
     * @param _userStorage Address of the user storage contract
     * @param _resourceStorage Address of the resource storage contract
     */
    function initialize(
        address _storageAllocatorStorage,
        address _nodeStorage,
        address _userStorage,
        address _resourceStorage
    ) external {
        _initializeBase(_nodeStorage, _userStorage, _resourceStorage, msg.sender);
        
        require(_storageAllocatorStorage != address(0), "Invalid storage allocator storage address");
        storageAllocatorStorage = StorageAllocatorStorage(_storageAllocatorStorage);

        // Set up roles
        _grantRole(STORAGE_ALLOCATOR_ROLE, msg.sender);
        _grantRole(STORAGE_MANAGER_ROLE, msg.sender);
    }

    /**
     * @dev Allocate storage across specified nodes
     * @param allocationId Unique identifier for the allocation
     * @param requester Address requesting the storage
     * @param sizeGB Size of storage in GB
     * @param nodeIds Array of node IDs to allocate storage on
     */
    function allocateStorage(
        string calldata allocationId,
        address requester,
        uint256 sizeGB,
        string[] calldata nodeIds
    ) external onlyRole(STORAGE_ALLOCATOR_ROLE) whenNotPaused nonReentrant {
        if (bytes(allocationId).length == 0) revert InvalidAllocationId(allocationId);
        if (requester == address(0)) revert InvalidRequester(requester);
        if (sizeGB == 0) revert InvalidSizeGB(sizeGB);
        if (nodeIds.length == 0) revert EmptyNodeList();

        // Check if allocation already exists
        (string memory existingAllocationId, , , , ) = 
            storageAllocatorStorage.allocations(allocationId);
        if (bytes(existingAllocationId).length > 0) {
            revert AllocationAlreadyExists(allocationId);
        }

        emit AllocationRequested(allocationId, requester, sizeGB, block.timestamp);

        // Note: In a real implementation, this would:
        // 1. Validate node availability and capacity
        // 2. Calculate storage distribution across nodes
        // 3. Create StorageAllocation struct with provided data
        // 4. Store in allocations mapping
        // 5. Update nodeAllocations mapping for each node
        // 6. Update requesterAllocations mapping
        // 7. Set initial status (e.g., 0 = pending, 1 = allocated, 2 = active, 3 = released)
        
        emit AllocationCompleted(allocationId, requester, nodeIds.length, sizeGB);
    }

    /**
     * @dev Update storage allocation status
     * @param allocationId Unique identifier for the allocation
     * @param newStatus New status value
     */
    function updateAllocationStatus(
        string calldata allocationId,
        uint8 newStatus
    ) external onlyRole(STORAGE_MANAGER_ROLE) whenNotPaused nonReentrant {
        if (bytes(allocationId).length == 0) revert InvalidAllocationId(allocationId);

        // Check if allocation exists
        (string memory existingAllocationId, address requester, , , ) = 
            storageAllocatorStorage.allocations(allocationId);
        if (bytes(existingAllocationId).length == 0) {
            revert AllocationNotFound(allocationId);
        }

        // Validate status transition (basic validation)
        if (newStatus > 4) revert InvalidStatus(newStatus); // 0-4 are valid statuses

        // Handle status-specific logic
        if (newStatus == 3) { // Released status
            emit AllocationReleased(allocationId, requester, block.timestamp);
        }

        // Note: In a real implementation, this would:
        // 1. Update the status field in the allocations mapping
        // 2. Emit AllocationStatusUpdated event from storage
        // 3. Handle any side effects of status changes (e.g., cleanup for released status)
    }

    /**
     * @dev Get storage allocation details
     * @param allocationId Unique identifier for the allocation
     * @return allocationId_ Allocation ID
     * @return requester Address of the requester
     * @return sizeGB Size in GB
     * @return nodeIds Array of node IDs
     * @return status Current status
     * @return allocatedAt Allocation timestamp
     */
    function getAllocation(
        string calldata allocationId
    ) external view returns (
        string memory allocationId_,
        address requester,
        uint256 sizeGB,
        string[] memory nodeIds,
        uint8 status,
        uint256 allocatedAt
    ) {
        if (bytes(allocationId).length == 0) revert InvalidAllocationId(allocationId);

        (allocationId_, requester, sizeGB, status, allocatedAt) = storageAllocatorStorage.allocations(allocationId);
        nodeIds = storageAllocatorStorage.getAllocationNodes(allocationId);
    }

    /**
     * @dev Get storage allocations for a specific node
     * @param nodeId Node identifier
     * @return allocationIds Array of allocation IDs on the node
     */
    function getNodeAllocations(
        string calldata nodeId
    ) external view returns (string[] memory allocationIds) {
        if (bytes(nodeId).length == 0) revert InvalidAllocationId(nodeId);

        return storageAllocatorStorage.getNodeAllocations(nodeId);
    }

    /**
     * @dev Get storage allocations for a specific requester
     * @param requester Address of the requester
     * @return allocationIds Array of allocation IDs for the requester
     */
    function getRequesterAllocations(
        address requester
    ) external view returns (string[] memory allocationIds) {
        if (requester == address(0)) revert InvalidRequester(requester);

        return storageAllocatorStorage.getRequesterAllocations(requester);
    }

    /**
     * @dev Check if a storage allocation exists
     * @param allocationId Unique identifier for the allocation
     * @return exists True if allocation exists, false otherwise
     */
    function allocationExists(string calldata allocationId) external view returns (bool exists) {
        if (bytes(allocationId).length == 0) return false;
        
        (string memory existingAllocationId, , , , ) = 
            storageAllocatorStorage.allocations(allocationId);
        return bytes(existingAllocationId).length > 0;
    }

    /**
     * @dev Check if a requester owns a specific allocation
     * @param requester Address of the requester
     * @param allocationId Allocation identifier
     * @return owns True if requester owns the allocation
     */
    function isRequesterOwner(
        address requester,
        string calldata allocationId
    ) external view returns (bool owns) {
        if (requester == address(0) || bytes(allocationId).length == 0) return false;

        (, address allocationRequester, , , ) = storageAllocatorStorage.allocations(allocationId);
        return allocationRequester == requester;
    }

    /**
     * @dev Get total allocated storage size for a node
     * @param nodeId Node identifier
     * @return totalSizeGB Total allocated storage in GB
     */
    function getNodeTotalAllocation(
        string calldata nodeId
    ) external view returns (uint256 totalSizeGB) {
        if (bytes(nodeId).length == 0) return 0;

        string[] memory allocIds = storageAllocatorStorage.getNodeAllocations(nodeId);
        
        for (uint256 i = 0; i < allocIds.length; i++) {
            (, , uint256 sizeGB, uint8 status, ) = 
                storageAllocatorStorage.allocations(allocIds[i]);
            
            // Only count active allocations (status 2 = active)
            if (status == 2) {
                totalSizeGB += sizeGB;
            }
        }
    }
}
