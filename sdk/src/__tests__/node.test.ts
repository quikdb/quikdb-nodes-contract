import { ethers } from "ethers";
import { NodeModule } from "../modules/node";
import { NodeStatus, NodeTier, ProviderType } from "../types/node.types";

// Mock data and contract interactions
jest.mock("ethers", () => {
  const originalModule = jest.requireActual("ethers");

  // Mock contract calls
  const mockContract = {
    getNodeInfo: jest.fn().mockResolvedValue({
      nodeId: "node-123",
      nodeAddress: "0x1234567890123456789012345678901234567890",
      status: 1, // NodeStatus.ACTIVE
      providerType: 0, // ProviderType.COMPUTE
      tier: 3, // NodeTier.STANDARD
      capacity: {
        cpuCores: 8,
        memoryGB: 32,
        storageGB: 512,
        networkMbps: 1000,
        gpuCount: 1,
        gpuType: "NVIDIA RTX 3080",
      },
      metrics: {
        uptimePercentage: 9950, // 99.50%
        totalJobs: 120,
        successfulJobs: 118,
        totalEarnings: ethers.parseEther("5.25").toString(),
        lastHeartbeat: Math.floor(Date.now() / 1000) - 300, // 5 minutes ago
        avgResponseTime: 150,
      },
      listing: {
        isListed: true,
        hourlyRate: ethers.parseEther("0.01").toString(),
        availability: 95,
        region: "us-east-1",
        supportedServices: ["compute", "ai-inference", "database"],
        minJobDuration: 1,
        maxJobDuration: 24,
      },
      registeredAt: Math.floor(Date.now() / 1000) - 30 * 24 * 3600, // 30 days ago
      lastUpdated: Math.floor(Date.now() / 1000) - 3600, // 1 hour ago
      exists: true,
      extended: {
        hardwareFingerprint: "hw-fp-123456",
        carbonFootprint: 750,
        compliance: ["GDPR", "HIPAA"],
        securityScore: 900, // 9.0/10
        operatorBio: "Professional node operator with 5 years of experience",
        specialCapabilities: ["CUDA", "TPU"],
        bondAmount: ethers.parseEther("1.0").toString(),
        isVerified: true,
        verificationExpiry: Math.floor(Date.now() / 1000) + 180 * 24 * 3600, // 180 days from now
        contactInfo: "encrypted-contact-info",
      },
      certifications: ["0x123..."],
      connectedNetworks: ["ethereum", "lisk", "polygon"],
    }),
    registerNode: jest.fn().mockResolvedValue({
      hash: "0x123456789abcdef",
      wait: jest.fn().mockResolvedValue({ status: 1 }),
    }),
    updateNodeStatus: jest.fn().mockResolvedValue({
      hash: "0x123456789abcdef",
      wait: jest.fn().mockResolvedValue({ status: 1 }),
    }),
    getTotalNodes: jest.fn().mockResolvedValue(42),
    connect: jest.fn().mockReturnThis(),
  };

  return {
    ...originalModule,
    Contract: jest.fn().mockImplementation(() => mockContract),
    JsonRpcProvider: jest.fn().mockImplementation(() => ({})),
    Wallet: jest.fn().mockImplementation(() => ({
      connect: jest.fn().mockReturnThis(),
    })),
  };
});

describe("NodeModule", () => {
  let nodeModule: NodeModule;
  const mockProvider = new ethers.JsonRpcProvider("https://rpc-mock.lisk.io");
  const mockSigner = new ethers.Wallet("0x0123456789abcdef", mockProvider);

  beforeEach(() => {
    // Initialize module with mock provider and contract address
    nodeModule = new NodeModule(
      mockProvider,
      "0x1234567890123456789012345678901234567890",
      mockSigner
    );
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe("getNodeInfo", () => {
    it("should return node information for a given node ID", async () => {
      const nodeInfo = await nodeModule.getNodeInfo("node-123");

      expect(nodeInfo).toBeDefined();
      expect(nodeInfo.nodeId).toBe("node-123");
      expect(nodeInfo.status).toBe(NodeStatus.ACTIVE);
      expect(nodeInfo.tier).toBe(NodeTier.STANDARD);
      expect(nodeInfo.providerType).toBe(ProviderType.COMPUTE);
    });
  });

  describe("registerNode", () => {
    it("should register a new node", async () => {
      const result = await nodeModule.registerNode(
        "new-node-123",
        "0x0987654321098765432109876543210987654321",
        NodeTier.PREMIUM,
        ProviderType.STORAGE
      );

      expect(result).toBeDefined();
      expect(result.hash).toBe("0x123456789abcdef");
    });
  });

  describe("getTotalNodes", () => {
    it("should return the total number of nodes", async () => {
      const total = await nodeModule.getTotalNodes();
      expect(total).toBe(42);
    });
  });
});
