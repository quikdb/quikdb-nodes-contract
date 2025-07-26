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
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Generate unique salt based on timestamp to avoid collisions
        bytes32 salt = keccak256(abi.encodePacked("QuikDB_v1.1", block.timestamp));

        // Deploy UserNodeRegistry implementation
        UserNodeRegistry registryImpl = new UserNodeRegistry{salt: salt}();

        // Deploy proxy for UserNodeRegistry
        bytes memory registryInitData = abi.encodeWithSelector(
            UserNodeRegistry.initialize.selector,
            msg.sender
        );

        ERC1967Proxy registryProxy = new ERC1967Proxy{salt: salt}(
            address(registryImpl),
            registryInitData
        );

        // Deploy QuiksToken implementation
        QuiksToken tokenImpl = new QuiksToken{salt: salt}();

        // Deploy proxy for QuiksToken
        bytes memory tokenInitData = abi.encodeWithSelector(
            QuiksToken.initialize.selector,
            "QuikDB Token",
            "QUIKS",
            1000000000 * 10**18,
            msg.sender
        );

        ERC1967Proxy tokenProxy = new ERC1967Proxy{salt: salt}(
            address(tokenImpl),
            tokenInitData
        );

        vm.stopBroadcast();

        // Output addresses for CLI consumption
        console.log("UserNodeRegistry:", address(registryProxy));
        console.log("UserNodeRegistryImpl:", address(registryImpl));
        console.log("QuiksToken:", address(tokenProxy));
        console.log("QuiksTokenImpl:", address(tokenImpl));
    }
}

