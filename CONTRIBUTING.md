# Contributing to quikdb-nodes-contract

This repo is open source. Contributions are welcome — bug fixes, test coverage, gas optimisations, and documentation improvements.

---

## Prerequisites

| Tool | Version | Install |
| ---- | ------- | ------- |
| Foundry | latest | `curl -L https://foundry.paradigm.xyz \| bash && foundryup` |
| Git | any | system |

No Node.js, no npm, no hardhat. Foundry only.

---

## Local Setup

```bash
git clone https://github.com/quikdb/quikdb-nodes-contract
cd quikdb-nodes-contract
forge install        # installs OpenZeppelin and forge-std from foundry.toml
forge build          # should compile with 0 errors
forge test -vvv      # should pass all tests
```

If `forge install` fails, run:

```bash
git submodule update --init --recursive
```

---

## Project Structure

```
src/
├── tokens/
│   ├── QuiksToken.sol       — ERC-20 QUIKS, 500M hard cap, UUPS upgradeable
│   └── MockUSDT.sol         — Testnet USDT simulation only
├── QuiksStaking.sol         — Node Affiliate staking, 5K QUIKS, 90-day lock
├── UserNodeRegistry.sol     — User/node/app registry
└── ReferralSystem.sol       — Referral codes and USDT reward distribution

scripts/
└── QuikDBDeployment.sol     — CREATE2 deployment script (CI only)

test/
├── QuikDB.t.sol             — Core registry and token tests
└── ReferralSystem.t.sol     — Referral system tests
```

---

## Running Tests

```bash
forge test -vvv                          # all tests, verbose
forge test --match-test testStake -vvv   # run a specific test
forge test --match-contract QuikDB -vvv  # run a specific test file
forge coverage                           # coverage report
```

All tests must pass before submitting a PR. PRs that break existing tests will not be merged.

---

## Writing Tests

Tests live in `test/`. Use Foundry's `Test` base contract.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/tokens/QuiksToken.sol";

contract MyFeatureTest is Test {
    QuiksToken token;
    address owner = address(0xBEEF);

    function setUp() public {
        // Deploy implementation + proxy manually in tests
        QuiksToken impl = new QuiksToken();
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(impl),
            abi.encodeCall(QuiksToken.initialize, (
                "QuikDB Token", "QUIKS",
                500_000_000 * 1e18,
                500_000_000 * 1e18,
                owner
            ))
        );
        token = QuiksToken(address(proxy));
    }

    function testMaxSupplyEnforced() public {
        vm.prank(owner);
        vm.expectRevert("Would exceed maxSupply");
        token.mint(owner, 1);   // supply is already at cap
    }
}
```

Test naming: `test<WhatItTests>` for passing cases, `testRevert<WhatShouldFail>` for expected reverts.

---

## Storage Layout Rules

All contracts use UUPS upgradeable proxies. **Never reorder or remove storage variables between versions.** Only append new variables at the end of the storage block.

Wrong:
```solidity
// v1
uint256 public maxSupply;
address public treasury;   // added in v2 — WRONG, inserted before existing vars
uint256 public totalStaked;
```

Correct:
```solidity
// v1
uint256 public maxSupply;
uint256 public totalStaked;
// v2 — append only
address public treasury;
```

Violating storage layout corrupts all proxy state. If you are unsure, run:

```bash
forge inspect QuiksToken storage-layout
```

and compare against the deployed version before submitting.

---

## Gas Optimisation

Run the gas snapshot before and after your change:

```bash
forge snapshot                    # before
# make your change
forge snapshot --diff             # compare
```

Include the diff output in your PR description if your change affects gas.

---

## Submitting a PR

1. Fork the repo and create a branch: `git checkout -b fix/my-fix`
2. Make your change
3. Run `forge test -vvv` — all tests must pass
4. Run `forge build --sizes` — no contract should exceed 24KB
5. Open a PR against `main`

PR title format:
- `fix: description` — bug fix
- `feat: description` — new feature
- `test: description` — test coverage only
- `docs: description` — documentation only
- `gas: description` — gas optimisation

---

## What We Will Not Merge

- Changes that alter storage layout of deployed contracts without a migration path
- New `mint()` calls that bypass the `maxSupply` check
- Admin functions callable by non-owners without explicit design rationale
- Tests that `vm.assume` away all meaningful edge cases
- Any change that removes `nonReentrant` from state-mutating functions

---

## Deployment

You cannot deploy from your local machine. All deployments go through GitHub Actions on network branches. See [README.md](README.md) for the full deployment flow.

---

## Questions

Open a GitHub issue or reach out on the [QuikDB Discord](https://discord.gg/quikdb).
