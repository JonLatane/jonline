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
  /** DIRECT_POSTS - Returns LIMITED posts that are directly addressed to the user. */
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

/**
 * Valid GetPostsRequest formats:
 * - {[listing_type: PublicPosts]}                  (get ServerPublic/GlobalPublic posts you can see)
 * - {listing_type:MyGroupsPosts|FollowingPosts}    (auth required)
 * - {post_id:}                                     (get one post including preview data)
 * - {post_id:, reply_depth: 1}                     (get replies to a post - only support for replyDepth=1 for now tho)
 * - {listing_type: MyGroupsPosts|
 *      GroupPostsPendingModeration,
 *      group_id:}                                  (get posts/posts needing moderation for a group)
 * - {author_user_id:, group_id:}                   (get posts by a user for a group)
 * - {listing_type: AuthorPosts, author_user_id:}   (TODO: get posts by a user)
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
  /** TODO: Implement support for this */
  replyDepth?: number | undefined;
  listingType: PostListingType;
}

export interface GetPostsResponse {
  posts: Post[];
}

export interface CreatePostRequest {
  title?: string | undefined;
  link?: string | undefined;
  content?: string | undefined;
  replyToPostId?: string | undefined;
}

export interface Post {
  id: string;
  author?: Author | undefined;
  replyToPostId?: string | undefined;
  title?: string | undefined;
  link?: string | undefined;
  content?: string | undefined;
  responseCount: number;
  replyCount: number;
  /**
   * There should never be more than reply_count replies. However,
   * there may be fewer than reply_count replies if some replies are
   * hidden by moderation or visibility.
   * Replies are not generally loaded by default, but can be added to Posts
   * in the frontend.
   */
  replies: Post[];
  previewImage?: Uint8Array | undefined;
  visibility: Visibility;
  moderation: Moderation;
  groupCount: number;
  /**
   * When the post is returned in the context of a group_id parameter,
   * this can be returned. It lets the UI know whether the post can be
   * cross-posted to a group, and of course, *about* the cross-post
   * (time, moderation) if that's relevant.
   */
  currentGroupPost?: GroupPost | undefined;
  createdAt: string | undefined;
  updatedAt?: string | undefined;
}

/**
 * Post-centric version of User. UI can cross-reference user details
 * from its own cache (for things like admin/bot icons).
 */
export interface Author {
  userId: string;
  username?: string | undefined;
}

export interface GroupPost {
  groupId: string;
  postId: string;
  userId: string;
  groupModeration: Moderation;
  createdAt: string | undefined;
}

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

export interface GetGroupPostsResponse {
  groupPosts: GroupPost[];
}

function createBaseGetPostsRequest(): GetPostsRequest {
  return { postId: undefined, authorUserId: undefined, groupId: undefined, replyDepth: undefined, listingType: 0 };
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
    if (message.listingType !== 0) {
      writer.uint32(80).int32(message.listingType);
    }
    return writer;
  },

  decode(input: _m0.Reader | Uint8Array, length?: number): GetPostsRequest {
    const reader = input instanceof _m0.Reader ? input : new _m0.Reader(input);
    let end = length === undefined ? reader.len : reader.pos + length;
    const message = createBaseGetPostsRequest();
    while (reader.pos < end) {
      const tag = reader.uint32();
      switch (tag >>> 3) {
        case 1:
          message.postId = reader.string();
          break;
        case 2:
          message.authorUserId = reader.string();
          break;
        case 3:
          message.groupId = reader.string();
          break;
        case 4:
          message.replyDepth = reader.uint32();
          break;
        case 10:
          message.listingType = reader.int32() as any;
          break;
        default:
          reader.skipType(tag & 7);
          break;
      }
    }
    return message;
  },

  fromJSON(object: any): GetPostsRequest {
    return {
      postId: isSet(object.postId) ? String(object.postId) : undefined,
      authorUserId: isSet(object.authorUserId) ? String(object.authorUserId) : undefined,
      groupId: isSet(object.groupId) ? String(object.groupId) : undefined,
      replyDepth: isSet(object.replyDepth) ? Number(object.replyDepth) : undefined,
      listingType: isSet(object.listingType) ? postListingTypeFromJSON(object.listingType) : 0,
    };
  },

  toJSON(message: GetPostsRequest): unknown {
    const obj: any = {};
    message.postId !== undefined && (obj.postId = message.postId);
    message.authorUserId !== undefined && (obj.authorUserId = message.authorUserId);
    message.groupId !== undefined && (obj.groupId = message.groupId);
    message.replyDepth !== undefined && (obj.replyDepth = Math.round(message.replyDepth));
    message.listingType !== undefined && (obj.listingType = postListingTypeToJSON(message.listingType));
    return obj;
  },

  create<I extends Exact<DeepPartial<GetPostsRequest>, I>>(base?: I): GetPostsRequest {
    return GetPostsRequest.fromPartial(base ?? {});
  },

  fromPartial<I extends Exact<DeepPartial<GetPostsRequest>, I>>(object: I): GetPostsRequest {
    const message = createBaseGetPostsRequest();
    message.postId = object.postId ?? undefined;
    message.authorUserId = object.authorUserId ?? undefined;
    message.groupId = object.groupId ?? undefined;
    message.replyDepth = object.replyDepth ?? undefined;
    message.listingType = object.listingType ?? 0;
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
    const reader = input instanceof _m0.Reader ? input : new _m0.Reader(input);
    let end = length === undefined ? reader.len : reader.pos + length;
    const message = createBaseGetPostsResponse();
    while (reader.pos < end) {
      const tag = reader.uint32();
      switch (tag >>> 3) {
        case 1:
          message.posts.push(Post.decode(reader, reader.uint32()));
          break;
        default:
          reader.skipType(tag & 7);
          break;
      }
    }
    return message;
  },

  fromJSON(object: any): GetPostsResponse {
    return { posts: Array.isArray(object?.posts) ? object.posts.map((e: any) => Post.fromJSON(e)) : [] };
  },

  toJSON(message: GetPostsResponse): unknown {
    const obj: any = {};
    if (message.posts) {
      obj.posts = message.posts.map((e) => e ? Post.toJSON(e) : undefined);
    } else {
      obj.posts = [];
    }
    return obj;
  },

  create<I extends Exact<DeepPartial<GetPostsResponse>, I>>(base?: I): GetPostsResponse {
    return GetPostsResponse.fromPartial(base ?? {});
  },

  fromPartial<I extends Exact<DeepPartial<GetPostsResponse>, I>>(object: I): GetPostsResponse {
    const message = createBaseGetPostsResponse();
    message.posts = object.posts?.map((e) => Post.fromPartial(e)) || [];
    return message;
  },
};

function createBaseCreatePostRequest(): CreatePostRequest {
  return { title: undefined, link: undefined, content: undefined, replyToPostId: undefined };
}

export const CreatePostRequest = {
  encode(message: CreatePostRequest, writer: _m0.Writer = _m0.Writer.create()): _m0.Writer {
    if (message.title !== undefined) {
      writer.uint32(10).string(message.title);
    }
    if (message.link !== undefined) {
      writer.uint32(18).string(message.link);
    }
    if (message.content !== undefined) {
      writer.uint32(26).string(message.content);
    }
    if (message.replyToPostId !== undefined) {
      writer.uint32(34).string(message.replyToPostId);
    }
    return writer;
  },

  decode(input: _m0.Reader | Uint8Array, length?: number): CreatePostRequest {
    const reader = input instanceof _m0.Reader ? input : new _m0.Reader(input);
    let end = length === undefined ? reader.len : reader.pos + length;
    const message = createBaseCreatePostRequest();
    while (reader.pos < end) {
      const tag = reader.uint32();
      switch (tag >>> 3) {
        case 1:
          message.title = reader.string();
          break;
        case 2:
          message.link = reader.string();
          break;
        case 3:
          message.content = reader.string();
          break;
        case 4:
          message.replyToPostId = reader.string();
          break;
        default:
          reader.skipType(tag & 7);
          break;
      }
    }
    return message;
  },

  fromJSON(object: any): CreatePostRequest {
    return {
      title: isSet(object.title) ? String(object.title) : undefined,
      link: isSet(object.link) ? String(object.link) : undefined,
      content: isSet(object.content) ? String(object.content) : undefined,
      replyToPostId: isSet(object.replyToPostId) ? String(object.replyToPostId) : undefined,
    };
  },

  toJSON(message: CreatePostRequest): unknown {
    const obj: any = {};
    message.title !== undefined && (obj.title = message.title);
    message.link !== undefined && (obj.link = message.link);
    message.content !== undefined && (obj.content = message.content);
    message.replyToPostId !== undefined && (obj.replyToPostId = message.replyToPostId);
    return obj;
  },

  create<I extends Exact<DeepPartial<CreatePostRequest>, I>>(base?: I): CreatePostRequest {
    return CreatePostRequest.fromPartial(base ?? {});
  },

  fromPartial<I extends Exact<DeepPartial<CreatePostRequest>, I>>(object: I): CreatePostRequest {
    const message = createBaseCreatePostRequest();
    message.title = object.title ?? undefined;
    message.link = object.link ?? undefined;
    message.content = object.content ?? undefined;
    message.replyToPostId = object.replyToPostId ?? undefined;
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
    replies: [],
    previewImage: undefined,
    visibility: 0,
    moderation: 0,
    groupCount: 0,
    currentGroupPost: undefined,
    createdAt: undefined,
    updatedAt: undefined,
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
    for (const v of message.replies) {
      Post.encode(v!, writer.uint32(74).fork()).ldelim();
    }
    if (message.previewImage !== undefined) {
      writer.uint32(82).bytes(message.previewImage);
    }
    if (message.visibility !== 0) {
      writer.uint32(88).int32(message.visibility);
    }
    if (message.moderation !== 0) {
      writer.uint32(96).int32(message.moderation);
    }
    if (message.groupCount !== 0) {
      writer.uint32(112).int32(message.groupCount);
    }
    if (message.currentGroupPost !== undefined) {
      GroupPost.encode(message.currentGroupPost, writer.uint32(122).fork()).ldelim();
    }
    if (message.createdAt !== undefined) {
      Timestamp.encode(toTimestamp(message.createdAt), writer.uint32(162).fork()).ldelim();
    }
    if (message.updatedAt !== undefined) {
      Timestamp.encode(toTimestamp(message.updatedAt), writer.uint32(170).fork()).ldelim();
    }
    return writer;
  },

  decode(input: _m0.Reader | Uint8Array, length?: number): Post {
    const reader = input instanceof _m0.Reader ? input : new _m0.Reader(input);
    let end = length === undefined ? reader.len : reader.pos + length;
    const message = createBasePost();
    while (reader.pos < end) {
      const tag = reader.uint32();
      switch (tag >>> 3) {
        case 1:
          message.id = reader.string();
          break;
        case 2:
          message.author = Author.decode(reader, reader.uint32());
          break;
        case 3:
          message.replyToPostId = reader.string();
          break;
        case 4:
          message.title = reader.string();
          break;
        case 5:
          message.link = reader.string();
          break;
        case 6:
          message.content = reader.string();
          break;
        case 7:
          message.responseCount = reader.int32();
          break;
        case 8:
          message.replyCount = reader.int32();
          break;
        case 9:
          message.replies.push(Post.decode(reader, reader.uint32()));
          break;
        case 10:
          message.previewImage = reader.bytes();
          break;
        case 11:
          message.visibility = reader.int32() as any;
          break;
        case 12:
          message.moderation = reader.int32() as any;
          break;
        case 14:
          message.groupCount = reader.int32();
          break;
        case 15:
          message.currentGroupPost = GroupPost.decode(reader, reader.uint32());
          break;
        case 20:
          message.createdAt = fromTimestamp(Timestamp.decode(reader, reader.uint32()));
          break;
        case 21:
          message.updatedAt = fromTimestamp(Timestamp.decode(reader, reader.uint32()));
          break;
        default:
          reader.skipType(tag & 7);
          break;
      }
    }
    return message;
  },

  fromJSON(object: any): Post {
    return {
      id: isSet(object.id) ? String(object.id) : "",
      author: isSet(object.author) ? Author.fromJSON(object.author) : undefined,
      replyToPostId: isSet(object.replyToPostId) ? String(object.replyToPostId) : undefined,
      title: isSet(object.title) ? String(object.title) : undefined,
      link: isSet(object.link) ? String(object.link) : undefined,
      content: isSet(object.content) ? String(object.content) : undefined,
      responseCount: isSet(object.responseCount) ? Number(object.responseCount) : 0,
      replyCount: isSet(object.replyCount) ? Number(object.replyCount) : 0,
      replies: Array.isArray(object?.replies) ? object.replies.map((e: any) => Post.fromJSON(e)) : [],
      previewImage: isSet(object.previewImage) ? bytesFromBase64(object.previewImage) : undefined,
      visibility: isSet(object.visibility) ? visibilityFromJSON(object.visibility) : 0,
      moderation: isSet(object.moderation) ? moderationFromJSON(object.moderation) : 0,
      groupCount: isSet(object.groupCount) ? Number(object.groupCount) : 0,
      currentGroupPost: isSet(object.currentGroupPost) ? GroupPost.fromJSON(object.currentGroupPost) : undefined,
      createdAt: isSet(object.createdAt) ? String(object.createdAt) : undefined,
      updatedAt: isSet(object.updatedAt) ? String(object.updatedAt) : undefined,
    };
  },

  toJSON(message: Post): unknown {
    const obj: any = {};
    message.id !== undefined && (obj.id = message.id);
    message.author !== undefined && (obj.author = message.author ? Author.toJSON(message.author) : undefined);
    message.replyToPostId !== undefined && (obj.replyToPostId = message.replyToPostId);
    message.title !== undefined && (obj.title = message.title);
    message.link !== undefined && (obj.link = message.link);
    message.content !== undefined && (obj.content = message.content);
    message.responseCount !== undefined && (obj.responseCount = Math.round(message.responseCount));
    message.replyCount !== undefined && (obj.replyCount = Math.round(message.replyCount));
    if (message.replies) {
      obj.replies = message.replies.map((e) => e ? Post.toJSON(e) : undefined);
    } else {
      obj.replies = [];
    }
    message.previewImage !== undefined &&
      (obj.previewImage = message.previewImage !== undefined ? base64FromBytes(message.previewImage) : undefined);
    message.visibility !== undefined && (obj.visibility = visibilityToJSON(message.visibility));
    message.moderation !== undefined && (obj.moderation = moderationToJSON(message.moderation));
    message.groupCount !== undefined && (obj.groupCount = Math.round(message.groupCount));
    message.currentGroupPost !== undefined &&
      (obj.currentGroupPost = message.currentGroupPost ? GroupPost.toJSON(message.currentGroupPost) : undefined);
    message.createdAt !== undefined && (obj.createdAt = message.createdAt);
    message.updatedAt !== undefined && (obj.updatedAt = message.updatedAt);
    return obj;
  },

  create<I extends Exact<DeepPartial<Post>, I>>(base?: I): Post {
    return Post.fromPartial(base ?? {});
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
    message.replies = object.replies?.map((e) => Post.fromPartial(e)) || [];
    message.previewImage = object.previewImage ?? undefined;
    message.visibility = object.visibility ?? 0;
    message.moderation = object.moderation ?? 0;
    message.groupCount = object.groupCount ?? 0;
    message.currentGroupPost = (object.currentGroupPost !== undefined && object.currentGroupPost !== null)
      ? GroupPost.fromPartial(object.currentGroupPost)
      : undefined;
    message.createdAt = object.createdAt ?? undefined;
    message.updatedAt = object.updatedAt ?? undefined;
    return message;
  },
};

function createBaseAuthor(): Author {
  return { userId: "", username: undefined };
}

export const Author = {
  encode(message: Author, writer: _m0.Writer = _m0.Writer.create()): _m0.Writer {
    if (message.userId !== "") {
      writer.uint32(10).string(message.userId);
    }
    if (message.username !== undefined) {
      writer.uint32(18).string(message.username);
    }
    return writer;
  },

  decode(input: _m0.Reader | Uint8Array, length?: number): Author {
    const reader = input instanceof _m0.Reader ? input : new _m0.Reader(input);
    let end = length === undefined ? reader.len : reader.pos + length;
    const message = createBaseAuthor();
    while (reader.pos < end) {
      const tag = reader.uint32();
      switch (tag >>> 3) {
        case 1:
          message.userId = reader.string();
          break;
        case 2:
          message.username = reader.string();
          break;
        default:
          reader.skipType(tag & 7);
          break;
      }
    }
    return message;
  },

  fromJSON(object: any): Author {
    return {
      userId: isSet(object.userId) ? String(object.userId) : "",
      username: isSet(object.username) ? String(object.username) : undefined,
    };
  },

  toJSON(message: Author): unknown {
    const obj: any = {};
    message.userId !== undefined && (obj.userId = message.userId);
    message.username !== undefined && (obj.username = message.username);
    return obj;
  },

  create<I extends Exact<DeepPartial<Author>, I>>(base?: I): Author {
    return Author.fromPartial(base ?? {});
  },

  fromPartial<I extends Exact<DeepPartial<Author>, I>>(object: I): Author {
    const message = createBaseAuthor();
    message.userId = object.userId ?? "";
    message.username = object.username ?? undefined;
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
    const reader = input instanceof _m0.Reader ? input : new _m0.Reader(input);
    let end = length === undefined ? reader.len : reader.pos + length;
    const message = createBaseGroupPost();
    while (reader.pos < end) {
      const tag = reader.uint32();
      switch (tag >>> 3) {
        case 1:
          message.groupId = reader.string();
          break;
        case 2:
          message.postId = reader.string();
          break;
        case 3:
          message.userId = reader.string();
          break;
        case 4:
          message.groupModeration = reader.int32() as any;
          break;
        case 5:
          message.createdAt = fromTimestamp(Timestamp.decode(reader, reader.uint32()));
          break;
        default:
          reader.skipType(tag & 7);
          break;
      }
    }
    return message;
  },

  fromJSON(object: any): GroupPost {
    return {
      groupId: isSet(object.groupId) ? String(object.groupId) : "",
      postId: isSet(object.postId) ? String(object.postId) : "",
      userId: isSet(object.userId) ? String(object.userId) : "",
      groupModeration: isSet(object.groupModeration) ? moderationFromJSON(object.groupModeration) : 0,
      createdAt: isSet(object.createdAt) ? String(object.createdAt) : undefined,
    };
  },

  toJSON(message: GroupPost): unknown {
    const obj: any = {};
    message.groupId !== undefined && (obj.groupId = message.groupId);
    message.postId !== undefined && (obj.postId = message.postId);
    message.userId !== undefined && (obj.userId = message.userId);
    message.groupModeration !== undefined && (obj.groupModeration = moderationToJSON(message.groupModeration));
    message.createdAt !== undefined && (obj.createdAt = message.createdAt);
    return obj;
  },

  create<I extends Exact<DeepPartial<GroupPost>, I>>(base?: I): GroupPost {
    return GroupPost.fromPartial(base ?? {});
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
    const reader = input instanceof _m0.Reader ? input : new _m0.Reader(input);
    let end = length === undefined ? reader.len : reader.pos + length;
    const message = createBaseUserPost();
    while (reader.pos < end) {
      const tag = reader.uint32();
      switch (tag >>> 3) {
        case 1:
          message.groupId = reader.string();
          break;
        case 2:
          message.userId = reader.string();
          break;
        case 3:
          message.createdAt = fromTimestamp(Timestamp.decode(reader, reader.uint32()));
          break;
        default:
          reader.skipType(tag & 7);
          break;
      }
    }
    return message;
  },

  fromJSON(object: any): UserPost {
    return {
      groupId: isSet(object.groupId) ? String(object.groupId) : "",
      userId: isSet(object.userId) ? String(object.userId) : "",
      createdAt: isSet(object.createdAt) ? String(object.createdAt) : undefined,
    };
  },

  toJSON(message: UserPost): unknown {
    const obj: any = {};
    message.groupId !== undefined && (obj.groupId = message.groupId);
    message.userId !== undefined && (obj.userId = message.userId);
    message.createdAt !== undefined && (obj.createdAt = message.createdAt);
    return obj;
  },

  create<I extends Exact<DeepPartial<UserPost>, I>>(base?: I): UserPost {
    return UserPost.fromPartial(base ?? {});
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
    const reader = input instanceof _m0.Reader ? input : new _m0.Reader(input);
    let end = length === undefined ? reader.len : reader.pos + length;
    const message = createBaseGetGroupPostsRequest();
    while (reader.pos < end) {
      const tag = reader.uint32();
      switch (tag >>> 3) {
        case 1:
          message.postId = reader.string();
          break;
        case 2:
          message.groupId = reader.string();
          break;
        default:
          reader.skipType(tag & 7);
          break;
      }
    }
    return message;
  },

  fromJSON(object: any): GetGroupPostsRequest {
    return {
      postId: isSet(object.postId) ? String(object.postId) : "",
      groupId: isSet(object.groupId) ? String(object.groupId) : undefined,
    };
  },

  toJSON(message: GetGroupPostsRequest): unknown {
    const obj: any = {};
    message.postId !== undefined && (obj.postId = message.postId);
    message.groupId !== undefined && (obj.groupId = message.groupId);
    return obj;
  },

  create<I extends Exact<DeepPartial<GetGroupPostsRequest>, I>>(base?: I): GetGroupPostsRequest {
    return GetGroupPostsRequest.fromPartial(base ?? {});
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
    const reader = input instanceof _m0.Reader ? input : new _m0.Reader(input);
    let end = length === undefined ? reader.len : reader.pos + length;
    const message = createBaseGetGroupPostsResponse();
    while (reader.pos < end) {
      const tag = reader.uint32();
      switch (tag >>> 3) {
        case 1:
          message.groupPosts.push(GroupPost.decode(reader, reader.uint32()));
          break;
        default:
          reader.skipType(tag & 7);
          break;
      }
    }
    return message;
  },

  fromJSON(object: any): GetGroupPostsResponse {
    return {
      groupPosts: Array.isArray(object?.groupPosts) ? object.groupPosts.map((e: any) => GroupPost.fromJSON(e)) : [],
    };
  },

  toJSON(message: GetGroupPostsResponse): unknown {
    const obj: any = {};
    if (message.groupPosts) {
      obj.groupPosts = message.groupPosts.map((e) => e ? GroupPost.toJSON(e) : undefined);
    } else {
      obj.groupPosts = [];
    }
    return obj;
  },

  create<I extends Exact<DeepPartial<GetGroupPostsResponse>, I>>(base?: I): GetGroupPostsResponse {
    return GetGroupPostsResponse.fromPartial(base ?? {});
  },

  fromPartial<I extends Exact<DeepPartial<GetGroupPostsResponse>, I>>(object: I): GetGroupPostsResponse {
    const message = createBaseGetGroupPostsResponse();
    message.groupPosts = object.groupPosts?.map((e) => GroupPost.fromPartial(e)) || [];
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
