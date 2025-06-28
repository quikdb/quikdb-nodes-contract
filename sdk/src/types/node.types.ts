/**
 * Node status enumeration
 */
export enum NodeStatus {
  PENDING = 0,
  ACTIVE = 1,
  INACTIVE = 2,
  MAINTENANCE = 3,
  SUSPENDED = 4,
  DEREGISTERED = 5,
  LISTED = 6,
  OFFLINE = 7,
}

/**
 * Provider type enumeration
 */
export enum ProviderType {
  COMPUTE = 0,
  STORAGE = 1,
  NETWORK = 2,
}

/**
 * Node tier enumeration
 */
export enum NodeTier {
  NANO = 0,
  MICRO = 1,
  BASIC = 2,
  STANDARD = 3,
  PREMIUM = 4,
  ENTERPRISE = 5,
}

/**
 * Node capacity structure
 */
export interface NodeCapacity {
  cpuCores: number;
  memoryGB: number;
  storageGB: number;
  networkMbps: number;
  gpuCount: number;
  gpuType: string;
}

/**
 * Node metrics structure
 */
export interface NodeMetrics {
  uptimePercentage: number;
  totalJobs: number;
  successfulJobs: number;
  totalEarnings: string;
  lastHeartbeat: number;
  avgResponseTime: number;
}

/**
 * Node listing information
 */
export interface NodeListing {
  isListed: boolean;
  hourlyRate: string;
  availability: number;
  region: string;
  supportedServices: string[];
  minJobDuration: number;
  maxJobDuration: number;
}

/**
 * Extended node information
 */
export interface NodeExtendedInfo {
  hardwareFingerprint: string;
  carbonFootprint: number;
  compliance: string[];
  securityScore: number;
  operatorBio: string;
  specialCapabilities: string[];
  bondAmount: string;
  isVerified: boolean;
  verificationExpiry: number;
  contactInfo: string;
}

/**
 * Complete node information
 */
export interface NodeInfo {
  nodeId: string;
  nodeAddress: string;
  status: number; // NodeStatus enum value
  providerType: number; // ProviderType enum value
  tier: number; // NodeTier enum value
  capacity: NodeCapacity;
  metrics: NodeMetrics;
  listing: NodeListing;
  registeredAt: number;
  lastUpdated: number;
  exists: boolean;
  extended: NodeExtendedInfo;
  certifications: string[];
  connectedNetworks: string[];
}
