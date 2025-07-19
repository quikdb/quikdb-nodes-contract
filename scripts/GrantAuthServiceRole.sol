// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../lib/forge-std/src/Script.sol";
import "../src/proxy/UserLogic.sol";

/**
 * @title Grant Auth Service Role
 * @dev Script to grant AUTH_SERVICE_ROLE to a specific address
 */
contract GrantAuthServiceRole is Script {
    function run() external {
        // Load environment variables
        address deployer = vm.envAddress("DEPLOYER_ADDRESS");
        address newAuthService = vm.envAddress("NEW_AUTH_SERVICE_ADDRESS");
        address userLogicProxy = vm.envAddress("USER_LOGIC_PROXY");

        // Start broadcasting with deployer's private key
        vm.startBroadcast();

        // Get the UserLogic contract
        UserLogic userLogic = UserLogic(userLogicProxy);

        // Grant AUTH_SERVICE_ROLE to the new address
        bytes32 AUTH_SERVICE_ROLE = keccak256("AUTH_SERVICE_ROLE");
        userLogic.grantRole(AUTH_SERVICE_ROLE, newAuthService);

        console.log("AUTH_SERVICE_ROLE granted to:", newAuthService);
        console.log("UserLogic contract:", address(userLogic));

        vm.stopBroadcast();
    }
}
