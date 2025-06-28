import { ethers } from "ethers";
import { UserModule } from "../modules/user";
import { UserType } from "../types/user.types";

// Mock data and contract interactions
jest.mock("ethers", () => {
  const originalModule = jest.requireActual("ethers");

  // Mock contract calls
  const mockContract = {
    getUserProfile: jest.fn().mockResolvedValue({
      userAddress: "0x1234567890123456789012345678901234567890",
      userType: 1, // UserType.CONSUMER
      profileHash:
        "0x7890123456789012345678901234567890123456789012345678901234567890",
      isActive: true,
      createdAt: Math.floor(Date.now() / 1000) - 30 * 24 * 3600, // 30 days ago
      isVerified: true,
      reputation: 95,
      totalTransactions: 25,
      paymentInfo: "payment-info-hash",
      preferences: { notificationsEnabled: true, language: "en" },
      subscriptionTier: 2,
      exists: true,
    }),
    registerUser: jest.fn().mockResolvedValue({
      hash: "0xabcdef1234567890",
      wait: jest.fn().mockResolvedValue({ status: 1 }),
    }),
    updateUserStatus: jest.fn().mockResolvedValue({
      hash: "0xabcdef1234567890",
      wait: jest.fn().mockResolvedValue({ status: 1 }),
    }),
    getUserCount: jest.fn().mockResolvedValue(156),
    connect: jest.fn().mockReturnThis(),
  };

  return {
    ...originalModule,
    Contract: jest.fn().mockImplementation(() => mockContract),
    JsonRpcProvider: jest.fn().mockImplementation(() => ({})),
    Wallet: jest.fn().mockImplementation(() => ({
      connect: jest.fn().mockReturnThis(),
    })),
  };
});

describe("UserModule", () => {
  let userModule: UserModule;
  const mockProvider = new ethers.JsonRpcProvider("https://rpc-mock.lisk.io");
  const mockSigner = new ethers.Wallet("0x0123456789abcdef", mockProvider);

  beforeEach(() => {
    // Initialize module with mock provider and contract address
    userModule = new UserModule(
      mockProvider,
      "0x1234567890123456789012345678901234567890",
      mockSigner
    );
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe("getUserProfile", () => {
    it("should return user profile information for a given address", async () => {
      const userAddress = "0x1234567890123456789012345678901234567890";
      const profile = await userModule.getUserProfile(userAddress);

      expect(profile).toBeDefined();
      expect(profile.userAddress).toBe(userAddress);
      expect(profile.userType).toBe(UserType.CONSUMER);
      expect(profile.isActive).toBe(true);
      expect(profile.exists).toBe(true);
    });
  });

  describe("registerUser", () => {
    it("should register a new user and return transaction response", async () => {
      const userAddress = "0x2345678901234567890123456789012345678901";
      const profileHash =
        "0x7890123456789012345678901234567890123456789012345678901234567890";
      const userType = UserType.PROVIDER;

      const result = await userModule.registerUser(
        userAddress,
        profileHash,
        userType
      );

      expect(result).toBeDefined();
      expect(result.hash).toBe("0xabcdef1234567890");
    });

    it("should throw an error if signer is not provided", async () => {
      // Create a module without signer
      const noSignerModule = new UserModule(
        mockProvider,
        "0x1234567890123456789012345678901234567890"
      );

      const userAddress = "0x2345678901234567890123456789012345678901";
      const profileHash =
        "0x7890123456789012345678901234567890123456789012345678901234567890";
      const userType = UserType.PROVIDER;

      await expect(
        noSignerModule.registerUser(userAddress, profileHash, userType)
      ).rejects.toThrow("Signer required for this operation");
    });
  });

  describe("updateUserStatus", () => {
    it("should update user status and return transaction response", async () => {
      const userAddress = "0x1234567890123456789012345678901234567890";
      const isActive = false;

      const result = await userModule.updateUserStatus(userAddress, isActive);

      expect(result).toBeDefined();
      expect(result.hash).toBe("0xabcdef1234567890");
    });
  });

  describe("getUserCount", () => {
    it("should return the total number of registered users", async () => {
      const count = await userModule.getUserCount();
      expect(count).toBe(156);
    });
  });
});
