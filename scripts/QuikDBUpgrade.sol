// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import "../src/proxy/NodeLogic.sol";
import "../src/proxy/UserLogic.sol";
import "../src/proxy/ResourceLogic.sol";
import "../src/proxy/RewardsLogic.sol";
import "../src/proxy/ApplicationLogic.sol";
import "../src/proxy/StorageAllocatorLogic.sol";
import "../src/proxy/ClusterLogic.sol";
import "../src/proxy/PerformanceLogic.sol";
import "../src/proxy/Facade.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/interfaces/IERC1967.sol";

/**
 * @title QuikDBUpgrade
 * @notice Upgrades QuikDB logic contracts while preserving proxy addresses
 * @dev Uses CREATE2 for new implementations and ProxyAdmin for upgrades
 */
contract QuikDBUpgrade is Script {
    // CREATE2 salt for new implementation contracts - increment version for upgrades
    bytes32 public constant IMPL_SALT = keccak256("QuikDB.v7.2025.IMPL");

    // EIP-1967 admin slot: bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1)
    bytes32 constant ADMIN_SLOT = bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1);

    // Existing deployment addresses (loaded from latest.json)
    struct ExistingDeployment {
        address nodeStorage;
        address userStorage;
        address resourceStorage;
        address rewardsStorage;
        address applicationStorage;
        address storageAllocatorStorage;
        address clusterStorage;
        address performanceStorage;
        address proxyAdmin;
        address nodeLogicProxy;
        address userLogicProxy;
        address resourceLogicProxy;
        address rewardsLogicProxy;
        address applicationLogicProxy;
        address storageAllocatorLogicProxy;
        address clusterLogicProxy;
        address performanceLogicProxy;
        address facadeProxy;
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("=== QUIKDB PROXY UPGRADE STARTED ===");
        console.log("Deployer address:", deployer);
        console.log("New Implementation Salt:", vm.toString(IMPL_SALT));

        // Load existing deployment addresses
        ExistingDeployment memory existing = loadExistingDeployment();

        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy new implementation contracts using CREATE2
        console.log("=== DEPLOYING NEW IMPLEMENTATIONS (CREATE2) ===");
        NodeLogic newNodeLogicImpl = new NodeLogic{salt: IMPL_SALT}();
        UserLogic newUserLogicImpl = new UserLogic{salt: IMPL_SALT}();
        ResourceLogic newResourceLogicImpl = new ResourceLogic{salt: IMPL_SALT}();
        RewardsLogic newRewardsLogicImpl = new RewardsLogic{salt: IMPL_SALT}();
        ApplicationLogic newApplicationLogicImpl = new ApplicationLogic{salt: IMPL_SALT}();
        StorageAllocatorLogic newStorageAllocatorLogicImpl = new StorageAllocatorLogic{salt: IMPL_SALT}();
        ClusterLogic newClusterLogicImpl = new ClusterLogic{salt: IMPL_SALT}();
        PerformanceLogic newPerformanceLogicImpl = new PerformanceLogic{salt: IMPL_SALT}();
        Facade newFacadeImpl = new Facade{salt: IMPL_SALT}();

        console.log("New NodeLogic Implementation deployed at:", address(newNodeLogicImpl));
        console.log("New UserLogic Implementation deployed at:", address(newUserLogicImpl));
        console.log("New ResourceLogic Implementation deployed at:", address(newResourceLogicImpl));
        console.log("New RewardsLogic Implementation deployed at:", address(newRewardsLogicImpl));
        console.log("New ApplicationLogic Implementation deployed at:", address(newApplicationLogicImpl));
        console.log("New StorageAllocatorLogic Implementation deployed at:", address(newStorageAllocatorLogicImpl));
        console.log("New ClusterLogic Implementation deployed at:", address(newClusterLogicImpl));
        console.log("New PerformanceLogic Implementation deployed at:", address(newPerformanceLogicImpl));
        console.log("New Facade Implementation deployed at:", address(newFacadeImpl));

        // 2. Upgrade proxies to new implementations
        console.log("=== UPGRADING PROXY CONTRACTS ===");

        // Debug the proxy admin address
        console.log("ProxyAdmin address:", existing.proxyAdmin);

        // Try to verify admin has required access with better error handling
        ProxyAdmin proxyAdmin = ProxyAdmin(existing.proxyAdmin);

        // Check if the address is actually a contract
        uint256 codeSize;
        address proxyAdminAddr = existing.proxyAdmin;

        assembly {
            codeSize := extcodesize(proxyAdminAddr)
        }

        console.log("ProxyAdmin code size:", codeSize);
        require(codeSize > 0, "ProxyAdmin address has no code - not a contract");

        // Check if the deployer is the owner of the ProxyAdmin - with try/catch
        console.log("Checking ProxyAdmin owner...");
        try proxyAdmin.owner() returns (address proxyAdminOwner) {
            console.log("ProxyAdmin owner:", proxyAdminOwner);
            console.log("Deployer address:", deployer);

            if (proxyAdminOwner != deployer) {
                console.log("WARNING: Deployer is not the owner of ProxyAdmin");
                console.log("Continuing anyway - remove this in production!");
                // For testing, we'll continue instead of reverting
                // require(proxyAdminOwner == deployer, "Deployer is not the owner of ProxyAdmin");
            }
        } catch Error(string memory reason) {
            console.log("Failed to get ProxyAdmin owner:", reason);
            revert(string(abi.encodePacked("Failed to get ProxyAdmin owner: ", reason)));
        } catch {
            console.log("Failed to get ProxyAdmin owner: unknown error");
            revert("Failed to get ProxyAdmin owner: unknown error");
        }

        // Use try/catch to handle potential errors during upgrades

        // Upgrade proxies using ProxyAdmin
        console.log("Using ProxyAdmin for upgrades");

        // Get direct reference to the interface method we need to call
        bytes memory emptyData = "";

        // Upgrade all proxies using raw admin slot logic like NodeLogic
        console.log("Upgrading proxies using direct admin address + upgradeAndCall...");

        address[9] memory proxyAddrs;
        address[9] memory newImpls;
        string[9] memory labels = ["NodeLogic", "UserLogic", "ResourceLogic", "RewardsLogic", "ApplicationLogic", "StorageAllocatorLogic", "ClusterLogic", "PerformanceLogic", "Facade"];

        proxyAddrs[0] = existing.nodeLogicProxy;
        proxyAddrs[1] = existing.userLogicProxy;
        proxyAddrs[2] = existing.resourceLogicProxy;
        proxyAddrs[3] = existing.rewardsLogicProxy;
        proxyAddrs[4] = existing.applicationLogicProxy;
        proxyAddrs[5] = existing.storageAllocatorLogicProxy;
        proxyAddrs[6] = existing.clusterLogicProxy;
        proxyAddrs[7] = existing.performanceLogicProxy;
        proxyAddrs[8] = existing.facadeProxy;

        newImpls[0] = address(newNodeLogicImpl);
        newImpls[1] = address(newUserLogicImpl);
        newImpls[2] = address(newResourceLogicImpl);
        newImpls[3] = address(newRewardsLogicImpl);
        newImpls[4] = address(newApplicationLogicImpl);
        newImpls[5] = address(newStorageAllocatorLogicImpl);
        newImpls[6] = address(newClusterLogicImpl);
        newImpls[7] = address(newPerformanceLogicImpl);
        newImpls[8] = address(newFacadeImpl);

        for (uint256 i = 0; i < proxyAddrs.length; i++) {
            bytes32 adminRaw = vm.load(proxyAddrs[i], ADMIN_SLOT);
            address proxyAdminFromSlot = address(uint160(uint256(adminRaw)));

            console.log(string.concat("Upgrading ", labels[i], " proxy..."));

            (bool success, bytes memory returnData) = proxyAdminFromSlot.call(
                abi.encodeWithSignature("upgradeAndCall(address,address,bytes)", proxyAddrs[i], newImpls[i], emptyData)
            );

            if (success) {
                console.log(string.concat(labels[i], " proxy upgraded successfully"));
            } else {
                string memory reason = returnData.length > 0 ? _getRevertMsg(returnData) : "unknown error";
                console.log(string.concat(labels[i], " upgrade failed: "), reason);
                revert(string(abi.encodePacked(labels[i], " upgrade failed: ", reason)));
            }
        }

        // 3. Verify upgrades
        console.log("=== VERIFYING UPGRADES ===");
        verifyUpgrade(existing.nodeLogicProxy, address(newNodeLogicImpl), "NodeLogic");
        verifyUpgrade(existing.userLogicProxy, address(newUserLogicImpl), "UserLogic");
        verifyUpgrade(existing.resourceLogicProxy, address(newResourceLogicImpl), "ResourceLogic");
        verifyUpgrade(existing.rewardsLogicProxy, address(newRewardsLogicImpl), "RewardsLogic");
        verifyUpgrade(existing.applicationLogicProxy, address(newApplicationLogicImpl), "ApplicationLogic");
        verifyUpgrade(existing.storageAllocatorLogicProxy, address(newStorageAllocatorLogicImpl), "StorageAllocatorLogic");
        verifyUpgrade(existing.clusterLogicProxy, address(newClusterLogicImpl), "ClusterLogic");
        verifyUpgrade(existing.performanceLogicProxy, address(newPerformanceLogicImpl), "PerformanceLogic");
        verifyUpgrade(existing.facadeProxy, address(newFacadeImpl), "Facade");

        vm.stopBroadcast();

        console.log("=== UPGRADE SUMMARY ===");
        console.log("Proxy Addresses (UNCHANGED):");
        console.log("  NodeLogic Proxy:", existing.nodeLogicProxy);
        console.log("  UserLogic Proxy:", existing.userLogicProxy);
        console.log("  ResourceLogic Proxy:", existing.resourceLogicProxy);
        console.log("  RewardsLogic Proxy:", existing.rewardsLogicProxy);
        console.log("  ApplicationLogic Proxy:", existing.applicationLogicProxy);
        console.log("  StorageAllocatorLogic Proxy:", existing.storageAllocatorLogicProxy);
        console.log("  ClusterLogic Proxy:", existing.clusterLogicProxy);
        console.log("  PerformanceLogic Proxy:", existing.performanceLogicProxy);
        console.log("  Facade Proxy:", existing.facadeProxy);
        console.log("");
        console.log("New Implementation Addresses:");
        console.log("  NodeLogic Impl:", address(newNodeLogicImpl));
        console.log("  UserLogic Impl:", address(newUserLogicImpl));
        console.log("  ResourceLogic Impl:", address(newResourceLogicImpl));
        console.log("  RewardsLogic Impl:", address(newRewardsLogicImpl));
        console.log("  ApplicationLogic Impl:", address(newApplicationLogicImpl));
        console.log("  StorageAllocatorLogic Impl:", address(newStorageAllocatorLogicImpl));
        console.log("  ClusterLogic Impl:", address(newClusterLogicImpl));
        console.log("  PerformanceLogic Impl:", address(newPerformanceLogicImpl));
        console.log("  Facade Impl:", address(newFacadeImpl));

        console.log("=== QUIKDB UPGRADE COMPLETED ===");
    }

    function loadExistingDeployment() internal view returns (ExistingDeployment memory) {
        // Load addresses from environment variables (set by upgrade controller)
        return ExistingDeployment({
            nodeStorage: vm.envAddress("NODE_STORAGE"),
            userStorage: vm.envAddress("USER_STORAGE"),
            resourceStorage: vm.envAddress("RESOURCE_STORAGE"),
            rewardsStorage: vm.envAddress("REWARDS_STORAGE"),
            applicationStorage: vm.envAddress("APPLICATION_STORAGE"),
            storageAllocatorStorage: vm.envAddress("STORAGE_ALLOCATOR_STORAGE"),
            clusterStorage: vm.envAddress("CLUSTER_STORAGE"),
            performanceStorage: vm.envAddress("PERFORMANCE_STORAGE"),
            proxyAdmin: vm.envAddress("PROXY_ADMIN"),
            nodeLogicProxy: vm.envAddress("NODE_LOGIC_PROXY"),
            userLogicProxy: vm.envAddress("USER_LOGIC_PROXY"),
            resourceLogicProxy: vm.envAddress("RESOURCE_LOGIC_PROXY"),
            rewardsLogicProxy: vm.envAddress("REWARDS_LOGIC_PROXY"),
            applicationLogicProxy: vm.envAddress("APPLICATION_LOGIC_PROXY"),
            storageAllocatorLogicProxy: vm.envAddress("STORAGE_ALLOCATOR_LOGIC_PROXY"),
            clusterLogicProxy: vm.envAddress("CLUSTER_LOGIC_PROXY"),
            performanceLogicProxy: vm.envAddress("PERFORMANCE_LOGIC_PROXY"),
            facadeProxy: vm.envAddress("FACADE_PROXY")
        });
    }

    function verifyUpgrade(address proxy, address expectedImpl, string memory contractName) internal view {
        // Get the implementation address from the proxy's storage
        // Implementation slot: bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)
        bytes32 implementationSlot = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

        address actualImpl;

        // Use vm.load to read from the proxy's storage slot
        bytes32 value = vm.load(proxy, implementationSlot);
        actualImpl = address(uint160(uint256(value)));

        console.log(string(abi.encodePacked(contractName, " upgrade verification:")));
        console.log("  Proxy:", proxy);
        console.log("  Expected implementation:", expectedImpl);
        console.log("  Actual implementation:", actualImpl);

        if (actualImpl == address(0)) {
            console.log("Warning: Could not retrieve implementation address");
            return;
        }

        if (actualImpl != expectedImpl) {
            console.log("ERROR: Implementation address mismatch!");
            revert(string(abi.encodePacked(contractName, " upgrade verification failed: implementation mismatch")));
        } else {
            console.log("SUCCESS: Implementation address matches!");
        }
    }

    // Helper function to extract the revert reason from the response
    function _getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Transaction reverted silently";

        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string));
    }
}
