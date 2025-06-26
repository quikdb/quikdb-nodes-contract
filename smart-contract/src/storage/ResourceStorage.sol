// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title ResourceStorage
 * @dev Storage contract for resource-related data (listings, allocations, etc.)
 * @notice This contract is immutable and stores all resource data permanently
 */
contract ResourceStorage is AccessControl {
    bytes32 public constant LOGIC_ROLE = keccak256("LOGIC_ROLE");

    // Compute tier enumeration
    enum ComputeTier {
        NANO, // Nano tier - very minimal compute
        MICRO, // Micro tier - minimal compute
        BASIC, // Basic tier - basic compute
        STANDARD, // Standard tier - general purpose
        PREMIUM, // Premium tier - high performance
        ENTERPRISE // Enterprise tier - maximum performance
    }

    // Storage tier enumeration
    enum StorageTier {
        BASIC, // Basic storage - standard HDD
        FAST, // Fast storage - SSD
        PREMIUM, // Premium storage - NVMe SSD
        ARCHIVE // Archive storage - cold storage
    }

    // Listing status enumeration
    enum ListingStatus {
        ACTIVE, // Listing is active and available
        INACTIVE, // Listing is temporarily inactive
        SUSPENDED, // Listing is suspended by admin
        EXPIRED, // Listing has expired
        CANCELLED // Listing was cancelled by provider
    }

    // Allocation status enumeration
    enum AllocationStatus {
        PENDING, // Allocation requested but not confirmed
        ACTIVE, // Allocation is active and running
        COMPLETED, // Allocation completed successfully
        CANCELLED, // Allocation was cancelled
        EXPIRED, // Allocation expired
        FAILED // Allocation failed
    }

    // Compute listing structure
    struct ComputeListing {
        bytes32 listingId; // Unique listing identifier
        string nodeId; // Associated node ID
        address provider; // Provider address
        ComputeTier tier; // Compute tier
        uint256 cpuCores; // Number of CPU cores
        uint256 memoryGB; // Memory in GB
        uint256 storageGB; // Storage in GB
        uint256 hourlyRate; // Hourly rate in wei
        string region; // Geographic region
        ListingStatus status; // Current status
        uint256 createdAt; // Creation timestamp
        uint256 updatedAt; // Last update timestamp
        uint256 expiresAt; // Expiration timestamp
        bool isActive; // Quick active check
        string[] tags; // Additional tags for filtering
    }

    // Storage listing structure
    struct StorageListing {
        bytes32 listingId; // Unique listing identifier
        string nodeId; // Associated node ID
        address provider; // Provider address
        StorageTier tier; // Storage tier
        uint256 storageGB; // Storage capacity in GB
        uint256 hourlyRate; // Hourly rate per GB in wei
        string region; // Geographic region
        ListingStatus status; // Current status
        uint256 createdAt; // Creation timestamp
        uint256 updatedAt; // Last update timestamp
        uint256 expiresAt; // Expiration timestamp
        bool isActive; // Quick active check
        string[] features; // Storage features (encryption, backup, etc.)
    }

    // Resource allocation structure
    struct ResourceAllocation {
        bytes32 allocationId; // Unique allocation identifier
        bytes32 listingId; // Associated listing ID
        address customer; // Customer address
        address provider; // Provider address
        string nodeId; // Associated node ID
        AllocationStatus status; // Current status
        uint256 duration; // Duration in hours
        uint256 totalCost; // Total cost in wei
        uint256 createdAt; // Creation timestamp
        uint256 startedAt; // Start timestamp
        uint256 expiresAt; // Expiration timestamp
        uint256 completedAt; // Completion timestamp
        bool isActive; // Quick active check
        string containerInfo; // Container/instance information
    }

    // Performance metrics structure
    struct PerformanceMetrics {
        uint256 avgResponseTime; // Average response time in ms
        uint256 uptimePercentage; // Uptime percentage (0-10000)
        uint256 throughput; // Throughput metric
        uint256 errorRate; // Error rate (0-10000)
        uint256 lastUpdated; // Last metrics update
    }

    // Storage mappings
    mapping(bytes32 => ComputeListing) private computeListings;
    mapping(bytes32 => StorageListing) private storageListings;
    mapping(bytes32 => ResourceAllocation) private allocations;
    mapping(bytes32 => PerformanceMetrics) private listingMetrics;

    // Indexing mappings
    mapping(address => bytes32[]) private providerComputeListings;
    mapping(address => bytes32[]) private providerStorageListings;
    mapping(address => bytes32[]) private customerAllocations;
    mapping(string => bytes32[]) private nodeListings;
    mapping(ComputeTier => bytes32[]) private computeListingsByTier;
    mapping(StorageTier => bytes32[]) private storageListingsByTier;
    mapping(string => bytes32[]) private listingsByRegion;

    // Statistics
    uint256 private totalComputeListings;
    uint256 private totalStorageListings;
    uint256 private totalAllocations;
    uint256 private activeComputeListings;
    uint256 private activeStorageListings;
    uint256 private activeAllocations;

    // Counters for unique IDs
    uint256 private nextListingId = 1;
    uint256 private nextAllocationId = 1;

    // Events
    event ResourceDataUpdated(bytes32 indexed id, string dataType);

    modifier onlyLogic() {
        require(hasRole(LOGIC_ROLE, msg.sender), "Only logic contract");
        _;
    }

    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    /**
     * @dev Set the logic contract address
     * @param logicContract Address of the logic contract
     */
    function setLogicContract(
        address logicContract
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(LOGIC_ROLE, logicContract);
    }

    // =============================================================================
    // COMPUTE LISTING FUNCTIONS
    // =============================================================================

    /**
     * @dev Create a new compute listing
     * @param nodeId Associated node ID
     * @param provider Provider address
     * @param tier Compute tier
     * @param cpuCores Number of CPU cores
     * @param memoryGB Memory in GB
     * @param storageGB Storage in GB
     * @param hourlyRate Hourly rate in wei
     * @param region Geographic region
     * @return listingId Unique listing identifier
     */
    function createComputeListing(
        string calldata nodeId,
        address provider,
        ComputeTier tier,
        uint256 cpuCores,
        uint256 memoryGB,
        uint256 storageGB,
        uint256 hourlyRate,
        string calldata region
    ) external onlyLogic returns (bytes32 listingId) {
        listingId = keccak256(
            abi.encodePacked("compute", nextListingId, block.timestamp)
        );
        nextListingId++;

        ComputeListing storage listing = computeListings[listingId];
        listing.listingId = listingId;
        listing.nodeId = nodeId;
        listing.provider = provider;
        listing.tier = tier;
        listing.cpuCores = cpuCores;
        listing.memoryGB = memoryGB;
        listing.storageGB = storageGB;
        listing.hourlyRate = hourlyRate;
        listing.region = region;
        listing.status = ListingStatus.ACTIVE;
        listing.createdAt = block.timestamp;
        listing.updatedAt = block.timestamp;
        listing.expiresAt = block.timestamp + 30 days; // Default 30 day expiration
        listing.isActive = true;

        // Update indexes
        providerComputeListings[provider].push(listingId);
        nodeListings[nodeId].push(listingId);
        computeListingsByTier[tier].push(listingId);
        listingsByRegion[region].push(listingId);

        totalComputeListings++;
        activeComputeListings++;

        emit ResourceDataUpdated(listingId, "compute_created");
        return listingId;
    }

    /**
     * @dev Update compute listing status
     * @param listingId Listing identifier
     * @param status New status
     */
    function updateComputeListingStatus(
        bytes32 listingId,
        ListingStatus status
    ) external onlyLogic {
        require(
            computeListings[listingId].listingId != bytes32(0),
            "Listing does not exist"
        );

        ComputeListing storage listing = computeListings[listingId];
        ListingStatus oldStatus = listing.status;
        listing.status = status;
        listing.updatedAt = block.timestamp;

        bool newActive = (status == ListingStatus.ACTIVE);
        bool oldActive = (oldStatus == ListingStatus.ACTIVE);

        if (newActive != oldActive) {
            listing.isActive = newActive;
            if (newActive) {
                activeComputeListings++;
            } else {
                activeComputeListings--;
            }
        }

        emit ResourceDataUpdated(listingId, "compute_status");
    }

    // =============================================================================
    // STORAGE LISTING FUNCTIONS
    // =============================================================================

    /**
     * @dev Create a new storage listing
     * @param nodeId Associated node ID
     * @param provider Provider address
     * @param tier Storage tier
     * @param storageGB Storage capacity in GB
     * @param hourlyRate Hourly rate per GB in wei
     * @param region Geographic region
     * @return listingId Unique listing identifier
     */
    function createStorageListing(
        string calldata nodeId,
        address provider,
        StorageTier tier,
        uint256 storageGB,
        uint256 hourlyRate,
        string calldata region
    ) external onlyLogic returns (bytes32 listingId) {
        listingId = keccak256(
            abi.encodePacked("storage", nextListingId, block.timestamp)
        );
        nextListingId++;

        StorageListing storage listing = storageListings[listingId];
        listing.listingId = listingId;
        listing.nodeId = nodeId;
        listing.provider = provider;
        listing.tier = tier;
        listing.storageGB = storageGB;
        listing.hourlyRate = hourlyRate;
        listing.region = region;
        listing.status = ListingStatus.ACTIVE;
        listing.createdAt = block.timestamp;
        listing.updatedAt = block.timestamp;
        listing.expiresAt = block.timestamp + 30 days; // Default 30 day expiration
        listing.isActive = true;

        // Update indexes
        providerStorageListings[provider].push(listingId);
        nodeListings[nodeId].push(listingId);
        storageListingsByTier[tier].push(listingId);
        listingsByRegion[region].push(listingId);

        totalStorageListings++;
        activeStorageListings++;

        emit ResourceDataUpdated(listingId, "storage_created");
        return listingId;
    }

    /**
     * @dev Update storage listing status
     * @param listingId Listing identifier
     * @param status New status
     */
    function updateStorageListingStatus(
        bytes32 listingId,
        ListingStatus status
    ) external onlyLogic {
        require(
            storageListings[listingId].listingId != bytes32(0),
            "Listing does not exist"
        );

        StorageListing storage listing = storageListings[listingId];
        ListingStatus oldStatus = listing.status;
        listing.status = status;
        listing.updatedAt = block.timestamp;

        bool newActive = (status == ListingStatus.ACTIVE);
        bool oldActive = (oldStatus == ListingStatus.ACTIVE);

        if (newActive != oldActive) {
            listing.isActive = newActive;
            if (newActive) {
                activeStorageListings++;
            } else {
                activeStorageListings--;
            }
        }

        emit ResourceDataUpdated(listingId, "storage_status");
    }

    // =============================================================================
    // RESOURCE ALLOCATION FUNCTIONS
    // =============================================================================

    /**
     * @dev Allocate compute resources
     * @param listingId Associated listing ID
     * @param customer Customer address
     * @param duration Duration in hours
     * @param totalCost Total cost in wei
     * @return allocationId Unique allocation identifier
     */
    function allocateCompute(
        bytes32 listingId,
        address customer,
        uint256 duration,
        uint256 totalCost
    ) external onlyLogic returns (bytes32 allocationId) {
        require(computeListings[listingId].isActive, "Listing not active");

        allocationId = keccak256(
            abi.encodePacked("allocation", nextAllocationId, block.timestamp)
        );
        nextAllocationId++;

        ComputeListing memory listing = computeListings[listingId];

        ResourceAllocation storage allocation = allocations[allocationId];
        allocation.allocationId = allocationId;
        allocation.listingId = listingId;
        allocation.customer = customer;
        allocation.provider = listing.provider;
        allocation.nodeId = listing.nodeId;
        allocation.status = AllocationStatus.PENDING;
        allocation.duration = duration;
        allocation.totalCost = totalCost;
        allocation.createdAt = block.timestamp;
        allocation.expiresAt = block.timestamp + (duration * 1 hours);
        allocation.isActive = true;

        // Update indexes
        customerAllocations[customer].push(allocationId);

        totalAllocations++;
        activeAllocations++;

        emit ResourceDataUpdated(allocationId, "allocation_created");
        return allocationId;
    }

    /**
     * @dev Update allocation status
     * @param allocationId Allocation identifier
     * @param status New status
     */
    function updateAllocationStatus(
        bytes32 allocationId,
        AllocationStatus status
    ) external onlyLogic {
        require(
            allocations[allocationId].allocationId != bytes32(0),
            "Allocation does not exist"
        );

        ResourceAllocation storage allocation = allocations[allocationId];
        AllocationStatus oldStatus = allocation.status;
        allocation.status = status;

        if (
            status == AllocationStatus.ACTIVE &&
            oldStatus == AllocationStatus.PENDING
        ) {
            allocation.startedAt = block.timestamp;
        } else if (
            status == AllocationStatus.COMPLETED ||
            status == AllocationStatus.CANCELLED ||
            status == AllocationStatus.FAILED
        ) {
            allocation.completedAt = block.timestamp;
            allocation.isActive = false;
            if (
                oldStatus == AllocationStatus.ACTIVE ||
                oldStatus == AllocationStatus.PENDING
            ) {
                activeAllocations--;
            }
        }

        emit ResourceDataUpdated(allocationId, "allocation_status");
    }

    // =============================================================================
    // VIEW FUNCTIONS
    // =============================================================================

    /**
     * @dev Get compute listing
     * @param listingId Listing identifier
     * @return Compute listing struct
     */
    function getComputeListing(
        bytes32 listingId
    ) external view returns (ComputeListing memory) {
        require(
            computeListings[listingId].listingId != bytes32(0),
            "Listing does not exist"
        );
        return computeListings[listingId];
    }

    /**
     * @dev Get storage listing
     * @param listingId Listing identifier
     * @return Storage listing struct
     */
    function getStorageListing(
        bytes32 listingId
    ) external view returns (StorageListing memory) {
        require(
            storageListings[listingId].listingId != bytes32(0),
            "Listing does not exist"
        );
        return storageListings[listingId];
    }

    /**
     * @dev Get resource allocation
     * @param allocationId Allocation identifier
     * @return Resource allocation struct
     */
    function getAllocation(
        bytes32 allocationId
    ) external view returns (ResourceAllocation memory) {
        require(
            allocations[allocationId].allocationId != bytes32(0),
            "Allocation does not exist"
        );
        return allocations[allocationId];
    }

    /**
     * @dev Get compute listings by provider
     * @param provider Provider address
     * @return Array of listing IDs
     */
    function getProviderComputeListings(
        address provider
    ) external view returns (bytes32[] memory) {
        return providerComputeListings[provider];
    }

    /**
     * @dev Get storage listings by provider
     * @param provider Provider address
     * @return Array of listing IDs
     */
    function getProviderStorageListings(
        address provider
    ) external view returns (bytes32[] memory) {
        return providerStorageListings[provider];
    }

    /**
     * @dev Get allocations by customer
     * @param customer Customer address
     * @return Array of allocation IDs
     */
    function getCustomerAllocations(
        address customer
    ) external view returns (bytes32[] memory) {
        return customerAllocations[customer];
    }

    /**
     * @dev Get compute listings by tier
     * @param tier Compute tier
     * @return Array of listing IDs
     */
    function getComputeListingsByTier(
        ComputeTier tier
    ) external view returns (bytes32[] memory) {
        return computeListingsByTier[tier];
    }

    /**
     * @dev Get storage listings by tier
     * @param tier Storage tier
     * @return Array of listing IDs
     */
    function getStorageListingsByTier(
        StorageTier tier
    ) external view returns (bytes32[] memory) {
        return storageListingsByTier[tier];
    }

    /**
     * @dev Get listings by region
     * @param region Geographic region
     * @return Array of listing IDs
     */
    function getListingsByRegion(
        string calldata region
    ) external view returns (bytes32[] memory) {
        return listingsByRegion[region];
    }

    /**
     * @dev Get total statistics
     * @return computeListingsCount Total compute listings
     * @return storageListingsCount Total storage listings
     * @return totalAllocs Total allocations
     * @return activeCompute Active compute listings
     * @return activeStorage Active storage listings
     * @return activeAllocs Active allocations
     */
    function getStats()
        external
        view
        returns (
            uint256 computeListingsCount,
            uint256 storageListingsCount,
            uint256 totalAllocs,
            uint256 activeCompute,
            uint256 activeStorage,
            uint256 activeAllocs
        )
    {
        return (
            totalComputeListings,
            totalStorageListings,
            totalAllocations,
            activeComputeListings,
            activeStorageListings,
            activeAllocations
        );
    }

    /**
     * @dev Get total allocations count
     * @return Total number of allocations
     */
    function getTotalAllocations() external view returns (uint256) {
        return totalAllocations;
    }

    // =============================================================================
    // PERFORMANCE METRICS FUNCTIONS
    // =============================================================================

    /**
     * @dev Update listing performance metrics
     * @param listingId Listing identifier
     * @param metrics Performance metrics
     */
    function updateListingMetrics(
        bytes32 listingId,
        PerformanceMetrics calldata metrics
    ) external onlyLogic {
        listingMetrics[listingId] = metrics;
        emit ResourceDataUpdated(listingId, "metrics");
    }

    /**
     * @dev Get listing performance metrics
     * @param listingId Listing identifier
     * @return Performance metrics struct
     */
    function getListingMetrics(
        bytes32 listingId
    ) external view returns (PerformanceMetrics memory) {
        return listingMetrics[listingId];
    }
}
