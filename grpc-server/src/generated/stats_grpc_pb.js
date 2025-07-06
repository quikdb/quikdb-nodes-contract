// GENERATED CODE -- DO NOT EDIT!

'use strict';
var grpc = require('@grpc/grpc-js');
var stats_pb = require('./stats_pb.js');
var user_pb = require('./user_pb.js');
var node_pb = require('./node_pb.js');

function serialize_quikdb_stats_GetSystemStatsRequest(arg) {
  if (!(arg instanceof stats_pb.GetSystemStatsRequest)) {
    throw new Error('Expected argument of type quikdb.stats.GetSystemStatsRequest');
  }
  return Buffer.from(arg.serializeBinary());
}

function deserialize_quikdb_stats_GetSystemStatsRequest(buffer_arg) {
  return stats_pb.GetSystemStatsRequest.deserializeBinary(new Uint8Array(buffer_arg));
}

function serialize_quikdb_stats_GetSystemStatsResponse(arg) {
  if (!(arg instanceof stats_pb.GetSystemStatsResponse)) {
    throw new Error('Expected argument of type quikdb.stats.GetSystemStatsResponse');
  }
  return Buffer.from(arg.serializeBinary());
}

function deserialize_quikdb_stats_GetSystemStatsResponse(buffer_arg) {
  return stats_pb.GetSystemStatsResponse.deserializeBinary(new Uint8Array(buffer_arg));
}


// Stats service
var StatsServiceService = exports.StatsServiceService = {
  getSystemStats: {
    path: '/quikdb.stats.StatsService/GetSystemStats',
    requestStream: false,
    responseStream: false,
    requestType: stats_pb.GetSystemStatsRequest,
    responseType: stats_pb.GetSystemStatsResponse,
    requestSerialize: serialize_quikdb_stats_GetSystemStatsRequest,
    requestDeserialize: deserialize_quikdb_stats_GetSystemStatsRequest,
    responseSerialize: serialize_quikdb_stats_GetSystemStatsResponse,
    responseDeserialize: deserialize_quikdb_stats_GetSystemStatsResponse,
  },
};

exports.StatsServiceClient = grpc.makeGenericClientConstructor(StatsServiceService, 'StatsService');
