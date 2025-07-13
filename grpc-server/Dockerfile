# Multi-stage build for QuikDB gRPC Server
FROM node:18-alpine AS builder

# Set working directory
WORKDIR /app

# Copy package files
COPY package.json yarn.lock ./

# Install dependencies
RUN yarn install --frozen-lockfile

# Copy source code
COPY . .

# Generate proto files
RUN yarn proto:gen && yarn proto:gen:ts

# Build TypeScript
RUN yarn build

# Production stage
FROM node:18-alpine AS production

# Install dumb-init for proper signal handling
RUN apk add --no-cache dumb-init

# Create app user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S grpc -u 1001

# Set working directory
WORKDIR /app

# Copy package files
COPY package.json yarn.lock ./

# Install production dependencies only
RUN yarn install --frozen-lockfile --production && \
    yarn cache clean

# Copy built application
COPY --from=builder --chown=grpc:nodejs /app/dist ./dist
COPY --from=builder --chown=grpc:nodejs /app/src/generated ./src/generated
COPY --from=builder --chown=grpc:nodejs /app/proto ./proto

# Create logs directory
RUN mkdir -p logs && chown grpc:nodejs logs

# Switch to non-root user
USER grpc

# Expose ports
EXPOSE 50051 3001

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3001/health', (res) => { process.exit(res.statusCode === 200 ? 0 : 1) })"

# Use dumb-init to handle signals properly
ENTRYPOINT ["dumb-init", "--"]

# Start the server
CMD ["node", "dist/server.js"]
