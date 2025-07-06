// package: quikdb.health
// file: health.proto

/* tslint:disable */
/* eslint-disable */

import * as grpc from "@grpc/grpc-js";
import * as health_pb from "./health_pb";

interface IHealthServiceService extends grpc.ServiceDefinition<grpc.UntypedServiceImplementation> {
    healthCheck: IHealthServiceService_IHealthCheck;
}

interface IHealthServiceService_IHealthCheck extends grpc.MethodDefinition<health_pb.HealthCheckRequest, health_pb.HealthCheckResponse> {
    path: "/quikdb.health.HealthService/HealthCheck";
    requestStream: false;
    responseStream: false;
    requestSerialize: grpc.serialize<health_pb.HealthCheckRequest>;
    requestDeserialize: grpc.deserialize<health_pb.HealthCheckRequest>;
    responseSerialize: grpc.serialize<health_pb.HealthCheckResponse>;
    responseDeserialize: grpc.deserialize<health_pb.HealthCheckResponse>;
}

export const HealthServiceService: IHealthServiceService;

export interface IHealthServiceServer extends grpc.UntypedServiceImplementation {
    healthCheck: grpc.handleUnaryCall<health_pb.HealthCheckRequest, health_pb.HealthCheckResponse>;
}

export interface IHealthServiceClient {
    healthCheck(request: health_pb.HealthCheckRequest, callback: (error: grpc.ServiceError | null, response: health_pb.HealthCheckResponse) => void): grpc.ClientUnaryCall;
    healthCheck(request: health_pb.HealthCheckRequest, metadata: grpc.Metadata, callback: (error: grpc.ServiceError | null, response: health_pb.HealthCheckResponse) => void): grpc.ClientUnaryCall;
    healthCheck(request: health_pb.HealthCheckRequest, metadata: grpc.Metadata, options: Partial<grpc.CallOptions>, callback: (error: grpc.ServiceError | null, response: health_pb.HealthCheckResponse) => void): grpc.ClientUnaryCall;
}

export class HealthServiceClient extends grpc.Client implements IHealthServiceClient {
    constructor(address: string, credentials: grpc.ChannelCredentials, options?: Partial<grpc.ClientOptions>);
    public healthCheck(request: health_pb.HealthCheckRequest, callback: (error: grpc.ServiceError | null, response: health_pb.HealthCheckResponse) => void): grpc.ClientUnaryCall;
    public healthCheck(request: health_pb.HealthCheckRequest, metadata: grpc.Metadata, callback: (error: grpc.ServiceError | null, response: health_pb.HealthCheckResponse) => void): grpc.ClientUnaryCall;
    public healthCheck(request: health_pb.HealthCheckRequest, metadata: grpc.Metadata, options: Partial<grpc.CallOptions>, callback: (error: grpc.ServiceError | null, response: health_pb.HealthCheckResponse) => void): grpc.ClientUnaryCall;
}
