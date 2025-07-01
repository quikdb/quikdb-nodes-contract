module.exports = {
  preset: "ts-jest",
  testEnvironment: "node",
  testMatch: ["**/__tests__/**/*.test.ts"],
  // Skip integration tests by default (they need a local blockchain)
  testPathIgnorePatterns: ["/node_modules/", "/dist/", "/integration.test.ts"],
  verbose: true,
  transform: {
    "^.+\\.ts$": [
      "ts-jest",
      {
        tsconfig: "tsconfig.json",
      },
    ],
  },
};
