// package: quikdb.events
// file: events.proto

/* tslint:disable */
/* eslint-disable */

import * as jspb from "google-protobuf";

export class EventFilter extends jspb.Message { 
    clearContractAddressesList(): void;
    getContractAddressesList(): Array<string>;
    setContractAddressesList(value: Array<string>): EventFilter;
    addContractAddresses(value: string, index?: number): string;
    clearEventNamesList(): void;
    getEventNamesList(): Array<string>;
    setEventNamesList(value: Array<string>): EventFilter;
    addEventNames(value: string, index?: number): string;
    getFromBlock(): number;
    setFromBlock(value: number): EventFilter;
    getToBlock(): number;
    setToBlock(value: number): EventFilter;

    serializeBinary(): Uint8Array;
    toObject(includeInstance?: boolean): EventFilter.AsObject;
    static toObject(includeInstance: boolean, msg: EventFilter): EventFilter.AsObject;
    static extensions: {[key: number]: jspb.ExtensionFieldInfo<jspb.Message>};
    static extensionsBinary: {[key: number]: jspb.ExtensionFieldBinaryInfo<jspb.Message>};
    static serializeBinaryToWriter(message: EventFilter, writer: jspb.BinaryWriter): void;
    static deserializeBinary(bytes: Uint8Array): EventFilter;
    static deserializeBinaryFromReader(message: EventFilter, reader: jspb.BinaryReader): EventFilter;
}

export namespace EventFilter {
    export type AsObject = {
        contractAddressesList: Array<string>,
        eventNamesList: Array<string>,
        fromBlock: number,
        toBlock: number,
    }
}

export class StreamEventsRequest extends jspb.Message { 

    hasFilter(): boolean;
    clearFilter(): void;
    getFilter(): EventFilter | undefined;
    setFilter(value?: EventFilter): StreamEventsRequest;
    getIncludeHistorical(): boolean;
    setIncludeHistorical(value: boolean): StreamEventsRequest;

    serializeBinary(): Uint8Array;
    toObject(includeInstance?: boolean): StreamEventsRequest.AsObject;
    static toObject(includeInstance: boolean, msg: StreamEventsRequest): StreamEventsRequest.AsObject;
    static extensions: {[key: number]: jspb.ExtensionFieldInfo<jspb.Message>};
    static extensionsBinary: {[key: number]: jspb.ExtensionFieldBinaryInfo<jspb.Message>};
    static serializeBinaryToWriter(message: StreamEventsRequest, writer: jspb.BinaryWriter): void;
    static deserializeBinary(bytes: Uint8Array): StreamEventsRequest;
    static deserializeBinaryFromReader(message: StreamEventsRequest, reader: jspb.BinaryReader): StreamEventsRequest;
}

export namespace StreamEventsRequest {
    export type AsObject = {
        filter?: EventFilter.AsObject,
        includeHistorical: boolean,
    }
}

export class ContractEvent extends jspb.Message { 
    getContractAddress(): string;
    setContractAddress(value: string): ContractEvent;
    getEventName(): string;
    setEventName(value: string): ContractEvent;
    getBlockNumber(): number;
    setBlockNumber(value: number): ContractEvent;
    getTransactionHash(): string;
    setTransactionHash(value: string): ContractEvent;
    getLogIndex(): number;
    setLogIndex(value: number): ContractEvent;

    getArgsMap(): jspb.Map<string, string>;
    clearArgsMap(): void;
    getTimestamp(): number;
    setTimestamp(value: number): ContractEvent;

    serializeBinary(): Uint8Array;
    toObject(includeInstance?: boolean): ContractEvent.AsObject;
    static toObject(includeInstance: boolean, msg: ContractEvent): ContractEvent.AsObject;
    static extensions: {[key: number]: jspb.ExtensionFieldInfo<jspb.Message>};
    static extensionsBinary: {[key: number]: jspb.ExtensionFieldBinaryInfo<jspb.Message>};
    static serializeBinaryToWriter(message: ContractEvent, writer: jspb.BinaryWriter): void;
    static deserializeBinary(bytes: Uint8Array): ContractEvent;
    static deserializeBinaryFromReader(message: ContractEvent, reader: jspb.BinaryReader): ContractEvent;
}

export namespace ContractEvent {
    export type AsObject = {
        contractAddress: string,
        eventName: string,
        blockNumber: number,
        transactionHash: string,
        logIndex: number,

        argsMap: Array<[string, string]>,
        timestamp: number,
    }
}

export class StreamEventsResponse extends jspb.Message { 

    hasEvent(): boolean;
    clearEvent(): void;
    getEvent(): ContractEvent | undefined;
    setEvent(value?: ContractEvent): StreamEventsResponse;

    serializeBinary(): Uint8Array;
    toObject(includeInstance?: boolean): StreamEventsResponse.AsObject;
    static toObject(includeInstance: boolean, msg: StreamEventsResponse): StreamEventsResponse.AsObject;
    static extensions: {[key: number]: jspb.ExtensionFieldInfo<jspb.Message>};
    static extensionsBinary: {[key: number]: jspb.ExtensionFieldBinaryInfo<jspb.Message>};
    static serializeBinaryToWriter(message: StreamEventsResponse, writer: jspb.BinaryWriter): void;
    static deserializeBinary(bytes: Uint8Array): StreamEventsResponse;
    static deserializeBinaryFromReader(message: StreamEventsResponse, reader: jspb.BinaryReader): StreamEventsResponse;
}

export namespace StreamEventsResponse {
    export type AsObject = {
        event?: ContractEvent.AsObject,
    }
}
