/**
 * User types enumeration
 */
export enum UserType {
  CONSUMER = 0,
  PROVIDER = 1,
  MARKETPLACE_ADMIN = 2,
  PLATFORM_ADMIN = 3,
}

/**
 * User profile structure
 */
export interface UserProfile {
  userAddress: string;
  profileHash: string;
  userType: number;
  isActive: boolean;
  exists: boolean;
  createdAt: number;
  updatedAt: number;
  totalSpent: string;
  totalEarned: string;
  reputationScore: number;
  isVerified: boolean;
}

/**
 * User preferences structure
 */
export interface UserPreferences {
  preferredRegion: string;
  maxHourlyRate: string;
  autoRenewal: boolean;
  preferredProviders: string[];
  notificationLevel: number;
}

/**
 * User statistics structure
 */
export interface UserStats {
  totalTransactions: number;
  avgRating: number;
  completedJobs: number;
  cancelledJobs: number;
  lastActivity: number;
}

/**
 * Complete user information
 */
export interface UserInfo {
  address?: string; // Optional address property, present in mock data but not in contract return
  profile: UserProfile;
  preferences: UserPreferences;
  stats: UserStats;
  exists: boolean;
}
