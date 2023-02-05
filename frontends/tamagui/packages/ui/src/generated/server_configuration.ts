/* eslint-disable */
import _m0 from "protobufjs/minimal";
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

export enum AuthenticationFeature {
  AUTHENTICATION_FEATURE_UNKNOWN = 0,
  /** CREATE_ACCOUNT - Users can sign up for an account. */
  CREATE_ACCOUNT = 1,
  /** LOGIN - Users can sign in with an existing account. */
  LOGIN = 2,
  UNRECOGNIZED = -1,
}

export function authenticationFeatureFromJSON(object: any): AuthenticationFeature {
  switch (object) {
    case 0:
    case "AUTHENTICATION_FEATURE_UNKNOWN":
      return AuthenticationFeature.AUTHENTICATION_FEATURE_UNKNOWN;
    case 1:
    case "CREATE_ACCOUNT":
      return AuthenticationFeature.CREATE_ACCOUNT;
    case 2:
    case "LOGIN":
      return AuthenticationFeature.LOGIN;
    case -1:
    case "UNRECOGNIZED":
    default:
      return AuthenticationFeature.UNRECOGNIZED;
  }
}

export function authenticationFeatureToJSON(object: AuthenticationFeature): string {
  switch (object) {
    case AuthenticationFeature.AUTHENTICATION_FEATURE_UNKNOWN:
      return "AUTHENTICATION_FEATURE_UNKNOWN";
    case AuthenticationFeature.CREATE_ACCOUNT:
      return "CREATE_ACCOUNT";
    case AuthenticationFeature.LOGIN:
      return "LOGIN";
    case AuthenticationFeature.UNRECOGNIZED:
    default:
      return "UNRECOGNIZED";
  }
}

export enum PrivateUserStrategy {
  /**
   * ACCOUNT_IS_FROZEN - `PRIVATE` Users can't see other Users (only `PUBLIC_GLOBAL` Visilibity Users/Posts/Events).
   * Other users can't see them.
   */
  ACCOUNT_IS_FROZEN = 0,
  /**
   * LIMITED_CREEPINESS - Users can see other users they follow, but only `PUBLIC_GLOBAL` Visilibity Posts/Events.
   * Other users can't see them.
   */
  LIMITED_CREEPINESS = 1,
  /**
   * LET_ME_CREEP_ON_PPL - Users can see other users they follow, including their `PUBLIC_SERVER` Posts/Events.
   * Other users can't see them.
   */
  LET_ME_CREEP_ON_PPL = 2,
  UNRECOGNIZED = -1,
}

export function privateUserStrategyFromJSON(object: any): PrivateUserStrategy {
  switch (object) {
    case 0:
    case "ACCOUNT_IS_FROZEN":
      return PrivateUserStrategy.ACCOUNT_IS_FROZEN;
    case 1:
    case "LIMITED_CREEPINESS":
      return PrivateUserStrategy.LIMITED_CREEPINESS;
    case 2:
    case "LET_ME_CREEP_ON_PPL":
      return PrivateUserStrategy.LET_ME_CREEP_ON_PPL;
    case -1:
    case "UNRECOGNIZED":
    default:
      return PrivateUserStrategy.UNRECOGNIZED;
  }
}

export function privateUserStrategyToJSON(object: PrivateUserStrategy): string {
  switch (object) {
    case PrivateUserStrategy.ACCOUNT_IS_FROZEN:
      return "ACCOUNT_IS_FROZEN";
    case PrivateUserStrategy.LIMITED_CREEPINESS:
      return "LIMITED_CREEPINESS";
    case PrivateUserStrategy.LET_ME_CREEP_ON_PPL:
      return "LET_ME_CREEP_ON_PPL";
    case PrivateUserStrategy.UNRECOGNIZED:
    default:
      return "UNRECOGNIZED";
  }
}

/** Offers a choice of web UIs. All */
export enum WebUserInterface {
  /** FLUTTER_WEB - Uses Flutter Web. Loaded from /app. */
  FLUTTER_WEB = 0,
  /**
   * HANDLEBARS_TEMPLATES - Uses Handlebars templates. Deprecated; will revert to Tamagui UI if chosen.
   *
   * @deprecated
   */
  HANDLEBARS_TEMPLATES = 1,
  /** REACT_TAMAGUI - React UI using Tamagui (a React Native UI library). */
  REACT_TAMAGUI = 2,
  UNRECOGNIZED = -1,
}

export function webUserInterfaceFromJSON(object: any): WebUserInterface {
  switch (object) {
    case 0:
    case "FLUTTER_WEB":
      return WebUserInterface.FLUTTER_WEB;
    case 1:
    case "HANDLEBARS_TEMPLATES":
      return WebUserInterface.HANDLEBARS_TEMPLATES;
    case 2:
    case "REACT_TAMAGUI":
      return WebUserInterface.REACT_TAMAGUI;
    case -1:
    case "UNRECOGNIZED":
    default:
      return WebUserInterface.UNRECOGNIZED;
  }
}

export function webUserInterfaceToJSON(object: WebUserInterface): string {
  switch (object) {
    case WebUserInterface.FLUTTER_WEB:
      return "FLUTTER_WEB";
    case WebUserInterface.HANDLEBARS_TEMPLATES:
      return "HANDLEBARS_TEMPLATES";
    case WebUserInterface.REACT_TAMAGUI:
      return "REACT_TAMAGUI";
    case WebUserInterface.UNRECOGNIZED:
    default:
      return "UNRECOGNIZED";
  }
}

/** Configuration for a Jonline server instance. */
export interface ServerConfiguration {
  /** The name, description, logo, color scheme, etc. of the server. */
  serverInfo?:
    | ServerInfo
    | undefined;
  /**
   * Permissions for a user who isn't logged in to the server. Allows
   * admins to disable certain features for anonymous users. Valid values are
   * `VIEW_USERS`, `VIEW_GROUPS`, `VIEW_POSTS`, and `VIEW_EVENTS`.
   */
  anonymousUserPermissions: Permission[];
  /**
   * Default user permissions given to a new user. Users with `MODERATE_USERS` permission can also
   * grant/revoke these permissions for others. Valid values are
   * `VIEW_USERS`, `PUBLISH_USERS_LOCALLY`, `PUBLISH_USERS_GLOBALLY`,
   * `VIEW_GROUPS`, `CREATE_GROUPS`, `PUBLISH_GROUPS_LOCALLY`, `PUBLISH_GROUPS_GLOBALLY`, `JOIN_GROUPS`,
   * `VIEW_POSTS`, `CREATE_POSTS`, `PUBLISH_POSTS_LOCALLY`, `PUBLISH_POSTS_GLOBALLY`,
   * `VIEW_EVENTS`, `CREATE_EVENTS`, `PUBLISH_EVENTS_LOCALLY`, and `PUBLISH_EVENTS_GLOBALLY`.
   */
  defaultUserPermissions: Permission[];
  /**
   * Permissions grantable by a user with the `GRANT_BASIC_PERMISSIONS` permission. Valid values are
   * `VIEW_USERS`, `PUBLISH_USERS_LOCALLY`, `PUBLISH_USERS_GLOBALLY`,
   * `VIEW_GROUPS`, `CREATE_GROUPS`, `PUBLISH_GROUPS_LOCALLY`, `PUBLISH_GROUPS_GLOBALLY`, `JOIN_GROUPS`,
   * `VIEW_POSTS`, `CREATE_POSTS`, `PUBLISH_POSTS_LOCALLY`, `PUBLISH_POSTS_GLOBALLY`,
   * `VIEW_EVENTS`, `CREATE_EVENTS`, `PUBLISH_EVENTS_LOCALLY`, and `PUBLISH_EVENTS_GLOBALLY`.
   */
  basicUserPermissions: Permission[];
  /**
   * If default visibility is `GLOBAL_PUBLIC`, default_user_permissions *must*
   * contain `PUBLISH_USERS_GLOBALLY`.
   */
  peopleSettings:
    | FeatureSettings
    | undefined;
  /**
   * If default visibility is `GLOBAL_PUBLIC`, default_user_permissions *must*
   * contain `PUBLISH_GROUPS_GLOBALLY`.
   */
  groupSettings:
    | FeatureSettings
    | undefined;
  /**
   * If default visibility is `GLOBAL_PUBLIC`, default_user_permissions *must*
   * contain `PUBLISH_POSTS_GLOBALLY`.
   */
  postSettings:
    | PostSettings
    | undefined;
  /**
   * If default visibility is `GLOBAL_PUBLIC`, default_user_permissions *must*
   * contain `PUBLISH_EVENTS_GLOBALLY`.
   */
  eventSettings:
    | FeatureSettings
    | undefined;
  /** Strategy when a user sets their visibility to `PRIVATE`. Defaults to `ACCOUNT_IS_FROZEN`. */
  privateUserStrategy: PrivateUserStrategy;
  /**
   * Allows admins to enable/disable creating accounts and logging in.
   * Eventually, external auth too hopefully!
   */
  authenticationFeatures: AuthenticationFeature[];
}

export interface FeatureSettings {
  /** Hide the Posts or Events tab from the user with this flag. */
  visible: boolean;
  /**
   * Only `UNMODERATED` and `PENDING` are valid.
   * When `UNMODERATED`, user reports may transition status to `PENDING`.
   * When `PENDING`, users' SERVER_PUBLIC or `GLOBAL_PUBLIC` posts will not
   * be visible until a moderator approves them. `LIMITED` visiblity
   * posts are always visible to targeted users (who have not blocked
   * the author) regardless of default_moderation.
   */
  defaultModeration: Moderation;
  /**
   * Only `SERVER_PUBLIC` and `GLOBAL_PUBLIC` are valid. `GLOBAL_PUBLIC` is only valid
   * if default_user_permissions contains `GLOBALLY_PUBLISH_[USERS|GROUPS|POSTS|EVENTS]`
   * as appropriate.
   */
  defaultVisibility: Visibility;
  customTitle?: string | undefined;
}

export interface PostSettings {
  /** Hide the Posts or Events tab from the user with this flag. */
  visible: boolean;
  /**
   * Only `UNMODERATED` and `PENDING` are valid.
   * When `UNMODERATED`, user reports may transition status to `PENDING`.
   * When `PENDING`, users' SERVER_PUBLIC or `GLOBAL_PUBLIC` posts will not
   * be visible until a moderator approves them. `LIMITED` visiblity
   * posts are always visible to targeted users (who have not blocked
   * the author) regardless of default_moderation.
   */
  defaultModeration: Moderation;
  /**
   * Only `SERVER_PUBLIC` and `GLOBAL_PUBLIC` are valid. `GLOBAL_PUBLIC` is only valid
   * if default_user_permissions contains `GLOBALLY_PUBLISH_[USERS|GROUPS|POSTS|EVENTS]`
   * as appropriate.
   */
  defaultVisibility: Visibility;
  customTitle?:
    | string
    | undefined;
  /**
   * Controls whether replies are shown in the UI. Note that users' ability to reply
   * is controlled by the `REPLY_TO_POSTS` permission.
   */
  enableReplies: boolean;
}

export interface ServerInfo {
  name?: string | undefined;
  shortName?: string | undefined;
  description?: string | undefined;
  privacyPolicyLink?: string | undefined;
  aboutLink?: string | undefined;
  webUserInterface?: WebUserInterface | undefined;
  colors?: ServerColors | undefined;
  logo?: Uint8Array | undefined;
}

/** Color in ARGB hex format (i.e `0xAARRGGBB`). */
export interface ServerColors {
  /** App Bar/primary accent color. */
  primary?:
    | number
    | undefined;
  /** Nav/secondary accent color. */
  navigation?:
    | number
    | undefined;
  /** Color used on author of a post in discussion threads for it. */
  author?:
    | number
    | undefined;
  /** Color used on author for admin posts. */
  admin?:
    | number
    | undefined;
  /** Color used on author for moderator posts. */
  moderator?: number | undefined;
}

function createBaseServerConfiguration(): ServerConfiguration {
  return {
    serverInfo: undefined,
    anonymousUserPermissions: [],
    defaultUserPermissions: [],
    basicUserPermissions: [],
    peopleSettings: undefined,
    groupSettings: undefined,
    postSettings: undefined,
    eventSettings: undefined,
    privateUserStrategy: 0,
    authenticationFeatures: [],
  };
}

export const ServerConfiguration = {
  encode(message: ServerConfiguration, writer: _m0.Writer = _m0.Writer.create()): _m0.Writer {
    if (message.serverInfo !== undefined) {
      ServerInfo.encode(message.serverInfo, writer.uint32(10).fork()).ldelim();
    }
    writer.uint32(82).fork();
    for (const v of message.anonymousUserPermissions) {
      writer.int32(v);
    }
    writer.ldelim();
    writer.uint32(90).fork();
    for (const v of message.defaultUserPermissions) {
      writer.int32(v);
    }
    writer.ldelim();
    writer.uint32(98).fork();
    for (const v of message.basicUserPermissions) {
      writer.int32(v);
    }
    writer.ldelim();
    if (message.peopleSettings !== undefined) {
      FeatureSettings.encode(message.peopleSettings, writer.uint32(162).fork()).ldelim();
    }
    if (message.groupSettings !== undefined) {
      FeatureSettings.encode(message.groupSettings, writer.uint32(170).fork()).ldelim();
    }
    if (message.postSettings !== undefined) {
      PostSettings.encode(message.postSettings, writer.uint32(178).fork()).ldelim();
    }
    if (message.eventSettings !== undefined) {
      FeatureSettings.encode(message.eventSettings, writer.uint32(186).fork()).ldelim();
    }
    if (message.privateUserStrategy !== 0) {
      writer.uint32(800).int32(message.privateUserStrategy);
    }
    writer.uint32(810).fork();
    for (const v of message.authenticationFeatures) {
      writer.int32(v);
    }
    writer.ldelim();
    return writer;
  },

  decode(input: _m0.Reader | Uint8Array, length?: number): ServerConfiguration {
    const reader = input instanceof _m0.Reader ? input : new _m0.Reader(input);
    let end = length === undefined ? reader.len : reader.pos + length;
    const message = createBaseServerConfiguration();
    while (reader.pos < end) {
      const tag = reader.uint32();
      switch (tag >>> 3) {
        case 1:
          message.serverInfo = ServerInfo.decode(reader, reader.uint32());
          break;
        case 10:
          if ((tag & 7) === 2) {
            const end2 = reader.uint32() + reader.pos;
            while (reader.pos < end2) {
              message.anonymousUserPermissions.push(reader.int32() as any);
            }
          } else {
            message.anonymousUserPermissions.push(reader.int32() as any);
          }
          break;
        case 11:
          if ((tag & 7) === 2) {
            const end2 = reader.uint32() + reader.pos;
            while (reader.pos < end2) {
              message.defaultUserPermissions.push(reader.int32() as any);
            }
          } else {
            message.defaultUserPermissions.push(reader.int32() as any);
          }
          break;
        case 12:
          if ((tag & 7) === 2) {
            const end2 = reader.uint32() + reader.pos;
            while (reader.pos < end2) {
              message.basicUserPermissions.push(reader.int32() as any);
            }
          } else {
            message.basicUserPermissions.push(reader.int32() as any);
          }
          break;
        case 20:
          message.peopleSettings = FeatureSettings.decode(reader, reader.uint32());
          break;
        case 21:
          message.groupSettings = FeatureSettings.decode(reader, reader.uint32());
          break;
        case 22:
          message.postSettings = PostSettings.decode(reader, reader.uint32());
          break;
        case 23:
          message.eventSettings = FeatureSettings.decode(reader, reader.uint32());
          break;
        case 100:
          message.privateUserStrategy = reader.int32() as any;
          break;
        case 101:
          if ((tag & 7) === 2) {
            const end2 = reader.uint32() + reader.pos;
            while (reader.pos < end2) {
              message.authenticationFeatures.push(reader.int32() as any);
            }
          } else {
            message.authenticationFeatures.push(reader.int32() as any);
          }
          break;
        default:
          reader.skipType(tag & 7);
          break;
      }
    }
    return message;
  },

  fromJSON(object: any): ServerConfiguration {
    return {
      serverInfo: isSet(object.serverInfo) ? ServerInfo.fromJSON(object.serverInfo) : undefined,
      anonymousUserPermissions: Array.isArray(object?.anonymousUserPermissions)
        ? object.anonymousUserPermissions.map((e: any) => permissionFromJSON(e))
        : [],
      defaultUserPermissions: Array.isArray(object?.defaultUserPermissions)
        ? object.defaultUserPermissions.map((e: any) => permissionFromJSON(e))
        : [],
      basicUserPermissions: Array.isArray(object?.basicUserPermissions)
        ? object.basicUserPermissions.map((e: any) => permissionFromJSON(e))
        : [],
      peopleSettings: isSet(object.peopleSettings) ? FeatureSettings.fromJSON(object.peopleSettings) : undefined,
      groupSettings: isSet(object.groupSettings) ? FeatureSettings.fromJSON(object.groupSettings) : undefined,
      postSettings: isSet(object.postSettings) ? PostSettings.fromJSON(object.postSettings) : undefined,
      eventSettings: isSet(object.eventSettings) ? FeatureSettings.fromJSON(object.eventSettings) : undefined,
      privateUserStrategy: isSet(object.privateUserStrategy)
        ? privateUserStrategyFromJSON(object.privateUserStrategy)
        : 0,
      authenticationFeatures: Array.isArray(object?.authenticationFeatures)
        ? object.authenticationFeatures.map((e: any) => authenticationFeatureFromJSON(e))
        : [],
    };
  },

  toJSON(message: ServerConfiguration): unknown {
    const obj: any = {};
    message.serverInfo !== undefined &&
      (obj.serverInfo = message.serverInfo ? ServerInfo.toJSON(message.serverInfo) : undefined);
    if (message.anonymousUserPermissions) {
      obj.anonymousUserPermissions = message.anonymousUserPermissions.map((e) => permissionToJSON(e));
    } else {
      obj.anonymousUserPermissions = [];
    }
    if (message.defaultUserPermissions) {
      obj.defaultUserPermissions = message.defaultUserPermissions.map((e) => permissionToJSON(e));
    } else {
      obj.defaultUserPermissions = [];
    }
    if (message.basicUserPermissions) {
      obj.basicUserPermissions = message.basicUserPermissions.map((e) => permissionToJSON(e));
    } else {
      obj.basicUserPermissions = [];
    }
    message.peopleSettings !== undefined &&
      (obj.peopleSettings = message.peopleSettings ? FeatureSettings.toJSON(message.peopleSettings) : undefined);
    message.groupSettings !== undefined &&
      (obj.groupSettings = message.groupSettings ? FeatureSettings.toJSON(message.groupSettings) : undefined);
    message.postSettings !== undefined &&
      (obj.postSettings = message.postSettings ? PostSettings.toJSON(message.postSettings) : undefined);
    message.eventSettings !== undefined &&
      (obj.eventSettings = message.eventSettings ? FeatureSettings.toJSON(message.eventSettings) : undefined);
    message.privateUserStrategy !== undefined &&
      (obj.privateUserStrategy = privateUserStrategyToJSON(message.privateUserStrategy));
    if (message.authenticationFeatures) {
      obj.authenticationFeatures = message.authenticationFeatures.map((e) => authenticationFeatureToJSON(e));
    } else {
      obj.authenticationFeatures = [];
    }
    return obj;
  },

  create<I extends Exact<DeepPartial<ServerConfiguration>, I>>(base?: I): ServerConfiguration {
    return ServerConfiguration.fromPartial(base ?? {});
  },

  fromPartial<I extends Exact<DeepPartial<ServerConfiguration>, I>>(object: I): ServerConfiguration {
    const message = createBaseServerConfiguration();
    message.serverInfo = (object.serverInfo !== undefined && object.serverInfo !== null)
      ? ServerInfo.fromPartial(object.serverInfo)
      : undefined;
    message.anonymousUserPermissions = object.anonymousUserPermissions?.map((e) => e) || [];
    message.defaultUserPermissions = object.defaultUserPermissions?.map((e) => e) || [];
    message.basicUserPermissions = object.basicUserPermissions?.map((e) => e) || [];
    message.peopleSettings = (object.peopleSettings !== undefined && object.peopleSettings !== null)
      ? FeatureSettings.fromPartial(object.peopleSettings)
      : undefined;
    message.groupSettings = (object.groupSettings !== undefined && object.groupSettings !== null)
      ? FeatureSettings.fromPartial(object.groupSettings)
      : undefined;
    message.postSettings = (object.postSettings !== undefined && object.postSettings !== null)
      ? PostSettings.fromPartial(object.postSettings)
      : undefined;
    message.eventSettings = (object.eventSettings !== undefined && object.eventSettings !== null)
      ? FeatureSettings.fromPartial(object.eventSettings)
      : undefined;
    message.privateUserStrategy = object.privateUserStrategy ?? 0;
    message.authenticationFeatures = object.authenticationFeatures?.map((e) => e) || [];
    return message;
  },
};

function createBaseFeatureSettings(): FeatureSettings {
  return { visible: false, defaultModeration: 0, defaultVisibility: 0, customTitle: undefined };
}

export const FeatureSettings = {
  encode(message: FeatureSettings, writer: _m0.Writer = _m0.Writer.create()): _m0.Writer {
    if (message.visible === true) {
      writer.uint32(8).bool(message.visible);
    }
    if (message.defaultModeration !== 0) {
      writer.uint32(16).int32(message.defaultModeration);
    }
    if (message.defaultVisibility !== 0) {
      writer.uint32(24).int32(message.defaultVisibility);
    }
    if (message.customTitle !== undefined) {
      writer.uint32(34).string(message.customTitle);
    }
    return writer;
  },

  decode(input: _m0.Reader | Uint8Array, length?: number): FeatureSettings {
    const reader = input instanceof _m0.Reader ? input : new _m0.Reader(input);
    let end = length === undefined ? reader.len : reader.pos + length;
    const message = createBaseFeatureSettings();
    while (reader.pos < end) {
      const tag = reader.uint32();
      switch (tag >>> 3) {
        case 1:
          message.visible = reader.bool();
          break;
        case 2:
          message.defaultModeration = reader.int32() as any;
          break;
        case 3:
          message.defaultVisibility = reader.int32() as any;
          break;
        case 4:
          message.customTitle = reader.string();
          break;
        default:
          reader.skipType(tag & 7);
          break;
      }
    }
    return message;
  },

  fromJSON(object: any): FeatureSettings {
    return {
      visible: isSet(object.visible) ? Boolean(object.visible) : false,
      defaultModeration: isSet(object.defaultModeration) ? moderationFromJSON(object.defaultModeration) : 0,
      defaultVisibility: isSet(object.defaultVisibility) ? visibilityFromJSON(object.defaultVisibility) : 0,
      customTitle: isSet(object.customTitle) ? String(object.customTitle) : undefined,
    };
  },

  toJSON(message: FeatureSettings): unknown {
    const obj: any = {};
    message.visible !== undefined && (obj.visible = message.visible);
    message.defaultModeration !== undefined && (obj.defaultModeration = moderationToJSON(message.defaultModeration));
    message.defaultVisibility !== undefined && (obj.defaultVisibility = visibilityToJSON(message.defaultVisibility));
    message.customTitle !== undefined && (obj.customTitle = message.customTitle);
    return obj;
  },

  create<I extends Exact<DeepPartial<FeatureSettings>, I>>(base?: I): FeatureSettings {
    return FeatureSettings.fromPartial(base ?? {});
  },

  fromPartial<I extends Exact<DeepPartial<FeatureSettings>, I>>(object: I): FeatureSettings {
    const message = createBaseFeatureSettings();
    message.visible = object.visible ?? false;
    message.defaultModeration = object.defaultModeration ?? 0;
    message.defaultVisibility = object.defaultVisibility ?? 0;
    message.customTitle = object.customTitle ?? undefined;
    return message;
  },
};

function createBasePostSettings(): PostSettings {
  return { visible: false, defaultModeration: 0, defaultVisibility: 0, customTitle: undefined, enableReplies: false };
}

export const PostSettings = {
  encode(message: PostSettings, writer: _m0.Writer = _m0.Writer.create()): _m0.Writer {
    if (message.visible === true) {
      writer.uint32(8).bool(message.visible);
    }
    if (message.defaultModeration !== 0) {
      writer.uint32(16).int32(message.defaultModeration);
    }
    if (message.defaultVisibility !== 0) {
      writer.uint32(24).int32(message.defaultVisibility);
    }
    if (message.customTitle !== undefined) {
      writer.uint32(34).string(message.customTitle);
    }
    if (message.enableReplies === true) {
      writer.uint32(40).bool(message.enableReplies);
    }
    return writer;
  },

  decode(input: _m0.Reader | Uint8Array, length?: number): PostSettings {
    const reader = input instanceof _m0.Reader ? input : new _m0.Reader(input);
    let end = length === undefined ? reader.len : reader.pos + length;
    const message = createBasePostSettings();
    while (reader.pos < end) {
      const tag = reader.uint32();
      switch (tag >>> 3) {
        case 1:
          message.visible = reader.bool();
          break;
        case 2:
          message.defaultModeration = reader.int32() as any;
          break;
        case 3:
          message.defaultVisibility = reader.int32() as any;
          break;
        case 4:
          message.customTitle = reader.string();
          break;
        case 5:
          message.enableReplies = reader.bool();
          break;
        default:
          reader.skipType(tag & 7);
          break;
      }
    }
    return message;
  },

  fromJSON(object: any): PostSettings {
    return {
      visible: isSet(object.visible) ? Boolean(object.visible) : false,
      defaultModeration: isSet(object.defaultModeration) ? moderationFromJSON(object.defaultModeration) : 0,
      defaultVisibility: isSet(object.defaultVisibility) ? visibilityFromJSON(object.defaultVisibility) : 0,
      customTitle: isSet(object.customTitle) ? String(object.customTitle) : undefined,
      enableReplies: isSet(object.enableReplies) ? Boolean(object.enableReplies) : false,
    };
  },

  toJSON(message: PostSettings): unknown {
    const obj: any = {};
    message.visible !== undefined && (obj.visible = message.visible);
    message.defaultModeration !== undefined && (obj.defaultModeration = moderationToJSON(message.defaultModeration));
    message.defaultVisibility !== undefined && (obj.defaultVisibility = visibilityToJSON(message.defaultVisibility));
    message.customTitle !== undefined && (obj.customTitle = message.customTitle);
    message.enableReplies !== undefined && (obj.enableReplies = message.enableReplies);
    return obj;
  },

  create<I extends Exact<DeepPartial<PostSettings>, I>>(base?: I): PostSettings {
    return PostSettings.fromPartial(base ?? {});
  },

  fromPartial<I extends Exact<DeepPartial<PostSettings>, I>>(object: I): PostSettings {
    const message = createBasePostSettings();
    message.visible = object.visible ?? false;
    message.defaultModeration = object.defaultModeration ?? 0;
    message.defaultVisibility = object.defaultVisibility ?? 0;
    message.customTitle = object.customTitle ?? undefined;
    message.enableReplies = object.enableReplies ?? false;
    return message;
  },
};

function createBaseServerInfo(): ServerInfo {
  return {
    name: undefined,
    shortName: undefined,
    description: undefined,
    privacyPolicyLink: undefined,
    aboutLink: undefined,
    webUserInterface: undefined,
    colors: undefined,
    logo: undefined,
  };
}

export const ServerInfo = {
  encode(message: ServerInfo, writer: _m0.Writer = _m0.Writer.create()): _m0.Writer {
    if (message.name !== undefined) {
      writer.uint32(10).string(message.name);
    }
    if (message.shortName !== undefined) {
      writer.uint32(18).string(message.shortName);
    }
    if (message.description !== undefined) {
      writer.uint32(26).string(message.description);
    }
    if (message.privacyPolicyLink !== undefined) {
      writer.uint32(34).string(message.privacyPolicyLink);
    }
    if (message.aboutLink !== undefined) {
      writer.uint32(42).string(message.aboutLink);
    }
    if (message.webUserInterface !== undefined) {
      writer.uint32(48).int32(message.webUserInterface);
    }
    if (message.colors !== undefined) {
      ServerColors.encode(message.colors, writer.uint32(58).fork()).ldelim();
    }
    if (message.logo !== undefined) {
      writer.uint32(66).bytes(message.logo);
    }
    return writer;
  },

  decode(input: _m0.Reader | Uint8Array, length?: number): ServerInfo {
    const reader = input instanceof _m0.Reader ? input : new _m0.Reader(input);
    let end = length === undefined ? reader.len : reader.pos + length;
    const message = createBaseServerInfo();
    while (reader.pos < end) {
      const tag = reader.uint32();
      switch (tag >>> 3) {
        case 1:
          message.name = reader.string();
          break;
        case 2:
          message.shortName = reader.string();
          break;
        case 3:
          message.description = reader.string();
          break;
        case 4:
          message.privacyPolicyLink = reader.string();
          break;
        case 5:
          message.aboutLink = reader.string();
          break;
        case 6:
          message.webUserInterface = reader.int32() as any;
          break;
        case 7:
          message.colors = ServerColors.decode(reader, reader.uint32());
          break;
        case 8:
          message.logo = reader.bytes();
          break;
        default:
          reader.skipType(tag & 7);
          break;
      }
    }
    return message;
  },

  fromJSON(object: any): ServerInfo {
    return {
      name: isSet(object.name) ? String(object.name) : undefined,
      shortName: isSet(object.shortName) ? String(object.shortName) : undefined,
      description: isSet(object.description) ? String(object.description) : undefined,
      privacyPolicyLink: isSet(object.privacyPolicyLink) ? String(object.privacyPolicyLink) : undefined,
      aboutLink: isSet(object.aboutLink) ? String(object.aboutLink) : undefined,
      webUserInterface: isSet(object.webUserInterface) ? webUserInterfaceFromJSON(object.webUserInterface) : undefined,
      colors: isSet(object.colors) ? ServerColors.fromJSON(object.colors) : undefined,
      logo: isSet(object.logo) ? bytesFromBase64(object.logo) : undefined,
    };
  },

  toJSON(message: ServerInfo): unknown {
    const obj: any = {};
    message.name !== undefined && (obj.name = message.name);
    message.shortName !== undefined && (obj.shortName = message.shortName);
    message.description !== undefined && (obj.description = message.description);
    message.privacyPolicyLink !== undefined && (obj.privacyPolicyLink = message.privacyPolicyLink);
    message.aboutLink !== undefined && (obj.aboutLink = message.aboutLink);
    message.webUserInterface !== undefined && (obj.webUserInterface = message.webUserInterface !== undefined
      ? webUserInterfaceToJSON(message.webUserInterface)
      : undefined);
    message.colors !== undefined && (obj.colors = message.colors ? ServerColors.toJSON(message.colors) : undefined);
    message.logo !== undefined && (obj.logo = message.logo !== undefined ? base64FromBytes(message.logo) : undefined);
    return obj;
  },

  create<I extends Exact<DeepPartial<ServerInfo>, I>>(base?: I): ServerInfo {
    return ServerInfo.fromPartial(base ?? {});
  },

  fromPartial<I extends Exact<DeepPartial<ServerInfo>, I>>(object: I): ServerInfo {
    const message = createBaseServerInfo();
    message.name = object.name ?? undefined;
    message.shortName = object.shortName ?? undefined;
    message.description = object.description ?? undefined;
    message.privacyPolicyLink = object.privacyPolicyLink ?? undefined;
    message.aboutLink = object.aboutLink ?? undefined;
    message.webUserInterface = object.webUserInterface ?? undefined;
    message.colors = (object.colors !== undefined && object.colors !== null)
      ? ServerColors.fromPartial(object.colors)
      : undefined;
    message.logo = object.logo ?? undefined;
    return message;
  },
};

function createBaseServerColors(): ServerColors {
  return { primary: undefined, navigation: undefined, author: undefined, admin: undefined, moderator: undefined };
}

export const ServerColors = {
  encode(message: ServerColors, writer: _m0.Writer = _m0.Writer.create()): _m0.Writer {
    if (message.primary !== undefined) {
      writer.uint32(8).uint32(message.primary);
    }
    if (message.navigation !== undefined) {
      writer.uint32(16).uint32(message.navigation);
    }
    if (message.author !== undefined) {
      writer.uint32(24).uint32(message.author);
    }
    if (message.admin !== undefined) {
      writer.uint32(32).uint32(message.admin);
    }
    if (message.moderator !== undefined) {
      writer.uint32(40).uint32(message.moderator);
    }
    return writer;
  },

  decode(input: _m0.Reader | Uint8Array, length?: number): ServerColors {
    const reader = input instanceof _m0.Reader ? input : new _m0.Reader(input);
    let end = length === undefined ? reader.len : reader.pos + length;
    const message = createBaseServerColors();
    while (reader.pos < end) {
      const tag = reader.uint32();
      switch (tag >>> 3) {
        case 1:
          message.primary = reader.uint32();
          break;
        case 2:
          message.navigation = reader.uint32();
          break;
        case 3:
          message.author = reader.uint32();
          break;
        case 4:
          message.admin = reader.uint32();
          break;
        case 5:
          message.moderator = reader.uint32();
          break;
        default:
          reader.skipType(tag & 7);
          break;
      }
    }
    return message;
  },

  fromJSON(object: any): ServerColors {
    return {
      primary: isSet(object.primary) ? Number(object.primary) : undefined,
      navigation: isSet(object.navigation) ? Number(object.navigation) : undefined,
      author: isSet(object.author) ? Number(object.author) : undefined,
      admin: isSet(object.admin) ? Number(object.admin) : undefined,
      moderator: isSet(object.moderator) ? Number(object.moderator) : undefined,
    };
  },

  toJSON(message: ServerColors): unknown {
    const obj: any = {};
    message.primary !== undefined && (obj.primary = Math.round(message.primary));
    message.navigation !== undefined && (obj.navigation = Math.round(message.navigation));
    message.author !== undefined && (obj.author = Math.round(message.author));
    message.admin !== undefined && (obj.admin = Math.round(message.admin));
    message.moderator !== undefined && (obj.moderator = Math.round(message.moderator));
    return obj;
  },

  create<I extends Exact<DeepPartial<ServerColors>, I>>(base?: I): ServerColors {
    return ServerColors.fromPartial(base ?? {});
  },

  fromPartial<I extends Exact<DeepPartial<ServerColors>, I>>(object: I): ServerColors {
    const message = createBaseServerColors();
    message.primary = object.primary ?? undefined;
    message.navigation = object.navigation ?? undefined;
    message.author = object.author ?? undefined;
    message.admin = object.admin ?? undefined;
    message.moderator = object.moderator ?? undefined;
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

function isSet(value: any): boolean {
  return value !== null && value !== undefined;
}
