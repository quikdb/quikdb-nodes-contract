module.exports = {
  parser: "@typescript-eslint/parser",
  plugins: ["@typescript-eslint"],
  extends: ["eslint:recommended", "plugin:@typescript-eslint/recommended"],
  env: {
    node: true,
    jest: true,
  },
  rules: {
    // Allow unused vars with underscore prefix
    "@typescript-eslint/no-unused-vars": [
      "warn",
      { argsIgnorePattern: "^_", varsIgnorePattern: "^_" },
    ],
    // Allow empty functions (sometimes needed for mocks)
    "@typescript-eslint/no-empty-function": "off",
    // Allow explicit any (sometimes needed when working with unknown contract types)
    "@typescript-eslint/no-explicit-any": "off",
    // Allow non-null assertions (for tests mostly)
    "@typescript-eslint/no-non-null-assertion": "off",
  },
  ignorePatterns: [
    "dist",
    "node_modules",
    "jest.config.js",
    "jest.integration.config.js",
    "scripts",
    "*.js",
  ],
};
