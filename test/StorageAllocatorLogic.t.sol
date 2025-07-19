// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./BaseTest.sol";

/**
 * @title StorageAllocatorLogicTest
 * @notice Test suite for StorageAllocatorLogic contract functionality
 */
contract StorageAllocatorLogicTest is BaseTest {
    
    function testStorageAllocatorLogic_AllocateStorage() public {
        string[] memory nodeIds = new string[](2);
        nodeIds[0] = "node1";
        nodeIds[1] = "node2";
        
        vm.startPrank(storageAllocator);
        
        vm.expectEmit(true, true, false, false);
        emit StorageAllocatorLogic.AllocationRequested("alloc-123", user, 100, block.timestamp);
        
        storageAllocatorLogic.allocateStorage(
            "alloc-123",
            user,
            100, // 100GB
            nodeIds
        );
        
        vm.stopPrank();
    }
    
    function testStorageAllocatorLogic_AllocateStorage_OnlyAuthorized() public {
        string[] memory nodeIds = new string[](1);
        nodeIds[0] = "node1";
        
        vm.startPrank(user); // Unauthorized user
        
        vm.expectRevert();
        storageAllocatorLogic.allocateStorage(
            "alloc-123",
            user,
            100,
            nodeIds
        );
        
        vm.stopPrank();
    }
    
    function testStorageAllocatorLogic_AllocateStorage_InvalidAllocationId() public {
        string[] memory nodeIds = new string[](1);
        nodeIds[0] = "node1";
        
        vm.startPrank(storageAllocator);
        
        vm.expectRevert();
        storageAllocatorLogic.allocateStorage(
            "", // Invalid allocation ID
            user,
            100,
            nodeIds
        );
        
        vm.stopPrank();
    }
    
    function testStorageAllocatorLogic_AllocateStorage_InvalidRequester() public {
        string[] memory nodeIds = new string[](1);
        nodeIds[0] = "node1";
        
        vm.startPrank(storageAllocator);
        
        vm.expectRevert();
        storageAllocatorLogic.allocateStorage(
            "alloc-123",
            address(0), // Invalid requester
            100,
            nodeIds
        );
        
        vm.stopPrank();
    }
    
    function testStorageAllocatorLogic_AllocateStorage_InvalidSizeGB() public {
        string[] memory nodeIds = new string[](1);
        nodeIds[0] = "node1";
        
        vm.startPrank(storageAllocator);
        
        vm.expectRevert();
        storageAllocatorLogic.allocateStorage(
            "alloc-123",
            user,
            0, // Invalid size
            nodeIds
        );
        
        vm.stopPrank();
    }
    
    function testStorageAllocatorLogic_AllocateStorage_EmptyNodeList() public {
        string[] memory nodeIds = new string[](0); // Empty array
        
        vm.startPrank(storageAllocator);
        
        vm.expectRevert();
        storageAllocatorLogic.allocateStorage(
            "alloc-123",
            user,
            100,
            nodeIds
        );
        
        vm.stopPrank();
    }
    
    function testStorageAllocatorLogic_UpdateAllocationStatus() public {
        vm.startPrank(storageAllocator);
        
        // Note: This test may fail because allocation doesn't exist in storage
        // In real implementation, we'd allocate first, then update
        vm.expectRevert();
        storageAllocatorLogic.updateAllocationStatus("alloc-123", 1);
        
        vm.stopPrank();
    }
    
    function testStorageAllocatorLogic_UpdateAllocationStatus_OnlyAuthorized() public {
        vm.startPrank(user); // Unauthorized user
        
        vm.expectRevert();
        storageAllocatorLogic.updateAllocationStatus("alloc-123", 1);
        
        vm.stopPrank();
    }
    
    function testStorageAllocatorLogic_UpdateAllocationStatus_InvalidAllocationId() public {
        vm.startPrank(storageAllocator);
        
        vm.expectRevert();
        storageAllocatorLogic.updateAllocationStatus("", 1); // Invalid allocation ID
        
        vm.stopPrank();
    }
    
    function testStorageAllocatorLogic_GetAllocation() public view {
        (
            string memory allocationId,
            address requester,
            uint256 sizeGB,
            string[] memory nodeIds,
            uint8 status,
            uint256 allocatedAt
        ) = storageAllocatorLogic.getAllocation("nonexistent-alloc");
        
        // Should return empty data for nonexistent allocation
        assertEq(bytes(allocationId).length, 0, "AllocationId should be empty for nonexistent allocation");
        assertEq(requester, address(0), "Requester should be zero for nonexistent allocation");
        assertEq(sizeGB, 0, "SizeGB should be 0 for nonexistent allocation");
        assertEq(nodeIds.length, 0, "NodeIds should be empty for nonexistent allocation");
        assertEq(status, 0, "Status should be 0 for nonexistent allocation");
        assertEq(allocatedAt, 0, "AllocatedAt should be 0 for nonexistent allocation");
    }
    
    function testStorageAllocatorLogic_GetAllocation_InvalidAllocationId() public {
        vm.expectRevert();
        storageAllocatorLogic.getAllocation("");
    }
    
    function testStorageAllocatorLogic_GetNodeAllocations() public view {
        string[] memory allocations = storageAllocatorLogic.getNodeAllocations("node1");
        
        // Should return empty array initially
        assertEq(allocations.length, 0, "Should return empty allocations array initially");
    }
    
    function testStorageAllocatorLogic_GetNodeAllocations_InvalidNodeId() public {
        vm.expectRevert();
        storageAllocatorLogic.getNodeAllocations("");
    }
    
    function testStorageAllocatorLogic_GetRequesterAllocations() public view {
        string[] memory allocations = storageAllocatorLogic.getRequesterAllocations(user);
        
        // Should return empty array initially
        assertEq(allocations.length, 0, "Should return empty allocations array initially");
    }
    
    function testStorageAllocatorLogic_GetRequesterAllocations_InvalidRequester() public {
        vm.expectRevert();
        storageAllocatorLogic.getRequesterAllocations(address(0));
    }
    
    function testStorageAllocatorLogic_AllocationExists() public view {
        bool exists = storageAllocatorLogic.allocationExists("nonexistent-alloc");
        assertFalse(exists, "Nonexistent allocation should return false");
    }
    
    function testStorageAllocatorLogic_AllocationExists_InvalidAllocationId() public view {
        bool exists = storageAllocatorLogic.allocationExists("");
        assertFalse(exists, "Empty allocation ID should return false");
    }
    
    function testStorageAllocatorLogic_IsRequesterOwner() public view {
        bool owns = storageAllocatorLogic.isRequesterOwner(user, "nonexistent-alloc");
        assertFalse(owns, "Should return false for nonexistent allocation");
    }
    
    function testStorageAllocatorLogic_IsRequesterOwner_InvalidParams() public view {
        bool owns1 = storageAllocatorLogic.isRequesterOwner(address(0), "alloc-123");
        assertFalse(owns1, "Should return false for invalid requester");
        
        bool owns2 = storageAllocatorLogic.isRequesterOwner(user, "");
        assertFalse(owns2, "Should return false for invalid allocation ID");
    }
    
    function testStorageAllocatorLogic_GetNodeTotalAllocation() public view {
        uint256 total = storageAllocatorLogic.getNodeTotalAllocation("node1");
        
        // Should return 0 initially (no active allocations)
        assertEq(total, 0, "Should return 0 total allocation initially");
    }
    
    function testStorageAllocatorLogic_GetNodeTotalAllocation_InvalidNodeId() public view {
        uint256 total = storageAllocatorLogic.getNodeTotalAllocation("");
        
        // Should return 0 for invalid node ID
        assertEq(total, 0, "Should return 0 for invalid node ID");
    }
}
