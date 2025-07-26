// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/tokens/QuiksToken.sol";
import "../src/UserNodeRegistry.sol";

contract QuikDBTest is Test {
    QuiksToken token;
    UserNodeRegistry registry;

    address owner = address(0xABCD);
    address user = address(0x1000);
    address operator = address(0x2000);

    function setUp() public {
        token = new QuiksToken();
        token.initialize("QuikDB Token", "QUIKS", 0, owner);

        registry = new UserNodeRegistry();
        registry.initialize(owner);
    }

    function testOwnerSet() public {
        assertEq(token.owner(), owner);
        assertEq(registry.owner(), owner);
    }

    function testMintByOwner() public {
        vm.prank(owner);
        token.mint(user, 123);
        assertEq(token.balanceOf(user), 123);
    }

    function testRegisterUser() public {
        vm.prank(user);
        registry.registerUser(user, bytes32("profile"), UserNodeRegistry.UserType.CONSUMER);
        (address addr,, UserNodeRegistry.UserType utype,, , , ,) = registry.users(user);
        assertEq(addr, user);
        assertEq(uint256(utype), uint256(UserNodeRegistry.UserType.CONSUMER));
    }

    function testRegisterNode() public {
        vm.prank(owner);
        registry.registerNode(operator, bytes32("meta"), UserNodeRegistry.NodeTier.BASIC, UserNodeRegistry.ProviderType.STORAGE);
        (address op,, UserNodeRegistry.NodeTier tier, UserNodeRegistry.ProviderType ptype,, , , , , , , ,) = registry.nodes(operator);
        assertEq(op, operator);
        assertEq(uint256(tier), uint256(UserNodeRegistry.NodeTier.BASIC));
        assertEq(uint256(ptype), uint256(UserNodeRegistry.ProviderType.STORAGE));
    }

    function testPauseUnpause() public {
        vm.prank(owner);
        registry.pause();
        assertTrue(registry.paused());
        vm.prank(owner);
        registry.unpause();
        assertFalse(registry.paused());
    }
}
