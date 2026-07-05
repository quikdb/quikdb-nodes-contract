// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../src/UserNodeRegistry.sol";
import "../src/tokens/QuiksToken.sol";
import "../src/tokens/MockUSDT.sol";
import "../src/QuiksStaking.sol";

/**
 * @title QuikDBDeployment
 * @notice CREATE2 deterministic deployment of all QuikDB contracts
 * @dev Uses CREATE2 for predictable addresses across networks.
 *
 * Deploys:
 *   - UserNodeRegistry (UUPS proxy)
 *   - QuiksToken (UUPS proxy) — 500M supply, 500M hard cap
 *   - QuiksStaking (UUPS proxy) — 5,000 QUIKS stake, 90-day lock
 *   - MockUSDT (non-upgradeable, testnet only)
 */
contract QuikDBDeployment is Script {
    uint256 constant INITIAL_SUPPLY = 500_000_000 * 10**18; // 500M QUIKS
    uint256 constant MAX_SUPPLY     = 500_000_000 * 10**18; // hard cap — no more minting ever

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        // Unique salt per deploy — prevents CREATE2 collision if re-deploying
        bytes32 salt = keccak256(abi.encodePacked("QuikDB_v3.0", block.timestamp));

        // ── UserNodeRegistry ──────────────────────────────────────────────
        UserNodeRegistry registryImpl = new UserNodeRegistry{salt: salt}();
        bytes memory registryInitData = abi.encodeWithSelector(
            UserNodeRegistry.initialize.selector,
            deployer
        );
        ERC1967Proxy registryProxy = new ERC1967Proxy{salt: salt}(
            address(registryImpl),
            registryInitData
        );

        // ── QuiksToken ────────────────────────────────────────────────────
        // 500M minted to deployer; maxSupply hard cap = 500M (no further minting possible)
        QuiksToken tokenImpl = new QuiksToken{salt: salt}();
        bytes memory tokenInitData = abi.encodeWithSelector(
            QuiksToken.initialize.selector,
            "QuikDB Token",
            "QUIKS",
            INITIAL_SUPPLY,
            MAX_SUPPLY,
            deployer
        );
        ERC1967Proxy tokenProxy = new ERC1967Proxy{salt: salt}(
            address(tokenImpl),
            tokenInitData
        );

        // ── QuiksStaking ──────────────────────────────────────────────────
        // 5,000 QUIKS stake, 90-day lock, owner-triggered slash → burn
        QuiksStaking stakingImpl = new QuiksStaking{salt: salt}();
        bytes memory stakingInitData = abi.encodeWithSelector(
            QuiksStaking.initialize.selector,
            address(tokenProxy),
            deployer
        );
        ERC1967Proxy stakingProxy = new ERC1967Proxy{salt: salt}(
            address(stakingImpl),
            stakingInitData
        );

        // ── MockUSDT (testnet payout simulation only) ─────────────────────
        MockUSDT mockUsdt = new MockUSDT{salt: salt}(deployer);
        mockUsdt.mint(deployer, 1_000_000 * 10**6); // 1M USDT (6 decimals)

        vm.stopBroadcast();

        // ── Console output (parsed by DeploymentController.ts) ────────────
        console.log("UserNodeRegistry:", address(registryProxy));
        console.log("UserNodeRegistryImpl:", address(registryImpl));
        console.log("QuiksToken:", address(tokenProxy));
        console.log("QuiksTokenImpl:", address(tokenImpl));
        console.log("QuiksStaking:", address(stakingProxy));
        console.log("QuiksStakingImpl:", address(stakingImpl));
        console.log("MockUSDT:", address(mockUsdt));

        // ── Write deployment JSON (GitHub Actions picks this up) ──────────
        string memory networkName = vm.envOr("NETWORK_NAME", string("unknown"));
        string memory obj = "deployment";
        vm.serializeAddress(obj, "UserNodeRegistry", address(registryProxy));
        vm.serializeAddress(obj, "UserNodeRegistryImpl", address(registryImpl));
        vm.serializeAddress(obj, "QuiksToken", address(tokenProxy));
        vm.serializeAddress(obj, "QuiksTokenImpl", address(tokenImpl));
        vm.serializeAddress(obj, "QuiksStaking", address(stakingProxy));
        vm.serializeAddress(obj, "QuiksStakingImpl", address(stakingImpl));
        vm.serializeAddress(obj, "USDTToken", address(mockUsdt));
        vm.serializeAddress(obj, "deployer", deployer);
        vm.serializeString(obj, "network", networkName);
        string memory finalJson = vm.serializeString(obj, "version", "3.0.0");

        string memory outPath = string(abi.encodePacked("./deployments/", networkName, ".json"));
        vm.writeJson(finalJson, outPath);
        console.log("Deployment JSON written to:", outPath);
    }
}
