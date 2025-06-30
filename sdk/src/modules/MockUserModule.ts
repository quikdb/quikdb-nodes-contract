import { ethers } from "ethers";
import { BaseModule, TransactionResponse } from "../types/common.types";
import {
  UserProfile,
  UserPreferences,
  UserStats,
  UserInfo,
  UserType,
} from "../types/user.types";
import { mockUsers } from "../../examples/mock-data";

/**
 * Mock implementation of UserModule for testing without a blockchain
 *
 * This module provides all the functionality of the standard UserModule
 * but uses in-memory mock data instead of making actual blockchain calls.
 * This is useful for:
 * - Local development without a blockchain connection
 * - Writing tests that don't depend on external services
 * - Demonstrating SDK features without a real contract deployment
 */
export class MockUserModule implements BaseModule {
  private mockUsers: Map<string, UserInfo>;
  private provider: ethers.Provider;
  private signer?: ethers.Signer;
  private contract: ethers.Contract; // Dummy contract to match interface

  constructor(
    provider: ethers.Provider,
    contractAddress: string,
    signer?: ethers.Signer
  ) {
    this.provider = provider;
    this.signer = signer;
    this.mockUsers = new Map<string, UserInfo>();

    // Initialize with some mock data
    this.generateMockData();

    // Create a dummy contract object to satisfy type requirements
    this.contract = new ethers.Contract(
      contractAddress,
      [], // Empty ABI since we're not using the contract
      provider
    );
  }

  /**
   * Generate some mock data for testing
   */
  private generateMockData() {
    // Generate 30 mock users
    for (let i = 0; i < 30; i++) {
      const userAddress = ethers.Wallet.createRandom().address;

      // Create deterministic but varied data
      let userType: UserType;
      if (i % 10 === 0) {
        userType = UserType.MARKETPLACE_ADMIN;
      } else if (i % 5 === 0) {
        userType = UserType.PLATFORM_ADMIN;
      } else if (i % 3 === 0) {
        userType = UserType.PROVIDER;
      } else {
        userType = UserType.CONSUMER;
      }

      const isActive = i % 4 !== 0; // 75% active

      // Current time minus 0-365 days
      const now = Math.floor(Date.now() / 1000);
      const createdAt = now - Math.floor(i % 365) * 24 * 60 * 60;
      const updatedAt =
        createdAt + Math.floor(Math.random() * (now - createdAt));

      // Create profile
      const profileHash = ethers.keccak256(
        ethers.toUtf8Bytes(`profile-${userAddress}-${i}`)
      );

      const totalSpent = ethers
        .parseEther((0.01 * (i % 100)).toFixed(18))
        .toString();

      const totalEarned = ethers
        .parseEther((0.02 * (i % 50)).toFixed(18))
        .toString();

      const reputationScore = 50 + (i % 50); // 50-99

      const profile: UserProfile = {
        profileHash,
        userType,
        isActive,
        createdAt,
        updatedAt,
        totalSpent,
        totalEarned,
        reputationScore,
        isVerified: i % 3 === 0, // 33% verified
      };

      // Create preferences
      const preferences: UserPreferences = {
        preferredRegion: ["us-east", "eu-central", "ap-south"][i % 3],
        maxHourlyRate: ethers
          .parseEther((0.1 * (1 + (i % 10))).toFixed(18))
          .toString(),
        autoRenewal: i % 2 === 0,
        preferredProviders: Array.from(
          { length: i % 5 },
          (_, idx) => ethers.Wallet.createRandom().address
        ),
        notificationLevel: i % 3,
      };

      // Create stats
      const stats: UserStats = {
        totalTransactions: i * 5,
        avgRating: 3 + (i % 20) / 10, // 3.0-4.9
        completedJobs: i * 3,
        cancelledJobs: i % 5,
        lastActivity: now - (i % 30) * 24 * 60 * 60, // Last 30 days
      };

      // Create full user info
      this.mockUsers.set(userAddress, {
        address: userAddress,
        profile,
        preferences,
        stats,
        exists: true,
      });
    }
  }

  /**
   * Connect to a new provider
   * @param provider Ethers provider
   */
  connect(provider: ethers.Provider): void {
    this.provider = provider;
  }

  /**
   * Set a new signer for transactions
   * @param signer Ethers signer
   */
  setSigner(signer: ethers.Signer): void {
    this.signer = signer;
  }

  /**
   * Get user profile
   * @param userAddress Address of the user
   * @returns User profile
   */
  async getUserProfile(userAddress: string): Promise<UserProfile> {
    const user = this.mockUsers.get(userAddress);
    if (!user) {
      throw new Error(`User not found: ${userAddress}`);
    }
    return user.profile;
  }

  /**
   * Get complete user information
   * @param userAddress Address of the user
   * @returns Complete user info
   */
  async getUserInfo(userAddress: string): Promise<UserInfo> {
    const user = this.mockUsers.get(userAddress);
    if (!user) {
      throw new Error(`User not found: ${userAddress}`);
    }
    return user;
  }

  /**
   * Register a new user
   * @param userAddress Address of the user
   * @param profileHash Hash of encrypted profile data
   * @param userType Type of user
   * @returns Transaction response
   */
  async registerUser(
    userAddress: string,
    profileHash: string,
    userType: UserType
  ): Promise<TransactionResponse> {
    if (!this.signer) {
      throw new Error("Signer required for this operation");
    }

    if (this.mockUsers.has(userAddress)) {
      throw new Error(`User already exists: ${userAddress}`);
    }

    const now = Math.floor(Date.now() / 1000);

    // Create a new user
    const profile: UserProfile = {
      profileHash,
      userType,
      isActive: true,
      createdAt: now,
      updatedAt: now,
      totalSpent: "0",
      totalEarned: "0",
      reputationScore: 50,
      isVerified: false,
    };

    const preferences: UserPreferences = {
      preferredRegion: "us-east",
      maxHourlyRate: "0",
      autoRenewal: false,
      preferredProviders: [],
      notificationLevel: 1,
    };

    const stats: UserStats = {
      totalTransactions: 0,
      avgRating: 0,
      completedJobs: 0,
      cancelledJobs: 0,
      lastActivity: now,
    };

    this.mockUsers.set(userAddress, {
      address: userAddress,
      profile,
      preferences,
      stats,
      exists: true,
    });

    // Return mock transaction response
    return this.mockTransactionResponse(`register-user-${userAddress}`);
  }

  /**
   * Update user profile
   * @param userAddress Address of the user
   * @param profileHash New profile hash
   * @returns Transaction response
   */
  async updateUserProfile(
    userAddress: string,
    profileHash: string
  ): Promise<TransactionResponse> {
    if (!this.signer) {
      throw new Error("Signer required for this operation");
    }

    const user = this.mockUsers.get(userAddress);
    if (!user) {
      throw new Error(`User not found: ${userAddress}`);
    }

    // Update profile
    user.profile.profileHash = profileHash;
    user.profile.updatedAt = Math.floor(Date.now() / 1000);

    // Return mock transaction response
    return this.mockTransactionResponse(`update-profile-${userAddress}`);
  }

  /**
   * Update user preferences
   * @param userAddress Address of the user
   * @param preferences User preferences
   * @returns Transaction response
   */
  async updateUserPreferences(
    userAddress: string,
    preferences: UserPreferences
  ): Promise<TransactionResponse> {
    if (!this.signer) {
      throw new Error("Signer required for this operation");
    }

    const user = this.mockUsers.get(userAddress);
    if (!user) {
      throw new Error(`User not found: ${userAddress}`);
    }

    // Update preferences
    user.preferences = preferences;
    user.profile.updatedAt = Math.floor(Date.now() / 1000);

    // Return mock transaction response
    return this.mockTransactionResponse(`update-preferences-${userAddress}`);
  }

  /**
   * Get user stats
   * @param userAddress Address of the user
   * @returns User stats
   */
  async getUserStats(userAddress: string): Promise<UserStats> {
    const user = this.mockUsers.get(userAddress);
    if (!user) {
      throw new Error(`User not found: ${userAddress}`);
    }
    return user.stats;
  }

  /**
   * Get users list with pagination and filtering
   * @param page Page number (0-based)
   * @param pageSize Number of users per page
   * @param filter Optional filter criteria
   * @returns Array of user addresses and pagination info
   */
  async getUsersList(
    page: number = 0,
    pageSize: number = 10,
    filter?: {
      userType?: UserType;
      isActive?: boolean;
      registeredAfter?: number; // timestamp
      reputationScoreAbove?: number;
    }
  ): Promise<{
    users: string[];
    totalUsers: number;
    totalPages: number;
    currentPage: number;
    hasNextPage: boolean;
    hasPreviousPage: boolean;
  }> {
    // Input validation
    if (page < 0) page = 0;
    if (pageSize <= 0) pageSize = 10;
    if (pageSize > 100) pageSize = 100; // Set a reasonable limit

    // Get all users and convert to array
    let users = Array.from(this.mockUsers.entries());

    // Apply filters if provided
    if (filter) {
      if (filter.userType !== undefined) {
        users = users.filter(
          ([_, user]) => user.profile.userType === filter.userType
        );
      }

      if (filter.isActive !== undefined) {
        users = users.filter(
          ([_, user]) => user.profile.isActive === filter.isActive
        );
      }

      if (filter.registeredAfter !== undefined) {
        users = users.filter(
          ([_, user]) => user.profile.createdAt > filter.registeredAfter!
        );
      }

      if (filter.reputationScoreAbove !== undefined) {
        users = users.filter(
          ([_, user]) =>
            user.profile.reputationScore > filter.reputationScoreAbove!
        );
      }
    }

    // Sort by registration date (newest first)
    users.sort(([_, a], [__, b]) => b.profile.createdAt - a.profile.createdAt);

    // Extract user addresses
    const userAddresses = users.map(([address, _]) => address);

    // Calculate pagination
    const totalUsers = userAddresses.length;
    const totalPages = Math.ceil(totalUsers / pageSize) || 1;
    const startIdx = page * pageSize;
    const endIdx = Math.min(startIdx + pageSize, totalUsers);
    const pageUsers = userAddresses.slice(startIdx, endIdx);

    return {
      users: pageUsers,
      totalUsers,
      totalPages,
      currentPage: page,
      hasNextPage: page < totalPages - 1,
      hasPreviousPage: page > 0,
    };
  }

  /**
   * Get total number of users
   * @returns Total number of users
   */
  async getTotalUsers(): Promise<number> {
    return this.mockUsers.size;
  }

  /**
   * Get users by type
   * @param userType User type
   * @returns Array of user addresses
   */
  async getUsersByType(userType: UserType): Promise<string[]> {
    const users = Array.from(this.mockUsers.entries())
      .filter(([_, user]) => user.profile.userType === userType)
      .map(([address, _]) => address);

    return users;
  }

  /**
   * Get all user addresses
   * @returns Array of all user addresses
   */
  async getAllUserAddresses(): Promise<string[]> {
    return Array.from(this.mockUsers.keys());
  }

  /**
   * Get user address by index
   * @param index User index
   * @returns User address
   */
  async getUserAddressByIndex(index: number): Promise<string> {
    const userAddresses = Array.from(this.mockUsers.keys());
    if (index < 0 || index >= userAddresses.length) {
      throw new Error(`User index out of range: ${index}`);
    }
    return userAddresses[index];
  }

  // Helper method to generate mock transaction responses
  private mockTransactionResponse(operationId: string): TransactionResponse {
    // Create a more compliant mock transaction response
    const mockTx = {
      hash: ethers.keccak256(
        ethers.toUtf8Bytes(`${operationId}-${Date.now()}`)
      ),
      confirmations: 1,
      from: this.signer
        ? this.signer.getAddress().then((a) => a)
        : "0x0000000000000000000000000000000000000000",
      to: "0x0000000000000000000000000000000000000000",
      data: "0x",
      value: BigInt(0),
      nonce: 0,
      gasLimit: BigInt(100000),
      gasPrice: BigInt(1000000000),
      chainId: 1337,
      blockNumber: 12345678,
      blockHash: ethers.keccak256(ethers.toUtf8Bytes(`block-${Date.now()}`)),
      index: 0,
      type: 0,
      wait: async () => ({
        status: 1,
        blockNumber: 12345678,
        blockHash: ethers.keccak256(ethers.toUtf8Bytes(`block-${Date.now()}`)),
        index: 0,
        logs: [],
        gasUsed: BigInt(50000),
        cumulativeGasUsed: BigInt(50000),
        type: 0,
        from: this.signer
          ? await this.signer.getAddress()
          : "0x0000000000000000000000000000000000000000",
        to: "0x0000000000000000000000000000000000000000",
      }),
    } as unknown as TransactionResponse;

    return mockTx;
  }
}
