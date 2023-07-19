/* eslint-disable */
import _m0 from "protobufjs/minimal";
import { Timestamp } from "./google/protobuf/timestamp";
import { Permission, permissionFromJSON, permissionToJSON } from "./permissions";
import {
  Moderation,
  moderationFromJSON,
  moderationToJSON,
  Visibility,
  visibilityFromJSON,
  visibilityToJSON,
} from "./visibility_moderation";

export const protobufPackage = "jonline";

export enum UserListingType {
  EVERYONE = 0,
  FOLLOWING = 1,
  FRIENDS = 2,
  FOLLOWERS = 3,
  FOLLOW_REQUESTS = 4,
  UNRECOGNIZED = -1,
}

export function userListingTypeFromJSON(object: any): UserListingType {
  switch (object) {
    case 0:
    case "EVERYONE":
      return UserListingType.EVERYONE;
    case 1:
    case "FOLLOWING":
      return UserListingType.FOLLOWING;
    case 2:
    case "FRIENDS":
      return UserListingType.FRIENDS;
    case 3:
    case "FOLLOWERS":
      return UserListingType.FOLLOWERS;
    case 4:
    case "FOLLOW_REQUESTS":
      return UserListingType.FOLLOW_REQUESTS;
    case -1:
    case "UNRECOGNIZED":
    default:
      return UserListingType.UNRECOGNIZED;
  }
}

export function userListingTypeToJSON(object: UserListingType): string {
  switch (object) {
    case UserListingType.EVERYONE:
      return "EVERYONE";
    case UserListingType.FOLLOWING:
      return "FOLLOWING";
    case UserListingType.FRIENDS:
      return "FRIENDS";
    case UserListingType.FOLLOWERS:
      return "FOLLOWERS";
    case UserListingType.FOLLOW_REQUESTS:
      return "FOLLOW_REQUESTS";
    case UserListingType.UNRECOGNIZED:
    default:
      return "UNRECOGNIZED";
  }
}

export interface User {
  id: string;
  username: string;
  realName: string;
  email?: ContactMethod | undefined;
  phone?: ContactMethod | undefined;
  permissions: Permission[];
  /**
   * Media ID for the user's avatar. Note that its visibility is managed by the User and thus
   * it may not be accessible to the current user.
   */
  avatarMediaId?: string | undefined;
  bio: string;
  /**
   * User visibility is a bit different from Post visibility.
   * LIMITED means the user can only be seen by users they follow
   * (as opposed to Posts' individualized visibilities).
   * PRIVATE visibility means no one can see the user.
   * See server_configuration.proto for details about PRIVATE
   * users' ability to creep.
   */
  visibility: Visibility;
  moderation: Moderation;
  /** Only PENDING or UNMODERATED are valid. */
  defaultFollowModeration: Moderation;
  followerCount?: number | undefined;
  followingCount?: number | undefined;
  groupCount?: number | undefined;
  postCount?: number | undefined;
  responseCount?:
    | number
    | undefined;
  /**
   * Presence indicates the current user is following
   * or has a pending follow request for this user.
   */
  currentUserFollow?:
    | Follow
    | undefined;
  /**
   * Presence indicates this user is following or has
   * a pending follow request for the current user.
   */
  targetCurrentUserFollow?: Follow | undefined;
  currentGroupMembership?: Membership | undefined;
  createdAt: string | undefined;
  updatedAt?: string | undefined;
}

export interface Follow {
  userId: string;
  targetUserId: string;
  targetUserModeration: Moderation;
  createdAt: string | undefined;
  updatedAt?: string | undefined;
}

/**
 * Model for a user's membership in a group. Memberships are generically
 * included as part of User models when relevant in Jonline, but UIs should use the group_id
 * to reconcile memberships with groups.
 */
export interface Membership {
  userId: string;
  groupId: string;
  /**
   * Valid Membership Permissions are:
   * * `VIEW_POSTS`, `CREATE_POSTS`, `MODERATE_POSTS`
   * * `VIEW_EVENTS`, CREATE_EVENTS, `MODERATE_EVENTS`
   * * `ADMIN` and `MODERATE_USERS`
   */
  permissions: Permission[];
  /** Tracks whether group moderators need to approve the membership. */
  groupModeration: Moderation;
  /** Tracks whether the user needs to approve the membership. */
  userModeration: Moderation;
  createdAt: string | undefined;
  updatedAt?: string | undefined;
}

export interface ContactMethod {
  /** `mailto:` or `tel:` URL. */
  value?: string | undefined;
  visibility: Visibility;
  /**
   * Server-side flag indicating whether the server can verify
   * (and otherwise interact via) the contact method.
   */
  supportedByServer: boolean;
  /**
   * Indicates the user has completed verification of the contact method.
   * Verification requires `supported_by_server` to be `true`.
   */
  verified: boolean;
}

export interface GetUsersRequest {
  username?: string | undefined;
  userId?:
    | string
    | undefined;
  /**
   * optional string group_id = 3;
   * optional string email = 2;
   * optional string phone = 3;
   */
  page?: number | undefined;
  listingType: UserListingType;
}

export interface GetUsersResponse {
  users: User[];
  hasNextPage: boolean;
}

function createBaseUser(): User {
  return {
    id: "",
    username: "",
    realName: "",
    email: undefined,
    phone: undefined,
    permissions: [],
    avatarMediaId: undefined,
    bio: "",
    visibility: 0,
    moderation: 0,
    defaultFollowModeration: 0,
    followerCount: undefined,
    followingCount: undefined,
    groupCount: undefined,
    postCount: undefined,
    responseCount: undefined,
    currentUserFollow: undefined,
    targetCurrentUserFollow: undefined,
    currentGroupMembership: undefined,
    createdAt: undefined,
    updatedAt: undefined,
  };
}

export const User = {
  encode(message: User, writer: _m0.Writer = _m0.Writer.create()): _m0.Writer {
    if (message.id !== "") {
      writer.uint32(10).string(message.id);
    }
    if (message.username !== "") {
      writer.uint32(18).string(message.username);
    }
    if (message.realName !== "") {
      writer.uint32(26).string(message.realName);
    }
    if (message.email !== undefined) {
      ContactMethod.encode(message.email, writer.uint32(34).fork()).ldelim();
    }
    if (message.phone !== undefined) {
      ContactMethod.encode(message.phone, writer.uint32(42).fork()).ldelim();
    }
    writer.uint32(50).fork();
    for (const v of message.permissions) {
      writer.int32(v);
    }
    writer.ldelim();
    if (message.avatarMediaId !== undefined) {
      writer.uint32(58).string(message.avatarMediaId);
    }
    if (message.bio !== "") {
      writer.uint32(66).string(message.bio);
    }
    if (message.visibility !== 0) {
      writer.uint32(160).int32(message.visibility);
    }
    if (message.moderation !== 0) {
      writer.uint32(168).int32(message.moderation);
    }
    if (message.defaultFollowModeration !== 0) {
      writer.uint32(240).int32(message.defaultFollowModeration);
    }
    if (message.followerCount !== undefined) {
      writer.uint32(248).int32(message.followerCount);
    }
    if (message.followingCount !== undefined) {
      writer.uint32(256).int32(message.followingCount);
    }
    if (message.groupCount !== undefined) {
      writer.uint32(264).int32(message.groupCount);
    }
    if (message.postCount !== undefined) {
      writer.uint32(272).int32(message.postCount);
    }
    if (message.responseCount !== undefined) {
      writer.uint32(280).int32(message.responseCount);
    }
    if (message.currentUserFollow !== undefined) {
      Follow.encode(message.currentUserFollow, writer.uint32(402).fork()).ldelim();
    }
    if (message.targetCurrentUserFollow !== undefined) {
      Follow.encode(message.targetCurrentUserFollow, writer.uint32(410).fork()).ldelim();
    }
    if (message.currentGroupMembership !== undefined) {
      Membership.encode(message.currentGroupMembership, writer.uint32(418).fork()).ldelim();
    }
    if (message.createdAt !== undefined) {
      Timestamp.encode(toTimestamp(message.createdAt), writer.uint32(802).fork()).ldelim();
    }
    if (message.updatedAt !== undefined) {
      Timestamp.encode(toTimestamp(message.updatedAt), writer.uint32(810).fork()).ldelim();
    }
    return writer;
  },

  decode(input: _m0.Reader | Uint8Array, length?: number): User {
    const reader = input instanceof _m0.Reader ? input : new _m0.Reader(input);
    let end = length === undefined ? reader.len : reader.pos + length;
    const message = createBaseUser();
    while (reader.pos < end) {
      const tag = reader.uint32();
      switch (tag >>> 3) {
        case 1:
          message.id = reader.string();
          break;
        case 2:
          message.username = reader.string();
          break;
        case 3:
          message.realName = reader.string();
          break;
        case 4:
          message.email = ContactMethod.decode(reader, reader.uint32());
          break;
        case 5:
          message.phone = ContactMethod.decode(reader, reader.uint32());
          break;
        case 6:
          if ((tag & 7) === 2) {
            const end2 = reader.uint32() + reader.pos;
            while (reader.pos < end2) {
              message.permissions.push(reader.int32() as any);
            }
          } else {
            message.permissions.push(reader.int32() as any);
          }
          break;
        case 7:
          message.avatarMediaId = reader.string();
          break;
        case 8:
          message.bio = reader.string();
          break;
        case 20:
          message.visibility = reader.int32() as any;
          break;
        case 21:
          message.moderation = reader.int32() as any;
          break;
        case 30:
          message.defaultFollowModeration = reader.int32() as any;
          break;
        case 31:
          message.followerCount = reader.int32();
          break;
        case 32:
          message.followingCount = reader.int32();
          break;
        case 33:
          message.groupCount = reader.int32();
          break;
        case 34:
          message.postCount = reader.int32();
          break;
        case 35:
          message.responseCount = reader.int32();
          break;
        case 50:
          message.currentUserFollow = Follow.decode(reader, reader.uint32());
          break;
        case 51:
          message.targetCurrentUserFollow = Follow.decode(reader, reader.uint32());
          break;
        case 52:
          message.currentGroupMembership = Membership.decode(reader, reader.uint32());
          break;
        case 100:
          message.createdAt = fromTimestamp(Timestamp.decode(reader, reader.uint32()));
          break;
        case 101:
          message.updatedAt = fromTimestamp(Timestamp.decode(reader, reader.uint32()));
          break;
        default:
          reader.skipType(tag & 7);
          break;
      }
    }
    return message;
  },

  fromJSON(object: any): User {
    return {
      id: isSet(object.id) ? String(object.id) : "",
      username: isSet(object.username) ? String(object.username) : "",
      realName: isSet(object.realName) ? String(object.realName) : "",
      email: isSet(object.email) ? ContactMethod.fromJSON(object.email) : undefined,
      phone: isSet(object.phone) ? ContactMethod.fromJSON(object.phone) : undefined,
      permissions: Array.isArray(object?.permissions) ? object.permissions.map((e: any) => permissionFromJSON(e)) : [],
      avatarMediaId: isSet(object.avatarMediaId) ? String(object.avatarMediaId) : undefined,
      bio: isSet(object.bio) ? String(object.bio) : "",
      visibility: isSet(object.visibility) ? visibilityFromJSON(object.visibility) : 0,
      moderation: isSet(object.moderation) ? moderationFromJSON(object.moderation) : 0,
      defaultFollowModeration: isSet(object.defaultFollowModeration)
        ? moderationFromJSON(object.defaultFollowModeration)
        : 0,
      followerCount: isSet(object.followerCount) ? Number(object.followerCount) : undefined,
      followingCount: isSet(object.followingCount) ? Number(object.followingCount) : undefined,
      groupCount: isSet(object.groupCount) ? Number(object.groupCount) : undefined,
      postCount: isSet(object.postCount) ? Number(object.postCount) : undefined,
      responseCount: isSet(object.responseCount) ? Number(object.responseCount) : undefined,
      currentUserFollow: isSet(object.currentUserFollow) ? Follow.fromJSON(object.currentUserFollow) : undefined,
      targetCurrentUserFollow: isSet(object.targetCurrentUserFollow)
        ? Follow.fromJSON(object.targetCurrentUserFollow)
        : undefined,
      currentGroupMembership: isSet(object.currentGroupMembership)
        ? Membership.fromJSON(object.currentGroupMembership)
        : undefined,
      createdAt: isSet(object.createdAt) ? String(object.createdAt) : undefined,
      updatedAt: isSet(object.updatedAt) ? String(object.updatedAt) : undefined,
    };
  },

  toJSON(message: User): unknown {
    const obj: any = {};
    message.id !== undefined && (obj.id = message.id);
    message.username !== undefined && (obj.username = message.username);
    message.realName !== undefined && (obj.realName = message.realName);
    message.email !== undefined && (obj.email = message.email ? ContactMethod.toJSON(message.email) : undefined);
    message.phone !== undefined && (obj.phone = message.phone ? ContactMethod.toJSON(message.phone) : undefined);
    if (message.permissions) {
      obj.permissions = message.permissions.map((e) => permissionToJSON(e));
    } else {
      obj.permissions = [];
    }
    message.avatarMediaId !== undefined && (obj.avatarMediaId = message.avatarMediaId);
    message.bio !== undefined && (obj.bio = message.bio);
    message.visibility !== undefined && (obj.visibility = visibilityToJSON(message.visibility));
    message.moderation !== undefined && (obj.moderation = moderationToJSON(message.moderation));
    message.defaultFollowModeration !== undefined &&
      (obj.defaultFollowModeration = moderationToJSON(message.defaultFollowModeration));
    message.followerCount !== undefined && (obj.followerCount = Math.round(message.followerCount));
    message.followingCount !== undefined && (obj.followingCount = Math.round(message.followingCount));
    message.groupCount !== undefined && (obj.groupCount = Math.round(message.groupCount));
    message.postCount !== undefined && (obj.postCount = Math.round(message.postCount));
    message.responseCount !== undefined && (obj.responseCount = Math.round(message.responseCount));
    message.currentUserFollow !== undefined &&
      (obj.currentUserFollow = message.currentUserFollow ? Follow.toJSON(message.currentUserFollow) : undefined);
    message.targetCurrentUserFollow !== undefined && (obj.targetCurrentUserFollow = message.targetCurrentUserFollow
      ? Follow.toJSON(message.targetCurrentUserFollow)
      : undefined);
    message.currentGroupMembership !== undefined && (obj.currentGroupMembership = message.currentGroupMembership
      ? Membership.toJSON(message.currentGroupMembership)
      : undefined);
    message.createdAt !== undefined && (obj.createdAt = message.createdAt);
    message.updatedAt !== undefined && (obj.updatedAt = message.updatedAt);
    return obj;
  },

  create<I extends Exact<DeepPartial<User>, I>>(base?: I): User {
    return User.fromPartial(base ?? {});
  },

  fromPartial<I extends Exact<DeepPartial<User>, I>>(object: I): User {
    const message = createBaseUser();
    message.id = object.id ?? "";
    message.username = object.username ?? "";
    message.realName = object.realName ?? "";
    message.email = (object.email !== undefined && object.email !== null)
      ? ContactMethod.fromPartial(object.email)
      : undefined;
    message.phone = (object.phone !== undefined && object.phone !== null)
      ? ContactMethod.fromPartial(object.phone)
      : undefined;
    message.permissions = object.permissions?.map((e) => e) || [];
    message.avatarMediaId = object.avatarMediaId ?? undefined;
    message.bio = object.bio ?? "";
    message.visibility = object.visibility ?? 0;
    message.moderation = object.moderation ?? 0;
    message.defaultFollowModeration = object.defaultFollowModeration ?? 0;
    message.followerCount = object.followerCount ?? undefined;
    message.followingCount = object.followingCount ?? undefined;
    message.groupCount = object.groupCount ?? undefined;
    message.postCount = object.postCount ?? undefined;
    message.responseCount = object.responseCount ?? undefined;
    message.currentUserFollow = (object.currentUserFollow !== undefined && object.currentUserFollow !== null)
      ? Follow.fromPartial(object.currentUserFollow)
      : undefined;
    message.targetCurrentUserFollow =
      (object.targetCurrentUserFollow !== undefined && object.targetCurrentUserFollow !== null)
        ? Follow.fromPartial(object.targetCurrentUserFollow)
        : undefined;
    message.currentGroupMembership =
      (object.currentGroupMembership !== undefined && object.currentGroupMembership !== null)
        ? Membership.fromPartial(object.currentGroupMembership)
        : undefined;
    message.createdAt = object.createdAt ?? undefined;
    message.updatedAt = object.updatedAt ?? undefined;
    return message;
  },
};

function createBaseFollow(): Follow {
  return { userId: "", targetUserId: "", targetUserModeration: 0, createdAt: undefined, updatedAt: undefined };
}

export const Follow = {
  encode(message: Follow, writer: _m0.Writer = _m0.Writer.create()): _m0.Writer {
    if (message.userId !== "") {
      writer.uint32(10).string(message.userId);
    }
    if (message.targetUserId !== "") {
      writer.uint32(18).string(message.targetUserId);
    }
    if (message.targetUserModeration !== 0) {
      writer.uint32(24).int32(message.targetUserModeration);
    }
    if (message.createdAt !== undefined) {
      Timestamp.encode(toTimestamp(message.createdAt), writer.uint32(34).fork()).ldelim();
    }
    if (message.updatedAt !== undefined) {
      Timestamp.encode(toTimestamp(message.updatedAt), writer.uint32(42).fork()).ldelim();
    }
    return writer;
  },

  decode(input: _m0.Reader | Uint8Array, length?: number): Follow {
    const reader = input instanceof _m0.Reader ? input : new _m0.Reader(input);
    let end = length === undefined ? reader.len : reader.pos + length;
    const message = createBaseFollow();
    while (reader.pos < end) {
      const tag = reader.uint32();
      switch (tag >>> 3) {
        case 1:
          message.userId = reader.string();
          break;
        case 2:
          message.targetUserId = reader.string();
          break;
        case 3:
          message.targetUserModeration = reader.int32() as any;
          break;
        case 4:
          message.createdAt = fromTimestamp(Timestamp.decode(reader, reader.uint32()));
          break;
        case 5:
          message.updatedAt = fromTimestamp(Timestamp.decode(reader, reader.uint32()));
          break;
        default:
          reader.skipType(tag & 7);
          break;
      }
    }
    return message;
  },

  fromJSON(object: any): Follow {
    return {
      userId: isSet(object.userId) ? String(object.userId) : "",
      targetUserId: isSet(object.targetUserId) ? String(object.targetUserId) : "",
      targetUserModeration: isSet(object.targetUserModeration) ? moderationFromJSON(object.targetUserModeration) : 0,
      createdAt: isSet(object.createdAt) ? String(object.createdAt) : undefined,
      updatedAt: isSet(object.updatedAt) ? String(object.updatedAt) : undefined,
    };
  },

  toJSON(message: Follow): unknown {
    const obj: any = {};
    message.userId !== undefined && (obj.userId = message.userId);
    message.targetUserId !== undefined && (obj.targetUserId = message.targetUserId);
    message.targetUserModeration !== undefined &&
      (obj.targetUserModeration = moderationToJSON(message.targetUserModeration));
    message.createdAt !== undefined && (obj.createdAt = message.createdAt);
    message.updatedAt !== undefined && (obj.updatedAt = message.updatedAt);
    return obj;
  },

  create<I extends Exact<DeepPartial<Follow>, I>>(base?: I): Follow {
    return Follow.fromPartial(base ?? {});
  },

  fromPartial<I extends Exact<DeepPartial<Follow>, I>>(object: I): Follow {
    const message = createBaseFollow();
    message.userId = object.userId ?? "";
    message.targetUserId = object.targetUserId ?? "";
    message.targetUserModeration = object.targetUserModeration ?? 0;
    message.createdAt = object.createdAt ?? undefined;
    message.updatedAt = object.updatedAt ?? undefined;
    return message;
  },
};

function createBaseMembership(): Membership {
  return {
    userId: "",
    groupId: "",
    permissions: [],
    groupModeration: 0,
    userModeration: 0,
    createdAt: undefined,
    updatedAt: undefined,
  };
}

export const Membership = {
  encode(message: Membership, writer: _m0.Writer = _m0.Writer.create()): _m0.Writer {
    if (message.userId !== "") {
      writer.uint32(10).string(message.userId);
    }
    if (message.groupId !== "") {
      writer.uint32(18).string(message.groupId);
    }
    writer.uint32(26).fork();
    for (const v of message.permissions) {
      writer.int32(v);
    }
    writer.ldelim();
    if (message.groupModeration !== 0) {
      writer.uint32(32).int32(message.groupModeration);
    }
    if (message.userModeration !== 0) {
      writer.uint32(40).int32(message.userModeration);
    }
    if (message.createdAt !== undefined) {
      Timestamp.encode(toTimestamp(message.createdAt), writer.uint32(50).fork()).ldelim();
    }
    if (message.updatedAt !== undefined) {
      Timestamp.encode(toTimestamp(message.updatedAt), writer.uint32(58).fork()).ldelim();
    }
    return writer;
  },

  decode(input: _m0.Reader | Uint8Array, length?: number): Membership {
    const reader = input instanceof _m0.Reader ? input : new _m0.Reader(input);
    let end = length === undefined ? reader.len : reader.pos + length;
    const message = createBaseMembership();
    while (reader.pos < end) {
      const tag = reader.uint32();
      switch (tag >>> 3) {
        case 1:
          message.userId = reader.string();
          break;
        case 2:
          message.groupId = reader.string();
          break;
        case 3:
          if ((tag & 7) === 2) {
            const end2 = reader.uint32() + reader.pos;
            while (reader.pos < end2) {
              message.permissions.push(reader.int32() as any);
            }
          } else {
            message.permissions.push(reader.int32() as any);
          }
          break;
        case 4:
          message.groupModeration = reader.int32() as any;
          break;
        case 5:
          message.userModeration = reader.int32() as any;
          break;
        case 6:
          message.createdAt = fromTimestamp(Timestamp.decode(reader, reader.uint32()));
          break;
        case 7:
          message.updatedAt = fromTimestamp(Timestamp.decode(reader, reader.uint32()));
          break;
        default:
          reader.skipType(tag & 7);
          break;
      }
    }
    return message;
  },

  fromJSON(object: any): Membership {
    return {
      userId: isSet(object.userId) ? String(object.userId) : "",
      groupId: isSet(object.groupId) ? String(object.groupId) : "",
      permissions: Array.isArray(object?.permissions) ? object.permissions.map((e: any) => permissionFromJSON(e)) : [],
      groupModeration: isSet(object.groupModeration) ? moderationFromJSON(object.groupModeration) : 0,
      userModeration: isSet(object.userModeration) ? moderationFromJSON(object.userModeration) : 0,
      createdAt: isSet(object.createdAt) ? String(object.createdAt) : undefined,
      updatedAt: isSet(object.updatedAt) ? String(object.updatedAt) : undefined,
    };
  },

  toJSON(message: Membership): unknown {
    const obj: any = {};
    message.userId !== undefined && (obj.userId = message.userId);
    message.groupId !== undefined && (obj.groupId = message.groupId);
    if (message.permissions) {
      obj.permissions = message.permissions.map((e) => permissionToJSON(e));
    } else {
      obj.permissions = [];
    }
    message.groupModeration !== undefined && (obj.groupModeration = moderationToJSON(message.groupModeration));
    message.userModeration !== undefined && (obj.userModeration = moderationToJSON(message.userModeration));
    message.createdAt !== undefined && (obj.createdAt = message.createdAt);
    message.updatedAt !== undefined && (obj.updatedAt = message.updatedAt);
    return obj;
  },

  create<I extends Exact<DeepPartial<Membership>, I>>(base?: I): Membership {
    return Membership.fromPartial(base ?? {});
  },

  fromPartial<I extends Exact<DeepPartial<Membership>, I>>(object: I): Membership {
    const message = createBaseMembership();
    message.userId = object.userId ?? "";
    message.groupId = object.groupId ?? "";
    message.permissions = object.permissions?.map((e) => e) || [];
    message.groupModeration = object.groupModeration ?? 0;
    message.userModeration = object.userModeration ?? 0;
    message.createdAt = object.createdAt ?? undefined;
    message.updatedAt = object.updatedAt ?? undefined;
    return message;
  },
};

function createBaseContactMethod(): ContactMethod {
  return { value: undefined, visibility: 0, supportedByServer: false, verified: false };
}

export const ContactMethod = {
  encode(message: ContactMethod, writer: _m0.Writer = _m0.Writer.create()): _m0.Writer {
    if (message.value !== undefined) {
      writer.uint32(10).string(message.value);
    }
    if (message.visibility !== 0) {
      writer.uint32(16).int32(message.visibility);
    }
    if (message.supportedByServer === true) {
      writer.uint32(24).bool(message.supportedByServer);
    }
    if (message.verified === true) {
      writer.uint32(32).bool(message.verified);
    }
    return writer;
  },

  decode(input: _m0.Reader | Uint8Array, length?: number): ContactMethod {
    const reader = input instanceof _m0.Reader ? input : new _m0.Reader(input);
    let end = length === undefined ? reader.len : reader.pos + length;
    const message = createBaseContactMethod();
    while (reader.pos < end) {
      const tag = reader.uint32();
      switch (tag >>> 3) {
        case 1:
          message.value = reader.string();
          break;
        case 2:
          message.visibility = reader.int32() as any;
          break;
        case 3:
          message.supportedByServer = reader.bool();
          break;
        case 4:
          message.verified = reader.bool();
          break;
        default:
          reader.skipType(tag & 7);
          break;
      }
    }
    return message;
  },

  fromJSON(object: any): ContactMethod {
    return {
      value: isSet(object.value) ? String(object.value) : undefined,
      visibility: isSet(object.visibility) ? visibilityFromJSON(object.visibility) : 0,
      supportedByServer: isSet(object.supportedByServer) ? Boolean(object.supportedByServer) : false,
      verified: isSet(object.verified) ? Boolean(object.verified) : false,
    };
  },

  toJSON(message: ContactMethod): unknown {
    const obj: any = {};
    message.value !== undefined && (obj.value = message.value);
    message.visibility !== undefined && (obj.visibility = visibilityToJSON(message.visibility));
    message.supportedByServer !== undefined && (obj.supportedByServer = message.supportedByServer);
    message.verified !== undefined && (obj.verified = message.verified);
    return obj;
  },

  create<I extends Exact<DeepPartial<ContactMethod>, I>>(base?: I): ContactMethod {
    return ContactMethod.fromPartial(base ?? {});
  },

  fromPartial<I extends Exact<DeepPartial<ContactMethod>, I>>(object: I): ContactMethod {
    const message = createBaseContactMethod();
    message.value = object.value ?? undefined;
    message.visibility = object.visibility ?? 0;
    message.supportedByServer = object.supportedByServer ?? false;
    message.verified = object.verified ?? false;
    return message;
  },
};

function createBaseGetUsersRequest(): GetUsersRequest {
  return { username: undefined, userId: undefined, page: undefined, listingType: 0 };
}

export const GetUsersRequest = {
  encode(message: GetUsersRequest, writer: _m0.Writer = _m0.Writer.create()): _m0.Writer {
    if (message.username !== undefined) {
      writer.uint32(10).string(message.username);
    }
    if (message.userId !== undefined) {
      writer.uint32(18).string(message.userId);
    }
    if (message.page !== undefined) {
      writer.uint32(792).int32(message.page);
    }
    if (message.listingType !== 0) {
      writer.uint32(800).int32(message.listingType);
    }
    return writer;
  },

  decode(input: _m0.Reader | Uint8Array, length?: number): GetUsersRequest {
    const reader = input instanceof _m0.Reader ? input : new _m0.Reader(input);
    let end = length === undefined ? reader.len : reader.pos + length;
    const message = createBaseGetUsersRequest();
    while (reader.pos < end) {
      const tag = reader.uint32();
      switch (tag >>> 3) {
        case 1:
          message.username = reader.string();
          break;
        case 2:
          message.userId = reader.string();
          break;
        case 99:
          message.page = reader.int32();
          break;
        case 100:
          message.listingType = reader.int32() as any;
          break;
        default:
          reader.skipType(tag & 7);
          break;
      }
    }
    return message;
  },

  fromJSON(object: any): GetUsersRequest {
    return {
      username: isSet(object.username) ? String(object.username) : undefined,
      userId: isSet(object.userId) ? String(object.userId) : undefined,
      page: isSet(object.page) ? Number(object.page) : undefined,
      listingType: isSet(object.listingType) ? userListingTypeFromJSON(object.listingType) : 0,
    };
  },

  toJSON(message: GetUsersRequest): unknown {
    const obj: any = {};
    message.username !== undefined && (obj.username = message.username);
    message.userId !== undefined && (obj.userId = message.userId);
    message.page !== undefined && (obj.page = Math.round(message.page));
    message.listingType !== undefined && (obj.listingType = userListingTypeToJSON(message.listingType));
    return obj;
  },

  create<I extends Exact<DeepPartial<GetUsersRequest>, I>>(base?: I): GetUsersRequest {
    return GetUsersRequest.fromPartial(base ?? {});
  },

  fromPartial<I extends Exact<DeepPartial<GetUsersRequest>, I>>(object: I): GetUsersRequest {
    const message = createBaseGetUsersRequest();
    message.username = object.username ?? undefined;
    message.userId = object.userId ?? undefined;
    message.page = object.page ?? undefined;
    message.listingType = object.listingType ?? 0;
    return message;
  },
};

function createBaseGetUsersResponse(): GetUsersResponse {
  return { users: [], hasNextPage: false };
}

export const GetUsersResponse = {
  encode(message: GetUsersResponse, writer: _m0.Writer = _m0.Writer.create()): _m0.Writer {
    for (const v of message.users) {
      User.encode(v!, writer.uint32(10).fork()).ldelim();
    }
    if (message.hasNextPage === true) {
      writer.uint32(16).bool(message.hasNextPage);
    }
    return writer;
  },

  decode(input: _m0.Reader | Uint8Array, length?: number): GetUsersResponse {
    const reader = input instanceof _m0.Reader ? input : new _m0.Reader(input);
    let end = length === undefined ? reader.len : reader.pos + length;
    const message = createBaseGetUsersResponse();
    while (reader.pos < end) {
      const tag = reader.uint32();
      switch (tag >>> 3) {
        case 1:
          message.users.push(User.decode(reader, reader.uint32()));
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

  fromJSON(object: any): GetUsersResponse {
    return {
      users: Array.isArray(object?.users) ? object.users.map((e: any) => User.fromJSON(e)) : [],
      hasNextPage: isSet(object.hasNextPage) ? Boolean(object.hasNextPage) : false,
    };
  },

  toJSON(message: GetUsersResponse): unknown {
    const obj: any = {};
    if (message.users) {
      obj.users = message.users.map((e) => e ? User.toJSON(e) : undefined);
    } else {
      obj.users = [];
    }
    message.hasNextPage !== undefined && (obj.hasNextPage = message.hasNextPage);
    return obj;
  },

  create<I extends Exact<DeepPartial<GetUsersResponse>, I>>(base?: I): GetUsersResponse {
    return GetUsersResponse.fromPartial(base ?? {});
  },

  fromPartial<I extends Exact<DeepPartial<GetUsersResponse>, I>>(object: I): GetUsersResponse {
    const message = createBaseGetUsersResponse();
    message.users = object.users?.map((e) => User.fromPartial(e)) || [];
    message.hasNextPage = object.hasNextPage ?? false;
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
