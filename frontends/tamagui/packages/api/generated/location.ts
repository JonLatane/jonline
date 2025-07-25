// Code generated by protoc-gen-ts_proto. DO NOT EDIT.
// versions:
//   protoc-gen-ts_proto  v2.7.5
//   protoc               v5.29.3
// source: location.proto

/* eslint-disable */
import { BinaryReader, BinaryWriter } from "@bufbuild/protobuf/wire";

export const protobufPackage = "jonline";

/** Locations are places where events can happen. */
export interface Location {
  /** The ID of the location. May not be unique. */
  id: string;
  /** The User ID of the location's creator, if available. */
  creatorId: string;
  /**
   * This should probably come from OpenStreetMap APIs, with an option for Google Maps.
   * Ideally both the Flutter and React apps, and any others, should prefer OpenStreetMap
   * but give the user the option to use Google Maps.
   */
  uniformlyFormattedAddress: string;
}

function createBaseLocation(): Location {
  return { id: "", creatorId: "", uniformlyFormattedAddress: "" };
}

export const Location: MessageFns<Location> = {
  encode(message: Location, writer: BinaryWriter = new BinaryWriter()): BinaryWriter {
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

  decode(input: BinaryReader | Uint8Array, length?: number): Location {
    const reader = input instanceof BinaryReader ? input : new BinaryReader(input);
    const end = length === undefined ? reader.len : reader.pos + length;
    const message = createBaseLocation();
    while (reader.pos < end) {
      const tag = reader.uint32();
      switch (tag >>> 3) {
        case 1: {
          if (tag !== 10) {
            break;
          }

          message.id = reader.string();
          continue;
        }
        case 2: {
          if (tag !== 18) {
            break;
          }

          message.creatorId = reader.string();
          continue;
        }
        case 3: {
          if (tag !== 26) {
            break;
          }

          message.uniformlyFormattedAddress = reader.string();
          continue;
        }
      }
      if ((tag & 7) === 4 || tag === 0) {
        break;
      }
      reader.skip(tag & 7);
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

export interface MessageFns<T> {
  encode(message: T, writer?: BinaryWriter): BinaryWriter;
  decode(input: BinaryReader | Uint8Array, length?: number): T;
  fromJSON(object: any): T;
  toJSON(message: T): unknown;
  create<I extends Exact<DeepPartial<T>, I>>(base?: I): T;
  fromPartial<I extends Exact<DeepPartial<T>, I>>(object: I): T;
}
