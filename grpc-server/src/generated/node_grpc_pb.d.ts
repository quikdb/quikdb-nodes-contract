// package: quikdb.node
// file: node.proto

/* tslint:disable */
/* eslint-disable */

import * as grpc from "@grpc/grpc-js";
import * as node_pb from "./node_pb";
import * as common_pb from "./common_pb";

interface INodeServiceService extends grpc.ServiceDefinition<grpc.UntypedServiceImplementation> {
    registerNode: INodeServiceService_IRegisterNode;
    getNodeInfo: INodeServiceService_IGetNodeInfo;
    updateNodeStatus: INodeServiceService_IUpdateNodeStatus;
    updateNodeExtendedInfo: INodeServiceService_IUpdateNodeExtendedInfo;
    listNode: INodeServiceService_IListNode;
    getNodeStats: INodeServiceService_IGetNodeStats;
    getNodes: INodeServiceService_IGetNodes;
    streamNodes: INodeServiceService_IStreamNodes;
}

interface INodeServiceService_IRegisterNode extends grpc.MethodDefinition<node_pb.RegisterNodeRequest, node_pb.RegisterNodeResponse> {
    path: "/quikdb.node.NodeService/RegisterNode";
    requestStream: false;
    responseStream: false;
    requestSerialize: grpc.serialize<node_pb.RegisterNodeRequest>;
    requestDeserialize: grpc.deserialize<node_pb.RegisterNodeRequest>;
    responseSerialize: grpc.serialize<node_pb.RegisterNodeResponse>;
    responseDeserialize: grpc.deserialize<node_pb.RegisterNodeResponse>;
}
interface INodeServiceService_IGetNodeInfo extends grpc.MethodDefinition<node_pb.GetNodeInfoRequest, node_pb.GetNodeInfoResponse> {
    path: "/quikdb.node.NodeService/GetNodeInfo";
    requestStream: false;
    responseStream: false;
    requestSerialize: grpc.serialize<node_pb.GetNodeInfoRequest>;
    requestDeserialize: grpc.deserialize<node_pb.GetNodeInfoRequest>;
    responseSerialize: grpc.serialize<node_pb.GetNodeInfoResponse>;
    responseDeserialize: grpc.deserialize<node_pb.GetNodeInfoResponse>;
}
interface INodeServiceService_IUpdateNodeStatus extends grpc.MethodDefinition<node_pb.UpdateNodeStatusRequest, node_pb.UpdateNodeStatusResponse> {
    path: "/quikdb.node.NodeService/UpdateNodeStatus";
    requestStream: false;
    responseStream: false;
    requestSerialize: grpc.serialize<node_pb.UpdateNodeStatusRequest>;
    requestDeserialize: grpc.deserialize<node_pb.UpdateNodeStatusRequest>;
    responseSerialize: grpc.serialize<node_pb.UpdateNodeStatusResponse>;
    responseDeserialize: grpc.deserialize<node_pb.UpdateNodeStatusResponse>;
}
interface INodeServiceService_IUpdateNodeExtendedInfo extends grpc.MethodDefinition<node_pb.UpdateNodeExtendedInfoRequest, node_pb.UpdateNodeExtendedInfoResponse> {
    path: "/quikdb.node.NodeService/UpdateNodeExtendedInfo";
    requestStream: false;
    responseStream: false;
    requestSerialize: grpc.serialize<node_pb.UpdateNodeExtendedInfoRequest>;
    requestDeserialize: grpc.deserialize<node_pb.UpdateNodeExtendedInfoRequest>;
    responseSerialize: grpc.serialize<node_pb.UpdateNodeExtendedInfoResponse>;
    responseDeserialize: grpc.deserialize<node_pb.UpdateNodeExtendedInfoResponse>;
}
interface INodeServiceService_IListNode extends grpc.MethodDefinition<node_pb.ListNodeRequest, node_pb.ListNodeResponse> {
    path: "/quikdb.node.NodeService/ListNode";
    requestStream: false;
    responseStream: false;
    requestSerialize: grpc.serialize<node_pb.ListNodeRequest>;
    requestDeserialize: grpc.deserialize<node_pb.ListNodeRequest>;
    responseSerialize: grpc.serialize<node_pb.ListNodeResponse>;
    responseDeserialize: grpc.deserialize<node_pb.ListNodeResponse>;
}
interface INodeServiceService_IGetNodeStats extends grpc.MethodDefinition<node_pb.GetNodeStatsRequest, node_pb.GetNodeStatsResponse> {
    path: "/quikdb.node.NodeService/GetNodeStats";
    requestStream: false;
    responseStream: false;
    requestSerialize: grpc.serialize<node_pb.GetNodeStatsRequest>;
    requestDeserialize: grpc.deserialize<node_pb.GetNodeStatsRequest>;
    responseSerialize: grpc.serialize<node_pb.GetNodeStatsResponse>;
    responseDeserialize: grpc.deserialize<node_pb.GetNodeStatsResponse>;
}
interface INodeServiceService_IGetNodes extends grpc.MethodDefinition<node_pb.GetNodesRequest, node_pb.GetNodesResponse> {
    path: "/quikdb.node.NodeService/GetNodes";
    requestStream: false;
    responseStream: false;
    requestSerialize: grpc.serialize<node_pb.GetNodesRequest>;
    requestDeserialize: grpc.deserialize<node_pb.GetNodesRequest>;
    responseSerialize: grpc.serialize<node_pb.GetNodesResponse>;
    responseDeserialize: grpc.deserialize<node_pb.GetNodesResponse>;
}
interface INodeServiceService_IStreamNodes extends grpc.MethodDefinition<node_pb.StreamNodesRequest, node_pb.StreamNodesResponse> {
    path: "/quikdb.node.NodeService/StreamNodes";
    requestStream: false;
    responseStream: true;
    requestSerialize: grpc.serialize<node_pb.StreamNodesRequest>;
    requestDeserialize: grpc.deserialize<node_pb.StreamNodesRequest>;
    responseSerialize: grpc.serialize<node_pb.StreamNodesResponse>;
    responseDeserialize: grpc.deserialize<node_pb.StreamNodesResponse>;
}

export const NodeServiceService: INodeServiceService;

export interface INodeServiceServer extends grpc.UntypedServiceImplementation {
    registerNode: grpc.handleUnaryCall<node_pb.RegisterNodeRequest, node_pb.RegisterNodeResponse>;
    getNodeInfo: grpc.handleUnaryCall<node_pb.GetNodeInfoRequest, node_pb.GetNodeInfoResponse>;
    updateNodeStatus: grpc.handleUnaryCall<node_pb.UpdateNodeStatusRequest, node_pb.UpdateNodeStatusResponse>;
    updateNodeExtendedInfo: grpc.handleUnaryCall<node_pb.UpdateNodeExtendedInfoRequest, node_pb.UpdateNodeExtendedInfoResponse>;
    listNode: grpc.handleUnaryCall<node_pb.ListNodeRequest, node_pb.ListNodeResponse>;
    getNodeStats: grpc.handleUnaryCall<node_pb.GetNodeStatsRequest, node_pb.GetNodeStatsResponse>;
    getNodes: grpc.handleUnaryCall<node_pb.GetNodesRequest, node_pb.GetNodesResponse>;
    streamNodes: grpc.handleServerStreamingCall<node_pb.StreamNodesRequest, node_pb.StreamNodesResponse>;
}

export interface INodeServiceClient {
    registerNode(request: node_pb.RegisterNodeRequest, callback: (error: grpc.ServiceError | null, response: node_pb.RegisterNodeResponse) => void): grpc.ClientUnaryCall;
    registerNode(request: node_pb.RegisterNodeRequest, metadata: grpc.Metadata, callback: (error: grpc.ServiceError | null, response: node_pb.RegisterNodeResponse) => void): grpc.ClientUnaryCall;
    registerNode(request: node_pb.RegisterNodeRequest, metadata: grpc.Metadata, options: Partial<grpc.CallOptions>, callback: (error: grpc.ServiceError | null, response: node_pb.RegisterNodeResponse) => void): grpc.ClientUnaryCall;
    getNodeInfo(request: node_pb.GetNodeInfoRequest, callback: (error: grpc.ServiceError | null, response: node_pb.GetNodeInfoResponse) => void): grpc.ClientUnaryCall;
    getNodeInfo(request: node_pb.GetNodeInfoRequest, metadata: grpc.Metadata, callback: (error: grpc.ServiceError | null, response: node_pb.GetNodeInfoResponse) => void): grpc.ClientUnaryCall;
    getNodeInfo(request: node_pb.GetNodeInfoRequest, metadata: grpc.Metadata, options: Partial<grpc.CallOptions>, callback: (error: grpc.ServiceError | null, response: node_pb.GetNodeInfoResponse) => void): grpc.ClientUnaryCall;
    updateNodeStatus(request: node_pb.UpdateNodeStatusRequest, callback: (error: grpc.ServiceError | null, response: node_pb.UpdateNodeStatusResponse) => void): grpc.ClientUnaryCall;
    updateNodeStatus(request: node_pb.UpdateNodeStatusRequest, metadata: grpc.Metadata, callback: (error: grpc.ServiceError | null, response: node_pb.UpdateNodeStatusResponse) => void): grpc.ClientUnaryCall;
    updateNodeStatus(request: node_pb.UpdateNodeStatusRequest, metadata: grpc.Metadata, options: Partial<grpc.CallOptions>, callback: (error: grpc.ServiceError | null, response: node_pb.UpdateNodeStatusResponse) => void): grpc.ClientUnaryCall;
    updateNodeExtendedInfo(request: node_pb.UpdateNodeExtendedInfoRequest, callback: (error: grpc.ServiceError | null, response: node_pb.UpdateNodeExtendedInfoResponse) => void): grpc.ClientUnaryCall;
    updateNodeExtendedInfo(request: node_pb.UpdateNodeExtendedInfoRequest, metadata: grpc.Metadata, callback: (error: grpc.ServiceError | null, response: node_pb.UpdateNodeExtendedInfoResponse) => void): grpc.ClientUnaryCall;
    updateNodeExtendedInfo(request: node_pb.UpdateNodeExtendedInfoRequest, metadata: grpc.Metadata, options: Partial<grpc.CallOptions>, callback: (error: grpc.ServiceError | null, response: node_pb.UpdateNodeExtendedInfoResponse) => void): grpc.ClientUnaryCall;
    listNode(request: node_pb.ListNodeRequest, callback: (error: grpc.ServiceError | null, response: node_pb.ListNodeResponse) => void): grpc.ClientUnaryCall;
    listNode(request: node_pb.ListNodeRequest, metadata: grpc.Metadata, callback: (error: grpc.ServiceError | null, response: node_pb.ListNodeResponse) => void): grpc.ClientUnaryCall;
    listNode(request: node_pb.ListNodeRequest, metadata: grpc.Metadata, options: Partial<grpc.CallOptions>, callback: (error: grpc.ServiceError | null, response: node_pb.ListNodeResponse) => void): grpc.ClientUnaryCall;
    getNodeStats(request: node_pb.GetNodeStatsRequest, callback: (error: grpc.ServiceError | null, response: node_pb.GetNodeStatsResponse) => void): grpc.ClientUnaryCall;
    getNodeStats(request: node_pb.GetNodeStatsRequest, metadata: grpc.Metadata, callback: (error: grpc.ServiceError | null, response: node_pb.GetNodeStatsResponse) => void): grpc.ClientUnaryCall;
    getNodeStats(request: node_pb.GetNodeStatsRequest, metadata: grpc.Metadata, options: Partial<grpc.CallOptions>, callback: (error: grpc.ServiceError | null, response: node_pb.GetNodeStatsResponse) => void): grpc.ClientUnaryCall;
    getNodes(request: node_pb.GetNodesRequest, callback: (error: grpc.ServiceError | null, response: node_pb.GetNodesResponse) => void): grpc.ClientUnaryCall;
    getNodes(request: node_pb.GetNodesRequest, metadata: grpc.Metadata, callback: (error: grpc.ServiceError | null, response: node_pb.GetNodesResponse) => void): grpc.ClientUnaryCall;
    getNodes(request: node_pb.GetNodesRequest, metadata: grpc.Metadata, options: Partial<grpc.CallOptions>, callback: (error: grpc.ServiceError | null, response: node_pb.GetNodesResponse) => void): grpc.ClientUnaryCall;
    streamNodes(request: node_pb.StreamNodesRequest, options?: Partial<grpc.CallOptions>): grpc.ClientReadableStream<node_pb.StreamNodesResponse>;
    streamNodes(request: node_pb.StreamNodesRequest, metadata?: grpc.Metadata, options?: Partial<grpc.CallOptions>): grpc.ClientReadableStream<node_pb.StreamNodesResponse>;
}

export class NodeServiceClient extends grpc.Client implements INodeServiceClient {
    constructor(address: string, credentials: grpc.ChannelCredentials, options?: Partial<grpc.ClientOptions>);
    public registerNode(request: node_pb.RegisterNodeRequest, callback: (error: grpc.ServiceError | null, response: node_pb.RegisterNodeResponse) => void): grpc.ClientUnaryCall;
    public registerNode(request: node_pb.RegisterNodeRequest, metadata: grpc.Metadata, callback: (error: grpc.ServiceError | null, response: node_pb.RegisterNodeResponse) => void): grpc.ClientUnaryCall;
    public registerNode(request: node_pb.RegisterNodeRequest, metadata: grpc.Metadata, options: Partial<grpc.CallOptions>, callback: (error: grpc.ServiceError | null, response: node_pb.RegisterNodeResponse) => void): grpc.ClientUnaryCall;
    public getNodeInfo(request: node_pb.GetNodeInfoRequest, callback: (error: grpc.ServiceError | null, response: node_pb.GetNodeInfoResponse) => void): grpc.ClientUnaryCall;
    public getNodeInfo(request: node_pb.GetNodeInfoRequest, metadata: grpc.Metadata, callback: (error: grpc.ServiceError | null, response: node_pb.GetNodeInfoResponse) => void): grpc.ClientUnaryCall;
    public getNodeInfo(request: node_pb.GetNodeInfoRequest, metadata: grpc.Metadata, options: Partial<grpc.CallOptions>, callback: (error: grpc.ServiceError | null, response: node_pb.GetNodeInfoResponse) => void): grpc.ClientUnaryCall;
    public updateNodeStatus(request: node_pb.UpdateNodeStatusRequest, callback: (error: grpc.ServiceError | null, response: node_pb.UpdateNodeStatusResponse) => void): grpc.ClientUnaryCall;
    public updateNodeStatus(request: node_pb.UpdateNodeStatusRequest, metadata: grpc.Metadata, callback: (error: grpc.ServiceError | null, response: node_pb.UpdateNodeStatusResponse) => void): grpc.ClientUnaryCall;
    public updateNodeStatus(request: node_pb.UpdateNodeStatusRequest, metadata: grpc.Metadata, options: Partial<grpc.CallOptions>, callback: (error: grpc.ServiceError | null, response: node_pb.UpdateNodeStatusResponse) => void): grpc.ClientUnaryCall;
    public updateNodeExtendedInfo(request: node_pb.UpdateNodeExtendedInfoRequest, callback: (error: grpc.ServiceError | null, response: node_pb.UpdateNodeExtendedInfoResponse) => void): grpc.ClientUnaryCall;
    public updateNodeExtendedInfo(request: node_pb.UpdateNodeExtendedInfoRequest, metadata: grpc.Metadata, callback: (error: grpc.ServiceError | null, response: node_pb.UpdateNodeExtendedInfoResponse) => void): grpc.ClientUnaryCall;
    public updateNodeExtendedInfo(request: node_pb.UpdateNodeExtendedInfoRequest, metadata: grpc.Metadata, options: Partial<grpc.CallOptions>, callback: (error: grpc.ServiceError | null, response: node_pb.UpdateNodeExtendedInfoResponse) => void): grpc.ClientUnaryCall;
    public listNode(request: node_pb.ListNodeRequest, callback: (error: grpc.ServiceError | null, response: node_pb.ListNodeResponse) => void): grpc.ClientUnaryCall;
    public listNode(request: node_pb.ListNodeRequest, metadata: grpc.Metadata, callback: (error: grpc.ServiceError | null, response: node_pb.ListNodeResponse) => void): grpc.ClientUnaryCall;
    public listNode(request: node_pb.ListNodeRequest, metadata: grpc.Metadata, options: Partial<grpc.CallOptions>, callback: (error: grpc.ServiceError | null, response: node_pb.ListNodeResponse) => void): grpc.ClientUnaryCall;
    public getNodeStats(request: node_pb.GetNodeStatsRequest, callback: (error: grpc.ServiceError | null, response: node_pb.GetNodeStatsResponse) => void): grpc.ClientUnaryCall;
    public getNodeStats(request: node_pb.GetNodeStatsRequest, metadata: grpc.Metadata, callback: (error: grpc.ServiceError | null, response: node_pb.GetNodeStatsResponse) => void): grpc.ClientUnaryCall;
    public getNodeStats(request: node_pb.GetNodeStatsRequest, metadata: grpc.Metadata, options: Partial<grpc.CallOptions>, callback: (error: grpc.ServiceError | null, response: node_pb.GetNodeStatsResponse) => void): grpc.ClientUnaryCall;
    public getNodes(request: node_pb.GetNodesRequest, callback: (error: grpc.ServiceError | null, response: node_pb.GetNodesResponse) => void): grpc.ClientUnaryCall;
    public getNodes(request: node_pb.GetNodesRequest, metadata: grpc.Metadata, callback: (error: grpc.ServiceError | null, response: node_pb.GetNodesResponse) => void): grpc.ClientUnaryCall;
    public getNodes(request: node_pb.GetNodesRequest, metadata: grpc.Metadata, options: Partial<grpc.CallOptions>, callback: (error: grpc.ServiceError | null, response: node_pb.GetNodesResponse) => void): grpc.ClientUnaryCall;
    public streamNodes(request: node_pb.StreamNodesRequest, options?: Partial<grpc.CallOptions>): grpc.ClientReadableStream<node_pb.StreamNodesResponse>;
    public streamNodes(request: node_pb.StreamNodesRequest, metadata?: grpc.Metadata, options?: Partial<grpc.CallOptions>): grpc.ClientReadableStream<node_pb.StreamNodesResponse>;
}
