#!/usr/bin/env node
const fs = require("fs");
const path = require("path");

/**
 * Script to extract ABIs from Foundry artifacts and save them in the SDK
 */

const ARTIFACT_DIR = path.join(__dirname, "../smart-contract/out");
const SDK_ABI_DIR = path.join(__dirname, "../sdk/src/abis");

// Ensure the ABI directory exists
if (!fs.existsSync(SDK_ABI_DIR)) {
  fs.mkdirSync(SDK_ABI_DIR, { recursive: true });
}

// List of contracts to extract ABIs from
const contracts = [
  { name: "NodeStorage", path: "NodeStorage.sol/NodeStorage.json" },
  { name: "UserStorage", path: "UserStorage.sol/UserStorage.json" },
  { name: "ResourceStorage", path: "ResourceStorage.sol/ResourceStorage.json" },
];

// Extract and save ABIs
contracts.forEach((contract) => {
  try {
    const artifactPath = path.join(ARTIFACT_DIR, contract.path);
    if (!fs.existsSync(artifactPath)) {
      console.error(`Artifact not found: ${artifactPath}`);
      return;
    }

    // Read the artifact JSON
    const artifact = JSON.parse(fs.readFileSync(artifactPath, "utf8"));

    // Extract the ABI
    const abi = artifact.abi;

    // Create the ABI file content
    const abiFileContent = JSON.stringify(
      {
        name: contract.name,
        abi,
      },
      null,
      2
    );

    // Save the ABI file
    const outputPath = path.join(SDK_ABI_DIR, `${contract.name}.json`);
    fs.writeFileSync(outputPath, abiFileContent);

    console.log(
      `ABI extracted for ${contract.name} and saved to ${outputPath}`
    );
  } catch (error) {
    console.error(`Error extracting ABI for ${contract.name}:`, error.message);
  }
});

console.log("ABI extraction complete!");
