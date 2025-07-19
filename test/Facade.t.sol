// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./BaseTest.sol";

/**
 * @title FacadeTest
 * @notice Tests for Facade contract functionality
 */
contract FacadeTest is BaseTest {
    // =============================================================
    //                      STATS TESTS
    // =============================================================

    function testFacade_InitialStats() public view {
        (uint256 totalNodes, uint256 totalUsers, uint256 totalAllocations) = facade.getTotalStats();
        assertEq(totalNodes, 0);
        assertEq(totalUsers, 0);
        assertEq(totalAllocations, 0);
    }

    function testFacade_StatsAfterSingleRegistrations() public {
        // Register a node
        _registerTestNode("facade-test-node");

        // Register a user
        _registerTestUser(user, UserStorage.UserType.PROVIDER);

        // Check stats through facade
        (uint256 totalNodes, uint256 totalUsers, uint256 totalAllocations) = facade.getTotalStats();
        assertEq(totalNodes, 1);
        assertEq(totalUsers, 1);
        assertEq(totalAllocations, 0);
    }

    function testFacade_StatsAfterMultipleRegistrations() public {
        // Register multiple nodes
        _registerTestNode("node-1");
        vm.startPrank(nodeOperator);
        nodeLogic.registerNode("node-2", nodeOperator, NodeStorage.NodeTier.STANDARD, NodeStorage.ProviderType.STORAGE);
        vm.stopPrank();

        // Register multiple users
        _registerTestUser(address(0x100), UserStorage.UserType.CONSUMER);
        _registerTestUser(address(0x200), UserStorage.UserType.PROVIDER);
        _registerTestUser(address(0x300), UserStorage.UserType.CONSUMER);

        (uint256 totalNodes, uint256 totalUsers, uint256 totalAllocations) = facade.getTotalStats();
        assertEq(totalNodes, 2);
        assertEq(totalUsers, 3);
        assertEq(totalAllocations, 0);
    }

    // =============================================================
    //                    INTEGRATION TESTS
    // =============================================================

    function testFacade_CompleteWorkflow() public {
        // 1. Register nodes of different types
        vm.startPrank(nodeOperator);
        nodeLogic.registerNode(
            "compute-node", nodeOperator, NodeStorage.NodeTier.STANDARD, NodeStorage.ProviderType.COMPUTE
        );
        nodeLogic.registerNode(
            "storage-node", nodeOperator, NodeStorage.NodeTier.PREMIUM, NodeStorage.ProviderType.STORAGE
        );
        vm.stopPrank();

        // 2. Register users of different types
        vm.startPrank(authService);
        userLogic.registerUser(address(0x100), keccak256("consumer-profile"), UserStorage.UserType.CONSUMER);
        userLogic.registerUser(address(0x200), keccak256("provider-profile"), UserStorage.UserType.PROVIDER);
        vm.stopPrank();

        // 3. Verify through facade
        (uint256 totalNodes, uint256 totalUsers, uint256 totalAllocations) = facade.getTotalStats();
        assertEq(totalNodes, 2);
        assertEq(totalUsers, 2);
        assertEq(totalAllocations, 0);

        // 4. Verify individual registrations still work
        NodeStorage.NodeInfo memory computeNode = nodeLogic.getNodeInfo("compute-node");
        NodeStorage.NodeInfo memory storageNode = nodeLogic.getNodeInfo("storage-node");
        UserStorage.UserProfile memory consumer = userLogic.getUserProfile(address(0x100));
        UserStorage.UserProfile memory provider = userLogic.getUserProfile(address(0x200));

        assertEq(computeNode.nodeId, "compute-node");
        assertEq(storageNode.nodeId, "storage-node");
        assertEq(uint8(consumer.userType), uint8(UserStorage.UserType.CONSUMER));
        assertEq(uint8(provider.userType), uint8(UserStorage.UserType.PROVIDER));
    }

    // =============================================================
    //                    PROXY BEHAVIOR TESTS
    // =============================================================

    function testFacade_ProxyDelegation() public {
        // Test that facade properly delegates to underlying contracts
        _registerTestNode("proxy-test-node");
        _registerTestUser(address(0x400), UserStorage.UserType.CONSUMER);

        // Stats should reflect the delegated calls
        (uint256 totalNodes, uint256 totalUsers, /* uint256 totalAllocations */ ) = facade.getTotalStats();
        assertEq(totalNodes, 1);
        assertEq(totalUsers, 1);

        // Direct contract calls should show same data
        NodeStorage.NodeInfo memory nodeInfo = nodeLogic.getNodeInfo("proxy-test-node");
        UserStorage.UserProfile memory userProfile = userLogic.getUserProfile(address(0x400));

        assertEq(nodeInfo.nodeId, "proxy-test-node");
        assertEq(uint8(userProfile.userType), uint8(UserStorage.UserType.CONSUMER));
    }

    // =============================================================
    //                    EDGE CASE TESTS
    // =============================================================

    function testFacade_EmptyState() public view {
        // Test facade behavior with no registrations
        (uint256 totalNodes, uint256 totalUsers, uint256 totalAllocations) = facade.getTotalStats();

        assertEq(totalNodes, 0);
        assertEq(totalUsers, 0);
        assertEq(totalAllocations, 0);
    }

    function testFacade_OnlyNodes() public {
        // Register only nodes, no users
        _registerTestNode("only-node-1");
        vm.startPrank(nodeOperator);
        nodeLogic.registerNode(
            "only-node-2", nodeOperator, NodeStorage.NodeTier.PREMIUM, NodeStorage.ProviderType.STORAGE
        );
        vm.stopPrank();

        (uint256 totalNodes, uint256 totalUsers, uint256 totalAllocations) = facade.getTotalStats();
        assertEq(totalNodes, 2);
        assertEq(totalUsers, 0);
        assertEq(totalAllocations, 0);
    }

    function testFacade_OnlyUsers() public {
        // Register only users, no nodes
        _registerTestUser(address(0x500), UserStorage.UserType.CONSUMER);
        _registerTestUser(address(0x600), UserStorage.UserType.PROVIDER);

        (uint256 totalNodes, uint256 totalUsers, uint256 totalAllocations) = facade.getTotalStats();
        assertEq(totalNodes, 0);
        assertEq(totalUsers, 2);
        assertEq(totalAllocations, 0);
    }
}
