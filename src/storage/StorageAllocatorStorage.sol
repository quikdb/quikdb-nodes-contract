// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title StorageAllocatorStorage
 * @dev Storage contract for storage allocation system
 * Contains only storage layout and structs - no logic functions
 */
contract StorageAllocatorStorage is AccessControl {
    // Role for logic contracts that can modify storage
    bytes32 public constant LOGIC_ROLE = keccak256("LOGIC_ROLE");

    /**
     * @dev Storage allocation status enumeration
     */
    enum AllocationStatus {
        PENDING,    // 0 - Allocation requested but not yet processed
        ALLOCATED,  // 1 - Storage allocated but not yet active
        ACTIVE,     // 2 - Storage allocation is active and in use
        RELEASED,   // 3 - Storage allocation has been released
        FAILED      // 4 - Allocation failed
    }

    /**
     * @dev Storage allocation structure
     */
    struct StorageAllocation {
        string allocationId;
        address requester;
        uint256 sizeGB;
        uint8 status;
        uint256 allocatedAt;
        uint256 updatedAt;
        string[] nodeIds;
        uint256 replicationFactor;
        string region;
    }

    // Storage mappings
    mapping(string => StorageAllocation) public allocations;
    mapping(string => string[]) internal allocationNodes; // nodeIds for each allocation
    mapping(string => string[]) internal nodeAllocations; // allocations for each node
    mapping(address => string[]) internal requesterAllocations; // allocations for each requester
    mapping(string => bool) public allocationExists;
    
    // Statistics
    uint256 public totalAllocations;
    uint256 public activeAllocations;
    uint256 public totalAllocatedGB;

    // Access control modifier
    modifier onlyLogic() {
        require(hasRole(LOGIC_ROLE, msg.sender), "Caller is not Logic contract");
        _;
    }

    /**
     * @dev Constructor sets up the contract with the deployer as the default admin
     * @param admin Address to be granted the default admin role
     */
    constructor(address admin) {
        require(admin != address(0), "Invalid admin address");
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    /**
     * @dev Set the logic contract address
     * @param logicContract Address of the logic contract
     */
    function setLogicContract(address logicContract) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(LOGIC_ROLE, logicContract);
    }

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

    /**
     * @dev Create a new storage allocation
     * @param allocation StorageAllocation struct containing allocation data
     */
    function createAllocation(StorageAllocation calldata allocation) external onlyLogic {
        require(!allocationExists[allocation.allocationId], "Allocation already exists");
        require(bytes(allocation.allocationId).length > 0, "Invalid allocation ID");
        require(allocation.requester != address(0), "Invalid requester");
        require(allocation.sizeGB > 0, "Invalid size");
        require(allocation.nodeIds.length > 0, "No nodes provided");
        
        // Store allocation
        allocations[allocation.allocationId] = allocation;
        allocationExists[allocation.allocationId] = true;
        
        // Update node allocations for each node
        for (uint256 i = 0; i < allocation.nodeIds.length; i++) {
            nodeAllocations[allocation.nodeIds[i]].push(allocation.allocationId);
            allocationNodes[allocation.allocationId].push(allocation.nodeIds[i]);
        }
        
        // Update requester allocations
        requesterAllocations[allocation.requester].push(allocation.allocationId);
        
        // Update statistics
        totalAllocations++;
        if (allocation.status == uint8(AllocationStatus.ACTIVE)) {
            activeAllocations++;
            totalAllocatedGB += allocation.sizeGB;
        }
        
        emit StorageAllocated(
            allocation.allocationId,
            allocation.requester,
            allocation.sizeGB,
            allocation.nodeIds,
            allocation.allocatedAt
        );
    }

    /**
     * @dev Update allocation status
     * @param allocationId Allocation identifier
     * @param newStatus New status for the allocation
     */
    function updateAllocationStatus(string calldata allocationId, uint8 newStatus) external onlyLogic {
        require(allocationExists[allocationId], "Allocation does not exist");
        require(newStatus <= uint8(AllocationStatus.FAILED), "Invalid status");
        
        StorageAllocation storage allocation = allocations[allocationId];
        uint8 oldStatus = allocation.status;
        
        // Update statistics based on status changes
        if (oldStatus == uint8(AllocationStatus.ACTIVE) && newStatus != uint8(AllocationStatus.ACTIVE)) {
            activeAllocations--;
            totalAllocatedGB -= allocation.sizeGB;
        } else if (oldStatus != uint8(AllocationStatus.ACTIVE) && newStatus == uint8(AllocationStatus.ACTIVE)) {
            activeAllocations++;
            totalAllocatedGB += allocation.sizeGB;
        }
        
        allocation.status = newStatus;
        allocation.updatedAt = block.timestamp;
        
        emit AllocationStatusUpdated(allocationId, allocation.requester, oldStatus, newStatus, block.timestamp);
    }

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

    /**
     * @dev Get allocation details
     * @param allocationId Allocation identifier
     * @return StorageAllocation struct
     */
    function getAllocation(string calldata allocationId) external view returns (StorageAllocation memory) {
        require(allocationExists[allocationId], "Allocation does not exist");
        return allocations[allocationId];
    }

    /**
     * @dev Get storage statistics
     * @return total Total number of allocations
     * @return active Number of active allocations
     * @return totalGB Total allocated storage in GB
     */
    function getStorageStats() external view returns (uint256 total, uint256 active, uint256 totalGB) {
        return (totalAllocations, activeAllocations, totalAllocatedGB);
    }
}
