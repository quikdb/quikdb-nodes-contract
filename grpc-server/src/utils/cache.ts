/**
 * Cache utility using node-cache
 */

import NodeCache from 'node-cache';
import { config } from '../config';
import { logger } from './logger';

// Create cache instance
export const cache = new NodeCache({
  stdTTL: config.cache.ttl,
  checkperiod: config.cache.checkPeriod,
  maxKeys: config.cache.maxKeys,
  useClones: false // For better performance, but be careful with object mutations
});

// Cache events
cache.on('set', (key, value) => {
  logger.debug(`Cache set: ${key}`);
});

cache.on('del', (key, value) => {
  logger.debug(`Cache delete: ${key}`);
});

cache.on('expired', (key, value) => {
  logger.debug(`Cache expired: ${key}`);
});

// Cache statistics
export function getCacheStats() {
  return cache.getStats();
}

// Cache health check
export function isCacheHealthy(): boolean {
  try {
    const stats = cache.getStats();
    return stats.keys >= 0; // Simple health check
  } catch (error) {
    logger.error('Cache health check failed:', error);
    return false;
  }
}
