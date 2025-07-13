// package: quikdb.events
// file: events.proto

/* tslint:disable */
/* eslint-disable */

import * as grpc from "@grpc/grpc-js";
import * as events_pb from "./events_pb";

interface IEventServiceService extends grpc.ServiceDefinition<grpc.UntypedServiceImplementation> {
    streamEvents: IEventServiceService_IStreamEvents;
}

interface IEventServiceService_IStreamEvents extends grpc.MethodDefinition<events_pb.StreamEventsRequest, events_pb.StreamEventsResponse> {
    path: "/quikdb.events.EventService/StreamEvents";
    requestStream: false;
    responseStream: true;
    requestSerialize: grpc.serialize<events_pb.StreamEventsRequest>;
    requestDeserialize: grpc.deserialize<events_pb.StreamEventsRequest>;
    responseSerialize: grpc.serialize<events_pb.StreamEventsResponse>;
    responseDeserialize: grpc.deserialize<events_pb.StreamEventsResponse>;
}

export const EventServiceService: IEventServiceService;

export interface IEventServiceServer extends grpc.UntypedServiceImplementation {
    streamEvents: grpc.handleServerStreamingCall<events_pb.StreamEventsRequest, events_pb.StreamEventsResponse>;
}

export interface IEventServiceClient {
    streamEvents(request: events_pb.StreamEventsRequest, options?: Partial<grpc.CallOptions>): grpc.ClientReadableStream<events_pb.StreamEventsResponse>;
    streamEvents(request: events_pb.StreamEventsRequest, metadata?: grpc.Metadata, options?: Partial<grpc.CallOptions>): grpc.ClientReadableStream<events_pb.StreamEventsResponse>;
}

export class EventServiceClient extends grpc.Client implements IEventServiceClient {
    constructor(address: string, credentials: grpc.ChannelCredentials, options?: Partial<grpc.ClientOptions>);
    public streamEvents(request: events_pb.StreamEventsRequest, options?: Partial<grpc.CallOptions>): grpc.ClientReadableStream<events_pb.StreamEventsResponse>;
    public streamEvents(request: events_pb.StreamEventsRequest, metadata?: grpc.Metadata, options?: Partial<grpc.CallOptions>): grpc.ClientReadableStream<events_pb.StreamEventsResponse>;
}
