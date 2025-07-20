// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ValidationLibrary
 * @notice Shared validation functions and constants for production-grade input validation
 * @dev Provides gas-efficient validation with custom errors
 */
library ValidationLibrary {
    // =============================================================================
    // CONSTANTS
    // =============================================================================
    
    // Cluster limits
    uint256 public constant MIN_CLUSTER_SIZE = 1;
    uint256 public constant MAX_CLUSTER_SIZE = 100;
    uint256 public constant MIN_ACTIVE_NODES = 1;
    uint256 public constant MAX_REGIONS_PER_CLUSTER = 10;
    
    // Resource allocation limits (in GB)
    uint256 public constant MIN_STORAGE_ALLOCATION = 1; // 1 GB minimum
    uint256 public constant MAX_STORAGE_ALLOCATION = 100_000; // 100 TB maximum
    uint256 public constant MIN_MEMORY_ALLOCATION = 1; // 1 GB minimum
    uint256 public constant MAX_MEMORY_ALLOCATION = 1_000; // 1 TB maximum
    uint256 public constant MIN_CPU_ALLOCATION = 1; // 1 vCPU minimum
    uint256 public constant MAX_CPU_ALLOCATION = 256; // 256 vCPUs maximum
    
    // Reward limits (in wei)
    uint256 public constant MIN_REWARD_AMOUNT = 1e15; // 0.001 ETH
    uint256 public constant MAX_REWARD_AMOUNT = 100e18; // 100 ETH
    uint256 public constant MAX_DAILY_REWARDS_PER_OPERATOR = 1000e18; // 1000 ETH
    uint256 public constant MAX_MONTHLY_REWARDS_PER_OPERATOR = 30000e18; // 30000 ETH
    
    // Performance score limits
    uint256 public constant MIN_PERFORMANCE_SCORE = 0;
    uint256 public constant MAX_PERFORMANCE_SCORE = 100;
    uint256 public constant PERFORMANCE_SCALE = 100; // For percentage calculations
    
    // String length limits
    uint256 public constant MIN_ID_LENGTH = 3;
    uint256 public constant MAX_ID_LENGTH = 64;
    uint256 public constant MAX_METADATA_LENGTH = 1024;
    uint256 public constant MAX_DESCRIPTION_LENGTH = 512;
    uint256 public constant MAX_REGION_LENGTH = 32;
    uint256 public constant MAX_VERSION_LENGTH = 16;
    
    // Time limits
    uint256 public constant MIN_REWARD_INTERVAL = 1 hours;
    uint256 public constant MAX_REWARD_INTERVAL = 30 days;
    uint256 public constant MIN_CLUSTER_UPDATE_INTERVAL = 5 minutes;
    
    // Numeric limits
    uint256 public constant MAX_UINT64 = type(uint64).max;
    uint256 public constant MAX_UINT32 = type(uint32).max;
    uint256 public constant MAX_UINT16 = type(uint16).max;
    uint256 public constant MAX_UINT8 = type(uint8).max;
    
    // Geographic distribution
    uint256 public constant MIN_GEOGRAPHIC_DISTRIBUTION = 2; // Minimum regions for redundancy
    uint256 public constant MAX_NODES_PER_REGION = 50;

    // =============================================================================
    // CUSTOM ERRORS
    // =============================================================================
    
    // Address validation errors
    error InvalidAddress(address addr);
    error ZeroAddress();
    error SameAddress(address addr1, address addr2);
    
    // String validation errors
    error InvalidStringLength(string str, uint256 minLength, uint256 maxLength);
    error EmptyString();
    error InvalidCharacters(string str);
    
    // Numeric validation errors
    error InvalidRange(uint256 value, uint256 min, uint256 max);
    error InvalidPerformanceScore(uint256 score);
    error InvalidRewardAmount(uint256 amount);
    error ExceedsMaximum(uint256 value, uint256 maximum);
    error BelowMinimum(uint256 value, uint256 minimum);
    
    // Cluster validation errors
    error InvalidClusterSize(uint256 size);
    error InsufficientGeographicDistribution(uint256 regions, uint256 required);
    error TooManyNodesPerRegion(string region, uint256 nodeCount);
    error DuplicateNode(string nodeId);
    
    // Resource validation errors
    error InvalidResourceAllocation(string resource, uint256 amount);
    error InsufficientResources(uint256 requested, uint256 available);
    
    // Reward validation errors
    error DailyRewardLimitExceeded(address operator, uint256 amount);
    error MonthlyRewardLimitExceeded(address operator, uint256 amount);
    error RewardIntervalTooShort(uint256 interval);
    
    // Time validation errors
    error InvalidTimestamp(uint256 timestamp);
    error TimestampInFuture(uint256 timestamp);
    error TimestampTooOld(uint256 timestamp, uint256 maxAge);

    // =============================================================================
    // ADDRESS VALIDATION
    // =============================================================================
    
    /**
     * @dev Validates that an address is not zero
     */
    function validateAddress(address addr) internal pure {
        if (addr == address(0)) revert ZeroAddress();
    }
    
    /**
     * @dev Validates that addresses are different
     */
    function validateDifferentAddresses(address addr1, address addr2) internal pure {
        if (addr1 == addr2) revert SameAddress(addr1, addr2);
    }
    
    /**
     * @dev Validates multiple addresses are not zero
     */
    function validateAddresses(address[] memory addresses) internal pure {
        for (uint256 i = 0; i < addresses.length; i++) {
            validateAddress(addresses[i]);
        }
    }

    // =============================================================================
    // STRING VALIDATION
    // =============================================================================
    
    /**
     * @dev Validates string length within bounds
     */
    function validateStringLength(string memory str, uint256 minLength, uint256 maxLength) internal pure {
        uint256 length = bytes(str).length;
        if (length < minLength || length > maxLength) {
            revert InvalidStringLength(str, minLength, maxLength);
        }
    }
    
    /**
     * @dev Validates ID format and length
     */
    function validateId(string memory id) internal pure {
        validateStringLength(id, MIN_ID_LENGTH, MAX_ID_LENGTH);
        
        bytes memory idBytes = bytes(id);
        for (uint256 i = 0; i < idBytes.length; i++) {
            bytes1 char = idBytes[i];
            // Allow alphanumeric, hyphens, and underscores
            if (!(
                (char >= 0x30 && char <= 0x39) || // 0-9
                (char >= 0x41 && char <= 0x5A) || // A-Z
                (char >= 0x61 && char <= 0x7A) || // a-z
                char == 0x2D || // -
                char == 0x5F    // _
            )) {
                revert InvalidCharacters(id);
            }
        }
    }
    
    /**
     * @dev Validates metadata length
     */
    function validateMetadata(string memory metadata) internal pure {
        validateStringLength(metadata, 0, MAX_METADATA_LENGTH);
    }
    
    /**
     * @dev Validates region string
     */
    function validateRegion(string memory region) internal pure {
        validateStringLength(region, 2, MAX_REGION_LENGTH);
    }

    // =============================================================================
    // NUMERIC VALIDATION
    // =============================================================================
    
    /**
     * @dev Validates a value is within a specific range
     */
    function validateRange(uint256 value, uint256 min, uint256 max) internal pure {
        if (value < min || value > max) {
            revert InvalidRange(value, min, max);
        }
    }
    
    /**
     * @dev Validates performance score (0-100)
     */
    function validatePerformanceScore(uint256 score) internal pure {
        if (score > MAX_PERFORMANCE_SCORE) {
            revert InvalidPerformanceScore(score);
        }
    }
    
    /**
     * @dev Validates multiple performance scores
     */
    function validatePerformanceScores(uint256[] memory scores) internal pure {
        for (uint256 i = 0; i < scores.length; i++) {
            validatePerformanceScore(scores[i]);
        }
    }
    
    /**
     * @dev Validates reward amount
     */
    function validateRewardAmount(uint256 amount) internal pure {
        if (amount < MIN_REWARD_AMOUNT || amount > MAX_REWARD_AMOUNT) {
            revert InvalidRewardAmount(amount);
        }
    }
    
    /**
     * @dev Validates uint256 fits in smaller uint type
     */
    function validateUint64(uint256 value) internal pure {
        if (value > MAX_UINT64) revert ExceedsMaximum(value, MAX_UINT64);
    }
    
    function validateUint32(uint256 value) internal pure {
        if (value > MAX_UINT32) revert ExceedsMaximum(value, MAX_UINT32);
    }
    
    function validateUint16(uint256 value) internal pure {
        if (value > MAX_UINT16) revert ExceedsMaximum(value, MAX_UINT16);
    }
    
    function validateUint8(uint256 value) internal pure {
        if (value > MAX_UINT8) revert ExceedsMaximum(value, MAX_UINT8);
    }

    // =============================================================================
    // CLUSTER VALIDATION
    // =============================================================================
    
    /**
     * @dev Validates cluster size
     */
    function validateClusterSize(uint256 size) internal pure {
        if (size < MIN_CLUSTER_SIZE || size > MAX_CLUSTER_SIZE) {
            revert InvalidClusterSize(size);
        }
    }
    
    /**
     * @dev Validates geographic distribution for redundancy
     */
    function validateGeographicDistribution(string[] memory regions) internal pure {
        if (regions.length < MIN_GEOGRAPHIC_DISTRIBUTION) {
            revert InsufficientGeographicDistribution(regions.length, MIN_GEOGRAPHIC_DISTRIBUTION);
        }
        
        // Validate each region string
        for (uint256 i = 0; i < regions.length; i++) {
            validateRegion(regions[i]);
        }
        
        // Check for duplicates
        for (uint256 i = 0; i < regions.length; i++) {
            for (uint256 j = i + 1; j < regions.length; j++) {
                if (keccak256(bytes(regions[i])) == keccak256(bytes(regions[j]))) {
                    revert InvalidCharacters("Duplicate region");
                }
            }
        }
    }
    
    /**
     * @dev Validates node IDs for uniqueness
     */
    function validateUniqueNodeIds(string[] memory nodeIds) internal pure {
        for (uint256 i = 0; i < nodeIds.length; i++) {
            validateId(nodeIds[i]);
            
            // Check for duplicates
            for (uint256 j = i + 1; j < nodeIds.length; j++) {
                if (keccak256(bytes(nodeIds[i])) == keccak256(bytes(nodeIds[j]))) {
                    revert DuplicateNode(nodeIds[i]);
                }
            }
        }
    }

    // =============================================================================
    // RESOURCE VALIDATION
    // =============================================================================
    
    /**
     * @dev Validates storage allocation
     */
    function validateStorageAllocation(uint256 storageGB) internal pure {
        if (storageGB < MIN_STORAGE_ALLOCATION || storageGB > MAX_STORAGE_ALLOCATION) {
            revert InvalidResourceAllocation("storage", storageGB);
        }
    }
    
    /**
     * @dev Validates memory allocation
     */
    function validateMemoryAllocation(uint256 memoryGB) internal pure {
        if (memoryGB < MIN_MEMORY_ALLOCATION || memoryGB > MAX_MEMORY_ALLOCATION) {
            revert InvalidResourceAllocation("memory", memoryGB);
        }
    }
    
    /**
     * @dev Validates CPU allocation
     */
    function validateCpuAllocation(uint256 cpuCores) internal pure {
        if (cpuCores < MIN_CPU_ALLOCATION || cpuCores > MAX_CPU_ALLOCATION) {
            revert InvalidResourceAllocation("cpu", cpuCores);
        }
    }
    
    /**
     * @dev Validates complete resource allocation
     */
    function validateResourceAllocations(uint256 storageGB, uint256 memoryGB, uint256 cpuCores) internal pure {
        validateStorageAllocation(storageGB);
        validateMemoryAllocation(memoryGB);
        validateCpuAllocation(cpuCores);
    }

    // =============================================================================
    // TIME VALIDATION
    // =============================================================================
    
    /**
     * @dev Validates timestamp is not in the future
     */
    function validateTimestamp(uint256 timestamp) internal view {
        if (timestamp > block.timestamp) {
            revert TimestampInFuture(timestamp);
        }
    }
    
    /**
     * @dev Validates timestamp is not too old
     */
    function validateTimestampAge(uint256 timestamp, uint256 maxAge) internal view {
        validateTimestamp(timestamp);
        if (block.timestamp - timestamp > maxAge) {
            revert TimestampTooOld(timestamp, maxAge);
        }
    }
    
    /**
     * @dev Validates reward interval
     */
    function validateRewardInterval(uint256 interval) internal pure {
        if (interval < MIN_REWARD_INTERVAL || interval > MAX_REWARD_INTERVAL) {
            revert RewardIntervalTooShort(interval);
        }
    }

    // =============================================================================
    // BATCH VALIDATION
    // =============================================================================
    
    /**
     * @dev Validates array is not empty and within size limits
     */
    function validateArrayLength(uint256 length, uint256 minLength, uint256 maxLength) internal pure {
        if (length < minLength) revert BelowMinimum(length, minLength);
        if (length > maxLength) revert ExceedsMaximum(length, maxLength);
    }
    
    /**
     * @dev Validates that array indices are within bounds
     */
    function validateArrayIndex(uint256 index, uint256 arrayLength) internal pure {
        if (index >= arrayLength) revert InvalidRange(index, 0, arrayLength - 1);
    }
    
    /**
     * @dev Validates pagination parameters
     */
    function validatePagination(uint256 offset, uint256 limit, uint256 maxLimit) internal pure {
        if (limit == 0) revert BelowMinimum(limit, 1);
        if (limit > maxLimit) revert ExceedsMaximum(limit, maxLimit);
    }
}
