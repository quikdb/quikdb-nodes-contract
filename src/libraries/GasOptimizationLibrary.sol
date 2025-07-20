// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title GasOptimizationLibrary
 * @notice Gas optimization utilities for efficient contract operations
 * @dev Provides assembly optimizations, batch operations, and efficient data structures
 */
library GasOptimizationLibrary {
    // ---------------------------------------------------------------------
    // Constants for gas optimization
    // ---------------------------------------------------------------------
    
    uint256 private constant BATCH_SIZE_LIMIT = 100;
    uint256 private constant PAGE_SIZE_DEFAULT = 50;
    uint256 private constant PAGE_SIZE_MAX = 200;
    
    // ---------------------------------------------------------------------
    // Structs for packed storage
    // ---------------------------------------------------------------------
    
    struct PackedNodeInfo {
        address nodeAddress;     // 20 bytes
        uint64 timestamp;        // 8 bytes  
        uint32 capacity;         // 4 bytes
        uint32 status;           // 4 bytes
        // Total: 36 bytes (fits in 2 storage slots)
    }
    
    struct PackedClusterInfo {
        uint64 createdAt;        // 8 bytes
        uint64 updatedAt;        // 8 bytes
        uint32 nodeCount;        // 4 bytes
        uint32 strategy;         // 4 bytes
        uint16 minActiveNodes;   // 2 bytes
        uint8 status;            // 1 byte
        bool autoManaged;        // 1 byte
        // Total: 28 bytes (fits in 1 storage slot)
    }
    
    struct PackedRewardInfo {
        address nodeOperator;    // 20 bytes
        uint64 distributionDate; // 8 bytes
        uint32 amount;           // 4 bytes (scaled by 1e12 for precision)
        // Total: 32 bytes (fits in 1 storage slot)
    }
    
    // ---------------------------------------------------------------------
    // Events optimized for indexing
    // ---------------------------------------------------------------------
    
    event BatchClusterRegistered(
        uint256 indexed batchId,
        uint256 clusterCount,
        uint256 totalNodes
    );
    
    event BatchRewardDistributed(
        uint256 indexed batchId,
        uint256 rewardCount,
        uint256 totalAmount
    );
    
    event PaginatedQuery(
        address indexed caller,
        string indexed queryType,
        uint256 offset,
        uint256 limit,
        uint256 totalResults
    );
    
    // ---------------------------------------------------------------------
    // Custom Errors for gas efficiency
    // ---------------------------------------------------------------------
    
    error BatchSizeExceeded(uint256 provided, uint256 maximum);
    error InvalidPagination(uint256 offset, uint256 limit);
    error EmptyBatch();
    error BatchProcessingFailed(uint256 failedIndex);
    
    // ---------------------------------------------------------------------
    // Assembly Optimized Functions
    // ---------------------------------------------------------------------
    
    /**
     * @dev Gas-optimized array length check using assembly
     */
    function checkArrayLength(uint256 length, uint256 maxLength) internal pure {
        assembly {
            if gt(length, maxLength) {
                let ptr := mload(0x40)
                mstore(ptr, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                mstore(add(ptr, 0x04), 0x0000000000000000000000000000000000000000000000000000000000000020)
                mstore(add(ptr, 0x24), 0x0000000000000000000000000000000000000000000000000000000000000011)
                mstore(add(ptr, 0x44), 0x4172726179206c656e67746820746f6f206c6172676500000000000000000000)
                revert(ptr, 0x64)
            }
        }
    }
    
    /**
     * @dev Gas-optimized address validation using assembly
     */
    function validateAddress(address addr) internal pure {
        assembly {
            if iszero(addr) {
                let ptr := mload(0x40)
                mstore(ptr, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                mstore(add(ptr, 0x04), 0x0000000000000000000000000000000000000000000000000000000000000020)
                mstore(add(ptr, 0x24), 0x0000000000000000000000000000000000000000000000000000000000000010)
                mstore(add(ptr, 0x44), 0x496e76616c696420616464726573730000000000000000000000000000000000)
                revert(ptr, 0x64)
            }
        }
    }
    
    /**
     * @dev Gas-optimized array copying using assembly
     */
    function copyArray(string[] memory source, uint256 start, uint256 length) 
        internal 
        pure 
        returns (string[] memory result) 
    {
        require(start + length <= source.length, "Array bounds exceeded");
        
        assembly {
            result := mload(0x40)
            let resultLength := length
            mstore(result, resultLength)
            let resultData := add(result, 0x20)
            let sourceData := add(source, 0x20)
            let sourceStart := add(sourceData, mul(start, 0x20))
            
            for { let i := 0 } lt(i, length) { i := add(i, 1) } {
                let sourceElement := mload(add(sourceStart, mul(i, 0x20)))
                mstore(add(resultData, mul(i, 0x20)), sourceElement)
            }
            
            mstore(0x40, add(resultData, mul(length, 0x20)))
        }
    }
    
    /**
     * @dev Gas-optimized keccak256 for multiple values
     */
    function hashMultiple(bytes32[] memory values) internal pure returns (bytes32 result) {
        assembly {
            let dataPtr := add(values, 0x20)
            let dataSize := mul(mload(values), 0x20)
            result := keccak256(dataPtr, dataSize)
        }
    }
    
    // ---------------------------------------------------------------------
    // Batch Operation Utilities
    // ---------------------------------------------------------------------
    
    /**
     * @dev Validate batch operation parameters
     */
    function validateBatchOperation(uint256 batchSize) internal pure {
        if (batchSize == 0) revert EmptyBatch();
        if (batchSize > BATCH_SIZE_LIMIT) revert BatchSizeExceeded(batchSize, BATCH_SIZE_LIMIT);
    }
    
    /**
     * @dev Generate batch ID for tracking
     */
    function generateBatchId(address caller, uint256 timestamp, uint256 batchSize) 
        internal 
        pure 
        returns (uint256) 
    {
        return uint256(keccak256(abi.encodePacked(caller, timestamp, batchSize)));
    }
    
    /**
     * @dev Efficient pagination parameters validation
     */
    function validatePagination(uint256 offset, uint256 limit, uint256 totalItems) 
        internal 
        pure 
        returns (uint256 adjustedLimit) 
    {
        if (limit == 0 || limit > PAGE_SIZE_MAX) {
            adjustedLimit = PAGE_SIZE_DEFAULT;
        } else {
            adjustedLimit = limit;
        }
        
        if (offset >= totalItems && totalItems > 0) {
            revert InvalidPagination(offset, limit);
        }
        
        // Adjust limit if it would exceed total items
        if (offset + adjustedLimit > totalItems) {
            adjustedLimit = totalItems - offset;
        }
    }
    
    // ---------------------------------------------------------------------
    // Storage Optimization Utilities
    // ---------------------------------------------------------------------
    
    /**
     * @dev Pack multiple uint values into single storage slot
     */
    function packUints(uint32 a, uint32 b, uint32 c, uint32 d) internal pure returns (uint128 packed) {
        assembly {
            packed := or(
                or(
                    or(a, shl(32, b)),
                    shl(64, c)
                ),
                shl(96, d)
            )
        }
    }
    
    /**
     * @dev Unpack uint values from storage slot
     */
    function unpackUints(uint128 packed) 
        internal 
        pure 
        returns (uint32 a, uint32 b, uint32 c, uint32 d) 
    {
        assembly {
            a := and(packed, 0xffffffff)
            b := and(shr(32, packed), 0xffffffff)
            c := and(shr(64, packed), 0xffffffff)
            d := and(shr(96, packed), 0xffffffff)
        }
    }
    
    /**
     * @dev Pack address and timestamp into single storage slot
     */
    function packAddressTimestamp(address addr, uint64 timestampValue) 
        internal 
        pure 
        returns (uint256 packed) 
    {
        assembly {
            packed := or(addr, shl(160, timestampValue))
        }
    }
    
    /**
     * @dev Unpack address and timestamp from storage slot
     */
    function unpackAddressTimestamp(uint256 packed) 
        internal 
        pure 
        returns (address addr, uint64 timestampValue) 
    {
        assembly {
            addr := and(packed, 0xffffffffffffffffffffffffffffffffffffffff)
            timestampValue := shr(160, packed)
        }
    }
    
    // ---------------------------------------------------------------------
    // Lazy Deletion Utilities
    // ---------------------------------------------------------------------
    
    /**
     * @dev Mark element for lazy deletion (gas-efficient)
     */
    function markForDeletion(mapping(uint256 => bool) storage deletedFlags, uint256 index) internal {
        deletedFlags[index] = true;
    }
    
    /**
     * @dev Check if element is deleted
     */
    function isDeleted(mapping(uint256 => bool) storage deletedFlags, uint256 index) 
        internal 
        view 
        returns (bool) 
    {
        return deletedFlags[index];
    }
    
    /**
     * @dev Compact array by removing deleted elements (periodic cleanup)
     */
    function compactStringArray(
        string[] storage array,
        mapping(uint256 => bool) storage deletedFlags,
        uint256 lastCompactionIndex
    ) internal returns (uint256 newLength) {
        uint256 writeIndex = lastCompactionIndex;
        uint256 length = array.length;
        
        for (uint256 readIndex = lastCompactionIndex; readIndex < length; readIndex++) {
            if (!deletedFlags[readIndex]) {
                if (writeIndex != readIndex) {
                    array[writeIndex] = array[readIndex];
                    deletedFlags[writeIndex] = false;
                    deletedFlags[readIndex] = true;
                }
                writeIndex++;
            }
        }
        
        // Reduce array length
        assembly {
            sstore(array.slot, writeIndex)
        }
        
        return writeIndex;
    }
    
    // ---------------------------------------------------------------------
    // View Function Optimizations
    // ---------------------------------------------------------------------
    
    /**
     * @dev Optimized view function for getting multiple values
     */
    function batchGetAddresses(
        mapping(string => address) storage addressMap,
        string[] memory keys
    ) internal view returns (address[] memory addresses) {
        uint256 length = keys.length;
        addresses = new address[](length);
        
        assembly {
            let keysPtr := add(keys, 0x20)
            let addressesPtr := add(addresses, 0x20)
            
            for { let i := 0 } lt(i, length) { i := add(i, 1) } {
                let keyPtr := mload(add(keysPtr, mul(i, 0x20)))
                // Note: This is simplified - actual implementation would need proper mapping access
                mstore(add(addressesPtr, mul(i, 0x20)), 0) // Placeholder
            }
        }
    }
    
    /**
     * @dev Gas-optimized event emission for batch operations
     */
    function emitBatchEvent(
        uint256 batchId,
        uint256 itemCount,
        uint256 totalAmount,
        string memory eventType
    ) internal {
        if (keccak256(bytes(eventType)) == keccak256(bytes("cluster"))) {
            emit BatchClusterRegistered(batchId, itemCount, totalAmount);
        } else if (keccak256(bytes(eventType)) == keccak256(bytes("reward"))) {
            emit BatchRewardDistributed(batchId, itemCount, totalAmount);
        }
    }
    
    // ---------------------------------------------------------------------
    // Memory Management Optimizations
    // ---------------------------------------------------------------------
    
    /**
     * @dev Efficient memory allocation for dynamic arrays
     */
    function allocateStringArray(uint256 size) internal pure returns (string[] memory result) {
        assembly {
            result := mload(0x40)
            mstore(result, size)
            let dataSize := mul(size, 0x20)
            mstore(0x40, add(add(result, 0x20), dataSize))
        }
    }
    
    /**
     * @dev Efficient memory allocation for address arrays
     */
    function allocateAddressArray(uint256 size) internal pure returns (address[] memory result) {
        assembly {
            result := mload(0x40)
            mstore(result, size)
            let dataSize := mul(size, 0x20)
            mstore(0x40, add(add(result, 0x20), dataSize))
        }
    }
    
    /**
     * @dev Calculate optimal batch size based on gas limit
     */
    function calculateOptimalBatchSize(uint256 gasPerItem, uint256 gasLimit) 
        internal 
        pure 
        returns (uint256) 
    {
        uint256 maxItems = gasLimit / gasPerItem;
        return maxItems > BATCH_SIZE_LIMIT ? BATCH_SIZE_LIMIT : maxItems;
    }
}
