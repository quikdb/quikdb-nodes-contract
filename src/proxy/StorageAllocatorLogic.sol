// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../storage/StorageAllocatorStorage.sol";
import "../storage/NodeStorage.sol";
import "../libraries/ValidationLibrary.sol";
import "../libraries/RateLimitingLibrary.sol";
import "../libraries/GasOptimizationLibrary.sol";
import "./BaseLogic.sol";

/**
 * @title StorageAllocatorLogic
 * @notice Implementation contract for storage allocation management with production-grade validation
 * @dev Inherits from BaseLogic (proxy pattern) and coordinates storage allocations.
 */
contract StorageAllocatorLogic is BaseLogic {
    using ValidationLibrary for *;
    using RateLimitingLibrary for *;
    using GasOptimizationLibrary for *;
    
    // ---------------------------------------------------------------------
    // Storage contracts
    // ---------------------------------------------------------------------
    StorageAllocatorStorage public storageAllocatorStorage;

    // Daily allocation tracking per requester (for rate limiting)
    mapping(address => mapping(uint256 => uint256)) private dailyAllocations; // requester => day => count

    // ---------------------------------------------------------------------
    // Roles
    // ---------------------------------------------------------------------
    bytes32 public constant STORAGE_ALLOCATOR_ROLE = keccak256("STORAGE_ALLOCATOR_ROLE");
    bytes32 public constant STORAGE_MANAGER_ROLE   = keccak256("STORAGE_MANAGER_ROLE");

    // ---------------------------------------------------------------------
    // Events
    // ---------------------------------------------------------------------
    event AllocationRequested(
        string  indexed allocationId,
        address indexed requester,
        uint256         sizeGB,
        uint256         timestamp
    );

    event AllocationCompleted(
        string  indexed allocationId,
        address indexed requester,
        uint256         nodeCount,
        uint256         totalSizeGB
    );

    event AllocationReleased(
        string  indexed allocationId,
        address indexed requester,
        uint256         timestamp
    );

    event AllocationStatusUpdated(
        string indexed allocationId,
        uint8  previousStatus,
        uint8  newStatus
    );

    // ---------------------------------------------------------------------
    // Constants
    // ---------------------------------------------------------------------
    uint256 public constant MIN_ALLOCATION_SIZE_GB   = 1;     // 1 GB
    uint256 public constant MAX_ALLOCATION_SIZE_GB   = 10_000; // 10 TB
    uint256 public constant MIN_REPLICATION_FACTOR   = 1;
    uint256 public constant MAX_REPLICATION_FACTOR   = 5;
    uint256 public constant MAX_NODES_PER_ALLOCATION = 50;

    // ---------------------------------------------------------------------
    // Errors
    // ---------------------------------------------------------------------
    error AllocationAlreadyExists(string allocationId);
    error AllocationNotFound(string allocationId);
    error InvalidAllocationId(string allocationId);
    error InvalidRequester(address requester);
    error InvalidSizeGB(uint256 sizeGB);
    error InvalidStatus(uint8 status);
    error EmptyNodeList();
    error TooManyNodes(uint256 nodeCount);
    error UnauthorizedRequester(address requester, string allocationId);
    error InsufficientStorageCapacity(uint256 requested, uint256 available);
    error NodeNotFound(string nodeId);
    error NodeInactive(string nodeId);
    error InvalidReplicationFactor(uint256 factor);
    error GeographicDistributionFailed(string reason);
    error NodeCapacityExceeded(string nodeId, uint256 requested, uint256 available);

    // ---------------------------------------------------------------------
    // Initialization
    // ---------------------------------------------------------------------
    /**
     * @dev Initialize the storage allocator logic contract.
     */
    function initialize(
        address _storageAllocatorStorage,
        address _nodeStorage,
        address _userStorage,
        address _resourceStorage
    ) external {
        _initializeBase(_nodeStorage, _userStorage, _resourceStorage, msg.sender);

        if (_storageAllocatorStorage == address(0)) revert("Invalid storage allocator storage address");
        storageAllocatorStorage = StorageAllocatorStorage(_storageAllocatorStorage);

        // Grant allocator role to deployer
        _grantRole(STORAGE_ALLOCATOR_ROLE, msg.sender);
    }

    // ---------------------------------------------------------------------
    // Public / external functions
    // ---------------------------------------------------------------------

    /**
     * @dev Allocate storage across specified nodes.
     */
    /**
     * @dev Allocate storage with comprehensive production validation
     */
    function allocateStorage(
        string  calldata allocationId,
        address         requester,
        uint256         sizeGB,
        string[] calldata nodeIds,
        uint256         replicationFactor
    ) external 
        rateLimit("allocateStorage", RateLimitingLibrary.MAX_STORAGE_OPERATIONS_PER_MINUTE, RateLimitingLibrary.MINUTE_WINDOW)
        circuitBreakerCheck("storageAllocation")
        emergencyPauseCheck("StorageAllocatorLogic") {
        // === PRODUCTION VALIDATION ===
        
        // Validate allocation ID format
        ValidationLibrary.validateId(allocationId);
        
        // Validate requester address
        ValidationLibrary.validateAddress(requester);
        
        // Validate storage size allocation
        ValidationLibrary.validateStorageAllocation(sizeGB);
        
        // Validate node list
        ValidationLibrary.validateArrayLength(nodeIds.length, 1, ValidationLibrary.MAX_CLUSTER_SIZE);
        ValidationLibrary.validateUniqueNodeIds(nodeIds);
        
        // Validate replication factor
        ValidationLibrary.validateRange(replicationFactor, MIN_REPLICATION_FACTOR, MAX_REPLICATION_FACTOR);
        require(replicationFactor <= nodeIds.length, "Replication factor exceeds node count");
        
        // === BUSINESS LOGIC VALIDATION ===
        
        // Check if allocation already exists by attempting to get it and handling the revert
        try storageAllocatorStorage.getAllocation(allocationId) {
            revert AllocationAlreadyExists(allocationId);
        } catch {
            // Allocation doesn't exist, which is what we want
        }

        // === DAILY ALLOCATION LIMITS PER REQUESTER ===
        uint256 currentDay = block.timestamp / 1 days;
        uint256 todayAllocations = dailyAllocations[requester][currentDay];
        if (todayAllocations >= RateLimitingLibrary.MAX_ALLOCATIONS_PER_REQUESTER_PER_DAY) {
            revert RateLimitingLibrary.RateLimitExceededError(
                "allocateStorage", 
                todayAllocations, 
                RateLimitingLibrary.MAX_ALLOCATIONS_PER_REQUESTER_PER_DAY
            );
        }
        
        // Update daily allocation count
        dailyAllocations[requester][currentDay] = todayAllocations + 1;

        // === NODE VERIFICATION WITH GEOGRAPHIC DISTRIBUTION ===
        string[] memory validated = new string[](nodeIds.length);
        uint256   validCount      = 0;
        string[] memory regions = new string[](nodeIds.length);
        uint256 regionCount = 0;

        for (uint256 i = 0; i < nodeIds.length; i++) {
            string calldata nodeId = nodeIds[i];
            
            // Check if node exists in storage
            if (!nodeStorage.doesNodeExist(nodeId)) revert NodeNotFound(nodeId);

            // Get node information for comprehensive validation
            NodeStorage.NodeInfo memory nodeInfo = nodeStorage.getNodeInfo(nodeId);
            
            // Validate node status - must be ACTIVE or LISTED to accept allocations
            if (nodeInfo.status != NodeStorage.NodeStatus.ACTIVE &&
                nodeInfo.status != NodeStorage.NodeStatus.LISTED) {
                revert NodeInactive(nodeId);
            }
            
            // Validate node has sufficient storage capacity
            if (nodeInfo.capacity.storageGB < sizeGB) {
                revert NodeCapacityExceeded(nodeId, sizeGB, nodeInfo.capacity.storageGB);
            }
            
            // Validate node is properly registered (has valid address)
            if (nodeInfo.nodeAddress == address(0)) {
                revert NodeInactive(nodeId);
            }
            
            // Validate node exists flag is consistent
            if (!nodeInfo.exists) {
                revert NodeNotFound(nodeId);
            }

            validated[validCount++] = nodeId;
        }

        if (validCount < replicationFactor)
            revert GeographicDistributionFailed("Insufficient valid nodes for replication factor");

        if (!_validateGeographicDistribution(validated, validCount))
            revert GeographicDistributionFailed("Nodes not geographically distributed");

        // --- persistence --------------------------------------------------
        // --- create allocation ----------------------------------------
        StorageAllocatorStorage.StorageAllocation memory allocation = 
            StorageAllocatorStorage.StorageAllocation({
                allocationId:        allocationId,
                requester:           requester,
                sizeGB:              sizeGB,
                status:              uint8(StorageAllocatorStorage.AllocationStatus.PENDING),
                allocatedAt:         block.timestamp,
                updatedAt:           block.timestamp,
                nodeIds:             _resizeArray(validated, validCount),
                replicationFactor:   replicationFactor,
                region:              ""
            });

        storageAllocatorStorage.createAllocation(allocation);

        emit AllocationRequested(
            allocationId,
            requester,
            sizeGB,
            block.timestamp
        );
    }

    /**
     * @dev Update storage allocation status.
     */
    function updateAllocationStatus(
        string calldata allocationId,
        StorageAllocatorStorage.AllocationStatus status
    ) external {
        // Validate allocation exists
        StorageAllocatorStorage.StorageAllocation memory allocation = storageAllocatorStorage.getAllocation(allocationId);
        
        // Validate status transition
        _validateStatusTransition(StorageAllocatorStorage.AllocationStatus(allocation.status), status);

        // Update allocation status
        storageAllocatorStorage.updateAllocationStatus(allocationId, uint8(status));
        
        emit AllocationStatusUpdated(allocationId, uint8(allocation.status), uint8(status));
    }

    /**
     * @dev Read-only helpers.
     */
    function getAllocation(string calldata allocationId)
        external
        view
        returns (StorageAllocatorStorage.StorageAllocation memory)
    {
        if (bytes(allocationId).length == 0) revert InvalidAllocationId(allocationId);

        // getAllocation in storage contract will revert if allocation doesn't exist
        return storageAllocatorStorage.getAllocation(allocationId);
    }

    function getNodeAllocations(string calldata nodeId)
        external
        view
        returns (string[] memory)
    {
        if (bytes(nodeId).length == 0) revert InvalidAllocationId(nodeId);
        return storageAllocatorStorage.getNodeAllocations(nodeId);
    }

    function getRequesterAllocations(address requester)
        external
        view
        returns (string[] memory)
    {
        if (requester == address(0)) revert InvalidRequester(requester);
        return storageAllocatorStorage.getRequesterAllocations(requester);
    }

    function getStorageStats()
        external
        view
        returns (
            uint256 totalAllocations,
            uint256 activeAllocations,
            uint256 totalStorageGB
        )
    {
        return storageAllocatorStorage.getStorageStats();
    }

    /**
     * @dev Validate nodes for storage allocation (public helper)
     * @param nodeIds Array of node identifiers to validate
     * @param requiredCapacityGB Minimum storage capacity required per node
     * @return validNodes Array of validated node IDs
     * @return nodeAddresses Array of corresponding node addresses
     */
    function validateNodesForAllocation(
        string[] calldata nodeIds,
        uint256 requiredCapacityGB
    ) external view returns (string[] memory validNodes, address[] memory nodeAddresses) {
        if (nodeIds.length == 0) revert EmptyNodeList();
        
        validNodes = new string[](nodeIds.length);
        nodeAddresses = new address[](nodeIds.length);
        uint256 validCount = 0;
        
        for (uint256 i = 0; i < nodeIds.length; i++) {
            string calldata nodeId = nodeIds[i];
            
            // Basic validation
            if (bytes(nodeId).length == 0) continue;
            if (!nodeStorage.doesNodeExist(nodeId)) continue;
            
            NodeStorage.NodeInfo memory nodeInfo = nodeStorage.getNodeInfo(nodeId);
            
            // Check if node is available for allocations
            if (nodeInfo.status != NodeStorage.NodeStatus.ACTIVE &&
                nodeInfo.status != NodeStorage.NodeStatus.LISTED) continue;
                
            // Check capacity
            if (nodeInfo.capacity.storageGB < requiredCapacityGB) continue;
            
            // Check valid registration
            if (nodeInfo.nodeAddress == address(0) || !nodeInfo.exists) continue;
            
            validNodes[validCount] = nodeId;
            nodeAddresses[validCount] = nodeInfo.nodeAddress;
            validCount++;
        }
        
        // Resize arrays to actual valid count
        string[] memory finalValidNodes = new string[](validCount);
        address[] memory finalNodeAddresses = new address[](validCount);
        
        for (uint256 i = 0; i < validCount; i++) {
            finalValidNodes[i] = validNodes[i];
            finalNodeAddresses[i] = nodeAddresses[i];
        }
        
        return (finalValidNodes, finalNodeAddresses);
    }

    // ---------------------------------------------------------------------
    // Internal helpers
    // ---------------------------------------------------------------------

    function _validateStatusTransition(
        StorageAllocatorStorage.AllocationStatus currentStatus,
        StorageAllocatorStorage.AllocationStatus newStatus
    ) internal pure {
        if (currentStatus == StorageAllocatorStorage.AllocationStatus.PENDING) {
            require(
                newStatus == StorageAllocatorStorage.AllocationStatus.ACTIVE ||
                newStatus == StorageAllocatorStorage.AllocationStatus.FAILED,
                "Invalid status transition from PENDING"
            );
        } else if (currentStatus == StorageAllocatorStorage.AllocationStatus.ACTIVE) {
            require(
                newStatus == StorageAllocatorStorage.AllocationStatus.RELEASED ||
                newStatus == StorageAllocatorStorage.AllocationStatus.FAILED,
                "Invalid status transition from ACTIVE"
            );
        } else {
            revert("Cannot transition from terminal status");
        }
    }

    function _validateGeographicDistribution(string[] memory nodeIds, uint256 nodeCount)
        internal
        view
        returns (bool)
    {
        if (nodeCount <= 1) return true;

        string[] memory regions = new string[](nodeCount);
        for (uint256 i = 0; i < nodeCount; i++) {
            regions[i] = nodeStorage.getNodeInfo(nodeIds[i]).listing.region;
        }

        for (uint256 i = 0; i < nodeCount - 1; i++) {
            for (uint256 j = i + 1; j < nodeCount; j++) {
                if (keccak256(bytes(regions[i])) != keccak256(bytes(regions[j]))) {
                    return true;
                }
            }
        }
        return false;
    }

    function _resizeArray(string[] memory src, uint256 validCount)
        internal
        pure
        returns (string[] memory dst)
    {
        dst = new string[](validCount);
        for (uint256 i = 0; i < validCount; i++) {
            dst[i] = src[i];
        }
    }

    /**
     * @dev Get daily allocation count for a requester
     */
    function getDailyAllocationCount(address requester) external view returns (uint256) {
        uint256 currentDay = block.timestamp / 1 days;
        return dailyAllocations[requester][currentDay];
    }

    // =============================================================================
    // GAS OPTIMIZED BATCH OPERATIONS  
    // =============================================================================

    /**
     * @dev Batch allocate storage for multiple requesters (gas optimized)
     */
    function batchAllocateStorage(
        string[] calldata allocationIds,
        address[] calldata requesters,
        uint256[] calldata sizesGB,
        string[][] calldata nodeIdsBatch,
        uint256[] calldata replicationFactors
    ) external 
        rateLimit("batchAllocateStorage", RateLimitingLibrary.MAX_STORAGE_OPERATIONS_PER_MINUTE * 5, RateLimitingLibrary.MINUTE_WINDOW)
        circuitBreakerCheck("batchStorageAllocation")
        emergencyPauseCheck("StorageAllocatorLogic")
    {
        uint256 batchSize = allocationIds.length;
        
        // Validate batch operation
        GasOptimizationLibrary.validateBatchOperation(batchSize);
        
        // Validate all arrays have same length
        require(
            requesters.length == batchSize &&
            sizesGB.length == batchSize &&
            nodeIdsBatch.length == batchSize &&
            replicationFactors.length == batchSize,
            "Array length mismatch"
        );
        
        uint256 successfulAllocations = 0;
        uint256 totalStorageAllocated = 0;
        
        // Process each allocation in the batch
        for (uint256 i = 0; i < batchSize; i++) {
            try this._allocateSingleStorage(
                allocationIds[i],
                requesters[i],
                sizesGB[i],
                nodeIdsBatch[i],
                replicationFactors[i]
            ) {
                successfulAllocations++;
                totalStorageAllocated += sizesGB[i];
            } catch {
                // Continue with next allocation on failure
                continue;
            }
        }
        
        require(successfulAllocations > 0, "Batch allocation failed completely");
    }

    /**
     * @dev Internal function for single storage allocation (used by batch)
     */
    function _allocateSingleStorage(
        string calldata allocationId,
        address requester,
        uint256 sizeGB,
        string[] calldata nodeIds,
        uint256 replicationFactor
    ) external {
        require(msg.sender == address(this), "Internal function only");
        
        // Reuse existing allocation logic with minimal validation
        _performStorageAllocation(allocationId, requester, sizeGB, nodeIds, replicationFactor);
    }

    /**
     * @dev Perform storage allocation (extracted for batch operations)
     */
    function _performStorageAllocation(
        string calldata allocationId,
        address requester,
        uint256 sizeGB,
        string[] calldata nodeIds,
        uint256 replicationFactor
    ) internal {
        // Basic validation (optimized for batch operations)
        ValidationLibrary.validateId(allocationId);
        ValidationLibrary.validateAddress(requester);
        ValidationLibrary.validateStorageAllocation(sizeGB);
        
        // Check daily allocation limits
        uint256 currentDay = block.timestamp / 1 days;
        uint256 todayAllocations = dailyAllocations[requester][currentDay];
        if (todayAllocations >= RateLimitingLibrary.MAX_ALLOCATIONS_PER_REQUESTER_PER_DAY) {
            revert RateLimitingLibrary.RateLimitExceededError(
                "allocateStorage", 
                todayAllocations, 
                RateLimitingLibrary.MAX_ALLOCATIONS_PER_REQUESTER_PER_DAY
            );
        }
        
        // Update daily allocation count
        dailyAllocations[requester][currentDay] = todayAllocations + 1;
        
        // Create allocation (simplified for batch efficiency)
        StorageAllocatorStorage.StorageAllocation memory allocation = 
            StorageAllocatorStorage.StorageAllocation({
                allocationId: allocationId,
                requester: requester,
                sizeGB: sizeGB,
                status: uint8(StorageAllocatorStorage.AllocationStatus.PENDING),
                allocatedAt: block.timestamp,
                updatedAt: block.timestamp,
                nodeIds: nodeIds,
                replicationFactor: replicationFactor,
                region: ""
            });

        storageAllocatorStorage.createAllocation(allocation);
        emit AllocationRequested(allocationId, requester, sizeGB, block.timestamp);
    }

    /**
     * @dev Get remaining daily allocation capacity for a requester
     */
    function getRemainingDailyCapacity(address requester) external view returns (uint256) {
        uint256 currentDay = block.timestamp / 1 days;
        uint256 used = dailyAllocations[requester][currentDay];
        return used >= RateLimitingLibrary.MAX_ALLOCATIONS_PER_REQUESTER_PER_DAY 
            ? 0 
            : RateLimitingLibrary.MAX_ALLOCATIONS_PER_REQUESTER_PER_DAY - used;
    }

    /**
     * @dev Get contract name for circuit breaker logging
     */
    function _getContractName() internal pure override returns (string memory) {
        return "StorageAllocatorLogic";
    }
}
