// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./BaseTest.sol";

/**
 * @title NodeLogicTest
 * @notice Tests for NodeLogic contract functionality
 */
contract NodeLogicTest is BaseTest {
    // =============================================================
    //                      BASIC NODE TESTS
    // =============================================================

    function testNodeRegistration_BasicFlow() public {
        vm.startPrank(nodeOperator);

        string memory nodeId = "test-node-1";
        nodeLogic.registerNode(nodeId, nodeOperator, NodeStorage.NodeTier.STANDARD, NodeStorage.ProviderType.COMPUTE);

        NodeStorage.NodeInfo memory nodeInfo = nodeLogic.getNodeInfo(nodeId);
        assertEq(nodeInfo.nodeId, nodeId);
        assertEq(nodeInfo.nodeAddress, nodeOperator);
        assertEq(uint8(nodeInfo.tier), uint8(NodeStorage.NodeTier.STANDARD));
        assertEq(uint8(nodeInfo.providerType), uint8(NodeStorage.ProviderType.COMPUTE));

        vm.stopPrank();
    }

    function testNodeRegistration_DifferentTiers() public {
        vm.startPrank(nodeOperator);

        // Test BASIC tier
        nodeLogic.registerNode("basic-node", nodeOperator, NodeStorage.NodeTier.BASIC, NodeStorage.ProviderType.COMPUTE);
        NodeStorage.NodeInfo memory basicNode = nodeLogic.getNodeInfo("basic-node");
        assertEq(uint8(basicNode.tier), uint8(NodeStorage.NodeTier.BASIC));

        // Test STANDARD tier
        nodeLogic.registerNode(
            "standard-node", nodeOperator, NodeStorage.NodeTier.STANDARD, NodeStorage.ProviderType.COMPUTE
        );
        NodeStorage.NodeInfo memory standardNode = nodeLogic.getNodeInfo("standard-node");
        assertEq(uint8(standardNode.tier), uint8(NodeStorage.NodeTier.STANDARD));

        // Test PREMIUM tier
        nodeLogic.registerNode(
            "premium-node", nodeOperator, NodeStorage.NodeTier.PREMIUM, NodeStorage.ProviderType.STORAGE
        );
        NodeStorage.NodeInfo memory premiumNode = nodeLogic.getNodeInfo("premium-node");
        assertEq(uint8(premiumNode.tier), uint8(NodeStorage.NodeTier.PREMIUM));

        vm.stopPrank();
    }

    function testNodeRegistration_DifferentProviderTypes() public {
        vm.startPrank(nodeOperator);

        // Test COMPUTE provider
        nodeLogic.registerNode(
            "compute-node", nodeOperator, NodeStorage.NodeTier.STANDARD, NodeStorage.ProviderType.COMPUTE
        );
        NodeStorage.NodeInfo memory computeNode = nodeLogic.getNodeInfo("compute-node");
        assertEq(uint8(computeNode.providerType), uint8(NodeStorage.ProviderType.COMPUTE));

        // Test STORAGE provider
        nodeLogic.registerNode(
            "storage-node", nodeOperator, NodeStorage.NodeTier.STANDARD, NodeStorage.ProviderType.STORAGE
        );
        NodeStorage.NodeInfo memory storageNode = nodeLogic.getNodeInfo("storage-node");
        assertEq(uint8(storageNode.providerType), uint8(NodeStorage.ProviderType.STORAGE));

        vm.stopPrank();
    }

    // =============================================================
    //                    ACCESS CONTROL TESTS
    // =============================================================

    function testNodeRegistration_AccessControl() public {
        vm.startPrank(user); // user doesn't have NODE_OPERATOR_ROLE

        vm.expectRevert();
        nodeLogic.registerNode(
            "unauthorized-node", user, NodeStorage.NodeTier.STANDARD, NodeStorage.ProviderType.COMPUTE
        );

        vm.stopPrank();
    }

    function testNodeRegistration_OnlyOperatorCanRegister() public {
        // Admin should not be able to register without NODE_OPERATOR_ROLE
        vm.startPrank(admin);

        vm.expectRevert();
        nodeLogic.registerNode("admin-node", admin, NodeStorage.NodeTier.STANDARD, NodeStorage.ProviderType.COMPUTE);

        vm.stopPrank();
    }

    // =============================================================
    //                    VALIDATION TESTS
    // =============================================================

    function testNodeRegistration_EmptyNodeId() public {
        vm.startPrank(nodeOperator);

        // Note: The current implementation allows empty strings as node IDs
        // They get hashed to a valid bytes32 value, so registration succeeds
        // If empty node IDs should be rejected, add validation to NodeStorage.registerNode
        nodeLogic.registerNode("", nodeOperator, NodeStorage.NodeTier.STANDARD, NodeStorage.ProviderType.COMPUTE);

        // Verify the registration succeeded
        NodeStorage.NodeInfo memory nodeInfo = nodeLogic.getNodeInfo("");
        assertEq(nodeInfo.nodeId, "");
        assertEq(nodeInfo.nodeAddress, nodeOperator);
        assertEq(uint8(nodeInfo.tier), uint8(NodeStorage.NodeTier.STANDARD));

        vm.stopPrank();
    }

    function testNodeRegistration_DuplicateNodeId() public {
        vm.startPrank(nodeOperator);

        string memory nodeId = "duplicate-node";

        // First registration should succeed
        nodeLogic.registerNode(nodeId, nodeOperator, NodeStorage.NodeTier.STANDARD, NodeStorage.ProviderType.COMPUTE);

        // Second registration with same ID should fail
        vm.expectRevert();
        nodeLogic.registerNode(nodeId, nodeOperator, NodeStorage.NodeTier.PREMIUM, NodeStorage.ProviderType.STORAGE);

        vm.stopPrank();
    }

    // =============================================================
    //                      HELPER TESTS
    // =============================================================

    function testRegisterTestNode_Helper() public {
        _registerTestNode("helper-test-node");
        _assertNodeExists("helper-test-node", nodeOperator);
    }

    function testMultipleNodeRegistrations() public {
        vm.startPrank(nodeOperator);

        // Register multiple nodes
        nodeLogic.registerNode("node-1", nodeOperator, NodeStorage.NodeTier.BASIC, NodeStorage.ProviderType.COMPUTE);
        nodeLogic.registerNode("node-2", nodeOperator, NodeStorage.NodeTier.STANDARD, NodeStorage.ProviderType.STORAGE);
        nodeLogic.registerNode("node-3", nodeOperator, NodeStorage.NodeTier.PREMIUM, NodeStorage.ProviderType.COMPUTE);

        // Verify all exist
        _assertNodeExists("node-1", nodeOperator);
        _assertNodeExists("node-2", nodeOperator);
        _assertNodeExists("node-3", nodeOperator);

        vm.stopPrank();
    }
}
