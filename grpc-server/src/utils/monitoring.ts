/**
 * Monitoring and metrics setup
 */

import express from 'express';
import { register, collectDefaultMetrics, Counter, Histogram, Gauge } from 'prom-client';
import { config } from '../config';
import { logger } from '../utils/logger';
import { getCacheStats } from '../utils/cache';

// Collect default metrics (CPU, memory, etc.)
collectDefaultMetrics();

// Custom metrics
export const grpcRequestsTotal = new Counter({
  name: 'grpc_requests_total',
  help: 'Total number of gRPC requests',
  labelNames: ['method', 'status']
});

export const grpcRequestDuration = new Histogram({
  name: 'grpc_request_duration_seconds',
  help: 'Duration of gRPC requests in seconds',
  labelNames: ['method'],
  buckets: [0.001, 0.005, 0.01, 0.05, 0.1, 0.5, 1, 5]
});

export const contractCallsTotal = new Counter({
  name: 'contract_calls_total',
  help: 'Total number of smart contract calls',
  labelNames: ['contract', 'method', 'status']
});

export const contractCallDuration = new Histogram({
  name: 'contract_call_duration_seconds',
  help: 'Duration of smart contract calls in seconds',
  labelNames: ['contract', 'method'],
  buckets: [0.1, 0.5, 1, 2, 5, 10, 30]
});

export const cacheHitsTotal = new Counter({
  name: 'cache_hits_total',
  help: 'Total number of cache hits',
  labelNames: ['type']
});

export const cacheSize = new Gauge({
  name: 'cache_size',
  help: 'Current cache size'
});

/**
 * Update cache metrics
 */
export function updateCacheMetrics(): void {
  try {
    const stats = getCacheStats();
    cacheSize.set(stats.keys);
  } catch (error) {
    logger.warn('Failed to update cache metrics:', error);
  }
}

/**
 * Start metrics collection interval
 */
export function startMetricsCollection(): void {
  if (!config.monitoring.enabled) {
    return;
  }

  // Update cache metrics every 30 seconds
  setInterval(updateCacheMetrics, 30000);
  logger.info('Metrics collection started');
}

/**
 * Start metrics server
 */
export function startMetricsServer(): void {
  if (!config.monitoring.enabled) {
    logger.info('Monitoring disabled, skipping metrics server');
    return;
  }

  const app = express();

  // Health endpoint
  app.get('/health', (req, res) => {
    res.json({
      status: 'ok',
      timestamp: new Date().toISOString(),
      uptime: process.uptime()
    });
  });

  // Metrics endpoint
  app.get('/metrics', async (req, res) => {
    try {
      res.set('Content-Type', register.contentType);
      res.end(await register.metrics());
    } catch (error) {
      logger.error('Failed to generate metrics:', error);
      res.status(500).end();
    }
  });

  // Start server
  app.listen(config.monitoring.metricsPort, () => {
    logger.info(`Metrics server listening on port ${config.monitoring.metricsPort}`);
    logger.info(`Health check: http://localhost:${config.monitoring.metricsPort}/health`);
    logger.info(`Metrics endpoint: http://localhost:${config.monitoring.metricsPort}/metrics`);
  });
}
