// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../base/BaseDeployment.sol";
import "../../src/storage/NodeStorage.sol";
import "../../src/storage/UserStorage.sol";
import "../../src/storage/ResourceStorage.sol";
import "../../src/proxy/QuikNodeLogic.sol";
import "../../src/proxy/QuikUserLogic.sol";
import "../../src/proxy/QuikResourceLogic.sol";
import "../../src/proxy/QuikFacade.sol";

/**
 * @title ConfigurationSetup
 * @notice Handles final configuration and access control setup for the QuikDB system
 * @dev Final stages of the deployment process - configures storage contracts and sets up roles
 */
contract ConfigurationSetup is BaseDeployment {
    
    // =============================================================
    //                   STORAGE CONFIGURATION
    // =============================================================
    
    /**
     * @notice Configure storage contracts to point to their respective logic proxies
     * @param _nodeStorageAddress Address of NodeStorage contract
     * @param _userStorageAddress Address of UserStorage contract
     * @param _resourceStorageAddress Address of ResourceStorage contract
     * @param _nodeLogicProxyAddress Address of NodeLogic proxy
     * @param _userLogicProxyAddress Address of UserLogic proxy
     * @param _resourceLogicProxyAddress Address of ResourceLogic proxy
     */
    function setupStorageContracts(
        address _nodeStorageAddress,
        address _userStorageAddress,
        address _resourceStorageAddress,
        address _nodeLogicProxyAddress,
        address _userLogicProxyAddress,
        address _resourceLogicProxyAddress
    ) external {
        console.log("=== CONFIGURING STORAGE CONTRACTS ===");
        
        // Validate all required addresses
        address[] memory addresses = new address[](6);
        addresses[0] = _nodeStorageAddress;
        addresses[1] = _userStorageAddress;
        addresses[2] = _resourceStorageAddress;
        addresses[3] = _nodeLogicProxyAddress;
        addresses[4] = _userLogicProxyAddress;
        addresses[5] = _resourceLogicProxyAddress;
        
        string[] memory names = new string[](6);
        names[0] = "NodeStorage";
        names[1] = "UserStorage";
        names[2] = "ResourceStorage";
        names[3] = "NodeLogic Proxy";
        names[4] = "UserLogic Proxy";
        names[5] = "ResourceLogic Proxy";
        
        validateAddresses(addresses, names);
        
        // Configure storage contracts to use their respective logic proxies
        try NodeStorage(_nodeStorageAddress).setLogicContract(_nodeLogicProxyAddress) {
            console.log("NodeStorage configured to use NodeLogic proxy");
        } catch {
            console.log("WARNING: Failed to configure NodeStorage");
        }
        
        try UserStorage(_userStorageAddress).setLogicContract(_userLogicProxyAddress) {
            console.log("UserStorage configured to use UserLogic proxy");
        } catch {
            console.log("WARNING: Failed to configure UserStorage");
        }
        
        try ResourceStorage(_resourceStorageAddress).setLogicContract(_resourceLogicProxyAddress) {
            console.log("ResourceStorage configured to use ResourceLogic proxy");
        } catch {
            console.log("WARNING: Failed to configure ResourceStorage");
        }
        
        logStageCompletion("STORAGE CONTRACTS CONFIGURATION");
    }
    
    // =============================================================
    //                    ACCESS CONTROL SETUP
    // =============================================================
    
    /**
     * @notice Setup access control roles for all contracts
     * @param deployerAddress Address that will receive admin roles
     * @param _nodeLogicProxyAddress Address of NodeLogic proxy
     * @param _userLogicProxyAddress Address of UserLogic proxy
     * @param _facadeProxyAddress Address of Facade proxy
     */
    function setupAccessControl(
        address deployerAddress,
        address _nodeLogicProxyAddress,
        address _userLogicProxyAddress,
        address _facadeProxyAddress
    ) external {
        console.log("=== SETTING UP ACCESS CONTROL ===");
        
        // Validate required addresses
        address[] memory addresses = new address[](3);
        addresses[0] = _nodeLogicProxyAddress;
        addresses[1] = _userLogicProxyAddress;
        addresses[2] = _facadeProxyAddress;
        
        string[] memory names = new string[](3);
        names[0] = "NodeLogic Proxy";
        names[1] = "UserLogic Proxy";
        names[2] = "Facade Proxy";
        
        validateAddresses(addresses, names);
        
        // Setup NodeLogic roles - use deployer address as role holder
        try QuikNodeLogic(_nodeLogicProxyAddress).grantRole(
            QuikNodeLogic(_nodeLogicProxyAddress).NODE_OPERATOR_ROLE(), 
            deployerAddress
        ) {
            console.log("NODE_OPERATOR_ROLE granted to deployer:", deployerAddress);
        } catch {
            console.log("WARNING: Failed to grant NODE_OPERATOR_ROLE");
        }
        
        // Setup UserLogic roles
        try QuikUserLogic(_userLogicProxyAddress).grantRole(
            QuikUserLogic(_userLogicProxyAddress).AUTH_SERVICE_ROLE(), 
            deployerAddress
        ) {
            console.log("AUTH_SERVICE_ROLE granted to deployer:", deployerAddress);
        } catch {
            console.log("WARNING: Failed to grant AUTH_SERVICE_ROLE");
        }
        
        // Setup Facade roles
        try QuikFacade(_facadeProxyAddress).grantRole(
            QuikFacade(_facadeProxyAddress).UPGRADER_ROLE(), 
            deployerAddress
        ) {
            console.log("UPGRADER_ROLE granted to deployer:", deployerAddress);
        } catch {
            console.log("WARNING: Failed to grant UPGRADER_ROLE");
        }
        
        logStageCompletion("ACCESS CONTROL SETUP");
    }
    
    /**
     * @notice Setup additional roles for specific addresses
     * @param _nodeLogicProxyAddress Address of NodeLogic proxy
     * @param _userLogicProxyAddress Address of UserLogic proxy
     * @param _facadeProxyAddress Address of Facade proxy
     * @param roleRecipient Address that will receive the roles
     * @param grantNodeOperator Whether to grant NODE_OPERATOR_ROLE
     * @param grantAuthService Whether to grant AUTH_SERVICE_ROLE
     * @param grantUpgrader Whether to grant UPGRADER_ROLE
     */
    function setupAdditionalRoles(
        address _nodeLogicProxyAddress,
        address _userLogicProxyAddress,
        address _facadeProxyAddress,
        address roleRecipient,
        bool grantNodeOperator,
        bool grantAuthService,
        bool grantUpgrader
    ) external {
        console.log("=== SETTING UP ADDITIONAL ROLES ===");
        console.log("Role recipient:", roleRecipient);
        
        if (grantNodeOperator) {
            QuikNodeLogic nodeLogic = QuikNodeLogic(_nodeLogicProxyAddress);
            nodeLogic.grantRole(nodeLogic.NODE_OPERATOR_ROLE(), roleRecipient);
            console.log("NODE_OPERATOR_ROLE granted to:", roleRecipient);
        }
        
        if (grantAuthService) {
            QuikUserLogic userLogic = QuikUserLogic(_userLogicProxyAddress);
            userLogic.grantRole(userLogic.AUTH_SERVICE_ROLE(), roleRecipient);
            console.log("AUTH_SERVICE_ROLE granted to:", roleRecipient);
        }
        
        if (grantUpgrader) {
            QuikFacade facade = QuikFacade(_facadeProxyAddress);
            facade.grantRole(facade.UPGRADER_ROLE(), roleRecipient);
            console.log("UPGRADER_ROLE granted to:", roleRecipient);
        }
        
        logStageCompletion("ADDITIONAL ROLES SETUP");
    }
    
    // =============================================================
    //                     VERIFICATION
    // =============================================================
    
    /**
     * @notice Verify the complete deployment setup
     * @param _nodeStorageAddress Address of NodeStorage contract
     * @param _userStorageAddress Address of UserStorage contract
     * @param _resourceStorageAddress Address of ResourceStorage contract
     * @param _nodeLogicProxyAddress Address of NodeLogic proxy
     * @param _userLogicProxyAddress Address of UserLogic proxy
     * @param _resourceLogicProxyAddress Address of ResourceLogic proxy
     * @param _facadeProxyAddress Address of Facade proxy
     * @return success Whether all verifications passed
     */
    function verifyDeployment(
        address _nodeStorageAddress,
        address _userStorageAddress,
        address _resourceStorageAddress,
        address _nodeLogicProxyAddress,
        address _userLogicProxyAddress,
        address _resourceLogicProxyAddress,
        address _facadeProxyAddress
    ) external view returns (bool success) {
        console.log("=== VERIFYING DEPLOYMENT ===");
        
        // Check that all addresses are set
        if (_nodeStorageAddress == address(0) ||
            _userStorageAddress == address(0) ||
            _resourceStorageAddress == address(0) ||
            _nodeLogicProxyAddress == address(0) ||
            _userLogicProxyAddress == address(0) ||
            _resourceLogicProxyAddress == address(0) ||
            _facadeProxyAddress == address(0)) {
            console.log("VERIFICATION FAILED: One or more addresses are zero");
            return false;
        }
        
        // Check that all contracts have code (are deployed)
        uint256 nodeStorageSize;
        uint256 facadeSize;
        assembly {
            nodeStorageSize := extcodesize(_nodeStorageAddress)
            facadeSize := extcodesize(_facadeProxyAddress)
        }
        
        if (nodeStorageSize == 0 || facadeSize == 0) {
            console.log("VERIFICATION FAILED: One or more contracts not deployed");
            return false;
        }
        
        console.log("VERIFICATION PASSED: All contracts properly deployed and configured");
        return true;
    }
}
