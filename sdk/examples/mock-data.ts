/**
 * Mock data for SDK examples and testing
 * This file provides sample data to test SDK functionality without a live contract
 */
import { ethers } from "ethers";
import { NodeStatus, NodeTier, ProviderType } from "../src/types/node.types";
import { UserType } from "../src/types/user.types";

// Generate a random Ethereum address
export const generateRandomAddress = (): string => {
  const wallet = ethers.Wallet.createRandom();
  return wallet.address;
};

// Generate a consistent set of mock nodes
export const generateMockNodes = (
  count: number = 20
): {
  nodeId: string;
  address: string;
  status: NodeStatus;
  tier: NodeTier;
  providerType: ProviderType;
  registeredAt: number;
}[] => {
  const nodes = [];

  for (let i = 0; i < count; i++) {
    // Create deterministic but different nodeIds
    const nodeId = `mock-node-${i.toString().padStart(3, "0")}`;

    // Generate a random node status with weighted probability
    let status = NodeStatus.PENDING;
    const statusRandom = Math.random();
    if (statusRandom > 0.7) status = NodeStatus.ACTIVE;
    else if (statusRandom > 0.4) status = NodeStatus.PENDING;
    else if (statusRandom > 0.3) status = NodeStatus.OFFLINE;
    else status = NodeStatus.DEREGISTERED;

    // Generate a random node tier with weighted probability
    let tier = NodeTier.STANDARD;
    const tierRandom = Math.random();
    if (tierRandom > 0.8) tier = NodeTier.PREMIUM;
    else if (tierRandom > 0.5) tier = NodeTier.STANDARD;
    else if (tierRandom > 0.2) tier = NodeTier.BASIC;
    else tier = NodeTier.MICRO;

    // Generate a random provider type
    const providerType =
      Math.random() > 0.5 ? ProviderType.COMPUTE : ProviderType.STORAGE;

    // Registration timestamp between 1-365 days ago
    const now = Math.floor(Date.now() / 1000);
    const registeredAt = now - Math.floor(Math.random() * 365 * 24 * 60 * 60);

    nodes.push({
      nodeId,
      address: generateRandomAddress(),
      status,
      tier,
      providerType,
      registeredAt,
    });
  }

  return nodes;
};

// Create mock users
export const generateMockUsers = (
  count: number = 10
): {
  address: string;
  userType: UserType;
  isActive: boolean;
  registeredAt: number;
  profileHash: string;
}[] => {
  const users = [];

  for (let i = 0; i < count; i++) {
    // Generate a random user type
    let userType = UserType.CONSUMER;
    const typeRandom = Math.random();
    if (typeRandom > 0.7) userType = UserType.PROVIDER;
    else if (typeRandom > 0.4) userType = UserType.CONSUMER;
    else userType = UserType.MARKETPLACE_ADMIN;

    // Registration timestamp between 1-180 days ago
    const now = Math.floor(Date.now() / 1000);
    const registeredAt = now - Math.floor(Math.random() * 180 * 24 * 60 * 60);

    users.push({
      address: generateRandomAddress(),
      userType,
      isActive: Math.random() > 0.2, // 80% active
      registeredAt,
      profileHash: ethers.keccak256(ethers.toUtf8Bytes(`profile-${i}`)),
    });
  }

  return users;
};

// Generate a full mock node with all details
export const getMockNodeInfo = (nodeId: string) => {
  const nodeIdNum = parseInt(nodeId.split("-").pop() || "0");

  // Generate deterministic but realistic values based on nodeId
  const status =
    nodeIdNum % 10 > 7
      ? NodeStatus.ACTIVE
      : nodeIdNum % 10 > 4
      ? NodeStatus.PENDING
      : nodeIdNum % 10 > 2
      ? NodeStatus.OFFLINE
      : NodeStatus.DEREGISTERED;

  const tier =
    nodeIdNum % 4 === 0
      ? NodeTier.PREMIUM
      : nodeIdNum % 4 === 1
      ? NodeTier.STANDARD
      : nodeIdNum % 4 === 2
      ? NodeTier.BASIC
      : NodeTier.MICRO;

  const providerType =
    nodeIdNum % 2 === 0 ? ProviderType.COMPUTE : ProviderType.STORAGE;

  // Registration timestamp between 1-365 days ago
  const now = Math.floor(Date.now() / 1000);
  const seed = (nodeIdNum * 13) % 365; // Deterministic seed
  const registeredAt = now - seed * 24 * 60 * 60;

  // Generate other node details
  const mockNodeInfo = {
    nodeId,
    nodeAddress: generateRandomAddress(),
    status,
    tier,
    providerType,
    registeredAt,
    lastUpdated: now - 60 * 60 * (nodeIdNum % 24), // Last updated between 0-23 hours ago
    exists: true,
    listing: {
      isListed: status === NodeStatus.ACTIVE,
      hourlyRate: ethers
        .parseEther((0.01 + (nodeIdNum % 10) / 100).toString())
        .toString(),
      availability: 90 + (nodeIdNum % 10),
      region: ["us-east", "us-west", "eu-central", "ap-south"][nodeIdNum % 4],
      supportedServices: ["container", "vm", "database"],
      minJobDuration: 1,
      maxJobDuration: 24 * 30, // 30 days
    },
    capacity: {
      cpuCores: 4 + (nodeIdNum % 60),
      memoryGB: 16 + (nodeIdNum % 112),
      storageGB: 512 + nodeIdNum * 256,
      networkMbps: 1000,
      gpuCount: nodeIdNum % 4,
      gpuType: nodeIdNum % 4 ? "NVIDIA RTX 4090" : "",
    },
    metrics: {
      uptimePercentage: 98 + (nodeIdNum % 3),
      totalJobs: nodeIdNum * 10,
      successfulJobs: nodeIdNum * 9,
      totalEarnings: ethers.parseEther((nodeIdNum * 0.5).toString()).toString(),
      lastHeartbeat: now - 60 * 5, // 5 minutes ago
      avgResponseTime: 50 + (nodeIdNum % 100),
    },
    extended: {
      hardwareFingerprint: ethers
        .keccak256(ethers.toUtf8Bytes(`hw-${nodeId}`))
        .slice(0, 34),
      carbonFootprint: 10 + (nodeIdNum % 40),
      compliance: ["GDPR", "ISO27001", "HIPAA"].slice(0, 1 + (nodeIdNum % 3)),
      securityScore: 70 + (nodeIdNum % 30),
      operatorBio: `Operator of node ${nodeId} with experience in cloud infrastructure`,
      specialCapabilities: ["gpu-acceleration", "low-latency", "high-memory"],
      bondAmount: ethers
        .parseEther((1 + (nodeIdNum % 10)).toString())
        .toString(),
      isVerified: nodeIdNum % 5 === 0,
      verificationExpiry: now + 30 * 24 * 60 * 60, // 30 days in future
      contactInfo: `operator${nodeIdNum}@example.com`,
    },
    certifications: [`CERT-${nodeIdNum % 3}-${nodeId}`],
    connectedNetworks: ["mainnet", "testnet"],
  };

  return mockNodeInfo;
};

// Pre-generate a set of mock nodes
export const mockNodes = generateMockNodes();
export const mockUsers = generateMockUsers();
