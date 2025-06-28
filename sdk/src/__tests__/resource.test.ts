import { ethers } from "ethers";
import { ResourceModule } from "../modules/resource";

// Mock data and contract interactions
jest.mock("ethers", () => {
  const originalModule = jest.requireActual("ethers");

  // Mock contract calls
  const mockContract = {
    getComputeListings: jest.fn().mockResolvedValue([
      {
        listingId: "0",
        nodeId: "node-123",
        resourceType: 0, // compute
        tier: 3, // standard
        cpuCores: 8,
        memoryGB: 32,
        storageGB: 512,
        price: ethers.parseEther("0.01").toString(),
        region: "us-east-1",
        isActive: true,
        createdAt: Math.floor(Date.now() / 1000) - 7 * 24 * 3600, // 7 days ago
        features: ["GPU", "SSD"],
        avgRating: 45, // 4.5/5.0
      },
      {
        listingId: "1",
        nodeId: "node-456",
        resourceType: 0, // compute
        tier: 4, // premium
        cpuCores: 16,
        memoryGB: 64,
        storageGB: 1024,
        price: ethers.parseEther("0.025").toString(),
        region: "eu-west-2",
        isActive: true,
        createdAt: Math.floor(Date.now() / 1000) - 14 * 24 * 3600, // 14 days ago
        features: ["GPU", "SSD", "TPU"],
        avgRating: 48, // 4.8/5.0
      },
    ]),
    getStorageListings: jest.fn().mockResolvedValue([
      {
        listingId: "2",
        nodeId: "node-789",
        resourceType: 1, // storage
        tier: 3, // standard
        capacityGB: 2048,
        redundancyFactor: 3,
        price: ethers.parseEther("0.005").toString(),
        region: "ap-northeast-1",
        isActive: true,
        createdAt: Math.floor(Date.now() / 1000) - 10 * 24 * 3600, // 10 days ago
        storageType: "SSD",
        avgRating: 43, // 4.3/5.0
      },
    ]),
    createComputeListing: jest.fn().mockResolvedValue("3"),
    createStorageListing: jest.fn().mockResolvedValue("4"),
    updateListingStatus: jest.fn().mockResolvedValue({
      hash: "0xabcdef123456",
      wait: jest.fn().mockResolvedValue({ status: 1 }),
    }),
    getTotalListings: jest.fn().mockResolvedValue(4),
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

describe("ResourceModule", () => {
  let resourceModule: ResourceModule;
  const mockProvider = new ethers.JsonRpcProvider("https://rpc-mock.lisk.io");
  const mockSigner = new ethers.Wallet("0x0123456789abcdef", mockProvider);

  beforeEach(() => {
    // Initialize module with mock provider and contract address
    resourceModule = new ResourceModule(
      mockProvider,
      "0x1234567890123456789012345678901234567890",
      mockSigner
    );
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe("getComputeListings", () => {
    it("should return available compute listings", async () => {
      const listings = await resourceModule.getComputeListings();

      expect(listings).toBeDefined();
      expect(Array.isArray(listings)).toBe(true);
      expect(listings.length).toBe(2);
      expect(listings[0].nodeId).toBe("node-123");
      expect(listings[0].resourceType).toBe(0); // compute
      expect(listings[1].cpuCores).toBe(16);
    });
  });

  describe("getStorageListings", () => {
    it("should return available storage listings", async () => {
      const listings = await resourceModule.getStorageListings();

      expect(listings).toBeDefined();
      expect(Array.isArray(listings)).toBe(true);
      expect(listings.length).toBe(1);
      expect(listings[0].nodeId).toBe("node-789");
      expect(listings[0].resourceType).toBe(1); // storage
      expect(listings[0].capacityGB).toBe(2048);
    });
  });

  describe("createComputeListing", () => {
    it("should create a new compute listing and return the listing ID", async () => {
      const nodeId = "node-new";
      const tier = 3; // standard
      const cpuCores = 4;
      const memoryGB = 16;
      const storageGB = 256;
      const pricePerHour = ethers.parseEther("0.015").toString();
      const region = "us-west-2";

      const listingId = await resourceModule.createComputeListing(
        nodeId,
        tier,
        cpuCores,
        memoryGB,
        storageGB,
        pricePerHour,
        region
      );

      expect(listingId).toBe("3");
    });

    it("should throw an error if signer is not provided", async () => {
      // Create a module without signer
      const noSignerModule = new ResourceModule(
        mockProvider,
        "0x1234567890123456789012345678901234567890"
      );

      await expect(
        noSignerModule.createComputeListing(
          "node-new",
          3,
          4,
          16,
          256,
          "15000000000000000",
          "us-west-2"
        )
      ).rejects.toThrow("Signer required for this operation");
    });
  });

  describe("createStorageListing", () => {
    it("should create a new storage listing and return the listing ID", async () => {
      const nodeId = "node-new";
      const tier = 2; // basic
      const capacityGB = 1024;
      const redundancyFactor = 2;
      const pricePerGBMonth = ethers.parseEther("0.0001").toString();
      const region = "eu-central-1";
      const storageType = "HDD";

      const listingId = await resourceModule.createStorageListing(
        nodeId,
        tier,
        capacityGB,
        redundancyFactor,
        pricePerGBMonth,
        region,
        storageType
      );

      expect(listingId).toBe("4");
    });
  });

  describe("updateListingStatus", () => {
    it("should update a listing status and return transaction response", async () => {
      const listingId = "1";
      const isActive = false;

      const result = await resourceModule.updateListingStatus(
        listingId,
        isActive
      );

      expect(result).toBeDefined();
      expect(result.hash).toBe("0xabcdef123456");
    });
  });

  describe("getTotalListings", () => {
    it("should return the total number of resource listings", async () => {
      const count = await resourceModule.getTotalListings();
      expect(count).toBe(4);
    });
  });
});
