// package: quikdb.health
// file: health.proto

/* tslint:disable */
/* eslint-disable */

import * as jspb from "google-protobuf";

export class HealthCheckRequest extends jspb.Message { 

    serializeBinary(): Uint8Array;
    toObject(includeInstance?: boolean): HealthCheckRequest.AsObject;
    static toObject(includeInstance: boolean, msg: HealthCheckRequest): HealthCheckRequest.AsObject;
    static extensions: {[key: number]: jspb.ExtensionFieldInfo<jspb.Message>};
    static extensionsBinary: {[key: number]: jspb.ExtensionFieldBinaryInfo<jspb.Message>};
    static serializeBinaryToWriter(message: HealthCheckRequest, writer: jspb.BinaryWriter): void;
    static deserializeBinary(bytes: Uint8Array): HealthCheckRequest;
    static deserializeBinaryFromReader(message: HealthCheckRequest, reader: jspb.BinaryReader): HealthCheckRequest;
}

export namespace HealthCheckRequest {
    export type AsObject = {
    }
}

export class HealthCheckResponse extends jspb.Message { 
    getHealthy(): boolean;
    setHealthy(value: boolean): HealthCheckResponse;
    getVersion(): string;
    setVersion(value: string): HealthCheckResponse;
    getTimestamp(): number;
    setTimestamp(value: number): HealthCheckResponse;
    getBlockchainStatus(): string;
    setBlockchainStatus(value: string): HealthCheckResponse;
    getLastBlockNumber(): number;
    setLastBlockNumber(value: number): HealthCheckResponse;
    clearConnectedContractsList(): void;
    getConnectedContractsList(): Array<string>;
    setConnectedContractsList(value: Array<string>): HealthCheckResponse;
    addConnectedContracts(value: string, index?: number): string;

    serializeBinary(): Uint8Array;
    toObject(includeInstance?: boolean): HealthCheckResponse.AsObject;
    static toObject(includeInstance: boolean, msg: HealthCheckResponse): HealthCheckResponse.AsObject;
    static extensions: {[key: number]: jspb.ExtensionFieldInfo<jspb.Message>};
    static extensionsBinary: {[key: number]: jspb.ExtensionFieldBinaryInfo<jspb.Message>};
    static serializeBinaryToWriter(message: HealthCheckResponse, writer: jspb.BinaryWriter): void;
    static deserializeBinary(bytes: Uint8Array): HealthCheckResponse;
    static deserializeBinaryFromReader(message: HealthCheckResponse, reader: jspb.BinaryReader): HealthCheckResponse;
}

export namespace HealthCheckResponse {
    export type AsObject = {
        healthy: boolean,
        version: string,
        timestamp: number,
        blockchainStatus: string,
        lastBlockNumber: number,
        connectedContractsList: Array<string>,
    }
}
