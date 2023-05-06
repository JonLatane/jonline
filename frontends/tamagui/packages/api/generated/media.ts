/* eslint-disable */
import _m0 from "protobufjs/minimal";
import { Timestamp } from "./google/protobuf/timestamp";
import {
  Moderation,
  moderationFromJSON,
  moderationToJSON,
  Visibility,
  visibilityFromJSON,
  visibilityToJSON,
} from "./visibility_moderation";

export const protobufPackage = "jonline";

/**
 * Valid GetMediaRequest formats:
 * - `{user_id: "123"}` - Gets the media of the given user that the current user can see. IE:
 *     - *all* of the current user's own media
 *     - `GLOBAL_PUBLIC` media for the user if the current user is not logged in.
 *     - `SERVER_PUBLIC` media for the user if the current user is logged in.
 *     - `LIMITED` media for the user if the current user is following the user.
 * - `{media_id: "123"}` - Gets the media with the given ID, if visible to the current user.
 */
export interface GetMediaRequest {
  /** Returns the single media item with the given ID. */
  mediaId?:
    | string
    | undefined;
  /** Returns all media items for the given user. */
  userId?: string | undefined;
  page: number;
}

export interface GetMediaResponse {
  media: Media[];
  hasNextPage: boolean;
}

/**
 * A Jonline `Media` object represents a single media item, such as a photo or video.
 * Media data is deliberately *not returnable from the gRPC API*. Instead, the client
 * should fetch media from `http[s]://my.jonline.instance/media/{id}` (TODO: implement this).
 *
 * Media objects may be created with a POST or PUT to `http[s]://my.jonline.instance/media`.
 * On success, the endpoint will return the media ID.
 *
 * HTTP Media endpoints support supplying the Access Token in a `jonline-media-access` cookie,
 * or via a `jonline_access_token` query parameter.
 * Fetching media without authentication requires that it has `GLOBAL_PUBLIC` visibility.
 */
export interface Media {
  /** The ID of the media item. */
  id: string;
  /** The ID of the user who created the media item. */
  userId?:
    | string
    | undefined;
  /** An optional title for the media item. */
  name?:
    | string
    | undefined;
  /** An optional description for the media item. */
  description?:
    | string
    | undefined;
  /** Visibility of the media item. */
  visibility: Visibility;
  /** Moderation of the media item. */
  moderation: Moderation;
  createdAt: string | undefined;
  updatedAt: string | undefined;
}

function createBaseGetMediaRequest(): GetMediaRequest {
  return { mediaId: undefined, userId: undefined, page: 0 };
}

export const GetMediaRequest = {
  encode(message: GetMediaRequest, writer: _m0.Writer = _m0.Writer.create()): _m0.Writer {
    if (message.mediaId !== undefined) {
      writer.uint32(10).string(message.mediaId);
    }
    if (message.userId !== undefined) {
      writer.uint32(18).string(message.userId);
    }
    if (message.page !== 0) {
      writer.uint32(88).uint32(message.page);
    }
    return writer;
  },

  decode(input: _m0.Reader | Uint8Array, length?: number): GetMediaRequest {
    const reader = input instanceof _m0.Reader ? input : new _m0.Reader(input);
    let end = length === undefined ? reader.len : reader.pos + length;
    const message = createBaseGetMediaRequest();
    while (reader.pos < end) {
      const tag = reader.uint32();
      switch (tag >>> 3) {
        case 1:
          message.mediaId = reader.string();
          break;
        case 2:
          message.userId = reader.string();
          break;
        case 11:
          message.page = reader.uint32();
          break;
        default:
          reader.skipType(tag & 7);
          break;
      }
    }
    return message;
  },

  fromJSON(object: any): GetMediaRequest {
    return {
      mediaId: isSet(object.mediaId) ? String(object.mediaId) : undefined,
      userId: isSet(object.userId) ? String(object.userId) : undefined,
      page: isSet(object.page) ? Number(object.page) : 0,
    };
  },

  toJSON(message: GetMediaRequest): unknown {
    const obj: any = {};
    message.mediaId !== undefined && (obj.mediaId = message.mediaId);
    message.userId !== undefined && (obj.userId = message.userId);
    message.page !== undefined && (obj.page = Math.round(message.page));
    return obj;
  },

  create<I extends Exact<DeepPartial<GetMediaRequest>, I>>(base?: I): GetMediaRequest {
    return GetMediaRequest.fromPartial(base ?? {});
  },

  fromPartial<I extends Exact<DeepPartial<GetMediaRequest>, I>>(object: I): GetMediaRequest {
    const message = createBaseGetMediaRequest();
    message.mediaId = object.mediaId ?? undefined;
    message.userId = object.userId ?? undefined;
    message.page = object.page ?? 0;
    return message;
  },
};

function createBaseGetMediaResponse(): GetMediaResponse {
  return { media: [], hasNextPage: false };
}

export const GetMediaResponse = {
  encode(message: GetMediaResponse, writer: _m0.Writer = _m0.Writer.create()): _m0.Writer {
    for (const v of message.media) {
      Media.encode(v!, writer.uint32(10).fork()).ldelim();
    }
    if (message.hasNextPage === true) {
      writer.uint32(16).bool(message.hasNextPage);
    }
    return writer;
  },

  decode(input: _m0.Reader | Uint8Array, length?: number): GetMediaResponse {
    const reader = input instanceof _m0.Reader ? input : new _m0.Reader(input);
    let end = length === undefined ? reader.len : reader.pos + length;
    const message = createBaseGetMediaResponse();
    while (reader.pos < end) {
      const tag = reader.uint32();
      switch (tag >>> 3) {
        case 1:
          message.media.push(Media.decode(reader, reader.uint32()));
          break;
        case 2:
          message.hasNextPage = reader.bool();
          break;
        default:
          reader.skipType(tag & 7);
          break;
      }
    }
    return message;
  },

  fromJSON(object: any): GetMediaResponse {
    return {
      media: Array.isArray(object?.media) ? object.media.map((e: any) => Media.fromJSON(e)) : [],
      hasNextPage: isSet(object.hasNextPage) ? Boolean(object.hasNextPage) : false,
    };
  },

  toJSON(message: GetMediaResponse): unknown {
    const obj: any = {};
    if (message.media) {
      obj.media = message.media.map((e) => e ? Media.toJSON(e) : undefined);
    } else {
      obj.media = [];
    }
    message.hasNextPage !== undefined && (obj.hasNextPage = message.hasNextPage);
    return obj;
  },

  create<I extends Exact<DeepPartial<GetMediaResponse>, I>>(base?: I): GetMediaResponse {
    return GetMediaResponse.fromPartial(base ?? {});
  },

  fromPartial<I extends Exact<DeepPartial<GetMediaResponse>, I>>(object: I): GetMediaResponse {
    const message = createBaseGetMediaResponse();
    message.media = object.media?.map((e) => Media.fromPartial(e)) || [];
    message.hasNextPage = object.hasNextPage ?? false;
    return message;
  },
};

function createBaseMedia(): Media {
  return {
    id: "",
    userId: undefined,
    name: undefined,
    description: undefined,
    visibility: 0,
    moderation: 0,
    createdAt: undefined,
    updatedAt: undefined,
  };
}

export const Media = {
  encode(message: Media, writer: _m0.Writer = _m0.Writer.create()): _m0.Writer {
    if (message.id !== "") {
      writer.uint32(10).string(message.id);
    }
    if (message.userId !== undefined) {
      writer.uint32(18).string(message.userId);
    }
    if (message.name !== undefined) {
      writer.uint32(26).string(message.name);
    }
    if (message.description !== undefined) {
      writer.uint32(34).string(message.description);
    }
    if (message.visibility !== 0) {
      writer.uint32(40).int32(message.visibility);
    }
    if (message.moderation !== 0) {
      writer.uint32(48).int32(message.moderation);
    }
    if (message.createdAt !== undefined) {
      Timestamp.encode(toTimestamp(message.createdAt), writer.uint32(122).fork()).ldelim();
    }
    if (message.updatedAt !== undefined) {
      Timestamp.encode(toTimestamp(message.updatedAt), writer.uint32(130).fork()).ldelim();
    }
    return writer;
  },

  decode(input: _m0.Reader | Uint8Array, length?: number): Media {
    const reader = input instanceof _m0.Reader ? input : new _m0.Reader(input);
    let end = length === undefined ? reader.len : reader.pos + length;
    const message = createBaseMedia();
    while (reader.pos < end) {
      const tag = reader.uint32();
      switch (tag >>> 3) {
        case 1:
          message.id = reader.string();
          break;
        case 2:
          message.userId = reader.string();
          break;
        case 3:
          message.name = reader.string();
          break;
        case 4:
          message.description = reader.string();
          break;
        case 5:
          message.visibility = reader.int32() as any;
          break;
        case 6:
          message.moderation = reader.int32() as any;
          break;
        case 15:
          message.createdAt = fromTimestamp(Timestamp.decode(reader, reader.uint32()));
          break;
        case 16:
          message.updatedAt = fromTimestamp(Timestamp.decode(reader, reader.uint32()));
          break;
        default:
          reader.skipType(tag & 7);
          break;
      }
    }
    return message;
  },

  fromJSON(object: any): Media {
    return {
      id: isSet(object.id) ? String(object.id) : "",
      userId: isSet(object.userId) ? String(object.userId) : undefined,
      name: isSet(object.name) ? String(object.name) : undefined,
      description: isSet(object.description) ? String(object.description) : undefined,
      visibility: isSet(object.visibility) ? visibilityFromJSON(object.visibility) : 0,
      moderation: isSet(object.moderation) ? moderationFromJSON(object.moderation) : 0,
      createdAt: isSet(object.createdAt) ? String(object.createdAt) : undefined,
      updatedAt: isSet(object.updatedAt) ? String(object.updatedAt) : undefined,
    };
  },

  toJSON(message: Media): unknown {
    const obj: any = {};
    message.id !== undefined && (obj.id = message.id);
    message.userId !== undefined && (obj.userId = message.userId);
    message.name !== undefined && (obj.name = message.name);
    message.description !== undefined && (obj.description = message.description);
    message.visibility !== undefined && (obj.visibility = visibilityToJSON(message.visibility));
    message.moderation !== undefined && (obj.moderation = moderationToJSON(message.moderation));
    message.createdAt !== undefined && (obj.createdAt = message.createdAt);
    message.updatedAt !== undefined && (obj.updatedAt = message.updatedAt);
    return obj;
  },

  create<I extends Exact<DeepPartial<Media>, I>>(base?: I): Media {
    return Media.fromPartial(base ?? {});
  },

  fromPartial<I extends Exact<DeepPartial<Media>, I>>(object: I): Media {
    const message = createBaseMedia();
    message.id = object.id ?? "";
    message.userId = object.userId ?? undefined;
    message.name = object.name ?? undefined;
    message.description = object.description ?? undefined;
    message.visibility = object.visibility ?? 0;
    message.moderation = object.moderation ?? 0;
    message.createdAt = object.createdAt ?? undefined;
    message.updatedAt = object.updatedAt ?? undefined;
    return message;
  },
};

type Builtin = Date | Function | Uint8Array | string | number | boolean | undefined;

export type DeepPartial<T> = T extends Builtin ? T
  : T extends Array<infer U> ? Array<DeepPartial<U>> : T extends ReadonlyArray<infer U> ? ReadonlyArray<DeepPartial<U>>
  : T extends {} ? { [K in keyof T]?: DeepPartial<T[K]> }
  : Partial<T>;

type KeysOfUnion<T> = T extends T ? keyof T : never;
export type Exact<P, I extends P> = P extends Builtin ? P
  : P & { [K in keyof P]: Exact<P[K], I[K]> } & { [K in Exclude<keyof I, KeysOfUnion<P>>]: never };

function toTimestamp(dateStr: string): Timestamp {
  const date = new Date(dateStr);
  const seconds = date.getTime() / 1_000;
  const nanos = (date.getTime() % 1_000) * 1_000_000;
  return { seconds, nanos };
}

function fromTimestamp(t: Timestamp): string {
  let millis = t.seconds * 1_000;
  millis += t.nanos / 1_000_000;
  return new Date(millis).toISOString();
}

function isSet(value: any): boolean {
  return value !== null && value !== undefined;
}
