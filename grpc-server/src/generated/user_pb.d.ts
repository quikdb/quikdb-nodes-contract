// package: quikdb.user
// file: user.proto

/* tslint:disable */
/* eslint-disable */

import * as jspb from "google-protobuf";
import * as common_pb from "./common_pb";

export class UserProfile extends jspb.Message { 
    getProfileHash(): string;
    setProfileHash(value: string): UserProfile;
    getUserType(): UserType;
    setUserType(value: UserType): UserProfile;
    getIsActive(): boolean;
    setIsActive(value: boolean): UserProfile;
    getCreatedAt(): number;
    setCreatedAt(value: number): UserProfile;
    getUpdatedAt(): number;
    setUpdatedAt(value: number): UserProfile;
    getTotalSpent(): string;
    setTotalSpent(value: string): UserProfile;
    getTotalEarned(): string;
    setTotalEarned(value: string): UserProfile;
    getReputationScore(): number;
    setReputationScore(value: number): UserProfile;
    getIsVerified(): boolean;
    setIsVerified(value: boolean): UserProfile;

    serializeBinary(): Uint8Array;
    toObject(includeInstance?: boolean): UserProfile.AsObject;
    static toObject(includeInstance: boolean, msg: UserProfile): UserProfile.AsObject;
    static extensions: {[key: number]: jspb.ExtensionFieldInfo<jspb.Message>};
    static extensionsBinary: {[key: number]: jspb.ExtensionFieldBinaryInfo<jspb.Message>};
    static serializeBinaryToWriter(message: UserProfile, writer: jspb.BinaryWriter): void;
    static deserializeBinary(bytes: Uint8Array): UserProfile;
    static deserializeBinaryFromReader(message: UserProfile, reader: jspb.BinaryReader): UserProfile;
}

export namespace UserProfile {
    export type AsObject = {
        profileHash: string,
        userType: UserType,
        isActive: boolean,
        createdAt: number,
        updatedAt: number,
        totalSpent: string,
        totalEarned: string,
        reputationScore: number,
        isVerified: boolean,
    }
}

export class UserStats extends jspb.Message { 
    getTotalUsers(): number;
    setTotalUsers(value: number): UserStats;

    serializeBinary(): Uint8Array;
    toObject(includeInstance?: boolean): UserStats.AsObject;
    static toObject(includeInstance: boolean, msg: UserStats): UserStats.AsObject;
    static extensions: {[key: number]: jspb.ExtensionFieldInfo<jspb.Message>};
    static extensionsBinary: {[key: number]: jspb.ExtensionFieldBinaryInfo<jspb.Message>};
    static serializeBinaryToWriter(message: UserStats, writer: jspb.BinaryWriter): void;
    static deserializeBinary(bytes: Uint8Array): UserStats;
    static deserializeBinaryFromReader(message: UserStats, reader: jspb.BinaryReader): UserStats;
}

export namespace UserStats {
    export type AsObject = {
        totalUsers: number,
    }
}

export class RegisterUserRequest extends jspb.Message { 
    getUserAddress(): string;
    setUserAddress(value: string): RegisterUserRequest;
    getProfileHash(): string;
    setProfileHash(value: string): RegisterUserRequest;
    getUserType(): UserType;
    setUserType(value: UserType): RegisterUserRequest;

    serializeBinary(): Uint8Array;
    toObject(includeInstance?: boolean): RegisterUserRequest.AsObject;
    static toObject(includeInstance: boolean, msg: RegisterUserRequest): RegisterUserRequest.AsObject;
    static extensions: {[key: number]: jspb.ExtensionFieldInfo<jspb.Message>};
    static extensionsBinary: {[key: number]: jspb.ExtensionFieldBinaryInfo<jspb.Message>};
    static serializeBinaryToWriter(message: RegisterUserRequest, writer: jspb.BinaryWriter): void;
    static deserializeBinary(bytes: Uint8Array): RegisterUserRequest;
    static deserializeBinaryFromReader(message: RegisterUserRequest, reader: jspb.BinaryReader): RegisterUserRequest;
}

export namespace RegisterUserRequest {
    export type AsObject = {
        userAddress: string,
        profileHash: string,
        userType: UserType,
    }
}

export class RegisterUserResponse extends jspb.Message { 
    getSuccess(): boolean;
    setSuccess(value: boolean): RegisterUserResponse;
    getTransactionHash(): string;
    setTransactionHash(value: string): RegisterUserResponse;
    getMessage(): string;
    setMessage(value: string): RegisterUserResponse;

    serializeBinary(): Uint8Array;
    toObject(includeInstance?: boolean): RegisterUserResponse.AsObject;
    static toObject(includeInstance: boolean, msg: RegisterUserResponse): RegisterUserResponse.AsObject;
    static extensions: {[key: number]: jspb.ExtensionFieldInfo<jspb.Message>};
    static extensionsBinary: {[key: number]: jspb.ExtensionFieldBinaryInfo<jspb.Message>};
    static serializeBinaryToWriter(message: RegisterUserResponse, writer: jspb.BinaryWriter): void;
    static deserializeBinary(bytes: Uint8Array): RegisterUserResponse;
    static deserializeBinaryFromReader(message: RegisterUserResponse, reader: jspb.BinaryReader): RegisterUserResponse;
}

export namespace RegisterUserResponse {
    export type AsObject = {
        success: boolean,
        transactionHash: string,
        message: string,
    }
}

export class GetUserProfileRequest extends jspb.Message { 
    getUserAddress(): string;
    setUserAddress(value: string): GetUserProfileRequest;

    serializeBinary(): Uint8Array;
    toObject(includeInstance?: boolean): GetUserProfileRequest.AsObject;
    static toObject(includeInstance: boolean, msg: GetUserProfileRequest): GetUserProfileRequest.AsObject;
    static extensions: {[key: number]: jspb.ExtensionFieldInfo<jspb.Message>};
    static extensionsBinary: {[key: number]: jspb.ExtensionFieldBinaryInfo<jspb.Message>};
    static serializeBinaryToWriter(message: GetUserProfileRequest, writer: jspb.BinaryWriter): void;
    static deserializeBinary(bytes: Uint8Array): GetUserProfileRequest;
    static deserializeBinaryFromReader(message: GetUserProfileRequest, reader: jspb.BinaryReader): GetUserProfileRequest;
}

export namespace GetUserProfileRequest {
    export type AsObject = {
        userAddress: string,
    }
}

export class GetUserProfileResponse extends jspb.Message { 

    hasProfile(): boolean;
    clearProfile(): void;
    getProfile(): UserProfile | undefined;
    setProfile(value?: UserProfile): GetUserProfileResponse;

    serializeBinary(): Uint8Array;
    toObject(includeInstance?: boolean): GetUserProfileResponse.AsObject;
    static toObject(includeInstance: boolean, msg: GetUserProfileResponse): GetUserProfileResponse.AsObject;
    static extensions: {[key: number]: jspb.ExtensionFieldInfo<jspb.Message>};
    static extensionsBinary: {[key: number]: jspb.ExtensionFieldBinaryInfo<jspb.Message>};
    static serializeBinaryToWriter(message: GetUserProfileResponse, writer: jspb.BinaryWriter): void;
    static deserializeBinary(bytes: Uint8Array): GetUserProfileResponse;
    static deserializeBinaryFromReader(message: GetUserProfileResponse, reader: jspb.BinaryReader): GetUserProfileResponse;
}

export namespace GetUserProfileResponse {
    export type AsObject = {
        profile?: UserProfile.AsObject,
    }
}

export class UpdateUserProfileRequest extends jspb.Message { 
    getUserAddress(): string;
    setUserAddress(value: string): UpdateUserProfileRequest;
    getProfileHash(): string;
    setProfileHash(value: string): UpdateUserProfileRequest;

    serializeBinary(): Uint8Array;
    toObject(includeInstance?: boolean): UpdateUserProfileRequest.AsObject;
    static toObject(includeInstance: boolean, msg: UpdateUserProfileRequest): UpdateUserProfileRequest.AsObject;
    static extensions: {[key: number]: jspb.ExtensionFieldInfo<jspb.Message>};
    static extensionsBinary: {[key: number]: jspb.ExtensionFieldBinaryInfo<jspb.Message>};
    static serializeBinaryToWriter(message: UpdateUserProfileRequest, writer: jspb.BinaryWriter): void;
    static deserializeBinary(bytes: Uint8Array): UpdateUserProfileRequest;
    static deserializeBinaryFromReader(message: UpdateUserProfileRequest, reader: jspb.BinaryReader): UpdateUserProfileRequest;
}

export namespace UpdateUserProfileRequest {
    export type AsObject = {
        userAddress: string,
        profileHash: string,
    }
}

export class UpdateUserProfileResponse extends jspb.Message { 
    getSuccess(): boolean;
    setSuccess(value: boolean): UpdateUserProfileResponse;
    getTransactionHash(): string;
    setTransactionHash(value: string): UpdateUserProfileResponse;
    getMessage(): string;
    setMessage(value: string): UpdateUserProfileResponse;

    serializeBinary(): Uint8Array;
    toObject(includeInstance?: boolean): UpdateUserProfileResponse.AsObject;
    static toObject(includeInstance: boolean, msg: UpdateUserProfileResponse): UpdateUserProfileResponse.AsObject;
    static extensions: {[key: number]: jspb.ExtensionFieldInfo<jspb.Message>};
    static extensionsBinary: {[key: number]: jspb.ExtensionFieldBinaryInfo<jspb.Message>};
    static serializeBinaryToWriter(message: UpdateUserProfileResponse, writer: jspb.BinaryWriter): void;
    static deserializeBinary(bytes: Uint8Array): UpdateUserProfileResponse;
    static deserializeBinaryFromReader(message: UpdateUserProfileResponse, reader: jspb.BinaryReader): UpdateUserProfileResponse;
}

export namespace UpdateUserProfileResponse {
    export type AsObject = {
        success: boolean,
        transactionHash: string,
        message: string,
    }
}

export class GetUserStatsRequest extends jspb.Message { 

    serializeBinary(): Uint8Array;
    toObject(includeInstance?: boolean): GetUserStatsRequest.AsObject;
    static toObject(includeInstance: boolean, msg: GetUserStatsRequest): GetUserStatsRequest.AsObject;
    static extensions: {[key: number]: jspb.ExtensionFieldInfo<jspb.Message>};
    static extensionsBinary: {[key: number]: jspb.ExtensionFieldBinaryInfo<jspb.Message>};
    static serializeBinaryToWriter(message: GetUserStatsRequest, writer: jspb.BinaryWriter): void;
    static deserializeBinary(bytes: Uint8Array): GetUserStatsRequest;
    static deserializeBinaryFromReader(message: GetUserStatsRequest, reader: jspb.BinaryReader): GetUserStatsRequest;
}

export namespace GetUserStatsRequest {
    export type AsObject = {
    }
}

export class GetUserStatsResponse extends jspb.Message { 

    hasStats(): boolean;
    clearStats(): void;
    getStats(): UserStats | undefined;
    setStats(value?: UserStats): GetUserStatsResponse;

    serializeBinary(): Uint8Array;
    toObject(includeInstance?: boolean): GetUserStatsResponse.AsObject;
    static toObject(includeInstance: boolean, msg: GetUserStatsResponse): GetUserStatsResponse.AsObject;
    static extensions: {[key: number]: jspb.ExtensionFieldInfo<jspb.Message>};
    static extensionsBinary: {[key: number]: jspb.ExtensionFieldBinaryInfo<jspb.Message>};
    static serializeBinaryToWriter(message: GetUserStatsResponse, writer: jspb.BinaryWriter): void;
    static deserializeBinary(bytes: Uint8Array): GetUserStatsResponse;
    static deserializeBinaryFromReader(message: GetUserStatsResponse, reader: jspb.BinaryReader): GetUserStatsResponse;
}

export namespace GetUserStatsResponse {
    export type AsObject = {
        stats?: UserStats.AsObject,
    }
}

export class GetUsersRequest extends jspb.Message { 

    hasPagination(): boolean;
    clearPagination(): void;
    getPagination(): common_pb.PaginationRequest | undefined;
    setPagination(value?: common_pb.PaginationRequest): GetUsersRequest;
    getTypeFilter(): UserType;
    setTypeFilter(value: UserType): GetUsersRequest;
    getVerifiedOnly(): boolean;
    setVerifiedOnly(value: boolean): GetUsersRequest;
    getActiveOnly(): boolean;
    setActiveOnly(value: boolean): GetUsersRequest;

    serializeBinary(): Uint8Array;
    toObject(includeInstance?: boolean): GetUsersRequest.AsObject;
    static toObject(includeInstance: boolean, msg: GetUsersRequest): GetUsersRequest.AsObject;
    static extensions: {[key: number]: jspb.ExtensionFieldInfo<jspb.Message>};
    static extensionsBinary: {[key: number]: jspb.ExtensionFieldBinaryInfo<jspb.Message>};
    static serializeBinaryToWriter(message: GetUsersRequest, writer: jspb.BinaryWriter): void;
    static deserializeBinary(bytes: Uint8Array): GetUsersRequest;
    static deserializeBinaryFromReader(message: GetUsersRequest, reader: jspb.BinaryReader): GetUsersRequest;
}

export namespace GetUsersRequest {
    export type AsObject = {
        pagination?: common_pb.PaginationRequest.AsObject,
        typeFilter: UserType,
        verifiedOnly: boolean,
        activeOnly: boolean,
    }
}

export class GetUsersResponse extends jspb.Message { 
    clearUsersList(): void;
    getUsersList(): Array<UserProfile>;
    setUsersList(value: Array<UserProfile>): GetUsersResponse;
    addUsers(value?: UserProfile, index?: number): UserProfile;

    hasPagination(): boolean;
    clearPagination(): void;
    getPagination(): common_pb.PaginationResponse | undefined;
    setPagination(value?: common_pb.PaginationResponse): GetUsersResponse;

    serializeBinary(): Uint8Array;
    toObject(includeInstance?: boolean): GetUsersResponse.AsObject;
    static toObject(includeInstance: boolean, msg: GetUsersResponse): GetUsersResponse.AsObject;
    static extensions: {[key: number]: jspb.ExtensionFieldInfo<jspb.Message>};
    static extensionsBinary: {[key: number]: jspb.ExtensionFieldBinaryInfo<jspb.Message>};
    static serializeBinaryToWriter(message: GetUsersResponse, writer: jspb.BinaryWriter): void;
    static deserializeBinary(bytes: Uint8Array): GetUsersResponse;
    static deserializeBinaryFromReader(message: GetUsersResponse, reader: jspb.BinaryReader): GetUsersResponse;
}

export namespace GetUsersResponse {
    export type AsObject = {
        usersList: Array<UserProfile.AsObject>,
        pagination?: common_pb.PaginationResponse.AsObject,
    }
}

export class StreamUsersRequest extends jspb.Message { 
    getTypeFilter(): UserType;
    setTypeFilter(value: UserType): StreamUsersRequest;
    getVerifiedOnly(): boolean;
    setVerifiedOnly(value: boolean): StreamUsersRequest;
    getActiveOnly(): boolean;
    setActiveOnly(value: boolean): StreamUsersRequest;
    getBatchSize(): number;
    setBatchSize(value: number): StreamUsersRequest;

    serializeBinary(): Uint8Array;
    toObject(includeInstance?: boolean): StreamUsersRequest.AsObject;
    static toObject(includeInstance: boolean, msg: StreamUsersRequest): StreamUsersRequest.AsObject;
    static extensions: {[key: number]: jspb.ExtensionFieldInfo<jspb.Message>};
    static extensionsBinary: {[key: number]: jspb.ExtensionFieldBinaryInfo<jspb.Message>};
    static serializeBinaryToWriter(message: StreamUsersRequest, writer: jspb.BinaryWriter): void;
    static deserializeBinary(bytes: Uint8Array): StreamUsersRequest;
    static deserializeBinaryFromReader(message: StreamUsersRequest, reader: jspb.BinaryReader): StreamUsersRequest;
}

export namespace StreamUsersRequest {
    export type AsObject = {
        typeFilter: UserType,
        verifiedOnly: boolean,
        activeOnly: boolean,
        batchSize: number,
    }
}

export class StreamUsersResponse extends jspb.Message { 
    clearUsersList(): void;
    getUsersList(): Array<UserProfile>;
    setUsersList(value: Array<UserProfile>): StreamUsersResponse;
    addUsers(value?: UserProfile, index?: number): UserProfile;
    getIsFinalBatch(): boolean;
    setIsFinalBatch(value: boolean): StreamUsersResponse;
    getTotalSent(): number;
    setTotalSent(value: number): StreamUsersResponse;

    serializeBinary(): Uint8Array;
    toObject(includeInstance?: boolean): StreamUsersResponse.AsObject;
    static toObject(includeInstance: boolean, msg: StreamUsersResponse): StreamUsersResponse.AsObject;
    static extensions: {[key: number]: jspb.ExtensionFieldInfo<jspb.Message>};
    static extensionsBinary: {[key: number]: jspb.ExtensionFieldBinaryInfo<jspb.Message>};
    static serializeBinaryToWriter(message: StreamUsersResponse, writer: jspb.BinaryWriter): void;
    static deserializeBinary(bytes: Uint8Array): StreamUsersResponse;
    static deserializeBinaryFromReader(message: StreamUsersResponse, reader: jspb.BinaryReader): StreamUsersResponse;
}

export namespace StreamUsersResponse {
    export type AsObject = {
        usersList: Array<UserProfile.AsObject>,
        isFinalBatch: boolean,
        totalSent: number,
    }
}

export enum UserType {
    USER_TYPE_CONSUMER = 0,
    USER_TYPE_PROVIDER = 1,
    USER_TYPE_HYBRID = 2,
    USER_TYPE_ENTERPRISE = 3,
}
