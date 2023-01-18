/* eslint-disable */
import _m0 from "protobufjs/minimal";
import { Timestamp } from "./google/protobuf/timestamp";
import { ContactMethod, User } from "./users";

export const protobufPackage = "jonline";

export interface CreateAccountRequest {
  username: string;
  password: string;
  email?: ContactMethod | undefined;
  phone?:
    | ContactMethod
    | undefined;
  /** Request an expiration time for the Auth Token returned. By default it will not expire. */
  expiresAt?: Date | undefined;
  deviceName?: string | undefined;
}

export interface LoginRequest {
  username: string;
  password: string;
  /** Request an expiration time for the Auth Token returned. By default it will not expire. */
  expiresAt?: Date | undefined;
  deviceName?: string | undefined;
}

/** Returned when creating an account or logging in. */
export interface RefreshTokenResponse {
  refreshToken: ExpirableToken | undefined;
  accessToken: ExpirableToken | undefined;
  user: User | undefined;
}

export interface ExpirableToken {
  token: string;
  /** Optional expiration time for the token. If not set, the token will not expire. */
  expiresAt?: Date | undefined;
}

export interface AccessTokenRequest {
  refreshToken: string;
  /** Optional *requested* expiration time for the token. Server may ignore this. */
  expiresAt?: Date | undefined;
}

export interface AccessTokenResponse {
  accessToken?: string | undefined;
  expiresAt?: Date | undefined;
}

function createBaseCreateAccountRequest(): CreateAccountRequest {
  return {
    username: "",
    password: "",
    email: undefined,
    phone: undefined,
    expiresAt: undefined,
    deviceName: undefined,
  };
}

export const CreateAccountRequest = {
  encode(message: CreateAccountRequest, writer: _m0.Writer = _m0.Writer.create()): _m0.Writer {
    if (message.username !== "") {
      writer.uint32(10).string(message.username);
    }
    if (message.password !== "") {
      writer.uint32(18).string(message.password);
    }
    if (message.email !== undefined) {
      ContactMethod.encode(message.email, writer.uint32(26).fork()).ldelim();
    }
    if (message.phone !== undefined) {
      ContactMethod.encode(message.phone, writer.uint32(34).fork()).ldelim();
    }
    if (message.expiresAt !== undefined) {
      Timestamp.encode(toTimestamp(message.expiresAt), writer.uint32(42).fork()).ldelim();
    }
    if (message.deviceName !== undefined) {
      writer.uint32(50).string(message.deviceName);
    }
    return writer;
  },

  decode(input: _m0.Reader | Uint8Array, length?: number): CreateAccountRequest {
    const reader = input instanceof _m0.Reader ? input : new _m0.Reader(input);
    let end = length === undefined ? reader.len : reader.pos + length;
    const message = createBaseCreateAccountRequest();
    while (reader.pos < end) {
      const tag = reader.uint32();
      switch (tag >>> 3) {
        case 1:
          message.username = reader.string();
          break;
        case 2:
          message.password = reader.string();
          break;
        case 3:
          message.email = ContactMethod.decode(reader, reader.uint32());
          break;
        case 4:
          message.phone = ContactMethod.decode(reader, reader.uint32());
          break;
        case 5:
          message.expiresAt = fromTimestamp(Timestamp.decode(reader, reader.uint32()));
          break;
        case 6:
          message.deviceName = reader.string();
          break;
        default:
          reader.skipType(tag & 7);
          break;
      }
    }
    return message;
  },

  fromJSON(object: any): CreateAccountRequest {
    return {
      username: isSet(object.username) ? String(object.username) : "",
      password: isSet(object.password) ? String(object.password) : "",
      email: isSet(object.email) ? ContactMethod.fromJSON(object.email) : undefined,
      phone: isSet(object.phone) ? ContactMethod.fromJSON(object.phone) : undefined,
      expiresAt: isSet(object.expiresAt) ? fromJsonTimestamp(object.expiresAt) : undefined,
      deviceName: isSet(object.deviceName) ? String(object.deviceName) : undefined,
    };
  },

  toJSON(message: CreateAccountRequest): unknown {
    const obj: any = {};
    message.username !== undefined && (obj.username = message.username);
    message.password !== undefined && (obj.password = message.password);
    message.email !== undefined && (obj.email = message.email ? ContactMethod.toJSON(message.email) : undefined);
    message.phone !== undefined && (obj.phone = message.phone ? ContactMethod.toJSON(message.phone) : undefined);
    message.expiresAt !== undefined && (obj.expiresAt = message.expiresAt.toISOString());
    message.deviceName !== undefined && (obj.deviceName = message.deviceName);
    return obj;
  },

  create<I extends Exact<DeepPartial<CreateAccountRequest>, I>>(base?: I): CreateAccountRequest {
    return CreateAccountRequest.fromPartial(base ?? {});
  },

  fromPartial<I extends Exact<DeepPartial<CreateAccountRequest>, I>>(object: I): CreateAccountRequest {
    const message = createBaseCreateAccountRequest();
    message.username = object.username ?? "";
    message.password = object.password ?? "";
    message.email = (object.email !== undefined && object.email !== null)
      ? ContactMethod.fromPartial(object.email)
      : undefined;
    message.phone = (object.phone !== undefined && object.phone !== null)
      ? ContactMethod.fromPartial(object.phone)
      : undefined;
    message.expiresAt = object.expiresAt ?? undefined;
    message.deviceName = object.deviceName ?? undefined;
    return message;
  },
};

function createBaseLoginRequest(): LoginRequest {
  return { username: "", password: "", expiresAt: undefined, deviceName: undefined };
}

export const LoginRequest = {
  encode(message: LoginRequest, writer: _m0.Writer = _m0.Writer.create()): _m0.Writer {
    if (message.username !== "") {
      writer.uint32(10).string(message.username);
    }
    if (message.password !== "") {
      writer.uint32(18).string(message.password);
    }
    if (message.expiresAt !== undefined) {
      Timestamp.encode(toTimestamp(message.expiresAt), writer.uint32(26).fork()).ldelim();
    }
    if (message.deviceName !== undefined) {
      writer.uint32(34).string(message.deviceName);
    }
    return writer;
  },

  decode(input: _m0.Reader | Uint8Array, length?: number): LoginRequest {
    const reader = input instanceof _m0.Reader ? input : new _m0.Reader(input);
    let end = length === undefined ? reader.len : reader.pos + length;
    const message = createBaseLoginRequest();
    while (reader.pos < end) {
      const tag = reader.uint32();
      switch (tag >>> 3) {
        case 1:
          message.username = reader.string();
          break;
        case 2:
          message.password = reader.string();
          break;
        case 3:
          message.expiresAt = fromTimestamp(Timestamp.decode(reader, reader.uint32()));
          break;
        case 4:
          message.deviceName = reader.string();
          break;
        default:
          reader.skipType(tag & 7);
          break;
      }
    }
    return message;
  },

  fromJSON(object: any): LoginRequest {
    return {
      username: isSet(object.username) ? String(object.username) : "",
      password: isSet(object.password) ? String(object.password) : "",
      expiresAt: isSet(object.expiresAt) ? fromJsonTimestamp(object.expiresAt) : undefined,
      deviceName: isSet(object.deviceName) ? String(object.deviceName) : undefined,
    };
  },

  toJSON(message: LoginRequest): unknown {
    const obj: any = {};
    message.username !== undefined && (obj.username = message.username);
    message.password !== undefined && (obj.password = message.password);
    message.expiresAt !== undefined && (obj.expiresAt = message.expiresAt.toISOString());
    message.deviceName !== undefined && (obj.deviceName = message.deviceName);
    return obj;
  },

  create<I extends Exact<DeepPartial<LoginRequest>, I>>(base?: I): LoginRequest {
    return LoginRequest.fromPartial(base ?? {});
  },

  fromPartial<I extends Exact<DeepPartial<LoginRequest>, I>>(object: I): LoginRequest {
    const message = createBaseLoginRequest();
    message.username = object.username ?? "";
    message.password = object.password ?? "";
    message.expiresAt = object.expiresAt ?? undefined;
    message.deviceName = object.deviceName ?? undefined;
    return message;
  },
};

function createBaseRefreshTokenResponse(): RefreshTokenResponse {
  return { refreshToken: undefined, accessToken: undefined, user: undefined };
}

export const RefreshTokenResponse = {
  encode(message: RefreshTokenResponse, writer: _m0.Writer = _m0.Writer.create()): _m0.Writer {
    if (message.refreshToken !== undefined) {
      ExpirableToken.encode(message.refreshToken, writer.uint32(10).fork()).ldelim();
    }
    if (message.accessToken !== undefined) {
      ExpirableToken.encode(message.accessToken, writer.uint32(18).fork()).ldelim();
    }
    if (message.user !== undefined) {
      User.encode(message.user, writer.uint32(26).fork()).ldelim();
    }
    return writer;
  },

  decode(input: _m0.Reader | Uint8Array, length?: number): RefreshTokenResponse {
    const reader = input instanceof _m0.Reader ? input : new _m0.Reader(input);
    let end = length === undefined ? reader.len : reader.pos + length;
    const message = createBaseRefreshTokenResponse();
    while (reader.pos < end) {
      const tag = reader.uint32();
      switch (tag >>> 3) {
        case 1:
          message.refreshToken = ExpirableToken.decode(reader, reader.uint32());
          break;
        case 2:
          message.accessToken = ExpirableToken.decode(reader, reader.uint32());
          break;
        case 3:
          message.user = User.decode(reader, reader.uint32());
          break;
        default:
          reader.skipType(tag & 7);
          break;
      }
    }
    return message;
  },

  fromJSON(object: any): RefreshTokenResponse {
    return {
      refreshToken: isSet(object.refreshToken) ? ExpirableToken.fromJSON(object.refreshToken) : undefined,
      accessToken: isSet(object.accessToken) ? ExpirableToken.fromJSON(object.accessToken) : undefined,
      user: isSet(object.user) ? User.fromJSON(object.user) : undefined,
    };
  },

  toJSON(message: RefreshTokenResponse): unknown {
    const obj: any = {};
    message.refreshToken !== undefined &&
      (obj.refreshToken = message.refreshToken ? ExpirableToken.toJSON(message.refreshToken) : undefined);
    message.accessToken !== undefined &&
      (obj.accessToken = message.accessToken ? ExpirableToken.toJSON(message.accessToken) : undefined);
    message.user !== undefined && (obj.user = message.user ? User.toJSON(message.user) : undefined);
    return obj;
  },

  create<I extends Exact<DeepPartial<RefreshTokenResponse>, I>>(base?: I): RefreshTokenResponse {
    return RefreshTokenResponse.fromPartial(base ?? {});
  },

  fromPartial<I extends Exact<DeepPartial<RefreshTokenResponse>, I>>(object: I): RefreshTokenResponse {
    const message = createBaseRefreshTokenResponse();
    message.refreshToken = (object.refreshToken !== undefined && object.refreshToken !== null)
      ? ExpirableToken.fromPartial(object.refreshToken)
      : undefined;
    message.accessToken = (object.accessToken !== undefined && object.accessToken !== null)
      ? ExpirableToken.fromPartial(object.accessToken)
      : undefined;
    message.user = (object.user !== undefined && object.user !== null) ? User.fromPartial(object.user) : undefined;
    return message;
  },
};

function createBaseExpirableToken(): ExpirableToken {
  return { token: "", expiresAt: undefined };
}

export const ExpirableToken = {
  encode(message: ExpirableToken, writer: _m0.Writer = _m0.Writer.create()): _m0.Writer {
    if (message.token !== "") {
      writer.uint32(10).string(message.token);
    }
    if (message.expiresAt !== undefined) {
      Timestamp.encode(toTimestamp(message.expiresAt), writer.uint32(18).fork()).ldelim();
    }
    return writer;
  },

  decode(input: _m0.Reader | Uint8Array, length?: number): ExpirableToken {
    const reader = input instanceof _m0.Reader ? input : new _m0.Reader(input);
    let end = length === undefined ? reader.len : reader.pos + length;
    const message = createBaseExpirableToken();
    while (reader.pos < end) {
      const tag = reader.uint32();
      switch (tag >>> 3) {
        case 1:
          message.token = reader.string();
          break;
        case 2:
          message.expiresAt = fromTimestamp(Timestamp.decode(reader, reader.uint32()));
          break;
        default:
          reader.skipType(tag & 7);
          break;
      }
    }
    return message;
  },

  fromJSON(object: any): ExpirableToken {
    return {
      token: isSet(object.token) ? String(object.token) : "",
      expiresAt: isSet(object.expiresAt) ? fromJsonTimestamp(object.expiresAt) : undefined,
    };
  },

  toJSON(message: ExpirableToken): unknown {
    const obj: any = {};
    message.token !== undefined && (obj.token = message.token);
    message.expiresAt !== undefined && (obj.expiresAt = message.expiresAt.toISOString());
    return obj;
  },

  create<I extends Exact<DeepPartial<ExpirableToken>, I>>(base?: I): ExpirableToken {
    return ExpirableToken.fromPartial(base ?? {});
  },

  fromPartial<I extends Exact<DeepPartial<ExpirableToken>, I>>(object: I): ExpirableToken {
    const message = createBaseExpirableToken();
    message.token = object.token ?? "";
    message.expiresAt = object.expiresAt ?? undefined;
    return message;
  },
};

function createBaseAccessTokenRequest(): AccessTokenRequest {
  return { refreshToken: "", expiresAt: undefined };
}

export const AccessTokenRequest = {
  encode(message: AccessTokenRequest, writer: _m0.Writer = _m0.Writer.create()): _m0.Writer {
    if (message.refreshToken !== "") {
      writer.uint32(10).string(message.refreshToken);
    }
    if (message.expiresAt !== undefined) {
      Timestamp.encode(toTimestamp(message.expiresAt), writer.uint32(18).fork()).ldelim();
    }
    return writer;
  },

  decode(input: _m0.Reader | Uint8Array, length?: number): AccessTokenRequest {
    const reader = input instanceof _m0.Reader ? input : new _m0.Reader(input);
    let end = length === undefined ? reader.len : reader.pos + length;
    const message = createBaseAccessTokenRequest();
    while (reader.pos < end) {
      const tag = reader.uint32();
      switch (tag >>> 3) {
        case 1:
          message.refreshToken = reader.string();
          break;
        case 2:
          message.expiresAt = fromTimestamp(Timestamp.decode(reader, reader.uint32()));
          break;
        default:
          reader.skipType(tag & 7);
          break;
      }
    }
    return message;
  },

  fromJSON(object: any): AccessTokenRequest {
    return {
      refreshToken: isSet(object.refreshToken) ? String(object.refreshToken) : "",
      expiresAt: isSet(object.expiresAt) ? fromJsonTimestamp(object.expiresAt) : undefined,
    };
  },

  toJSON(message: AccessTokenRequest): unknown {
    const obj: any = {};
    message.refreshToken !== undefined && (obj.refreshToken = message.refreshToken);
    message.expiresAt !== undefined && (obj.expiresAt = message.expiresAt.toISOString());
    return obj;
  },

  create<I extends Exact<DeepPartial<AccessTokenRequest>, I>>(base?: I): AccessTokenRequest {
    return AccessTokenRequest.fromPartial(base ?? {});
  },

  fromPartial<I extends Exact<DeepPartial<AccessTokenRequest>, I>>(object: I): AccessTokenRequest {
    const message = createBaseAccessTokenRequest();
    message.refreshToken = object.refreshToken ?? "";
    message.expiresAt = object.expiresAt ?? undefined;
    return message;
  },
};

function createBaseAccessTokenResponse(): AccessTokenResponse {
  return { accessToken: undefined, expiresAt: undefined };
}

export const AccessTokenResponse = {
  encode(message: AccessTokenResponse, writer: _m0.Writer = _m0.Writer.create()): _m0.Writer {
    if (message.accessToken !== undefined) {
      writer.uint32(18).string(message.accessToken);
    }
    if (message.expiresAt !== undefined) {
      Timestamp.encode(toTimestamp(message.expiresAt), writer.uint32(26).fork()).ldelim();
    }
    return writer;
  },

  decode(input: _m0.Reader | Uint8Array, length?: number): AccessTokenResponse {
    const reader = input instanceof _m0.Reader ? input : new _m0.Reader(input);
    let end = length === undefined ? reader.len : reader.pos + length;
    const message = createBaseAccessTokenResponse();
    while (reader.pos < end) {
      const tag = reader.uint32();
      switch (tag >>> 3) {
        case 2:
          message.accessToken = reader.string();
          break;
        case 3:
          message.expiresAt = fromTimestamp(Timestamp.decode(reader, reader.uint32()));
          break;
        default:
          reader.skipType(tag & 7);
          break;
      }
    }
    return message;
  },

  fromJSON(object: any): AccessTokenResponse {
    return {
      accessToken: isSet(object.accessToken) ? String(object.accessToken) : undefined,
      expiresAt: isSet(object.expiresAt) ? fromJsonTimestamp(object.expiresAt) : undefined,
    };
  },

  toJSON(message: AccessTokenResponse): unknown {
    const obj: any = {};
    message.accessToken !== undefined && (obj.accessToken = message.accessToken);
    message.expiresAt !== undefined && (obj.expiresAt = message.expiresAt.toISOString());
    return obj;
  },

  create<I extends Exact<DeepPartial<AccessTokenResponse>, I>>(base?: I): AccessTokenResponse {
    return AccessTokenResponse.fromPartial(base ?? {});
  },

  fromPartial<I extends Exact<DeepPartial<AccessTokenResponse>, I>>(object: I): AccessTokenResponse {
    const message = createBaseAccessTokenResponse();
    message.accessToken = object.accessToken ?? undefined;
    message.expiresAt = object.expiresAt ?? undefined;
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

function toTimestamp(date: Date): Timestamp {
  const seconds = date.getTime() / 1_000;
  const nanos = (date.getTime() % 1_000) * 1_000_000;
  return { seconds, nanos };
}

function fromTimestamp(t: Timestamp): Date {
  let millis = t.seconds * 1_000;
  millis += t.nanos / 1_000_000;
  return new Date(millis);
}

function fromJsonTimestamp(o: any): Date {
  if (o instanceof Date) {
    return o;
  } else if (typeof o === "string") {
    return new Date(o);
  } else {
    return fromTimestamp(Timestamp.fromJSON(o));
  }
}

function isSet(value: any): boolean {
  return value !== null && value !== undefined;
}
