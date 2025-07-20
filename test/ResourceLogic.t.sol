// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../test/BaseTest.sol";
import "../src/proxy/ResourceLogic.sol";
import "../src/storage/ResourceStorage.sol";

/**
 * @title ResourceLogicTest - Tests for ResourceLogic contract functionality
 */
contract ResourceLogicTest is BaseTest {
    ResourceLogic public resourceLogic;
    address public testNode = address(0x456);
    address public testUser = address(0x789);
    string public constant TEST_NODE_ID = "test-node-1";

    function setUp() public override {
        super.setUp();
        
        // Deploy ResourceLogic
        resourceLogic = new ResourceLogic();
        resourceLogic.initialize(
            address(nodeStorage),
            address(userStorage),
            address(resourceStorage),
            admin
        );

        // Register a test node
        vm.prank(admin);
        nodeLogic.registerNode(
            TEST_NODE_ID,
            testNode,
            NodeStorage.NodeTier.BASIC,
            NodeStorage.ProviderType.COMPUTE
        );
    }

    function testResourceLogic_Initialization() public {
        assertEq(address(resourceLogic.nodeStorage()), address(nodeStorage), "Node storage should be set");
        assertEq(address(resourceLogic.userStorage()), address(userStorage), "User storage should be set");
        assertEq(address(resourceLogic.resourceStorage()), address(resourceStorage), "Resource storage should be set");
        assertTrue(resourceLogic.hasRole(resourceLogic.ADMIN_ROLE(), admin), "Admin should have admin role");
    }

    function testResourceLogic_CreateComputeListing() public {
        vm.prank(testNode);
        vm.expectEmit(true, true, false, true);
        emit ComputeListingCreated(bytes32(0), TEST_NODE_ID, uint8(IResourceTypes.ComputeTier.STANDARD), 100);
        
        bytes32 listingId = resourceLogic.createComputeListing(
            TEST_NODE_ID,
            IResourceTypes.ComputeTier.STANDARD,
            4, // cpuCores
            16, // memoryGB
            100, // storageGB
            100, // hourlyRate
            "us-east-1" // region
        );
        
        assertTrue(listingId != bytes32(0), "Listing ID should be generated");
    }

    function testResourceLogic_CreateComputeListing_OnlyNodeOperator() public {
        vm.prank(testUser);
        vm.expectRevert("Not node operator");
        resourceLogic.createComputeListing(
            TEST_NODE_ID,
            IResourceTypes.ComputeTier.STANDARD,
            4, 16, 100, 100,
            "us-east-1"
        );
    }

    function testResourceLogic_CreateComputeListing_WhenPaused() public {
        vm.prank(admin);
        resourceLogic.pause();
        
        vm.prank(testNode);
        vm.expectRevert();
        resourceLogic.createComputeListing(
            TEST_NODE_ID,
            IResourceTypes.ComputeTier.STANDARD,
            4, 16, 100, 100,
            "us-east-1"
        );
    }

    function testResourceLogic_CreateStorageListing() public {
        vm.prank(testNode);
        vm.expectEmit(true, true, false, true);
        emit StorageListingCreated(bytes32(0), TEST_NODE_ID, uint8(IResourceTypes.StorageTier.FAST), 50);
        
        bytes32 listingId = resourceLogic.createStorageListing(
            TEST_NODE_ID,
            IResourceTypes.StorageTier.FAST,
            1000, // capacityGB
            50, // hourlyRate
            "us-west-2" // region
        );
        
        assertTrue(listingId != bytes32(0), "Listing ID should be generated");
    }

    function testResourceLogic_CreateStorageListing_OnlyNodeOperator() public {
        vm.prank(testUser);
        vm.expectRevert("Not node operator");
        resourceLogic.createStorageListing(
            TEST_NODE_ID,
            IResourceTypes.StorageTier.FAST,
            1000, 50,
            "us-west-2"
        );
    }

    function testResourceLogic_PurchaseCompute() public {
        // First create a compute listing
        vm.prank(testNode);
        bytes32 listingId = resourceLogic.createComputeListing(
            TEST_NODE_ID,
            IResourceTypes.ComputeTier.STANDARD,
            4, 16, 100, 100,
            "us-east-1"
        );

        // Purchase the resource as testUser
        vm.prank(testUser);
        vm.deal(testUser, 10 ether); // Give testUser some ETH
        vm.expectEmit(true, true, true, true);
        emit ComputeResourceAllocated(bytes32(0), testUser, listingId, 24);
        
        bytes32 allocationId = resourceLogic.purchaseCompute{value: 2400}(
            listingId,
            24 // duration in hours
        );
        
        assertTrue(allocationId != bytes32(0), "Allocation ID should be generated");
    }

    function testResourceLogic_PurchaseCompute_OnlyMarketplace() public {
        // First create a compute listing
        vm.prank(testNode);
        bytes32 listingId = resourceLogic.createComputeListing(
            TEST_NODE_ID,
            IResourceTypes.ComputeTier.STANDARD,
            4, 16, 100, 100,
            "us-east-1"
        );

        vm.prank(testUser);
        vm.expectRevert();
        resourceLogic.purchaseCompute{value: 2400}(listingId, 24);
    }

    function testResourceLogic_GetAllocation() public {
        // First create and allocate a resource
        vm.prank(testNode);
        bytes32 listingId = resourceLogic.createComputeListing(
            TEST_NODE_ID,
            IResourceTypes.ComputeTier.STANDARD,
            4, 16, 100, 100,
            "us-east-1"
        );

        vm.prank(testUser);
        vm.deal(testUser, 10 ether);
        bytes32 allocationId = resourceLogic.purchaseCompute{value: 2400}(
            listingId,
            24
        );

        // Get allocation details
        IResourceTypes.ResourceAllocation memory allocation = resourceLogic.getResourceAllocation(allocationId);
        assertEq(allocation.listingId, listingId, "Listing ID should match");
        assertEq(allocation.customer, testUser, "Customer should match");
        assertEq(allocation.duration, 24, "Duration should match");
    }

    function testResourceLogic_GetResourceStats() public {
        // Create multiple listings to test stats
        vm.prank(testNode);
        resourceLogic.createComputeListing(
            TEST_NODE_ID,
            IResourceTypes.ComputeTier.STANDARD,
            4, 16, 100, 100,
            "us-east-1"
        );

        vm.prank(testNode);
        resourceLogic.createStorageListing(
            TEST_NODE_ID,
            IResourceTypes.StorageTier.FAST,
            500, 50,
            "us-east-1"
        );

        // Get stats
        uint256 totalAllocations = resourceLogic.getResourceStats();
        // Should be 0 since we haven't allocated anything yet
        assertEq(totalAllocations, 0, "Should have no allocations initially");
    }

    function testResourceLogic_MultipleAllocations() public {
        // First create a compute listing
        vm.prank(testNode);
        bytes32 listingId = resourceLogic.createComputeListing(
            TEST_NODE_ID,
            IResourceTypes.ComputeTier.STANDARD,
            4, 16, 100, 100,
            "us-east-1"
        );

        vm.prank(testUser);
        vm.deal(testUser, 10 ether);
        bytes32 allocationId = resourceLogic.purchaseCompute{value: 2400}(
            listingId,
            24
        );

        // Test that we can get the allocation
        IResourceTypes.ResourceAllocation memory allocation = resourceLogic.getResourceAllocation(allocationId);
        assertTrue(allocation.customer == testUser, "Customer should be set");
        assertTrue(allocation.listingId == listingId, "Listing ID should be set");
    }

    function testResourceLogic_GetComputeListing() public {
        vm.prank(testNode);
        bytes32 listingId = resourceLogic.createComputeListing(
            TEST_NODE_ID,
            IResourceTypes.ComputeTier.STANDARD,
            4, 16, 100, 100,
            "us-east-1"
        );

        IResourceTypes.ComputeListing memory listing = resourceLogic.getComputeListing(listingId);

        assertEq(listing.nodeId, TEST_NODE_ID, "Node ID should match");
        assertEq(listing.provider, testNode, "Provider should match");
        assertEq(uint8(listing.tier), uint8(IResourceTypes.ComputeTier.STANDARD), "Tier should match");
        assertEq(listing.cpuCores, 4, "CPU cores should match");
        assertEq(listing.memoryGB, 16, "Memory should match");
        assertEq(listing.storageGB, 100, "Storage should match");
        assertEq(listing.hourlyRate, 100, "Hourly rate should match");
        assertEq(listing.region, "us-east-1", "Region should match");
        assertTrue(listing.isActive, "Should be active");
    }

    function testResourceLogic_GetStorageListing() public {
        vm.prank(testNode);
        bytes32 listingId = resourceLogic.createStorageListing(
            TEST_NODE_ID,
            IResourceTypes.StorageTier.FAST,
            1000, 50,
            "us-west-2"
        );

        IResourceTypes.StorageListing memory listing = resourceLogic.getStorageListing(listingId);

        assertEq(listing.nodeId, TEST_NODE_ID, "Node ID should match");
        assertEq(listing.provider, testNode, "Provider should match");
        assertEq(uint8(listing.tier), uint8(IResourceTypes.StorageTier.FAST), "Tier should match");
        assertEq(listing.storageGB, 1000, "Storage capacity should match");
        assertEq(listing.hourlyRate, 50, "Hourly rate should match");
        assertEq(listing.region, "us-west-2", "Region should match");
        assertTrue(listing.isActive, "Should be active");
    }

    // Events for testing
    event ComputeListingCreated(bytes32 indexed listingId, string indexed nodeId, uint8 tier, uint256 hourlyRate);
    event StorageListingCreated(bytes32 indexed listingId, string indexed nodeId, uint8 tier, uint256 hourlyRate);
    event ComputeResourceAllocated(
        bytes32 indexed allocationId, address indexed buyer, bytes32 indexed listingId, uint256 duration
    );
}
