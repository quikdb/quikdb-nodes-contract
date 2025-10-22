// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/ReferralSystem.sol";
import "../src/UserNodeRegistry.sol";
import "../src/tokens/QuiksToken.sol";
import "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/**
 * @title DeployReferralSystem
 * @notice Deployment script for ReferralSystem contract with UUPS proxy pattern
 * @dev Run with: forge script scripts/DeployReferralSystem.s.sol:DeployReferralSystem --rpc-url <RPC_URL> --broadcast
 */
contract DeployReferralSystem is Script {
    
    function run() external {
        // Load environment variables
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        // Load existing contract addresses from environment
        address userRegistryAddress = vm.envAddress("USER_REGISTRY_ADDRESS");
        address quiksTokenAddress = vm.envAddress("QUIKS_TOKEN_ADDRESS");
        
        console.log("=================================================");
        console.log("Deploying ReferralSystem");
        console.log("=================================================");
        console.log("Deployer:", deployer);
        console.log("UserNodeRegistry:", userRegistryAddress);
        console.log("QuiksToken:", quiksTokenAddress);
        console.log("=================================================");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy implementation contract
        ReferralSystem referralSystemImpl = new ReferralSystem();
        console.log("ReferralSystem Implementation deployed at:", address(referralSystemImpl));
        
        // Encode initialization data
        bytes memory initData = abi.encodeWithSelector(
            ReferralSystem.initialize.selector,
            userRegistryAddress,  // UserNodeRegistry address
            quiksTokenAddress,    // QuiksToken address
            deployer              // Owner address
        );
        
        // Deploy proxy contract
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(referralSystemImpl),
            initData
        );
        console.log("ReferralSystem Proxy deployed at:", address(proxy));
        
        // Wrap proxy in ReferralSystem interface
        ReferralSystem referralSystem = ReferralSystem(address(proxy));
        
        // Verify initialization
        console.log("=================================================");
        console.log("Verifying deployment...");
        console.log("Owner:", referralSystem.owner());
        console.log("UserRegistry:", address(referralSystem.userRegistry()));
        console.log("QuiksToken:", address(referralSystem.quiksToken()));
        console.log("Total Referral Codes:", referralSystem.totalReferralCodes());
        console.log("Auto Reward Enabled:", referralSystem.autoRewardEnabled());
        console.log("=================================================");
        
        vm.stopBroadcast();
        
        // Save deployment addresses to file
        string memory deploymentInfo = string.concat(
            "REFERRAL_SYSTEM_PROXY=", vm.toString(address(proxy)), "\n",
            "REFERRAL_SYSTEM_IMPL=", vm.toString(address(referralSystemImpl)), "\n"
        );
        
        vm.writeFile("./deployments/referral-system-latest.txt", deploymentInfo);
        console.log("Deployment info saved to ./deployments/referral-system-latest.txt");
    }
}

/**
 * @title UpgradeReferralSystem
 * @notice Script to upgrade ReferralSystem implementation
 * @dev Run with: forge script scripts/DeployReferralSystem.s.sol:UpgradeReferralSystem --rpc-url <RPC_URL> --broadcast
 */
contract UpgradeReferralSystem is Script {
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address proxyAddress = vm.envAddress("REFERRAL_SYSTEM_PROXY");
        
        console.log("=================================================");
        console.log("Upgrading ReferralSystem");
        console.log("=================================================");
        console.log("Proxy Address:", proxyAddress);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy new implementation
        ReferralSystem newImpl = new ReferralSystem();
        console.log("New Implementation deployed at:", address(newImpl));
        
        // Upgrade proxy to new implementation
        ReferralSystem(proxyAddress).upgradeToAndCall(address(newImpl), "");
        console.log("Proxy upgraded successfully");
        
        vm.stopBroadcast();
        
        console.log("=================================================");
    }
}

/**
 * @title FundReferralSystem
 * @notice Script to fund ReferralSystem with QUIKS tokens for rewards
 * @dev Run with: forge script scripts/DeployReferralSystem.s.sol:FundReferralSystem --rpc-url <RPC_URL> --broadcast
 */
contract FundReferralSystem is Script {
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address proxyAddress = vm.envAddress("REFERRAL_SYSTEM_PROXY");
        address quiksTokenAddress = vm.envAddress("QUIKS_TOKEN_ADDRESS");
        uint256 fundAmount = vm.envUint("FUND_AMOUNT"); // Amount in wei (e.g., 100000 ether for 100,000 QUIKS)
        
        console.log("=================================================");
        console.log("Funding ReferralSystem");
        console.log("=================================================");
        console.log("ReferralSystem:", proxyAddress);
        console.log("QuiksToken:", quiksTokenAddress);
        console.log("Fund Amount:", fundAmount);
        
        vm.startBroadcast(deployerPrivateKey);
        
        QuiksToken quiksToken = QuiksToken(quiksTokenAddress);
        
        // Approve tokens
        quiksToken.approve(proxyAddress, fundAmount);
        console.log("Approved QUIKS tokens");
        
        // Fund the contract
        ReferralSystem referralSystem = ReferralSystem(proxyAddress);
        referralSystem.fundRewards(fundAmount);
        console.log("Funded ReferralSystem with", fundAmount, "QUIKS");
        
        // Check balance
        uint256 balance = quiksToken.balanceOf(proxyAddress);
        console.log("ReferralSystem balance:", balance);
        
        vm.stopBroadcast();
        
        console.log("=================================================");
    }
}
