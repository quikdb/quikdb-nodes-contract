// package: quikdb.stats
// file: stats.proto

/* tslint:disable */
/* eslint-disable */

import * as jspb from "google-protobuf";
import * as user_pb from "./user_pb";
import * as node_pb from "./node_pb";

export class SystemStats extends jspb.Message { 

    hasUserStats(): boolean;
    clearUserStats(): void;
    getUserStats(): user_pb.UserStats | undefined;
    setUserStats(value?: user_pb.UserStats): SystemStats;

    hasNodeStats(): boolean;
    clearNodeStats(): void;
    getNodeStats(): node_pb.NodeStats | undefined;
    setNodeStats(value?: node_pb.NodeStats): SystemStats;
    getTotalTransactions(): number;
    setTotalTransactions(value: number): SystemStats;
    getTotalVolume(): number;
    setTotalVolume(value: number): SystemStats;
    getLastUpdated(): number;
    setLastUpdated(value: number): SystemStats;

    serializeBinary(): Uint8Array;
    toObject(includeInstance?: boolean): SystemStats.AsObject;
    static toObject(includeInstance: boolean, msg: SystemStats): SystemStats.AsObject;
    static extensions: {[key: number]: jspb.ExtensionFieldInfo<jspb.Message>};
    static extensionsBinary: {[key: number]: jspb.ExtensionFieldBinaryInfo<jspb.Message>};
    static serializeBinaryToWriter(message: SystemStats, writer: jspb.BinaryWriter): void;
    static deserializeBinary(bytes: Uint8Array): SystemStats;
    static deserializeBinaryFromReader(message: SystemStats, reader: jspb.BinaryReader): SystemStats;
}

export namespace SystemStats {
    export type AsObject = {
        userStats?: user_pb.UserStats.AsObject,
        nodeStats?: node_pb.NodeStats.AsObject,
        totalTransactions: number,
        totalVolume: number,
        lastUpdated: number,
    }
}

export class GetSystemStatsRequest extends jspb.Message { 

    serializeBinary(): Uint8Array;
    toObject(includeInstance?: boolean): GetSystemStatsRequest.AsObject;
    static toObject(includeInstance: boolean, msg: GetSystemStatsRequest): GetSystemStatsRequest.AsObject;
    static extensions: {[key: number]: jspb.ExtensionFieldInfo<jspb.Message>};
    static extensionsBinary: {[key: number]: jspb.ExtensionFieldBinaryInfo<jspb.Message>};
    static serializeBinaryToWriter(message: GetSystemStatsRequest, writer: jspb.BinaryWriter): void;
    static deserializeBinary(bytes: Uint8Array): GetSystemStatsRequest;
    static deserializeBinaryFromReader(message: GetSystemStatsRequest, reader: jspb.BinaryReader): GetSystemStatsRequest;
}

export namespace GetSystemStatsRequest {
    export type AsObject = {
    }
}

export class GetSystemStatsResponse extends jspb.Message { 

    hasStats(): boolean;
    clearStats(): void;
    getStats(): SystemStats | undefined;
    setStats(value?: SystemStats): GetSystemStatsResponse;

    serializeBinary(): Uint8Array;
    toObject(includeInstance?: boolean): GetSystemStatsResponse.AsObject;
    static toObject(includeInstance: boolean, msg: GetSystemStatsResponse): GetSystemStatsResponse.AsObject;
    static extensions: {[key: number]: jspb.ExtensionFieldInfo<jspb.Message>};
    static extensionsBinary: {[key: number]: jspb.ExtensionFieldBinaryInfo<jspb.Message>};
    static serializeBinaryToWriter(message: GetSystemStatsResponse, writer: jspb.BinaryWriter): void;
    static deserializeBinary(bytes: Uint8Array): GetSystemStatsResponse;
    static deserializeBinaryFromReader(message: GetSystemStatsResponse, reader: jspb.BinaryReader): GetSystemStatsResponse;
}

export namespace GetSystemStatsResponse {
    export type AsObject = {
        stats?: SystemStats.AsObject,
    }
}
