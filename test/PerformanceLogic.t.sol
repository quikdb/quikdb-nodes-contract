// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import "../src/proxy/PerformanceLogic.sol";
import "../src/storage/PerformanceStorage.sol";
import "../src/storage/NodeStorage.sol";
import "../src/storage/UserStorage.sol";
import "../src/storage/ResourceStorage.sol";
import "../src/proxy/Proxy.sol";
import {ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

/**
 * @title PerformanceLogicTest
 * @notice Tests for PerformanceLogic contract functionality using QuikProxy infrastructure
 * @dev Tests performance metrics recording, access control, and proxy upgrades
 */
contract PerformanceLogicTest is Test {
    // Test addresses
    address internal admin = address(0x1);
    address internal recorder = address(0x2);
    address internal nodeOperator = address(0x3);
    address internal unauthorized = address(0x4);

    // Storage contracts
    NodeStorage internal nodeStorage;
    UserStorage internal userStorage;
    ResourceStorage internal resourceStorage;
    PerformanceStorage internal performanceStorage;

    // Logic implementation contracts
    PerformanceLogic internal performanceLogicImpl;
    PerformanceLogic internal performanceLogicImplV2; // For upgrade tests

    // QuikProxy infrastructure
    QuikProxy internal performanceLogicProxy;
    QuikProxyAdmin internal quikProxyAdmin;

    // Proxied contract
    PerformanceLogic internal performanceLogic;

    function setUp() public {
        _deployStorageContracts();
        _deployImplementationContract();
        _deployQuikProxyInfrastructure();
        _deployQuikProxy();
        _configureContracts();
        _setupRoles();
    }

    // =============================================================
    //                     DEPLOYMENT HELPERS
    // =============================================================

    function _deployStorageContracts() internal {
        vm.startPrank(admin);
        nodeStorage = new NodeStorage(admin);
        userStorage = new UserStorage(admin);
        resourceStorage = new ResourceStorage(admin);
        performanceStorage = new PerformanceStorage(admin);
        vm.stopPrank();
    }

    function _deployImplementationContract() internal {
        vm.startPrank(admin);
        performanceLogicImpl = new PerformanceLogic();
        vm.stopPrank();
    }

    function _deployQuikProxyInfrastructure() internal {
        vm.startPrank(admin);
        quikProxyAdmin = new QuikProxyAdmin(admin);
        vm.stopPrank();
    }

    function _deployQuikProxy() internal {
        vm.startPrank(admin);

        performanceLogicProxy = new QuikProxy(
            address(performanceLogicImpl),
            address(quikProxyAdmin),
            abi.encodeWithSelector(
                PerformanceLogic.initialize.selector,
                address(nodeStorage),
                address(userStorage),
                address(resourceStorage),
                admin
            )
        );

        vm.stopPrank();
    }

    function _configureContracts() internal {
        vm.startPrank(admin);

        // Get proxied contract
        performanceLogic = PerformanceLogic(payable(address(performanceLogicProxy)));

        // Set up storage contracts to use the proxy
        performanceStorage.setLogicContract(address(performanceLogicProxy));
        
        // Set performance storage in the logic contract
        performanceLogic.setPerformanceStorage(address(performanceStorage));

        vm.stopPrank();
    }

    function _setupRoles() internal {
        vm.startPrank(admin);
        performanceLogic.grantRole(performanceLogic.PERFORMANCE_RECORDER_ROLE(), recorder);
        performanceLogic.grantRole(performanceLogic.NODE_OPERATOR_ROLE(), nodeOperator);
        vm.stopPrank();
    }

    // =============================================================
    //                   PERFORMANCE METRICS TESTS
    // =============================================================

    function testRecordDailyMetrics_StoresValuesCorrectly() public {
        vm.startPrank(recorder);

        string memory nodeId = "test-node-1";
        uint256 testDate = 1700000000; // Fixed timestamp
        uint16 uptime = 9500;      // 95% uptime
        uint32 responseTime = 150;  // 150ms response time
        uint32 throughput = 1000;   // 1000 ops/sec
        uint64 storageUsed = 50000000000; // 50GB
        uint16 networkLatency = 20; // 20ms latency
        uint16 errorRate = 100;     // 1% error rate
        uint8 dailyScore = 85;      // 85/100 score

        // Initially, metrics should not exist
        assertFalse(performanceStorage.doMetricsExist(nodeId, testDate));

        // Record metrics - should succeed now
        performanceLogic.recordDailyMetrics(
            nodeId,
            testDate,
            uptime,
            responseTime,
            throughput,
            storageUsed,
            networkLatency,
            errorRate,
            dailyScore
        );

        // Verify metrics were stored correctly
        assertTrue(performanceStorage.doMetricsExist(nodeId, testDate));
        
        PerformanceStorage.DailyMetrics memory storedMetrics = performanceLogic.getDailyMetrics(nodeId, testDate);
        assertEq(storedMetrics.nodeId, nodeId);
        assertEq(storedMetrics.date, testDate);
        assertEq(storedMetrics.uptime, uptime);
        assertEq(storedMetrics.responseTime, responseTime);
        assertEq(storedMetrics.throughput, throughput);
        assertEq(storedMetrics.storageUsed, storageUsed);
        assertEq(storedMetrics.networkLatency, networkLatency);
        assertEq(storedMetrics.errorRate, errorRate);
        assertEq(storedMetrics.dailyScore, dailyScore);

        vm.stopPrank();
    }

    function testRecordDailyMetrics_SameNodeDateOverwriteForbidden() public {
        vm.startPrank(recorder);

        string memory nodeId = "test-node-duplicate";
        uint256 testDate = 1700000000;

        // First recording should succeed
        performanceLogic.recordDailyMetrics(
            nodeId,
            testDate,
            9500, 150, 1000, 50000000000, 20, 100, 85
        );

        // Verify metrics exist
        assertTrue(performanceStorage.doMetricsExist(nodeId, testDate));

        // Second recording with same node/date should fail
        vm.expectRevert("Metrics already exist");
        performanceLogic.recordDailyMetrics(
            nodeId,
            testDate,
            9600, 140, 1100, 51000000000, 18, 90, 87 // Different values
        );

        vm.stopPrank();
    }

    function testRecordDailyMetrics_NonAuthorizedRecordRevert() public {
        vm.startPrank(unauthorized);

        string memory nodeId = "unauthorized-node";
        uint256 testDate = 1700000000;

        // Unauthorized user should not be able to record metrics
        vm.expectRevert();
        performanceLogic.recordDailyMetrics(
            nodeId,
            testDate,
            9000, 200, 800, 40000000000, 25, 200, 75
        );

        vm.stopPrank();
    }

    function testRecordDailyMetrics_InvalidParametersRevert() public {
        vm.startPrank(recorder);

        string memory nodeId = "test-node-invalid";
        uint256 testDate = 1700000000;

        // Invalid uptime (> 10000)
        vm.expectRevert("Invalid uptime percentage");
        performanceLogic.recordDailyMetrics(
            nodeId,
            testDate,
            10001, // Invalid uptime
            150, 1000, 50000000000, 20, 100, 85
        );

        // Invalid error rate (> 10000)
        vm.expectRevert("Invalid error rate");
        performanceLogic.recordDailyMetrics(
            nodeId,
            testDate,
            9500, 150, 1000, 50000000000, 20,
            10001, // Invalid error rate
            85
        );

        // Invalid daily score (> 100)
        vm.expectRevert("Invalid daily score");
        performanceLogic.recordDailyMetrics(
            nodeId,
            testDate,
            9500, 150, 1000, 50000000000, 20, 100,
            101 // Invalid daily score
        );

        // Invalid node ID (empty)
        vm.expectRevert("Invalid node ID");
        performanceLogic.recordDailyMetrics(
            "", // Empty node ID
            testDate,
            9500, 150, 1000, 50000000000, 20, 100, 85
        );

        vm.stopPrank();
    }

    function testGetDailyMetrics_ReturnsAccurateData() public {
        vm.startPrank(recorder);

        string memory nodeId = "test-node-accurate";
        uint256 testDate = 1700000000;
        uint16 uptime = 9500;      // 95% uptime
        uint32 responseTime = 150;  // 150ms response time
        uint32 throughput = 1000;   // 1000 ops/sec
        uint64 storageUsed = 50000000000; // 50GB
        uint16 networkLatency = 20; // 20ms latency
        uint16 errorRate = 100;     // 1% error rate
        uint8 dailyScore = 85;      // 85/100 score

        // First record some metrics
        performanceLogic.recordDailyMetrics(
            nodeId,
            testDate,
            uptime,
            responseTime,
            throughput,
            storageUsed,
            networkLatency,
            errorRate,
            dailyScore
        );

        vm.stopPrank();

        // Get metrics and verify they match what was recorded
        PerformanceStorage.DailyMetrics memory metrics = performanceLogic.getDailyMetrics(nodeId, testDate);

        assertEq(metrics.nodeId, nodeId);
        assertEq(metrics.date, testDate);
        assertEq(metrics.uptime, uptime);
        assertEq(metrics.responseTime, responseTime);
        assertEq(metrics.throughput, throughput);
        assertEq(metrics.storageUsed, storageUsed);
        assertEq(metrics.networkLatency, networkLatency);
        assertEq(metrics.errorRate, errorRate);
        assertEq(metrics.dailyScore, dailyScore);
    }

    function testGetDailyMetrics_InvalidNodeIdRevert() public {
        uint256 testDate = 1700000000;

        // Empty node ID should revert
        vm.expectRevert("Invalid node ID");
        performanceLogic.getDailyMetrics("", testDate);
    }

    function testGetNodeMetricsHistory_ReturnsCorrectFormat() public {
        vm.startPrank(recorder);

        string memory nodeId = "test-node-history";
        uint256 startDate = 1700000000;
        uint256 endDate = 1700000000 + (5 * 86400); // 5 days later

        // Record some metrics first
        performanceLogic.recordDailyMetrics(
            nodeId,
            startDate,
            9200, 180, 900, 45000000000, 25, 150, 80
        );

        vm.stopPrank();

        // Get metrics history
        (PerformanceStorage.DailyMetrics[] memory metrics, uint256[] memory dates) = 
            performanceLogic.getNodeMetricsHistory(nodeId, startDate, endDate);

        // Verify we got the recorded data
        assertEq(metrics.length, 1);
        assertEq(dates.length, 1);
        assertEq(dates[0], startDate);
        assertEq(metrics[0].nodeId, nodeId);
        assertEq(metrics[0].date, startDate);
        assertEq(metrics[0].dailyScore, 80);
    }

    function testGetNodeMetricsHistory_InvalidDateRangeRevert() public {
        string memory nodeId = "test-node-invalid-range";
        uint256 startDate = 1700000000;
        uint256 endDate = startDate - 86400; // End before start

        // Invalid date range should revert
        vm.expectRevert("Invalid date range");
        performanceLogic.getNodeMetricsHistory(nodeId, startDate, endDate);
    }

    // =============================================================
    //                     PROXY UPGRADE TESTS
    // =============================================================

    function testProxyUpgrade_PreservesStorageUsingQuikProxy() public {
        // Record some initial state
        vm.startPrank(recorder);
        
        string memory nodeId = "upgrade-test-node";
        uint256 testDate = 1700000000;

        // Record metrics
        performanceLogic.recordDailyMetrics(
            nodeId,
            testDate,
            9200, 180, 900, 45000000000, 25, 150, 80
        );
        
        // Verify metrics were stored
        assertTrue(performanceStorage.doMetricsExist(nodeId, testDate));
        
        vm.stopPrank();

        // Deploy new implementation
        vm.startPrank(admin);
        performanceLogicImplV2 = new PerformanceLogic();

        // Verify current version
        assertEq(performanceLogic.VERSION(), 1);

        // Perform upgrade using QuikProxyAdmin
        quikProxyAdmin.upgradeLogic(
            ITransparentUpgradeableProxy(address(performanceLogicProxy)),
            address(performanceLogicImplV2)
        );

        // Verify upgrade worked - contract should still respond
        assertEq(performanceLogic.VERSION(), 1);

        // Verify roles are preserved
        assertTrue(performanceLogic.hasRole(performanceLogic.ADMIN_ROLE(), admin));
        assertTrue(performanceLogic.hasRole(performanceLogic.PERFORMANCE_RECORDER_ROLE(), recorder));

        // Verify storage contract reference is preserved
        assertEq(address(performanceLogic.performanceStorage()), address(performanceStorage));

        // Verify we can still call functions after upgrade and stored data is preserved
        PerformanceStorage.DailyMetrics memory metrics = performanceLogic.getDailyMetrics(nodeId, testDate);
        assertEq(metrics.nodeId, nodeId);
        assertEq(metrics.dailyScore, 80);

        vm.stopPrank();
    }

    function testProxyUpgrade_UnauthorizedUpgradeRevert() public {
        vm.startPrank(unauthorized);

        // Deploy new implementation
        PerformanceLogic newImpl = new PerformanceLogic();

        // Unauthorized user should not be able to upgrade
        vm.expectRevert("Not authorized to upgrade");
        quikProxyAdmin.upgradeLogic(
            ITransparentUpgradeableProxy(address(performanceLogicProxy)),
            address(newImpl)
        );

        vm.stopPrank();
    }

    function testProxyUpgrade_OnlyAdminCanUpgrade() public {
        // Deploy new implementation as admin
        vm.startPrank(admin);
        PerformanceLogic newImpl = new PerformanceLogic();

        // Admin should be able to upgrade
        quikProxyAdmin.upgradeLogic(
            ITransparentUpgradeableProxy(address(performanceLogicProxy)),
            address(newImpl)
        );

        // Verify upgrade worked
        assertEq(performanceLogic.VERSION(), 1);

        vm.stopPrank();
    }

    // =============================================================
    //                     INTEGRATION TESTS
    // =============================================================

    function testIntegration_BaseLogicInheritance() public view {
        // Verify PerformanceLogic inherits from BaseLogic correctly
        assertEq(address(performanceLogic.nodeStorage()), address(nodeStorage));
        assertEq(address(performanceLogic.userStorage()), address(userStorage));
        assertEq(address(performanceLogic.resourceStorage()), address(resourceStorage));

        // Verify BaseLogic roles are available
        assertTrue(performanceLogic.hasRole(performanceLogic.ADMIN_ROLE(), admin));
        assertTrue(performanceLogic.hasRole(performanceLogic.NODE_OPERATOR_ROLE(), nodeOperator));
    }

    function testIntegration_StorageContractLinking() public view {
        // Verify performance storage has logic contract set
        assertTrue(performanceStorage.hasRole(performanceStorage.LOGIC_ROLE(), address(performanceLogicProxy)));

        // Verify performance logic has storage contract set
        assertEq(address(performanceLogic.performanceStorage()), address(performanceStorage));
    }

    function testIntegration_RoleBasedAccess() public {
        // Test admin functions
        vm.startPrank(admin);
        
        // Admin should be able to update storage contract
        performanceLogic.updatePerformanceStorage(address(performanceStorage));
        
        // Admin should be able to pause/unpause
        performanceLogic.pause();
        performanceLogic.unpause();
        
        vm.stopPrank();

        // Test unauthorized access to admin functions
        vm.startPrank(unauthorized);
        
        vm.expectRevert();
        performanceLogic.updatePerformanceStorage(address(0x999));
        
        vm.expectRevert();
        performanceLogic.pause();
        
        vm.stopPrank();
    }

    function testIntegration_PauseStopsOperations() public {
        // Pause the contract
        vm.startPrank(admin);
        performanceLogic.pause();
        vm.stopPrank();

        // Recording should fail when paused
        vm.startPrank(recorder);
        
        vm.expectRevert(); // Using generic expectRevert for OpenZeppelin v5 compatibility
        performanceLogic.recordDailyMetrics(
            "paused-test-node",
            1700000000,
            9500, 150, 1000, 50000000000, 20, 100, 85
        );
        
        vm.stopPrank();

        // Unpause and try again
        vm.startPrank(admin);
        performanceLogic.unpause();
        vm.stopPrank();

        // Should work after unpause
        vm.startPrank(recorder);
        
        performanceLogic.recordDailyMetrics(
            "unpaused-test-node",
            1700000000,
            9500, 150, 1000, 50000000000, 20, 100, 85
        );
        
        // Verify metrics were recorded
        assertTrue(performanceStorage.doMetricsExist("unpaused-test-node", 1700000000));
        
        vm.stopPrank();
    }

    // =============================================================
    //                       HELPER TESTS
    // =============================================================

    function testHelpers_ValidateInputParameters() public {
        vm.startPrank(recorder);

        string memory nodeId = "validation-test";
        uint256 testDate = 1700000000;

        // Test boundary values that should be valid
        
        // Minimum valid values - should succeed
        performanceLogic.recordDailyMetrics(
            nodeId, testDate,
            0,     // 0% uptime (minimum)
            1,     // 1ms response time
            0,     // 0 ops/sec throughput
            0,     // 0 bytes storage
            0,     // 0ms network latency
            0,     // 0% error rate (minimum)
            0      // 0/100 daily score (minimum)
        );

        // Maximum valid values - should succeed
        performanceLogic.recordDailyMetrics(
            nodeId, testDate + 1,
            10000, // 100% uptime (maximum)
            type(uint32).max, // Max response time
            type(uint32).max, // Max throughput
            type(uint64).max, // Max storage
            type(uint16).max, // Max network latency
            10000, // 100% error rate (maximum)
            100    // 100/100 daily score (maximum)
        );

        vm.stopPrank();
    }
}
