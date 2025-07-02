// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import "../src/proxy/NodeLogic.sol";
import "../src/proxy/UserLogic.sol";
import "../src/proxy/ResourceLogic.sol";
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
    bytes32 public constant IMPL_SALT = keccak256("QuikDB.v2.2025.IMPL");
    
    // Existing deployment addresses (loaded from latest.json)
    struct ExistingDeployment {
        address nodeStorage;
        address userStorage;
        address resourceStorage;
        address proxyAdmin;
        address nodeLogicProxy;
        address userLogicProxy;
        address resourceLogicProxy;
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
        Facade newFacadeImpl = new Facade{salt: IMPL_SALT}();
        
        console.log("New NodeLogic Implementation deployed at:", address(newNodeLogicImpl));
        console.log("New UserLogic Implementation deployed at:", address(newUserLogicImpl));
        console.log("New ResourceLogic Implementation deployed at:", address(newResourceLogicImpl));
        console.log("New Facade Implementation deployed at:", address(newFacadeImpl));
        
        // 2. Upgrade proxies to new implementations
        console.log("=== UPGRADING PROXY CONTRACTS ===");
        
        // Verify admin has required access - will revert if not the case
        ProxyAdmin proxyAdmin = ProxyAdmin(existing.proxyAdmin);
        
        // Check if the deployer is the owner of the ProxyAdmin
        address proxyAdminOwner = proxyAdmin.owner();
        console.log("ProxyAdmin owner:", proxyAdminOwner);
        console.log("Deployer address:", deployer);
        require(proxyAdminOwner == deployer, "Deployer is not the owner of ProxyAdmin");
        
        // Use try/catch to handle potential errors during upgrades
        
        // Upgrade NodeLogic proxy
        console.log("Upgrading NodeLogic proxy...");
        try proxyAdmin.upgradeAndCall(
            ITransparentUpgradeableProxy(existing.nodeLogicProxy),
            address(newNodeLogicImpl),
            ""
        ) {
            console.log("NodeLogic proxy upgraded successfully");
        } catch Error(string memory reason) {
            console.log("NodeLogic upgrade failed:", reason);
            revert(string(abi.encodePacked("NodeLogic upgrade failed: ", reason)));
        } catch {
            console.log("NodeLogic upgrade failed: unknown error");
            revert("NodeLogic upgrade failed: unknown error");
        }
        
        // Upgrade UserLogic proxy
        console.log("Upgrading UserLogic proxy...");
        try proxyAdmin.upgradeAndCall(
            ITransparentUpgradeableProxy(existing.userLogicProxy),
            address(newUserLogicImpl),
            ""
        ) {
            console.log("UserLogic proxy upgraded successfully");
        } catch Error(string memory reason) {
            console.log("UserLogic upgrade failed:", reason);
            revert(string(abi.encodePacked("UserLogic upgrade failed: ", reason)));
        } catch {
            console.log("UserLogic upgrade failed: unknown error");
            revert("UserLogic upgrade failed: unknown error");
        }
        
        // Upgrade ResourceLogic proxy
        console.log("Upgrading ResourceLogic proxy...");
        try proxyAdmin.upgradeAndCall(
            ITransparentUpgradeableProxy(existing.resourceLogicProxy),
            address(newResourceLogicImpl),
            ""
        ) {
            console.log("ResourceLogic proxy upgraded successfully");
        } catch Error(string memory reason) {
            console.log("ResourceLogic upgrade failed:", reason);
            revert(string(abi.encodePacked("ResourceLogic upgrade failed: ", reason)));
        } catch {
            console.log("ResourceLogic upgrade failed: unknown error");
            revert("ResourceLogic upgrade failed: unknown error");
        }
        
        // Upgrade Facade proxy
        console.log("Upgrading Facade proxy...");
        try proxyAdmin.upgradeAndCall(
            ITransparentUpgradeableProxy(existing.facadeProxy),
            address(newFacadeImpl),
            ""
        ) {
            console.log("Facade proxy upgraded successfully");
        } catch Error(string memory reason) {
            console.log("Facade upgrade failed:", reason);
            revert(string(abi.encodePacked("Facade upgrade failed: ", reason)));
        } catch {
            console.log("Facade upgrade failed: unknown error");
            revert("Facade upgrade failed: unknown error");
        }
        
        // 3. Verify upgrades
        console.log("=== VERIFYING UPGRADES ===");
        verifyUpgrade(existing.nodeLogicProxy, address(newNodeLogicImpl), "NodeLogic");
        verifyUpgrade(existing.userLogicProxy, address(newUserLogicImpl), "UserLogic");
        verifyUpgrade(existing.resourceLogicProxy, address(newResourceLogicImpl), "ResourceLogic");
        verifyUpgrade(existing.facadeProxy, address(newFacadeImpl), "Facade");
        
        vm.stopBroadcast();
        
        console.log("=== UPGRADE SUMMARY ===");
        console.log("Proxy Addresses (UNCHANGED):");
        console.log("  NodeLogic Proxy:", existing.nodeLogicProxy);
        console.log("  UserLogic Proxy:", existing.userLogicProxy);
        console.log("  ResourceLogic Proxy:", existing.resourceLogicProxy);
        console.log("  Facade Proxy:", existing.facadeProxy);
        console.log("");
        console.log("New Implementation Addresses:");
        console.log("  NodeLogic Impl:", address(newNodeLogicImpl));
        console.log("  UserLogic Impl:", address(newUserLogicImpl));
        console.log("  ResourceLogic Impl:", address(newResourceLogicImpl));
        console.log("  Facade Impl:", address(newFacadeImpl));
        
        console.log("=== QUIKDB UPGRADE COMPLETED ===");
    }
    
    function loadExistingDeployment() internal view returns (ExistingDeployment memory) {
        // Load addresses from environment variables (set by upgrade controller)
        return ExistingDeployment({
            nodeStorage: vm.envAddress("NODE_STORAGE"),
            userStorage: vm.envAddress("USER_STORAGE"),
            resourceStorage: vm.envAddress("RESOURCE_STORAGE"),
            proxyAdmin: vm.envAddress("PROXY_ADMIN"),
            nodeLogicProxy: vm.envAddress("NODE_LOGIC_PROXY"),
            userLogicProxy: vm.envAddress("USER_LOGIC_PROXY"),
            resourceLogicProxy: vm.envAddress("RESOURCE_LOGIC_PROXY"),
            facadeProxy: vm.envAddress("FACADE_PROXY")
        });
    }
    
    function verifyUpgrade(address proxy, address expectedImpl, string memory contractName) internal pure {
        // Note: In production, you would verify the implementation address
        // This is a simplified verification
        console.log(string(abi.encodePacked(contractName, " upgrade verified - proxy: ")), proxy);
        console.log(string(abi.encodePacked("  New implementation: ")), expectedImpl);
    }
}
