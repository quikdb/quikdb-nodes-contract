// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IResourceTrackingEvents {
    // Container Events
    event ContainerCreated(
        bytes32 indexed containerId,
        address indexed nodeOperator,
        address indexed customer,
        bytes32 purchaseId,
        string imageHash,
        uint256 cpuAllocation,
        uint256 memoryAllocation,
        uint256 storageAllocation,
        uint256 timestamp
    );
    event ContainerDeployed(
        bytes32 indexed containerId,
        address indexed nodeOperator,
        string nodeId,
        uint256 deploymentTime,
        uint256 timestamp
    );
    event ContainerStarted(
        bytes32 indexed containerId, address indexed nodeOperator, uint256 startTime, uint256 timestamp
    );
    event ContainerStopped(
        bytes32 indexed containerId, address indexed nodeOperator, uint256 stopTime, string reason, uint256 timestamp
    );
    event ContainerFailed(
        bytes32 indexed containerId,
        address indexed nodeOperator,
        string errorCode,
        string errorMessage,
        uint256 timestamp
    );
    event ContainerDestroyed(
        bytes32 indexed containerId, address indexed nodeOperator, uint256 destructionTime, uint256 timestamp
    );
    event ContainerResourceUsage(
        bytes32 indexed containerId,
        address indexed nodeOperator,
        uint256 cpuUsagePercent,
        uint256 memoryUsageBytes,
        uint256 storageUsageBytes,
        uint256 networkInBytes,
        uint256 networkOutBytes,
        uint256 timestamp
    );
    event ContainerHealthCheck(
        bytes32 indexed containerId,
        address indexed nodeOperator,
        bool isHealthy,
        uint256 responseTime,
        string healthStatus,
        uint256 timestamp
    );
    event ContainerPerformanceMetrics(
        bytes32 indexed containerId,
        address indexed nodeOperator,
        uint256 averageCpu,
        uint256 peakMemory,
        uint256 ioOperations,
        uint256 uptimeSeconds,
        uint256 timestamp
    );

    // Storage Events
    event FileUploaded(
        bytes32 indexed fileId,
        address indexed uploader,
        bytes32 storageContractId,
        string fileName,
        uint256 fileSize,
        string fileHash,
        uint256 timestamp
    );
    event FileDownloaded(
        bytes32 indexed fileId,
        address indexed downloader,
        bytes32 storageContractId,
        uint256 downloadSize,
        uint256 timestamp
    );
    event FileDeleted(bytes32 indexed fileId, address indexed owner, bytes32 storageContractId, uint256 timestamp);
    event StorageNodeAssigned(
        bytes32 indexed fileId, address indexed nodeOperator, string nodeId, bool isPrimary, uint256 timestamp
    );
    event StorageNodeReassigned(
        bytes32 indexed fileId,
        address indexed oldNodeOperator,
        address indexed newNodeOperator,
        string reason,
        uint256 timestamp
    );
    event FileReplicationStarted(
        bytes32 indexed fileId,
        address indexed sourceNode,
        address indexed targetNode,
        uint256 replicationFactor,
        uint256 timestamp
    );
    event FileReplicationCompleted(
        bytes32 indexed fileId, address indexed sourceNode, address indexed targetNode, bool success, uint256 timestamp
    );
    event DataIntegrityCheck(
        bytes32 indexed fileId,
        address indexed nodeOperator,
        string computedHash,
        string expectedHash,
        bool isValid,
        uint256 timestamp
    );
    event DataCorruptionDetected(
        bytes32 indexed fileId, address indexed nodeOperator, string corruptionType, uint256 timestamp
    );
    event StorageBucketCreated(
        bytes32 indexed bucketId, address indexed owner, string bucketName, uint256 maxSize, uint256 timestamp
    );
    event StorageBucketUpdated(bytes32 indexed bucketId, address indexed owner, uint256 newMaxSize, uint256 timestamp);
    event StorageBucketDeleted(bytes32 indexed bucketId, address indexed owner, uint256 timestamp);

    // Node Management Events
    event NodeRegistered(
        address indexed nodeOperator,
        string nodeId,
        string nodeType,
        uint256 cpuCores,
        uint256 memoryGB,
        uint256 storageGB,
        uint256 networkSpeed,
        string region,
        uint256 timestamp
    );
    event NodeDeregistered(address indexed nodeOperator, string nodeId, string reason, uint256 timestamp);
    event NodeVerified(
        address indexed nodeOperator, string nodeId, address indexed verifier, bool isVerified, uint256 timestamp
    );
    event NodeCapacityUpdated(
        address indexed nodeOperator,
        string nodeId,
        uint256 availableCpu,
        uint256 availableMemory,
        uint256 availableStorage,
        uint256 timestamp
    );
    event NodeAvailabilityChanged(
        address indexed nodeOperator, string nodeId, bool isOnline, bool acceptingJobs, uint256 timestamp
    );
    event NodePerformanceReport(
        address indexed nodeOperator,
        string nodeId,
        uint256 completedJobs,
        uint256 failedJobs,
        uint256 averageResponseTime,
        uint256 uptimePercent,
        uint256 timestamp
    );
    event NodeReputationUpdated(
        address indexed nodeOperator,
        string nodeId,
        uint256 oldScore,
        uint256 newScore,
        string reason,
        uint256 timestamp
    );
    event NodeHealthReport(
        address indexed nodeOperator,
        string nodeId,
        bool isHealthy,
        uint256 cpuUsage,
        uint256 memoryUsage,
        uint256 diskUsage,
        uint256 temperature,
        uint256 timestamp
    );
    event NodeMaintenanceScheduled(
        address indexed nodeOperator,
        string nodeId,
        uint256 maintenanceStart,
        uint256 estimatedDuration,
        string maintenanceType,
        uint256 timestamp
    );
    event NodeEarningsCalculated(
        address indexed nodeOperator,
        string nodeId,
        uint256 computeEarnings,
        uint256 storageEarnings,
        uint256 bonusEarnings,
        uint256 period,
        uint256 timestamp
    );
    event NodePaymentProcessed(
        address indexed nodeOperator, string nodeId, uint256 amount, bytes32 paymentId, uint256 timestamp
    );

    // Billing Events
    event ResourceUsageRecorded(
        bytes32 indexed resourceId,
        address indexed customer,
        address indexed nodeOperator,
        string resourceType,
        uint256 unitsConsumed,
        uint256 ratePerUnit,
        uint256 cost,
        uint256 timestamp
    );
    event BillingCycleStarted(
        address indexed customer, uint256 cycleId, uint256 startTime, uint256 endTime, uint256 timestamp
    );
    event BillingCycleCompleted(
        address indexed customer, uint256 cycleId, uint256 totalUsage, uint256 totalCost, uint256 timestamp
    );
    event PricingModelUpdated(
        string resourceType, uint256 oldRate, uint256 newRate, uint256 effectiveDate, uint256 timestamp
    );
    event CostCalculated(
        bytes32 indexed resourceId,
        address indexed customer,
        uint256 usageAmount,
        uint256 rate,
        uint256 totalCost,
        uint256 timestamp
    );
    event PaymentRequired(
        address indexed customer, uint256 invoiceId, uint256 amountDue, uint256 dueDate, uint256 timestamp
    );
    event PaymentReceived(
        address indexed customer, uint256 invoiceId, uint256 amountPaid, bytes32 paymentHash, uint256 timestamp
    );
    event PaymentOverdue(
        address indexed customer, uint256 invoiceId, uint256 amountOverdue, uint256 daysPastDue, uint256 timestamp
    );
    event RevenueDistributed(uint256 totalRevenue, uint256 platformFee, uint256 nodeOperatorShare, uint256 timestamp);
    event NodeOperatorPayout(
        address indexed nodeOperator, uint256 amount, uint256 period, bytes32 payoutId, uint256 timestamp
    );
    event UsageAnalyticsGenerated(
        address indexed customer,
        uint256 period,
        uint256 totalComputeHours,
        uint256 totalStorageGB,
        uint256 totalNetworkGB,
        uint256 totalCost,
        uint256 timestamp
    );
    event PlatformUsageReport(
        uint256 period,
        uint256 totalActiveUsers,
        uint256 totalComputeHours,
        uint256 totalStorageGB,
        uint256 totalRevenue,
        uint256 timestamp
    );

    // Job Events
    event JobCreated(
        bytes32 indexed jobId,
        address indexed customer,
        bytes32 computeContractId,
        string jobType,
        string jobSpecHash,
        uint256 estimatedDuration,
        uint256 maxCost,
        uint256 timestamp
    );
    event JobAssigned(
        bytes32 indexed jobId,
        address indexed nodeOperator,
        bytes32 containerId,
        uint256 assignmentTime,
        uint256 timestamp
    );
    event JobStarted(
        bytes32 indexed jobId, address indexed nodeOperator, bytes32 containerId, uint256 startTime, uint256 timestamp
    );
    event JobProgressUpdate(
        bytes32 indexed jobId,
        address indexed nodeOperator,
        uint256 progressPercent,
        string statusMessage,
        uint256 timestamp
    );
    event JobCompleted(
        bytes32 indexed jobId,
        address indexed nodeOperator,
        bytes32 containerId,
        bool success,
        string resultHash,
        uint256 completionTime,
        uint256 actualCost,
        uint256 timestamp
    );
    event JobFailed(
        bytes32 indexed jobId,
        address indexed nodeOperator,
        bytes32 containerId,
        string errorCode,
        string errorMessage,
        uint256 timestamp
    );
    event JobResultVerified(
        bytes32 indexed jobId, address indexed verifier, bool isValid, string verificationHash, uint256 timestamp
    );
    event JobResultDisputed(bytes32 indexed jobId, address indexed disputer, string disputeReason, uint256 timestamp);
}
