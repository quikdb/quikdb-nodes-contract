/**
 * Stats service implementation for gRPC
 */

import { sendUnaryData, ServerUnaryCall } from '@grpc/grpc-js';
import { contractManager } from '../contracts';
import { logger } from '../utils/logger';
import { cache } from '../utils/cache';
import * as pb from '../generated/stats_pb';
import * as userPb from '../generated/user_pb';
import * as nodePb from '../generated/node_pb';

export class StatsServiceImpl {
  
  /**
   * Get system statistics
   */
  async getSystemStats(
    call: ServerUnaryCall<pb.GetSystemStatsRequest, pb.GetSystemStatsResponse>,
    callback: sendUnaryData<pb.GetSystemStatsResponse>
  ): Promise<void> {
    try {
      const cacheKey = 'system:stats';
      
      // Check cache first
      const cached = cache.get<pb.GetSystemStatsResponse>(cacheKey);
      if (cached) {
        return callback(null, cached);
      }

      const contracts = contractManager.getContracts();
      logger.info('Getting system stats');

      // Get stats from smart contracts
      const totalUsers = await contracts.userStorage.getTotalUsers();
      const totalNodes = await contracts.nodeStorage.getTotalNodes();

      // For now, we'll use placeholder values for some stats
      // In a real implementation, you'd track these in your contracts
      const totalTransactions = 0;
      const totalVolume = 0;

      // Create response
      const response = new pb.GetSystemStatsResponse();
      const stats = new pb.SystemStats();

      // User stats
      const userStats = new userPb.UserStats();
      userStats.setTotalUsers(Number(totalUsers));
      stats.setUserStats(userStats);

      // Node stats
      const nodeStats = new nodePb.NodeStats();
      nodeStats.setTotalNodes(Number(totalNodes));
      nodeStats.setActiveNodes(0); // Would need to query contract for active nodes
      nodeStats.setListedNodes(0); // Would need to query contract for listed nodes
      nodeStats.setVerifiedNodes(0); // Would need to query contract for verified nodes
      stats.setNodeStats(nodeStats);

      // System stats
      stats.setTotalTransactions(totalTransactions);
      stats.setTotalVolume(totalVolume);
      stats.setLastUpdated(Date.now());
      
      response.setStats(stats);

      // Cache the response
      cache.set(cacheKey, response, 60); // Cache for 1 minute

      callback(null, response);

    } catch (error: any) {
      logger.error('Failed to get system stats:', error);
      callback(new Error(`Failed to get system stats: ${error.message}`));
    }
  }
}

export const statsService = new StatsServiceImpl();
