// GENERATED CODE -- DO NOT EDIT!

'use strict';
var grpc = require('@grpc/grpc-js');
var user_pb = require('./user_pb.js');
var common_pb = require('./common_pb.js');

function serialize_quikdb_user_GetUserProfileRequest(arg) {
  if (!(arg instanceof user_pb.GetUserProfileRequest)) {
    throw new Error('Expected argument of type quikdb.user.GetUserProfileRequest');
  }
  return Buffer.from(arg.serializeBinary());
}

function deserialize_quikdb_user_GetUserProfileRequest(buffer_arg) {
  return user_pb.GetUserProfileRequest.deserializeBinary(new Uint8Array(buffer_arg));
}

function serialize_quikdb_user_GetUserProfileResponse(arg) {
  if (!(arg instanceof user_pb.GetUserProfileResponse)) {
    throw new Error('Expected argument of type quikdb.user.GetUserProfileResponse');
  }
  return Buffer.from(arg.serializeBinary());
}

function deserialize_quikdb_user_GetUserProfileResponse(buffer_arg) {
  return user_pb.GetUserProfileResponse.deserializeBinary(new Uint8Array(buffer_arg));
}

function serialize_quikdb_user_GetUserStatsRequest(arg) {
  if (!(arg instanceof user_pb.GetUserStatsRequest)) {
    throw new Error('Expected argument of type quikdb.user.GetUserStatsRequest');
  }
  return Buffer.from(arg.serializeBinary());
}

function deserialize_quikdb_user_GetUserStatsRequest(buffer_arg) {
  return user_pb.GetUserStatsRequest.deserializeBinary(new Uint8Array(buffer_arg));
}

function serialize_quikdb_user_GetUserStatsResponse(arg) {
  if (!(arg instanceof user_pb.GetUserStatsResponse)) {
    throw new Error('Expected argument of type quikdb.user.GetUserStatsResponse');
  }
  return Buffer.from(arg.serializeBinary());
}

function deserialize_quikdb_user_GetUserStatsResponse(buffer_arg) {
  return user_pb.GetUserStatsResponse.deserializeBinary(new Uint8Array(buffer_arg));
}

function serialize_quikdb_user_GetUsersRequest(arg) {
  if (!(arg instanceof user_pb.GetUsersRequest)) {
    throw new Error('Expected argument of type quikdb.user.GetUsersRequest');
  }
  return Buffer.from(arg.serializeBinary());
}

function deserialize_quikdb_user_GetUsersRequest(buffer_arg) {
  return user_pb.GetUsersRequest.deserializeBinary(new Uint8Array(buffer_arg));
}

function serialize_quikdb_user_GetUsersResponse(arg) {
  if (!(arg instanceof user_pb.GetUsersResponse)) {
    throw new Error('Expected argument of type quikdb.user.GetUsersResponse');
  }
  return Buffer.from(arg.serializeBinary());
}

function deserialize_quikdb_user_GetUsersResponse(buffer_arg) {
  return user_pb.GetUsersResponse.deserializeBinary(new Uint8Array(buffer_arg));
}

function serialize_quikdb_user_RegisterUserRequest(arg) {
  if (!(arg instanceof user_pb.RegisterUserRequest)) {
    throw new Error('Expected argument of type quikdb.user.RegisterUserRequest');
  }
  return Buffer.from(arg.serializeBinary());
}

function deserialize_quikdb_user_RegisterUserRequest(buffer_arg) {
  return user_pb.RegisterUserRequest.deserializeBinary(new Uint8Array(buffer_arg));
}

function serialize_quikdb_user_RegisterUserResponse(arg) {
  if (!(arg instanceof user_pb.RegisterUserResponse)) {
    throw new Error('Expected argument of type quikdb.user.RegisterUserResponse');
  }
  return Buffer.from(arg.serializeBinary());
}

function deserialize_quikdb_user_RegisterUserResponse(buffer_arg) {
  return user_pb.RegisterUserResponse.deserializeBinary(new Uint8Array(buffer_arg));
}

function serialize_quikdb_user_StreamUsersRequest(arg) {
  if (!(arg instanceof user_pb.StreamUsersRequest)) {
    throw new Error('Expected argument of type quikdb.user.StreamUsersRequest');
  }
  return Buffer.from(arg.serializeBinary());
}

function deserialize_quikdb_user_StreamUsersRequest(buffer_arg) {
  return user_pb.StreamUsersRequest.deserializeBinary(new Uint8Array(buffer_arg));
}

function serialize_quikdb_user_StreamUsersResponse(arg) {
  if (!(arg instanceof user_pb.StreamUsersResponse)) {
    throw new Error('Expected argument of type quikdb.user.StreamUsersResponse');
  }
  return Buffer.from(arg.serializeBinary());
}

function deserialize_quikdb_user_StreamUsersResponse(buffer_arg) {
  return user_pb.StreamUsersResponse.deserializeBinary(new Uint8Array(buffer_arg));
}

function serialize_quikdb_user_UpdateUserProfileRequest(arg) {
  if (!(arg instanceof user_pb.UpdateUserProfileRequest)) {
    throw new Error('Expected argument of type quikdb.user.UpdateUserProfileRequest');
  }
  return Buffer.from(arg.serializeBinary());
}

function deserialize_quikdb_user_UpdateUserProfileRequest(buffer_arg) {
  return user_pb.UpdateUserProfileRequest.deserializeBinary(new Uint8Array(buffer_arg));
}

function serialize_quikdb_user_UpdateUserProfileResponse(arg) {
  if (!(arg instanceof user_pb.UpdateUserProfileResponse)) {
    throw new Error('Expected argument of type quikdb.user.UpdateUserProfileResponse');
  }
  return Buffer.from(arg.serializeBinary());
}

function deserialize_quikdb_user_UpdateUserProfileResponse(buffer_arg) {
  return user_pb.UpdateUserProfileResponse.deserializeBinary(new Uint8Array(buffer_arg));
}


// User service
var UserServiceService = exports.UserServiceService = {
  registerUser: {
    path: '/quikdb.user.UserService/RegisterUser',
    requestStream: false,
    responseStream: false,
    requestType: user_pb.RegisterUserRequest,
    responseType: user_pb.RegisterUserResponse,
    requestSerialize: serialize_quikdb_user_RegisterUserRequest,
    requestDeserialize: deserialize_quikdb_user_RegisterUserRequest,
    responseSerialize: serialize_quikdb_user_RegisterUserResponse,
    responseDeserialize: deserialize_quikdb_user_RegisterUserResponse,
  },
  getUserProfile: {
    path: '/quikdb.user.UserService/GetUserProfile',
    requestStream: false,
    responseStream: false,
    requestType: user_pb.GetUserProfileRequest,
    responseType: user_pb.GetUserProfileResponse,
    requestSerialize: serialize_quikdb_user_GetUserProfileRequest,
    requestDeserialize: deserialize_quikdb_user_GetUserProfileRequest,
    responseSerialize: serialize_quikdb_user_GetUserProfileResponse,
    responseDeserialize: deserialize_quikdb_user_GetUserProfileResponse,
  },
  updateUserProfile: {
    path: '/quikdb.user.UserService/UpdateUserProfile',
    requestStream: false,
    responseStream: false,
    requestType: user_pb.UpdateUserProfileRequest,
    responseType: user_pb.UpdateUserProfileResponse,
    requestSerialize: serialize_quikdb_user_UpdateUserProfileRequest,
    requestDeserialize: deserialize_quikdb_user_UpdateUserProfileRequest,
    responseSerialize: serialize_quikdb_user_UpdateUserProfileResponse,
    responseDeserialize: deserialize_quikdb_user_UpdateUserProfileResponse,
  },
  getUserStats: {
    path: '/quikdb.user.UserService/GetUserStats',
    requestStream: false,
    responseStream: false,
    requestType: user_pb.GetUserStatsRequest,
    responseType: user_pb.GetUserStatsResponse,
    requestSerialize: serialize_quikdb_user_GetUserStatsRequest,
    requestDeserialize: deserialize_quikdb_user_GetUserStatsRequest,
    responseSerialize: serialize_quikdb_user_GetUserStatsResponse,
    responseDeserialize: deserialize_quikdb_user_GetUserStatsResponse,
  },
  // User listing and streaming
getUsers: {
    path: '/quikdb.user.UserService/GetUsers',
    requestStream: false,
    responseStream: false,
    requestType: user_pb.GetUsersRequest,
    responseType: user_pb.GetUsersResponse,
    requestSerialize: serialize_quikdb_user_GetUsersRequest,
    requestDeserialize: deserialize_quikdb_user_GetUsersRequest,
    responseSerialize: serialize_quikdb_user_GetUsersResponse,
    responseDeserialize: deserialize_quikdb_user_GetUsersResponse,
  },
  streamUsers: {
    path: '/quikdb.user.UserService/StreamUsers',
    requestStream: false,
    responseStream: true,
    requestType: user_pb.StreamUsersRequest,
    responseType: user_pb.StreamUsersResponse,
    requestSerialize: serialize_quikdb_user_StreamUsersRequest,
    requestDeserialize: deserialize_quikdb_user_StreamUsersRequest,
    responseSerialize: serialize_quikdb_user_StreamUsersResponse,
    responseDeserialize: deserialize_quikdb_user_StreamUsersResponse,
  },
};

exports.UserServiceClient = grpc.makeGenericClientConstructor(UserServiceService, 'UserService');
