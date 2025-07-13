// package: quikdb.node
// file: node.proto

/* tslint:disable */
/* eslint-disable */

import * as jspb from "google-protobuf";
import * as common_pb from "./common_pb";

export class NodeCapacity extends jspb.Message { 
    getCpuCores(): number;
    setCpuCores(value: number): NodeCapacity;
    getMemoryGb(): number;
    setMemoryGb(value: number): NodeCapacity;
    getStorageGb(): number;
    setStorageGb(value: number): NodeCapacity;
    getNetworkMbps(): number;
    setNetworkMbps(value: number): NodeCapacity;
    getGpuCount(): number;
    setGpuCount(value: number): NodeCapacity;
    getGpuType(): string;
    setGpuType(value: string): NodeCapacity;

    serializeBinary(): Uint8Array;
    toObject(includeInstance?: boolean): NodeCapacity.AsObject;
    static toObject(includeInstance: boolean, msg: NodeCapacity): NodeCapacity.AsObject;
    static extensions: {[key: number]: jspb.ExtensionFieldInfo<jspb.Message>};
    static extensionsBinary: {[key: number]: jspb.ExtensionFieldBinaryInfo<jspb.Message>};
    static serializeBinaryToWriter(message: NodeCapacity, writer: jspb.BinaryWriter): void;
    static deserializeBinary(bytes: Uint8Array): NodeCapacity;
    static deserializeBinaryFromReader(message: NodeCapacity, reader: jspb.BinaryReader): NodeCapacity;
}

export namespace NodeCapacity {
    export type AsObject = {
        cpuCores: number,
        memoryGb: number,
        storageGb: number,
        networkMbps: number,
        gpuCount: number,
        gpuType: string,
    }
}

export class NodeMetrics extends jspb.Message { 
    getUptimePercentage(): number;
    setUptimePercentage(value: number): NodeMetrics;
    getTotalJobs(): number;
    setTotalJobs(value: number): NodeMetrics;
    getSuccessfulJobs(): number;
    setSuccessfulJobs(value: number): NodeMetrics;
    getTotalEarnings(): string;
    setTotalEarnings(value: string): NodeMetrics;
    getLastHeartbeat(): number;
    setLastHeartbeat(value: number): NodeMetrics;
    getAvgResponseTime(): number;
    setAvgResponseTime(value: number): NodeMetrics;

    serializeBinary(): Uint8Array;
    toObject(includeInstance?: boolean): NodeMetrics.AsObject;
    static toObject(includeInstance: boolean, msg: NodeMetrics): NodeMetrics.AsObject;
    static extensions: {[key: number]: jspb.ExtensionFieldInfo<jspb.Message>};
    static extensionsBinary: {[key: number]: jspb.ExtensionFieldBinaryInfo<jspb.Message>};
    static serializeBinaryToWriter(message: NodeMetrics, writer: jspb.BinaryWriter): void;
    static deserializeBinary(bytes: Uint8Array): NodeMetrics;
    static deserializeBinaryFromReader(message: NodeMetrics, reader: jspb.BinaryReader): NodeMetrics;
}

export namespace NodeMetrics {
    export type AsObject = {
        uptimePercentage: number,
        totalJobs: number,
        successfulJobs: number,
        totalEarnings: string,
        lastHeartbeat: number,
        avgResponseTime: number,
    }
}

export class NodeListing extends jspb.Message { 
    getIsListed(): boolean;
    setIsListed(value: boolean): NodeListing;
    getHourlyRate(): string;
    setHourlyRate(value: string): NodeListing;
    getAvailability(): number;
    setAvailability(value: number): NodeListing;
    getRegion(): string;
    setRegion(value: string): NodeListing;
    clearSupportedServicesList(): void;
    getSupportedServicesList(): Array<string>;
    setSupportedServicesList(value: Array<string>): NodeListing;
    addSupportedServices(value: string, index?: number): string;
    getMinJobDuration(): number;
    setMinJobDuration(value: number): NodeListing;
    getMaxJobDuration(): number;
    setMaxJobDuration(value: number): NodeListing;

    serializeBinary(): Uint8Array;
    toObject(includeInstance?: boolean): NodeListing.AsObject;
    static toObject(includeInstance: boolean, msg: NodeListing): NodeListing.AsObject;
    static extensions: {[key: number]: jspb.ExtensionFieldInfo<jspb.Message>};
    static extensionsBinary: {[key: number]: jspb.ExtensionFieldBinaryInfo<jspb.Message>};
    static serializeBinaryToWriter(message: NodeListing, writer: jspb.BinaryWriter): void;
    static deserializeBinary(bytes: Uint8Array): NodeListing;
    static deserializeBinaryFromReader(message: NodeListing, reader: jspb.BinaryReader): NodeListing;
}

export namespace NodeListing {
    export type AsObject = {
        isListed: boolean,
        hourlyRate: string,
        availability: number,
        region: string,
        supportedServicesList: Array<string>,
        minJobDuration: number,
        maxJobDuration: number,
    }
}

export class NodeExtendedInfo extends jspb.Message { 
    getHardwareFingerprint(): string;
    setHardwareFingerprint(value: string): NodeExtendedInfo;
    getCarbonFootprint(): number;
    setCarbonFootprint(value: number): NodeExtendedInfo;
    clearComplianceList(): void;
    getComplianceList(): Array<string>;
    setComplianceList(value: Array<string>): NodeExtendedInfo;
    addCompliance(value: string, index?: number): string;
    getSecurityScore(): number;
    setSecurityScore(value: number): NodeExtendedInfo;
    getOperatorBio(): string;
    setOperatorBio(value: string): NodeExtendedInfo;
    clearSpecialCapabilitiesList(): void;
    getSpecialCapabilitiesList(): Array<string>;
    setSpecialCapabilitiesList(value: Array<string>): NodeExtendedInfo;
    addSpecialCapabilities(value: string, index?: number): string;
    getBondAmount(): string;
    setBondAmount(value: string): NodeExtendedInfo;
    getIsVerified(): boolean;
    setIsVerified(value: boolean): NodeExtendedInfo;
    getVerificationExpiry(): number;
    setVerificationExpiry(value: number): NodeExtendedInfo;
    getContactInfo(): string;
    setContactInfo(value: string): NodeExtendedInfo;

    serializeBinary(): Uint8Array;
    toObject(includeInstance?: boolean): NodeExtendedInfo.AsObject;
    static toObject(includeInstance: boolean, msg: NodeExtendedInfo): NodeExtendedInfo.AsObject;
    static extensions: {[key: number]: jspb.ExtensionFieldInfo<jspb.Message>};
    static extensionsBinary: {[key: number]: jspb.ExtensionFieldBinaryInfo<jspb.Message>};
    static serializeBinaryToWriter(message: NodeExtendedInfo, writer: jspb.BinaryWriter): void;
    static deserializeBinary(bytes: Uint8Array): NodeExtendedInfo;
    static deserializeBinaryFromReader(message: NodeExtendedInfo, reader: jspb.BinaryReader): NodeExtendedInfo;
}

export namespace NodeExtendedInfo {
    export type AsObject = {
        hardwareFingerprint: string,
        carbonFootprint: number,
        complianceList: Array<string>,
        securityScore: number,
        operatorBio: string,
        specialCapabilitiesList: Array<string>,
        bondAmount: string,
        isVerified: boolean,
        verificationExpiry: number,
        contactInfo: string,
    }
}

export class NodeInfo extends jspb.Message { 
    getNodeId(): string;
    setNodeId(value: string): NodeInfo;
    getNodeAddress(): string;
    setNodeAddress(value: string): NodeInfo;
    getStatus(): NodeStatus;
    setStatus(value: NodeStatus): NodeInfo;
    getProviderType(): ProviderType;
    setProviderType(value: ProviderType): NodeInfo;
    getTier(): NodeTier;
    setTier(value: NodeTier): NodeInfo;

    hasCapacity(): boolean;
    clearCapacity(): void;
    getCapacity(): NodeCapacity | undefined;
    setCapacity(value?: NodeCapacity): NodeInfo;

    hasMetrics(): boolean;
    clearMetrics(): void;
    getMetrics(): NodeMetrics | undefined;
    setMetrics(value?: NodeMetrics): NodeInfo;

    hasListing(): boolean;
    clearListing(): void;
    getListing(): NodeListing | undefined;
    setListing(value?: NodeListing): NodeInfo;
    getRegisteredAt(): number;
    setRegisteredAt(value: number): NodeInfo;
    getLastUpdated(): number;
    setLastUpdated(value: number): NodeInfo;
    getExists(): boolean;
    setExists(value: boolean): NodeInfo;

    hasExtended(): boolean;
    clearExtended(): void;
    getExtended(): NodeExtendedInfo | undefined;
    setExtended(value?: NodeExtendedInfo): NodeInfo;
    clearCertificationsList(): void;
    getCertificationsList(): Array<string>;
    setCertificationsList(value: Array<string>): NodeInfo;
    addCertifications(value: string, index?: number): string;
    clearConnectedNetworksList(): void;
    getConnectedNetworksList(): Array<string>;
    setConnectedNetworksList(value: Array<string>): NodeInfo;
    addConnectedNetworks(value: string, index?: number): string;

    serializeBinary(): Uint8Array;
    toObject(includeInstance?: boolean): NodeInfo.AsObject;
    static toObject(includeInstance: boolean, msg: NodeInfo): NodeInfo.AsObject;
    static extensions: {[key: number]: jspb.ExtensionFieldInfo<jspb.Message>};
    static extensionsBinary: {[key: number]: jspb.ExtensionFieldBinaryInfo<jspb.Message>};
    static serializeBinaryToWriter(message: NodeInfo, writer: jspb.BinaryWriter): void;
    static deserializeBinary(bytes: Uint8Array): NodeInfo;
    static deserializeBinaryFromReader(message: NodeInfo, reader: jspb.BinaryReader): NodeInfo;
}

export namespace NodeInfo {
    export type AsObject = {
        nodeId: string,
        nodeAddress: string,
        status: NodeStatus,
        providerType: ProviderType,
        tier: NodeTier,
        capacity?: NodeCapacity.AsObject,
        metrics?: NodeMetrics.AsObject,
        listing?: NodeListing.AsObject,
        registeredAt: number,
        lastUpdated: number,
        exists: boolean,
        extended?: NodeExtendedInfo.AsObject,
        certificationsList: Array<string>,
        connectedNetworksList: Array<string>,
    }
}

export class NodeStats extends jspb.Message { 
    getTotalNodes(): number;
    setTotalNodes(value: number): NodeStats;
    getActiveNodes(): number;
    setActiveNodes(value: number): NodeStats;
    getListedNodes(): number;
    setListedNodes(value: number): NodeStats;
    getVerifiedNodes(): number;
    setVerifiedNodes(value: number): NodeStats;

    serializeBinary(): Uint8Array;
    toObject(includeInstance?: boolean): NodeStats.AsObject;
    static toObject(includeInstance: boolean, msg: NodeStats): NodeStats.AsObject;
    static extensions: {[key: number]: jspb.ExtensionFieldInfo<jspb.Message>};
    static extensionsBinary: {[key: number]: jspb.ExtensionFieldBinaryInfo<jspb.Message>};
    static serializeBinaryToWriter(message: NodeStats, writer: jspb.BinaryWriter): void;
    static deserializeBinary(bytes: Uint8Array): NodeStats;
    static deserializeBinaryFromReader(message: NodeStats, reader: jspb.BinaryReader): NodeStats;
}

export namespace NodeStats {
    export type AsObject = {
        totalNodes: number,
        activeNodes: number,
        listedNodes: number,
        verifiedNodes: number,
    }
}

export class RegisterNodeRequest extends jspb.Message { 
    getNodeId(): string;
    setNodeId(value: string): RegisterNodeRequest;
    getNodeAddress(): string;
    setNodeAddress(value: string): RegisterNodeRequest;
    getTier(): NodeTier;
    setTier(value: NodeTier): RegisterNodeRequest;
    getProviderType(): ProviderType;
    setProviderType(value: ProviderType): RegisterNodeRequest;

    serializeBinary(): Uint8Array;
    toObject(includeInstance?: boolean): RegisterNodeRequest.AsObject;
    static toObject(includeInstance: boolean, msg: RegisterNodeRequest): RegisterNodeRequest.AsObject;
    static extensions: {[key: number]: jspb.ExtensionFieldInfo<jspb.Message>};
    static extensionsBinary: {[key: number]: jspb.ExtensionFieldBinaryInfo<jspb.Message>};
    static serializeBinaryToWriter(message: RegisterNodeRequest, writer: jspb.BinaryWriter): void;
    static deserializeBinary(bytes: Uint8Array): RegisterNodeRequest;
    static deserializeBinaryFromReader(message: RegisterNodeRequest, reader: jspb.BinaryReader): RegisterNodeRequest;
}

export namespace RegisterNodeRequest {
    export type AsObject = {
        nodeId: string,
        nodeAddress: string,
        tier: NodeTier,
        providerType: ProviderType,
    }
}

export class RegisterNodeResponse extends jspb.Message { 
    getSuccess(): boolean;
    setSuccess(value: boolean): RegisterNodeResponse;
    getTransactionHash(): string;
    setTransactionHash(value: string): RegisterNodeResponse;
    getMessage(): string;
    setMessage(value: string): RegisterNodeResponse;

    serializeBinary(): Uint8Array;
    toObject(includeInstance?: boolean): RegisterNodeResponse.AsObject;
    static toObject(includeInstance: boolean, msg: RegisterNodeResponse): RegisterNodeResponse.AsObject;
    static extensions: {[key: number]: jspb.ExtensionFieldInfo<jspb.Message>};
    static extensionsBinary: {[key: number]: jspb.ExtensionFieldBinaryInfo<jspb.Message>};
    static serializeBinaryToWriter(message: RegisterNodeResponse, writer: jspb.BinaryWriter): void;
    static deserializeBinary(bytes: Uint8Array): RegisterNodeResponse;
    static deserializeBinaryFromReader(message: RegisterNodeResponse, reader: jspb.BinaryReader): RegisterNodeResponse;
}

export namespace RegisterNodeResponse {
    export type AsObject = {
        success: boolean,
        transactionHash: string,
        message: string,
    }
}

export class GetNodeInfoRequest extends jspb.Message { 
    getNodeId(): string;
    setNodeId(value: string): GetNodeInfoRequest;

    serializeBinary(): Uint8Array;
    toObject(includeInstance?: boolean): GetNodeInfoRequest.AsObject;
    static toObject(includeInstance: boolean, msg: GetNodeInfoRequest): GetNodeInfoRequest.AsObject;
    static extensions: {[key: number]: jspb.ExtensionFieldInfo<jspb.Message>};
    static extensionsBinary: {[key: number]: jspb.ExtensionFieldBinaryInfo<jspb.Message>};
    static serializeBinaryToWriter(message: GetNodeInfoRequest, writer: jspb.BinaryWriter): void;
    static deserializeBinary(bytes: Uint8Array): GetNodeInfoRequest;
    static deserializeBinaryFromReader(message: GetNodeInfoRequest, reader: jspb.BinaryReader): GetNodeInfoRequest;
}

export namespace GetNodeInfoRequest {
    export type AsObject = {
        nodeId: string,
    }
}

export class GetNodeInfoResponse extends jspb.Message { 

    hasNode(): boolean;
    clearNode(): void;
    getNode(): NodeInfo | undefined;
    setNode(value?: NodeInfo): GetNodeInfoResponse;

    serializeBinary(): Uint8Array;
    toObject(includeInstance?: boolean): GetNodeInfoResponse.AsObject;
    static toObject(includeInstance: boolean, msg: GetNodeInfoResponse): GetNodeInfoResponse.AsObject;
    static extensions: {[key: number]: jspb.ExtensionFieldInfo<jspb.Message>};
    static extensionsBinary: {[key: number]: jspb.ExtensionFieldBinaryInfo<jspb.Message>};
    static serializeBinaryToWriter(message: GetNodeInfoResponse, writer: jspb.BinaryWriter): void;
    static deserializeBinary(bytes: Uint8Array): GetNodeInfoResponse;
    static deserializeBinaryFromReader(message: GetNodeInfoResponse, reader: jspb.BinaryReader): GetNodeInfoResponse;
}

export namespace GetNodeInfoResponse {
    export type AsObject = {
        node?: NodeInfo.AsObject,
    }
}

export class UpdateNodeStatusRequest extends jspb.Message { 
    getNodeId(): string;
    setNodeId(value: string): UpdateNodeStatusRequest;
    getStatus(): NodeStatus;
    setStatus(value: NodeStatus): UpdateNodeStatusRequest;

    serializeBinary(): Uint8Array;
    toObject(includeInstance?: boolean): UpdateNodeStatusRequest.AsObject;
    static toObject(includeInstance: boolean, msg: UpdateNodeStatusRequest): UpdateNodeStatusRequest.AsObject;
    static extensions: {[key: number]: jspb.ExtensionFieldInfo<jspb.Message>};
    static extensionsBinary: {[key: number]: jspb.ExtensionFieldBinaryInfo<jspb.Message>};
    static serializeBinaryToWriter(message: UpdateNodeStatusRequest, writer: jspb.BinaryWriter): void;
    static deserializeBinary(bytes: Uint8Array): UpdateNodeStatusRequest;
    static deserializeBinaryFromReader(message: UpdateNodeStatusRequest, reader: jspb.BinaryReader): UpdateNodeStatusRequest;
}

export namespace UpdateNodeStatusRequest {
    export type AsObject = {
        nodeId: string,
        status: NodeStatus,
    }
}

export class UpdateNodeStatusResponse extends jspb.Message { 
    getSuccess(): boolean;
    setSuccess(value: boolean): UpdateNodeStatusResponse;
    getTransactionHash(): string;
    setTransactionHash(value: string): UpdateNodeStatusResponse;
    getMessage(): string;
    setMessage(value: string): UpdateNodeStatusResponse;

    serializeBinary(): Uint8Array;
    toObject(includeInstance?: boolean): UpdateNodeStatusResponse.AsObject;
    static toObject(includeInstance: boolean, msg: UpdateNodeStatusResponse): UpdateNodeStatusResponse.AsObject;
    static extensions: {[key: number]: jspb.ExtensionFieldInfo<jspb.Message>};
    static extensionsBinary: {[key: number]: jspb.ExtensionFieldBinaryInfo<jspb.Message>};
    static serializeBinaryToWriter(message: UpdateNodeStatusResponse, writer: jspb.BinaryWriter): void;
    static deserializeBinary(bytes: Uint8Array): UpdateNodeStatusResponse;
    static deserializeBinaryFromReader(message: UpdateNodeStatusResponse, reader: jspb.BinaryReader): UpdateNodeStatusResponse;
}

export namespace UpdateNodeStatusResponse {
    export type AsObject = {
        success: boolean,
        transactionHash: string,
        message: string,
    }
}

export class UpdateNodeExtendedInfoRequest extends jspb.Message { 
    getNodeId(): string;
    setNodeId(value: string): UpdateNodeExtendedInfoRequest;

    hasExtended(): boolean;
    clearExtended(): void;
    getExtended(): NodeExtendedInfo | undefined;
    setExtended(value?: NodeExtendedInfo): UpdateNodeExtendedInfoRequest;

    serializeBinary(): Uint8Array;
    toObject(includeInstance?: boolean): UpdateNodeExtendedInfoRequest.AsObject;
    static toObject(includeInstance: boolean, msg: UpdateNodeExtendedInfoRequest): UpdateNodeExtendedInfoRequest.AsObject;
    static extensions: {[key: number]: jspb.ExtensionFieldInfo<jspb.Message>};
    static extensionsBinary: {[key: number]: jspb.ExtensionFieldBinaryInfo<jspb.Message>};
    static serializeBinaryToWriter(message: UpdateNodeExtendedInfoRequest, writer: jspb.BinaryWriter): void;
    static deserializeBinary(bytes: Uint8Array): UpdateNodeExtendedInfoRequest;
    static deserializeBinaryFromReader(message: UpdateNodeExtendedInfoRequest, reader: jspb.BinaryReader): UpdateNodeExtendedInfoRequest;
}

export namespace UpdateNodeExtendedInfoRequest {
    export type AsObject = {
        nodeId: string,
        extended?: NodeExtendedInfo.AsObject,
    }
}

export class UpdateNodeExtendedInfoResponse extends jspb.Message { 
    getSuccess(): boolean;
    setSuccess(value: boolean): UpdateNodeExtendedInfoResponse;
    getTransactionHash(): string;
    setTransactionHash(value: string): UpdateNodeExtendedInfoResponse;
    getMessage(): string;
    setMessage(value: string): UpdateNodeExtendedInfoResponse;

    serializeBinary(): Uint8Array;
    toObject(includeInstance?: boolean): UpdateNodeExtendedInfoResponse.AsObject;
    static toObject(includeInstance: boolean, msg: UpdateNodeExtendedInfoResponse): UpdateNodeExtendedInfoResponse.AsObject;
    static extensions: {[key: number]: jspb.ExtensionFieldInfo<jspb.Message>};
    static extensionsBinary: {[key: number]: jspb.ExtensionFieldBinaryInfo<jspb.Message>};
    static serializeBinaryToWriter(message: UpdateNodeExtendedInfoResponse, writer: jspb.BinaryWriter): void;
    static deserializeBinary(bytes: Uint8Array): UpdateNodeExtendedInfoResponse;
    static deserializeBinaryFromReader(message: UpdateNodeExtendedInfoResponse, reader: jspb.BinaryReader): UpdateNodeExtendedInfoResponse;
}

export namespace UpdateNodeExtendedInfoResponse {
    export type AsObject = {
        success: boolean,
        transactionHash: string,
        message: string,
    }
}

export class ListNodeRequest extends jspb.Message { 
    getNodeId(): string;
    setNodeId(value: string): ListNodeRequest;
    getHourlyRate(): string;
    setHourlyRate(value: string): ListNodeRequest;
    getAvailability(): number;
    setAvailability(value: number): ListNodeRequest;

    serializeBinary(): Uint8Array;
    toObject(includeInstance?: boolean): ListNodeRequest.AsObject;
    static toObject(includeInstance: boolean, msg: ListNodeRequest): ListNodeRequest.AsObject;
    static extensions: {[key: number]: jspb.ExtensionFieldInfo<jspb.Message>};
    static extensionsBinary: {[key: number]: jspb.ExtensionFieldBinaryInfo<jspb.Message>};
    static serializeBinaryToWriter(message: ListNodeRequest, writer: jspb.BinaryWriter): void;
    static deserializeBinary(bytes: Uint8Array): ListNodeRequest;
    static deserializeBinaryFromReader(message: ListNodeRequest, reader: jspb.BinaryReader): ListNodeRequest;
}

export namespace ListNodeRequest {
    export type AsObject = {
        nodeId: string,
        hourlyRate: string,
        availability: number,
    }
}

export class ListNodeResponse extends jspb.Message { 
    getSuccess(): boolean;
    setSuccess(value: boolean): ListNodeResponse;
    getTransactionHash(): string;
    setTransactionHash(value: string): ListNodeResponse;
    getMessage(): string;
    setMessage(value: string): ListNodeResponse;

    serializeBinary(): Uint8Array;
    toObject(includeInstance?: boolean): ListNodeResponse.AsObject;
    static toObject(includeInstance: boolean, msg: ListNodeResponse): ListNodeResponse.AsObject;
    static extensions: {[key: number]: jspb.ExtensionFieldInfo<jspb.Message>};
    static extensionsBinary: {[key: number]: jspb.ExtensionFieldBinaryInfo<jspb.Message>};
    static serializeBinaryToWriter(message: ListNodeResponse, writer: jspb.BinaryWriter): void;
    static deserializeBinary(bytes: Uint8Array): ListNodeResponse;
    static deserializeBinaryFromReader(message: ListNodeResponse, reader: jspb.BinaryReader): ListNodeResponse;
}

export namespace ListNodeResponse {
    export type AsObject = {
        success: boolean,
        transactionHash: string,
        message: string,
    }
}

export class GetNodeStatsRequest extends jspb.Message { 

    serializeBinary(): Uint8Array;
    toObject(includeInstance?: boolean): GetNodeStatsRequest.AsObject;
    static toObject(includeInstance: boolean, msg: GetNodeStatsRequest): GetNodeStatsRequest.AsObject;
    static extensions: {[key: number]: jspb.ExtensionFieldInfo<jspb.Message>};
    static extensionsBinary: {[key: number]: jspb.ExtensionFieldBinaryInfo<jspb.Message>};
    static serializeBinaryToWriter(message: GetNodeStatsRequest, writer: jspb.BinaryWriter): void;
    static deserializeBinary(bytes: Uint8Array): GetNodeStatsRequest;
    static deserializeBinaryFromReader(message: GetNodeStatsRequest, reader: jspb.BinaryReader): GetNodeStatsRequest;
}

export namespace GetNodeStatsRequest {
    export type AsObject = {
    }
}

export class GetNodeStatsResponse extends jspb.Message { 

    hasStats(): boolean;
    clearStats(): void;
    getStats(): NodeStats | undefined;
    setStats(value?: NodeStats): GetNodeStatsResponse;

    serializeBinary(): Uint8Array;
    toObject(includeInstance?: boolean): GetNodeStatsResponse.AsObject;
    static toObject(includeInstance: boolean, msg: GetNodeStatsResponse): GetNodeStatsResponse.AsObject;
    static extensions: {[key: number]: jspb.ExtensionFieldInfo<jspb.Message>};
    static extensionsBinary: {[key: number]: jspb.ExtensionFieldBinaryInfo<jspb.Message>};
    static serializeBinaryToWriter(message: GetNodeStatsResponse, writer: jspb.BinaryWriter): void;
    static deserializeBinary(bytes: Uint8Array): GetNodeStatsResponse;
    static deserializeBinaryFromReader(message: GetNodeStatsResponse, reader: jspb.BinaryReader): GetNodeStatsResponse;
}

export namespace GetNodeStatsResponse {
    export type AsObject = {
        stats?: NodeStats.AsObject,
    }
}

export class GetNodesRequest extends jspb.Message { 

    hasPagination(): boolean;
    clearPagination(): void;
    getPagination(): common_pb.PaginationRequest | undefined;
    setPagination(value?: common_pb.PaginationRequest): GetNodesRequest;
    getStatusFilter(): NodeStatus;
    setStatusFilter(value: NodeStatus): GetNodesRequest;
    getProviderFilter(): ProviderType;
    setProviderFilter(value: ProviderType): GetNodesRequest;
    getTierFilter(): NodeTier;
    setTierFilter(value: NodeTier): GetNodesRequest;
    getVerifiedOnly(): boolean;
    setVerifiedOnly(value: boolean): GetNodesRequest;
    getListedOnly(): boolean;
    setListedOnly(value: boolean): GetNodesRequest;

    serializeBinary(): Uint8Array;
    toObject(includeInstance?: boolean): GetNodesRequest.AsObject;
    static toObject(includeInstance: boolean, msg: GetNodesRequest): GetNodesRequest.AsObject;
    static extensions: {[key: number]: jspb.ExtensionFieldInfo<jspb.Message>};
    static extensionsBinary: {[key: number]: jspb.ExtensionFieldBinaryInfo<jspb.Message>};
    static serializeBinaryToWriter(message: GetNodesRequest, writer: jspb.BinaryWriter): void;
    static deserializeBinary(bytes: Uint8Array): GetNodesRequest;
    static deserializeBinaryFromReader(message: GetNodesRequest, reader: jspb.BinaryReader): GetNodesRequest;
}

export namespace GetNodesRequest {
    export type AsObject = {
        pagination?: common_pb.PaginationRequest.AsObject,
        statusFilter: NodeStatus,
        providerFilter: ProviderType,
        tierFilter: NodeTier,
        verifiedOnly: boolean,
        listedOnly: boolean,
    }
}

export class GetNodesResponse extends jspb.Message { 
    clearNodesList(): void;
    getNodesList(): Array<NodeInfo>;
    setNodesList(value: Array<NodeInfo>): GetNodesResponse;
    addNodes(value?: NodeInfo, index?: number): NodeInfo;

    hasPagination(): boolean;
    clearPagination(): void;
    getPagination(): common_pb.PaginationResponse | undefined;
    setPagination(value?: common_pb.PaginationResponse): GetNodesResponse;

    serializeBinary(): Uint8Array;
    toObject(includeInstance?: boolean): GetNodesResponse.AsObject;
    static toObject(includeInstance: boolean, msg: GetNodesResponse): GetNodesResponse.AsObject;
    static extensions: {[key: number]: jspb.ExtensionFieldInfo<jspb.Message>};
    static extensionsBinary: {[key: number]: jspb.ExtensionFieldBinaryInfo<jspb.Message>};
    static serializeBinaryToWriter(message: GetNodesResponse, writer: jspb.BinaryWriter): void;
    static deserializeBinary(bytes: Uint8Array): GetNodesResponse;
    static deserializeBinaryFromReader(message: GetNodesResponse, reader: jspb.BinaryReader): GetNodesResponse;
}

export namespace GetNodesResponse {
    export type AsObject = {
        nodesList: Array<NodeInfo.AsObject>,
        pagination?: common_pb.PaginationResponse.AsObject,
    }
}

export class StreamNodesRequest extends jspb.Message { 
    getStatusFilter(): NodeStatus;
    setStatusFilter(value: NodeStatus): StreamNodesRequest;
    getProviderFilter(): ProviderType;
    setProviderFilter(value: ProviderType): StreamNodesRequest;
    getTierFilter(): NodeTier;
    setTierFilter(value: NodeTier): StreamNodesRequest;
    getVerifiedOnly(): boolean;
    setVerifiedOnly(value: boolean): StreamNodesRequest;
    getListedOnly(): boolean;
    setListedOnly(value: boolean): StreamNodesRequest;
    getBatchSize(): number;
    setBatchSize(value: number): StreamNodesRequest;

    serializeBinary(): Uint8Array;
    toObject(includeInstance?: boolean): StreamNodesRequest.AsObject;
    static toObject(includeInstance: boolean, msg: StreamNodesRequest): StreamNodesRequest.AsObject;
    static extensions: {[key: number]: jspb.ExtensionFieldInfo<jspb.Message>};
    static extensionsBinary: {[key: number]: jspb.ExtensionFieldBinaryInfo<jspb.Message>};
    static serializeBinaryToWriter(message: StreamNodesRequest, writer: jspb.BinaryWriter): void;
    static deserializeBinary(bytes: Uint8Array): StreamNodesRequest;
    static deserializeBinaryFromReader(message: StreamNodesRequest, reader: jspb.BinaryReader): StreamNodesRequest;
}

export namespace StreamNodesRequest {
    export type AsObject = {
        statusFilter: NodeStatus,
        providerFilter: ProviderType,
        tierFilter: NodeTier,
        verifiedOnly: boolean,
        listedOnly: boolean,
        batchSize: number,
    }
}

export class StreamNodesResponse extends jspb.Message { 
    clearNodesList(): void;
    getNodesList(): Array<NodeInfo>;
    setNodesList(value: Array<NodeInfo>): StreamNodesResponse;
    addNodes(value?: NodeInfo, index?: number): NodeInfo;
    getIsFinalBatch(): boolean;
    setIsFinalBatch(value: boolean): StreamNodesResponse;
    getTotalSent(): number;
    setTotalSent(value: number): StreamNodesResponse;

    serializeBinary(): Uint8Array;
    toObject(includeInstance?: boolean): StreamNodesResponse.AsObject;
    static toObject(includeInstance: boolean, msg: StreamNodesResponse): StreamNodesResponse.AsObject;
    static extensions: {[key: number]: jspb.ExtensionFieldInfo<jspb.Message>};
    static extensionsBinary: {[key: number]: jspb.ExtensionFieldBinaryInfo<jspb.Message>};
    static serializeBinaryToWriter(message: StreamNodesResponse, writer: jspb.BinaryWriter): void;
    static deserializeBinary(bytes: Uint8Array): StreamNodesResponse;
    static deserializeBinaryFromReader(message: StreamNodesResponse, reader: jspb.BinaryReader): StreamNodesResponse;
}

export namespace StreamNodesResponse {
    export type AsObject = {
        nodesList: Array<NodeInfo.AsObject>,
        isFinalBatch: boolean,
        totalSent: number,
    }
}

export enum NodeStatus {
    NODE_STATUS_PENDING = 0,
    NODE_STATUS_ACTIVE = 1,
    NODE_STATUS_MAINTENANCE = 2,
    NODE_STATUS_INACTIVE = 3,
    NODE_STATUS_SUSPENDED = 4,
    NODE_STATUS_TERMINATED = 5,
    NODE_STATUS_BANNED = 6,
}

export enum ProviderType {
    PROVIDER_TYPE_COMPUTE = 0,
    PROVIDER_TYPE_STORAGE = 1,
}

export enum NodeTier {
    NODE_TIER_BASIC = 0,
    NODE_TIER_STANDARD = 1,
    NODE_TIER_PREMIUM = 2,
    NODE_TIER_ENTERPRISE = 3,
    NODE_TIER_HYPERSCALE = 4,
    NODE_TIER_EDGE = 5,
    NODE_TIER_SPECIALTY = 6,
}
