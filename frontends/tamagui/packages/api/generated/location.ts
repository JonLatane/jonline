/* eslint-disable */
import _m0 from "protobufjs/minimal";

export const protobufPackage = "jonline";

/** Locations */
export interface Location {
  id: string;
  creatorId: string;
  /**
   * This should probably come from OpenStreetMap APIs, with an option for Google Maps.
   * Ideally both the Flutter and React apps, and any others, should prefer OpenStreetMap
   * but give the user the option to use Google Maps.
   */
  uniformlyFormattedAddress: string;
}

export interface LocationAlias {
  id: string;
  alias: string;
  creatorId: string;
}

function createBaseLocation(): Location {
  return { id: "", creatorId: "", uniformlyFormattedAddress: "" };
}

export const Location = {
  encode(message: Location, writer: _m0.Writer = _m0.Writer.create()): _m0.Writer {
    if (message.id !== "") {
      writer.uint32(10).string(message.id);
    }
    if (message.creatorId !== "") {
      writer.uint32(18).string(message.creatorId);
    }
    if (message.uniformlyFormattedAddress !== "") {
      writer.uint32(26).string(message.uniformlyFormattedAddress);
    }
    return writer;
  },

  decode(input: _m0.Reader | Uint8Array, length?: number): Location {
    const reader = input instanceof _m0.Reader ? input : _m0.Reader.create(input);
    let end = length === undefined ? reader.len : reader.pos + length;
    const message = createBaseLocation();
    while (reader.pos < end) {
      const tag = reader.uint32();
      switch (tag >>> 3) {
        case 1:
          if (tag !== 10) {
            break;
          }

          message.id = reader.string();
          continue;
        case 2:
          if (tag !== 18) {
            break;
          }

          message.creatorId = reader.string();
          continue;
        case 3:
          if (tag !== 26) {
            break;
          }

          message.uniformlyFormattedAddress = reader.string();
          continue;
      }
      if ((tag & 7) === 4 || tag === 0) {
        break;
      }
      reader.skipType(tag & 7);
    }
    return message;
  },

  fromJSON(object: any): Location {
    return {
      id: isSet(object.id) ? globalThis.String(object.id) : "",
      creatorId: isSet(object.creatorId) ? globalThis.String(object.creatorId) : "",
      uniformlyFormattedAddress: isSet(object.uniformlyFormattedAddress)
        ? globalThis.String(object.uniformlyFormattedAddress)
        : "",
    };
  },

  toJSON(message: Location): unknown {
    const obj: any = {};
    if (message.id !== "") {
      obj.id = message.id;
    }
    if (message.creatorId !== "") {
      obj.creatorId = message.creatorId;
    }
    if (message.uniformlyFormattedAddress !== "") {
      obj.uniformlyFormattedAddress = message.uniformlyFormattedAddress;
    }
    return obj;
  },

  create<I extends Exact<DeepPartial<Location>, I>>(base?: I): Location {
    return Location.fromPartial(base ?? ({} as any));
  },
  fromPartial<I extends Exact<DeepPartial<Location>, I>>(object: I): Location {
    const message = createBaseLocation();
    message.id = object.id ?? "";
    message.creatorId = object.creatorId ?? "";
    message.uniformlyFormattedAddress = object.uniformlyFormattedAddress ?? "";
    return message;
  },
};

function createBaseLocationAlias(): LocationAlias {
  return { id: "", alias: "", creatorId: "" };
}

export const LocationAlias = {
  encode(message: LocationAlias, writer: _m0.Writer = _m0.Writer.create()): _m0.Writer {
    if (message.id !== "") {
      writer.uint32(10).string(message.id);
    }
    if (message.alias !== "") {
      writer.uint32(18).string(message.alias);
    }
    if (message.creatorId !== "") {
      writer.uint32(26).string(message.creatorId);
    }
    return writer;
  },

  decode(input: _m0.Reader | Uint8Array, length?: number): LocationAlias {
    const reader = input instanceof _m0.Reader ? input : _m0.Reader.create(input);
    let end = length === undefined ? reader.len : reader.pos + length;
    const message = createBaseLocationAlias();
    while (reader.pos < end) {
      const tag = reader.uint32();
      switch (tag >>> 3) {
        case 1:
          if (tag !== 10) {
            break;
          }

          message.id = reader.string();
          continue;
        case 2:
          if (tag !== 18) {
            break;
          }

          message.alias = reader.string();
          continue;
        case 3:
          if (tag !== 26) {
            break;
          }

          message.creatorId = reader.string();
          continue;
      }
      if ((tag & 7) === 4 || tag === 0) {
        break;
      }
      reader.skipType(tag & 7);
    }
    return message;
  },

  fromJSON(object: any): LocationAlias {
    return {
      id: isSet(object.id) ? globalThis.String(object.id) : "",
      alias: isSet(object.alias) ? globalThis.String(object.alias) : "",
      creatorId: isSet(object.creatorId) ? globalThis.String(object.creatorId) : "",
    };
  },

  toJSON(message: LocationAlias): unknown {
    const obj: any = {};
    if (message.id !== "") {
      obj.id = message.id;
    }
    if (message.alias !== "") {
      obj.alias = message.alias;
    }
    if (message.creatorId !== "") {
      obj.creatorId = message.creatorId;
    }
    return obj;
  },

  create<I extends Exact<DeepPartial<LocationAlias>, I>>(base?: I): LocationAlias {
    return LocationAlias.fromPartial(base ?? ({} as any));
  },
  fromPartial<I extends Exact<DeepPartial<LocationAlias>, I>>(object: I): LocationAlias {
    const message = createBaseLocationAlias();
    message.id = object.id ?? "";
    message.alias = object.alias ?? "";
    message.creatorId = object.creatorId ?? "";
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
