/* eslint-disable */
import _m0 from "protobufjs/minimal";
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
 * Valid GetEventsRequest formats:
 * - {[listing_type: PublicEvents]}                  (TODO: get ServerPublic/GlobalPublic events you can see)
 * - {listing_type:MyGroupsEvents|FollowingEvents}   (TODO: get events for groups joined or user followed; auth required)
 * - {event_id:}                                     (TODO: get single event including preview data)
 * - {listing_type: GroupEvents|
 *      GroupEventsPendingModeration,
 *      group_id:}                                  (TODO: get events/events needing moderation for a group)
 * - {author_user_id:, group_id:}                   (TODO: get events by a user for a group)
 * - {listing_type: AuthorEvents, author_user_id:}  (TODO: get events by a user)
 */
export interface GetMediaRequest {
  /** Returns the single event with the given ID. */
  eventId?: string | undefined;
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
 * HTTP Media endpoints support supplying the Access Token in a `jonline-media-access` cookie.
 * Fetching media without authentication requires that it has `GLOBAL_PUBLIC` visibility.
 */
export interface Media {
  /** The ID of the Media object. */
  id: string;
  /** An optional title for the media item. */
  title?:
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
}

function createBaseGetMediaRequest(): GetMediaRequest {
  return { eventId: undefined, page: 0 };
}

export const GetMediaRequest = {
  encode(message: GetMediaRequest, writer: _m0.Writer = _m0.Writer.create()): _m0.Writer {
    if (message.eventId !== undefined) {
      writer.uint32(10).string(message.eventId);
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
          message.eventId = reader.string();
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
      eventId: isSet(object.eventId) ? String(object.eventId) : undefined,
      page: isSet(object.page) ? Number(object.page) : 0,
    };
  },

  toJSON(message: GetMediaRequest): unknown {
    const obj: any = {};
    message.eventId !== undefined && (obj.eventId = message.eventId);
    message.page !== undefined && (obj.page = Math.round(message.page));
    return obj;
  },

  create<I extends Exact<DeepPartial<GetMediaRequest>, I>>(base?: I): GetMediaRequest {
    return GetMediaRequest.fromPartial(base ?? {});
  },

  fromPartial<I extends Exact<DeepPartial<GetMediaRequest>, I>>(object: I): GetMediaRequest {
    const message = createBaseGetMediaRequest();
    message.eventId = object.eventId ?? undefined;
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
  return { id: "", title: undefined, description: undefined, visibility: 0, moderation: 0 };
}

export const Media = {
  encode(message: Media, writer: _m0.Writer = _m0.Writer.create()): _m0.Writer {
    if (message.id !== "") {
      writer.uint32(10).string(message.id);
    }
    if (message.title !== undefined) {
      writer.uint32(18).string(message.title);
    }
    if (message.description !== undefined) {
      writer.uint32(26).string(message.description);
    }
    if (message.visibility !== 0) {
      writer.uint32(32).int32(message.visibility);
    }
    if (message.moderation !== 0) {
      writer.uint32(40).int32(message.moderation);
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
          message.title = reader.string();
          break;
        case 3:
          message.description = reader.string();
          break;
        case 4:
          message.visibility = reader.int32() as any;
          break;
        case 5:
          message.moderation = reader.int32() as any;
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
      title: isSet(object.title) ? String(object.title) : undefined,
      description: isSet(object.description) ? String(object.description) : undefined,
      visibility: isSet(object.visibility) ? visibilityFromJSON(object.visibility) : 0,
      moderation: isSet(object.moderation) ? moderationFromJSON(object.moderation) : 0,
    };
  },

  toJSON(message: Media): unknown {
    const obj: any = {};
    message.id !== undefined && (obj.id = message.id);
    message.title !== undefined && (obj.title = message.title);
    message.description !== undefined && (obj.description = message.description);
    message.visibility !== undefined && (obj.visibility = visibilityToJSON(message.visibility));
    message.moderation !== undefined && (obj.moderation = moderationToJSON(message.moderation));
    return obj;
  },

  create<I extends Exact<DeepPartial<Media>, I>>(base?: I): Media {
    return Media.fromPartial(base ?? {});
  },

  fromPartial<I extends Exact<DeepPartial<Media>, I>>(object: I): Media {
    const message = createBaseMedia();
    message.id = object.id ?? "";
    message.title = object.title ?? undefined;
    message.description = object.description ?? undefined;
    message.visibility = object.visibility ?? 0;
    message.moderation = object.moderation ?? 0;
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

function isSet(value: any): boolean {
  return value !== null && value !== undefined;
}
