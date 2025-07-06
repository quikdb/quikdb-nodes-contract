/**
 * Health service implementation for gRPC
 */

import { sendUnaryData, ServerUnaryCall } from '@grpc/grpc-js';
import { contractManager } from '../contracts';
import { logger } from '../utils/logger';
import * as pb from '../generated/health_pb';

export class HealthServiceImpl {
  
  /**
   * Health check endpoint
   */
  async healthCheck(
    call: ServerUnaryCall<pb.HealthCheckRequest, pb.HealthCheckResponse>,
    callback: sendUnaryData<pb.HealthCheckResponse>
  ): Promise<void> {
    try {
      logger.info('Health check requested');

      const response = new pb.HealthCheckResponse();
      const contracts = contractManager.getContracts();
      
      // Check if contracts are available
      let blockchainStatus = 'disconnected';
      let lastBlockNumber = 0;
      const connectedContracts: string[] = [];

      try {
        if (contracts) {
          // Try to get current block number
          const provider = contractManager.getProvider();
          if (provider) {
            lastBlockNumber = await provider.getBlockNumber();
            blockchainStatus = 'connected';
          }

          // List connected contracts
          if (contracts.userLogic) connectedContracts.push('UserLogic');
          if (contracts.userStorage) connectedContracts.push('UserStorage');
          if (contracts.nodeLogic) connectedContracts.push('NodeLogic');
          if (contracts.nodeStorage) connectedContracts.push('NodeStorage');
          if (contracts.resourceLogic) connectedContracts.push('ResourceLogic');
          if (contracts.resourceStorage) connectedContracts.push('ResourceStorage');
        }
      } catch (error) {
        logger.warn('Blockchain connection check failed:', error);
        blockchainStatus = 'error';
      }

      // Build response
      response.setHealthy(blockchainStatus === 'connected');
      response.setVersion('1.0.0');
      response.setTimestamp(Date.now());
      response.setBlockchainStatus(blockchainStatus);
      response.setLastBlockNumber(lastBlockNumber);
      response.setConnectedContractsList(connectedContracts);

      callback(null, response);

    } catch (error: any) {
      logger.error('Health check failed:', error);
      
      const response = new pb.HealthCheckResponse();
      response.setHealthy(false);
      response.setVersion('1.0.0');
      response.setTimestamp(Date.now());
      response.setBlockchainStatus('error');
      response.setLastBlockNumber(0);
      response.setConnectedContractsList([]);

      callback(null, response);
    }
  }
}

export const healthService = new HealthServiceImpl();
