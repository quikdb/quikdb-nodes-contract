// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IResourceTypes {
    enum ComputeTier {
        NANO,
        MICRO,
        BASIC,
        STANDARD,
        PREMIUM,
        ENTERPRISE
    }

    enum StorageTier {
        BASIC,
        FAST,
        PREMIUM,
        ARCHIVE
    }

    enum ListingStatus {
        ACTIVE,
        INACTIVE,
        SUSPENDED,
        EXPIRED,
        CANCELLED
    }

    enum AllocationStatus {
        PENDING,
        ACTIVE,
        COMPLETED,
        CANCELLED,
        EXPIRED,
        FAILED
    }

    struct ComputeListing {
        string nodeId;
        address provider;
        uint96 hourlyRate;
        uint32 createdAt;
        uint32 expiresAt;
        ListingStatus status;
        bool isActive;
        string region;
        ComputeTier tier;
        uint32 cpuCores;
        uint32 memoryGB;
        uint32 storageGB;
        string[] tags;
    }

    struct StorageListing {
        string nodeId;
        address provider;
        uint96 hourlyRate;
        uint32 createdAt;
        uint32 expiresAt;
        ListingStatus status;
        bool isActive;
        string region;
        StorageTier tier;
        uint32 storageGB;
        string[] features;
    }

    struct ResourceAllocation {
        bytes32 listingId;
        address customer;
        address provider;
        string nodeId;
        AllocationStatus status;
        uint32 duration;
        uint32 createdAt;
        uint32 startedAt;
        uint32 expiresAt;
        uint96 totalCost;
        bool isActive;
        string containerInfo;
    }

    struct PerformanceMetrics {
        uint32 avgResponseTime;
        uint16 uptimePercentage;
        uint32 throughput;
        uint16 errorRate;
        uint32 lastUpdated;
    }
}
