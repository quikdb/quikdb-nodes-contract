/**
 * Main gRPC server for QuikDB contracts
 */

import * as grpc from '@grpc/grpc-js';
import * as protoLoader from '@grpc/proto-loader';
import * as path from 'path';
import { config } from './config';
import { logger } from './utils/logger';
import { startMetricsServer, startMetricsCollection } from './utils/monitoring';
import { contractManager } from './contracts';
import { userService } from './services/userService';
import { healthService } from './services/healthService';
import { statsService } from './services/statsService';
import { eventsService } from './services/eventsService';

/**
 * Main gRPC server class
 */
export class QuikDBGrpcServer {
  private server: grpc.Server;
  private isShuttingDown = false;
  private protoPackages: any = {};

  constructor() {
    this.server = new grpc.Server({
      'grpc.max_receive_message_length': config.server.maxReceiveMessageLength,
      'grpc.max_send_message_length': config.server.maxSendMessageLength,
      'grpc.keepalive_time_ms': config.server.keepaliveTimeMs,
      'grpc.keepalive_timeout_ms': config.server.keepaliveTimeoutMs,
      'grpc.keepalive_permit_without_calls': config.server.keepalivePermitWithoutCalls ? 1 : 0,
      'grpc.http2.max_pings_without_data': config.server.http2MaxPingsWithoutData,
      'grpc.http2.min_time_between_pings_ms': config.server.http2MinTimeBetweenPingsMs,
      'grpc.http2.max_ping_strikes': config.server.http2MaxPingStrikes,
    });

    this.loadProtoDefinitions();
    this.setupServices();
    this.setupGracefulShutdown();
  }

  /**
   * Load all proto definitions
   */
  private loadProtoDefinitions(): void {
    const protoDir = path.join(__dirname, '../proto');
    const protoFiles = ['common.proto', 'user.proto', 'node.proto', 'health.proto', 'events.proto', 'stats.proto'];

    for (const protoFile of protoFiles) {
      try {
        const packageDefinition = protoLoader.loadSync(
          path.join(protoDir, protoFile),
          {
            keepCase: true,
            longs: String,
            enums: String,
            defaults: true,
            oneofs: true,
            includeDirs: [protoDir]
          }
        );

        const loaded = grpc.loadPackageDefinition(packageDefinition);
        
        // Merge loaded packages
        Object.assign(this.protoPackages, loaded);
        
        logger.info(`Loaded proto file: ${protoFile}`);
      } catch (error) {
        logger.error(`Failed to load proto file ${protoFile}:`, error);
        throw error;
      }
    }
  }

  /**
   * Setup gRPC services
   */
  private setupServices(): void {
    logger.info('Setting up gRPC services...');

    try {
      // User service
      if (this.protoPackages.quikdb?.user?.UserService?.service) {
        this.server.addService(this.protoPackages.quikdb.user.UserService.service, {
          RegisterUser: userService.registerUser.bind(userService),
          GetUserProfile: userService.getUserProfile.bind(userService),
          UpdateUserProfile: userService.updateUserProfile.bind(userService),
          GetUserStats: userService.getUserStats.bind(userService),
          GetUsers: userService.getUsers.bind(userService),
          StreamUsers: userService.streamUsers.bind(userService),
        });
        logger.info('UserService configured');
      }

      // Health service
      if (this.protoPackages.quikdb?.health?.HealthService?.service) {
        this.server.addService(this.protoPackages.quikdb.health.HealthService.service, {
          HealthCheck: healthService.healthCheck.bind(healthService),
        });
        logger.info('HealthService configured');
      }

      // Stats service
      if (this.protoPackages.quikdb?.stats?.StatsService?.service) {
        this.server.addService(this.protoPackages.quikdb.stats.StatsService.service, {
          GetSystemStats: statsService.getSystemStats.bind(statsService),
        });
        logger.info('StatsService configured');
      }

      // Events service
      if (this.protoPackages.quikdb?.events?.EventService?.service) {
        this.server.addService(this.protoPackages.quikdb.events.EventService.service, {
          StreamEvents: eventsService.streamEvents.bind(eventsService),
        });
        logger.info('EventService configured');
      }

      logger.info('All gRPC services configured successfully');
    } catch (error) {
      logger.error('Failed to setup services:', error);
      throw error;
    }
  }

  /**
   * Setup graceful shutdown handlers
   */
  private setupGracefulShutdown(): void {
    const shutdown = async (signal: string) => {
      if (this.isShuttingDown) {
        return;
      }

      this.isShuttingDown = true;
      logger.info(`Received ${signal}, starting graceful shutdown...`);

      // Stop accepting new requests
      this.server.tryShutdown((error) => {
        if (error) {
          logger.error('Error during server shutdown:', error);
          process.exit(1);
        } else {
          logger.info('gRPC server shut down successfully');
          process.exit(0);
        }
      });

      // Force shutdown after timeout
      setTimeout(() => {
        logger.warn('Force shutting down after timeout');
        process.exit(1);
      }, 30000);
    };

    process.on('SIGTERM', () => shutdown('SIGTERM'));
    process.on('SIGINT', () => shutdown('SIGINT'));
  }

  /**
   * Start the gRPC server
   */
  async start(): Promise<void> {
    try {
      logger.info('Initializing QuikDB gRPC server...');

      // Initialize contract manager
      await contractManager.initialize();
      logger.info('Contract manager initialized');

      // Start monitoring if enabled
      startMetricsCollection();
      startMetricsServer();

      // Test connectivity
      await contractManager.testConnectivity();
      logger.info('Contract connectivity verified');

      // Start server
      const bindAddress = `${config.server.host}:${config.server.port}`;
      
      return new Promise((resolve, reject) => {
        this.server.bindAsync(
          bindAddress,
          grpc.ServerCredentials.createInsecure(),
          (error, port) => {
            if (error) {
              logger.error('Failed to bind server:', error);
              reject(error);
              return;
            }

            logger.info(`QuikDB gRPC server listening on ${bindAddress} (port ${port})`);
            logger.info('Server configuration:', {
              blockchain: {
                network: config.blockchain.networkName,
                rpcUrl: config.blockchain.rpcUrl,
                chainId: config.blockchain.chainId
              },
              cache: {
                enabled: config.cache.enabled,
                ttl: config.cache.ttl
              },
              monitoring: {
                enabled: config.monitoring.enabled,
                port: config.monitoring.metricsPort
              }
            });

            resolve();
          }
        );
      });

    } catch (error) {
      logger.error('Failed to start gRPC server:', error);
      throw error;
    }
  }

  /**
   * Stop the server
   */
  stop(): Promise<void> {
    return new Promise((resolve) => {
      this.server.tryShutdown(() => {
        logger.info('gRPC server stopped');
        resolve();
      });
    });
  }
}

// Start server if this file is run directly
if (require.main === module) {
  const server = new QuikDBGrpcServer();
  
  server.start().catch((error) => {
    logger.error('Failed to start server:', error);
    process.exit(1);
  });
}

export default QuikDBGrpcServer;