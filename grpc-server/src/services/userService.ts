/**
 * User service implementation for gRPC
 */

import {
  sendUnaryData,
  ServerUnaryCall,
  ServerWritableStream,
} from "@grpc/grpc-js";
import { contractManager } from "../contracts";
import { logger } from "../utils/logger";
import { cache } from "../utils/cache";
import * as pb from "../generated/user_pb";
import * as commonPb from "../generated/common_pb";

export class UserServiceImpl {
  /**
   * Register a new user
   */
  async registerUser(
    call: ServerUnaryCall<pb.RegisterUserRequest, pb.RegisterUserResponse>,
    callback: sendUnaryData<pb.RegisterUserResponse>
  ): Promise<void> {
    try {
      const request = call.request;
      const contracts = contractManager.getContracts();

      if (!contractManager.hasWriteAccess()) {
        return callback(
          new Error("Write operations not available - no signer configured")
        );
      }

      // Handle both generated protobuf objects and dynamic objects
      const userAddress =
        typeof request.getUserAddress === "function"
          ? request.getUserAddress()
          : (request as any).user_address;
      let userType =
        typeof request.getUserType === "function"
          ? request.getUserType()
          : (request as any).user_type;
      const profileHash =
        typeof request.getProfileHash === "function"
          ? request.getProfileHash()
          : (request as any).profile_hash;

      // Convert enum string to number if needed
      if (typeof userType === "string") {
        const enumMap: { [key: string]: number } = {
          USER_TYPE_CONSUMER: 0,
          USER_TYPE_PROVIDER: 1,
          USER_TYPE_HYBRID: 2,
          USER_TYPE_ENTERPRISE: 3,
        };
        userType = enumMap[userType] ?? 0;
      }

      logger.info("Registering user", {
        userAddress,
        userType,
        profileHash,
      });

      // Call smart contract
      const tx = await contracts.userLogic.registerUser(
        userAddress,
        profileHash,
        userType
      );

      const receipt = await tx.wait();

      // Create response as plain object (compatible with dynamic proto loading)
      const response = {
        success: true,
        message: "User registered successfully",
        transaction_hash: receipt.hash,
      };

      console.log("📤 SERVER: Sending success response:", response);

      // Invalidate cache
      cache.flushAll();

      callback(null, response as any);
    } catch (error: any) {
      console.log("❌ Registration failed:", error.reason || error.message);

      logger.error("Failed to register user:", error);

      // Extract clean error message
      let errorMessage = "Unknown error";
      if (error.reason) {
        errorMessage = error.reason;
      } else if (
        error.message &&
        error.message.includes("User already registered")
      ) {
        errorMessage = "User already registered";
      } else if (error.message) {
        errorMessage =
          error.message.length > 100
            ? error.message.substring(0, 100) + "..."
            : error.message;
      }

      // Create response as plain object (compatible with dynamic proto loading)
      const response = {
        success: false,
        message: errorMessage,
        transaction_hash: "",
      };

      console.log("📤 SERVER: Sending error response:", response);

      callback(null, response as any);
    }
  }

  /**
   * Get user profile
   */
  async getUserProfile(
    call: ServerUnaryCall<pb.GetUserProfileRequest, pb.GetUserProfileResponse>,
    callback: sendUnaryData<pb.GetUserProfileResponse>
  ): Promise<void> {
    try {
      const request = call.request;

      // Handle both generated protobuf objects and dynamic objects
      const userAddress =
        typeof request.getUserAddress === "function"
          ? request.getUserAddress()
          : (request as any).user_address;

      const cacheKey = `user:${userAddress}`;

      // Check cache first
      const cached = cache.get<any>(cacheKey);
      if (cached) {
        return callback(null, cached);
      }

      const contracts = contractManager.getContracts();

      logger.info("Getting user profile", { userAddress });

      // Call smart contract
      const userProfile = await contracts.userLogic.getUserProfile(userAddress);

      // Create response as plain object (compatible with dynamic proto loading)
      const response = {
        profile: {
          profile_hash: userProfile.profileHash,
          user_type: userProfile.userType,
          is_active: userProfile.isActive || true,
          created_at: Number(userProfile.registeredAt) || 0,
          updated_at: Number(userProfile.updatedAt) || 0,
          total_spent: userProfile.totalSpent?.toString() || "0",
          total_earned: userProfile.totalEarned?.toString() || "0",
          reputation_score: userProfile.reputationScore || 0,
          is_verified: userProfile.isVerified || false,
        },
      };

      console.log("📤 SERVER: Sending user profile response:", response);

      // Cache the response
      cache.set(cacheKey, response);

      callback(null, response as any);
    } catch (error: any) {
      logger.error("Failed to get user profile:", error);
      callback(new Error(`Failed to get user profile: ${error.message}`));
    }
  }

  /**
   * Update user profile
   */
  async updateUserProfile(
    call: ServerUnaryCall<
      pb.UpdateUserProfileRequest,
      pb.UpdateUserProfileResponse
    >,
    callback: sendUnaryData<pb.UpdateUserProfileResponse>
  ): Promise<void> {
    try {
      const request = call.request;
      const contracts = contractManager.getContracts();

      if (!contractManager.hasWriteAccess()) {
        return callback(
          new Error("Write operations not available - no signer configured")
        );
      }

      // Handle both generated protobuf and dynamic proto request fields
      const userAddress = request.getUserAddress
        ? request.getUserAddress()
        : (request as any).user_address;
      const profileHash = request.getProfileHash
        ? request.getProfileHash()
        : (request as any).profile_hash;

      logger.info("Updating user profile", {
        userAddress,
        profileHash,
      });

      // Call smart contract
      const tx = await contracts.userLogic.updateUserProfile(
        userAddress,
        profileHash
      );

      const receipt = await tx.wait();

      // Create plain response object for dynamic proto compatibility
      const response = {
        success: true,
        message: "User profile updated successfully",
        transaction_hash: receipt.hash,
      };

      logger.info("User profile update successful", response);

      // Invalidate cache for this user
      cache.del(`user:${userAddress}`);

      callback(null, response as any);
    } catch (error: any) {
      logger.error("Failed to update user profile:", error);
      const response = {
        success: false,
        message: error.message || "Unknown error",
        transaction_hash: "",
      };
      callback(null, response as any);
    }
  }

  /**
   * Get user statistics
   */
  async getUserStats(
    call: ServerUnaryCall<pb.GetUserStatsRequest, pb.GetUserStatsResponse>,
    callback: sendUnaryData<pb.GetUserStatsResponse>
  ): Promise<void> {
    try {
      const cacheKey = "user:stats";

      // Check cache first
      const cached = cache.get<any>(cacheKey);
      if (cached) {
        return callback(null, cached);
      }

      const contracts = contractManager.getContracts();
      logger.info("Getting user stats");

      // Get stats from smart contract
      const totalUsers = await contracts.userStorage.getTotalUsers();

      // Create response as plain object (compatible with dynamic proto loading)
      const response = {
        stats: {
          total_users: Number(totalUsers),
        },
      };

      console.log("📤 SERVER: Sending user stats response:", response);

      // Cache the response
      cache.set(cacheKey, response);

      callback(null, response as any);
    } catch (error: any) {
      logger.error("Failed to get user stats:", error);
      callback(new Error(`Failed to get user stats: ${error.message}`));
    }
  }

  /**
   * Get multiple users with pagination
   */
  async getUsers(
    call: ServerUnaryCall<pb.GetUsersRequest, pb.GetUsersResponse>,
    callback: sendUnaryData<pb.GetUsersResponse>
  ): Promise<void> {
    try {
      const request = call.request;

      // Handle both generated protobuf and dynamic proto request fields
      const pagination = request.getPagination
        ? request.getPagination()
        : (request as any).pagination;

      const page = pagination?.getPage
        ? pagination.getPage()
        : pagination?.page || 0;
      const limit = Math.min(
        pagination?.getLimit ? pagination.getLimit() : pagination?.limit || 50,
        100
      ); // Cap at 100
      const offset = page * limit;

      const typeFilter = request.getTypeFilter
        ? request.getTypeFilter()
        : (request as any).type_filter;
      const verifiedOnly = request.getVerifiedOnly
        ? request.getVerifiedOnly()
        : (request as any).verified_only;
      const activeOnly = request.getActiveOnly
        ? request.getActiveOnly()
        : (request as any).active_only;

      const cacheKey = `users:${page}:${limit}:${typeFilter}:${verifiedOnly}:${activeOnly}`;

      // Check cache first
      const cached = cache.get<pb.GetUsersResponse>(cacheKey);
      if (cached) {
        return callback(null, cached);
      }

      const contracts = contractManager.getContracts();
      logger.info("Getting users", {
        page,
        limit,
        typeFilter,
        verifiedOnly,
        activeOnly,
      });

      // Get total count
      const totalCount = await contracts.userStorage.getTotalUsers();

      // Get users (simplified implementation)
      const users: any[] = [];
      const actualLimit = Math.min(limit, Number(totalCount) - offset);

      for (
        let i = offset;
        i < offset + actualLimit && i < Number(totalCount);
        i++
      ) {
        try {
          // This assumes you have a way to get user addresses by index
          const userAddresses = await contracts.userStorage.getUserAddresses?.(
            i,
            1
          );
          if (userAddresses && userAddresses.length > 0) {
            const userProfile = await contracts.userLogic.getUserProfile(
              userAddresses[0]
            );

            // Apply filters
            if (
              typeFilter !== pb.UserType.USER_TYPE_CONSUMER &&
              userProfile.userType !== typeFilter
            ) {
              continue;
            }
            if (verifiedOnly && !userProfile.isVerified) {
              continue;
            }
            if (activeOnly && !userProfile.isActive) {
              continue;
            }

            // Create plain profile object for dynamic proto compatibility
            const profile = {
              profile_hash: userProfile.profileHash,
              user_type: userProfile.userType,
              is_active: userProfile.isActive || true,
              created_at: Number(userProfile.registeredAt) || 0,
              updated_at: Number(userProfile.updatedAt) || 0,
              total_spent: userProfile.totalSpent?.toString() || "0",
              total_earned: userProfile.totalEarned?.toString() || "0",
              reputation_score: userProfile.reputationScore || 0,
              is_verified: userProfile.isVerified || false,
            };

            users.push(profile);
          }
        } catch (error) {
          // Skip users that can't be retrieved
          logger.warn(`Failed to get user at index ${i}:`, error);
        }
      }

      // Create response as plain object for dynamic proto compatibility
      const response = {
        users_list: users,
        pagination: {
          page: page,
          limit: limit,
          total_items: Number(totalCount),
          total_pages: Math.ceil(Number(totalCount) / limit),
          has_next: offset + limit < Number(totalCount),
          has_previous: page > 0,
        },
      };

      console.log("📤 SERVER: Sending users response:", {
        usersCount: users.length,
        pagination: response.pagination,
      });

      // Cache the response
      cache.set(cacheKey, response);

      callback(null, response as any);
    } catch (error: any) {
      logger.error("Failed to get users:", error);
      callback(new Error(`Failed to get users: ${error.message}`));
    }
  }

  /**
   * Stream users (for large datasets)
   */
  async streamUsers(
    call: ServerWritableStream<pb.StreamUsersRequest, pb.StreamUsersResponse>
  ): Promise<void> {
    try {
      const request = call.request;

      // Handle both generated protobuf and dynamic proto request fields
      const batchSize = Math.min(
        request.getBatchSize
          ? request.getBatchSize()
          : (request as any).batch_size || 10,
        50
      ); // Cap at 50 per batch
      const typeFilter = request.getTypeFilter
        ? request.getTypeFilter()
        : (request as any).type_filter;
      const verifiedOnly = request.getVerifiedOnly
        ? request.getVerifiedOnly()
        : (request as any).verified_only;
      const activeOnly = request.getActiveOnly
        ? request.getActiveOnly()
        : (request as any).active_only;

      const contracts = contractManager.getContracts();
      logger.info("Streaming users", {
        batchSize,
        typeFilter,
        verifiedOnly,
        activeOnly,
      });

      // Get users by type instead of trying to paginate all users
      let allUserAddresses: string[] = [];
      let actualTypeFilter: number | undefined;

      if (typeFilter !== undefined && typeFilter !== null) {
        // Get users of specific type (ensure it's a number)
        let numericTypeFilter = typeFilter;

        // Handle string enum names
        if (typeof typeFilter === "string") {
          const enumMap: { [key: string]: number } = {
            USER_TYPE_CONSUMER: 0,
            USER_TYPE_PROVIDER: 1,
            USER_TYPE_HYBRID: 2, // Maps to MARKETPLACE_ADMIN
            USER_TYPE_ENTERPRISE: 3, // Maps to PLATFORM_ADMIN
          };
          numericTypeFilter =
            enumMap[typeFilter] !== undefined
              ? enumMap[typeFilter]
              : parseInt(typeFilter);
        }

        actualTypeFilter = numericTypeFilter;
        logger.info(`Getting users of type ${numericTypeFilter}`);
        allUserAddresses = await contracts.userStorage.getUsersByType(
          numericTypeFilter
        );
      } else {
        // Get all users by combining all types
        const types = [0, 1, 2, 3]; // CONSUMER, PROVIDER, MARKETPLACE_ADMIN, PLATFORM_ADMIN
        for (const type of types) {
          const usersOfType = await contracts.userStorage.getUsersByType(type);
          allUserAddresses = allUserAddresses.concat(usersOfType);
        }
      }

      logger.info(`Found ${allUserAddresses.length} users to stream`);
      let processed = 0;

      for (
        let offset = 0;
        offset < allUserAddresses.length;
        offset += batchSize
      ) {
        // Check if client cancelled
        if (call.cancelled || call.destroyed) {
          logger.info("Client cancelled streaming users");
          break;
        }

        const users: any[] = [];

        try {
          // Get batch of user addresses from the collected list
          for (
            let i = offset;
            i < Math.min(offset + batchSize, allUserAddresses.length);
            i++
          ) {
            try {
              const userAddress = allUserAddresses[i];
              if (userAddress) {
                const userProfile = await contracts.userLogic.getUserProfile(
                  userAddress
                );

                // Apply filters - only include users that match the type filter
                if (
                  actualTypeFilter !== undefined &&
                  actualTypeFilter !== null &&
                  Number(userProfile.userType) !== Number(actualTypeFilter)
                ) {
                  continue;
                }
                if (verifiedOnly && !userProfile.isVerified) {
                  continue;
                }
                if (activeOnly && !userProfile.isActive) {
                  continue;
                }

                // Create plain profile object for dynamic proto compatibility
                const profile = {
                  profile_hash: userProfile.profileHash,
                  user_type: userProfile.userType,
                  is_active: userProfile.isActive || true,
                  created_at: Number(userProfile.registeredAt) || 0,
                  updated_at: Number(userProfile.updatedAt) || 0,
                  total_spent: userProfile.totalSpent?.toString() || "0",
                  total_earned: userProfile.totalEarned?.toString() || "0",
                  reputation_score: userProfile.reputationScore || 0,
                  is_verified: userProfile.isVerified || false,
                };

                users.push(profile);
                processed++;
              }
            } catch (error) {
              logger.warn(`Failed to stream user at index ${i}:`, error);
            }
          }

          // Send batch if we have users
          if (users.length > 0) {
            const response = {
              users: users,
              is_final_batch: offset + batchSize >= allUserAddresses.length,
              total_sent: processed,
            };

            call.write(response as any);
          }
        } catch (error) {
          logger.error(`Failed to get users batch at offset ${offset}:`, error);
        }

        // Small delay to prevent overwhelming the client
        await new Promise((resolve) => setTimeout(resolve, 10));
      }

      logger.info(`Finished streaming ${processed} users`);
      call.end();
    } catch (error: any) {
      logger.error("Failed to stream users:", error);
      call.destroy(new Error(`Failed to stream users: ${error.message}`));
    }
  }
}

export const userService = new UserServiceImpl();
