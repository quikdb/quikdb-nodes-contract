# Working with Proxy Contracts in QuikDB Nodes SDK

## Current Setup

The contracts at the provided addresses are proxy contracts:

```javascript
NODE_STORAGE_ADDRESS = "0x5FbDB2315678afecb367f032d93F642f64180aa3";
USER_STORAGE_ADDRESS = "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512";
RESOURCE_STORAGE_ADDRESS = "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0";
```

## Understanding Proxy Patterns

The test script has detected that these are proxy contracts. A proxy contract:

1. Stores the actual contract logic in a separate implementation contract
2. Delegates all calls to the implementation contract
3. Can be upgraded by pointing to a new implementation

## Common Proxy Storage Slots

The script checks these standard proxy implementation slots:

- EIP-1967: `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
- EIP-1822 (UUPS): `0x7050c9e0f4ca769c69bd3a8ef740bc37934f8e2c036e5a723fd8ee048ed3f8c3`
- Alternate: `0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7`

## Required Changes

### 1. SDK Updates Needed

The SDK should be updated to support proxy contracts:

```javascript
class QuikDBNodesSDK {
  constructor(config) {
    // New config options for proxy support
    const {
      provider,
      nodeStorageAddress,
      nodeStorageImplementationAddress, // New
      userStorageAddress,
      userStorageImplementationAddress, // New
      resourceStorageAddress,
      resourceStorageImplementationAddress, // New
      signer,
    } = config;

    // Initialize with both proxy and implementation addresses
    this.node = new NodeModule(
      provider,
      nodeStorageAddress,
      nodeStorageImplementationAddress,
      signer
    );
    // ... similar for other modules
  }
}
```

### 2. Contract Initialization

When initializing the SDK with proxy contracts:

```javascript
const sdk = new QuikDBNodesSDK({
  provider,
  // Proxy addresses
  nodeStorageAddress: PROXY_ADDRESS,
  userStorageAddress: USER_PROXY_ADDRESS,
  resourceStorageAddress: RESOURCE_PROXY_ADDRESS,
  // Implementation addresses (optional, SDK can auto-detect)
  nodeStorageImplementationAddress: NODE_IMPL_ADDRESS,
  userStorageImplementationAddress: USER_IMPL_ADDRESS,
  resourceStorageImplementationAddress: RESOURCE_IMPL_ADDRESS,
  signer: wallet,
});
```

## Next Steps

1. **Get Implementation Addresses**:

   ```javascript
   const nodeImplAddress = await provider.getStorage(
     NODE_STORAGE_ADDRESS,
     "0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc"
   );
   ```

2. **Verify Implementation Contracts**:

   - Get the implementation contract bytecode
   - Compare with expected contract interface
   - Update SDK ABIs if needed

3. **Update SDK**:

   - Add proxy support in contract modules
   - Add implementation address handling
   - Update ABI handling to work with proxy delegation

4. **Testing**:
   - Test both proxy and implementation contract interactions
   - Verify upgrades work correctly
   - Ensure state persistence across upgrades

## Common Issues

1. **Wrong Implementation Address**:

   - Check multiple storage slots
   - Verify implementation contract exists
   - Ensure implementation has correct interface

2. **ABI Mismatch**:

   - Update SDK ABIs to match implementation
   - Check for contract upgrades
   - Verify function signatures

3. **Proxy Delegation**:
   - Some functions might be proxy-specific
   - Check for admin functions
   - Handle upgrades properly

## Further Reading

- [EIP-1967: Standard Proxy Storage Slots](https://eips.ethereum.org/EIPS/eip-1967)
- [UUPS Proxies](https://docs.openzeppelin.com/contracts/4.x/api/proxy#UUPSUpgradeable)
- [OpenZeppelin Proxy Docs](https://docs.openzeppelin.com/contracts/4.x/upgradeable)
