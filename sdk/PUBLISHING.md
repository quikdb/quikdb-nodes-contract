# Publishing Guide for QuikDB Nodes SDK

This document explains how to publish a new version of the QuikDB Nodes SDK to npm.

## Prerequisites

1. You need an npm account with publishing rights to the `quikdb-nodes-sdk` package
2. You need to be logged in to npm on your machine (`npm login`)

## Publishing Steps

1. Update version number in package.json

   - Follow semantic versioning:
     - Patch (0.0.x): Bug fixes that don't affect the API
     - Minor (0.x.0): New backward-compatible features
     - Major (x.0.0): Breaking changes

2. Run tests to ensure everything works

   ```
   npm test
   npm run test:integration
   ```

3. Build the package

   ```
   npm run build:all
   ```

4. Publish to npm

   ```
   npm publish
   ```

5. Create a release tag in Git
   ```
   git tag -a v1.0.0 -m "Release v1.0.0"
   git push origin v1.0.0
   ```

## Versioning Strategy

We follow [Semantic Versioning](https://semver.org/):

- MAJOR version when you make incompatible API changes
- MINOR version when you add functionality in a backward-compatible manner
- PATCH version when you make backward-compatible bug fixes

## Testing Your Package Before Publishing

You can test the package locally before publishing:

1. Pack the package without publishing

   ```
   npm pack
   ```

2. Install the packed package in a test project
   ```
   cd ../test-project
   npm install ../quikdb-nodes-contract/sdk/quikdb-nodes-sdk-1.0.0.tgz
   ```

## Publishing to Different npm Registries

### Publishing to npm (default)

```
npm publish
```

### Publishing to a custom registry

```
npm publish --registry=https://registry.your-company.com
```

### Publishing a beta version

```
npm version prerelease --preid=beta
npm publish --tag beta
```

## After Publishing

After publishing, you should:

1. Update the documentation site if you have one
2. Notify users about the new version through appropriate channels
3. Update any example repos using the package
