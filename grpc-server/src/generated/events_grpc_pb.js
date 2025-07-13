// GENERATED CODE -- DO NOT EDIT!

'use strict';
var grpc = require('@grpc/grpc-js');
var events_pb = require('./events_pb.js');

function serialize_quikdb_events_StreamEventsRequest(arg) {
  if (!(arg instanceof events_pb.StreamEventsRequest)) {
    throw new Error('Expected argument of type quikdb.events.StreamEventsRequest');
  }
  return Buffer.from(arg.serializeBinary());
}

function deserialize_quikdb_events_StreamEventsRequest(buffer_arg) {
  return events_pb.StreamEventsRequest.deserializeBinary(new Uint8Array(buffer_arg));
}

function serialize_quikdb_events_StreamEventsResponse(arg) {
  if (!(arg instanceof events_pb.StreamEventsResponse)) {
    throw new Error('Expected argument of type quikdb.events.StreamEventsResponse');
  }
  return Buffer.from(arg.serializeBinary());
}

function deserialize_quikdb_events_StreamEventsResponse(buffer_arg) {
  return events_pb.StreamEventsResponse.deserializeBinary(new Uint8Array(buffer_arg));
}


// Event service
var EventServiceService = exports.EventServiceService = {
  streamEvents: {
    path: '/quikdb.events.EventService/StreamEvents',
    requestStream: false,
    responseStream: true,
    requestType: events_pb.StreamEventsRequest,
    responseType: events_pb.StreamEventsResponse,
    requestSerialize: serialize_quikdb_events_StreamEventsRequest,
    requestDeserialize: deserialize_quikdb_events_StreamEventsRequest,
    responseSerialize: serialize_quikdb_events_StreamEventsResponse,
    responseDeserialize: deserialize_quikdb_events_StreamEventsResponse,
  },
};

exports.EventServiceClient = grpc.makeGenericClientConstructor(EventServiceService, 'EventService');
