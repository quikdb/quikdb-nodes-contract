// package: quikdb.user
// file: user.proto

/* tslint:disable */
/* eslint-disable */

import * as grpc from "@grpc/grpc-js";
import * as user_pb from "./user_pb";
import * as common_pb from "./common_pb";

interface IUserServiceService extends grpc.ServiceDefinition<grpc.UntypedServiceImplementation> {
    registerUser: IUserServiceService_IRegisterUser;
    getUserProfile: IUserServiceService_IGetUserProfile;
    updateUserProfile: IUserServiceService_IUpdateUserProfile;
    getUserStats: IUserServiceService_IGetUserStats;
    getUsers: IUserServiceService_IGetUsers;
    streamUsers: IUserServiceService_IStreamUsers;
}

interface IUserServiceService_IRegisterUser extends grpc.MethodDefinition<user_pb.RegisterUserRequest, user_pb.RegisterUserResponse> {
    path: "/quikdb.user.UserService/RegisterUser";
    requestStream: false;
    responseStream: false;
    requestSerialize: grpc.serialize<user_pb.RegisterUserRequest>;
    requestDeserialize: grpc.deserialize<user_pb.RegisterUserRequest>;
    responseSerialize: grpc.serialize<user_pb.RegisterUserResponse>;
    responseDeserialize: grpc.deserialize<user_pb.RegisterUserResponse>;
}
interface IUserServiceService_IGetUserProfile extends grpc.MethodDefinition<user_pb.GetUserProfileRequest, user_pb.GetUserProfileResponse> {
    path: "/quikdb.user.UserService/GetUserProfile";
    requestStream: false;
    responseStream: false;
    requestSerialize: grpc.serialize<user_pb.GetUserProfileRequest>;
    requestDeserialize: grpc.deserialize<user_pb.GetUserProfileRequest>;
    responseSerialize: grpc.serialize<user_pb.GetUserProfileResponse>;
    responseDeserialize: grpc.deserialize<user_pb.GetUserProfileResponse>;
}
interface IUserServiceService_IUpdateUserProfile extends grpc.MethodDefinition<user_pb.UpdateUserProfileRequest, user_pb.UpdateUserProfileResponse> {
    path: "/quikdb.user.UserService/UpdateUserProfile";
    requestStream: false;
    responseStream: false;
    requestSerialize: grpc.serialize<user_pb.UpdateUserProfileRequest>;
    requestDeserialize: grpc.deserialize<user_pb.UpdateUserProfileRequest>;
    responseSerialize: grpc.serialize<user_pb.UpdateUserProfileResponse>;
    responseDeserialize: grpc.deserialize<user_pb.UpdateUserProfileResponse>;
}
interface IUserServiceService_IGetUserStats extends grpc.MethodDefinition<user_pb.GetUserStatsRequest, user_pb.GetUserStatsResponse> {
    path: "/quikdb.user.UserService/GetUserStats";
    requestStream: false;
    responseStream: false;
    requestSerialize: grpc.serialize<user_pb.GetUserStatsRequest>;
    requestDeserialize: grpc.deserialize<user_pb.GetUserStatsRequest>;
    responseSerialize: grpc.serialize<user_pb.GetUserStatsResponse>;
    responseDeserialize: grpc.deserialize<user_pb.GetUserStatsResponse>;
}
interface IUserServiceService_IGetUsers extends grpc.MethodDefinition<user_pb.GetUsersRequest, user_pb.GetUsersResponse> {
    path: "/quikdb.user.UserService/GetUsers";
    requestStream: false;
    responseStream: false;
    requestSerialize: grpc.serialize<user_pb.GetUsersRequest>;
    requestDeserialize: grpc.deserialize<user_pb.GetUsersRequest>;
    responseSerialize: grpc.serialize<user_pb.GetUsersResponse>;
    responseDeserialize: grpc.deserialize<user_pb.GetUsersResponse>;
}
interface IUserServiceService_IStreamUsers extends grpc.MethodDefinition<user_pb.StreamUsersRequest, user_pb.StreamUsersResponse> {
    path: "/quikdb.user.UserService/StreamUsers";
    requestStream: false;
    responseStream: true;
    requestSerialize: grpc.serialize<user_pb.StreamUsersRequest>;
    requestDeserialize: grpc.deserialize<user_pb.StreamUsersRequest>;
    responseSerialize: grpc.serialize<user_pb.StreamUsersResponse>;
    responseDeserialize: grpc.deserialize<user_pb.StreamUsersResponse>;
}

export const UserServiceService: IUserServiceService;

export interface IUserServiceServer extends grpc.UntypedServiceImplementation {
    registerUser: grpc.handleUnaryCall<user_pb.RegisterUserRequest, user_pb.RegisterUserResponse>;
    getUserProfile: grpc.handleUnaryCall<user_pb.GetUserProfileRequest, user_pb.GetUserProfileResponse>;
    updateUserProfile: grpc.handleUnaryCall<user_pb.UpdateUserProfileRequest, user_pb.UpdateUserProfileResponse>;
    getUserStats: grpc.handleUnaryCall<user_pb.GetUserStatsRequest, user_pb.GetUserStatsResponse>;
    getUsers: grpc.handleUnaryCall<user_pb.GetUsersRequest, user_pb.GetUsersResponse>;
    streamUsers: grpc.handleServerStreamingCall<user_pb.StreamUsersRequest, user_pb.StreamUsersResponse>;
}

export interface IUserServiceClient {
    registerUser(request: user_pb.RegisterUserRequest, callback: (error: grpc.ServiceError | null, response: user_pb.RegisterUserResponse) => void): grpc.ClientUnaryCall;
    registerUser(request: user_pb.RegisterUserRequest, metadata: grpc.Metadata, callback: (error: grpc.ServiceError | null, response: user_pb.RegisterUserResponse) => void): grpc.ClientUnaryCall;
    registerUser(request: user_pb.RegisterUserRequest, metadata: grpc.Metadata, options: Partial<grpc.CallOptions>, callback: (error: grpc.ServiceError | null, response: user_pb.RegisterUserResponse) => void): grpc.ClientUnaryCall;
    getUserProfile(request: user_pb.GetUserProfileRequest, callback: (error: grpc.ServiceError | null, response: user_pb.GetUserProfileResponse) => void): grpc.ClientUnaryCall;
    getUserProfile(request: user_pb.GetUserProfileRequest, metadata: grpc.Metadata, callback: (error: grpc.ServiceError | null, response: user_pb.GetUserProfileResponse) => void): grpc.ClientUnaryCall;
    getUserProfile(request: user_pb.GetUserProfileRequest, metadata: grpc.Metadata, options: Partial<grpc.CallOptions>, callback: (error: grpc.ServiceError | null, response: user_pb.GetUserProfileResponse) => void): grpc.ClientUnaryCall;
    updateUserProfile(request: user_pb.UpdateUserProfileRequest, callback: (error: grpc.ServiceError | null, response: user_pb.UpdateUserProfileResponse) => void): grpc.ClientUnaryCall;
    updateUserProfile(request: user_pb.UpdateUserProfileRequest, metadata: grpc.Metadata, callback: (error: grpc.ServiceError | null, response: user_pb.UpdateUserProfileResponse) => void): grpc.ClientUnaryCall;
    updateUserProfile(request: user_pb.UpdateUserProfileRequest, metadata: grpc.Metadata, options: Partial<grpc.CallOptions>, callback: (error: grpc.ServiceError | null, response: user_pb.UpdateUserProfileResponse) => void): grpc.ClientUnaryCall;
    getUserStats(request: user_pb.GetUserStatsRequest, callback: (error: grpc.ServiceError | null, response: user_pb.GetUserStatsResponse) => void): grpc.ClientUnaryCall;
    getUserStats(request: user_pb.GetUserStatsRequest, metadata: grpc.Metadata, callback: (error: grpc.ServiceError | null, response: user_pb.GetUserStatsResponse) => void): grpc.ClientUnaryCall;
    getUserStats(request: user_pb.GetUserStatsRequest, metadata: grpc.Metadata, options: Partial<grpc.CallOptions>, callback: (error: grpc.ServiceError | null, response: user_pb.GetUserStatsResponse) => void): grpc.ClientUnaryCall;
    getUsers(request: user_pb.GetUsersRequest, callback: (error: grpc.ServiceError | null, response: user_pb.GetUsersResponse) => void): grpc.ClientUnaryCall;
    getUsers(request: user_pb.GetUsersRequest, metadata: grpc.Metadata, callback: (error: grpc.ServiceError | null, response: user_pb.GetUsersResponse) => void): grpc.ClientUnaryCall;
    getUsers(request: user_pb.GetUsersRequest, metadata: grpc.Metadata, options: Partial<grpc.CallOptions>, callback: (error: grpc.ServiceError | null, response: user_pb.GetUsersResponse) => void): grpc.ClientUnaryCall;
    streamUsers(request: user_pb.StreamUsersRequest, options?: Partial<grpc.CallOptions>): grpc.ClientReadableStream<user_pb.StreamUsersResponse>;
    streamUsers(request: user_pb.StreamUsersRequest, metadata?: grpc.Metadata, options?: Partial<grpc.CallOptions>): grpc.ClientReadableStream<user_pb.StreamUsersResponse>;
}

export class UserServiceClient extends grpc.Client implements IUserServiceClient {
    constructor(address: string, credentials: grpc.ChannelCredentials, options?: Partial<grpc.ClientOptions>);
    public registerUser(request: user_pb.RegisterUserRequest, callback: (error: grpc.ServiceError | null, response: user_pb.RegisterUserResponse) => void): grpc.ClientUnaryCall;
    public registerUser(request: user_pb.RegisterUserRequest, metadata: grpc.Metadata, callback: (error: grpc.ServiceError | null, response: user_pb.RegisterUserResponse) => void): grpc.ClientUnaryCall;
    public registerUser(request: user_pb.RegisterUserRequest, metadata: grpc.Metadata, options: Partial<grpc.CallOptions>, callback: (error: grpc.ServiceError | null, response: user_pb.RegisterUserResponse) => void): grpc.ClientUnaryCall;
    public getUserProfile(request: user_pb.GetUserProfileRequest, callback: (error: grpc.ServiceError | null, response: user_pb.GetUserProfileResponse) => void): grpc.ClientUnaryCall;
    public getUserProfile(request: user_pb.GetUserProfileRequest, metadata: grpc.Metadata, callback: (error: grpc.ServiceError | null, response: user_pb.GetUserProfileResponse) => void): grpc.ClientUnaryCall;
    public getUserProfile(request: user_pb.GetUserProfileRequest, metadata: grpc.Metadata, options: Partial<grpc.CallOptions>, callback: (error: grpc.ServiceError | null, response: user_pb.GetUserProfileResponse) => void): grpc.ClientUnaryCall;
    public updateUserProfile(request: user_pb.UpdateUserProfileRequest, callback: (error: grpc.ServiceError | null, response: user_pb.UpdateUserProfileResponse) => void): grpc.ClientUnaryCall;
    public updateUserProfile(request: user_pb.UpdateUserProfileRequest, metadata: grpc.Metadata, callback: (error: grpc.ServiceError | null, response: user_pb.UpdateUserProfileResponse) => void): grpc.ClientUnaryCall;
    public updateUserProfile(request: user_pb.UpdateUserProfileRequest, metadata: grpc.Metadata, options: Partial<grpc.CallOptions>, callback: (error: grpc.ServiceError | null, response: user_pb.UpdateUserProfileResponse) => void): grpc.ClientUnaryCall;
    public getUserStats(request: user_pb.GetUserStatsRequest, callback: (error: grpc.ServiceError | null, response: user_pb.GetUserStatsResponse) => void): grpc.ClientUnaryCall;
    public getUserStats(request: user_pb.GetUserStatsRequest, metadata: grpc.Metadata, callback: (error: grpc.ServiceError | null, response: user_pb.GetUserStatsResponse) => void): grpc.ClientUnaryCall;
    public getUserStats(request: user_pb.GetUserStatsRequest, metadata: grpc.Metadata, options: Partial<grpc.CallOptions>, callback: (error: grpc.ServiceError | null, response: user_pb.GetUserStatsResponse) => void): grpc.ClientUnaryCall;
    public getUsers(request: user_pb.GetUsersRequest, callback: (error: grpc.ServiceError | null, response: user_pb.GetUsersResponse) => void): grpc.ClientUnaryCall;
    public getUsers(request: user_pb.GetUsersRequest, metadata: grpc.Metadata, callback: (error: grpc.ServiceError | null, response: user_pb.GetUsersResponse) => void): grpc.ClientUnaryCall;
    public getUsers(request: user_pb.GetUsersRequest, metadata: grpc.Metadata, options: Partial<grpc.CallOptions>, callback: (error: grpc.ServiceError | null, response: user_pb.GetUsersResponse) => void): grpc.ClientUnaryCall;
    public streamUsers(request: user_pb.StreamUsersRequest, options?: Partial<grpc.CallOptions>): grpc.ClientReadableStream<user_pb.StreamUsersResponse>;
    public streamUsers(request: user_pb.StreamUsersRequest, metadata?: grpc.Metadata, options?: Partial<grpc.CallOptions>): grpc.ClientReadableStream<user_pb.StreamUsersResponse>;
}
