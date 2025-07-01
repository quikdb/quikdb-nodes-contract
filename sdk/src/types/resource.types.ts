/**
 * Compute tier enumeration
 */
export enum ComputeTier {
  NANO = 0,
  MICRO = 1,
  BASIC = 2,
  STANDARD = 3,
  PREMIUM = 4,
  ENTERPRISE = 5,
}

/**
 * Storage tier enumeration
 */
export enum StorageTier {
  BASIC = 0,
  FAST = 1,
  PREMIUM = 2,
  ARCHIVE = 3,
}

/**
 * Listing status enumeration
 */
export enum ListingStatus {
  ACTIVE = 0,
  INACTIVE = 1,
  SUSPENDED = 2,
  EXPIRED = 3,
  CANCELLED = 4,
}

/**
 * Allocation status enumeration
 */
export enum AllocationStatus {
  PENDING = 0,
  ACTIVE = 1,
  COMPLETED = 2,
  CANCELLED = 3,
  EXPIRED = 4,
  FAILED = 5,
}

/**
 * Compute listing structure
 */
export interface ComputeListing {
  listingId: string;
  nodeId: string;
  nodeAddress: string;
  tier: number; // ComputeTier enum value
  resourceType: number; // 0 for compute
  cpuCores: number;
  memoryGB: number;
  storageGB: number;
  hourlyRate: string;
  region: string;
  isActive: boolean;
  createdAt: number;
}

/**
 * Storage listing structure
 */
export interface StorageListing {
  listingId: string;
  nodeId: string;
  nodeAddress: string;
  tier: number; // StorageTier enum value
  resourceType: number; // 1 for storage
  storageGB: number;
  hourlyRate: string;
  region: string;
  isActive: boolean;
  createdAt: number;
}

/**
 * Compute allocation structure
 */
export interface ComputeAllocation {
  allocationId: string;
  listingId: string;
  buyerAddress: string;
  startTime: number;
  endTime: number;
  totalCost: string;
  status: number; // AllocationStatus enum value
  usageMetrics: ResourceUsageMetrics;
}

/**
 * Resource usage metrics structure
 */
export interface ResourceUsageMetrics {
  cpuUsagePercent: number;
  memoryUsageGB: number;
  storageUsageGB: number;
  bandwidthUsageGB: number;
  lastUpdated: number;
}
