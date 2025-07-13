# QuikDB gRPC Server - Comprehensive Documentation

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Installation & Setup](#installation--setup)
4. [Configuration](#configuration)
5. [Services Documentation](#services-documentation)
6. [API Reference](#api-reference)
7. [Client Integration](#client-integration)
8. [Deployment](#deployment)
9. [Monitoring & Observability](#monitoring--observability)
10. [Development](#development)
11. [Troubleshooting](#troubleshooting)

## Overview

The QuikDB gRPC Server is a production-grade microservice that provides gRPC endpoints for interacting with QuikDB smart contracts. It features a modular architecture with separate proto files per service, comprehensive monitoring, caching, and streaming capabilities.

### Key Features

- **Modular Service Architecture**: Separate proto files for User, Health, Stats, Events, and Node services
- **Production-Ready**: Built-in monitoring, logging, caching, and graceful shutdown
- **Type-Safe**: Full TypeScript implementation with generated types
- **Streaming Support**: Real-time data streaming for large datasets
- **Blockchain Integration**: Direct smart contract interaction via ethers.js
- **Container-Ready**: Docker and Kubernetes deployment support

## Architecture

### Service Structure

```
QuikDB gRPC Server
├── UserService      # User management and profiles
├── HealthService     # Health checks and monitoring  
├── StatsService      # System statistics
├── EventService      # Blockchain event streaming
└── NodeService       # Node management (future)
```

### File Organization

```
grpc-server/
├── proto/                          # Protocol Buffer definitions
│   ├── common.proto                # Shared types and pagination
│   ├── user.proto                  # User service definitions
│   ├── node.proto                  # Node service definitions
│   ├── health.proto                # Health service definitions
│   ├── events.proto                # Event service definitions
│   └── stats.proto                 # Stats service definitions
├── src/
│   ├── config/
│   │   └── index.ts                # Configuration management
│   ├── contracts/
│   │   └── index.ts                # Smart contract interaction layer
│   ├── services/
│   │   ├── userService.ts          # User service implementation
│   │   ├── healthService.ts        # Health service implementation
│   │   ├── statsService.ts         # Stats service implementation
│   │   └── eventsService.ts        # Events service implementation
│   ├── utils/
│   │   ├── logger.ts               # Winston logging
│   │   ├── cache.ts                # Node-cache wrapper
│   │   ├── monitoring.ts           # Prometheus metrics
│   │   └── index.ts                # Utility exports
│   ├── generated/                  # Generated TypeScript from proto
│   └── server.ts                   # Main gRPC server
├── examples/
│   └── client.ts                   # Example client implementation
├── package.json                    # Dependencies and scripts
├── tsconfig.json                   # TypeScript configuration
├── Dockerfile                      # Container definition
├── docker-compose.yml              # Development environment
└── .env.example                    # Environment template
```

## Installation & Setup

### Prerequisites

- Node.js 18+ and yarn
- Protocol Buffers compiler (protoc)
- Access to QuikDB smart contracts
- Blockchain RPC endpoint

### Quick Start

1. **Clone and Install**
   ```bash
   cd grpc-server
   yarn install
   ```

2. **Generate Proto Types**
   ```bash
   yarn proto:gen && yarn proto:gen:ts
   ```

3. **Configure Environment**
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

4. **Build and Run**
   ```bash
   yarn build
   yarn start
   ```

### Available Scripts

```bash
yarn dev               # Development mode with hot reload
yarn build             # Compile TypeScript
yarn start             # Start production server
yarn proto:gen         # Generate JavaScript from proto
yarn proto:gen:ts      # Generate TypeScript definitions
yarn clean             # Clean generated files
yarn example           # Run example client
yarn test              # Run tests
yarn lint              # Lint code
yarn docker:build      # Build Docker image
yarn docker:run        # Run Docker container
```

## Configuration

### Environment Variables

Create a `.env` file based on `.env.example`:

```bash
# Server Configuration
SERVER_HOST=0.0.0.0
SERVER_PORT=50051
NODE_ENV=production

# Blockchain Configuration
BLOCKCHAIN_NETWORK_NAME=mainnet
BLOCKCHAIN_RPC_URL=https://eth-mainnet.alchemyapi.io/v2/your-key
BLOCKCHAIN_CHAIN_ID=1
BLOCKCHAIN_PRIVATE_KEY=your-private-key-for-write-ops

# Contract Addresses
USER_LOGIC_ADDRESS=0x...
USER_STORAGE_ADDRESS=0x...
NODE_LOGIC_ADDRESS=0x...
NODE_STORAGE_ADDRESS=0x...
RESOURCE_LOGIC_ADDRESS=0x...
RESOURCE_STORAGE_ADDRESS=0x...

# Cache Configuration
CACHE_ENABLED=true
CACHE_TTL=300
CACHE_MAX_KEYS=1000

# Monitoring Configuration
MONITORING_ENABLED=true
MONITORING_METRICS_PORT=3001
MONITORING_HEALTH_ENDPOINT=/health
MONITORING_METRICS_ENDPOINT=/metrics

# Logging Configuration
LOG_LEVEL=info
LOG_FORMAT=json
```

### Configuration Schema

The server validates all configuration using Zod schemas. Invalid configuration will prevent startup with detailed error messages.

## Services Documentation

### UserService

Manages user profiles and blockchain interactions.

**Package**: `quikdb.user`

#### Methods

- `RegisterUser` - Register new users on blockchain
- `GetUserProfile` - Retrieve user profile data
- `UpdateUserProfile` - Update user profile information
- `GetUserStats` - Get user statistics
- `GetUsers` - Paginated user listing with filters
- `StreamUsers` - Stream users for large datasets

### HealthService

Provides health checks and system status monitoring.

**Package**: `quikdb.health`

#### Methods

- `HealthCheck` - Get current system health status

### StatsService

Aggregates system-wide statistics from smart contracts.

**Package**: `quikdb.stats`

#### Methods

- `GetSystemStats` - Get comprehensive system statistics

### EventService

Streams blockchain events in real-time.

**Package**: `quikdb.events`

#### Methods

- `StreamEvents` - Stream blockchain events with filtering

## API Reference

### User Management

#### Register User

```protobuf
rpc RegisterUser(RegisterUserRequest) returns (RegisterUserResponse);

message RegisterUserRequest {
  string user_address = 1;
  string profile_hash = 2;
  UserType user_type = 3;
}

message RegisterUserResponse {
  bool success = 1;
  string transaction_hash = 2;
  string message = 3;
}
```

#### Get User Profile

```protobuf
rpc GetUserProfile(GetUserProfileRequest) returns (GetUserProfileResponse);

message GetUserProfileRequest {
  string user_address = 1;
}

message GetUserProfileResponse {
  UserProfile profile = 1;
}
```

#### Stream Users

```protobuf
rpc StreamUsers(StreamUsersRequest) returns (stream StreamUsersResponse);

message StreamUsersRequest {
  UserType type_filter = 1;
  bool verified_only = 2;
  bool active_only = 3;
  uint32 batch_size = 4;
}
```

### Health Monitoring

#### Health Check

```protobuf
rpc HealthCheck(HealthCheckRequest) returns (HealthCheckResponse);

message HealthCheckResponse {
  bool healthy = 1;
  string version = 2;
  uint64 timestamp = 3;
  string blockchain_status = 4;
  uint64 last_block_number = 5;
  repeated string connected_contracts = 6;
}
```

### Statistics

#### System Stats

```protobuf
rpc GetSystemStats(GetSystemStatsRequest) returns (GetSystemStatsResponse);

message GetSystemStatsResponse {
  SystemStats stats = 1;
}

message SystemStats {
  UserStats user_stats = 1;
  NodeStats node_stats = 2;
  uint64 total_transactions = 3;
  uint64 total_volume = 4;
  uint64 last_updated = 5;
}
```

### Event Streaming

#### Stream Events

```protobuf
rpc StreamEvents(StreamEventsRequest) returns (stream StreamEventsResponse);

message StreamEventsRequest {
  EventFilter filter = 1;
  bool include_historical = 2;
}

message EventFilter {
  repeated string contract_addresses = 1;
  repeated string event_names = 2;
  uint64 from_block = 3;
  uint64 to_block = 4;
}
```

## Client Integration

### Node.js/TypeScript Client

```typescript
import * as grpc from '@grpc/grpc-js';
import * as protoLoader from '@grpc/proto-loader';

// Load proto definitions
const userProto = protoLoader.loadSync('proto/user.proto', {
  keepCase: true,
  longs: String,
  enums: String,
  defaults: true,
  oneofs: true,
  includeDirs: ['proto']
});

const userPackage = grpc.loadPackageDefinition(userProto);
const UserService = userPackage.quikdb.user.UserService;

// Create client
const client = new UserService(
  'localhost:50051',
  grpc.credentials.createInsecure()
);

// Register user
const response = await new Promise((resolve, reject) => {
  client.RegisterUser({
    user_address: '0x1234567890123456789012345678901234567890',
    profile_hash: 'QmUserProfileHash',
    user_type: 0
  }, (error, response) => {
    if (error) reject(error);
    else resolve(response);
  });
});
```

### Python Client

```python
import grpc
import user_pb2
import user_pb2_grpc

# Create channel and stub
channel = grpc.insecure_channel('localhost:50051')
stub = user_pb2_grpc.UserServiceStub(channel)

# Register user
request = user_pb2.RegisterUserRequest(
    user_address='0x1234567890123456789012345678901234567890',
    profile_hash='QmUserProfileHash',
    user_type=0
)

response = stub.RegisterUser(request)
print(f"Success: {response.success}")
```

### Streaming Example

```typescript
// Stream users
const stream = client.StreamUsers({
  type_filter: 0,
  verified_only: false,
  active_only: true,
  batch_size: 10
});

stream.on('data', (response) => {
  console.log(`Received ${response.users_list.length} users`);
  console.log(`Is final batch: ${response.is_final_batch}`);
});

stream.on('end', () => {
  console.log('Stream ended');
});

stream.on('error', (error) => {
  console.error('Stream error:', error);
});
```

## Deployment

### Docker Deployment

#### Build Image

```bash
docker build -t quikdb-grpc-server .
```

#### Run Container

```bash
docker run -d \
  --name quikdb-grpc \
  -p 50051:50051 \
  -p 3001:3001 \
  --env-file .env \
  quikdb-grpc-server
```

#### Docker Compose

```bash
# Development environment
docker-compose up -d

# Production environment
docker-compose -f docker-compose.prod.yml up -d
```

### Kubernetes Deployment

#### Deployment Manifest

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: quikdb-grpc-server
spec:
  replicas: 3
  selector:
    matchLabels:
      app: quikdb-grpc-server
  template:
    metadata:
      labels:
        app: quikdb-grpc-server
    spec:
      containers:
      - name: grpc-server
        image: quikdb-grpc-server:latest
        ports:
        - containerPort: 50051
        - containerPort: 3001
        env:
        - name: SERVER_HOST
          value: "0.0.0.0"
        - name: BLOCKCHAIN_RPC_URL
          valueFrom:
            secretKeyRef:
              name: blockchain-secrets
              key: rpc-url
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 3001
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 3001
          initialDelaySeconds: 5
          periodSeconds: 5
```

#### Service Manifest

```yaml
apiVersion: v1
kind: Service
metadata:
  name: quikdb-grpc-service
spec:
  selector:
    app: quikdb-grpc-server
  ports:
  - name: grpc
    port: 50051
    targetPort: 50051
  - name: metrics
    port: 3001
    targetPort: 3001
  type: ClusterIP
```

### Load Balancing

For production deployments, use a load balancer that supports gRPC:

#### Nginx Configuration

```nginx
upstream grpc_backend {
    server 10.0.0.1:50051;
    server 10.0.0.2:50051;
    server 10.0.0.3:50051;
}

server {
    listen 50051 http2;
    
    location / {
        grpc_pass grpc://grpc_backend;
        grpc_set_header Host $host;
    }
}
```

#### Istio Service Mesh

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: quikdb-grpc-vs
spec:
  hosts:
  - quikdb-grpc.example.com
  gateways:
  - quikdb-gateway
  http:
  - match:
    - headers:
        content-type:
          prefix: application/grpc
    route:
    - destination:
        host: quikdb-grpc-service
        port:
          number: 50051
```

## Monitoring & Observability

### Health Endpoints

- **Health Check**: `GET http://localhost:3001/health`
- **Metrics**: `GET http://localhost:3001/metrics`

### Prometheus Metrics

The server exposes comprehensive metrics:

```
# Request metrics
grpc_requests_total{method, status}
grpc_request_duration_seconds{method}

# System metrics  
nodejs_heap_size_total_bytes
nodejs_heap_size_used_bytes
process_cpu_user_seconds_total

# Custom metrics
quikdb_cache_hits_total
quikdb_cache_misses_total
quikdb_blockchain_requests_total
quikdb_active_streams
```

### Logging

Structured JSON logging with configurable levels:

```json
{
  "timestamp": "2025-01-01T12:00:00.000Z",
  "level": "info",
  "message": "User registration successful",
  "service": "UserService",
  "method": "RegisterUser",
  "userAddress": "0x...",
  "transactionHash": "0x...",
  "duration": 1250
}
```

### Alerting

Recommended Prometheus alerts:

```yaml
groups:
- name: quikdb-grpc
  rules:
  - alert: GrpcServerDown
    expr: up{job="quikdb-grpc"} == 0
    for: 1m
    labels:
      severity: critical
    annotations:
      summary: "QuikDB gRPC server is down"
      
  - alert: HighErrorRate
    expr: rate(grpc_requests_total{status!="OK"}[5m]) / rate(grpc_requests_total[5m]) > 0.05
    for: 2m
    labels:
      severity: warning
    annotations:
      summary: "High gRPC error rate"
      
  - alert: BlockchainConnectivity
    expr: quikdb_blockchain_requests_total{status="error"} > 0
    for: 1m
    labels:
      severity: warning
    annotations:
      summary: "Blockchain connectivity issues"
```

## Development

### Proto Development

When modifying proto files:

1. **Edit proto files** in the `proto/` directory
2. **Regenerate types**: `yarn proto:gen && yarn proto:gen:ts`
3. **Update services** in `src/services/`
4. **Test changes**: `yarn build && yarn example`

### Adding New Services

1. **Create proto file**: `proto/newservice.proto`
2. **Add to generation scripts** in `package.json`
3. **Implement service**: `src/services/newService.ts`
4. **Register in server**: Update `src/server.ts`
5. **Add to example client**: Update `examples/client.ts`

### Testing

```bash
# Unit tests
yarn test

# Integration tests  
yarn test:integration

# End-to-end tests
yarn test:e2e

# Load testing
yarn test:load
```

### Code Quality

```bash
# Linting
yarn lint

# Type checking
yarn tsc --noEmit

# Formatting
yarn prettier --write src/**/*.ts
```

## Troubleshooting

### Common Issues

#### Server Won't Start

1. **Check configuration**: Ensure all required environment variables are set
2. **Verify contracts**: Confirm contract addresses are correct and deployed
3. **Test RPC connection**: Verify blockchain RPC URL is accessible
4. **Check ports**: Ensure ports 50051 and 3001 are available

#### gRPC Connection Errors

1. **Network connectivity**: Test with `telnet localhost 50051`
2. **Proto compatibility**: Ensure client and server use same proto definitions
3. **TLS configuration**: Check if using secure/insecure credentials correctly

#### Performance Issues

1. **Enable caching**: Set `CACHE_ENABLED=true`
2. **Adjust cache settings**: Tune `CACHE_TTL` and `CACHE_MAX_KEYS`
3. **Monitor metrics**: Check Prometheus metrics for bottlenecks
4. **Scale horizontally**: Deploy multiple instances with load balancer

#### Blockchain Integration Issues

1. **RPC limits**: Check if hitting rate limits on blockchain RPC
2. **Gas settings**: Verify gas price and limit settings for transactions
3. **Contract ABIs**: Ensure ABI files match deployed contracts
4. **Network configuration**: Confirm chain ID and network name

### Debug Mode

Enable detailed logging:

```bash
LOG_LEVEL=debug yarn dev
```

### Health Checks

Monitor service health:

```bash
# Basic health
curl http://localhost:3001/health

# Detailed metrics
curl http://localhost:3001/metrics

# gRPC health check
grpc_health_probe -addr=localhost:50051
```

---

This documentation provides comprehensive coverage of the QuikDB gRPC Server. For additional support or feature requests, please refer to the project repository or contact the development team.
