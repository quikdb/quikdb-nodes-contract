// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "./BaseTest.sol";

/**
 * @title ApplicationLogicTest
 * @notice Test suite for ApplicationLogic contract functionality
 */
contract ApplicationLogicTest is BaseTest {
    string[] private testNodeIds;
    string constant TEST_APP_ID = "test-app-1";
    string constant TEST_CONFIG_HASH = "QmTestConfigHash123";

    function setUp() public override {
        super.setUp();
        
        // Prepare test node IDs
        testNodeIds.push("node-1");
        testNodeIds.push("node-2");
        testNodeIds.push("node-3");
    }
    
    function testApplicationLogic_RegisterApplication() public {
        vm.startPrank(applicationDeployer);
        
        vm.expectEmit(true, true, false, true);
        emit ApplicationLogic.ApplicationRegistered(TEST_APP_ID, user, testNodeIds.length, block.timestamp);
        
        applicationLogic.registerApplication(
            TEST_APP_ID,
            user,
            testNodeIds,
            TEST_CONFIG_HASH
        );

        // Verify application was stored correctly
        (
            string memory appId,
            address deployer,
            string[] memory nodeIds,
            uint8 status,
            uint256 deployedAt,
            string memory configHash
        ) = applicationLogic.getApplication(TEST_APP_ID);

        assertEq(appId, TEST_APP_ID);
        assertEq(deployer, user);
        assertEq(nodeIds.length, testNodeIds.length);
        assertEq(status, 0); // pending status
        assertEq(deployedAt, block.timestamp);
        assertEq(configHash, TEST_CONFIG_HASH);

        // Verify application exists
        assertTrue(applicationLogic.applicationExists(TEST_APP_ID));

        // Verify deployer ownership
        assertTrue(applicationLogic.isDeployerOwner(user, TEST_APP_ID));
        assertFalse(applicationLogic.isDeployerOwner(admin, TEST_APP_ID));

        vm.stopPrank();
    }

    function testApplicationLogic_RegisterApplication_AlreadyExists() public {
        vm.startPrank(applicationDeployer);
        
        // Register first time
        applicationLogic.registerApplication(
            TEST_APP_ID,
            user,
            testNodeIds,
            TEST_CONFIG_HASH
        );

        // Try to register again
        vm.expectRevert(abi.encodeWithSelector(ApplicationLogic.ApplicationAlreadyExists.selector, TEST_APP_ID));
        applicationLogic.registerApplication(
            TEST_APP_ID,
            user,
            testNodeIds,
            TEST_CONFIG_HASH
        );
        
        vm.stopPrank();
    }
    
    function testApplicationLogic_RegisterApplication_OnlyAuthorized() public {
        vm.startPrank(user); // Unauthorized user
        
        vm.expectRevert();
        applicationLogic.registerApplication(
            TEST_APP_ID,
            user,
            testNodeIds,
            TEST_CONFIG_HASH
        );
        
        vm.stopPrank();
    }
    
    function testApplicationLogic_RegisterApplication_InvalidAppId() public {
        vm.startPrank(applicationDeployer);
        
        vm.expectRevert(abi.encodeWithSelector(ApplicationLogic.InvalidApplicationId.selector, ""));
        applicationLogic.registerApplication(
            "", // Invalid app ID
            user,
            testNodeIds,
            TEST_CONFIG_HASH
        );
        
        vm.stopPrank();
    }
    
    function testApplicationLogic_RegisterApplication_InvalidDeployer() public {
        vm.startPrank(applicationDeployer);
        
        vm.expectRevert(abi.encodeWithSelector(ApplicationLogic.InvalidDeployer.selector, address(0)));
        applicationLogic.registerApplication(
            TEST_APP_ID,
            address(0), // Invalid deployer
            testNodeIds,
            TEST_CONFIG_HASH
        );
        
        vm.stopPrank();
    }
    
    function testApplicationLogic_RegisterApplication_EmptyNodeList() public {
        string[] memory emptyNodeIds = new string[](0); // Empty array
        
        vm.startPrank(applicationDeployer);
        
        vm.expectRevert(ApplicationLogic.EmptyNodeList.selector);
        applicationLogic.registerApplication(
            TEST_APP_ID,
            user,
            emptyNodeIds,
            TEST_CONFIG_HASH
        );
        
        vm.stopPrank();
    }
    
    function testApplicationLogic_UpdateStatus() public {
        // First register an application
        vm.startPrank(applicationDeployer);
        applicationLogic.registerApplication(
            TEST_APP_ID,
            user,
            testNodeIds,
            TEST_CONFIG_HASH
        );
        vm.stopPrank();

        // Update status - need application manager role
        vm.startPrank(admin); // admin has manager role
        
        vm.expectEmit(true, true, false, true);
        emit ApplicationLogic.ApplicationStatusChanged(TEST_APP_ID, user, 0, 1);
        
        applicationLogic.updateStatus(TEST_APP_ID, 1);

        // Verify status was updated
        (, , , uint8 status, , ) = applicationLogic.getApplication(TEST_APP_ID);
        assertEq(status, 1);
        
        vm.stopPrank();
    }

    function testApplicationLogic_UpdateStatus_ApplicationNotFound() public {
        vm.startPrank(admin);
        
        vm.expectRevert(abi.encodeWithSelector(ApplicationLogic.ApplicationNotFound.selector, "nonexistent"));
        applicationLogic.updateStatus("nonexistent", 1);
        
        vm.stopPrank();
    }

    function testApplicationLogic_UpdateStatus_InvalidStatus() public {
        // First register an application
        vm.startPrank(applicationDeployer);
        applicationLogic.registerApplication(TEST_APP_ID, user, testNodeIds, TEST_CONFIG_HASH);
        vm.stopPrank();

        vm.startPrank(admin);
        
        vm.expectRevert(abi.encodeWithSelector(ApplicationLogic.InvalidStatus.selector, 5));
        applicationLogic.updateStatus(TEST_APP_ID, 5); // Status > 4 is invalid
        
        vm.stopPrank();
    }
    
    function testApplicationLogic_UpdateStatus_OnlyAuthorized() public {
        // First register an application
        vm.startPrank(applicationDeployer);
        applicationLogic.registerApplication(TEST_APP_ID, user, testNodeIds, TEST_CONFIG_HASH);
        vm.stopPrank();

        vm.startPrank(user); // Unauthorized user
        
        vm.expectRevert();
        applicationLogic.updateStatus(TEST_APP_ID, 1);
        
        vm.stopPrank();
    }
    
    function testApplicationLogic_UpdateStatus_InvalidAppId() public {
        vm.startPrank(admin);
        
        vm.expectRevert(abi.encodeWithSelector(ApplicationLogic.InvalidApplicationId.selector, ""));
        applicationLogic.updateStatus("", 1); // Invalid app ID
        
        vm.stopPrank();
    }
    
    function testApplicationLogic_GetApplication() public view {
        // Test nonexistent application
        (
            string memory appId,
            address deployer,
            string[] memory nodeIds,
            uint8 status,
            uint256 deployedAt,
            string memory configHash
        ) = applicationLogic.getApplication("nonexistent-app");
        
        // Should return empty data for nonexistent app
        assertEq(bytes(appId).length, 0, "AppId should be empty for nonexistent app");
        assertEq(deployer, address(0), "Deployer should be zero for nonexistent app");
        assertEq(nodeIds.length, 0, "NodeIds should be empty for nonexistent app");
        assertEq(status, 0, "Status should be 0 for nonexistent app");
        assertEq(deployedAt, 0, "DeployedAt should be 0 for nonexistent app");
        assertEq(bytes(configHash).length, 0, "ConfigHash should be empty for nonexistent app");
    }
    
    function testApplicationLogic_GetApplication_InvalidAppId() public {
        vm.expectRevert(abi.encodeWithSelector(ApplicationLogic.InvalidApplicationId.selector, ""));
        applicationLogic.getApplication("");
    }
    
    function testApplicationLogic_GetDeployerApps() public {
        // Initially empty
        string[] memory apps = applicationLogic.getDeployerApps(user);
        assertEq(apps.length, 0, "Should return empty apps array initially");

        // Register multiple applications
        vm.startPrank(applicationDeployer);
        applicationLogic.registerApplication("app-1", user, testNodeIds, "hash1");
        applicationLogic.registerApplication("app-2", user, testNodeIds, "hash2");
        vm.stopPrank();

        // Should return both applications
        apps = applicationLogic.getDeployerApps(user);
        assertEq(apps.length, 2);
        assertEq(apps[0], "app-1");
        assertEq(apps[1], "app-2");
    }
    
    function testApplicationLogic_GetDeployerApps_InvalidDeployer() public {
        vm.expectRevert(abi.encodeWithSelector(ApplicationLogic.InvalidDeployer.selector, address(0)));
        applicationLogic.getDeployerApps(address(0));
    }

    function testApplicationLogic_GetNodeApps() public {
        // Register applications on specific nodes
        vm.startPrank(applicationDeployer);
        
        string[] memory node1Apps = new string[](1);
        node1Apps[0] = "node-1";
        
        applicationLogic.registerApplication("app-1", user, node1Apps, "hash1");
        applicationLogic.registerApplication("app-2", user, node1Apps, "hash2");
        vm.stopPrank();

        // Check node apps
        string[] memory apps = applicationLogic.getNodeApps("node-1");
        assertEq(apps.length, 2);
        assertEq(apps[0], "app-1");
        assertEq(apps[1], "app-2");

        // Non-existent node should return empty
        apps = applicationLogic.getNodeApps("nonexistent-node");
        assertEq(apps.length, 0);
    }
    
    function testApplicationLogic_ApplicationExists() public {
        bool exists = applicationLogic.applicationExists("nonexistent-app");
        assertFalse(exists, "Nonexistent app should return false");

        // Register application
        vm.startPrank(applicationDeployer);
        applicationLogic.registerApplication(TEST_APP_ID, user, testNodeIds, TEST_CONFIG_HASH);
        vm.stopPrank();

        // Should now exist
        exists = applicationLogic.applicationExists(TEST_APP_ID);
        assertTrue(exists, "Registered app should return true");
    }
    
    function testApplicationLogic_ApplicationExists_InvalidAppId() public view {
        bool exists = applicationLogic.applicationExists("");
        assertFalse(exists, "Empty app ID should return false");
    }
    
    function testApplicationLogic_IsDeployerOwner() public {
        bool owns = applicationLogic.isDeployerOwner(user, "nonexistent-app");
        assertFalse(owns, "Should return false for nonexistent app");

        // Register application
        vm.startPrank(applicationDeployer);
        applicationLogic.registerApplication(TEST_APP_ID, user, testNodeIds, TEST_CONFIG_HASH);
        vm.stopPrank();

        // Check ownership
        owns = applicationLogic.isDeployerOwner(user, TEST_APP_ID);
        assertTrue(owns, "Deployer should own their app");

        owns = applicationLogic.isDeployerOwner(admin, TEST_APP_ID);
        assertFalse(owns, "Different address should not own the app");
    }
    
    function testApplicationLogic_IsDeployerOwner_InvalidParams() public view {
        bool owns1 = applicationLogic.isDeployerOwner(address(0), "test-app");
        assertFalse(owns1, "Should return false for invalid deployer");
        
        bool owns2 = applicationLogic.isDeployerOwner(user, "");
        assertFalse(owns2, "Should return false for invalid app ID");
    }

    function testApplicationLogic_PausedFunctionality() public {
        // Pause the contract
        vm.startPrank(admin);
        applicationLogic.pause();
        vm.stopPrank();

        // Should revert when paused
        vm.startPrank(applicationDeployer);
        vm.expectRevert();
        applicationLogic.registerApplication(TEST_APP_ID, user, testNodeIds, TEST_CONFIG_HASH);
        vm.stopPrank();

        vm.startPrank(admin);
        vm.expectRevert();
        applicationLogic.updateStatus(TEST_APP_ID, 1);
        vm.stopPrank();

        // Unpause and try again
        vm.startPrank(admin);
        applicationLogic.unpause();
        vm.stopPrank();

        vm.startPrank(applicationDeployer);
        applicationLogic.registerApplication(TEST_APP_ID, user, testNodeIds, TEST_CONFIG_HASH);
        vm.stopPrank();
    }

    function testApplicationLogic_MultipleApplicationsAndOperations() public {
        vm.startPrank(applicationDeployer);

        // Register multiple applications with different node configurations
        string[] memory app1Nodes = new string[](2);
        app1Nodes[0] = "node-1";
        app1Nodes[1] = "node-2";

        string[] memory app2Nodes = new string[](1);
        app2Nodes[0] = "node-3";

        applicationLogic.registerApplication("multi-app-1", user, app1Nodes, "hash1");
        applicationLogic.registerApplication("multi-app-2", user, app2Nodes, "hash2");

        vm.stopPrank();

        // Update statuses
        vm.startPrank(admin);
        applicationLogic.updateStatus("multi-app-1", 1);
        applicationLogic.updateStatus("multi-app-2", 2);
        vm.stopPrank();

        // Verify deployer apps
        string[] memory deployerApps = applicationLogic.getDeployerApps(user);
        assertEq(deployerApps.length, 2);

        // Verify node apps
        string[] memory node1Apps = applicationLogic.getNodeApps("node-1");
        assertEq(node1Apps.length, 1);
        assertEq(node1Apps[0], "multi-app-1");

        string[] memory node3Apps = applicationLogic.getNodeApps("node-3");
        assertEq(node3Apps.length, 1);
        assertEq(node3Apps[0], "multi-app-2");

        // Verify application details
        (, , , uint8 status1, , ) = applicationLogic.getApplication("multi-app-1");
        (, , , uint8 status2, , ) = applicationLogic.getApplication("multi-app-2");
        assertEq(status1, 1);
        assertEq(status2, 2);
    }
}
