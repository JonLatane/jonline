/* eslint-disable */
import { grpc } from "@improbable-eng/grpc-web";
import { BrowserHeaders } from "browser-headers";
import { Observable } from "rxjs";
import { share } from "rxjs/operators";
import {
  AccessTokenRequest,
  AccessTokenResponse,
  CreateAccountRequest,
  LoginRequest,
  RefreshTokenResponse,
} from "./authentication";
import { Event, GetEventsRequest, GetEventsResponse } from "./events";
import { GetServiceVersionResponse } from "./federation";
import { Empty } from "./google/protobuf/empty";
import { GetGroupsRequest, GetGroupsResponse, GetMembersRequest, GetMembersResponse, Group } from "./groups";
import { GetMediaRequest, GetMediaResponse } from "./media";
import {
  GetGroupPostsRequest,
  GetGroupPostsResponse,
  GetPostsRequest,
  GetPostsResponse,
  GroupPost,
  Post,
} from "./posts";
import { ServerConfiguration } from "./server_configuration";
import { Follow, GetUsersRequest, GetUsersResponse, Membership, User } from "./users";

export const protobufPackage = "jonline";

/**
 * The internet-facing Jonline service implementing the Jonline protocol,
 * generally exposed on port 27707.
 *
 * Authenticated calls require an `access_token` in request metadata to be included
 * directly as the value of the `authorization` header (with no `Bearer ` prefix).
 * First, use the `CreateAccount` or `Login` RPCs to fetch (and store) an initial
 * `refresh_token` and `access_token`. Use the `access_token` until it expires,
 * then use the `refresh_token` to call the `AccessToken` RPC for a new one.
 */
export interface Jonline {
  /** Get the version (from Cargo) of the Jonline service. *Publicly accessible.* */
  getServiceVersion(request: DeepPartial<Empty>, metadata?: grpc.Metadata): Promise<GetServiceVersionResponse>;
  /** Gets the Jonline server's configuration. *Publicly accessible.* */
  getServerConfiguration(request: DeepPartial<Empty>, metadata?: grpc.Metadata): Promise<ServerConfiguration>;
  /** Creates a user account and provides a `refresh_token` (along with an `access_token`). *Publicly accessible.* */
  createAccount(request: DeepPartial<CreateAccountRequest>, metadata?: grpc.Metadata): Promise<RefreshTokenResponse>;
  /** Logs in a user and provides a `refresh_token` (along with an `access_token`). *Publicly accessible.* */
  login(request: DeepPartial<LoginRequest>, metadata?: grpc.Metadata): Promise<RefreshTokenResponse>;
  /** Gets a new `access_token` (and possibly a new `refresh_token`, which should replace the old one in client storage), given a `refresh_token`. *Publicly accessible.* */
  accessToken(request: DeepPartial<AccessTokenRequest>, metadata?: grpc.Metadata): Promise<AccessTokenResponse>;
  /** Gets the current user. *Authenticated.* */
  getCurrentUser(request: DeepPartial<Empty>, metadata?: grpc.Metadata): Promise<User>;
  /**
   * Gets Users. *Publicly accessible **or** Authenticated.*
   * Unauthenticated calls only return Users of `GLOBAL_PUBLIC` visibility.
   */
  getUsers(request: DeepPartial<GetUsersRequest>, metadata?: grpc.Metadata): Promise<GetUsersResponse>;
  /**
   * Update a user by ID. *Authenticated.*
   * Updating other users requires `ADMIN` permissions.
   */
  updateUser(request: DeepPartial<User>, metadata?: grpc.Metadata): Promise<User>;
  /** Follow (or request to follow) a user. *Authenticated.* */
  createFollow(request: DeepPartial<Follow>, metadata?: grpc.Metadata): Promise<Follow>;
  /** Used to approve follow requests. *Authenticated.* */
  updateFollow(request: DeepPartial<Follow>, metadata?: grpc.Metadata): Promise<Follow>;
  /** Unfollow (or unrequest) a user. *Authenticated.* */
  deleteFollow(request: DeepPartial<Follow>, metadata?: grpc.Metadata): Promise<Empty>;
  /** (TODO) Gets Media (Images, Videos, etc) uploaded/owned by the current user. *Authenticated.* */
  getMedia(request: DeepPartial<GetMediaRequest>, metadata?: grpc.Metadata): Promise<GetMediaResponse>;
  /**
   * Gets Groups. *Publicly accessible **or** Authenticated.*
   * Unauthenticated calls only return Groups of `GLOBAL_PUBLIC` visibility.
   */
  getGroups(request: DeepPartial<GetGroupsRequest>, metadata?: grpc.Metadata): Promise<GetGroupsResponse>;
  /**
   * Creates a group with the current user as its admin. *Authenticated.*
   * Requires the `CREATE_GROUPS` permission.
   */
  createGroup(request: DeepPartial<Group>, metadata?: grpc.Metadata): Promise<Group>;
  /**
   * Update a Groups's information, default membership permissions or moderation. *Authenticated.*
   * Requires `ADMIN` permissions within the group, or `ADMIN` permissions for the user.
   */
  updateGroup(request: DeepPartial<Group>, metadata?: grpc.Metadata): Promise<Group>;
  /**
   * Delete a Group. *Authenticated.*
   * Requires `ADMIN` permissions within the group, or `ADMIN` permissions for the user.
   */
  deleteGroup(request: DeepPartial<Group>, metadata?: grpc.Metadata): Promise<Empty>;
  /**
   * Requests to join a group (or joins it), or sends an invite to the user. *Authenticated.*
   * Memberships and moderations are set to their defaults.
   */
  createMembership(request: DeepPartial<Membership>, metadata?: grpc.Metadata): Promise<Membership>;
  /**
   * Update aspects of a user's membership. *Authenticated.*
   * Updating permissions requires `ADMIN` permissions within the group, or `ADMIN` permissions for the user.
   * Updating moderation (approving/denying/banning) requires the same, or `MODERATE_USERS` permissions within the group.
   */
  updateMembership(request: DeepPartial<Membership>, metadata?: grpc.Metadata): Promise<Membership>;
  /** Leave a group (or cancel membership request). *Authenticated.* */
  deleteMembership(request: DeepPartial<Membership>, metadata?: grpc.Metadata): Promise<Empty>;
  /** Get Members (User+Membership) of a Group. *Authenticated.* */
  getMembers(request: DeepPartial<GetMembersRequest>, metadata?: grpc.Metadata): Promise<GetMembersResponse>;
  /**
   * Gets Posts. *Publicly accessible **or** Authenticated.*
   * Unauthenticated calls only return Posts of `GLOBAL_PUBLIC` visibility.
   */
  getPosts(request: DeepPartial<GetPostsRequest>, metadata?: grpc.Metadata): Promise<GetPostsResponse>;
  /** Creates a Post. *Authenticated.* */
  createPost(request: DeepPartial<Post>, metadata?: grpc.Metadata): Promise<Post>;
  /** Updates a Post. *Authenticated.* */
  updatePost(request: DeepPartial<Post>, metadata?: grpc.Metadata): Promise<Post>;
  /** (TODO) (Soft) deletes a Post. Returns the deleted version of the Post. *Authenticated.* */
  deletePost(request: DeepPartial<Post>, metadata?: grpc.Metadata): Promise<Post>;
  /** Cross-post a Post to a Group. *Authenticated.* */
  createGroupPost(request: DeepPartial<GroupPost>, metadata?: grpc.Metadata): Promise<GroupPost>;
  /** Group Moderators: Approve/Reject a GroupPost. *Authenticated.* */
  updateGroupPost(request: DeepPartial<GroupPost>, metadata?: grpc.Metadata): Promise<GroupPost>;
  /** Delete a GroupPost. *Authenticated.* */
  deleteGroupPost(request: DeepPartial<GroupPost>, metadata?: grpc.Metadata): Promise<Empty>;
  /** Get GroupPosts for a Post (and optional group). *Publicly accessible **or** Authenticated.* */
  getGroupPosts(request: DeepPartial<GetGroupPostsRequest>, metadata?: grpc.Metadata): Promise<GetGroupPostsResponse>;
  /** (TODO) Reply streaming interface */
  streamReplies(request: DeepPartial<Post>, metadata?: grpc.Metadata): Observable<Post>;
  /** Creates an Event. *Authenticated.* */
  createEvent(request: DeepPartial<Event>, metadata?: grpc.Metadata): Promise<Event>;
  /**
   * Gets Events. *Publicly accessible **or** Authenticated.*
   * Unauthenticated calls only return Events of `GLOBAL_PUBLIC` visibility.
   */
  getEvents(request: DeepPartial<GetEventsRequest>, metadata?: grpc.Metadata): Promise<GetEventsResponse>;
  /**
   * Configure the server (i.e. the response to GetServerConfiguration). *Authenticated.*
   * Requires `ADMIN` permissions.
   */
  configureServer(request: DeepPartial<ServerConfiguration>, metadata?: grpc.Metadata): Promise<ServerConfiguration>;
  /**
   * DELETE ALL Posts, Groups and Users except the one who performed the RPC. *Authenticated.*
   * Requires `ADMIN` permissions.
   * Note: Server Configuration is not deleted.
   */
  resetData(request: DeepPartial<Empty>, metadata?: grpc.Metadata): Promise<Empty>;
}

export class JonlineClientImpl implements Jonline {
  private readonly rpc: Rpc;

  constructor(rpc: Rpc) {
    this.rpc = rpc;
    this.getServiceVersion = this.getServiceVersion.bind(this);
    this.getServerConfiguration = this.getServerConfiguration.bind(this);
    this.createAccount = this.createAccount.bind(this);
    this.login = this.login.bind(this);
    this.accessToken = this.accessToken.bind(this);
    this.getCurrentUser = this.getCurrentUser.bind(this);
    this.getUsers = this.getUsers.bind(this);
    this.updateUser = this.updateUser.bind(this);
    this.createFollow = this.createFollow.bind(this);
    this.updateFollow = this.updateFollow.bind(this);
    this.deleteFollow = this.deleteFollow.bind(this);
    this.getMedia = this.getMedia.bind(this);
    this.getGroups = this.getGroups.bind(this);
    this.createGroup = this.createGroup.bind(this);
    this.updateGroup = this.updateGroup.bind(this);
    this.deleteGroup = this.deleteGroup.bind(this);
    this.createMembership = this.createMembership.bind(this);
    this.updateMembership = this.updateMembership.bind(this);
    this.deleteMembership = this.deleteMembership.bind(this);
    this.getMembers = this.getMembers.bind(this);
    this.getPosts = this.getPosts.bind(this);
    this.createPost = this.createPost.bind(this);
    this.updatePost = this.updatePost.bind(this);
    this.deletePost = this.deletePost.bind(this);
    this.createGroupPost = this.createGroupPost.bind(this);
    this.updateGroupPost = this.updateGroupPost.bind(this);
    this.deleteGroupPost = this.deleteGroupPost.bind(this);
    this.getGroupPosts = this.getGroupPosts.bind(this);
    this.streamReplies = this.streamReplies.bind(this);
    this.createEvent = this.createEvent.bind(this);
    this.getEvents = this.getEvents.bind(this);
    this.configureServer = this.configureServer.bind(this);
    this.resetData = this.resetData.bind(this);
  }

  getServiceVersion(request: DeepPartial<Empty>, metadata?: grpc.Metadata): Promise<GetServiceVersionResponse> {
    return this.rpc.unary(JonlineGetServiceVersionDesc, Empty.fromPartial(request), metadata);
  }

  getServerConfiguration(request: DeepPartial<Empty>, metadata?: grpc.Metadata): Promise<ServerConfiguration> {
    return this.rpc.unary(JonlineGetServerConfigurationDesc, Empty.fromPartial(request), metadata);
  }

  createAccount(request: DeepPartial<CreateAccountRequest>, metadata?: grpc.Metadata): Promise<RefreshTokenResponse> {
    return this.rpc.unary(JonlineCreateAccountDesc, CreateAccountRequest.fromPartial(request), metadata);
  }

  login(request: DeepPartial<LoginRequest>, metadata?: grpc.Metadata): Promise<RefreshTokenResponse> {
    return this.rpc.unary(JonlineLoginDesc, LoginRequest.fromPartial(request), metadata);
  }

  accessToken(request: DeepPartial<AccessTokenRequest>, metadata?: grpc.Metadata): Promise<AccessTokenResponse> {
    return this.rpc.unary(JonlineAccessTokenDesc, AccessTokenRequest.fromPartial(request), metadata);
  }

  getCurrentUser(request: DeepPartial<Empty>, metadata?: grpc.Metadata): Promise<User> {
    return this.rpc.unary(JonlineGetCurrentUserDesc, Empty.fromPartial(request), metadata);
  }

  getUsers(request: DeepPartial<GetUsersRequest>, metadata?: grpc.Metadata): Promise<GetUsersResponse> {
    return this.rpc.unary(JonlineGetUsersDesc, GetUsersRequest.fromPartial(request), metadata);
  }

  updateUser(request: DeepPartial<User>, metadata?: grpc.Metadata): Promise<User> {
    return this.rpc.unary(JonlineUpdateUserDesc, User.fromPartial(request), metadata);
  }

  createFollow(request: DeepPartial<Follow>, metadata?: grpc.Metadata): Promise<Follow> {
    return this.rpc.unary(JonlineCreateFollowDesc, Follow.fromPartial(request), metadata);
  }

  updateFollow(request: DeepPartial<Follow>, metadata?: grpc.Metadata): Promise<Follow> {
    return this.rpc.unary(JonlineUpdateFollowDesc, Follow.fromPartial(request), metadata);
  }

  deleteFollow(request: DeepPartial<Follow>, metadata?: grpc.Metadata): Promise<Empty> {
    return this.rpc.unary(JonlineDeleteFollowDesc, Follow.fromPartial(request), metadata);
  }

  getMedia(request: DeepPartial<GetMediaRequest>, metadata?: grpc.Metadata): Promise<GetMediaResponse> {
    return this.rpc.unary(JonlineGetMediaDesc, GetMediaRequest.fromPartial(request), metadata);
  }

  getGroups(request: DeepPartial<GetGroupsRequest>, metadata?: grpc.Metadata): Promise<GetGroupsResponse> {
    return this.rpc.unary(JonlineGetGroupsDesc, GetGroupsRequest.fromPartial(request), metadata);
  }

  createGroup(request: DeepPartial<Group>, metadata?: grpc.Metadata): Promise<Group> {
    return this.rpc.unary(JonlineCreateGroupDesc, Group.fromPartial(request), metadata);
  }

  updateGroup(request: DeepPartial<Group>, metadata?: grpc.Metadata): Promise<Group> {
    return this.rpc.unary(JonlineUpdateGroupDesc, Group.fromPartial(request), metadata);
  }

  deleteGroup(request: DeepPartial<Group>, metadata?: grpc.Metadata): Promise<Empty> {
    return this.rpc.unary(JonlineDeleteGroupDesc, Group.fromPartial(request), metadata);
  }

  createMembership(request: DeepPartial<Membership>, metadata?: grpc.Metadata): Promise<Membership> {
    return this.rpc.unary(JonlineCreateMembershipDesc, Membership.fromPartial(request), metadata);
  }

  updateMembership(request: DeepPartial<Membership>, metadata?: grpc.Metadata): Promise<Membership> {
    return this.rpc.unary(JonlineUpdateMembershipDesc, Membership.fromPartial(request), metadata);
  }

  deleteMembership(request: DeepPartial<Membership>, metadata?: grpc.Metadata): Promise<Empty> {
    return this.rpc.unary(JonlineDeleteMembershipDesc, Membership.fromPartial(request), metadata);
  }

  getMembers(request: DeepPartial<GetMembersRequest>, metadata?: grpc.Metadata): Promise<GetMembersResponse> {
    return this.rpc.unary(JonlineGetMembersDesc, GetMembersRequest.fromPartial(request), metadata);
  }

  getPosts(request: DeepPartial<GetPostsRequest>, metadata?: grpc.Metadata): Promise<GetPostsResponse> {
    return this.rpc.unary(JonlineGetPostsDesc, GetPostsRequest.fromPartial(request), metadata);
  }

  createPost(request: DeepPartial<Post>, metadata?: grpc.Metadata): Promise<Post> {
    return this.rpc.unary(JonlineCreatePostDesc, Post.fromPartial(request), metadata);
  }

  updatePost(request: DeepPartial<Post>, metadata?: grpc.Metadata): Promise<Post> {
    return this.rpc.unary(JonlineUpdatePostDesc, Post.fromPartial(request), metadata);
  }

  deletePost(request: DeepPartial<Post>, metadata?: grpc.Metadata): Promise<Post> {
    return this.rpc.unary(JonlineDeletePostDesc, Post.fromPartial(request), metadata);
  }

  createGroupPost(request: DeepPartial<GroupPost>, metadata?: grpc.Metadata): Promise<GroupPost> {
    return this.rpc.unary(JonlineCreateGroupPostDesc, GroupPost.fromPartial(request), metadata);
  }

  updateGroupPost(request: DeepPartial<GroupPost>, metadata?: grpc.Metadata): Promise<GroupPost> {
    return this.rpc.unary(JonlineUpdateGroupPostDesc, GroupPost.fromPartial(request), metadata);
  }

  deleteGroupPost(request: DeepPartial<GroupPost>, metadata?: grpc.Metadata): Promise<Empty> {
    return this.rpc.unary(JonlineDeleteGroupPostDesc, GroupPost.fromPartial(request), metadata);
  }

  getGroupPosts(request: DeepPartial<GetGroupPostsRequest>, metadata?: grpc.Metadata): Promise<GetGroupPostsResponse> {
    return this.rpc.unary(JonlineGetGroupPostsDesc, GetGroupPostsRequest.fromPartial(request), metadata);
  }

  streamReplies(request: DeepPartial<Post>, metadata?: grpc.Metadata): Observable<Post> {
    return this.rpc.invoke(JonlineStreamRepliesDesc, Post.fromPartial(request), metadata);
  }

  createEvent(request: DeepPartial<Event>, metadata?: grpc.Metadata): Promise<Event> {
    return this.rpc.unary(JonlineCreateEventDesc, Event.fromPartial(request), metadata);
  }

  getEvents(request: DeepPartial<GetEventsRequest>, metadata?: grpc.Metadata): Promise<GetEventsResponse> {
    return this.rpc.unary(JonlineGetEventsDesc, GetEventsRequest.fromPartial(request), metadata);
  }

  configureServer(request: DeepPartial<ServerConfiguration>, metadata?: grpc.Metadata): Promise<ServerConfiguration> {
    return this.rpc.unary(JonlineConfigureServerDesc, ServerConfiguration.fromPartial(request), metadata);
  }

  resetData(request: DeepPartial<Empty>, metadata?: grpc.Metadata): Promise<Empty> {
    return this.rpc.unary(JonlineResetDataDesc, Empty.fromPartial(request), metadata);
  }
}

export const JonlineDesc = { serviceName: "jonline.Jonline" };

export const JonlineGetServiceVersionDesc: UnaryMethodDefinitionish = {
  methodName: "GetServiceVersion",
  service: JonlineDesc,
  requestStream: false,
  responseStream: false,
  requestType: {
    serializeBinary() {
      return Empty.encode(this).finish();
    },
  } as any,
  responseType: {
    deserializeBinary(data: Uint8Array) {
      const value = GetServiceVersionResponse.decode(data);
      return {
        ...value,
        toObject() {
          return value;
        },
      };
    },
  } as any,
};

export const JonlineGetServerConfigurationDesc: UnaryMethodDefinitionish = {
  methodName: "GetServerConfiguration",
  service: JonlineDesc,
  requestStream: false,
  responseStream: false,
  requestType: {
    serializeBinary() {
      return Empty.encode(this).finish();
    },
  } as any,
  responseType: {
    deserializeBinary(data: Uint8Array) {
      const value = ServerConfiguration.decode(data);
      return {
        ...value,
        toObject() {
          return value;
        },
      };
    },
  } as any,
};

export const JonlineCreateAccountDesc: UnaryMethodDefinitionish = {
  methodName: "CreateAccount",
  service: JonlineDesc,
  requestStream: false,
  responseStream: false,
  requestType: {
    serializeBinary() {
      return CreateAccountRequest.encode(this).finish();
    },
  } as any,
  responseType: {
    deserializeBinary(data: Uint8Array) {
      const value = RefreshTokenResponse.decode(data);
      return {
        ...value,
        toObject() {
          return value;
        },
      };
    },
  } as any,
};

export const JonlineLoginDesc: UnaryMethodDefinitionish = {
  methodName: "Login",
  service: JonlineDesc,
  requestStream: false,
  responseStream: false,
  requestType: {
    serializeBinary() {
      return LoginRequest.encode(this).finish();
    },
  } as any,
  responseType: {
    deserializeBinary(data: Uint8Array) {
      const value = RefreshTokenResponse.decode(data);
      return {
        ...value,
        toObject() {
          return value;
        },
      };
    },
  } as any,
};

export const JonlineAccessTokenDesc: UnaryMethodDefinitionish = {
  methodName: "AccessToken",
  service: JonlineDesc,
  requestStream: false,
  responseStream: false,
  requestType: {
    serializeBinary() {
      return AccessTokenRequest.encode(this).finish();
    },
  } as any,
  responseType: {
    deserializeBinary(data: Uint8Array) {
      const value = AccessTokenResponse.decode(data);
      return {
        ...value,
        toObject() {
          return value;
        },
      };
    },
  } as any,
};

export const JonlineGetCurrentUserDesc: UnaryMethodDefinitionish = {
  methodName: "GetCurrentUser",
  service: JonlineDesc,
  requestStream: false,
  responseStream: false,
  requestType: {
    serializeBinary() {
      return Empty.encode(this).finish();
    },
  } as any,
  responseType: {
    deserializeBinary(data: Uint8Array) {
      const value = User.decode(data);
      return {
        ...value,
        toObject() {
          return value;
        },
      };
    },
  } as any,
};

export const JonlineGetUsersDesc: UnaryMethodDefinitionish = {
  methodName: "GetUsers",
  service: JonlineDesc,
  requestStream: false,
  responseStream: false,
  requestType: {
    serializeBinary() {
      return GetUsersRequest.encode(this).finish();
    },
  } as any,
  responseType: {
    deserializeBinary(data: Uint8Array) {
      const value = GetUsersResponse.decode(data);
      return {
        ...value,
        toObject() {
          return value;
        },
      };
    },
  } as any,
};

export const JonlineUpdateUserDesc: UnaryMethodDefinitionish = {
  methodName: "UpdateUser",
  service: JonlineDesc,
  requestStream: false,
  responseStream: false,
  requestType: {
    serializeBinary() {
      return User.encode(this).finish();
    },
  } as any,
  responseType: {
    deserializeBinary(data: Uint8Array) {
      const value = User.decode(data);
      return {
        ...value,
        toObject() {
          return value;
        },
      };
    },
  } as any,
};

export const JonlineCreateFollowDesc: UnaryMethodDefinitionish = {
  methodName: "CreateFollow",
  service: JonlineDesc,
  requestStream: false,
  responseStream: false,
  requestType: {
    serializeBinary() {
      return Follow.encode(this).finish();
    },
  } as any,
  responseType: {
    deserializeBinary(data: Uint8Array) {
      const value = Follow.decode(data);
      return {
        ...value,
        toObject() {
          return value;
        },
      };
    },
  } as any,
};

export const JonlineUpdateFollowDesc: UnaryMethodDefinitionish = {
  methodName: "UpdateFollow",
  service: JonlineDesc,
  requestStream: false,
  responseStream: false,
  requestType: {
    serializeBinary() {
      return Follow.encode(this).finish();
    },
  } as any,
  responseType: {
    deserializeBinary(data: Uint8Array) {
      const value = Follow.decode(data);
      return {
        ...value,
        toObject() {
          return value;
        },
      };
    },
  } as any,
};

export const JonlineDeleteFollowDesc: UnaryMethodDefinitionish = {
  methodName: "DeleteFollow",
  service: JonlineDesc,
  requestStream: false,
  responseStream: false,
  requestType: {
    serializeBinary() {
      return Follow.encode(this).finish();
    },
  } as any,
  responseType: {
    deserializeBinary(data: Uint8Array) {
      const value = Empty.decode(data);
      return {
        ...value,
        toObject() {
          return value;
        },
      };
    },
  } as any,
};

export const JonlineGetMediaDesc: UnaryMethodDefinitionish = {
  methodName: "GetMedia",
  service: JonlineDesc,
  requestStream: false,
  responseStream: false,
  requestType: {
    serializeBinary() {
      return GetMediaRequest.encode(this).finish();
    },
  } as any,
  responseType: {
    deserializeBinary(data: Uint8Array) {
      const value = GetMediaResponse.decode(data);
      return {
        ...value,
        toObject() {
          return value;
        },
      };
    },
  } as any,
};

export const JonlineGetGroupsDesc: UnaryMethodDefinitionish = {
  methodName: "GetGroups",
  service: JonlineDesc,
  requestStream: false,
  responseStream: false,
  requestType: {
    serializeBinary() {
      return GetGroupsRequest.encode(this).finish();
    },
  } as any,
  responseType: {
    deserializeBinary(data: Uint8Array) {
      const value = GetGroupsResponse.decode(data);
      return {
        ...value,
        toObject() {
          return value;
        },
      };
    },
  } as any,
};

export const JonlineCreateGroupDesc: UnaryMethodDefinitionish = {
  methodName: "CreateGroup",
  service: JonlineDesc,
  requestStream: false,
  responseStream: false,
  requestType: {
    serializeBinary() {
      return Group.encode(this).finish();
    },
  } as any,
  responseType: {
    deserializeBinary(data: Uint8Array) {
      const value = Group.decode(data);
      return {
        ...value,
        toObject() {
          return value;
        },
      };
    },
  } as any,
};

export const JonlineUpdateGroupDesc: UnaryMethodDefinitionish = {
  methodName: "UpdateGroup",
  service: JonlineDesc,
  requestStream: false,
  responseStream: false,
  requestType: {
    serializeBinary() {
      return Group.encode(this).finish();
    },
  } as any,
  responseType: {
    deserializeBinary(data: Uint8Array) {
      const value = Group.decode(data);
      return {
        ...value,
        toObject() {
          return value;
        },
      };
    },
  } as any,
};

export const JonlineDeleteGroupDesc: UnaryMethodDefinitionish = {
  methodName: "DeleteGroup",
  service: JonlineDesc,
  requestStream: false,
  responseStream: false,
  requestType: {
    serializeBinary() {
      return Group.encode(this).finish();
    },
  } as any,
  responseType: {
    deserializeBinary(data: Uint8Array) {
      const value = Empty.decode(data);
      return {
        ...value,
        toObject() {
          return value;
        },
      };
    },
  } as any,
};

export const JonlineCreateMembershipDesc: UnaryMethodDefinitionish = {
  methodName: "CreateMembership",
  service: JonlineDesc,
  requestStream: false,
  responseStream: false,
  requestType: {
    serializeBinary() {
      return Membership.encode(this).finish();
    },
  } as any,
  responseType: {
    deserializeBinary(data: Uint8Array) {
      const value = Membership.decode(data);
      return {
        ...value,
        toObject() {
          return value;
        },
      };
    },
  } as any,
};

export const JonlineUpdateMembershipDesc: UnaryMethodDefinitionish = {
  methodName: "UpdateMembership",
  service: JonlineDesc,
  requestStream: false,
  responseStream: false,
  requestType: {
    serializeBinary() {
      return Membership.encode(this).finish();
    },
  } as any,
  responseType: {
    deserializeBinary(data: Uint8Array) {
      const value = Membership.decode(data);
      return {
        ...value,
        toObject() {
          return value;
        },
      };
    },
  } as any,
};

export const JonlineDeleteMembershipDesc: UnaryMethodDefinitionish = {
  methodName: "DeleteMembership",
  service: JonlineDesc,
  requestStream: false,
  responseStream: false,
  requestType: {
    serializeBinary() {
      return Membership.encode(this).finish();
    },
  } as any,
  responseType: {
    deserializeBinary(data: Uint8Array) {
      const value = Empty.decode(data);
      return {
        ...value,
        toObject() {
          return value;
        },
      };
    },
  } as any,
};

export const JonlineGetMembersDesc: UnaryMethodDefinitionish = {
  methodName: "GetMembers",
  service: JonlineDesc,
  requestStream: false,
  responseStream: false,
  requestType: {
    serializeBinary() {
      return GetMembersRequest.encode(this).finish();
    },
  } as any,
  responseType: {
    deserializeBinary(data: Uint8Array) {
      const value = GetMembersResponse.decode(data);
      return {
        ...value,
        toObject() {
          return value;
        },
      };
    },
  } as any,
};

export const JonlineGetPostsDesc: UnaryMethodDefinitionish = {
  methodName: "GetPosts",
  service: JonlineDesc,
  requestStream: false,
  responseStream: false,
  requestType: {
    serializeBinary() {
      return GetPostsRequest.encode(this).finish();
    },
  } as any,
  responseType: {
    deserializeBinary(data: Uint8Array) {
      const value = GetPostsResponse.decode(data);
      return {
        ...value,
        toObject() {
          return value;
        },
      };
    },
  } as any,
};

export const JonlineCreatePostDesc: UnaryMethodDefinitionish = {
  methodName: "CreatePost",
  service: JonlineDesc,
  requestStream: false,
  responseStream: false,
  requestType: {
    serializeBinary() {
      return Post.encode(this).finish();
    },
  } as any,
  responseType: {
    deserializeBinary(data: Uint8Array) {
      const value = Post.decode(data);
      return {
        ...value,
        toObject() {
          return value;
        },
      };
    },
  } as any,
};

export const JonlineUpdatePostDesc: UnaryMethodDefinitionish = {
  methodName: "UpdatePost",
  service: JonlineDesc,
  requestStream: false,
  responseStream: false,
  requestType: {
    serializeBinary() {
      return Post.encode(this).finish();
    },
  } as any,
  responseType: {
    deserializeBinary(data: Uint8Array) {
      const value = Post.decode(data);
      return {
        ...value,
        toObject() {
          return value;
        },
      };
    },
  } as any,
};

export const JonlineDeletePostDesc: UnaryMethodDefinitionish = {
  methodName: "DeletePost",
  service: JonlineDesc,
  requestStream: false,
  responseStream: false,
  requestType: {
    serializeBinary() {
      return Post.encode(this).finish();
    },
  } as any,
  responseType: {
    deserializeBinary(data: Uint8Array) {
      const value = Post.decode(data);
      return {
        ...value,
        toObject() {
          return value;
        },
      };
    },
  } as any,
};

export const JonlineCreateGroupPostDesc: UnaryMethodDefinitionish = {
  methodName: "CreateGroupPost",
  service: JonlineDesc,
  requestStream: false,
  responseStream: false,
  requestType: {
    serializeBinary() {
      return GroupPost.encode(this).finish();
    },
  } as any,
  responseType: {
    deserializeBinary(data: Uint8Array) {
      const value = GroupPost.decode(data);
      return {
        ...value,
        toObject() {
          return value;
        },
      };
    },
  } as any,
};

export const JonlineUpdateGroupPostDesc: UnaryMethodDefinitionish = {
  methodName: "UpdateGroupPost",
  service: JonlineDesc,
  requestStream: false,
  responseStream: false,
  requestType: {
    serializeBinary() {
      return GroupPost.encode(this).finish();
    },
  } as any,
  responseType: {
    deserializeBinary(data: Uint8Array) {
      const value = GroupPost.decode(data);
      return {
        ...value,
        toObject() {
          return value;
        },
      };
    },
  } as any,
};

export const JonlineDeleteGroupPostDesc: UnaryMethodDefinitionish = {
  methodName: "DeleteGroupPost",
  service: JonlineDesc,
  requestStream: false,
  responseStream: false,
  requestType: {
    serializeBinary() {
      return GroupPost.encode(this).finish();
    },
  } as any,
  responseType: {
    deserializeBinary(data: Uint8Array) {
      const value = Empty.decode(data);
      return {
        ...value,
        toObject() {
          return value;
        },
      };
    },
  } as any,
};

export const JonlineGetGroupPostsDesc: UnaryMethodDefinitionish = {
  methodName: "GetGroupPosts",
  service: JonlineDesc,
  requestStream: false,
  responseStream: false,
  requestType: {
    serializeBinary() {
      return GetGroupPostsRequest.encode(this).finish();
    },
  } as any,
  responseType: {
    deserializeBinary(data: Uint8Array) {
      const value = GetGroupPostsResponse.decode(data);
      return {
        ...value,
        toObject() {
          return value;
        },
      };
    },
  } as any,
};

export const JonlineStreamRepliesDesc: UnaryMethodDefinitionish = {
  methodName: "StreamReplies",
  service: JonlineDesc,
  requestStream: false,
  responseStream: true,
  requestType: {
    serializeBinary() {
      return Post.encode(this).finish();
    },
  } as any,
  responseType: {
    deserializeBinary(data: Uint8Array) {
      const value = Post.decode(data);
      return {
        ...value,
        toObject() {
          return value;
        },
      };
    },
  } as any,
};

export const JonlineCreateEventDesc: UnaryMethodDefinitionish = {
  methodName: "CreateEvent",
  service: JonlineDesc,
  requestStream: false,
  responseStream: false,
  requestType: {
    serializeBinary() {
      return Event.encode(this).finish();
    },
  } as any,
  responseType: {
    deserializeBinary(data: Uint8Array) {
      const value = Event.decode(data);
      return {
        ...value,
        toObject() {
          return value;
        },
      };
    },
  } as any,
};

export const JonlineGetEventsDesc: UnaryMethodDefinitionish = {
  methodName: "GetEvents",
  service: JonlineDesc,
  requestStream: false,
  responseStream: false,
  requestType: {
    serializeBinary() {
      return GetEventsRequest.encode(this).finish();
    },
  } as any,
  responseType: {
    deserializeBinary(data: Uint8Array) {
      const value = GetEventsResponse.decode(data);
      return {
        ...value,
        toObject() {
          return value;
        },
      };
    },
  } as any,
};

export const JonlineConfigureServerDesc: UnaryMethodDefinitionish = {
  methodName: "ConfigureServer",
  service: JonlineDesc,
  requestStream: false,
  responseStream: false,
  requestType: {
    serializeBinary() {
      return ServerConfiguration.encode(this).finish();
    },
  } as any,
  responseType: {
    deserializeBinary(data: Uint8Array) {
      const value = ServerConfiguration.decode(data);
      return {
        ...value,
        toObject() {
          return value;
        },
      };
    },
  } as any,
};

export const JonlineResetDataDesc: UnaryMethodDefinitionish = {
  methodName: "ResetData",
  service: JonlineDesc,
  requestStream: false,
  responseStream: false,
  requestType: {
    serializeBinary() {
      return Empty.encode(this).finish();
    },
  } as any,
  responseType: {
    deserializeBinary(data: Uint8Array) {
      const value = Empty.decode(data);
      return {
        ...value,
        toObject() {
          return value;
        },
      };
    },
  } as any,
};

interface UnaryMethodDefinitionishR extends grpc.UnaryMethodDefinition<any, any> {
  requestStream: any;
  responseStream: any;
}

type UnaryMethodDefinitionish = UnaryMethodDefinitionishR;

interface Rpc {
  unary<T extends UnaryMethodDefinitionish>(
    methodDesc: T,
    request: any,
    metadata: grpc.Metadata | undefined,
  ): Promise<any>;
  invoke<T extends UnaryMethodDefinitionish>(
    methodDesc: T,
    request: any,
    metadata: grpc.Metadata | undefined,
  ): Observable<any>;
}

export class GrpcWebImpl {
  private host: string;
  private options: {
    transport?: grpc.TransportFactory;
    streamingTransport?: grpc.TransportFactory;
    debug?: boolean;
    metadata?: grpc.Metadata;
    upStreamRetryCodes?: number[];
  };

  constructor(
    host: string,
    options: {
      transport?: grpc.TransportFactory;
      streamingTransport?: grpc.TransportFactory;
      debug?: boolean;
      metadata?: grpc.Metadata;
      upStreamRetryCodes?: number[];
    },
  ) {
    this.host = host;
    this.options = options;
  }

  unary<T extends UnaryMethodDefinitionish>(
    methodDesc: T,
    _request: any,
    metadata: grpc.Metadata | undefined,
  ): Promise<any> {
    const request = { ..._request, ...methodDesc.requestType };
    const maybeCombinedMetadata = metadata && this.options.metadata
      ? new BrowserHeaders({ ...this.options?.metadata.headersMap, ...metadata?.headersMap })
      : metadata || this.options.metadata;
    return new Promise((resolve, reject) => {
      grpc.unary(methodDesc, {
        request,
        host: this.host,
        metadata: maybeCombinedMetadata,
        transport: this.options.transport,
        debug: this.options.debug,
        onEnd: function (response) {
          if (response.status === grpc.Code.OK) {
            resolve(response.message!.toObject());
          } else {
            const err = new GrpcWebError(response.statusMessage, response.status, response.trailers);
            reject(err);
          }
        },
      });
    });
  }

  invoke<T extends UnaryMethodDefinitionish>(
    methodDesc: T,
    _request: any,
    metadata: grpc.Metadata | undefined,
  ): Observable<any> {
    const upStreamCodes = this.options.upStreamRetryCodes || [];
    const DEFAULT_TIMEOUT_TIME: number = 3_000;
    const request = { ..._request, ...methodDesc.requestType };
    const maybeCombinedMetadata = metadata && this.options.metadata
      ? new BrowserHeaders({ ...this.options?.metadata.headersMap, ...metadata?.headersMap })
      : metadata || this.options.metadata;
    return new Observable((observer) => {
      const upStream = (() => {
        const client = grpc.invoke(methodDesc, {
          host: this.host,
          request,
          transport: this.options.streamingTransport || this.options.transport,
          metadata: maybeCombinedMetadata,
          debug: this.options.debug,
          onMessage: (next) => observer.next(next),
          onEnd: (code: grpc.Code, message: string, trailers: grpc.Metadata) => {
            if (code === 0) {
              observer.complete();
            } else if (upStreamCodes.includes(code)) {
              setTimeout(upStream, DEFAULT_TIMEOUT_TIME);
            } else {
              const err = new Error(message) as any;
              err.code = code;
              err.metadata = trailers;
              observer.error(err);
            }
          },
        });
        observer.add(() => client.close());
      });
      upStream();
    }).pipe(share());
  }
}

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

type Builtin = Date | Function | Uint8Array | string | number | boolean | undefined;

export type DeepPartial<T> = T extends Builtin ? T
  : T extends Array<infer U> ? Array<DeepPartial<U>> : T extends ReadonlyArray<infer U> ? ReadonlyArray<DeepPartial<U>>
  : T extends {} ? { [K in keyof T]?: DeepPartial<T[K]> }
  : Partial<T>;

export class GrpcWebError extends tsProtoGlobalThis.Error {
  constructor(message: string, public code: grpc.Code, public metadata: grpc.Metadata) {
    super(message);
  }
}
