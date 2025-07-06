// GENERATED CODE -- DO NOT EDIT!

'use strict';
var grpc = require('@grpc/grpc-js');
var health_pb = require('./health_pb.js');

function serialize_quikdb_health_HealthCheckRequest(arg) {
  if (!(arg instanceof health_pb.HealthCheckRequest)) {
    throw new Error('Expected argument of type quikdb.health.HealthCheckRequest');
  }
  return Buffer.from(arg.serializeBinary());
}

function deserialize_quikdb_health_HealthCheckRequest(buffer_arg) {
  return health_pb.HealthCheckRequest.deserializeBinary(new Uint8Array(buffer_arg));
}

function serialize_quikdb_health_HealthCheckResponse(arg) {
  if (!(arg instanceof health_pb.HealthCheckResponse)) {
    throw new Error('Expected argument of type quikdb.health.HealthCheckResponse');
  }
  return Buffer.from(arg.serializeBinary());
}

function deserialize_quikdb_health_HealthCheckResponse(buffer_arg) {
  return health_pb.HealthCheckResponse.deserializeBinary(new Uint8Array(buffer_arg));
}


// Health service
var HealthServiceService = exports.HealthServiceService = {
  healthCheck: {
    path: '/quikdb.health.HealthService/HealthCheck',
    requestStream: false,
    responseStream: false,
    requestType: health_pb.HealthCheckRequest,
    responseType: health_pb.HealthCheckResponse,
    requestSerialize: serialize_quikdb_health_HealthCheckRequest,
    requestDeserialize: deserialize_quikdb_health_HealthCheckRequest,
    responseSerialize: serialize_quikdb_health_HealthCheckResponse,
    responseDeserialize: deserialize_quikdb_health_HealthCheckResponse,
  },
};

exports.HealthServiceClient = grpc.makeGenericClientConstructor(HealthServiceService, 'HealthService');
