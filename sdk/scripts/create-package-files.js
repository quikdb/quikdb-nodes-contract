const fs = require("fs");
const path = require("path");
const { exec } = require("child_process");

// Create correct directory structure for the exported files
function fixDirectoryStructure() {
  const distPath = path.resolve(__dirname, "../dist");
  const srcPath = path.resolve(distPath, "src");

  // Ensure the correct index.js file exists at the root of dist
  fs.copyFileSync(
    path.resolve(srcPath, "index.js"),
    path.resolve(distPath, "index.js")
  );
  fs.copyFileSync(
    path.resolve(srcPath, "index.d.ts"),
    path.resolve(distPath, "index.d.ts")
  );

  // Ensure mocks.js file exists at the root of dist for /mocks subpath
  fs.copyFileSync(
    path.resolve(srcPath, "mocks.js"),
    path.resolve(distPath, "mocks.js")
  );
  fs.copyFileSync(
    path.resolve(srcPath, "mocks.d.ts"),
    path.resolve(distPath, "mocks.d.ts")
  );

  // Fix the import paths in the main index.js file
  const indexContent = fs.readFileSync(
    path.resolve(distPath, "index.js"),
    "utf8"
  );
  const fixedIndexContent = indexContent
    .replace('require("./types")', 'require("./src/types")')
    .replace('require("./modules")', 'require("./src/modules")')
    .replace('require("./QuikDBNodesSDK")', 'require("./src/QuikDBNodesSDK")')
    .replace('require("./utils")', 'require("./src/utils")');

  fs.writeFileSync(path.resolve(distPath, "index.js"), fixedIndexContent);

  // Fix the import paths in the mocks.js file
  const mocksContent = fs.readFileSync(
    path.resolve(distPath, "mocks.js"),
    "utf8"
  );
  const fixedMocksContent = mocksContent.replace(
    'require("./modules/mocks")',
    'require("./src/modules/mocks")'
  );

  fs.writeFileSync(path.resolve(distPath, "mocks.js"), fixedMocksContent);

  // Do the same for ESM
  const esmPath = path.resolve(distPath, "esm");
  const esmSrcPath = path.resolve(esmPath, "src");

  // Ensure the correct index.js file exists at the root of dist/esm
  fs.copyFileSync(
    path.resolve(esmSrcPath, "index.js"),
    path.resolve(esmPath, "index.js")
  );
  fs.copyFileSync(
    path.resolve(esmSrcPath, "index.d.ts"),
    path.resolve(esmPath, "index.d.ts")
  );

  // Ensure mocks.js file exists at the root of dist/esm for /mocks subpath
  fs.copyFileSync(
    path.resolve(esmSrcPath, "mocks.js"),
    path.resolve(esmPath, "mocks.js")
  );
  fs.copyFileSync(
    path.resolve(esmSrcPath, "mocks.d.ts"),
    path.resolve(esmPath, "mocks.d.ts")
  );

  // Fix the import paths in the main index.js file (ESM)
  const esmIndexContent = fs.readFileSync(
    path.resolve(esmPath, "index.js"),
    "utf8"
  );
  const fixedEsmIndexContent = esmIndexContent
    .replace('from "./types"', 'from "./src/types"')
    .replace('from "./modules"', 'from "./src/modules"')
    .replace('from "./QuikDBNodesSDK"', 'from "./src/QuikDBNodesSDK"')
    .replace('from "./utils"', 'from "./src/utils"');

  fs.writeFileSync(path.resolve(esmPath, "index.js"), fixedEsmIndexContent);

  // Fix the import paths in the mocks.js file (ESM)
  const esmMocksContent = fs.readFileSync(
    path.resolve(esmPath, "mocks.js"),
    "utf8"
  );
  const fixedEsmMocksContent = esmMocksContent.replace(
    'from "./modules/mocks"',
    'from "./src/modules/mocks"'
  );

  fs.writeFileSync(path.resolve(esmPath, "mocks.js"), fixedEsmMocksContent);
}

// Path to the root package.json
const packageJsonPath = path.resolve(__dirname, "../package.json");
// Path to the ESM package.json
const esmPackageJsonPath = path.resolve(__dirname, "../dist/esm/package.json");

// Read the main package.json
const packageJson = JSON.parse(fs.readFileSync(packageJsonPath, "utf8"));

// Create package.json for ESM
const esmPackageJson = {
  type: "module",
  sideEffects: false,
};

// Create dist/package.json for CJS
const cjsPackageJson = {
  type: "commonjs",
  sideEffects: false,
};

// Create and write ESM package.json
fs.writeFileSync(esmPackageJsonPath, JSON.stringify(esmPackageJson, null, 2));

// Create and write CJS package.json
fs.writeFileSync(
  path.resolve(__dirname, "../dist/package.json"),
  JSON.stringify(cjsPackageJson, null, 2)
);

// Fix directory structure for exports
fixDirectoryStructure();

console.log("✅ Package files created successfully");
