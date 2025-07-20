// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./BaseTest.sol";

/**
 * @title NodeLogicTest
 * @notice Tests for No    // =============================================================
    //                    COMPREHENSIVE NODE TESTS
    // =============================================================

    function testNodeLogic_NodeExists() public {
        registerTestNode("existing-node", nodeOperator, NodeStorage.NodeTier.BASIC);
        
        assertTrue(nodeLogic.nodeExists("existing-node"), "Node should exist");
        assertFalse(nodeLogic.nodeExists("non-existing-node"), "Node should not exist");
    }

    function testNodeLogic_UpdateNodeStatus() public {
        registerTestNode("status-node", nodeOperator, NodeStorage.NodeTier.BASIC);
        
        vm.prank(admin);
        nodeLogic.updateNodeStatus("status-node", NodeStorage.NodeStatus.INACTIVE);
        
        NodeStorage.NodeInfo memory nodeInfo = nodeLogic.getNodeInfo("status-node");
        assertEq(uint8(nodeInfo.status), uint8(NodeStorage.NodeStatus.INACTIVE), "Status should be updated");
    }

    function testNodeLogic_UpdateNodeStatus_OnlyAdmin() public {
        registerTestNode("status-node", nodeOperator, NodeStorage.NodeTier.BASIC);
        
        vm.prank(user);
        vm.expectRevert();
        nodeLogic.updateNodeStatus("status-node", NodeStorage.NodeStatus.INACTIVE);
    }

    function testNodeLogic_UpdateNodeStatus_NonExistentNode() public {
        vm.prank(admin);
        vm.expectRevert("Node not found");
        nodeLogic.updateNodeStatus("non-existent", NodeStorage.NodeStatus.INACTIVE);
    }

    function testNodeLogic_ListNodeForMarketplace() public {
        registerTestNode("marketplace-node", nodeOperator, NodeStorage.NodeTier.STANDARD);
        
        vm.prank(nodeOperator);
        nodeLogic.listNodeForMarketplace("marketplace-node", 100, 90);
        
        (uint256 hourlyRate, uint256 availability) = nodeLogic.getNodeMarketplaceListing("marketplace-node");
        assertEq(hourlyRate, 100, "Hourly rate should be set");
        assertEq(availability, 90, "Availability should be set");
    }

    function testNodeLogic_ListNodeForMarketplace_OnlyNodeOperator() public {
        registerTestNode("marketplace-node", nodeOperator, NodeStorage.NodeTier.STANDARD);
        
        vm.prank(user);
        vm.expectRevert("Not node operator");
        nodeLogic.listNodeForMarketplace("marketplace-node", 100, 90);
    }

    function testNodeLogic_UpdateExtendedInfo() public {
        registerTestNode("extended-node", nodeOperator, NodeStorage.NodeTier.STANDARD);
        
        vm.prank(nodeOperator);
        nodeLogic.updateExtendedInfo(
            "extended-node",
            "region-1",
            "datacenter-1",
            "ipfs://extended-config"
        );
        
        (string memory region, string memory datacenter, string memory configHash) = 
            nodeLogic.getNodeExtendedInfo("extended-node");
        assertEq(region, "region-1", "Region should be updated");
        assertEq(datacenter, "datacenter-1", "Datacenter should be updated");
        assertEq(configHash, "ipfs://extended-config", "Config hash should be updated");
    }

    function testNodeLogic_UpdateExtendedInfo_OnlyNodeOperator() public {
        registerTestNode("extended-node", nodeOperator, NodeStorage.NodeTier.STANDARD);
        
        vm.prank(user);
        vm.expectRevert("Not node operator");
        nodeLogic.updateExtendedInfo(
            "extended-node",
            "region-1",
            "datacenter-1",
            "ipfs://extended-config"
        );
    }

    function testNodeLogic_SetNodeAttribute() public {
        registerTestNode("attribute-node", nodeOperator, NodeStorage.NodeTier.STANDARD);
        
        vm.prank(nodeOperator);
        nodeLogic.setNodeAttribute("attribute-node", "cpu_model", "Intel Xeon");
        
        string memory value = nodeLogic.getNodeAttribute("attribute-node", "cpu_model");
        assertEq(value, "Intel Xeon", "Attribute should be set");
    }

    function testNodeLogic_SetNodeAttribute_OnlyNodeOperator() public {
        registerTestNode("attribute-node", nodeOperator, NodeStorage.NodeTier.STANDARD);
        
        vm.prank(user);
        vm.expectRevert("Not node operator");
        nodeLogic.setNodeAttribute("attribute-node", "cpu_model", "Intel Xeon");
    }

    function testNodeLogic_AddCertification() public {
        registerTestNode("cert-node", nodeOperator, NodeStorage.NodeTier.STANDARD);
        
        bytes32 certId = keccak256("iso-cert");
        
        vm.prank(admin);
        nodeLogic.addCertification("cert-node", certId, "ISO 27001", block.timestamp + 365 days);
        
        assertTrue(nodeLogic.hasCertification("cert-node", certId), "Should have certification");
    }

    function testNodeLogic_AddCertification_OnlyAdmin() public {
        registerTestNode("cert-node", nodeOperator, NodeStorage.NodeTier.STANDARD);
        
        bytes32 certId = keccak256("iso-cert");
        
        vm.prank(user);
        vm.expectRevert();
        nodeLogic.addCertification("cert-node", certId, "ISO 27001", block.timestamp + 365 days);
    }

    function testNodeLogic_SetVerificationStatus() public {
        registerTestNode("verify-node", nodeOperator, NodeStorage.NodeTier.STANDARD);
        
        vm.prank(admin);
        nodeLogic.setVerificationStatus("verify-node", true, block.timestamp + 365 days);
        
        (bool isVerified, uint256 expiryDate) = nodeLogic.getVerificationStatus("verify-node");
        assertTrue(isVerified, "Should be verified");
        assertEq(expiryDate, block.timestamp + 365 days, "Expiry date should match");
    }

    function testNodeLogic_SetVerificationStatus_OnlyAdmin() public {
        registerTestNode("verify-node", nodeOperator, NodeStorage.NodeTier.STANDARD);
        
        vm.prank(user);
        vm.expectRevert();
        nodeLogic.setVerificationStatus("verify-node", true, block.timestamp + 365 days);
    }

    function testNodeLogic_SetSecurityBond() public {
        registerTestNode("bond-node", nodeOperator, NodeStorage.NodeTier.STANDARD);
        
        vm.prank(admin);
        nodeLogic.setSecurityBond("bond-node", 1000 ether);
        
        uint256 bondAmount = nodeLogic.getSecurityBond("bond-node");
        assertEq(bondAmount, 1000 ether, "Bond amount should be set");
    }

    function testNodeLogic_SetSecurityBond_OnlyAdmin() public {
        registerTestNode("bond-node", nodeOperator, NodeStorage.NodeTier.STANDARD);
        
        vm.prank(user);
        vm.expectRevert();
        nodeLogic.setSecurityBond("bond-node", 1000 ether);
    }

    function testNodeLogic_GetNodesByOperator() public {
        vm.prank(nodeOperator);
        grantRole(nodeLogic.NODE_OPERATOR_ROLE(), nodeOperator);
        
        vm.startPrank(nodeOperator);
        nodeLogic.registerNode("op-node-1", nodeOperator, NodeStorage.NodeTier.BASIC, NodeStorage.ProviderType.COMPUTE);
        nodeLogic.registerNode("op-node-2", nodeOperator, NodeStorage.NodeTier.STANDARD, NodeStorage.ProviderType.STORAGE);
        vm.stopPrank();
        
        string[] memory nodes = nodeLogic.getNodesByOperator(nodeOperator);
        assertEq(nodes.length, 2, "Should have 2 nodes");
        assertEq(nodes[0], "op-node-1", "First node should match");
        assertEq(nodes[1], "op-node-2", "Second node should match");
    }

    function testNodeLogic_GetActiveNodeCount() public {
        uint256 initialCount = nodeLogic.getActiveNodeCount();
        
        registerTestNode("active-node-1", nodeOperator, NodeStorage.NodeTier.BASIC);
        registerTestNode("active-node-2", nodeOperator, NodeStorage.NodeTier.STANDARD);
        
        uint256 newCount = nodeLogic.getActiveNodeCount();
        assertEq(newCount, initialCount + 2, "Active node count should increase by 2");
        
        // Deactivate one node
        vm.prank(admin);
        nodeLogic.updateNodeStatus("active-node-1", NodeStorage.NodeStatus.INACTIVE);
        
        uint256 finalCount = nodeLogic.getActiveNodeCount();
        assertEq(finalCount, initialCount + 1, "Active node count should decrease by 1");
    }

    function testNodeLogic_GetTotalNodeCount() public {
        uint256 initialCount = nodeLogic.getTotalNodeCount();
        
        registerTestNode("total-node-1", nodeOperator, NodeStorage.NodeTier.BASIC);
        registerTestNode("total-node-2", nodeOperator, NodeStorage.NodeTier.STANDARD);
        
        uint256 newCount = nodeLogic.getTotalNodeCount();
        assertEq(newCount, initialCount + 2, "Total node count should increase by 2");
    }

    // =============================================================
    //                    HELPER FUNCTIONS
    // =============================================================

    function testRegisterTestNode_Helper() public {
        registerTestNode("test-helper-node", nodeOperator, NodeStorage.NodeTier.BASIC);

        NodeStorage.NodeInfo memory nodeInfo = nodeLogic.getNodeInfo("test-helper-node");
        assertEq(nodeInfo.nodeId, "test-helper-node");
        assertEq(nodeInfo.nodeAddress, nodeOperator);
        assertEq(uint8(nodeInfo.tier), uint8(NodeStorage.NodeTier.BASIC));
    }
}ontract functionality
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
