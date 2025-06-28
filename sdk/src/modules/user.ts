import { ethers } from "ethers";
import { BaseModule, TransactionResponse } from "../types/common.types";
import {
  UserProfile,
  UserPreferences,
  UserStats,
  UserInfo,
  UserType,
} from "../types/user.types";
import UserStorageABI from "../abis/UserStorage.json";

export class UserModule implements BaseModule {
  private provider: ethers.Provider;
  private contract: ethers.Contract;
  private signer?: ethers.Signer;

  /**
   * Initialize the User module
   * @param provider Ethers provider
   * @param contractAddress Address of the UserStorage contract
   * @param signer Optional signer for transactions
   */
  constructor(
    provider: ethers.Provider,
    contractAddress: string,
    signer?: ethers.Signer
  ) {
    this.provider = provider;
    this.contract = new ethers.Contract(
      contractAddress,
      UserStorageABI.abi,
      provider
    );

    if (signer) {
      this.signer = signer;
      this.contract = this.contract.connect(signer) as ethers.Contract;
    }
  }

  /**
   * Connect to a new provider
   * @param provider Ethers provider
   */
  connect(provider: ethers.Provider): void {
    this.provider = provider;
    this.contract = this.contract.connect(provider) as ethers.Contract;

    if (this.signer) {
      this.signer = this.signer.connect(provider);
      this.contract = this.contract.connect(this.signer) as ethers.Contract;
    }
  }

  /**
   * Set a new signer for transactions
   * @param signer Ethers signer
   */
  setSigner(signer: ethers.Signer): void {
    this.signer = signer;
    this.contract = this.contract.connect(signer) as ethers.Contract;
  }

  /**
   * Get user profile
   * @param userAddress Address of the user
   * @returns User profile
   */
  async getUserProfile(userAddress: string): Promise<UserProfile> {
    return await this.contract.getUserProfile(userAddress);
  }

  /**
   * Get complete user information
   * @param userAddress Address of the user
   * @returns Complete user info
   */
  async getUserInfo(userAddress: string): Promise<UserInfo> {
    return await this.contract.getUserInfo(userAddress);
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

    // Convert string to bytes32 if needed
    const hash =
      profileHash.startsWith("0x") && profileHash.length === 66
        ? profileHash
        : ethers.encodeBytes32String(profileHash);

    return await this.contract.registerUser(userAddress, hash, userType);
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

    // Convert string to bytes32 if needed
    const hash =
      profileHash.startsWith("0x") && profileHash.length === 66
        ? profileHash
        : ethers.encodeBytes32String(profileHash);

    return await this.contract.updateUserProfile(userAddress, hash);
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

    return await this.contract.updateUserPreferences(userAddress, preferences);
  }

  /**
   * Get user stats
   * @param userAddress Address of the user
   * @returns User stats
   */
  async getUserStats(userAddress: string): Promise<UserStats> {
    return await this.contract.getUserStats(userAddress);
  }

  /**
   * Get total number of users
   * @returns Total number of users
   */
  async getTotalUsers(): Promise<number> {
    return await this.contract.getTotalUsers();
  }

  /**
   * Get users by type
   * @param userType User type
   * @returns Array of user addresses
   */
  async getUsersByType(userType: UserType): Promise<string[]> {
    return await this.contract.getUsersByType(userType);
  }
}
