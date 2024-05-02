/* eslint-disable */
import _m0 from "protobufjs/minimal";
import { Timestamp } from "./google/protobuf/timestamp";
import { MediaReference } from "./media";
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

/** The type of group listing to get. */
export enum GroupListingType {
  /** ALL_GROUPS - Get all groups (visible to the current user). */
  ALL_GROUPS = 0,
  /** MY_GROUPS - Get groups the current user is a member of. */
  MY_GROUPS = 1,
  /** REQUESTED_GROUPS - Get groups the current user has requested to join. */
  REQUESTED_GROUPS = 2,
  /** INVITED_GROUPS - Get groups the current user has been invited to. */
  INVITED_GROUPS = 3,
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
    case "REQUESTED_GROUPS":
      return GroupListingType.REQUESTED_GROUPS;
    case 3:
    case "INVITED_GROUPS":
      return GroupListingType.INVITED_GROUPS;
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
    case GroupListingType.REQUESTED_GROUPS:
      return "REQUESTED_GROUPS";
    case GroupListingType.INVITED_GROUPS:
      return "INVITED_GROUPS";
    case GroupListingType.UNRECOGNIZED:
    default:
      return "UNRECOGNIZED";
  }
}

/** `Group`s are a way to organize users and posts (and thus events). They can be used for many purposes, */
export interface Group {
  /** The group's unique ID. */
  id: string;
  /** Mutable name of the group. Must be unique, such that the derived `shortname` is also unique. */
  name: string;
  /** Immutable shortname of the group. Derived from changes to `name` when the `Group` is updated. */
  shortname: string;
  /** A description of the group. */
  description: string;
  /** An avatar for the group. */
  avatar?:
    | MediaReference
    | undefined;
  /** The default permissions for new members of the group. */
  defaultMembershipPermissions: Permission[];
  /**
   * The default moderation for new members of the group.
   * Valid values are PENDING (requires a moderator to let you join) and UNMODERATED.
   */
  defaultMembershipModeration: Moderation;
  /** The default moderation for new posts in the group. */
  defaultPostModeration: Moderation;
  /** The default moderation for new events in the group. */
  defaultEventModeration: Moderation;
  /**
   * LIMITED visibility groups are only visible to members. PRIVATE groups are only
   * visibile to users with the ADMIN group permission.
   */
  visibility: Visibility;
  /** The number of members in the group. */
  memberCount: number;
  /** The number of posts in the group. */
  postCount: number;
  /** The number of events in the group. */
  eventCount: number;
  /** The permissions given to non-members of the group. */
  nonMemberPermissions: Permission[];
  /** The membership for the current user, if any. */
  currentUserMembership?:
    | Membership
    | undefined;
  /** The time the group was created. */
  createdAt:
    | string
    | undefined;
  /** The time the group was last updated. */
  updatedAt?: string | undefined;
}

/** Request to get a group or groups by name or ID. */
export interface GetGroupsRequest {
  /** The ID of the group to get. */
  groupId?:
    | string
    | undefined;
  /** The name of the group to get. */
  groupName?:
    | string
    | undefined;
  /**
   * The shortname of the group to get.
   * Group shortname search is case-insensitive.
   */
  groupShortname?:
    | string
    | undefined;
  /** The group listing type. */
  listingType: GroupListingType;
  /** The page of results to get. */
  page?: number | undefined;
}

/** Response to a GetGroupsRequest. */
export interface GetGroupsResponse {
  /** The groups that matched the request. */
  groups: Group[];
  /** Whether there are more groups to get. */
  hasNextPage: boolean;
}

/** Used when fetching group members using the `GetMembers` RPC. */
export interface Member {
  /** The user. */
  user:
    | User
    | undefined;
  /** The user's membership (or join request, or invitation, or both) in the group. */
  membership: Membership | undefined;
}

/** Request to get members of a group. */
export interface GetMembersRequest {
  /** The ID of the group to get members of. */
  groupId: string;
  /** The username of the members to search for. */
  username?:
    | string
    | undefined;
  /**
   * The membership status to filter members by.
   * If not specified, all members are returned.
   */
  groupModeration?:
    | Moderation
    | undefined;
  /** The page of results to get. */
  page?: number | undefined;
}

/** Response to a GetMembersRequest. */
export interface GetMembersResponse {
  /** The members that matched the request. */
  members: Member[];
  /** Whether there are more members to get. */
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
    eventCount: 0,
    nonMemberPermissions: [],
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
      MediaReference.encode(message.avatar, writer.uint32(42).fork()).ldelim();
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
    if (message.eventCount !== 0) {
      writer.uint32(104).uint32(message.eventCount);
    }
    writer.uint32(146).fork();
    for (const v of message.nonMemberPermissions) {
      writer.int32(v);
    }
    writer.ldelim();
    if (message.currentUserMembership !== undefined) {
      Membership.encode(message.currentUserMembership, writer.uint32(154).fork()).ldelim();
    }
    if (message.createdAt !== undefined) {
      Timestamp.encode(toTimestamp(message.createdAt), writer.uint32(162).fork()).ldelim();
    }
    if (message.updatedAt !== undefined) {
      Timestamp.encode(toTimestamp(message.updatedAt), writer.uint32(170).fork()).ldelim();
    }
    return writer;
  },

  decode(input: _m0.Reader | Uint8Array, length?: number): Group {
    const reader = input instanceof _m0.Reader ? input : _m0.Reader.create(input);
    let end = length === undefined ? reader.len : reader.pos + length;
    const message = createBaseGroup();
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

          message.name = reader.string();
          continue;
        case 3:
          if (tag !== 26) {
            break;
          }

          message.shortname = reader.string();
          continue;
        case 4:
          if (tag !== 34) {
            break;
          }

          message.description = reader.string();
          continue;
        case 5:
          if (tag !== 42) {
            break;
          }

          message.avatar = MediaReference.decode(reader, reader.uint32());
          continue;
        case 6:
          if (tag === 48) {
            message.defaultMembershipPermissions.push(reader.int32() as any);

            continue;
          }

          if (tag === 50) {
            const end2 = reader.uint32() + reader.pos;
            while (reader.pos < end2) {
              message.defaultMembershipPermissions.push(reader.int32() as any);
            }

            continue;
          }

          break;
        case 7:
          if (tag !== 56) {
            break;
          }

          message.defaultMembershipModeration = reader.int32() as any;
          continue;
        case 8:
          if (tag !== 64) {
            break;
          }

          message.defaultPostModeration = reader.int32() as any;
          continue;
        case 9:
          if (tag !== 72) {
            break;
          }

          message.defaultEventModeration = reader.int32() as any;
          continue;
        case 10:
          if (tag !== 80) {
            break;
          }

          message.visibility = reader.int32() as any;
          continue;
        case 11:
          if (tag !== 88) {
            break;
          }

          message.memberCount = reader.uint32();
          continue;
        case 12:
          if (tag !== 96) {
            break;
          }

          message.postCount = reader.uint32();
          continue;
        case 13:
          if (tag !== 104) {
            break;
          }

          message.eventCount = reader.uint32();
          continue;
        case 18:
          if (tag === 144) {
            message.nonMemberPermissions.push(reader.int32() as any);

            continue;
          }

          if (tag === 146) {
            const end2 = reader.uint32() + reader.pos;
            while (reader.pos < end2) {
              message.nonMemberPermissions.push(reader.int32() as any);
            }

            continue;
          }

          break;
        case 19:
          if (tag !== 154) {
            break;
          }

          message.currentUserMembership = Membership.decode(reader, reader.uint32());
          continue;
        case 20:
          if (tag !== 162) {
            break;
          }

          message.createdAt = fromTimestamp(Timestamp.decode(reader, reader.uint32()));
          continue;
        case 21:
          if (tag !== 170) {
            break;
          }

          message.updatedAt = fromTimestamp(Timestamp.decode(reader, reader.uint32()));
          continue;
      }
      if ((tag & 7) === 4 || tag === 0) {
        break;
      }
      reader.skipType(tag & 7);
    }
    return message;
  },

  fromJSON(object: any): Group {
    return {
      id: isSet(object.id) ? globalThis.String(object.id) : "",
      name: isSet(object.name) ? globalThis.String(object.name) : "",
      shortname: isSet(object.shortname) ? globalThis.String(object.shortname) : "",
      description: isSet(object.description) ? globalThis.String(object.description) : "",
      avatar: isSet(object.avatar) ? MediaReference.fromJSON(object.avatar) : undefined,
      defaultMembershipPermissions: globalThis.Array.isArray(object?.defaultMembershipPermissions)
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
      memberCount: isSet(object.memberCount) ? globalThis.Number(object.memberCount) : 0,
      postCount: isSet(object.postCount) ? globalThis.Number(object.postCount) : 0,
      eventCount: isSet(object.eventCount) ? globalThis.Number(object.eventCount) : 0,
      nonMemberPermissions: globalThis.Array.isArray(object?.nonMemberPermissions)
        ? object.nonMemberPermissions.map((e: any) => permissionFromJSON(e))
        : [],
      currentUserMembership: isSet(object.currentUserMembership)
        ? Membership.fromJSON(object.currentUserMembership)
        : undefined,
      createdAt: isSet(object.createdAt) ? globalThis.String(object.createdAt) : undefined,
      updatedAt: isSet(object.updatedAt) ? globalThis.String(object.updatedAt) : undefined,
    };
  },

  toJSON(message: Group): unknown {
    const obj: any = {};
    if (message.id !== "") {
      obj.id = message.id;
    }
    if (message.name !== "") {
      obj.name = message.name;
    }
    if (message.shortname !== "") {
      obj.shortname = message.shortname;
    }
    if (message.description !== "") {
      obj.description = message.description;
    }
    if (message.avatar !== undefined) {
      obj.avatar = MediaReference.toJSON(message.avatar);
    }
    if (message.defaultMembershipPermissions?.length) {
      obj.defaultMembershipPermissions = message.defaultMembershipPermissions.map((e) => permissionToJSON(e));
    }
    if (message.defaultMembershipModeration !== 0) {
      obj.defaultMembershipModeration = moderationToJSON(message.defaultMembershipModeration);
    }
    if (message.defaultPostModeration !== 0) {
      obj.defaultPostModeration = moderationToJSON(message.defaultPostModeration);
    }
    if (message.defaultEventModeration !== 0) {
      obj.defaultEventModeration = moderationToJSON(message.defaultEventModeration);
    }
    if (message.visibility !== 0) {
      obj.visibility = visibilityToJSON(message.visibility);
    }
    if (message.memberCount !== 0) {
      obj.memberCount = Math.round(message.memberCount);
    }
    if (message.postCount !== 0) {
      obj.postCount = Math.round(message.postCount);
    }
    if (message.eventCount !== 0) {
      obj.eventCount = Math.round(message.eventCount);
    }
    if (message.nonMemberPermissions?.length) {
      obj.nonMemberPermissions = message.nonMemberPermissions.map((e) => permissionToJSON(e));
    }
    if (message.currentUserMembership !== undefined) {
      obj.currentUserMembership = Membership.toJSON(message.currentUserMembership);
    }
    if (message.createdAt !== undefined) {
      obj.createdAt = message.createdAt;
    }
    if (message.updatedAt !== undefined) {
      obj.updatedAt = message.updatedAt;
    }
    return obj;
  },

  create<I extends Exact<DeepPartial<Group>, I>>(base?: I): Group {
    return Group.fromPartial(base ?? ({} as any));
  },
  fromPartial<I extends Exact<DeepPartial<Group>, I>>(object: I): Group {
    const message = createBaseGroup();
    message.id = object.id ?? "";
    message.name = object.name ?? "";
    message.shortname = object.shortname ?? "";
    message.description = object.description ?? "";
    message.avatar = (object.avatar !== undefined && object.avatar !== null)
      ? MediaReference.fromPartial(object.avatar)
      : undefined;
    message.defaultMembershipPermissions = object.defaultMembershipPermissions?.map((e) => e) || [];
    message.defaultMembershipModeration = object.defaultMembershipModeration ?? 0;
    message.defaultPostModeration = object.defaultPostModeration ?? 0;
    message.defaultEventModeration = object.defaultEventModeration ?? 0;
    message.visibility = object.visibility ?? 0;
    message.memberCount = object.memberCount ?? 0;
    message.postCount = object.postCount ?? 0;
    message.eventCount = object.eventCount ?? 0;
    message.nonMemberPermissions = object.nonMemberPermissions?.map((e) => e) || [];
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
  return { groupId: undefined, groupName: undefined, groupShortname: undefined, listingType: 0, page: undefined };
}

export const GetGroupsRequest = {
  encode(message: GetGroupsRequest, writer: _m0.Writer = _m0.Writer.create()): _m0.Writer {
    if (message.groupId !== undefined) {
      writer.uint32(10).string(message.groupId);
    }
    if (message.groupName !== undefined) {
      writer.uint32(18).string(message.groupName);
    }
    if (message.groupShortname !== undefined) {
      writer.uint32(26).string(message.groupShortname);
    }
    if (message.listingType !== 0) {
      writer.uint32(80).int32(message.listingType);
    }
    if (message.page !== undefined) {
      writer.uint32(88).int32(message.page);
    }
    return writer;
  },

  decode(input: _m0.Reader | Uint8Array, length?: number): GetGroupsRequest {
    const reader = input instanceof _m0.Reader ? input : _m0.Reader.create(input);
    let end = length === undefined ? reader.len : reader.pos + length;
    const message = createBaseGetGroupsRequest();
    while (reader.pos < end) {
      const tag = reader.uint32();
      switch (tag >>> 3) {
        case 1:
          if (tag !== 10) {
            break;
          }

          message.groupId = reader.string();
          continue;
        case 2:
          if (tag !== 18) {
            break;
          }

          message.groupName = reader.string();
          continue;
        case 3:
          if (tag !== 26) {
            break;
          }

          message.groupShortname = reader.string();
          continue;
        case 10:
          if (tag !== 80) {
            break;
          }

          message.listingType = reader.int32() as any;
          continue;
        case 11:
          if (tag !== 88) {
            break;
          }

          message.page = reader.int32();
          continue;
      }
      if ((tag & 7) === 4 || tag === 0) {
        break;
      }
      reader.skipType(tag & 7);
    }
    return message;
  },

  fromJSON(object: any): GetGroupsRequest {
    return {
      groupId: isSet(object.groupId) ? globalThis.String(object.groupId) : undefined,
      groupName: isSet(object.groupName) ? globalThis.String(object.groupName) : undefined,
      groupShortname: isSet(object.groupShortname) ? globalThis.String(object.groupShortname) : undefined,
      listingType: isSet(object.listingType) ? groupListingTypeFromJSON(object.listingType) : 0,
      page: isSet(object.page) ? globalThis.Number(object.page) : undefined,
    };
  },

  toJSON(message: GetGroupsRequest): unknown {
    const obj: any = {};
    if (message.groupId !== undefined) {
      obj.groupId = message.groupId;
    }
    if (message.groupName !== undefined) {
      obj.groupName = message.groupName;
    }
    if (message.groupShortname !== undefined) {
      obj.groupShortname = message.groupShortname;
    }
    if (message.listingType !== 0) {
      obj.listingType = groupListingTypeToJSON(message.listingType);
    }
    if (message.page !== undefined) {
      obj.page = Math.round(message.page);
    }
    return obj;
  },

  create<I extends Exact<DeepPartial<GetGroupsRequest>, I>>(base?: I): GetGroupsRequest {
    return GetGroupsRequest.fromPartial(base ?? ({} as any));
  },
  fromPartial<I extends Exact<DeepPartial<GetGroupsRequest>, I>>(object: I): GetGroupsRequest {
    const message = createBaseGetGroupsRequest();
    message.groupId = object.groupId ?? undefined;
    message.groupName = object.groupName ?? undefined;
    message.groupShortname = object.groupShortname ?? undefined;
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
    if (message.hasNextPage !== false) {
      writer.uint32(16).bool(message.hasNextPage);
    }
    return writer;
  },

  decode(input: _m0.Reader | Uint8Array, length?: number): GetGroupsResponse {
    const reader = input instanceof _m0.Reader ? input : _m0.Reader.create(input);
    let end = length === undefined ? reader.len : reader.pos + length;
    const message = createBaseGetGroupsResponse();
    while (reader.pos < end) {
      const tag = reader.uint32();
      switch (tag >>> 3) {
        case 1:
          if (tag !== 10) {
            break;
          }

          message.groups.push(Group.decode(reader, reader.uint32()));
          continue;
        case 2:
          if (tag !== 16) {
            break;
          }

          message.hasNextPage = reader.bool();
          continue;
      }
      if ((tag & 7) === 4 || tag === 0) {
        break;
      }
      reader.skipType(tag & 7);
    }
    return message;
  },

  fromJSON(object: any): GetGroupsResponse {
    return {
      groups: globalThis.Array.isArray(object?.groups) ? object.groups.map((e: any) => Group.fromJSON(e)) : [],
      hasNextPage: isSet(object.hasNextPage) ? globalThis.Boolean(object.hasNextPage) : false,
    };
  },

  toJSON(message: GetGroupsResponse): unknown {
    const obj: any = {};
    if (message.groups?.length) {
      obj.groups = message.groups.map((e) => Group.toJSON(e));
    }
    if (message.hasNextPage !== false) {
      obj.hasNextPage = message.hasNextPage;
    }
    return obj;
  },

  create<I extends Exact<DeepPartial<GetGroupsResponse>, I>>(base?: I): GetGroupsResponse {
    return GetGroupsResponse.fromPartial(base ?? ({} as any));
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
    const reader = input instanceof _m0.Reader ? input : _m0.Reader.create(input);
    let end = length === undefined ? reader.len : reader.pos + length;
    const message = createBaseMember();
    while (reader.pos < end) {
      const tag = reader.uint32();
      switch (tag >>> 3) {
        case 1:
          if (tag !== 10) {
            break;
          }

          message.user = User.decode(reader, reader.uint32());
          continue;
        case 2:
          if (tag !== 18) {
            break;
          }

          message.membership = Membership.decode(reader, reader.uint32());
          continue;
      }
      if ((tag & 7) === 4 || tag === 0) {
        break;
      }
      reader.skipType(tag & 7);
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
    if (message.user !== undefined) {
      obj.user = User.toJSON(message.user);
    }
    if (message.membership !== undefined) {
      obj.membership = Membership.toJSON(message.membership);
    }
    return obj;
  },

  create<I extends Exact<DeepPartial<Member>, I>>(base?: I): Member {
    return Member.fromPartial(base ?? ({} as any));
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
    const reader = input instanceof _m0.Reader ? input : _m0.Reader.create(input);
    let end = length === undefined ? reader.len : reader.pos + length;
    const message = createBaseGetMembersRequest();
    while (reader.pos < end) {
      const tag = reader.uint32();
      switch (tag >>> 3) {
        case 1:
          if (tag !== 10) {
            break;
          }

          message.groupId = reader.string();
          continue;
        case 2:
          if (tag !== 18) {
            break;
          }

          message.username = reader.string();
          continue;
        case 3:
          if (tag !== 24) {
            break;
          }

          message.groupModeration = reader.int32() as any;
          continue;
        case 10:
          if (tag !== 80) {
            break;
          }

          message.page = reader.int32();
          continue;
      }
      if ((tag & 7) === 4 || tag === 0) {
        break;
      }
      reader.skipType(tag & 7);
    }
    return message;
  },

  fromJSON(object: any): GetMembersRequest {
    return {
      groupId: isSet(object.groupId) ? globalThis.String(object.groupId) : "",
      username: isSet(object.username) ? globalThis.String(object.username) : undefined,
      groupModeration: isSet(object.groupModeration) ? moderationFromJSON(object.groupModeration) : undefined,
      page: isSet(object.page) ? globalThis.Number(object.page) : undefined,
    };
  },

  toJSON(message: GetMembersRequest): unknown {
    const obj: any = {};
    if (message.groupId !== "") {
      obj.groupId = message.groupId;
    }
    if (message.username !== undefined) {
      obj.username = message.username;
    }
    if (message.groupModeration !== undefined) {
      obj.groupModeration = moderationToJSON(message.groupModeration);
    }
    if (message.page !== undefined) {
      obj.page = Math.round(message.page);
    }
    return obj;
  },

  create<I extends Exact<DeepPartial<GetMembersRequest>, I>>(base?: I): GetMembersRequest {
    return GetMembersRequest.fromPartial(base ?? ({} as any));
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
    if (message.hasNextPage !== false) {
      writer.uint32(16).bool(message.hasNextPage);
    }
    return writer;
  },

  decode(input: _m0.Reader | Uint8Array, length?: number): GetMembersResponse {
    const reader = input instanceof _m0.Reader ? input : _m0.Reader.create(input);
    let end = length === undefined ? reader.len : reader.pos + length;
    const message = createBaseGetMembersResponse();
    while (reader.pos < end) {
      const tag = reader.uint32();
      switch (tag >>> 3) {
        case 1:
          if (tag !== 10) {
            break;
          }

          message.members.push(Member.decode(reader, reader.uint32()));
          continue;
        case 2:
          if (tag !== 16) {
            break;
          }

          message.hasNextPage = reader.bool();
          continue;
      }
      if ((tag & 7) === 4 || tag === 0) {
        break;
      }
      reader.skipType(tag & 7);
    }
    return message;
  },

  fromJSON(object: any): GetMembersResponse {
    return {
      members: globalThis.Array.isArray(object?.members) ? object.members.map((e: any) => Member.fromJSON(e)) : [],
      hasNextPage: isSet(object.hasNextPage) ? globalThis.Boolean(object.hasNextPage) : false,
    };
  },

  toJSON(message: GetMembersResponse): unknown {
    const obj: any = {};
    if (message.members?.length) {
      obj.members = message.members.map((e) => Member.toJSON(e));
    }
    if (message.hasNextPage !== false) {
      obj.hasNextPage = message.hasNextPage;
    }
    return obj;
  },

  create<I extends Exact<DeepPartial<GetMembersResponse>, I>>(base?: I): GetMembersResponse {
    return GetMembersResponse.fromPartial(base ?? ({} as any));
  },
  fromPartial<I extends Exact<DeepPartial<GetMembersResponse>, I>>(object: I): GetMembersResponse {
    const message = createBaseGetMembersResponse();
    message.members = object.members?.map((e) => Member.fromPartial(e)) || [];
    message.hasNextPage = object.hasNextPage ?? false;
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

function toTimestamp(dateStr: string): Timestamp {
  const date = new globalThis.Date(dateStr);
  const seconds = Math.trunc(date.getTime() / 1_000);
  const nanos = (date.getTime() % 1_000) * 1_000_000;
  return { seconds, nanos };
}

function fromTimestamp(t: Timestamp): string {
  let millis = (t.seconds || 0) * 1_000;
  millis += (t.nanos || 0) / 1_000_000;
  return new globalThis.Date(millis).toISOString();
}

function isSet(value: any): boolean {
  return value !== null && value !== undefined;
}
