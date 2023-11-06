/* eslint-disable */
import _m0 from "protobufjs/minimal";
import { Timestamp } from "./google/protobuf/timestamp";
import { MediaReference } from "./media";
import { Author } from "./users";
import {
  Moderation,
  moderationFromJSON,
  moderationToJSON,
  Visibility,
  visibilityFromJSON,
  visibilityToJSON,
} from "./visibility_moderation";

export const protobufPackage = "jonline";

/** A high-level enumeration of general ways of requesting posts. */
export enum PostListingType {
  /**
   * PUBLIC_POSTS - Gets SERVER_PUBLIC and GLOBAL_PUBLIC posts as is sensible.
   * Also usable for getting replies anywhere.
   */
  PUBLIC_POSTS = 0,
  /** FOLLOWING_POSTS - Returns posts from users the user is following. */
  FOLLOWING_POSTS = 1,
  /** MY_GROUPS_POSTS - Returns posts from any group the user is a member of. */
  MY_GROUPS_POSTS = 2,
  /** DIRECT_POSTS - Returns `DIRECT` posts that are directly addressed to the user. */
  DIRECT_POSTS = 3,
  POSTS_PENDING_MODERATION = 4,
  /** GROUP_POSTS - group_id parameter is required for these. */
  GROUP_POSTS = 10,
  GROUP_POSTS_PENDING_MODERATION = 11,
  UNRECOGNIZED = -1,
}

export function postListingTypeFromJSON(object: any): PostListingType {
  switch (object) {
    case 0:
    case "PUBLIC_POSTS":
      return PostListingType.PUBLIC_POSTS;
    case 1:
    case "FOLLOWING_POSTS":
      return PostListingType.FOLLOWING_POSTS;
    case 2:
    case "MY_GROUPS_POSTS":
      return PostListingType.MY_GROUPS_POSTS;
    case 3:
    case "DIRECT_POSTS":
      return PostListingType.DIRECT_POSTS;
    case 4:
    case "POSTS_PENDING_MODERATION":
      return PostListingType.POSTS_PENDING_MODERATION;
    case 10:
    case "GROUP_POSTS":
      return PostListingType.GROUP_POSTS;
    case 11:
    case "GROUP_POSTS_PENDING_MODERATION":
      return PostListingType.GROUP_POSTS_PENDING_MODERATION;
    case -1:
    case "UNRECOGNIZED":
    default:
      return PostListingType.UNRECOGNIZED;
  }
}

export function postListingTypeToJSON(object: PostListingType): string {
  switch (object) {
    case PostListingType.PUBLIC_POSTS:
      return "PUBLIC_POSTS";
    case PostListingType.FOLLOWING_POSTS:
      return "FOLLOWING_POSTS";
    case PostListingType.MY_GROUPS_POSTS:
      return "MY_GROUPS_POSTS";
    case PostListingType.DIRECT_POSTS:
      return "DIRECT_POSTS";
    case PostListingType.POSTS_PENDING_MODERATION:
      return "POSTS_PENDING_MODERATION";
    case PostListingType.GROUP_POSTS:
      return "GROUP_POSTS";
    case PostListingType.GROUP_POSTS_PENDING_MODERATION:
      return "GROUP_POSTS_PENDING_MODERATION";
    case PostListingType.UNRECOGNIZED:
    default:
      return "UNRECOGNIZED";
  }
}

export enum PostContext {
  POST = 0,
  REPLY = 1,
  EVENT = 2,
  EVENT_INSTANCE = 3,
  UNRECOGNIZED = -1,
}

export function postContextFromJSON(object: any): PostContext {
  switch (object) {
    case 0:
    case "POST":
      return PostContext.POST;
    case 1:
    case "REPLY":
      return PostContext.REPLY;
    case 2:
    case "EVENT":
      return PostContext.EVENT;
    case 3:
    case "EVENT_INSTANCE":
      return PostContext.EVENT_INSTANCE;
    case -1:
    case "UNRECOGNIZED":
    default:
      return PostContext.UNRECOGNIZED;
  }
}

export function postContextToJSON(object: PostContext): string {
  switch (object) {
    case PostContext.POST:
      return "POST";
    case PostContext.REPLY:
      return "REPLY";
    case PostContext.EVENT:
      return "EVENT";
    case PostContext.EVENT_INSTANCE:
      return "EVENT_INSTANCE";
    case PostContext.UNRECOGNIZED:
    default:
      return "UNRECOGNIZED";
  }
}

/**
 * Valid GetPostsRequest formats:
 *
 * - `{[listing_type: PublicPosts]}`
 *     - Get ServerPublic/GlobalPublic posts you can see based on your authorization (or lack thereof).
 * - `{listing_type:MyGroupsPosts|FollowingPosts}`
 *     - Get posts from groups you're a member of or from users you're following. Authorization required.
 * - `{post_id:}`
 *     - Get one post ,including preview data/
 * - `{post_id:, reply_depth: 1}`
 *     - Get replies to a post - only support for replyDepth=1 is done for now though.
 * - `{listing_type: MyGroupsPosts|GroupPostsPendingModeration, group_id:}`
 *     - Get posts/posts needing moderation for a group. Authorization may be required depending on group visibility.
 * - `{author_user_id:, group_id:}`
 *     - Get posts by a user for a group. (TODO)
 * - `{listing_type: AuthorPosts, author_user_id:}`
 *     - Get posts by a user. (TODO)
 */
export interface GetPostsRequest {
  /** Returns the single post with the given ID. */
  postId?:
    | string
    | undefined;
  /**
   * Limits results to replies to the given post.
   * optional string replies_to_post_id = 2;
   * Limits results to those by the given author user ID.
   */
  authorUserId?: string | undefined;
  groupId?:
    | string
    | undefined;
  /** Only supported for depth=2 for now. */
  replyDepth?:
    | number
    | undefined;
  /** Only POST and REPLY are supported for now. */
  context?: PostContext | undefined;
  listingType: PostListingType;
  page: number;
}

export interface GetPostsResponse {
  posts: Post[];
}

/**
 * A `Post` is a message that can be posted to the server. Its `visibility`
 * as well as any associated `GroupPost`s and `UserPost`s determine what users
 * see it and where.
 *
 * `Post`s are also a fundamental unit of the system. They provide a building block
 * of Visibility and Moderation management that is used throughout Posts, Replies, Events,
 * and Event Instances.
 */
export interface Post {
  /** Unique ID of the post. */
  id: string;
  /** The author of the post. This is a smaller version of User. */
  author?:
    | Author
    | undefined;
  /** If this is a reply, this is the ID of the post it's replying to. */
  replyToPostId?:
    | string
    | undefined;
  /** The title of the post. This is invalid for replies. */
  title?:
    | string
    | undefined;
  /** The link of the post. This is invalid for replies. */
  link?:
    | string
    | undefined;
  /** The content of the post. This is required for replies. */
  content?:
    | string
    | undefined;
  /** The number of responses (replies *and* replies to replies, etc.) to this post. */
  responseCount: number;
  /** The number of *direct* replies to this post. */
  replyCount: number;
  /** The number of groups this post is in. */
  groupCount: number;
  /** List of Media IDs associated with this post. Order is preserved. */
  media: MediaReference[];
  /**
   * Flag indicating whether Media has been generated for this Post.
   * Currently previews are generated for any Link post.
   */
  mediaGenerated: boolean;
  /** Flag indicating */
  embedLink: boolean;
  /**
   * Flag indicating a `LIMITED` or `SERVER_PUBLIC` post can be shared with groups and individuals,
   * and a `DIRECT` post can be shared with individuals.
   */
  shareable: boolean;
  /** Context of the Post (`POST`, `REPLY`, `EVENT`, or `EVENT_INSTANCE`.) */
  context: PostContext;
  /** The visibility of the Post. */
  visibility: Visibility;
  /** The moderation of the Post. */
  moderation: Moderation;
  /**
   * If the Post was retrieved from GetPosts with a group_id, the GroupPost
   * metadata may be returned along with the Post.
   */
  currentGroupPost?:
    | GroupPost
    | undefined;
  /**
   * Hierarchical replies to this post.
   *
   * There will never be more than `reply_count` replies. However,
   * there may be fewer than `reply_count` replies if some replies are
   * hidden by moderation or visibility.
   * Replies are not generally loaded by default, but can be added to Posts
   * in the frontend.
   */
  replies: Post[];
  createdAt: string | undefined;
  updatedAt?: string | undefined;
  publishedAt?: string | undefined;
  lastActivityAt: string | undefined;
}

/**
 * A `GroupPost` is a cross-post of a `Post` to a `Group`. It contains
 * information about the moderation of the post in the group, as well as
 * the time it was cross-posted and the user who did the cross-posting.
 */
export interface GroupPost {
  groupId: string;
  postId: string;
  userId: string;
  groupModeration: Moderation;
  createdAt: string | undefined;
}

/** A `UserPost` is a "direct share" of a `Post` to a `User`. Currently unused. */
export interface UserPost {
  groupId: string;
  userId: string;
  createdAt: string | undefined;
}

/** Used for getting context about GroupPosts of an existing Post. */
export interface GetGroupPostsRequest {
  postId: string;
  groupId?: string | undefined;
}

/** Used for getting context about GroupPosts of an existing Post. */
export interface GetGroupPostsResponse {
  groupPosts: GroupPost[];
}

function createBaseGetPostsRequest(): GetPostsRequest {
  return {
    postId: undefined,
    authorUserId: undefined,
    groupId: undefined,
    replyDepth: undefined,
    context: undefined,
    listingType: 0,
    page: 0,
  };
}

export const GetPostsRequest = {
  encode(message: GetPostsRequest, writer: _m0.Writer = _m0.Writer.create()): _m0.Writer {
    if (message.postId !== undefined) {
      writer.uint32(10).string(message.postId);
    }
    if (message.authorUserId !== undefined) {
      writer.uint32(18).string(message.authorUserId);
    }
    if (message.groupId !== undefined) {
      writer.uint32(26).string(message.groupId);
    }
    if (message.replyDepth !== undefined) {
      writer.uint32(32).uint32(message.replyDepth);
    }
    if (message.context !== undefined) {
      writer.uint32(40).int32(message.context);
    }
    if (message.listingType !== 0) {
      writer.uint32(80).int32(message.listingType);
    }
    if (message.page !== 0) {
      writer.uint32(120).uint32(message.page);
    }
    return writer;
  },

  decode(input: _m0.Reader | Uint8Array, length?: number): GetPostsRequest {
    const reader = input instanceof _m0.Reader ? input : _m0.Reader.create(input);
    let end = length === undefined ? reader.len : reader.pos + length;
    const message = createBaseGetPostsRequest();
    while (reader.pos < end) {
      const tag = reader.uint32();
      switch (tag >>> 3) {
        case 1:
          if (tag !== 10) {
            break;
          }

          message.postId = reader.string();
          continue;
        case 2:
          if (tag !== 18) {
            break;
          }

          message.authorUserId = reader.string();
          continue;
        case 3:
          if (tag !== 26) {
            break;
          }

          message.groupId = reader.string();
          continue;
        case 4:
          if (tag !== 32) {
            break;
          }

          message.replyDepth = reader.uint32();
          continue;
        case 5:
          if (tag !== 40) {
            break;
          }

          message.context = reader.int32() as any;
          continue;
        case 10:
          if (tag !== 80) {
            break;
          }

          message.listingType = reader.int32() as any;
          continue;
        case 15:
          if (tag !== 120) {
            break;
          }

          message.page = reader.uint32();
          continue;
      }
      if ((tag & 7) === 4 || tag === 0) {
        break;
      }
      reader.skipType(tag & 7);
    }
    return message;
  },

  fromJSON(object: any): GetPostsRequest {
    return {
      postId: isSet(object.postId) ? globalThis.String(object.postId) : undefined,
      authorUserId: isSet(object.authorUserId) ? globalThis.String(object.authorUserId) : undefined,
      groupId: isSet(object.groupId) ? globalThis.String(object.groupId) : undefined,
      replyDepth: isSet(object.replyDepth) ? globalThis.Number(object.replyDepth) : undefined,
      context: isSet(object.context) ? postContextFromJSON(object.context) : undefined,
      listingType: isSet(object.listingType) ? postListingTypeFromJSON(object.listingType) : 0,
      page: isSet(object.page) ? globalThis.Number(object.page) : 0,
    };
  },

  toJSON(message: GetPostsRequest): unknown {
    const obj: any = {};
    if (message.postId !== undefined) {
      obj.postId = message.postId;
    }
    if (message.authorUserId !== undefined) {
      obj.authorUserId = message.authorUserId;
    }
    if (message.groupId !== undefined) {
      obj.groupId = message.groupId;
    }
    if (message.replyDepth !== undefined) {
      obj.replyDepth = Math.round(message.replyDepth);
    }
    if (message.context !== undefined) {
      obj.context = postContextToJSON(message.context);
    }
    if (message.listingType !== 0) {
      obj.listingType = postListingTypeToJSON(message.listingType);
    }
    if (message.page !== 0) {
      obj.page = Math.round(message.page);
    }
    return obj;
  },

  create<I extends Exact<DeepPartial<GetPostsRequest>, I>>(base?: I): GetPostsRequest {
    return GetPostsRequest.fromPartial(base ?? ({} as any));
  },
  fromPartial<I extends Exact<DeepPartial<GetPostsRequest>, I>>(object: I): GetPostsRequest {
    const message = createBaseGetPostsRequest();
    message.postId = object.postId ?? undefined;
    message.authorUserId = object.authorUserId ?? undefined;
    message.groupId = object.groupId ?? undefined;
    message.replyDepth = object.replyDepth ?? undefined;
    message.context = object.context ?? undefined;
    message.listingType = object.listingType ?? 0;
    message.page = object.page ?? 0;
    return message;
  },
};

function createBaseGetPostsResponse(): GetPostsResponse {
  return { posts: [] };
}

export const GetPostsResponse = {
  encode(message: GetPostsResponse, writer: _m0.Writer = _m0.Writer.create()): _m0.Writer {
    for (const v of message.posts) {
      Post.encode(v!, writer.uint32(10).fork()).ldelim();
    }
    return writer;
  },

  decode(input: _m0.Reader | Uint8Array, length?: number): GetPostsResponse {
    const reader = input instanceof _m0.Reader ? input : _m0.Reader.create(input);
    let end = length === undefined ? reader.len : reader.pos + length;
    const message = createBaseGetPostsResponse();
    while (reader.pos < end) {
      const tag = reader.uint32();
      switch (tag >>> 3) {
        case 1:
          if (tag !== 10) {
            break;
          }

          message.posts.push(Post.decode(reader, reader.uint32()));
          continue;
      }
      if ((tag & 7) === 4 || tag === 0) {
        break;
      }
      reader.skipType(tag & 7);
    }
    return message;
  },

  fromJSON(object: any): GetPostsResponse {
    return { posts: globalThis.Array.isArray(object?.posts) ? object.posts.map((e: any) => Post.fromJSON(e)) : [] };
  },

  toJSON(message: GetPostsResponse): unknown {
    const obj: any = {};
    if (message.posts?.length) {
      obj.posts = message.posts.map((e) => Post.toJSON(e));
    }
    return obj;
  },

  create<I extends Exact<DeepPartial<GetPostsResponse>, I>>(base?: I): GetPostsResponse {
    return GetPostsResponse.fromPartial(base ?? ({} as any));
  },
  fromPartial<I extends Exact<DeepPartial<GetPostsResponse>, I>>(object: I): GetPostsResponse {
    const message = createBaseGetPostsResponse();
    message.posts = object.posts?.map((e) => Post.fromPartial(e)) || [];
    return message;
  },
};

function createBasePost(): Post {
  return {
    id: "",
    author: undefined,
    replyToPostId: undefined,
    title: undefined,
    link: undefined,
    content: undefined,
    responseCount: 0,
    replyCount: 0,
    groupCount: 0,
    media: [],
    mediaGenerated: false,
    embedLink: false,
    shareable: false,
    context: 0,
    visibility: 0,
    moderation: 0,
    currentGroupPost: undefined,
    replies: [],
    createdAt: undefined,
    updatedAt: undefined,
    publishedAt: undefined,
    lastActivityAt: undefined,
  };
}

export const Post = {
  encode(message: Post, writer: _m0.Writer = _m0.Writer.create()): _m0.Writer {
    if (message.id !== "") {
      writer.uint32(10).string(message.id);
    }
    if (message.author !== undefined) {
      Author.encode(message.author, writer.uint32(18).fork()).ldelim();
    }
    if (message.replyToPostId !== undefined) {
      writer.uint32(26).string(message.replyToPostId);
    }
    if (message.title !== undefined) {
      writer.uint32(34).string(message.title);
    }
    if (message.link !== undefined) {
      writer.uint32(42).string(message.link);
    }
    if (message.content !== undefined) {
      writer.uint32(50).string(message.content);
    }
    if (message.responseCount !== 0) {
      writer.uint32(56).int32(message.responseCount);
    }
    if (message.replyCount !== 0) {
      writer.uint32(64).int32(message.replyCount);
    }
    if (message.groupCount !== 0) {
      writer.uint32(72).int32(message.groupCount);
    }
    for (const v of message.media) {
      MediaReference.encode(v!, writer.uint32(82).fork()).ldelim();
    }
    if (message.mediaGenerated === true) {
      writer.uint32(88).bool(message.mediaGenerated);
    }
    if (message.embedLink === true) {
      writer.uint32(96).bool(message.embedLink);
    }
    if (message.shareable === true) {
      writer.uint32(104).bool(message.shareable);
    }
    if (message.context !== 0) {
      writer.uint32(112).int32(message.context);
    }
    if (message.visibility !== 0) {
      writer.uint32(120).int32(message.visibility);
    }
    if (message.moderation !== 0) {
      writer.uint32(128).int32(message.moderation);
    }
    if (message.currentGroupPost !== undefined) {
      GroupPost.encode(message.currentGroupPost, writer.uint32(146).fork()).ldelim();
    }
    for (const v of message.replies) {
      Post.encode(v!, writer.uint32(154).fork()).ldelim();
    }
    if (message.createdAt !== undefined) {
      Timestamp.encode(toTimestamp(message.createdAt), writer.uint32(162).fork()).ldelim();
    }
    if (message.updatedAt !== undefined) {
      Timestamp.encode(toTimestamp(message.updatedAt), writer.uint32(170).fork()).ldelim();
    }
    if (message.publishedAt !== undefined) {
      Timestamp.encode(toTimestamp(message.publishedAt), writer.uint32(178).fork()).ldelim();
    }
    if (message.lastActivityAt !== undefined) {
      Timestamp.encode(toTimestamp(message.lastActivityAt), writer.uint32(186).fork()).ldelim();
    }
    return writer;
  },

  decode(input: _m0.Reader | Uint8Array, length?: number): Post {
    const reader = input instanceof _m0.Reader ? input : _m0.Reader.create(input);
    let end = length === undefined ? reader.len : reader.pos + length;
    const message = createBasePost();
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

          message.author = Author.decode(reader, reader.uint32());
          continue;
        case 3:
          if (tag !== 26) {
            break;
          }

          message.replyToPostId = reader.string();
          continue;
        case 4:
          if (tag !== 34) {
            break;
          }

          message.title = reader.string();
          continue;
        case 5:
          if (tag !== 42) {
            break;
          }

          message.link = reader.string();
          continue;
        case 6:
          if (tag !== 50) {
            break;
          }

          message.content = reader.string();
          continue;
        case 7:
          if (tag !== 56) {
            break;
          }

          message.responseCount = reader.int32();
          continue;
        case 8:
          if (tag !== 64) {
            break;
          }

          message.replyCount = reader.int32();
          continue;
        case 9:
          if (tag !== 72) {
            break;
          }

          message.groupCount = reader.int32();
          continue;
        case 10:
          if (tag !== 82) {
            break;
          }

          message.media.push(MediaReference.decode(reader, reader.uint32()));
          continue;
        case 11:
          if (tag !== 88) {
            break;
          }

          message.mediaGenerated = reader.bool();
          continue;
        case 12:
          if (tag !== 96) {
            break;
          }

          message.embedLink = reader.bool();
          continue;
        case 13:
          if (tag !== 104) {
            break;
          }

          message.shareable = reader.bool();
          continue;
        case 14:
          if (tag !== 112) {
            break;
          }

          message.context = reader.int32() as any;
          continue;
        case 15:
          if (tag !== 120) {
            break;
          }

          message.visibility = reader.int32() as any;
          continue;
        case 16:
          if (tag !== 128) {
            break;
          }

          message.moderation = reader.int32() as any;
          continue;
        case 18:
          if (tag !== 146) {
            break;
          }

          message.currentGroupPost = GroupPost.decode(reader, reader.uint32());
          continue;
        case 19:
          if (tag !== 154) {
            break;
          }

          message.replies.push(Post.decode(reader, reader.uint32()));
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
        case 22:
          if (tag !== 178) {
            break;
          }

          message.publishedAt = fromTimestamp(Timestamp.decode(reader, reader.uint32()));
          continue;
        case 23:
          if (tag !== 186) {
            break;
          }

          message.lastActivityAt = fromTimestamp(Timestamp.decode(reader, reader.uint32()));
          continue;
      }
      if ((tag & 7) === 4 || tag === 0) {
        break;
      }
      reader.skipType(tag & 7);
    }
    return message;
  },

  fromJSON(object: any): Post {
    return {
      id: isSet(object.id) ? globalThis.String(object.id) : "",
      author: isSet(object.author) ? Author.fromJSON(object.author) : undefined,
      replyToPostId: isSet(object.replyToPostId) ? globalThis.String(object.replyToPostId) : undefined,
      title: isSet(object.title) ? globalThis.String(object.title) : undefined,
      link: isSet(object.link) ? globalThis.String(object.link) : undefined,
      content: isSet(object.content) ? globalThis.String(object.content) : undefined,
      responseCount: isSet(object.responseCount) ? globalThis.Number(object.responseCount) : 0,
      replyCount: isSet(object.replyCount) ? globalThis.Number(object.replyCount) : 0,
      groupCount: isSet(object.groupCount) ? globalThis.Number(object.groupCount) : 0,
      media: globalThis.Array.isArray(object?.media) ? object.media.map((e: any) => MediaReference.fromJSON(e)) : [],
      mediaGenerated: isSet(object.mediaGenerated) ? globalThis.Boolean(object.mediaGenerated) : false,
      embedLink: isSet(object.embedLink) ? globalThis.Boolean(object.embedLink) : false,
      shareable: isSet(object.shareable) ? globalThis.Boolean(object.shareable) : false,
      context: isSet(object.context) ? postContextFromJSON(object.context) : 0,
      visibility: isSet(object.visibility) ? visibilityFromJSON(object.visibility) : 0,
      moderation: isSet(object.moderation) ? moderationFromJSON(object.moderation) : 0,
      currentGroupPost: isSet(object.currentGroupPost) ? GroupPost.fromJSON(object.currentGroupPost) : undefined,
      replies: globalThis.Array.isArray(object?.replies) ? object.replies.map((e: any) => Post.fromJSON(e)) : [],
      createdAt: isSet(object.createdAt) ? globalThis.String(object.createdAt) : undefined,
      updatedAt: isSet(object.updatedAt) ? globalThis.String(object.updatedAt) : undefined,
      publishedAt: isSet(object.publishedAt) ? globalThis.String(object.publishedAt) : undefined,
      lastActivityAt: isSet(object.lastActivityAt) ? globalThis.String(object.lastActivityAt) : undefined,
    };
  },

  toJSON(message: Post): unknown {
    const obj: any = {};
    if (message.id !== "") {
      obj.id = message.id;
    }
    if (message.author !== undefined) {
      obj.author = Author.toJSON(message.author);
    }
    if (message.replyToPostId !== undefined) {
      obj.replyToPostId = message.replyToPostId;
    }
    if (message.title !== undefined) {
      obj.title = message.title;
    }
    if (message.link !== undefined) {
      obj.link = message.link;
    }
    if (message.content !== undefined) {
      obj.content = message.content;
    }
    if (message.responseCount !== 0) {
      obj.responseCount = Math.round(message.responseCount);
    }
    if (message.replyCount !== 0) {
      obj.replyCount = Math.round(message.replyCount);
    }
    if (message.groupCount !== 0) {
      obj.groupCount = Math.round(message.groupCount);
    }
    if (message.media?.length) {
      obj.media = message.media.map((e) => MediaReference.toJSON(e));
    }
    if (message.mediaGenerated === true) {
      obj.mediaGenerated = message.mediaGenerated;
    }
    if (message.embedLink === true) {
      obj.embedLink = message.embedLink;
    }
    if (message.shareable === true) {
      obj.shareable = message.shareable;
    }
    if (message.context !== 0) {
      obj.context = postContextToJSON(message.context);
    }
    if (message.visibility !== 0) {
      obj.visibility = visibilityToJSON(message.visibility);
    }
    if (message.moderation !== 0) {
      obj.moderation = moderationToJSON(message.moderation);
    }
    if (message.currentGroupPost !== undefined) {
      obj.currentGroupPost = GroupPost.toJSON(message.currentGroupPost);
    }
    if (message.replies?.length) {
      obj.replies = message.replies.map((e) => Post.toJSON(e));
    }
    if (message.createdAt !== undefined) {
      obj.createdAt = message.createdAt;
    }
    if (message.updatedAt !== undefined) {
      obj.updatedAt = message.updatedAt;
    }
    if (message.publishedAt !== undefined) {
      obj.publishedAt = message.publishedAt;
    }
    if (message.lastActivityAt !== undefined) {
      obj.lastActivityAt = message.lastActivityAt;
    }
    return obj;
  },

  create<I extends Exact<DeepPartial<Post>, I>>(base?: I): Post {
    return Post.fromPartial(base ?? ({} as any));
  },
  fromPartial<I extends Exact<DeepPartial<Post>, I>>(object: I): Post {
    const message = createBasePost();
    message.id = object.id ?? "";
    message.author = (object.author !== undefined && object.author !== null)
      ? Author.fromPartial(object.author)
      : undefined;
    message.replyToPostId = object.replyToPostId ?? undefined;
    message.title = object.title ?? undefined;
    message.link = object.link ?? undefined;
    message.content = object.content ?? undefined;
    message.responseCount = object.responseCount ?? 0;
    message.replyCount = object.replyCount ?? 0;
    message.groupCount = object.groupCount ?? 0;
    message.media = object.media?.map((e) => MediaReference.fromPartial(e)) || [];
    message.mediaGenerated = object.mediaGenerated ?? false;
    message.embedLink = object.embedLink ?? false;
    message.shareable = object.shareable ?? false;
    message.context = object.context ?? 0;
    message.visibility = object.visibility ?? 0;
    message.moderation = object.moderation ?? 0;
    message.currentGroupPost = (object.currentGroupPost !== undefined && object.currentGroupPost !== null)
      ? GroupPost.fromPartial(object.currentGroupPost)
      : undefined;
    message.replies = object.replies?.map((e) => Post.fromPartial(e)) || [];
    message.createdAt = object.createdAt ?? undefined;
    message.updatedAt = object.updatedAt ?? undefined;
    message.publishedAt = object.publishedAt ?? undefined;
    message.lastActivityAt = object.lastActivityAt ?? undefined;
    return message;
  },
};

function createBaseGroupPost(): GroupPost {
  return { groupId: "", postId: "", userId: "", groupModeration: 0, createdAt: undefined };
}

export const GroupPost = {
  encode(message: GroupPost, writer: _m0.Writer = _m0.Writer.create()): _m0.Writer {
    if (message.groupId !== "") {
      writer.uint32(10).string(message.groupId);
    }
    if (message.postId !== "") {
      writer.uint32(18).string(message.postId);
    }
    if (message.userId !== "") {
      writer.uint32(26).string(message.userId);
    }
    if (message.groupModeration !== 0) {
      writer.uint32(32).int32(message.groupModeration);
    }
    if (message.createdAt !== undefined) {
      Timestamp.encode(toTimestamp(message.createdAt), writer.uint32(42).fork()).ldelim();
    }
    return writer;
  },

  decode(input: _m0.Reader | Uint8Array, length?: number): GroupPost {
    const reader = input instanceof _m0.Reader ? input : _m0.Reader.create(input);
    let end = length === undefined ? reader.len : reader.pos + length;
    const message = createBaseGroupPost();
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

          message.postId = reader.string();
          continue;
        case 3:
          if (tag !== 26) {
            break;
          }

          message.userId = reader.string();
          continue;
        case 4:
          if (tag !== 32) {
            break;
          }

          message.groupModeration = reader.int32() as any;
          continue;
        case 5:
          if (tag !== 42) {
            break;
          }

          message.createdAt = fromTimestamp(Timestamp.decode(reader, reader.uint32()));
          continue;
      }
      if ((tag & 7) === 4 || tag === 0) {
        break;
      }
      reader.skipType(tag & 7);
    }
    return message;
  },

  fromJSON(object: any): GroupPost {
    return {
      groupId: isSet(object.groupId) ? globalThis.String(object.groupId) : "",
      postId: isSet(object.postId) ? globalThis.String(object.postId) : "",
      userId: isSet(object.userId) ? globalThis.String(object.userId) : "",
      groupModeration: isSet(object.groupModeration) ? moderationFromJSON(object.groupModeration) : 0,
      createdAt: isSet(object.createdAt) ? globalThis.String(object.createdAt) : undefined,
    };
  },

  toJSON(message: GroupPost): unknown {
    const obj: any = {};
    if (message.groupId !== "") {
      obj.groupId = message.groupId;
    }
    if (message.postId !== "") {
      obj.postId = message.postId;
    }
    if (message.userId !== "") {
      obj.userId = message.userId;
    }
    if (message.groupModeration !== 0) {
      obj.groupModeration = moderationToJSON(message.groupModeration);
    }
    if (message.createdAt !== undefined) {
      obj.createdAt = message.createdAt;
    }
    return obj;
  },

  create<I extends Exact<DeepPartial<GroupPost>, I>>(base?: I): GroupPost {
    return GroupPost.fromPartial(base ?? ({} as any));
  },
  fromPartial<I extends Exact<DeepPartial<GroupPost>, I>>(object: I): GroupPost {
    const message = createBaseGroupPost();
    message.groupId = object.groupId ?? "";
    message.postId = object.postId ?? "";
    message.userId = object.userId ?? "";
    message.groupModeration = object.groupModeration ?? 0;
    message.createdAt = object.createdAt ?? undefined;
    return message;
  },
};

function createBaseUserPost(): UserPost {
  return { groupId: "", userId: "", createdAt: undefined };
}

export const UserPost = {
  encode(message: UserPost, writer: _m0.Writer = _m0.Writer.create()): _m0.Writer {
    if (message.groupId !== "") {
      writer.uint32(10).string(message.groupId);
    }
    if (message.userId !== "") {
      writer.uint32(18).string(message.userId);
    }
    if (message.createdAt !== undefined) {
      Timestamp.encode(toTimestamp(message.createdAt), writer.uint32(26).fork()).ldelim();
    }
    return writer;
  },

  decode(input: _m0.Reader | Uint8Array, length?: number): UserPost {
    const reader = input instanceof _m0.Reader ? input : _m0.Reader.create(input);
    let end = length === undefined ? reader.len : reader.pos + length;
    const message = createBaseUserPost();
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

          message.userId = reader.string();
          continue;
        case 3:
          if (tag !== 26) {
            break;
          }

          message.createdAt = fromTimestamp(Timestamp.decode(reader, reader.uint32()));
          continue;
      }
      if ((tag & 7) === 4 || tag === 0) {
        break;
      }
      reader.skipType(tag & 7);
    }
    return message;
  },

  fromJSON(object: any): UserPost {
    return {
      groupId: isSet(object.groupId) ? globalThis.String(object.groupId) : "",
      userId: isSet(object.userId) ? globalThis.String(object.userId) : "",
      createdAt: isSet(object.createdAt) ? globalThis.String(object.createdAt) : undefined,
    };
  },

  toJSON(message: UserPost): unknown {
    const obj: any = {};
    if (message.groupId !== "") {
      obj.groupId = message.groupId;
    }
    if (message.userId !== "") {
      obj.userId = message.userId;
    }
    if (message.createdAt !== undefined) {
      obj.createdAt = message.createdAt;
    }
    return obj;
  },

  create<I extends Exact<DeepPartial<UserPost>, I>>(base?: I): UserPost {
    return UserPost.fromPartial(base ?? ({} as any));
  },
  fromPartial<I extends Exact<DeepPartial<UserPost>, I>>(object: I): UserPost {
    const message = createBaseUserPost();
    message.groupId = object.groupId ?? "";
    message.userId = object.userId ?? "";
    message.createdAt = object.createdAt ?? undefined;
    return message;
  },
};

function createBaseGetGroupPostsRequest(): GetGroupPostsRequest {
  return { postId: "", groupId: undefined };
}

export const GetGroupPostsRequest = {
  encode(message: GetGroupPostsRequest, writer: _m0.Writer = _m0.Writer.create()): _m0.Writer {
    if (message.postId !== "") {
      writer.uint32(10).string(message.postId);
    }
    if (message.groupId !== undefined) {
      writer.uint32(18).string(message.groupId);
    }
    return writer;
  },

  decode(input: _m0.Reader | Uint8Array, length?: number): GetGroupPostsRequest {
    const reader = input instanceof _m0.Reader ? input : _m0.Reader.create(input);
    let end = length === undefined ? reader.len : reader.pos + length;
    const message = createBaseGetGroupPostsRequest();
    while (reader.pos < end) {
      const tag = reader.uint32();
      switch (tag >>> 3) {
        case 1:
          if (tag !== 10) {
            break;
          }

          message.postId = reader.string();
          continue;
        case 2:
          if (tag !== 18) {
            break;
          }

          message.groupId = reader.string();
          continue;
      }
      if ((tag & 7) === 4 || tag === 0) {
        break;
      }
      reader.skipType(tag & 7);
    }
    return message;
  },

  fromJSON(object: any): GetGroupPostsRequest {
    return {
      postId: isSet(object.postId) ? globalThis.String(object.postId) : "",
      groupId: isSet(object.groupId) ? globalThis.String(object.groupId) : undefined,
    };
  },

  toJSON(message: GetGroupPostsRequest): unknown {
    const obj: any = {};
    if (message.postId !== "") {
      obj.postId = message.postId;
    }
    if (message.groupId !== undefined) {
      obj.groupId = message.groupId;
    }
    return obj;
  },

  create<I extends Exact<DeepPartial<GetGroupPostsRequest>, I>>(base?: I): GetGroupPostsRequest {
    return GetGroupPostsRequest.fromPartial(base ?? ({} as any));
  },
  fromPartial<I extends Exact<DeepPartial<GetGroupPostsRequest>, I>>(object: I): GetGroupPostsRequest {
    const message = createBaseGetGroupPostsRequest();
    message.postId = object.postId ?? "";
    message.groupId = object.groupId ?? undefined;
    return message;
  },
};

function createBaseGetGroupPostsResponse(): GetGroupPostsResponse {
  return { groupPosts: [] };
}

export const GetGroupPostsResponse = {
  encode(message: GetGroupPostsResponse, writer: _m0.Writer = _m0.Writer.create()): _m0.Writer {
    for (const v of message.groupPosts) {
      GroupPost.encode(v!, writer.uint32(10).fork()).ldelim();
    }
    return writer;
  },

  decode(input: _m0.Reader | Uint8Array, length?: number): GetGroupPostsResponse {
    const reader = input instanceof _m0.Reader ? input : _m0.Reader.create(input);
    let end = length === undefined ? reader.len : reader.pos + length;
    const message = createBaseGetGroupPostsResponse();
    while (reader.pos < end) {
      const tag = reader.uint32();
      switch (tag >>> 3) {
        case 1:
          if (tag !== 10) {
            break;
          }

          message.groupPosts.push(GroupPost.decode(reader, reader.uint32()));
          continue;
      }
      if ((tag & 7) === 4 || tag === 0) {
        break;
      }
      reader.skipType(tag & 7);
    }
    return message;
  },

  fromJSON(object: any): GetGroupPostsResponse {
    return {
      groupPosts: globalThis.Array.isArray(object?.groupPosts)
        ? object.groupPosts.map((e: any) => GroupPost.fromJSON(e))
        : [],
    };
  },

  toJSON(message: GetGroupPostsResponse): unknown {
    const obj: any = {};
    if (message.groupPosts?.length) {
      obj.groupPosts = message.groupPosts.map((e) => GroupPost.toJSON(e));
    }
    return obj;
  },

  create<I extends Exact<DeepPartial<GetGroupPostsResponse>, I>>(base?: I): GetGroupPostsResponse {
    return GetGroupPostsResponse.fromPartial(base ?? ({} as any));
  },
  fromPartial<I extends Exact<DeepPartial<GetGroupPostsResponse>, I>>(object: I): GetGroupPostsResponse {
    const message = createBaseGetGroupPostsResponse();
    message.groupPosts = object.groupPosts?.map((e) => GroupPost.fromPartial(e)) || [];
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
  const seconds = date.getTime() / 1_000;
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
