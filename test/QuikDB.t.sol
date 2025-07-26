// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../src/tokens/QuiksToken.sol";
import "../src/UserNodeRegistry.sol";

contract QuikDBTest is Test {
    QuiksToken token;
    UserNodeRegistry registry;

    address owner = address(0xABCD);
    address user = address(0x1000);
    address operator = address(0x2000);

    function setUp() public {
        // Deploy QuiksToken implementation
        QuiksToken tokenImpl = new QuiksToken();
        
        // Deploy proxy for QuiksToken
        bytes memory tokenInitData = abi.encodeWithSelector(
            QuiksToken.initialize.selector,
            "QuikDB Token",
            "QUIKS",
            1000000 ether,
            owner
        );
        ERC1967Proxy tokenProxy = new ERC1967Proxy(address(tokenImpl), tokenInitData);
        token = QuiksToken(address(tokenProxy));

        // Deploy UserNodeRegistry implementation
        UserNodeRegistry registryImpl = new UserNodeRegistry();
        
        // Deploy proxy for UserNodeRegistry
        bytes memory registryInitData = abi.encodeWithSelector(
            UserNodeRegistry.initialize.selector,
            owner
        );
        ERC1967Proxy registryProxy = new ERC1967Proxy(address(registryImpl), registryInitData);
        registry = UserNodeRegistry(address(registryProxy));
    }

    function testOwnerSet() public view {
        assertEq(token.owner(), owner);
        assertEq(registry.owner(), owner);
    }

    function testMintByOwner() public {
        vm.prank(owner);
        token.mint(user, 123 ether);
        assertEq(token.balanceOf(user), 123 ether);
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
