import * as dotenv from 'dotenv';

// Load environment variables
dotenv.config();

export interface Config {
  // Server configuration
  server: {
    port: number;
    host: string;
    maxReceiveMessageLength: number;
    maxSendMessageLength: number;
    keepaliveTimeMs: number;
    keepaliveTimeoutMs: number;
    keepalivePermitWithoutCalls: boolean;
    http2MaxPingsWithoutData: number;
    http2MinTimeBetweenPingsMs: number;
    http2MaxPingStrikes: number;
  };

  // Blockchain configuration
  blockchain: {
    rpcUrl: string;
    chainId: number;
    networkName: string;
    privateKey?: string;
    gasLimit: number;
    gasPrice: string;
    maxGasPrice: string;
    confirmations: number;
    timeout: number;
  };

  // Contract addresses
  contracts: {
    nodeLogic: string;
    userLogic: string;
    resourceLogic: string;
    facade: string;
    nodeStorage: string;
    userStorage: string;
    resourceStorage: string;
  };

  // Caching configuration
  cache: {
    enabled: boolean;
    ttl: number; // TTL in seconds
    maxKeys: number;
    checkPeriod: number;
  };

  // Rate limiting configuration
  rateLimit: {
    enabled: boolean;
    points: number; // Number of requests
    duration: number; // Per duration in seconds
    blockDuration: number; // Block duration in seconds
  };

  // Logging configuration
  logging: {
    level: string;
    format: string;
    colorize: boolean;
    timestamp: boolean;
    filename?: string;
    maxsize: number;
    maxFiles: number;
  };

  // Monitoring configuration
  monitoring: {
    enabled: boolean;
    metricsPort: number;
    healthCheckInterval: number;
  };

  // Redis configuration (for rate limiting and caching)
  redis: {
    host: string;
    port: number;
    password?: string;
    db: number;
    keyPrefix: string;
    maxRetriesPerRequest: number;
    retryDelayOnFailover: number;
    enableReadyCheck: boolean;
    lazyConnect: boolean;
  };

  // Streaming configuration
  streaming: {
    defaultBatchSize: number;
    maxBatchSize: number;
    eventBufferSize: number;
    heartbeatInterval: number;
  };

  // Environment
  env: 'development' | 'staging' | 'production';
}

const config: Config = {
  server: {
    port: parseInt(process.env.GRPC_PORT || '50051', 10),
    host: process.env.GRPC_HOST || '0.0.0.0',
    maxReceiveMessageLength: parseInt(process.env.MAX_RECEIVE_MESSAGE_LENGTH || '4194304', 10), // 4MB
    maxSendMessageLength: parseInt(process.env.MAX_SEND_MESSAGE_LENGTH || '4194304', 10), // 4MB
    keepaliveTimeMs: parseInt(process.env.KEEPALIVE_TIME_MS || '30000', 10), // 30 seconds
    keepaliveTimeoutMs: parseInt(process.env.KEEPALIVE_TIMEOUT_MS || '10000', 10), // 10 seconds
    keepalivePermitWithoutCalls: process.env.KEEPALIVE_PERMIT_WITHOUT_CALLS === 'true',
    http2MaxPingsWithoutData: parseInt(process.env.HTTP2_MAX_PINGS_WITHOUT_DATA || '0', 10),
    http2MinTimeBetweenPingsMs: parseInt(process.env.HTTP2_MIN_TIME_BETWEEN_PINGS_MS || '10000', 10),
    http2MaxPingStrikes: parseInt(process.env.HTTP2_MAX_PING_STRIKES || '2', 10),
  },

  blockchain: {
    rpcUrl: process.env.RPC_URL || 'http://localhost:8545',
    chainId: parseInt(process.env.CHAIN_ID || '31337', 10),
    networkName: process.env.NETWORK_NAME || 'localhost',
    privateKey: process.env.PRIVATE_KEY,
    gasLimit: parseInt(process.env.GAS_LIMIT || '500000', 10),
    gasPrice: process.env.GAS_PRICE || '20000000000', // 20 gwei
    maxGasPrice: process.env.MAX_GAS_PRICE || '100000000000', // 100 gwei
    confirmations: parseInt(process.env.CONFIRMATIONS || '1', 10),
    timeout: parseInt(process.env.BLOCKCHAIN_TIMEOUT || '30000', 10),
  },

  contracts: {
    nodeLogic: process.env.NODE_LOGIC_ADDRESS || '',
    userLogic: process.env.USER_LOGIC_ADDRESS || '',
    resourceLogic: process.env.RESOURCE_LOGIC_ADDRESS || '',
    facade: process.env.FACADE_ADDRESS || '',
    nodeStorage: process.env.NODE_STORAGE_ADDRESS || '',
    userStorage: process.env.USER_STORAGE_ADDRESS || '',
    resourceStorage: process.env.RESOURCE_STORAGE_ADDRESS || '',
  },

  cache: {
    enabled: process.env.CACHE_ENABLED !== 'false',
    ttl: parseInt(process.env.CACHE_TTL || '300', 10), // 5 minutes
    maxKeys: parseInt(process.env.CACHE_MAX_KEYS || '1000', 10),
    checkPeriod: parseInt(process.env.CACHE_CHECK_PERIOD || '600', 10), // 10 minutes
  },

  rateLimit: {
    enabled: process.env.RATE_LIMIT_ENABLED !== 'false',
    points: parseInt(process.env.RATE_LIMIT_POINTS || '100', 10),
    duration: parseInt(process.env.RATE_LIMIT_DURATION || '60', 10), // 1 minute
    blockDuration: parseInt(process.env.RATE_LIMIT_BLOCK_DURATION || '300', 10), // 5 minutes
  },

  logging: {
    level: process.env.LOG_LEVEL || 'info',
    format: process.env.LOG_FORMAT || 'combined',
    colorize: process.env.LOG_COLORIZE !== 'false',
    timestamp: process.env.LOG_TIMESTAMP !== 'false',
    filename: process.env.LOG_FILENAME,
    maxsize: parseInt(process.env.LOG_MAX_SIZE || '10485760', 10), // 10MB
    maxFiles: parseInt(process.env.LOG_MAX_FILES || '5', 10),
  },

  monitoring: {
    enabled: process.env.MONITORING_ENABLED !== 'false',
    metricsPort: parseInt(process.env.METRICS_PORT || '9090', 10),
    healthCheckInterval: parseInt(process.env.HEALTH_CHECK_INTERVAL || '30000', 10), // 30 seconds
  },

  redis: {
    host: process.env.REDIS_HOST || 'localhost',
    port: parseInt(process.env.REDIS_PORT || '6379', 10),
    password: process.env.REDIS_PASSWORD,
    db: parseInt(process.env.REDIS_DB || '0', 10),
    keyPrefix: process.env.REDIS_KEY_PREFIX || 'quikdb:grpc:',
    maxRetriesPerRequest: parseInt(process.env.REDIS_MAX_RETRIES || '3', 10),
    retryDelayOnFailover: parseInt(process.env.REDIS_RETRY_DELAY || '100', 10),
    enableReadyCheck: process.env.REDIS_READY_CHECK !== 'false',
    lazyConnect: process.env.REDIS_LAZY_CONNECT !== 'false',
  },

  streaming: {
    defaultBatchSize: parseInt(process.env.STREAM_DEFAULT_BATCH_SIZE || '10', 10),
    maxBatchSize: parseInt(process.env.STREAM_MAX_BATCH_SIZE || '100', 10),
    eventBufferSize: parseInt(process.env.EVENT_BUFFER_SIZE || '1000', 10),
    heartbeatInterval: parseInt(process.env.HEARTBEAT_INTERVAL || '30000', 10), // 30 seconds
  },

  env: (process.env.NODE_ENV as 'development' | 'staging' | 'production') || 'development',
};

// Validation
function validateConfig(config: Config): void {
  const errors: string[] = [];

  // Validate required contract addresses in production
  if (config.env === 'production') {
    const requiredContracts = ['nodeLogic', 'userLogic', 'facade'];
    for (const contract of requiredContracts) {
      if (!config.contracts[contract as keyof typeof config.contracts]) {
        errors.push(`Missing required contract address: ${contract}`);
      }
    }
  }

  // Validate blockchain configuration
  if (!config.blockchain.rpcUrl) {
    errors.push('Missing blockchain RPC URL');
  }

  // Validate port ranges
  if (config.server.port < 1 || config.server.port > 65535) {
    errors.push('Invalid server port range');
  }

  if (config.monitoring.metricsPort < 1 || config.monitoring.metricsPort > 65535) {
    errors.push('Invalid metrics port range');
  }

  if (errors.length > 0) {
    throw new Error(`Configuration validation failed: ${errors.join(', ')}`);
  }
}

// Validate configuration
validateConfig(config);

export default config;
export { config };
