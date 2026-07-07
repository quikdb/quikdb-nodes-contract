# quikdb-nodes-contract

Solidity smart contracts for QuikDB on-chain operations: user/node registration, referral rewards, QUIKS utility token, and node affiliate staking.

## Stack

| Component | Value |
| --------- | ----- |
| Language | Solidity ^0.8.20 |
| Framework | Foundry (Forge) |
| Dependencies | OpenZeppelin Contracts (upgradeable) |
| Config | `foundry.toml` |
| Build output | `out/` |

## Contracts

| File | Contract | Purpose |
| ---- | -------- | ------- |
| `src/UserNodeRegistry.sol` | UserNodeRegistry | Upgradeable registry for users, nodes, and applications. Handles registration, metadata, deployment tracking, performance metrics, and batch operations. |
| `src/ReferralSystem.sol` | ReferralSystem | Referral code generation, tracking, and USDT reward distribution. Tier-based bonuses. |
| `src/tokens/QuiksToken.sol` | QuiksToken | ERC-20 utility token (QUIKS). Owner-only minting with 500M hard cap, burnable, EIP-2612 permit. v2.0.0. |
| `src/QuiksStaking.sol` | QuiksStaking | Node Affiliate staking. 5,000 QUIKS required, 90-day lock, owner-triggered slash → burn. v1.0.0. |

All contracts use the UUPS upgradeable proxy pattern with `OwnableUpgradeable`, `PausableUpgradeable`, and `ReentrancyGuardUpgradeable`.

## Build and Test

```bash
forge build      # Compile
forge test -vvv  # Run tests
```

## Deployment

**ALL deployments go through GitHub Actions only — never deploy locally.**

Push to the target network branch to trigger a deploy. Each branch maps to exactly one network.

### Deploy branches (fresh deploy — all contracts)

| Branch | Network |
| ------ | ------- |
| `eth-sepolia` | Ethereum Sepolia (chainId 11155111) |
| `eth-mainnet` | Ethereum Mainnet (chainId 1) |
| `lisk-sepolia` | Lisk Sepolia (chainId 4202) |
| `lisk-mainnet` | Lisk Mainnet (chainId 1135) |

### Upgrade branches (upgrade proxy implementations only)

| Branch | Network |
| ------ | ------- |
| `eth-sepolia-upgrade` | Ethereum Sepolia |
| `eth-mainnet-upgrade` | Ethereum Mainnet |
| `lisk-sepolia-upgrade` | Lisk Sepolia |
| `lisk-mainnet-upgrade` | Lisk Mainnet |

### Transfer ownership

Use `workflow_dispatch` on the **Deploy Contracts** workflow. Requires `network` and `new_owner` address as inputs.

**WARNING: Always transfer ownership BEFORE rotating `DEPLOYER_PRIVATE_KEY`. If you rotate the key first, the new wallet cannot call `transferOwnership`.**

### Mainnet approval gate

Pushes to any `mainnet` branch require manual approval from Samson before the job runs (via the `mainnet-deploy` GH Environment).

### What happens on deploy

1. `forge test` runs — deploy aborts on any failure
2. `forge script scripts/QuikDBDeployment.sol` broadcasts transactions
3. Contract addresses are POSTed to `device-api` webhook
4. `device-api` stores addresses in MongoDB (`contractDeployments` collection)
5. `payoutTransferService` reads addresses from MongoDB at runtime

Deployment JSON files in `deployments/` are written during the run for the webhook step only — they are NOT committed back to the repo.

### Org secrets required

| Secret | Description |
| ------ | ----------- |
| `DEPLOYER_PRIVATE_KEY` | Wallet that owns QuiksToken + UserNodeRegistry |
| `LISK_SEPOLIA_RPC_URL` | `https://rpc.sepolia-api.lisk.com` |
| `LISK_MAINNET_RPC_URL` | `https://rpc.api.lisk.com` |
| `ETH_MAINNET_RPC_URL` | Ethereum mainnet RPC |
| `DEPLOY_WEBHOOK_TOKEN` | Bearer token for device-api webhook |
| `DEVICE_API_URL` | `https://device.quikdb.net` |

## Contract Addresses

Contract addresses are the source of truth in MongoDB (`contractDeployments` collection) — not in this repo.

Live networks: `eth-sepolia`, `eth-mainnet`, `lisk-sepolia`, `lisk-mainnet`

## Quirks

- Storage layout must be preserved across upgrades — never reorder or remove storage variables.
- `via_ir = true` enables IR-based compilation (better optimization, slower compile).
- QuiksToken `maxSupply` is enforced on-chain — `mint()` reverts if `totalSupply + amount > 500M`.
- `payoutTransferService` throws on init if no MongoDB record exists for the active network.
