// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../src/UserNodeRegistry.sol";
import "../src/tokens/QuiksToken.sol";

/**
 * @title QuikDBDeployment
 * @notice CREATE2 deterministic deployment of all QuikDB contracts
 * @dev Uses CREATE2 for predictable addresses across networks
 */
contract QuikDBDeployment is Script {
    bytes32 public constant SALT = keccak256("QuikDB_v1.0");
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy UserNodeRegistry
        UserNodeRegistry nodeRegistry = new UserNodeRegistry{salt: SALT}(msg.sender);
        
        // Deploy QuiksToken implementation
        QuiksToken tokenImpl = new QuiksToken{salt: SALT}();
        
        // Deploy proxy for QuiksToken
        bytes memory initData = abi.encodeWithSelector(
            QuiksToken.initialize.selector,
            "QuikDB Token",
            "QUIKS",
            1000000000 * 10**18, // 1 billion tokens
            msg.sender // deployer becomes owner
        );
        
        ERC1967Proxy tokenProxy = new ERC1967Proxy{salt: SALT}(
            address(tokenImpl),
            initData
        );
        
        vm.stopBroadcast();
        
        // Output addresses for CLI consumption
        console.log("UserNodeRegistry:", address(nodeRegistry));
        console.log("QuiksToken:", address(tokenProxy));
        console.log("QuiksTokenImpl:", address(tokenImpl));
    }
}
