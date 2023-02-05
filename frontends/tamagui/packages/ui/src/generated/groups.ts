/* eslint-disable */
import _m0 from "protobufjs/minimal";
import { Timestamp } from "./google/protobuf/timestamp";
import { Permission, permissionFromJSON, permissionToJSON } from "./permissions";
import { Membership, User } from "./users";
import {
  Moderation,
  moderationFromJSON,
  moderationToJSON,
  Visibility,
  visibilityFromJSON,
  visibilityToJSON,
} from "./visibility_moderation";

export const protobufPackage = "jonline";

export enum GroupListingType {
  ALL_GROUPS = 0,
  MY_GROUPS = 1,
  REQUESTED = 2,
  INVITED = 3,
  UNRECOGNIZED = -1,
}

export function groupListingTypeFromJSON(object: any): GroupListingType {
  switch (object) {
    case 0:
    case "ALL_GROUPS":
      return GroupListingType.ALL_GROUPS;
    case 1:
    case "MY_GROUPS":
      return GroupListingType.MY_GROUPS;
    case 2:
    case "REQUESTED":
      return GroupListingType.REQUESTED;
    case 3:
    case "INVITED":
      return GroupListingType.INVITED;
    case -1:
    case "UNRECOGNIZED":
    default:
      return GroupListingType.UNRECOGNIZED;
  }
}

export function groupListingTypeToJSON(object: GroupListingType): string {
  switch (object) {
    case GroupListingType.ALL_GROUPS:
      return "ALL_GROUPS";
    case GroupListingType.MY_GROUPS:
      return "MY_GROUPS";
    case GroupListingType.REQUESTED:
      return "REQUESTED";
    case GroupListingType.INVITED:
      return "INVITED";
    case GroupListingType.UNRECOGNIZED:
    default:
      return "UNRECOGNIZED";
  }
}

export interface Group {
  id: string;
  name: string;
  shortname: string;
  description: string;
  avatar?: Uint8Array | undefined;
  defaultMembershipPermissions: Permission[];
  /** Valid values are PENDING (requires a moderator to let you join) and UNMODERATED. */
  defaultMembershipModeration: Moderation;
  defaultPostModeration: Moderation;
  defaultEventModeration: Moderation;
  /**
   * LIMITED visibility groups are only visible to members. PRIVATE groups are only
   * visibile to users with the ADMIN group permission.
   */
  visibility: Visibility;
  memberCount: number;
  postCount: number;
  currentUserMembership?: Membership | undefined;
  createdAt: string | undefined;
  updatedAt?: string | undefined;
}

export interface GetGroupsRequest {
  groupId?: string | undefined;
  groupName?: string | undefined;
  listingType: GroupListingType;
  page?: number | undefined;
}

export interface GetGroupsResponse {
  groups: Group[];
  hasNextPage: boolean;
}

/**
 * Used by group MODERATE_USERS mods to manage group requests from the People tab.
 * See also: UserListingType.MEMBERSHIP_REQUESTS.
 */
export interface Member {
  user: User | undefined;
  membership: Membership | undefined;
}

export interface GetMembersRequest {
  groupId: string;
  username?: string | undefined;
  groupModeration?: Moderation | undefined;
  page?: number | undefined;
}

export interface GetMembersResponse {
  members: Member[];
  hasNextPage: boolean;
}

function createBaseGroup(): Group {
  return {
    id: "",
    name: "",
    shortname: "",
    description: "",
    avatar: undefined,
    defaultMembershipPermissions: [],
    defaultMembershipModeration: 0,
    defaultPostModeration: 0,
    defaultEventModeration: 0,
    visibility: 0,
    memberCount: 0,
    postCount: 0,
    currentUserMembership: undefined,
    createdAt: undefined,
    updatedAt: undefined,
  };
}

export const Group = {
  encode(message: Group, writer: _m0.Writer = _m0.Writer.create()): _m0.Writer {
    if (message.id !== "") {
      writer.uint32(10).string(message.id);
    }
    if (message.name !== "") {
      writer.uint32(18).string(message.name);
    }
    if (message.shortname !== "") {
      writer.uint32(26).string(message.shortname);
    }
    if (message.description !== "") {
      writer.uint32(34).string(message.description);
    }
    if (message.avatar !== undefined) {
      writer.uint32(42).bytes(message.avatar);
    }
    writer.uint32(50).fork();
    for (const v of message.defaultMembershipPermissions) {
      writer.int32(v);
    }
    writer.ldelim();
    if (message.defaultMembershipModeration !== 0) {
      writer.uint32(56).int32(message.defaultMembershipModeration);
    }
    if (message.defaultPostModeration !== 0) {
      writer.uint32(64).int32(message.defaultPostModeration);
    }
    if (message.defaultEventModeration !== 0) {
      writer.uint32(72).int32(message.defaultEventModeration);
    }
    if (message.visibility !== 0) {
      writer.uint32(80).int32(message.visibility);
    }
    if (message.memberCount !== 0) {
      writer.uint32(88).uint32(message.memberCount);
    }
    if (message.postCount !== 0) {
      writer.uint32(96).uint32(message.postCount);
    }
    if (message.currentUserMembership !== undefined) {
      Membership.encode(message.currentUserMembership, writer.uint32(106).fork()).ldelim();
    }
    if (message.createdAt !== undefined) {
      Timestamp.encode(toTimestamp(message.createdAt), writer.uint32(114).fork()).ldelim();
    }
    if (message.updatedAt !== undefined) {
      Timestamp.encode(toTimestamp(message.updatedAt), writer.uint32(122).fork()).ldelim();
    }
    return writer;
  },

  decode(input: _m0.Reader | Uint8Array, length?: number): Group {
    const reader = input instanceof _m0.Reader ? input : new _m0.Reader(input);
    let end = length === undefined ? reader.len : reader.pos + length;
    const message = createBaseGroup();
    while (reader.pos < end) {
      const tag = reader.uint32();
      switch (tag >>> 3) {
        case 1:
          message.id = reader.string();
          break;
        case 2:
          message.name = reader.string();
          break;
        case 3:
          message.shortname = reader.string();
          break;
        case 4:
          message.description = reader.string();
          break;
        case 5:
          message.avatar = reader.bytes();
          break;
        case 6:
          if ((tag & 7) === 2) {
            const end2 = reader.uint32() + reader.pos;
            while (reader.pos < end2) {
              message.defaultMembershipPermissions.push(reader.int32() as any);
            }
          } else {
            message.defaultMembershipPermissions.push(reader.int32() as any);
          }
          break;
        case 7:
          message.defaultMembershipModeration = reader.int32() as any;
          break;
        case 8:
          message.defaultPostModeration = reader.int32() as any;
          break;
        case 9:
          message.defaultEventModeration = reader.int32() as any;
          break;
        case 10:
          message.visibility = reader.int32() as any;
          break;
        case 11:
          message.memberCount = reader.uint32();
          break;
        case 12:
          message.postCount = reader.uint32();
          break;
        case 13:
          message.currentUserMembership = Membership.decode(reader, reader.uint32());
          break;
        case 14:
          message.createdAt = fromTimestamp(Timestamp.decode(reader, reader.uint32()));
          break;
        case 15:
          message.updatedAt = fromTimestamp(Timestamp.decode(reader, reader.uint32()));
          break;
        default:
          reader.skipType(tag & 7);
          break;
      }
    }
    return message;
  },

  fromJSON(object: any): Group {
    return {
      id: isSet(object.id) ? String(object.id) : "",
      name: isSet(object.name) ? String(object.name) : "",
      shortname: isSet(object.shortname) ? String(object.shortname) : "",
      description: isSet(object.description) ? String(object.description) : "",
      avatar: isSet(object.avatar) ? bytesFromBase64(object.avatar) : undefined,
      defaultMembershipPermissions: Array.isArray(object?.defaultMembershipPermissions)
        ? object.defaultMembershipPermissions.map((e: any) => permissionFromJSON(e))
        : [],
      defaultMembershipModeration: isSet(object.defaultMembershipModeration)
        ? moderationFromJSON(object.defaultMembershipModeration)
        : 0,
      defaultPostModeration: isSet(object.defaultPostModeration) ? moderationFromJSON(object.defaultPostModeration) : 0,
      defaultEventModeration: isSet(object.defaultEventModeration)
        ? moderationFromJSON(object.defaultEventModeration)
        : 0,
      visibility: isSet(object.visibility) ? visibilityFromJSON(object.visibility) : 0,
      memberCount: isSet(object.memberCount) ? Number(object.memberCount) : 0,
      postCount: isSet(object.postCount) ? Number(object.postCount) : 0,
      currentUserMembership: isSet(object.currentUserMembership)
        ? Membership.fromJSON(object.currentUserMembership)
        : undefined,
      createdAt: isSet(object.createdAt) ? String(object.createdAt) : undefined,
      updatedAt: isSet(object.updatedAt) ? String(object.updatedAt) : undefined,
    };
  },

  toJSON(message: Group): unknown {
    const obj: any = {};
    message.id !== undefined && (obj.id = message.id);
    message.name !== undefined && (obj.name = message.name);
    message.shortname !== undefined && (obj.shortname = message.shortname);
    message.description !== undefined && (obj.description = message.description);
    message.avatar !== undefined &&
      (obj.avatar = message.avatar !== undefined ? base64FromBytes(message.avatar) : undefined);
    if (message.defaultMembershipPermissions) {
      obj.defaultMembershipPermissions = message.defaultMembershipPermissions.map((e) => permissionToJSON(e));
    } else {
      obj.defaultMembershipPermissions = [];
    }
    message.defaultMembershipModeration !== undefined &&
      (obj.defaultMembershipModeration = moderationToJSON(message.defaultMembershipModeration));
    message.defaultPostModeration !== undefined &&
      (obj.defaultPostModeration = moderationToJSON(message.defaultPostModeration));
    message.defaultEventModeration !== undefined &&
      (obj.defaultEventModeration = moderationToJSON(message.defaultEventModeration));
    message.visibility !== undefined && (obj.visibility = visibilityToJSON(message.visibility));
    message.memberCount !== undefined && (obj.memberCount = Math.round(message.memberCount));
    message.postCount !== undefined && (obj.postCount = Math.round(message.postCount));
    message.currentUserMembership !== undefined && (obj.currentUserMembership = message.currentUserMembership
      ? Membership.toJSON(message.currentUserMembership)
      : undefined);
    message.createdAt !== undefined && (obj.createdAt = message.createdAt);
    message.updatedAt !== undefined && (obj.updatedAt = message.updatedAt);
    return obj;
  },

  create<I extends Exact<DeepPartial<Group>, I>>(base?: I): Group {
    return Group.fromPartial(base ?? {});
  },

  fromPartial<I extends Exact<DeepPartial<Group>, I>>(object: I): Group {
    const message = createBaseGroup();
    message.id = object.id ?? "";
    message.name = object.name ?? "";
    message.shortname = object.shortname ?? "";
    message.description = object.description ?? "";
    message.avatar = object.avatar ?? undefined;
    message.defaultMembershipPermissions = object.defaultMembershipPermissions?.map((e) => e) || [];
    message.defaultMembershipModeration = object.defaultMembershipModeration ?? 0;
    message.defaultPostModeration = object.defaultPostModeration ?? 0;
    message.defaultEventModeration = object.defaultEventModeration ?? 0;
    message.visibility = object.visibility ?? 0;
    message.memberCount = object.memberCount ?? 0;
    message.postCount = object.postCount ?? 0;
    message.currentUserMembership =
      (object.currentUserMembership !== undefined && object.currentUserMembership !== null)
        ? Membership.fromPartial(object.currentUserMembership)
        : undefined;
    message.createdAt = object.createdAt ?? undefined;
    message.updatedAt = object.updatedAt ?? undefined;
    return message;
  },
};

function createBaseGetGroupsRequest(): GetGroupsRequest {
  return { groupId: undefined, groupName: undefined, listingType: 0, page: undefined };
}

export const GetGroupsRequest = {
  encode(message: GetGroupsRequest, writer: _m0.Writer = _m0.Writer.create()): _m0.Writer {
    if (message.groupId !== undefined) {
      writer.uint32(10).string(message.groupId);
    }
    if (message.groupName !== undefined) {
      writer.uint32(18).string(message.groupName);
    }
    if (message.listingType !== 0) {
      writer.uint32(24).int32(message.listingType);
    }
    if (message.page !== undefined) {
      writer.uint32(32).int32(message.page);
    }
    return writer;
  },

  decode(input: _m0.Reader | Uint8Array, length?: number): GetGroupsRequest {
    const reader = input instanceof _m0.Reader ? input : new _m0.Reader(input);
    let end = length === undefined ? reader.len : reader.pos + length;
    const message = createBaseGetGroupsRequest();
    while (reader.pos < end) {
      const tag = reader.uint32();
      switch (tag >>> 3) {
        case 1:
          message.groupId = reader.string();
          break;
        case 2:
          message.groupName = reader.string();
          break;
        case 3:
          message.listingType = reader.int32() as any;
          break;
        case 4:
          message.page = reader.int32();
          break;
        default:
          reader.skipType(tag & 7);
          break;
      }
    }
    return message;
  },

  fromJSON(object: any): GetGroupsRequest {
    return {
      groupId: isSet(object.groupId) ? String(object.groupId) : undefined,
      groupName: isSet(object.groupName) ? String(object.groupName) : undefined,
      listingType: isSet(object.listingType) ? groupListingTypeFromJSON(object.listingType) : 0,
      page: isSet(object.page) ? Number(object.page) : undefined,
    };
  },

  toJSON(message: GetGroupsRequest): unknown {
    const obj: any = {};
    message.groupId !== undefined && (obj.groupId = message.groupId);
    message.groupName !== undefined && (obj.groupName = message.groupName);
    message.listingType !== undefined && (obj.listingType = groupListingTypeToJSON(message.listingType));
    message.page !== undefined && (obj.page = Math.round(message.page));
    return obj;
  },

  create<I extends Exact<DeepPartial<GetGroupsRequest>, I>>(base?: I): GetGroupsRequest {
    return GetGroupsRequest.fromPartial(base ?? {});
  },

  fromPartial<I extends Exact<DeepPartial<GetGroupsRequest>, I>>(object: I): GetGroupsRequest {
    const message = createBaseGetGroupsRequest();
    message.groupId = object.groupId ?? undefined;
    message.groupName = object.groupName ?? undefined;
    message.listingType = object.listingType ?? 0;
    message.page = object.page ?? undefined;
    return message;
  },
};

function createBaseGetGroupsResponse(): GetGroupsResponse {
  return { groups: [], hasNextPage: false };
}

export const GetGroupsResponse = {
  encode(message: GetGroupsResponse, writer: _m0.Writer = _m0.Writer.create()): _m0.Writer {
    for (const v of message.groups) {
      Group.encode(v!, writer.uint32(10).fork()).ldelim();
    }
    if (message.hasNextPage === true) {
      writer.uint32(16).bool(message.hasNextPage);
    }
    return writer;
  },

  decode(input: _m0.Reader | Uint8Array, length?: number): GetGroupsResponse {
    const reader = input instanceof _m0.Reader ? input : new _m0.Reader(input);
    let end = length === undefined ? reader.len : reader.pos + length;
    const message = createBaseGetGroupsResponse();
    while (reader.pos < end) {
      const tag = reader.uint32();
      switch (tag >>> 3) {
        case 1:
          message.groups.push(Group.decode(reader, reader.uint32()));
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

  fromJSON(object: any): GetGroupsResponse {
    return {
      groups: Array.isArray(object?.groups) ? object.groups.map((e: any) => Group.fromJSON(e)) : [],
      hasNextPage: isSet(object.hasNextPage) ? Boolean(object.hasNextPage) : false,
    };
  },

  toJSON(message: GetGroupsResponse): unknown {
    const obj: any = {};
    if (message.groups) {
      obj.groups = message.groups.map((e) => e ? Group.toJSON(e) : undefined);
    } else {
      obj.groups = [];
    }
    message.hasNextPage !== undefined && (obj.hasNextPage = message.hasNextPage);
    return obj;
  },

  create<I extends Exact<DeepPartial<GetGroupsResponse>, I>>(base?: I): GetGroupsResponse {
    return GetGroupsResponse.fromPartial(base ?? {});
  },

  fromPartial<I extends Exact<DeepPartial<GetGroupsResponse>, I>>(object: I): GetGroupsResponse {
    const message = createBaseGetGroupsResponse();
    message.groups = object.groups?.map((e) => Group.fromPartial(e)) || [];
    message.hasNextPage = object.hasNextPage ?? false;
    return message;
  },
};

function createBaseMember(): Member {
  return { user: undefined, membership: undefined };
}

export const Member = {
  encode(message: Member, writer: _m0.Writer = _m0.Writer.create()): _m0.Writer {
    if (message.user !== undefined) {
      User.encode(message.user, writer.uint32(10).fork()).ldelim();
    }
    if (message.membership !== undefined) {
      Membership.encode(message.membership, writer.uint32(18).fork()).ldelim();
    }
    return writer;
  },

  decode(input: _m0.Reader | Uint8Array, length?: number): Member {
    const reader = input instanceof _m0.Reader ? input : new _m0.Reader(input);
    let end = length === undefined ? reader.len : reader.pos + length;
    const message = createBaseMember();
    while (reader.pos < end) {
      const tag = reader.uint32();
      switch (tag >>> 3) {
        case 1:
          message.user = User.decode(reader, reader.uint32());
          break;
        case 2:
          message.membership = Membership.decode(reader, reader.uint32());
          break;
        default:
          reader.skipType(tag & 7);
          break;
      }
    }
    return message;
  },

  fromJSON(object: any): Member {
    return {
      user: isSet(object.user) ? User.fromJSON(object.user) : undefined,
      membership: isSet(object.membership) ? Membership.fromJSON(object.membership) : undefined,
    };
  },

  toJSON(message: Member): unknown {
    const obj: any = {};
    message.user !== undefined && (obj.user = message.user ? User.toJSON(message.user) : undefined);
    message.membership !== undefined &&
      (obj.membership = message.membership ? Membership.toJSON(message.membership) : undefined);
    return obj;
  },

  create<I extends Exact<DeepPartial<Member>, I>>(base?: I): Member {
    return Member.fromPartial(base ?? {});
  },

  fromPartial<I extends Exact<DeepPartial<Member>, I>>(object: I): Member {
    const message = createBaseMember();
    message.user = (object.user !== undefined && object.user !== null) ? User.fromPartial(object.user) : undefined;
    message.membership = (object.membership !== undefined && object.membership !== null)
      ? Membership.fromPartial(object.membership)
      : undefined;
    return message;
  },
};

function createBaseGetMembersRequest(): GetMembersRequest {
  return { groupId: "", username: undefined, groupModeration: undefined, page: undefined };
}

export const GetMembersRequest = {
  encode(message: GetMembersRequest, writer: _m0.Writer = _m0.Writer.create()): _m0.Writer {
    if (message.groupId !== "") {
      writer.uint32(10).string(message.groupId);
    }
    if (message.username !== undefined) {
      writer.uint32(18).string(message.username);
    }
    if (message.groupModeration !== undefined) {
      writer.uint32(24).int32(message.groupModeration);
    }
    if (message.page !== undefined) {
      writer.uint32(80).int32(message.page);
    }
    return writer;
  },

  decode(input: _m0.Reader | Uint8Array, length?: number): GetMembersRequest {
    const reader = input instanceof _m0.Reader ? input : new _m0.Reader(input);
    let end = length === undefined ? reader.len : reader.pos + length;
    const message = createBaseGetMembersRequest();
    while (reader.pos < end) {
      const tag = reader.uint32();
      switch (tag >>> 3) {
        case 1:
          message.groupId = reader.string();
          break;
        case 2:
          message.username = reader.string();
          break;
        case 3:
          message.groupModeration = reader.int32() as any;
          break;
        case 10:
          message.page = reader.int32();
          break;
        default:
          reader.skipType(tag & 7);
          break;
      }
    }
    return message;
  },

  fromJSON(object: any): GetMembersRequest {
    return {
      groupId: isSet(object.groupId) ? String(object.groupId) : "",
      username: isSet(object.username) ? String(object.username) : undefined,
      groupModeration: isSet(object.groupModeration) ? moderationFromJSON(object.groupModeration) : undefined,
      page: isSet(object.page) ? Number(object.page) : undefined,
    };
  },

  toJSON(message: GetMembersRequest): unknown {
    const obj: any = {};
    message.groupId !== undefined && (obj.groupId = message.groupId);
    message.username !== undefined && (obj.username = message.username);
    message.groupModeration !== undefined && (obj.groupModeration = message.groupModeration !== undefined
      ? moderationToJSON(message.groupModeration)
      : undefined);
    message.page !== undefined && (obj.page = Math.round(message.page));
    return obj;
  },

  create<I extends Exact<DeepPartial<GetMembersRequest>, I>>(base?: I): GetMembersRequest {
    return GetMembersRequest.fromPartial(base ?? {});
  },

  fromPartial<I extends Exact<DeepPartial<GetMembersRequest>, I>>(object: I): GetMembersRequest {
    const message = createBaseGetMembersRequest();
    message.groupId = object.groupId ?? "";
    message.username = object.username ?? undefined;
    message.groupModeration = object.groupModeration ?? undefined;
    message.page = object.page ?? undefined;
    return message;
  },
};

function createBaseGetMembersResponse(): GetMembersResponse {
  return { members: [], hasNextPage: false };
}

export const GetMembersResponse = {
  encode(message: GetMembersResponse, writer: _m0.Writer = _m0.Writer.create()): _m0.Writer {
    for (const v of message.members) {
      Member.encode(v!, writer.uint32(10).fork()).ldelim();
    }
    if (message.hasNextPage === true) {
      writer.uint32(16).bool(message.hasNextPage);
    }
    return writer;
  },

  decode(input: _m0.Reader | Uint8Array, length?: number): GetMembersResponse {
    const reader = input instanceof _m0.Reader ? input : new _m0.Reader(input);
    let end = length === undefined ? reader.len : reader.pos + length;
    const message = createBaseGetMembersResponse();
    while (reader.pos < end) {
      const tag = reader.uint32();
      switch (tag >>> 3) {
        case 1:
          message.members.push(Member.decode(reader, reader.uint32()));
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

  fromJSON(object: any): GetMembersResponse {
    return {
      members: Array.isArray(object?.members) ? object.members.map((e: any) => Member.fromJSON(e)) : [],
      hasNextPage: isSet(object.hasNextPage) ? Boolean(object.hasNextPage) : false,
    };
  },

  toJSON(message: GetMembersResponse): unknown {
    const obj: any = {};
    if (message.members) {
      obj.members = message.members.map((e) => e ? Member.toJSON(e) : undefined);
    } else {
      obj.members = [];
    }
    message.hasNextPage !== undefined && (obj.hasNextPage = message.hasNextPage);
    return obj;
  },

  create<I extends Exact<DeepPartial<GetMembersResponse>, I>>(base?: I): GetMembersResponse {
    return GetMembersResponse.fromPartial(base ?? {});
  },

  fromPartial<I extends Exact<DeepPartial<GetMembersResponse>, I>>(object: I): GetMembersResponse {
    const message = createBaseGetMembersResponse();
    message.members = object.members?.map((e) => Member.fromPartial(e)) || [];
    message.hasNextPage = object.hasNextPage ?? false;
    return message;
  },
};

declare var self: any | undefined;
declare var window: any | undefined;
declare var global: any | undefined;
var tsProtoGlobalThis: any = (() => {
  if (typeof globalThis !== "undefined") {
    return globalThis;
  }
  if (typeof self !== "undefined") {
    return self;
  }
  if (typeof window !== "undefined") {
    return window;
  }
  if (typeof global !== "undefined") {
    return global;
  }
  throw "Unable to locate global object";
})();

function bytesFromBase64(b64: string): Uint8Array {
  if (tsProtoGlobalThis.Buffer) {
    return Uint8Array.from(tsProtoGlobalThis.Buffer.from(b64, "base64"));
  } else {
    const bin = tsProtoGlobalThis.atob(b64);
    const arr = new Uint8Array(bin.length);
    for (let i = 0; i < bin.length; ++i) {
      arr[i] = bin.charCodeAt(i);
    }
    return arr;
  }
}

function base64FromBytes(arr: Uint8Array): string {
  if (tsProtoGlobalThis.Buffer) {
    return tsProtoGlobalThis.Buffer.from(arr).toString("base64");
  } else {
    const bin: string[] = [];
    arr.forEach((byte) => {
      bin.push(String.fromCharCode(byte));
    });
    return tsProtoGlobalThis.btoa(bin.join(""));
  }
}

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
