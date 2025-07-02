// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../base/BaseDeployment.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "../../src/proxy/QuikNodeLogic.sol";
import "../../src/proxy/QuikUserLogic.sol";
import "../../src/proxy/QuikResourceLogic.sol";
import "../../src/proxy/QuikFacade.sol";

/**
 * @title ProxyDeployment
 * @notice Deploys proxy infrastructure and proxy contracts for the QuikDB system
 * @dev Stage 3 of the deployment process - creates proxies that delegate to logic implementations
 */
contract ProxyDeployment is BaseDeployment {
    
    // =============================================================
    //                      PROXY ADMIN
    // =============================================================
    
    /**
     * @notice Deploy the ProxyAdmin contract
     * @param deployerAddress Address that will own the ProxyAdmin
     */
    function deployProxyAdmin(address deployerAddress) external {
        console.log("=== DEPLOYING PROXY ADMIN ===");
        
        // Initialize deployment configuration if not already done
        if (address(create2Deployer) == address(0)) {
            initializeDeployment();
        }
        
        bytes32 salt = keccak256(abi.encodePacked("QuikDB.ProxyAdmin"));
        bytes memory bytecode = abi.encodePacked(
            type(ProxyAdmin).creationCode,
            abi.encode(deployerAddress)
        );
        
        address predictedAddress = predictCreate2Address(salt, bytecode);
        console.log("Predicted ProxyAdmin address:", predictedAddress);
        
        ProxyAdmin proxyAdmin = ProxyAdmin(deployWithCreate2(salt, bytecode));
        proxyAdminAddress = address(proxyAdmin);
        logDeployment("ProxyAdmin", proxyAdminAddress);
        
        logStageCompletion("PROXY ADMIN DEPLOYMENT");
    }
    
    // =============================================================
    //                      PROXY CONTRACTS
    // =============================================================
    
    /**
     * @notice Deploy NodeLogic proxy with initialization
     * @param deployerAddress Address for initialization
     * @param _nodeStorageAddress Address of NodeStorage contract
     * @param _userStorageAddress Address of UserStorage contract
     * @param _resourceStorageAddress Address of ResourceStorage contract
     * @param _nodeLogicImplAddress Address of NodeLogic implementation
     * @param _proxyAdminAddress Address of ProxyAdmin
     */
    function deployNodeProxy(
        address deployerAddress,
        address _nodeStorageAddress,
        address _userStorageAddress,
        address _resourceStorageAddress,
        address _nodeLogicImplAddress,
        address _proxyAdminAddress
    ) external {
        console.log("=== DEPLOYING NODE LOGIC PROXY ===");
        
        // Initialize deployment configuration if not already done
        if (address(create2Deployer) == address(0)) {
            initializeDeployment();
        }
        
        // Validate required addresses
        address[] memory addresses = new address[](5);
        addresses[0] = _nodeStorageAddress;
        addresses[1] = _userStorageAddress;
        addresses[2] = _resourceStorageAddress;
        addresses[3] = _nodeLogicImplAddress;
        addresses[4] = _proxyAdminAddress;
        
        string[] memory names = new string[](5);
        names[0] = "NodeStorage";
        names[1] = "UserStorage";
        names[2] = "ResourceStorage";
        names[3] = "NodeLogic Implementation";
        names[4] = "ProxyAdmin";
        
        validateAddresses(addresses, names);
        
        // Prepare initialization data
        bytes memory initData = abi.encodeWithSelector(
            QuikNodeLogic.initialize.selector,
            _nodeStorageAddress,
            _userStorageAddress,
            _resourceStorageAddress,
            deployerAddress
        );
        
        // Deploy proxy using CREATE2
        bytes32 salt = keccak256(abi.encodePacked("QuikDB.NodeLogic.Proxy"));
        bytes memory bytecode = abi.encodePacked(
            type(TransparentUpgradeableProxy).creationCode,
            abi.encode(_nodeLogicImplAddress, _proxyAdminAddress, initData)
        );
        
        address predictedAddress = predictCreate2Address(salt, bytecode);
        console.log("Predicted NodeLogic Proxy address:", predictedAddress);
        
        TransparentUpgradeableProxy nodeLogicProxy = TransparentUpgradeableProxy(
            payable(deployWithCreate2(salt, bytecode))
        );
        
        nodeLogicProxyAddress = address(nodeLogicProxy);
        logDeployment("QuikNodeLogic Proxy", nodeLogicProxyAddress);
        
        logStageCompletion("NODE LOGIC PROXY DEPLOYMENT");
    }
    
    /**
     * @notice Deploy UserLogic proxy with initialization
     * @param deployerAddress Address for initialization
     * @param _nodeStorageAddress Address of NodeStorage contract
     * @param _userStorageAddress Address of UserStorage contract
     * @param _resourceStorageAddress Address of ResourceStorage contract
     * @param _userLogicImplAddress Address of UserLogic implementation
     * @param _proxyAdminAddress Address of ProxyAdmin
     */
    function deployUserProxy(
        address deployerAddress,
        address _nodeStorageAddress,
        address _userStorageAddress,
        address _resourceStorageAddress,
        address _userLogicImplAddress,
        address _proxyAdminAddress
    ) external {
        console.log("=== DEPLOYING USER LOGIC PROXY ===");
        
        // Validate required addresses
        address[] memory addresses = new address[](5);
        addresses[0] = _nodeStorageAddress;
        addresses[1] = _userStorageAddress;
        addresses[2] = _resourceStorageAddress;
        addresses[3] = _userLogicImplAddress;
        addresses[4] = _proxyAdminAddress;
        
        string[] memory names = new string[](5);
        names[0] = "NodeStorage";
        names[1] = "UserStorage";
        names[2] = "ResourceStorage";
        names[3] = "UserLogic Implementation";
        names[4] = "ProxyAdmin";
        
        validateAddresses(addresses, names);
        
        // Prepare initialization data
        bytes memory initData = abi.encodeWithSelector(
            QuikUserLogic.initialize.selector,
            _nodeStorageAddress,
            _userStorageAddress,
            _resourceStorageAddress,
            deployerAddress
        );
        
        // Deploy proxy using CREATE2
        bytes32 salt = keccak256(abi.encodePacked("QuikDB.UserLogic.Proxy"));
        bytes memory bytecode = abi.encodePacked(
            type(TransparentUpgradeableProxy).creationCode,
            abi.encode(_userLogicImplAddress, _proxyAdminAddress, initData)
        );
        
        address predictedAddress = predictCreate2Address(salt, bytecode);
        console.log("Predicted UserLogic Proxy address:", predictedAddress);
        
        TransparentUpgradeableProxy userLogicProxy = TransparentUpgradeableProxy(
            payable(deployWithCreate2(salt, bytecode))
        );
        
        userLogicProxyAddress = address(userLogicProxy);
        logDeployment("QuikUserLogic Proxy", userLogicProxyAddress);
        
        logStageCompletion("USER LOGIC PROXY DEPLOYMENT");
    }
    
    /**
     * @notice Deploy ResourceLogic proxy with initialization
     * @param deployerAddress Address for initialization
     * @param _nodeStorageAddress Address of NodeStorage contract
     * @param _userStorageAddress Address of UserStorage contract
     * @param _resourceStorageAddress Address of ResourceStorage contract
     * @param _resourceLogicImplAddress Address of ResourceLogic implementation
     * @param _proxyAdminAddress Address of ProxyAdmin
     */
    function deployResourceProxy(
        address deployerAddress,
        address _nodeStorageAddress,
        address _userStorageAddress,
        address _resourceStorageAddress,
        address _resourceLogicImplAddress,
        address _proxyAdminAddress
    ) external {
        console.log("=== DEPLOYING RESOURCE LOGIC PROXY ===");
        
        // Validate required addresses
        address[] memory addresses = new address[](5);
        addresses[0] = _nodeStorageAddress;
        addresses[1] = _userStorageAddress;
        addresses[2] = _resourceStorageAddress;
        addresses[3] = _resourceLogicImplAddress;
        addresses[4] = _proxyAdminAddress;
        
        string[] memory names = new string[](5);
        names[0] = "NodeStorage";
        names[1] = "UserStorage";
        names[2] = "ResourceStorage";
        names[3] = "ResourceLogic Implementation";
        names[4] = "ProxyAdmin";
        
        validateAddresses(addresses, names);
        
        // Prepare initialization data
        bytes memory initData = abi.encodeWithSelector(
            QuikResourceLogic.initialize.selector,
            _nodeStorageAddress,
            _userStorageAddress,
            _resourceStorageAddress,
            deployerAddress
        );
        
        // Deploy proxy using CREATE2
        bytes32 salt = keccak256(abi.encodePacked("QuikDB.ResourceLogic.Proxy"));
        bytes memory bytecode = abi.encodePacked(
            type(TransparentUpgradeableProxy).creationCode,
            abi.encode(_resourceLogicImplAddress, _proxyAdminAddress, initData)
        );
        
        address predictedAddress = predictCreate2Address(salt, bytecode);
        console.log("Predicted ResourceLogic Proxy address:", predictedAddress);
        
        TransparentUpgradeableProxy resourceLogicProxy = TransparentUpgradeableProxy(
            payable(deployWithCreate2(salt, bytecode))
        );
        
        resourceLogicProxyAddress = address(resourceLogicProxy);
        logDeployment("QuikResourceLogic Proxy", resourceLogicProxyAddress);
        
        logStageCompletion("RESOURCE LOGIC PROXY DEPLOYMENT");
    }
    
    /**
     * @notice Deploy Facade proxy with initialization
     * @param deployerAddress Address for initialization
     * @param _nodeLogicProxyAddress Address of NodeLogic proxy
     * @param _userLogicProxyAddress Address of UserLogic proxy
     * @param _resourceLogicProxyAddress Address of ResourceLogic proxy
     * @param _facadeImplAddress Address of Facade implementation
     * @param _proxyAdminAddress Address of ProxyAdmin
     */
    function deployFacadeProxy(
        address deployerAddress,
        address _nodeLogicProxyAddress,
        address _userLogicProxyAddress,
        address _resourceLogicProxyAddress,
        address _facadeImplAddress,
        address _proxyAdminAddress
    ) external {
        console.log("=== DEPLOYING FACADE PROXY ===");
        
        // Validate required addresses
        address[] memory addresses = new address[](5);
        addresses[0] = _nodeLogicProxyAddress;
        addresses[1] = _userLogicProxyAddress;
        addresses[2] = _resourceLogicProxyAddress;
        addresses[3] = _facadeImplAddress;
        addresses[4] = _proxyAdminAddress;
        
        string[] memory names = new string[](5);
        names[0] = "NodeLogic Proxy";
        names[1] = "UserLogic Proxy";
        names[2] = "ResourceLogic Proxy";
        names[3] = "Facade Implementation";
        names[4] = "ProxyAdmin";
        
        validateAddresses(addresses, names);
        
        // Prepare initialization data
        bytes memory initData = abi.encodeWithSelector(
            QuikFacade.initialize.selector,
            _nodeLogicProxyAddress,
            _userLogicProxyAddress,
            _resourceLogicProxyAddress,
            deployerAddress
        );
        
        // Deploy proxy using CREATE2
        bytes32 salt = keccak256(abi.encodePacked("QuikDB.Facade.Proxy"));
        bytes memory bytecode = abi.encodePacked(
            type(TransparentUpgradeableProxy).creationCode,
            abi.encode(_facadeImplAddress, _proxyAdminAddress, initData)
        );
        
        address predictedAddress = predictCreate2Address(salt, bytecode);
        console.log("Predicted Facade Proxy address:", predictedAddress);
        
        TransparentUpgradeableProxy facadeProxy = TransparentUpgradeableProxy(
            payable(deployWithCreate2(salt, bytecode))
        );
        
        facadeProxyAddress = address(facadeProxy);
        logDeployment("QuikFacade Proxy", facadeProxyAddress);
        
        logStageCompletion("FACADE PROXY DEPLOYMENT");
    }
    
    // =============================================================
    //                        GETTERS
    // =============================================================
    
    /**
     * @notice Get all deployed proxy addresses
     * @return proxyAdmin Address of ProxyAdmin
     * @return nodeProxy Address of NodeLogic proxy
     * @return userProxy Address of UserLogic proxy
     * @return resourceProxy Address of ResourceLogic proxy
     * @return facadeProxy Address of Facade proxy
     */
    function getProxyAddresses() 
        external 
        view 
        returns (
            address proxyAdmin,
            address nodeProxy,
            address userProxy,
            address resourceProxy,
            address facadeProxy
        ) 
    {
        return (
            proxyAdminAddress,
            nodeLogicProxyAddress,
            userLogicProxyAddress,
            resourceLogicProxyAddress,
            facadeProxyAddress
        );
    }
    
    // =============================================================
    //                    ADDRESS PREDICTION
    // =============================================================
    
    /**
     * @notice Predict proxy addresses using CREATE2
     * @param deployerAddress Address for initialization
     * @param nodeLogicImplAddress Address of NodeLogic implementation
     * @param userLogicImplAddress Address of UserLogic implementation 
     * @param resourceLogicImplAddress Address of ResourceLogic implementation
     * @param facadeImplAddress Address of Facade implementation
     * @param proxyAdminAddress Address of ProxyAdmin
     * @param nodeStorageAddress Address of NodeStorage contract
     * @param userStorageAddress Address of UserStorage contract
     * @param resourceStorageAddress Address of ResourceStorage contract
     * @return proxyAdmin Predicted ProxyAdmin address
     * @return nodeProxy Predicted NodeLogic proxy address
     * @return userProxy Predicted UserLogic proxy address
     * @return resourceProxy Predicted ResourceLogic proxy address
     * @return facadeProxy Predicted Facade proxy address
     */
    function predictProxyAddresses(
        address deployerAddress,
        address nodeLogicImplAddress,
        address userLogicImplAddress,
        address resourceLogicImplAddress,
        address facadeImplAddress,
        address proxyAdminAddress,
        address nodeStorageAddress,
        address userStorageAddress,
        address resourceStorageAddress
    ) external view returns (
        address proxyAdmin,
        address nodeProxy,
        address userProxy,
        address resourceProxy,
        address facadeProxy
    ) {
        // Predict ProxyAdmin address
        bytes32 proxyAdminSalt = keccak256(abi.encodePacked("QuikDB.ProxyAdmin"));
        bytes memory proxyAdminBytecode = abi.encodePacked(
            type(ProxyAdmin).creationCode,
            abi.encode(deployerAddress)
        );
        proxyAdmin = predictCreate2Address(proxyAdminSalt, proxyAdminBytecode);
        
        // Predict NodeLogic Proxy address
        bytes memory nodeInitData = abi.encodeWithSelector(
            QuikNodeLogic.initialize.selector,
            nodeStorageAddress,
            userStorageAddress,
            resourceStorageAddress,
            deployerAddress
        );
        bytes32 nodeSalt = keccak256(abi.encodePacked("QuikDB.NodeLogic.Proxy"));
        bytes memory nodeBytecode = abi.encodePacked(
            type(TransparentUpgradeableProxy).creationCode,
            abi.encode(nodeLogicImplAddress, proxyAdminAddress, nodeInitData)
        );
        nodeProxy = predictCreate2Address(nodeSalt, nodeBytecode);
        
        // Predict UserLogic Proxy address
        bytes memory userInitData = abi.encodeWithSelector(
            QuikUserLogic.initialize.selector,
            nodeStorageAddress,
            userStorageAddress,
            resourceStorageAddress,
            deployerAddress
        );
        bytes32 userSalt = keccak256(abi.encodePacked("QuikDB.UserLogic.Proxy"));
        bytes memory userBytecode = abi.encodePacked(
            type(TransparentUpgradeableProxy).creationCode,
            abi.encode(userLogicImplAddress, proxyAdminAddress, userInitData)
        );
        userProxy = predictCreate2Address(userSalt, userBytecode);
        
        // Predict ResourceLogic Proxy address
        bytes memory resourceInitData = abi.encodeWithSelector(
            QuikResourceLogic.initialize.selector,
            nodeStorageAddress,
            userStorageAddress,
            resourceStorageAddress,
            deployerAddress
        );
        bytes32 resourceSalt = keccak256(abi.encodePacked("QuikDB.ResourceLogic.Proxy"));
        bytes memory resourceBytecode = abi.encodePacked(
            type(TransparentUpgradeableProxy).creationCode,
            abi.encode(resourceLogicImplAddress, proxyAdminAddress, resourceInitData)
        );
        resourceProxy = predictCreate2Address(resourceSalt, resourceBytecode);
        
        // Predict Facade Proxy address
        bytes memory facadeInitData = abi.encodeWithSelector(
            QuikFacade.initialize.selector,
            nodeProxy,
            userProxy,
            resourceProxy,
            deployerAddress
        );
        bytes32 facadeSalt = keccak256(abi.encodePacked("QuikDB.Facade.Proxy"));
        bytes memory facadeBytecode = abi.encodePacked(
            type(TransparentUpgradeableProxy).creationCode,
            abi.encode(facadeImplAddress, proxyAdminAddress, facadeInitData)
        );
        facadeProxy = predictCreate2Address(facadeSalt, facadeBytecode);
    }
}
