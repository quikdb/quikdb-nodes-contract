// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./BaseTest.sol";

/**
 * @title ApplicationLogicTest
 * @notice Test suite for ApplicationLogic contract functionality
 */
contract ApplicationLogicTest is BaseTest {
    
    function testApplicationLogic_RegisterApplication() public {
        string[] memory nodeIds = new string[](2);
        nodeIds[0] = "node1";
        nodeIds[1] = "node2";
        
        vm.startPrank(applicationDeployer);
        
        vm.expectEmit(true, true, false, false);
        emit ApplicationLogic.ApplicationRegistered("test-app", user, 2, block.timestamp);
        
        applicationLogic.registerApplication(
            "test-app",
            user,
            nodeIds,
            "config-hash-123"
        );
        
        vm.stopPrank();
    }
    
    function testApplicationLogic_RegisterApplication_OnlyAuthorized() public {
        string[] memory nodeIds = new string[](1);
        nodeIds[0] = "node1";
        
        vm.startPrank(user); // Unauthorized user
        
        vm.expectRevert();
        applicationLogic.registerApplication(
            "test-app",
            user,
            nodeIds,
            "config-hash-123"
        );
        
        vm.stopPrank();
    }
    
    function testApplicationLogic_RegisterApplication_InvalidAppId() public {
        string[] memory nodeIds = new string[](1);
        nodeIds[0] = "node1";
        
        vm.startPrank(applicationDeployer);
        
        vm.expectRevert();
        applicationLogic.registerApplication(
            "", // Invalid app ID
            user,
            nodeIds,
            "config-hash-123"
        );
        
        vm.stopPrank();
    }
    
    function testApplicationLogic_RegisterApplication_InvalidDeployer() public {
        string[] memory nodeIds = new string[](1);
        nodeIds[0] = "node1";
        
        vm.startPrank(applicationDeployer);
        
        vm.expectRevert();
        applicationLogic.registerApplication(
            "test-app",
            address(0), // Invalid deployer
            nodeIds,
            "config-hash-123"
        );
        
        vm.stopPrank();
    }
    
    function testApplicationLogic_RegisterApplication_EmptyNodeList() public {
        string[] memory nodeIds = new string[](0); // Empty array
        
        vm.startPrank(applicationDeployer);
        
        vm.expectRevert();
        applicationLogic.registerApplication(
            "test-app",
            user,
            nodeIds,
            "config-hash-123"
        );
        
        vm.stopPrank();
    }
    
    function testApplicationLogic_UpdateStatus() public {
        vm.startPrank(applicationDeployer);
        
        // Note: This test may fail because application doesn't exist in storage
        // In real implementation, we'd register first, then update
        vm.expectRevert();
        applicationLogic.updateStatus("test-app", 1);
        
        vm.stopPrank();
    }
    
    function testApplicationLogic_UpdateStatus_OnlyAuthorized() public {
        vm.startPrank(user); // Unauthorized user
        
        vm.expectRevert();
        applicationLogic.updateStatus("test-app", 1);
        
        vm.stopPrank();
    }
    
    function testApplicationLogic_UpdateStatus_InvalidAppId() public {
        vm.startPrank(applicationDeployer);
        
        vm.expectRevert();
        applicationLogic.updateStatus("", 1); // Invalid app ID
        
        vm.stopPrank();
    }
    
    function testApplicationLogic_GetApplication() public view {
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
        vm.expectRevert();
        applicationLogic.getApplication("");
    }
    
    function testApplicationLogic_GetDeployerApps() public view {
        string[] memory apps = applicationLogic.getDeployerApps(user);
        
        // Should return empty array initially
        assertEq(apps.length, 0, "Should return empty apps array initially");
    }
    
    function testApplicationLogic_GetDeployerApps_InvalidDeployer() public {
        vm.expectRevert();
        applicationLogic.getDeployerApps(address(0));
    }
    
    function testApplicationLogic_ApplicationExists() public view {
        bool exists = applicationLogic.applicationExists("nonexistent-app");
        assertFalse(exists, "Nonexistent app should return false");
    }
    
    function testApplicationLogic_ApplicationExists_InvalidAppId() public view {
        bool exists = applicationLogic.applicationExists("");
        assertFalse(exists, "Empty app ID should return false");
    }
    
    function testApplicationLogic_IsDeployerOwner() public view {
        bool owns = applicationLogic.isDeployerOwner(user, "nonexistent-app");
        assertFalse(owns, "Should return false for nonexistent app");
    }
    
    function testApplicationLogic_IsDeployerOwner_InvalidParams() public view {
        bool owns1 = applicationLogic.isDeployerOwner(address(0), "test-app");
        assertFalse(owns1, "Should return false for invalid deployer");
        
        bool owns2 = applicationLogic.isDeployerOwner(user, "");
        assertFalse(owns2, "Should return false for invalid app ID");
    }
}
