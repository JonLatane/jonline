/* eslint-disable */
import _m0 from "protobufjs/minimal";

export const protobufPackage = "jonline";

export interface GetServiceVersionResponse {
  version: string;
}

/** The federation configuration for a Jonline server. */
export interface FederationInfo {
  /** A list of servers that this server will federate with. */
  servers: FederatedServer[];
}

/** A server that this server will federate with. */
export interface FederatedServer {
  /** The DNS hostname of the server to federate with. */
  host: string;
  /** Indicates to UI clients that they should enable/configure the indicated server by default. */
  configuredByDefault?:
    | boolean
    | undefined;
  /**
   * Indicates to UI clients that they should pin the indicated server by default
   * (showing its Events and Posts alongside the "main" server).
   */
  pinnedByDefault?: boolean | undefined;
}

function createBaseGetServiceVersionResponse(): GetServiceVersionResponse {
  return { version: "" };
}

export const GetServiceVersionResponse = {
  encode(message: GetServiceVersionResponse, writer: _m0.Writer = _m0.Writer.create()): _m0.Writer {
    if (message.version !== "") {
      writer.uint32(10).string(message.version);
    }
    return writer;
  },

  decode(input: _m0.Reader | Uint8Array, length?: number): GetServiceVersionResponse {
    const reader = input instanceof _m0.Reader ? input : _m0.Reader.create(input);
    let end = length === undefined ? reader.len : reader.pos + length;
    const message = createBaseGetServiceVersionResponse();
    while (reader.pos < end) {
      const tag = reader.uint32();
      switch (tag >>> 3) {
        case 1:
          if (tag !== 10) {
            break;
          }

          message.version = reader.string();
          continue;
      }
      if ((tag & 7) === 4 || tag === 0) {
        break;
      }
      reader.skipType(tag & 7);
    }
    return message;
  },

  fromJSON(object: any): GetServiceVersionResponse {
    return { version: isSet(object.version) ? globalThis.String(object.version) : "" };
  },

  toJSON(message: GetServiceVersionResponse): unknown {
    const obj: any = {};
    if (message.version !== "") {
      obj.version = message.version;
    }
    return obj;
  },

  create<I extends Exact<DeepPartial<GetServiceVersionResponse>, I>>(base?: I): GetServiceVersionResponse {
    return GetServiceVersionResponse.fromPartial(base ?? ({} as any));
  },
  fromPartial<I extends Exact<DeepPartial<GetServiceVersionResponse>, I>>(object: I): GetServiceVersionResponse {
    const message = createBaseGetServiceVersionResponse();
    message.version = object.version ?? "";
    return message;
  },
};

function createBaseFederationInfo(): FederationInfo {
  return { servers: [] };
}

export const FederationInfo = {
  encode(message: FederationInfo, writer: _m0.Writer = _m0.Writer.create()): _m0.Writer {
    for (const v of message.servers) {
      FederatedServer.encode(v!, writer.uint32(10).fork()).ldelim();
    }
    return writer;
  },

  decode(input: _m0.Reader | Uint8Array, length?: number): FederationInfo {
    const reader = input instanceof _m0.Reader ? input : _m0.Reader.create(input);
    let end = length === undefined ? reader.len : reader.pos + length;
    const message = createBaseFederationInfo();
    while (reader.pos < end) {
      const tag = reader.uint32();
      switch (tag >>> 3) {
        case 1:
          if (tag !== 10) {
            break;
          }

          message.servers.push(FederatedServer.decode(reader, reader.uint32()));
          continue;
      }
      if ((tag & 7) === 4 || tag === 0) {
        break;
      }
      reader.skipType(tag & 7);
    }
    return message;
  },

  fromJSON(object: any): FederationInfo {
    return {
      servers: globalThis.Array.isArray(object?.servers)
        ? object.servers.map((e: any) => FederatedServer.fromJSON(e))
        : [],
    };
  },

  toJSON(message: FederationInfo): unknown {
    const obj: any = {};
    if (message.servers?.length) {
      obj.servers = message.servers.map((e) => FederatedServer.toJSON(e));
    }
    return obj;
  },

  create<I extends Exact<DeepPartial<FederationInfo>, I>>(base?: I): FederationInfo {
    return FederationInfo.fromPartial(base ?? ({} as any));
  },
  fromPartial<I extends Exact<DeepPartial<FederationInfo>, I>>(object: I): FederationInfo {
    const message = createBaseFederationInfo();
    message.servers = object.servers?.map((e) => FederatedServer.fromPartial(e)) || [];
    return message;
  },
};

function createBaseFederatedServer(): FederatedServer {
  return { host: "", configuredByDefault: undefined, pinnedByDefault: undefined };
}

export const FederatedServer = {
  encode(message: FederatedServer, writer: _m0.Writer = _m0.Writer.create()): _m0.Writer {
    if (message.host !== "") {
      writer.uint32(10).string(message.host);
    }
    if (message.configuredByDefault !== undefined) {
      writer.uint32(16).bool(message.configuredByDefault);
    }
    if (message.pinnedByDefault !== undefined) {
      writer.uint32(24).bool(message.pinnedByDefault);
    }
    return writer;
  },

  decode(input: _m0.Reader | Uint8Array, length?: number): FederatedServer {
    const reader = input instanceof _m0.Reader ? input : _m0.Reader.create(input);
    let end = length === undefined ? reader.len : reader.pos + length;
    const message = createBaseFederatedServer();
    while (reader.pos < end) {
      const tag = reader.uint32();
      switch (tag >>> 3) {
        case 1:
          if (tag !== 10) {
            break;
          }

          message.host = reader.string();
          continue;
        case 2:
          if (tag !== 16) {
            break;
          }

          message.configuredByDefault = reader.bool();
          continue;
        case 3:
          if (tag !== 24) {
            break;
          }

          message.pinnedByDefault = reader.bool();
          continue;
      }
      if ((tag & 7) === 4 || tag === 0) {
        break;
      }
      reader.skipType(tag & 7);
    }
    return message;
  },

  fromJSON(object: any): FederatedServer {
    return {
      host: isSet(object.host) ? globalThis.String(object.host) : "",
      configuredByDefault: isSet(object.configuredByDefault)
        ? globalThis.Boolean(object.configuredByDefault)
        : undefined,
      pinnedByDefault: isSet(object.pinnedByDefault) ? globalThis.Boolean(object.pinnedByDefault) : undefined,
    };
  },

  toJSON(message: FederatedServer): unknown {
    const obj: any = {};
    if (message.host !== "") {
      obj.host = message.host;
    }
    if (message.configuredByDefault !== undefined) {
      obj.configuredByDefault = message.configuredByDefault;
    }
    if (message.pinnedByDefault !== undefined) {
      obj.pinnedByDefault = message.pinnedByDefault;
    }
    return obj;
  },

  create<I extends Exact<DeepPartial<FederatedServer>, I>>(base?: I): FederatedServer {
    return FederatedServer.fromPartial(base ?? ({} as any));
  },
  fromPartial<I extends Exact<DeepPartial<FederatedServer>, I>>(object: I): FederatedServer {
    const message = createBaseFederatedServer();
    message.host = object.host ?? "";
    message.configuredByDefault = object.configuredByDefault ?? undefined;
    message.pinnedByDefault = object.pinnedByDefault ?? undefined;
    return message;
  },
};

type Builtin = Date | Function | Uint8Array | string | number | boolean | undefined;

export type DeepPartial<T> = T extends Builtin ? T
  : T extends globalThis.Array<infer U> ? globalThis.Array<DeepPartial<U>>
  : T extends ReadonlyArray<infer U> ? ReadonlyArray<DeepPartial<U>>
  : T extends {} ? { [K in keyof T]?: DeepPartial<T[K]> }
  : Partial<T>;

type KeysOfUnion<T> = T extends T ? keyof T : never;
export type Exact<P, I extends P> = P extends Builtin ? P
  : P & { [K in keyof P]: Exact<P[K], I[K]> } & { [K in Exclude<keyof I, KeysOfUnion<P>>]: never };

function isSet(value: any): boolean {
  return value !== null && value !== undefined;
}
