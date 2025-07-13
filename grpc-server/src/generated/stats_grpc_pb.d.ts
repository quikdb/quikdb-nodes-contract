// package: quikdb.stats
// file: stats.proto

/* tslint:disable */
/* eslint-disable */

import * as grpc from "@grpc/grpc-js";
import * as stats_pb from "./stats_pb";
import * as user_pb from "./user_pb";
import * as node_pb from "./node_pb";

interface IStatsServiceService extends grpc.ServiceDefinition<grpc.UntypedServiceImplementation> {
    getSystemStats: IStatsServiceService_IGetSystemStats;
}

interface IStatsServiceService_IGetSystemStats extends grpc.MethodDefinition<stats_pb.GetSystemStatsRequest, stats_pb.GetSystemStatsResponse> {
    path: "/quikdb.stats.StatsService/GetSystemStats";
    requestStream: false;
    responseStream: false;
    requestSerialize: grpc.serialize<stats_pb.GetSystemStatsRequest>;
    requestDeserialize: grpc.deserialize<stats_pb.GetSystemStatsRequest>;
    responseSerialize: grpc.serialize<stats_pb.GetSystemStatsResponse>;
    responseDeserialize: grpc.deserialize<stats_pb.GetSystemStatsResponse>;
}

export const StatsServiceService: IStatsServiceService;

export interface IStatsServiceServer extends grpc.UntypedServiceImplementation {
    getSystemStats: grpc.handleUnaryCall<stats_pb.GetSystemStatsRequest, stats_pb.GetSystemStatsResponse>;
}

export interface IStatsServiceClient {
    getSystemStats(request: stats_pb.GetSystemStatsRequest, callback: (error: grpc.ServiceError | null, response: stats_pb.GetSystemStatsResponse) => void): grpc.ClientUnaryCall;
    getSystemStats(request: stats_pb.GetSystemStatsRequest, metadata: grpc.Metadata, callback: (error: grpc.ServiceError | null, response: stats_pb.GetSystemStatsResponse) => void): grpc.ClientUnaryCall;
    getSystemStats(request: stats_pb.GetSystemStatsRequest, metadata: grpc.Metadata, options: Partial<grpc.CallOptions>, callback: (error: grpc.ServiceError | null, response: stats_pb.GetSystemStatsResponse) => void): grpc.ClientUnaryCall;
}

export class StatsServiceClient extends grpc.Client implements IStatsServiceClient {
    constructor(address: string, credentials: grpc.ChannelCredentials, options?: Partial<grpc.ClientOptions>);
    public getSystemStats(request: stats_pb.GetSystemStatsRequest, callback: (error: grpc.ServiceError | null, response: stats_pb.GetSystemStatsResponse) => void): grpc.ClientUnaryCall;
    public getSystemStats(request: stats_pb.GetSystemStatsRequest, metadata: grpc.Metadata, callback: (error: grpc.ServiceError | null, response: stats_pb.GetSystemStatsResponse) => void): grpc.ClientUnaryCall;
    public getSystemStats(request: stats_pb.GetSystemStatsRequest, metadata: grpc.Metadata, options: Partial<grpc.CallOptions>, callback: (error: grpc.ServiceError | null, response: stats_pb.GetSystemStatsResponse) => void): grpc.ClientUnaryCall;
}
