// GENERATED CODE -- DO NOT EDIT!

'use strict';
var grpc = require('@grpc/grpc-js');
var node_pb = require('./node_pb.js');
var common_pb = require('./common_pb.js');

function serialize_quikdb_node_GetNodeInfoRequest(arg) {
  if (!(arg instanceof node_pb.GetNodeInfoRequest)) {
    throw new Error('Expected argument of type quikdb.node.GetNodeInfoRequest');
  }
  return Buffer.from(arg.serializeBinary());
}

function deserialize_quikdb_node_GetNodeInfoRequest(buffer_arg) {
  return node_pb.GetNodeInfoRequest.deserializeBinary(new Uint8Array(buffer_arg));
}

function serialize_quikdb_node_GetNodeInfoResponse(arg) {
  if (!(arg instanceof node_pb.GetNodeInfoResponse)) {
    throw new Error('Expected argument of type quikdb.node.GetNodeInfoResponse');
  }
  return Buffer.from(arg.serializeBinary());
}

function deserialize_quikdb_node_GetNodeInfoResponse(buffer_arg) {
  return node_pb.GetNodeInfoResponse.deserializeBinary(new Uint8Array(buffer_arg));
}

function serialize_quikdb_node_GetNodeStatsRequest(arg) {
  if (!(arg instanceof node_pb.GetNodeStatsRequest)) {
    throw new Error('Expected argument of type quikdb.node.GetNodeStatsRequest');
  }
  return Buffer.from(arg.serializeBinary());
}

function deserialize_quikdb_node_GetNodeStatsRequest(buffer_arg) {
  return node_pb.GetNodeStatsRequest.deserializeBinary(new Uint8Array(buffer_arg));
}

function serialize_quikdb_node_GetNodeStatsResponse(arg) {
  if (!(arg instanceof node_pb.GetNodeStatsResponse)) {
    throw new Error('Expected argument of type quikdb.node.GetNodeStatsResponse');
  }
  return Buffer.from(arg.serializeBinary());
}

function deserialize_quikdb_node_GetNodeStatsResponse(buffer_arg) {
  return node_pb.GetNodeStatsResponse.deserializeBinary(new Uint8Array(buffer_arg));
}

function serialize_quikdb_node_GetNodesRequest(arg) {
  if (!(arg instanceof node_pb.GetNodesRequest)) {
    throw new Error('Expected argument of type quikdb.node.GetNodesRequest');
  }
  return Buffer.from(arg.serializeBinary());
}

function deserialize_quikdb_node_GetNodesRequest(buffer_arg) {
  return node_pb.GetNodesRequest.deserializeBinary(new Uint8Array(buffer_arg));
}

function serialize_quikdb_node_GetNodesResponse(arg) {
  if (!(arg instanceof node_pb.GetNodesResponse)) {
    throw new Error('Expected argument of type quikdb.node.GetNodesResponse');
  }
  return Buffer.from(arg.serializeBinary());
}

function deserialize_quikdb_node_GetNodesResponse(buffer_arg) {
  return node_pb.GetNodesResponse.deserializeBinary(new Uint8Array(buffer_arg));
}

function serialize_quikdb_node_ListNodeRequest(arg) {
  if (!(arg instanceof node_pb.ListNodeRequest)) {
    throw new Error('Expected argument of type quikdb.node.ListNodeRequest');
  }
  return Buffer.from(arg.serializeBinary());
}

function deserialize_quikdb_node_ListNodeRequest(buffer_arg) {
  return node_pb.ListNodeRequest.deserializeBinary(new Uint8Array(buffer_arg));
}

function serialize_quikdb_node_ListNodeResponse(arg) {
  if (!(arg instanceof node_pb.ListNodeResponse)) {
    throw new Error('Expected argument of type quikdb.node.ListNodeResponse');
  }
  return Buffer.from(arg.serializeBinary());
}

function deserialize_quikdb_node_ListNodeResponse(buffer_arg) {
  return node_pb.ListNodeResponse.deserializeBinary(new Uint8Array(buffer_arg));
}

function serialize_quikdb_node_RegisterNodeRequest(arg) {
  if (!(arg instanceof node_pb.RegisterNodeRequest)) {
    throw new Error('Expected argument of type quikdb.node.RegisterNodeRequest');
  }
  return Buffer.from(arg.serializeBinary());
}

function deserialize_quikdb_node_RegisterNodeRequest(buffer_arg) {
  return node_pb.RegisterNodeRequest.deserializeBinary(new Uint8Array(buffer_arg));
}

function serialize_quikdb_node_RegisterNodeResponse(arg) {
  if (!(arg instanceof node_pb.RegisterNodeResponse)) {
    throw new Error('Expected argument of type quikdb.node.RegisterNodeResponse');
  }
  return Buffer.from(arg.serializeBinary());
}

function deserialize_quikdb_node_RegisterNodeResponse(buffer_arg) {
  return node_pb.RegisterNodeResponse.deserializeBinary(new Uint8Array(buffer_arg));
}

function serialize_quikdb_node_StreamNodesRequest(arg) {
  if (!(arg instanceof node_pb.StreamNodesRequest)) {
    throw new Error('Expected argument of type quikdb.node.StreamNodesRequest');
  }
  return Buffer.from(arg.serializeBinary());
}

function deserialize_quikdb_node_StreamNodesRequest(buffer_arg) {
  return node_pb.StreamNodesRequest.deserializeBinary(new Uint8Array(buffer_arg));
}

function serialize_quikdb_node_StreamNodesResponse(arg) {
  if (!(arg instanceof node_pb.StreamNodesResponse)) {
    throw new Error('Expected argument of type quikdb.node.StreamNodesResponse');
  }
  return Buffer.from(arg.serializeBinary());
}

function deserialize_quikdb_node_StreamNodesResponse(buffer_arg) {
  return node_pb.StreamNodesResponse.deserializeBinary(new Uint8Array(buffer_arg));
}

function serialize_quikdb_node_UpdateNodeExtendedInfoRequest(arg) {
  if (!(arg instanceof node_pb.UpdateNodeExtendedInfoRequest)) {
    throw new Error('Expected argument of type quikdb.node.UpdateNodeExtendedInfoRequest');
  }
  return Buffer.from(arg.serializeBinary());
}

function deserialize_quikdb_node_UpdateNodeExtendedInfoRequest(buffer_arg) {
  return node_pb.UpdateNodeExtendedInfoRequest.deserializeBinary(new Uint8Array(buffer_arg));
}

function serialize_quikdb_node_UpdateNodeExtendedInfoResponse(arg) {
  if (!(arg instanceof node_pb.UpdateNodeExtendedInfoResponse)) {
    throw new Error('Expected argument of type quikdb.node.UpdateNodeExtendedInfoResponse');
  }
  return Buffer.from(arg.serializeBinary());
}

function deserialize_quikdb_node_UpdateNodeExtendedInfoResponse(buffer_arg) {
  return node_pb.UpdateNodeExtendedInfoResponse.deserializeBinary(new Uint8Array(buffer_arg));
}

function serialize_quikdb_node_UpdateNodeStatusRequest(arg) {
  if (!(arg instanceof node_pb.UpdateNodeStatusRequest)) {
    throw new Error('Expected argument of type quikdb.node.UpdateNodeStatusRequest');
  }
  return Buffer.from(arg.serializeBinary());
}

function deserialize_quikdb_node_UpdateNodeStatusRequest(buffer_arg) {
  return node_pb.UpdateNodeStatusRequest.deserializeBinary(new Uint8Array(buffer_arg));
}

function serialize_quikdb_node_UpdateNodeStatusResponse(arg) {
  if (!(arg instanceof node_pb.UpdateNodeStatusResponse)) {
    throw new Error('Expected argument of type quikdb.node.UpdateNodeStatusResponse');
  }
  return Buffer.from(arg.serializeBinary());
}

function deserialize_quikdb_node_UpdateNodeStatusResponse(buffer_arg) {
  return node_pb.UpdateNodeStatusResponse.deserializeBinary(new Uint8Array(buffer_arg));
}


// Node service
var NodeServiceService = exports.NodeServiceService = {
  registerNode: {
    path: '/quikdb.node.NodeService/RegisterNode',
    requestStream: false,
    responseStream: false,
    requestType: node_pb.RegisterNodeRequest,
    responseType: node_pb.RegisterNodeResponse,
    requestSerialize: serialize_quikdb_node_RegisterNodeRequest,
    requestDeserialize: deserialize_quikdb_node_RegisterNodeRequest,
    responseSerialize: serialize_quikdb_node_RegisterNodeResponse,
    responseDeserialize: deserialize_quikdb_node_RegisterNodeResponse,
  },
  getNodeInfo: {
    path: '/quikdb.node.NodeService/GetNodeInfo',
    requestStream: false,
    responseStream: false,
    requestType: node_pb.GetNodeInfoRequest,
    responseType: node_pb.GetNodeInfoResponse,
    requestSerialize: serialize_quikdb_node_GetNodeInfoRequest,
    requestDeserialize: deserialize_quikdb_node_GetNodeInfoRequest,
    responseSerialize: serialize_quikdb_node_GetNodeInfoResponse,
    responseDeserialize: deserialize_quikdb_node_GetNodeInfoResponse,
  },
  updateNodeStatus: {
    path: '/quikdb.node.NodeService/UpdateNodeStatus',
    requestStream: false,
    responseStream: false,
    requestType: node_pb.UpdateNodeStatusRequest,
    responseType: node_pb.UpdateNodeStatusResponse,
    requestSerialize: serialize_quikdb_node_UpdateNodeStatusRequest,
    requestDeserialize: deserialize_quikdb_node_UpdateNodeStatusRequest,
    responseSerialize: serialize_quikdb_node_UpdateNodeStatusResponse,
    responseDeserialize: deserialize_quikdb_node_UpdateNodeStatusResponse,
  },
  updateNodeExtendedInfo: {
    path: '/quikdb.node.NodeService/UpdateNodeExtendedInfo',
    requestStream: false,
    responseStream: false,
    requestType: node_pb.UpdateNodeExtendedInfoRequest,
    responseType: node_pb.UpdateNodeExtendedInfoResponse,
    requestSerialize: serialize_quikdb_node_UpdateNodeExtendedInfoRequest,
    requestDeserialize: deserialize_quikdb_node_UpdateNodeExtendedInfoRequest,
    responseSerialize: serialize_quikdb_node_UpdateNodeExtendedInfoResponse,
    responseDeserialize: deserialize_quikdb_node_UpdateNodeExtendedInfoResponse,
  },
  listNode: {
    path: '/quikdb.node.NodeService/ListNode',
    requestStream: false,
    responseStream: false,
    requestType: node_pb.ListNodeRequest,
    responseType: node_pb.ListNodeResponse,
    requestSerialize: serialize_quikdb_node_ListNodeRequest,
    requestDeserialize: deserialize_quikdb_node_ListNodeRequest,
    responseSerialize: serialize_quikdb_node_ListNodeResponse,
    responseDeserialize: deserialize_quikdb_node_ListNodeResponse,
  },
  getNodeStats: {
    path: '/quikdb.node.NodeService/GetNodeStats',
    requestStream: false,
    responseStream: false,
    requestType: node_pb.GetNodeStatsRequest,
    responseType: node_pb.GetNodeStatsResponse,
    requestSerialize: serialize_quikdb_node_GetNodeStatsRequest,
    requestDeserialize: deserialize_quikdb_node_GetNodeStatsRequest,
    responseSerialize: serialize_quikdb_node_GetNodeStatsResponse,
    responseDeserialize: deserialize_quikdb_node_GetNodeStatsResponse,
  },
  // Node listing and streaming
getNodes: {
    path: '/quikdb.node.NodeService/GetNodes',
    requestStream: false,
    responseStream: false,
    requestType: node_pb.GetNodesRequest,
    responseType: node_pb.GetNodesResponse,
    requestSerialize: serialize_quikdb_node_GetNodesRequest,
    requestDeserialize: deserialize_quikdb_node_GetNodesRequest,
    responseSerialize: serialize_quikdb_node_GetNodesResponse,
    responseDeserialize: deserialize_quikdb_node_GetNodesResponse,
  },
  streamNodes: {
    path: '/quikdb.node.NodeService/StreamNodes',
    requestStream: false,
    responseStream: true,
    requestType: node_pb.StreamNodesRequest,
    responseType: node_pb.StreamNodesResponse,
    requestSerialize: serialize_quikdb_node_StreamNodesRequest,
    requestDeserialize: deserialize_quikdb_node_StreamNodesRequest,
    responseSerialize: serialize_quikdb_node_StreamNodesResponse,
    responseDeserialize: deserialize_quikdb_node_StreamNodesResponse,
  },
};

exports.NodeServiceClient = grpc.makeGenericClientConstructor(NodeServiceService, 'NodeService');
