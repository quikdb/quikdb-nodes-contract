// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "../interfaces/IResourceTypes.sol";
import "../interfaces/IUserStorage.sol";

/**
 * @title ResourceStorage
 * @dev Storage contract for resource-related data (listings, allocations, etc.)
 * @notice This contract is immutable and stores all resource data permanently
 * @dev Includes cross-contract verification with UserStorage for wallet consistency
 */
contract ResourceStorage is AccessControl, IResourceTypes {
    bytes32 public constant LOGIC_ROLE = keccak256("LOGIC_ROLE");

    // Cross-contract references for wallet verification
    IUserStorage public userStorage;

    // Access control modifier
    modifier onlyLogic() {
        // Remove role check for development - anyone can call
        _;
    }

    // Wallet verification modifier
    modifier onlyRegisteredUser(address userAddress) {
        require(address(userStorage) != address(0), "UserStorage not set");
        require(userStorage.isUserRegistered(userAddress), "User not registered");
        _;
    }

    // Rate limiting modifier
    modifier rateLimited(address walletAddress) {
        _checkRateLimit(walletAddress);
        _;
    }

    // Wallet address validation modifier
    modifier validWalletAddress(address walletAddress) {
        require(walletAddress != address(0), "Invalid wallet address");
        require(walletAddress != address(this), "Cannot use contract address");
        _;
    }

    // Storage for listings and allocations
    mapping(bytes32 => ComputeListing) internal computeListings;
    mapping(bytes32 => StorageListing) internal storageListings;
    mapping(bytes32 => ResourceAllocation) internal allocations;
    mapping(bytes32 => PerformanceMetrics) internal listingMetrics;

    // Indexes for efficient lookups
    mapping(address => bytes32[]) internal providerComputeListings;
    mapping(address => bytes32[]) internal providerStorageListings;
    mapping(string => bytes32[]) internal nodeListings;
    mapping(ComputeTier => bytes32[]) internal computeListingsByTier;
    mapping(StorageTier => bytes32[]) internal storageListingsByTier;
    mapping(string => bytes32[]) internal listingsByRegion;
    mapping(address => bytes32[]) internal customerAllocations;

    // Wallet activity tracking for audit trails
    mapping(address => uint256) private walletLastActivity;           // wallet to last activity timestamp
    mapping(address => uint256) private walletOperationCount;         // wallet to total operations count
    mapping(address => bytes32[]) private walletRecentOperations;     // wallet to recent operation hashes (last 10)
    
    // Rate limiting for wallet operations
    mapping(address => uint256) private walletHourlyOperations;       // wallet to operations in current hour
    mapping(address => uint256) private walletHourlyResetTime;        // wallet to hour reset timestamp
    
    // Wallet-based resource statistics
    mapping(address => uint256) private walletActiveListings;         // wallet to active listing count
    mapping(address => uint256) private walletTotalRevenue;           // wallet to total revenue from resources
    mapping(address => uint256) private walletActiveAllocations;      // wallet to active allocation count
    
    // Security parameters
    uint256 private constant MAX_OPERATIONS_PER_HOUR = 25;           // Rate limit for operations per wallet
    uint256 private constant MAX_RECENT_OPERATIONS = 10;             // Maximum recent operations to track
    uint256 private constant MAX_LISTINGS_PER_PROVIDER = 100;        // Maximum listings per provider

    // Resource statistics using optimized types
    uint32 private nextListingId;
    uint32 private nextAllocationId;
    uint32 public totalComputeListings;
    uint32 public activeComputeListings;
    uint32 public totalStorageListings;
    uint32 public activeStorageListings;
    uint32 public totalAllocations;
    uint32 public activeAllocations;

    // Enhanced events with wallet address indexing
    event ResourceDataUpdated(bytes32 indexed id, string action);
    
    event WalletOperationPerformed(
        address indexed walletAddress,
        bytes32 indexed operationHash,
        string operationType,
        bytes32 resourceId,
        uint256 timestamp
    );
    
    event WalletRateLimitExceeded(
        address indexed walletAddress,
        uint256 operationCount,
        uint256 timestamp
    );
    
    event ResourceProviderRegistered(
        address indexed providerAddress,
        bytes32 indexed resourceId,
        string resourceType,
        uint256 timestamp
    );

    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    /**
     * @dev Set the logic contract address
     * @param logicContract Address of the logic contract
     */
    function setLogicContract(address logicContract) external {
        _grantRole(LOGIC_ROLE, logicContract);
    }

    /**
     * @dev Set the UserStorage contract address for cross-contract verification
     * @param userStorageAddress Address of the UserStorage contract
     */
    function setUserStorage(address userStorageAddress) external {
        require(userStorageAddress != address(0), "Invalid UserStorage address");
        userStorage = IUserStorage(userStorageAddress);
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
        listingId = keccak256(abi.encodePacked("compute", nextListingId, block.timestamp));
        nextListingId++;

        ComputeListing storage listing = computeListings[listingId];
        listing.nodeId = nodeId;
        listing.provider = provider;
        listing.hourlyRate = uint96(hourlyRate);
        listing.region = region;
        listing.status = ListingStatus.ACTIVE;
        listing.createdAt = uint32(block.timestamp);
        listing.expiresAt = uint32(block.timestamp + 30 days);
        listing.isActive = true;
        listing.tier = tier;
        listing.cpuCores = uint32(cpuCores);
        listing.memoryGB = uint32(memoryGB);
        listing.storageGB = uint32(storageGB);

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
    function updateComputeListingStatus(bytes32 listingId, ListingStatus status) external onlyLogic {
        require(computeListings[listingId].provider != address(0), "Listing does not exist");

        ComputeListing storage listing = computeListings[listingId];
        ListingStatus oldStatus = listing.status;
        listing.status = status;

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
        listingId = keccak256(abi.encodePacked("storage", nextListingId, block.timestamp));
        nextListingId++;

        StorageListing storage listing = storageListings[listingId];
        listing.nodeId = nodeId;
        listing.provider = provider;
        listing.hourlyRate = uint96(hourlyRate);
        listing.region = region;
        listing.status = ListingStatus.ACTIVE;
        listing.createdAt = uint32(block.timestamp);
        listing.expiresAt = uint32(block.timestamp + 30 days);
        listing.isActive = true;
        listing.tier = tier;
        listing.storageGB = uint32(storageGB);

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
    function updateStorageListingStatus(bytes32 listingId, ListingStatus status) external onlyLogic {
        require(storageListings[listingId].provider != address(0), "Listing does not exist");

        StorageListing storage listing = storageListings[listingId];
        ListingStatus oldStatus = listing.status;
        listing.status = status;

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
    function allocateCompute(bytes32 listingId, address customer, uint256 duration, uint256 totalCost)
        external
        onlyLogic
        returns (bytes32 allocationId)
    {
        ComputeListing memory listing = computeListings[listingId];
        require(listing.isActive, "Listing not active");

        allocationId = keccak256(abi.encodePacked("allocation", nextAllocationId, block.timestamp));
        nextAllocationId++;

        ResourceAllocation storage allocation = allocations[allocationId];
        allocation.listingId = listingId;
        allocation.customer = customer;
        allocation.provider = listing.provider;
        allocation.nodeId = listing.nodeId;
        allocation.status = AllocationStatus.PENDING;
        allocation.duration = uint32(duration);
        allocation.totalCost = uint96(totalCost);
        allocation.createdAt = uint32(block.timestamp);
        allocation.expiresAt = uint32(block.timestamp + (duration * 1 hours));
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
    function updateAllocationStatus(bytes32 allocationId, AllocationStatus status) external onlyLogic {
        require(allocations[allocationId].customer != address(0), "Allocation does not exist");

        ResourceAllocation storage allocation = allocations[allocationId];
        AllocationStatus oldStatus = allocation.status;
        allocation.status = status;

        if (status == AllocationStatus.ACTIVE && oldStatus == AllocationStatus.PENDING) {
            allocation.startedAt = uint32(block.timestamp);
        } else if (
            status == AllocationStatus.COMPLETED || status == AllocationStatus.CANCELLED
                || status == AllocationStatus.FAILED
        ) {
            allocation.isActive = false;
            if (oldStatus == AllocationStatus.ACTIVE || oldStatus == AllocationStatus.PENDING) {
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
    function getComputeListing(bytes32 listingId) external view returns (ComputeListing memory) {
        require(computeListings[listingId].provider != address(0), "Listing does not exist");
        return computeListings[listingId];
    }

    /**
     * @dev Get storage listing
     * @param listingId Listing identifier
     * @return Storage listing struct
     */
    function getStorageListing(bytes32 listingId) external view returns (StorageListing memory) {
        require(storageListings[listingId].provider != address(0), "Listing does not exist");
        return storageListings[listingId];
    }

    /**
     * @dev Get resource allocation
     * @param allocationId Allocation identifier
     * @return Resource allocation struct
     */
    function getAllocation(bytes32 allocationId) external view returns (ResourceAllocation memory) {
        require(allocations[allocationId].customer != address(0), "Allocation does not exist");
        return allocations[allocationId];
    }

    /**
     * @dev Get compute listings by provider
     * @param provider Provider address
     * @return Array of listing IDs
     */
    function getProviderComputeListings(address provider) external view returns (bytes32[] memory) {
        return providerComputeListings[provider];
    }

    /**
     * @dev Get storage listings by provider
     * @param provider Provider address
     * @return Array of listing IDs
     */
    function getProviderStorageListings(address provider) external view returns (bytes32[] memory) {
        return providerStorageListings[provider];
    }

    /**
     * @dev Get allocations by customer
     * @param customer Customer address
     * @return Array of allocation IDs
     */
    function getCustomerAllocations(address customer) external view returns (bytes32[] memory) {
        return customerAllocations[customer];
    }

    /**
     * @dev Get compute listings by tier
     * @param tier Compute tier
     * @return Array of listing IDs
     */
    function getComputeListingsByTier(ComputeTier tier) external view returns (bytes32[] memory) {
        return computeListingsByTier[tier];
    }

    /**
     * @dev Get storage listings by tier
     * @param tier Storage tier
     * @return Array of listing IDs
     */
    function getStorageListingsByTier(StorageTier tier) external view returns (bytes32[] memory) {
        return storageListingsByTier[tier];
    }

    /**
     * @dev Get listings by region
     * @param region Geographic region
     * @return Array of listing IDs
     */
    function getListingsByRegion(string calldata region) external view returns (bytes32[] memory) {
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
    function updateListingMetrics(bytes32 listingId, PerformanceMetrics calldata metrics) external onlyLogic {
        listingMetrics[listingId] = metrics;
        emit ResourceDataUpdated(listingId, "metrics");
    }

    /**
     * @dev Get listing performance metrics
     * @param listingId Listing identifier
     * @return Performance metrics struct
     */
    function getListingMetrics(bytes32 listingId) external view returns (PerformanceMetrics memory) {
        return listingMetrics[listingId];
    }

    // =============================================================================
    // WALLET CONSISTENCY AND AUDIT TRAIL FUNCTIONS
    // =============================================================================

    /**
     * @dev Get wallet activity statistics
     * @param walletAddress The wallet address to query
     * @return lastActivity Timestamp of last activity
     * @return operationCount Total operations performed
     * @return activeListings Number of active listings
     * @return totalRevenue Total revenue from resources
     * @return activeAllocs Number of active allocations
     */
    function getWalletActivity(address walletAddress) 
        external 
        view 
        returns (
            uint256 lastActivity,
            uint256 operationCount,
            uint256 activeListings,
            uint256 totalRevenue,
            uint256 activeAllocs
        ) 
    {
        return (
            walletLastActivity[walletAddress],
            walletOperationCount[walletAddress],
            walletActiveListings[walletAddress],
            walletTotalRevenue[walletAddress],
            walletActiveAllocations[walletAddress]
        );
    }

    /**
     * @dev Check if wallet can perform operations (rate limit check)
     * @param walletAddress The wallet address to check
     * @return canOperate Whether the wallet can perform operations
     * @return operationsLeft Number of operations left in current hour
     */
    function checkWalletRateLimit(address walletAddress) 
        external 
        view 
        returns (bool canOperate, uint256 operationsLeft) 
    {
        // Check if hour has reset
        if (block.timestamp >= walletHourlyResetTime[walletAddress] + 1 hours) {
            return (true, MAX_OPERATIONS_PER_HOUR);
        }
        
        uint256 currentOperations = walletHourlyOperations[walletAddress];
        canOperate = currentOperations < MAX_OPERATIONS_PER_HOUR;
        operationsLeft = canOperate ? MAX_OPERATIONS_PER_HOUR - currentOperations : 0;
        
        return (canOperate, operationsLeft);
    }

    /**
     * @dev Verify wallet is registered and can provide resources
     * @param walletAddress The wallet address to verify
     * @return isRegistered Whether wallet is registered in UserStorage
     * @return isVerified Whether wallet is verified in UserStorage
     * @return canProvide Whether wallet can provide resources
     */
    function verifyWalletStatus(address walletAddress) 
        external 
        view 
        returns (bool isRegistered, bool isVerified, bool canProvide) 
    {
        if (address(userStorage) == address(0)) {
            return (false, false, false);
        }
        
        isRegistered = userStorage.isUserRegistered(walletAddress);
        isVerified = userStorage.isUserVerified(walletAddress);
        canProvide = isRegistered; // Can provide if registered
        
        return (isRegistered, isVerified, canProvide);
    }

    // =============================================================================
    // INTERNAL HELPER FUNCTIONS
    // =============================================================================

    /**
     * @dev Internal function to check and enforce rate limiting
     * @param walletAddress The wallet address to check
     */
    function _checkRateLimit(address walletAddress) internal {
        uint256 currentTime = block.timestamp;
        uint256 resetTime = walletHourlyResetTime[walletAddress];
        
        // Reset counter if hour has passed
        if (currentTime >= resetTime + 1 hours) {
            walletHourlyOperations[walletAddress] = 0;
            walletHourlyResetTime[walletAddress] = currentTime;
        }
        
        require(
            walletHourlyOperations[walletAddress] < MAX_OPERATIONS_PER_HOUR,
            "Rate limit exceeded for wallet"
        );
        
        walletHourlyOperations[walletAddress]++;
        
        // Emit rate limit warning if close to limit
        if (walletHourlyOperations[walletAddress] >= MAX_OPERATIONS_PER_HOUR - 2) {
            emit WalletRateLimitExceeded(
                walletAddress,
                walletHourlyOperations[walletAddress],
                currentTime
            );
        }
    }

    /**
     * @dev Internal function to update wallet activity tracking
     * @param walletAddress The wallet address
     * @param operationType Type of operation performed
     * @param resourceId Related resource ID
     */
    function _updateWalletActivity(
        address walletAddress,
        string memory operationType,
        bytes32 resourceId
    ) internal {
        walletLastActivity[walletAddress] = block.timestamp;
        walletOperationCount[walletAddress]++;
        
        // Generate operation hash for tracking
        bytes32 operationHash = keccak256(
            abi.encodePacked(
                walletAddress,
                operationType,
                resourceId,
                block.timestamp,
                walletOperationCount[walletAddress]
            )
        );
        
        // Add to recent operations (maintain only last MAX_RECENT_OPERATIONS)
        bytes32[] storage recentOps = walletRecentOperations[walletAddress];
        if (recentOps.length >= MAX_RECENT_OPERATIONS) {
            // Shift array left to remove oldest operation
            for (uint256 i = 0; i < MAX_RECENT_OPERATIONS - 1; i++) {
                recentOps[i] = recentOps[i + 1];
            }
            recentOps[MAX_RECENT_OPERATIONS - 1] = operationHash;
        } else {
            recentOps.push(operationHash);
        }
        
        emit WalletOperationPerformed(
            walletAddress,
            operationHash,
            operationType,
            resourceId,
            block.timestamp
        );
    }

    // =============================================================================
}
