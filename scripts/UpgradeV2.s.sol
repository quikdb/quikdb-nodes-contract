// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../src/UserNodeRegistry.sol";
import "../src/ReferralSystem.sol";

/**
 * @title UpgradeV2
 * @notice Upgrades UserNodeRegistry and ReferralSystem to V2 implementations
 * @dev Run with:
 *   forge script scripts/UpgradeV2.s.sol:UpgradeV2 --rpc-url <RPC_URL> --broadcast
 *
 * Environment Variables:
 *   PRIVATE_KEY                    - Deployer/owner private key
 *   USER_NODE_REGISTRY_PROXY       - Proxy address of UserNodeRegistry
 *   REFERRAL_SYSTEM_PROXY          - Proxy address of ReferralSystem
 *   USDT_TOKEN_ADDRESS             - Address of USDT token on the target chain
 *
 * Changes in V2:
 *   - UserNodeRegistry: NodeTier enum updated (HOBBY, BUILDER, STARTUP, TEAM)
 *   - ReferralSystem: Rewards distributed in USDT via Web3Auth instead of LSK
 */
contract UpgradeV2 is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        address registryProxy = vm.envAddress("USER_NODE_REGISTRY_PROXY");
        address referralProxy = vm.envAddress("REFERRAL_SYSTEM_PROXY");
        address usdtToken = vm.envAddress("USDT_TOKEN_ADDRESS");

        console.log("=================================================");
        console.log("QuikDB V2 Upgrade");
        console.log("=================================================");
        console.log("Deployer:", deployer);
        console.log("Registry Proxy:", registryProxy);
        console.log("Referral Proxy:", referralProxy);
        console.log("USDT Token:", usdtToken);
        console.log("=================================================");

        vm.startBroadcast(deployerPrivateKey);

        // ═══════════════════════════════════════════════════════════════
        // Step 1: Deploy new UserNodeRegistry V2 implementation
        // ═══════════════════════════════════════════════════════════════
        console.log("Deploying UserNodeRegistry V2 implementation...");
        UserNodeRegistry registryImplV2 = new UserNodeRegistry();
        console.log("UserNodeRegistry V2 impl:", address(registryImplV2));

        // Upgrade proxy to new implementation (no reinitializer needed for registry)
        UserNodeRegistry registry = UserNodeRegistry(registryProxy);
        registry.upgradeToAndCall(address(registryImplV2), "");
        console.log("UserNodeRegistry upgraded to V2");
        console.log("  Version:", registry.version());

        // ═══════════════════════════════════════════════════════════════
        // Step 2: Deploy new ReferralSystem V2 implementation
        // ═══════════════════════════════════════════════════════════════
        console.log("Deploying ReferralSystem V2 implementation...");
        ReferralSystem referralImplV2 = new ReferralSystem();
        console.log("ReferralSystem V2 impl:", address(referralImplV2));

        // Upgrade proxy and call initializeV2 to set USDT reward token
        bytes memory initV2Data = abi.encodeWithSelector(
            ReferralSystem.initializeV2.selector,
            usdtToken
        );
        ReferralSystem referral = ReferralSystem(referralProxy);
        referral.upgradeToAndCall(address(referralImplV2), initV2Data);
        console.log("ReferralSystem upgraded to V2");
        console.log("  Version:", referral.version());
        console.log("  Reward Token:", referral.getRewardToken());

        vm.stopBroadcast();

        // ═══════════════════════════════════════════════════════════════
        // Verification
        // ═══════════════════════════════════════════════════════════════
        console.log("=================================================");
        console.log("Verification");
        console.log("=================================================");

        // Verify versions
        string memory regVersion = registry.version();
        string memory refVersion = referral.version();
        console.log("UserNodeRegistry version:", regVersion);
        console.log("ReferralSystem version:", refVersion);

        // Verify reward token is set
        address rewardToken = referral.getRewardToken();
        require(rewardToken == usdtToken, "Reward token mismatch");
        console.log("Reward token verified:", rewardToken);

        // Verify existing data is preserved
        (uint256 totalUsers, uint256 totalNodes, uint256 totalDeployments) = registry.getTotalStats();
        console.log("Existing data preserved:");
        console.log("  Total users:", totalUsers);
        console.log("  Total nodes:", totalNodes);
        console.log("  Total deployments:", totalDeployments);

        // Save deployment info
        string memory deploymentInfo = string(abi.encodePacked(
            "UserNodeRegistry V2 Impl: ", vm.toString(address(registryImplV2)), "\n",
            "ReferralSystem V2 Impl: ", vm.toString(address(referralImplV2)), "\n",
            "USDT Reward Token: ", vm.toString(usdtToken), "\n",
            "Upgraded at: ", vm.toString(block.timestamp)
        ));
        vm.writeFile("./deployments/upgrade-v2-latest.txt", deploymentInfo);

        console.log("=================================================");
        console.log("V2 Upgrade Complete!");
        console.log("=================================================");
    }
}
