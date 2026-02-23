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

    function testRegisterNodeHobby() public {
        vm.prank(owner);
        registry.registerNode(operator, bytes32("meta"), UserNodeRegistry.NodeTier.HOBBY, UserNodeRegistry.ProviderType.COMPUTE);
        (address op,, UserNodeRegistry.NodeTier tier, UserNodeRegistry.ProviderType ptype,, , , , , , , ,) = registry.nodes(operator);
        assertEq(op, operator);
        assertEq(uint256(tier), uint256(UserNodeRegistry.NodeTier.HOBBY));
        assertEq(uint256(ptype), uint256(UserNodeRegistry.ProviderType.COMPUTE));
    }

    function testRegisterNodeBuilder() public {
        vm.prank(owner);
        registry.registerNode(operator, bytes32("meta"), UserNodeRegistry.NodeTier.BUILDER, UserNodeRegistry.ProviderType.COMPUTE);
        (,, UserNodeRegistry.NodeTier tier,,,,,,,,,,) = registry.nodes(operator);
        assertEq(uint256(tier), uint256(UserNodeRegistry.NodeTier.BUILDER));
    }

    function testRegisterNodeStartup() public {
        vm.prank(owner);
        registry.registerNode(operator, bytes32("meta"), UserNodeRegistry.NodeTier.STARTUP, UserNodeRegistry.ProviderType.HYBRID);
        (,, UserNodeRegistry.NodeTier tier,,,,,,,,,,) = registry.nodes(operator);
        assertEq(uint256(tier), uint256(UserNodeRegistry.NodeTier.STARTUP));
    }

    function testRegisterNodeTeam() public {
        vm.prank(owner);
        registry.registerNode(operator, bytes32("meta"), UserNodeRegistry.NodeTier.TEAM, UserNodeRegistry.ProviderType.STORAGE);
        (,, UserNodeRegistry.NodeTier tier,,,,,,,,,,) = registry.nodes(operator);
        assertEq(uint256(tier), uint256(UserNodeRegistry.NodeTier.TEAM));
    }

    function testAllNodeTierValues() public pure {
        // Verify enum ordering: HOBBY=0, BUILDER=1, STARTUP=2, TEAM=3
        assertEq(uint256(UserNodeRegistry.NodeTier.HOBBY), 0);
        assertEq(uint256(UserNodeRegistry.NodeTier.BUILDER), 1);
        assertEq(uint256(UserNodeRegistry.NodeTier.STARTUP), 2);
        assertEq(uint256(UserNodeRegistry.NodeTier.TEAM), 3);
    }

    function testPauseUnpause() public {
        vm.prank(owner);
        registry.pause();
        assertTrue(registry.paused());
        vm.prank(owner);
        registry.unpause();
        assertFalse(registry.paused());
    }

    function testVersionIsV2() public view {
        assertEq(
            keccak256(abi.encodePacked(registry.version())),
            keccak256(abi.encodePacked("2.0.0"))
        );
    }

    function testGetNodesByTier() public {
        address op1 = address(0x3001);
        address op2 = address(0x3002);
        address op3 = address(0x3003);

        vm.startPrank(owner);
        registry.registerNode(op1, bytes32("m1"), UserNodeRegistry.NodeTier.HOBBY, UserNodeRegistry.ProviderType.COMPUTE);
        registry.registerNode(op2, bytes32("m2"), UserNodeRegistry.NodeTier.HOBBY, UserNodeRegistry.ProviderType.COMPUTE);
        registry.registerNode(op3, bytes32("m3"), UserNodeRegistry.NodeTier.BUILDER, UserNodeRegistry.ProviderType.COMPUTE);
        vm.stopPrank();

        address[] memory hobbyNodes = registry.getNodesByTier(UserNodeRegistry.NodeTier.HOBBY);
        assertEq(hobbyNodes.length, 2);

        address[] memory builderNodes = registry.getNodesByTier(UserNodeRegistry.NodeTier.BUILDER);
        assertEq(builderNodes.length, 1);
    }
}
