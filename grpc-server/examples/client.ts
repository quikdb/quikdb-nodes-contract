/**
 * Example gRPC client for QuikDB contracts with separated services
 */

import * as grpc from '@grpc/grpc-js';
import * as protoLoader from '@grpc/proto-loader';
import * as path from 'path';

/**
 * Load proto definitions
 */
function loadProtoServices() {
  const protoDir = path.join(__dirname, '../proto');
  const packages: any = {};

  // Load each proto file
  const protoFiles = ['user.proto', 'health.proto', 'stats.proto', 'events.proto'];
  
  for (const protoFile of protoFiles) {
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
    Object.assign(packages, loaded);
  }

  return packages;
}

// Load proto definitions
const quikdbProto = loadProtoServices();

// Create clients
const serverAddress = 'localhost:50051';
const credentials = grpc.credentials.createInsecure();

const userClient = new quikdbProto.quikdb.user.UserService(serverAddress, credentials);
const healthClient = new quikdbProto.quikdb.health.HealthService(serverAddress, credentials);
const statsClient = new quikdbProto.quikdb.stats.StatsService(serverAddress, credentials);
const eventsClient = new quikdbProto.quikdb.events.EventService(serverAddress, credentials);

/**
 * Example usage functions
 */

async function healthCheck(): Promise<void> {
  console.log('\n=== Health Check ===');
  
  return new Promise((resolve, reject) => {
    healthClient.HealthCheck({}, (error: any, response: any) => {
      if (error) {
        console.error('Health check failed:', error.message);
        reject(error);
        return;
      }
      
      console.log('Health check result:', {
        healthy: response.healthy,
        version: response.version,
        timestamp: new Date(response.timestamp).toISOString(),
        blockchainStatus: response.blockchain_status,
        lastBlockNumber: response.last_block_number,
        connectedContracts: response.connected_contracts_list
      });
      
      resolve();
    });
  });
}

async function getSystemStats(): Promise<void> {
  console.log('\n=== System Stats ===');
  
  return new Promise((resolve, reject) => {
    statsClient.GetSystemStats({}, (error: any, response: any) => {
      if (error) {
        console.error('Failed to get system stats:', error.message);
        reject(error);
        return;
      }
      
      console.log('System stats:', {
        userStats: response.stats?.user_stats,
        nodeStats: response.stats?.node_stats,
        totalTransactions: response.stats?.total_transactions,
        totalVolume: response.stats?.total_volume,
        lastUpdated: new Date(response.stats?.last_updated || 0).toISOString()
      });
      
      resolve();
    });
  });
}

async function registerUser(): Promise<void> {
  console.log('\n=== Register User ===');
  
  const request = {
    user_address: '0x1234567890123456789012345678901234567890',
    profile_hash: 'QmUserProfileHash123',
    user_type: 0 // USER_TYPE_CONSUMER
  };
  
  return new Promise((resolve, reject) => {
    userClient.RegisterUser(request, (error: any, response: any) => {
      if (error) {
        console.error('Failed to register user:', error.message);
        reject(error);
        return;
      }
      
      console.log('User registration result:', {
        success: response.success,
        message: response.message,
        transactionHash: response.transaction_hash
      });
      
      resolve();
    });
  });
}

async function getUserProfile(): Promise<void> {
  console.log('\n=== Get User Profile ===');
  
  const request = {
    user_address: '0x1234567890123456789012345678901234567890'
  };
  
  return new Promise((resolve, reject) => {
    userClient.GetUserProfile(request, (error: any, response: any) => {
      if (error) {
        console.error('Failed to get user profile:', error.message);
        reject(error);
        return;
      }
      
      console.log('User profile:', {
        profileHash: response.profile?.profile_hash,
        userType: response.profile?.user_type,
        isActive: response.profile?.is_active,
        createdAt: new Date((response.profile?.created_at || 0) * 1000).toISOString(),
        totalSpent: response.profile?.total_spent,
        totalEarned: response.profile?.total_earned,
        reputationScore: response.profile?.reputation_score,
        isVerified: response.profile?.is_verified
      });
      
      resolve();
    });
  });
}

async function getUserStats(): Promise<void> {
  console.log('\n=== Get User Stats ===');
  
  return new Promise((resolve, reject) => {
    userClient.GetUserStats({}, (error: any, response: any) => {
      if (error) {
        console.error('Failed to get user stats:', error.message);
        reject(error);
        return;
      }
      
      console.log('User stats:', {
        totalUsers: response.stats?.total_users
      });
      
      resolve();
    });
  });
}

async function getUsers(): Promise<void> {
  console.log('\n=== Get Users (Paginated) ===');
  
  const request = {
    pagination: {
      page: 0,
      limit: 10,
      sort_by: 'created_at',
      sort_order: 'desc'
    },
    type_filter: 0, // USER_TYPE_CONSUMER
    verified_only: false,
    active_only: true
  };
  
  return new Promise((resolve, reject) => {
    userClient.GetUsers(request, (error: any, response: any) => {
      if (error) {
        console.error('Failed to get users:', error.message);
        reject(error);
        return;
      }
      
      console.log('Users result:', {
        usersCount: response.users_list?.length || 0,
        pagination: {
          page: response.pagination?.page,
          limit: response.pagination?.limit,
          totalPages: response.pagination?.total_pages,
          totalItems: response.pagination?.total_items,
          hasNext: response.pagination?.has_next,
          hasPrevious: response.pagination?.has_previous
        }
      });
      
      // Show first few users
      if (response.users_list && response.users_list.length > 0) {
        console.log('First user:', response.users_list[0]);
      }
      
      resolve();
    });
  });
}

async function streamUsers(): Promise<void> {
  console.log('\n=== Stream Users ===');
  
  const request = {
    type_filter: 0, // USER_TYPE_CONSUMER
    verified_only: false,
    active_only: true,
    batch_size: 5
  };
  
  return new Promise((resolve, reject) => {
    const stream = userClient.StreamUsers(request);
    let totalReceived = 0;
    
    stream.on('data', (response: any) => {
      console.log('Received user batch:', {
        usersInBatch: response.users_list?.length || 0,
        isFinalBatch: response.is_final_batch,
        totalSent: response.total_sent
      });
      
      totalReceived += response.users_list?.length || 0;
    });
    
    stream.on('end', () => {
      console.log(`Stream ended. Total users received: ${totalReceived}`);
      resolve();
    });
    
    stream.on('error', (error: any) => {
      console.error('Stream error:', error.message);
      reject(error);
    });
    
    // Auto-end stream after 10 seconds for demo
    setTimeout(() => {
      stream.cancel();
    }, 10000);
  });
}

async function streamEvents(): Promise<void> {
  console.log('\n=== Stream Events ===');
  
  const request = {
    filter: {
      contract_addresses_list: [], // Empty means all contracts
      event_names_list: [], // Empty means all events
      from_block: 0,
      to_block: 0 // 0 means latest
    },
    include_historical: false // Only real-time events
  };
  
  return new Promise((resolve, reject) => {
    const stream = eventsClient.StreamEvents(request);
    let eventCount = 0;
    
    stream.on('data', (response: any) => {
      eventCount++;
      console.log('Received event:', {
        contractAddress: response.event?.contract_address,
        eventName: response.event?.event_name,
        blockNumber: response.event?.block_number,
        transactionHash: response.event?.transaction_hash,
        timestamp: new Date(response.event?.timestamp || 0).toISOString()
      });
    });
    
    stream.on('end', () => {
      console.log(`Event stream ended. Total events received: ${eventCount}`);
      resolve();
    });
    
    stream.on('error', (error: any) => {
      console.error('Event stream error:', error.message);
      reject(error);
    });
    
    // Auto-end stream after 15 seconds for demo
    setTimeout(() => {
      console.log('Ending event stream after timeout...');
      stream.cancel();
      resolve();
    }, 15000);
  });
}

/**
 * Run all examples
 */
async function runExamples(): Promise<void> {
  try {
    console.log('QuikDB gRPC Client Examples');
    console.log('============================');
    
    // Basic examples
    await healthCheck();
    await getSystemStats();
    await getUserStats();
    
    // User management examples
    await registerUser();
    await getUserProfile();
    await getUsers();
    
    // Streaming examples
    await streamUsers();
    await streamEvents();
    
    console.log('\n✅ All examples completed successfully!');
    
  } catch (error) {
    console.error('\n❌ Example failed:', error);
    process.exit(1);
  }
}

// Run examples if this file is executed directly
if (require.main === module) {
  runExamples().finally(() => {
    process.exit(0);
  });
}

export {
  healthCheck,
  getSystemStats,
  registerUser,
  getUserProfile,
  getUserStats,
  getUsers,
  streamUsers,
  streamEvents
};
