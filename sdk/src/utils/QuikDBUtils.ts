import { ethers } from "ethers";

/**
 * Utility functions for the QuikDB Nodes SDK
 */
export class QuikDBUtils {
  /**
   * Convert a number to wei (BigInt)
   * @param ether Amount in ether
   * @returns BigInt representation in wei
   */
  static toWei(ether: string | number): bigint {
    return ethers.parseUnits(ether.toString(), "ether");
  }

  /**
   * Convert wei to ether (string)
   * @param wei Amount in wei (BigInt)
   * @returns String representation in ether
   */
  static fromWei(wei: bigint | string): string {
    return ethers.formatUnits(wei.toString(), "ether");
  }

  /**
   * Convert a string to bytes32 format
   * @param str String to convert
   * @returns Bytes32 representation
   */
  static stringToBytes32(str: string): string {
    return ethers.encodeBytes32String(str);
  }

  /**
   * Convert bytes32 to string
   * @param bytes32 Bytes32 to convert
   * @returns String representation
   */
  static bytes32ToString(bytes32: string): string {
    return ethers.decodeBytes32String(bytes32);
  }

  /**
   * Generate a unique ID using timestamp and random value
   * @returns Unique string ID
   */
  static generateUniqueId(): string {
    const timestamp = Date.now().toString();
    const random = Math.floor(Math.random() * 100000)
      .toString()
      .padStart(5, "0");
    return `${timestamp}-${random}`;
  }

  /**
   * Format a timestamp to a human-readable date string
   * @param timestamp Unix timestamp
   * @returns Formatted date string
   */
  static formatTimestamp(timestamp: number): string {
    return new Date(timestamp * 1000).toLocaleString();
  }

  /**
   * Calculate duration in hours between two timestamps
   * @param startTimestamp Start timestamp
   * @param endTimestamp End timestamp
   * @returns Duration in hours
   */
  static calculateDurationHours(
    startTimestamp: number,
    endTimestamp: number
  ): number {
    const durationSeconds = endTimestamp - startTimestamp;
    return Math.floor(durationSeconds / 3600);
  }

  /**
   * Generate a random ID for testing or development
   * @returns Random ID string
   */
  static generateRandomId(): string {
    return `id-${Math.random().toString(36).substring(2, 15)}`;
  }

  /**
   * Format a price to a human-readable string with ETH units
   * @param weiAmount Price amount in wei
   * @param decimals Number of decimals to display
   * @returns Formatted price string
   */
  static formatPrice(weiAmount: string | bigint, decimals: number = 6): string {
    const etherValue = this.fromWei(weiAmount);
    const parsed = parseFloat(etherValue);
    return `${parsed.toFixed(decimals)} ETH`;
  }

  /**
   * Convert node tier enumeration to human-readable string with details
   * @param tier Node tier value
   * @returns Formatted tier string with details
   */
  static formatTier(tier: number): string {
    const tiers = [
      "NANO (Limited Resources)",
      "MICRO (Basic Resources)",
      "BASIC (Standard Resources)",
      "STANDARD (Enhanced Resources)",
      "PREMIUM (High Performance)",
      "ENTERPRISE (Maximum Performance)",
    ];

    return tiers[tier] || "UNKNOWN";
  }

  /**
   * Calculate estimated cost for a compute resource
   * @param hourlyRate Hourly rate in wei
   * @param hours Duration in hours
   * @returns Total cost in wei
   */
  static calculateComputeCost(
    hourlyRate: string | bigint,
    hours: number
  ): bigint {
    const rate =
      typeof hourlyRate === "string" ? BigInt(hourlyRate) : hourlyRate;
    return rate * BigInt(hours);
  }

  /**
   * Calculate estimated cost for storage
   * @param pricePerGBMonth Price per GB per month in wei
   * @param sizeGB Size in GB
   * @param months Duration in months
   * @returns Total cost in wei
   */
  static calculateStorageCost(
    pricePerGBMonth: string | bigint,
    sizeGB: number,
    months: number
  ): bigint {
    const rate =
      typeof pricePerGBMonth === "string"
        ? BigInt(pricePerGBMonth)
        : pricePerGBMonth;
    return rate * BigInt(sizeGB) * BigInt(months);
  }

  /**
   * Check if a contract address is valid
   * @param address Contract address
   * @returns Boolean indicating if address is valid
   */
  static isValidAddress(address: string): boolean {
    return ethers.isAddress(address);
  }

  /**
   * Convert a value to a percentage string
   * @param value Value (e.g. 9950)
   * @param divisor Divisor (e.g. 100 for 2 decimal places)
   * @returns Formatted percentage string
   */
  static toPercentage(value: number, divisor: number = 100): string {
    return `${(value / divisor).toFixed(2)}%`;
  }
}
