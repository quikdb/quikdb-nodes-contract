/**
 * User service implementation for gRPC
 */

import { sendUnaryData, ServerUnaryCall, ServerWritableStream } from '@grpc/grpc-js';
import { contractManager } from '../contracts';
import { logger } from '../utils/logger';
import { cache } from '../utils/cache';
import * as pb from '../generated/user_pb';
import * as commonPb from '../generated/common_pb';

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
        return callback(new Error('Write operations not available - no signer configured'));
      }

      logger.info('Registering user', {
        userAddress: request.getUserAddress(),
        userType: request.getUserType(),
        profileHash: request.getProfileHash()
      });

      // Call smart contract
      const tx = await contracts.userLogic.registerUser(
        request.getUserAddress(),
        request.getProfileHash(),
        request.getUserType()
      );

      const receipt = await tx.wait();

      // Create response
      const response = new pb.RegisterUserResponse();
      response.setSuccess(true);
      response.setMessage('User registered successfully');
      response.setTransactionHash(receipt.hash);

      // Invalidate cache
      cache.flushAll();

      callback(null, response);

    } catch (error: any) {
      logger.error('Failed to register user:', error);
      const response = new pb.RegisterUserResponse();
      response.setSuccess(false);
      response.setMessage(error.message || 'Unknown error');
      callback(null, response);
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
      const userAddress = request.getUserAddress();
      const cacheKey = `user:${userAddress}`;

      // Check cache first
      const cached = cache.get<pb.GetUserProfileResponse>(cacheKey);
      if (cached) {
        return callback(null, cached);
      }

      const contracts = contractManager.getContracts();

      logger.info('Getting user profile', { userAddress });

      // Call smart contract
      const userProfile = await contracts.userLogic.getUserProfile(userAddress);

      // Create response
      const response = new pb.GetUserProfileResponse();
      
      // Create UserProfile message
      const profileMsg = new pb.UserProfile();
      profileMsg.setProfileHash(userProfile.profileHash);
      profileMsg.setUserType(userProfile.userType);
      profileMsg.setIsActive(userProfile.isActive || true);
      profileMsg.setCreatedAt(Number(userProfile.registeredAt) || 0);
      profileMsg.setUpdatedAt(Number(userProfile.updatedAt) || 0);
      profileMsg.setTotalSpent(userProfile.totalSpent?.toString() || '0');
      profileMsg.setTotalEarned(userProfile.totalEarned?.toString() || '0');
      profileMsg.setReputationScore(userProfile.reputationScore || 0);
      profileMsg.setIsVerified(userProfile.isVerified || false);

      response.setProfile(profileMsg);

      // Cache the response
      cache.set(cacheKey, response);

      callback(null, response);

    } catch (error: any) {
      logger.error('Failed to get user profile:', error);
      callback(new Error(`Failed to get user profile: ${error.message}`));
    }
  }

  /**
   * Update user profile
   */
  async updateUserProfile(
    call: ServerUnaryCall<pb.UpdateUserProfileRequest, pb.UpdateUserProfileResponse>,
    callback: sendUnaryData<pb.UpdateUserProfileResponse>
  ): Promise<void> {
    try {
      const request = call.request;
      const contracts = contractManager.getContracts();

      if (!contractManager.hasWriteAccess()) {
        return callback(new Error('Write operations not available - no signer configured'));
      }

      logger.info('Updating user profile', {
        userAddress: request.getUserAddress(),
        profileHash: request.getProfileHash()
      });

      // Call smart contract
      const tx = await contracts.userLogic.updateUserProfile(
        request.getUserAddress(),
        request.getProfileHash()
      );

      const receipt = await tx.wait();

      // Create response
      const response = new pb.UpdateUserProfileResponse();
      response.setSuccess(true);
      response.setMessage('User profile updated successfully');
      response.setTransactionHash(receipt.hash);

      // Invalidate cache for this user
      cache.del(`user:${request.getUserAddress()}`);

      callback(null, response);

    } catch (error: any) {
      logger.error('Failed to update user profile:', error);
      const response = new pb.UpdateUserProfileResponse();
      response.setSuccess(false);
      response.setMessage(error.message || 'Unknown error');
      callback(null, response);
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
      const cacheKey = 'user:stats';
      
      // Check cache first
      const cached = cache.get<pb.GetUserStatsResponse>(cacheKey);
      if (cached) {
        return callback(null, cached);
      }

      const contracts = contractManager.getContracts();
      logger.info('Getting user stats');

      // Get stats from smart contract
      const totalUsers = await contracts.userStorage.getTotalUsers();

      // Create response
      const response = new pb.GetUserStatsResponse();
      const stats = new pb.UserStats();
      stats.setTotalUsers(Number(totalUsers));
      
      response.setStats(stats);

      // Cache the response
      cache.set(cacheKey, response);

      callback(null, response);

    } catch (error: any) {
      logger.error('Failed to get user stats:', error);
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
      const pagination = request.getPagination();
      
      const page = pagination?.getPage() || 0;
      const limit = Math.min(pagination?.getLimit() || 50, 100); // Cap at 100
      const offset = page * limit;
      
      const typeFilter = request.getTypeFilter();
      const verifiedOnly = request.getVerifiedOnly();
      const activeOnly = request.getActiveOnly();

      const cacheKey = `users:${page}:${limit}:${typeFilter}:${verifiedOnly}:${activeOnly}`;
      
      // Check cache first
      const cached = cache.get<pb.GetUsersResponse>(cacheKey);
      if (cached) {
        return callback(null, cached);
      }

      const contracts = contractManager.getContracts();
      logger.info('Getting users', { page, limit, typeFilter, verifiedOnly, activeOnly });

      // Get total count
      const totalCount = await contracts.userStorage.getTotalUsers();

      // Get users (simplified implementation)
      const users: pb.UserProfile[] = [];
      const actualLimit = Math.min(limit, Number(totalCount) - offset);

      for (let i = offset; i < offset + actualLimit && i < Number(totalCount); i++) {
        try {
          // This assumes you have a way to get user addresses by index
          const userAddresses = await contracts.userStorage.getUserAddresses?.(i, 1);
          if (userAddresses && userAddresses.length > 0) {
            const userProfile = await contracts.userLogic.getUserProfile(userAddresses[0]);
            
            // Apply filters
            if (typeFilter !== pb.UserType.USER_TYPE_CONSUMER && userProfile.userType !== typeFilter) {
              continue;
            }
            if (verifiedOnly && !userProfile.isVerified) {
              continue;
            }
            if (activeOnly && !userProfile.isActive) {
              continue;
            }

            const profile = new pb.UserProfile();
            profile.setProfileHash(userProfile.profileHash);
            profile.setUserType(userProfile.userType);
            profile.setIsActive(userProfile.isActive || true);
            profile.setCreatedAt(Number(userProfile.registeredAt) || 0);
            profile.setUpdatedAt(Number(userProfile.updatedAt) || 0);
            profile.setTotalSpent(userProfile.totalSpent?.toString() || '0');
            profile.setTotalEarned(userProfile.totalEarned?.toString() || '0');
            profile.setReputationScore(userProfile.reputationScore || 0);
            profile.setIsVerified(userProfile.isVerified || false);

            users.push(profile);
          }
        } catch (error) {
          // Skip users that can't be retrieved
          logger.warn(`Failed to get user at index ${i}:`, error);
        }
      }

      // Create response
      const response = new pb.GetUsersResponse();
      response.setUsersList(users);
      
      // Create pagination response
      const paginationResponse = new commonPb.PaginationResponse();
      paginationResponse.setPage(page);
      paginationResponse.setLimit(limit);
      paginationResponse.setTotalItems(Number(totalCount));
      paginationResponse.setTotalPages(Math.ceil(Number(totalCount) / limit));
      paginationResponse.setHasNext(offset + limit < Number(totalCount));
      paginationResponse.setHasPrevious(page > 0);
      
      response.setPagination(paginationResponse);

      // Cache the response
      cache.set(cacheKey, response);

      callback(null, response);

    } catch (error: any) {
      logger.error('Failed to get users:', error);
      callback(new Error(`Failed to get users: ${error.message}`));
    }
  }

  /**
   * Stream users (for large datasets)
   */
  async streamUsers(call: ServerWritableStream<pb.StreamUsersRequest, pb.StreamUsersResponse>): Promise<void> {
    try {
      const request = call.request;
      const batchSize = Math.min(request.getBatchSize() || 10, 50); // Cap at 50 per batch
      const typeFilter = request.getTypeFilter();
      const verifiedOnly = request.getVerifiedOnly();
      const activeOnly = request.getActiveOnly();

      const contracts = contractManager.getContracts();
      logger.info('Streaming users', { batchSize, typeFilter, verifiedOnly, activeOnly });

      const totalCount = await contracts.userStorage.getTotalUsers();
      let processed = 0;

      for (let offset = 0; offset < Number(totalCount); offset += batchSize) {
        // Check if client cancelled
        if (call.cancelled || call.destroyed) {
          logger.info('Client cancelled streaming users');
          break;
        }

        const users: pb.UserProfile[] = [];

        try {
          // Get batch of user addresses (if available in your contract)
          for (let i = offset; i < Math.min(offset + batchSize, Number(totalCount)); i++) {
            try {
              // This assumes you have a way to get user addresses
              const userAddresses = await contracts.userStorage.getUserAddresses?.(i, 1);
              if (userAddresses && userAddresses.length > 0) {
                const userProfile = await contracts.userLogic.getUserProfile(userAddresses[0]);
                
                // Apply filters
                if (typeFilter !== pb.UserType.USER_TYPE_CONSUMER && userProfile.userType !== typeFilter) {
                  continue;
                }
                if (verifiedOnly && !userProfile.isVerified) {
                  continue;
                }
                if (activeOnly && !userProfile.isActive) {
                  continue;
                }

                const profile = new pb.UserProfile();
                profile.setProfileHash(userProfile.profileHash);
                profile.setUserType(userProfile.userType);
                profile.setIsActive(userProfile.isActive || true);
                profile.setCreatedAt(Number(userProfile.registeredAt) || 0);
                profile.setUpdatedAt(Number(userProfile.updatedAt) || 0);
                profile.setTotalSpent(userProfile.totalSpent?.toString() || '0');
                profile.setTotalEarned(userProfile.totalEarned?.toString() || '0');
                profile.setReputationScore(userProfile.reputationScore || 0);
                profile.setIsVerified(userProfile.isVerified || false);

                users.push(profile);
                processed++;
              }
            } catch (error) {
              logger.warn(`Failed to stream user at index ${i}:`, error);
            }
          }

          // Send batch if we have users
          if (users.length > 0) {
            const response = new pb.StreamUsersResponse();
            response.setUsersList(users);
            response.setIsFinalBatch(offset + batchSize >= Number(totalCount));
            response.setTotalSent(processed);
            
            call.write(response);
          }
        } catch (error) {
          logger.error(`Failed to get users batch at offset ${offset}:`, error);
        }

        // Small delay to prevent overwhelming the client
        await new Promise(resolve => setTimeout(resolve, 10));
      }

      logger.info(`Finished streaming ${processed} users`);
      call.end();

    } catch (error: any) {
      logger.error('Failed to stream users:', error);
      call.destroy(new Error(`Failed to stream users: ${error.message}`));
    }
  }
}

export const userService = new UserServiceImpl();
