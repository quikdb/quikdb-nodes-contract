// package: quikdb.common
// file: common.proto

/* tslint:disable */
/* eslint-disable */

import * as jspb from "google-protobuf";

export class Empty extends jspb.Message { 

    serializeBinary(): Uint8Array;
    toObject(includeInstance?: boolean): Empty.AsObject;
    static toObject(includeInstance: boolean, msg: Empty): Empty.AsObject;
    static extensions: {[key: number]: jspb.ExtensionFieldInfo<jspb.Message>};
    static extensionsBinary: {[key: number]: jspb.ExtensionFieldBinaryInfo<jspb.Message>};
    static serializeBinaryToWriter(message: Empty, writer: jspb.BinaryWriter): void;
    static deserializeBinary(bytes: Uint8Array): Empty;
    static deserializeBinaryFromReader(message: Empty, reader: jspb.BinaryReader): Empty;
}

export namespace Empty {
    export type AsObject = {
    }
}

export class Address extends jspb.Message { 
    getAddress(): string;
    setAddress(value: string): Address;

    serializeBinary(): Uint8Array;
    toObject(includeInstance?: boolean): Address.AsObject;
    static toObject(includeInstance: boolean, msg: Address): Address.AsObject;
    static extensions: {[key: number]: jspb.ExtensionFieldInfo<jspb.Message>};
    static extensionsBinary: {[key: number]: jspb.ExtensionFieldBinaryInfo<jspb.Message>};
    static serializeBinaryToWriter(message: Address, writer: jspb.BinaryWriter): void;
    static deserializeBinary(bytes: Uint8Array): Address;
    static deserializeBinaryFromReader(message: Address, reader: jspb.BinaryReader): Address;
}

export namespace Address {
    export type AsObject = {
        address: string,
    }
}

export class TransactionHash extends jspb.Message { 
    getHash(): string;
    setHash(value: string): TransactionHash;

    serializeBinary(): Uint8Array;
    toObject(includeInstance?: boolean): TransactionHash.AsObject;
    static toObject(includeInstance: boolean, msg: TransactionHash): TransactionHash.AsObject;
    static extensions: {[key: number]: jspb.ExtensionFieldInfo<jspb.Message>};
    static extensionsBinary: {[key: number]: jspb.ExtensionFieldBinaryInfo<jspb.Message>};
    static serializeBinaryToWriter(message: TransactionHash, writer: jspb.BinaryWriter): void;
    static deserializeBinary(bytes: Uint8Array): TransactionHash;
    static deserializeBinaryFromReader(message: TransactionHash, reader: jspb.BinaryReader): TransactionHash;
}

export namespace TransactionHash {
    export type AsObject = {
        hash: string,
    }
}

export class BlockNumber extends jspb.Message { 
    getNumber(): number;
    setNumber(value: number): BlockNumber;

    serializeBinary(): Uint8Array;
    toObject(includeInstance?: boolean): BlockNumber.AsObject;
    static toObject(includeInstance: boolean, msg: BlockNumber): BlockNumber.AsObject;
    static extensions: {[key: number]: jspb.ExtensionFieldInfo<jspb.Message>};
    static extensionsBinary: {[key: number]: jspb.ExtensionFieldBinaryInfo<jspb.Message>};
    static serializeBinaryToWriter(message: BlockNumber, writer: jspb.BinaryWriter): void;
    static deserializeBinary(bytes: Uint8Array): BlockNumber;
    static deserializeBinaryFromReader(message: BlockNumber, reader: jspb.BinaryReader): BlockNumber;
}

export namespace BlockNumber {
    export type AsObject = {
        number: number,
    }
}

export class PaginationRequest extends jspb.Message { 
    getPage(): number;
    setPage(value: number): PaginationRequest;
    getLimit(): number;
    setLimit(value: number): PaginationRequest;
    getSortBy(): string;
    setSortBy(value: string): PaginationRequest;
    getSortOrder(): string;
    setSortOrder(value: string): PaginationRequest;

    serializeBinary(): Uint8Array;
    toObject(includeInstance?: boolean): PaginationRequest.AsObject;
    static toObject(includeInstance: boolean, msg: PaginationRequest): PaginationRequest.AsObject;
    static extensions: {[key: number]: jspb.ExtensionFieldInfo<jspb.Message>};
    static extensionsBinary: {[key: number]: jspb.ExtensionFieldBinaryInfo<jspb.Message>};
    static serializeBinaryToWriter(message: PaginationRequest, writer: jspb.BinaryWriter): void;
    static deserializeBinary(bytes: Uint8Array): PaginationRequest;
    static deserializeBinaryFromReader(message: PaginationRequest, reader: jspb.BinaryReader): PaginationRequest;
}

export namespace PaginationRequest {
    export type AsObject = {
        page: number,
        limit: number,
        sortBy: string,
        sortOrder: string,
    }
}

export class PaginationResponse extends jspb.Message { 
    getPage(): number;
    setPage(value: number): PaginationResponse;
    getLimit(): number;
    setLimit(value: number): PaginationResponse;
    getTotalPages(): number;
    setTotalPages(value: number): PaginationResponse;
    getTotalItems(): number;
    setTotalItems(value: number): PaginationResponse;
    getHasNext(): boolean;
    setHasNext(value: boolean): PaginationResponse;
    getHasPrevious(): boolean;
    setHasPrevious(value: boolean): PaginationResponse;

    serializeBinary(): Uint8Array;
    toObject(includeInstance?: boolean): PaginationResponse.AsObject;
    static toObject(includeInstance: boolean, msg: PaginationResponse): PaginationResponse.AsObject;
    static extensions: {[key: number]: jspb.ExtensionFieldInfo<jspb.Message>};
    static extensionsBinary: {[key: number]: jspb.ExtensionFieldBinaryInfo<jspb.Message>};
    static serializeBinaryToWriter(message: PaginationResponse, writer: jspb.BinaryWriter): void;
    static deserializeBinary(bytes: Uint8Array): PaginationResponse;
    static deserializeBinaryFromReader(message: PaginationResponse, reader: jspb.BinaryReader): PaginationResponse;
}

export namespace PaginationResponse {
    export type AsObject = {
        page: number,
        limit: number,
        totalPages: number,
        totalItems: number,
        hasNext: boolean,
        hasPrevious: boolean,
    }
}
