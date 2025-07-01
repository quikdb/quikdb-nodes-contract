#!/bin/bash

# Prepare the SDK for publishing
echo "Preparing QuikDB Nodes SDK for publishing..."

# Make sure we're in the SDK directory
cd "$(dirname "$0")" || exit
cd sdk || exit

# Install dependencies
echo "Installing dependencies..."
npm install

# Ensure all the build scripts work
echo "Testing build process..."
npm run build

# Create a dry run package to see what will be included
echo "Creating a package dry run..."
npm pack --dry-run

echo ""
echo "===================================================================="
echo "The SDK is ready for publishing!"
echo ""
echo "To publish a new version:"
echo "1. Update the version in package.json"
echo "2. Run: npm run prepublishOnly"
echo "3. Run: npm publish"
echo ""
echo "See PUBLISHING.md for more detailed instructions."
echo "===================================================================="
