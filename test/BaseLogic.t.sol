// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../test/BaseTest.sol";
import "../src/proxy/BaseLogic.sol";
import "../src/storage/NodeStorage.sol";
import "../src/storage/UserStorage.sol";
import "../src/storage/ResourceStorage.sol";

/**
 * @title BaseLogicTest - Tests for BaseLogic contract functionality
 */
contract TestableBaseLogic is BaseLogic {
    function initialize(
        address _nodeStorage,
        address _userStorage,
        address _resourceStorage,
        address _admin
    ) external {
        _initializeBase(_nodeStorage, _userStorage, _resourceStorage, _admin);
    }

    function testIsNodeAuthorized(string calldata nodeId) external view returns (address) {
        return _isNodeAuthorized(nodeId);
    }

    function testOnlyNodeOperator(string calldata nodeId) external view returns (address) {
        return _onlyNodeOperator(nodeId);
    }
}

contract BaseLogicTest is BaseTest {
    TestableBaseLogic public baseLogic;
    address public testUser = address(0x123);
    address public testNode = address(0x456);

    function setUp() public override {
        super.setUp();
        
        // Deploy testable BaseLogic
        baseLogic = new TestableBaseLogic();
        baseLogic.initialize(
            address(nodeStorage),
            address(userStorage),
            address(resourceStorage),
            admin
        );

        // Register a test node for authorization tests
        vm.prank(admin);
        nodeLogic.registerNode(
            "test-node-1",
            testNode,
            NodeStorage.NodeTier.BASIC,
            NodeStorage.ProviderType.COMPUTE
        );
    }

    function testBaseLogic_Initialization() public view {
        assertEq(baseLogic.VERSION(), 1, "Version should be 1");
        assertEq(address(baseLogic.nodeStorage()), address(nodeStorage), "Node storage should be set");
        assertEq(address(baseLogic.userStorage()), address(userStorage), "User storage should be set");
        assertEq(address(baseLogic.resourceStorage()), address(resourceStorage), "Resource storage should be set");
        assertTrue(baseLogic.hasRole(baseLogic.ADMIN_ROLE(), admin), "Admin should have admin role");
        assertTrue(baseLogic.hasRole(baseLogic.UPGRADER_ROLE(), admin), "Admin should have upgrader role");
    }

    function testBaseLogic_InitializationInvalidAddresses() public {
        TestableBaseLogic newLogic = new TestableBaseLogic();
        
        // Test zero address for admin
        vm.expectRevert("Invalid address");
        newLogic.initialize(
            address(nodeStorage),
            address(userStorage),
            address(resourceStorage),
            address(0)
        );

        // Test zero address for nodeStorage
        vm.expectRevert("Invalid address");
        newLogic.initialize(
            address(0),
            address(userStorage),
            address(resourceStorage),
            admin
        );

        // Test zero address for userStorage
        vm.expectRevert("Invalid address");
        newLogic.initialize(
            address(nodeStorage),
            address(0),
            address(resourceStorage),
            admin
        );

        // Test zero address for resourceStorage
        vm.expectRevert("Invalid address");
        newLogic.initialize(
            address(nodeStorage),
            address(userStorage),
            address(0),
            admin
        );
    }

    function testBaseLogic_IsNodeAuthorized_AsNodeOperator() public {
        vm.prank(testNode);
        address nodeAddress = baseLogic.testIsNodeAuthorized("test-node-1");
        assertEq(nodeAddress, testNode, "Should return node address for authorized node");
    }

    function testBaseLogic_IsNodeAuthorized_AsAdmin() public {
        vm.prank(admin);
        address nodeAddress = baseLogic.testIsNodeAuthorized("test-node-1");
        assertEq(nodeAddress, testNode, "Should return node address for admin");
    }

    function testBaseLogic_IsNodeAuthorized_Unauthorized() public {
        vm.prank(testUser);
        vm.expectRevert("Not authorized");
        baseLogic.testIsNodeAuthorized("test-node-1");
    }

    function testBaseLogic_OnlyNodeOperator_Success() public {
        vm.prank(testNode);
        address nodeAddress = baseLogic.testOnlyNodeOperator("test-node-1");
        assertEq(nodeAddress, testNode, "Should return node address for node operator");
    }

    function testBaseLogic_OnlyNodeOperator_Unauthorized() public {
        vm.prank(testUser);
        vm.expectRevert("Not node operator");
        baseLogic.testOnlyNodeOperator("test-node-1");
    }

    function testBaseLogic_OnlyNodeOperator_Admin() public {
        vm.prank(admin);
        vm.expectRevert("Not node operator");
        baseLogic.testOnlyNodeOperator("test-node-1");
    }

    function testBaseLogic_UpdateStorageContract_NodeStorage() public {
        address newNodeStorage = address(new NodeStorage(admin));
        
        vm.prank(admin);
        vm.expectEmit(true, false, false, true);
        emit StorageContractUpdated("node", newNodeStorage);
        baseLogic.updateStorageContract("node", newNodeStorage);
        
        assertEq(address(baseLogic.nodeStorage()), newNodeStorage, "Node storage should be updated");
    }

    function testBaseLogic_UpdateStorageContract_UserStorage() public {
        address newUserStorage = address(new UserStorage(admin));
        
        vm.prank(admin);
        vm.expectEmit(true, false, false, true);
        emit StorageContractUpdated("user", newUserStorage);
        baseLogic.updateStorageContract("user", newUserStorage);
        
        assertEq(address(baseLogic.userStorage()), newUserStorage, "User storage should be updated");
    }

    function testBaseLogic_UpdateStorageContract_ResourceStorage() public {
        address newResourceStorage = address(new ResourceStorage(admin));
        
        vm.prank(admin);
        vm.expectEmit(true, false, false, true);
        emit StorageContractUpdated("resource", newResourceStorage);
        baseLogic.updateStorageContract("resource", newResourceStorage);
        
        assertEq(address(baseLogic.resourceStorage()), newResourceStorage, "Resource storage should be updated");
    }

    function testBaseLogic_UpdateStorageContract_InvalidType() public {
        address newStorage = address(0x789);
        
        vm.prank(admin);
        vm.expectRevert("Invalid type");
        baseLogic.updateStorageContract("invalid", newStorage);
    }

    function testBaseLogic_UpdateStorageContract_ZeroAddress() public {
        vm.prank(admin);
        vm.expectRevert("Invalid address");
        baseLogic.updateStorageContract("node", address(0));
    }

    function testBaseLogic_UpdateStorageContract_OnlyAdmin() public {
        address newStorage = address(0x789);
        
        vm.prank(testUser);
        vm.expectRevert();
        baseLogic.updateStorageContract("node", newStorage);
    }

    function testBaseLogic_PauseUnpause() public {
        assertFalse(baseLogic.paused(), "Should not be paused initially");
        
        vm.prank(admin);
        baseLogic.pause();
        assertTrue(baseLogic.paused(), "Should be paused after pause()");
        
        vm.prank(admin);
        baseLogic.unpause();
        assertFalse(baseLogic.paused(), "Should not be paused after unpause()");
    }

    function testBaseLogic_PauseOnlyAdmin() public {
        vm.prank(testUser);
        vm.expectRevert();
        baseLogic.pause();
    }

    function testBaseLogic_UnpauseOnlyAdmin() public {
        vm.prank(admin);
        baseLogic.pause();
        
        vm.prank(testUser);
        vm.expectRevert();
        baseLogic.unpause();
    }

    function testBaseLogic_Withdraw() public {
        // Send some ETH to the contract
        uint256 amount = 1 ether;
        vm.deal(address(baseLogic), amount);
        
        uint256 adminBalanceBefore = admin.balance;
        
        vm.prank(admin);
        baseLogic.withdraw();
        
        assertEq(address(baseLogic).balance, 0, "Contract balance should be 0 after withdraw");
        assertEq(admin.balance, adminBalanceBefore + amount, "Admin should receive the ETH");
    }

    function testBaseLogic_WithdrawOnlyAdmin() public {
        vm.deal(address(baseLogic), 1 ether);
        
        vm.prank(testUser);
        vm.expectRevert();
        baseLogic.withdraw();
    }

    function testBaseLogic_ReceiveEther() public {
        uint256 amount = 1 ether;
        uint256 balanceBefore = address(baseLogic).balance;
        
        (bool success,) = address(baseLogic).call{value: amount}("");
        assertTrue(success, "Should be able to receive ETH");
        assertEq(address(baseLogic).balance, balanceBefore + amount, "Balance should increase");
    }

    function testBaseLogic_FallbackFunction() public {
        uint256 amount = 1 ether;
        uint256 balanceBefore = address(baseLogic).balance;
        
        (bool success,) = address(baseLogic).call{value: amount}("invalidFunction()");
        assertTrue(success, "Should be able to call fallback");
        assertEq(address(baseLogic).balance, balanceBefore + amount, "Balance should increase");
    }

    function testBaseLogic_RoleConstants() public view {
        assertEq(baseLogic.ADMIN_ROLE(), baseLogic.DEFAULT_ADMIN_ROLE(), "ADMIN_ROLE should equal DEFAULT_ADMIN_ROLE");
        assertEq(baseLogic.MARKETPLACE_ROLE(), keccak256("MARKETPLACE_ROLE"), "MARKETPLACE_ROLE should match hash");
        assertEq(baseLogic.ORACLE_ROLE(), keccak256("ORACLE_ROLE"), "ORACLE_ROLE should match hash");
        assertEq(baseLogic.NODE_OPERATOR_ROLE(), keccak256("NODE_OPERATOR_ROLE"), "NODE_OPERATOR_ROLE should match hash");
        assertEq(baseLogic.AUTH_SERVICE_ROLE(), keccak256("AUTH_SERVICE_ROLE"), "AUTH_SERVICE_ROLE should match hash");
        assertEq(baseLogic.UPGRADER_ROLE(), keccak256("UPGRADER_ROLE"), "UPGRADER_ROLE should match hash");
    }

    event StorageContractUpdated(string contractType, address newAddress);
}
