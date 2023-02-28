import {
  AsyncThunk,
  createAsyncThunk,
  createEntityAdapter,
  createSlice,
  Dictionary,
  Draft,
  EntityAdapter,
  EntityId,
  PayloadAction,
  Slice,
} from "@reduxjs/toolkit";
import { CreatePostRequest, GetPostsRequest, GetPostsResponse, Post, formatError, PostListingType } from "@jonline/ui/src";
import { getCredentialClient } from "./accounts";
import { createTransform } from "redux-persist";
import moment from "moment";
import { AccountOrServer } from "../types";
import { DictionaryNum } from "@reduxjs/toolkit/dist/entities/models";
import { loadUserPosts } from "./users";
import { loadGroupPosts } from "./groups";

export type CreatePost = AccountOrServer & CreatePostRequest;
export const createPost: AsyncThunk<Post, CreatePost, any> = createAsyncThunk<Post, CreatePost>(
  "posts/create",
  async (request) => {
    const client = await getCredentialClient(request);
    return await client.createPost(request, client.credential);
  }
);

export type ReplyToPost = AccountOrServer & { postIdPath: string[], content: string };
export const replyToPost: AsyncThunk<Post, ReplyToPost, any> = createAsyncThunk<Post, ReplyToPost>(
  "posts/reply",
  async (request) => {
    const client = await getCredentialClient(request);
    const createPostRequest: CreatePostRequest = {
      replyToPostId: request.postIdPath[request.postIdPath.length - 1],
      content: request.content,
    };
    // TODO: Why doesn't the BE return the correct created date? We "estimate" it here.
    const result = await client.createPost(createPostRequest, client.credential);
    return { ...result, createdAt: new Date().toISOString() }
  }
);

export type LoadPostsRequest = AccountOrServer & {
  listingType?: PostListingType.PUBLIC_POSTS | PostListingType.FOLLOWING_POSTS | PostListingType.MY_GROUPS_POSTS,
  page?: number
};
export const defaultPostListingType = PostListingType.PUBLIC_POSTS;
export const loadPostsPage: AsyncThunk<GetPostsResponse, LoadPostsRequest, any> = createAsyncThunk<GetPostsResponse, LoadPostsRequest>(
  "posts/loadPage",
  async (request) => {
    let client = await getCredentialClient(request);
    let result = await client.getPosts({ listingType: defaultPostListingType, ...request }, client.credential);
    return result;
  }
);

export type LoadPostPreview = Post & AccountOrServer;
export const loadPostPreview: AsyncThunk<string, LoadPostPreview, any> = createAsyncThunk<string, LoadPostPreview>(
  "posts/loadPreview",
  async (request) => {
    let client = await getCredentialClient(request);
    let response = await client.getPosts(GetPostsRequest.create({ postId: request.id }), client.credential);
    let post = response.posts[0]!;
    return post.previewImage
      ? URL.createObjectURL(new Blob([post.previewImage!], { type: 'image/png' }))
      : '';
  }
);

export type LoadPost = { id: string } & AccountOrServer;
export type LoadPostResult = {
  post: Post;
  preview: string;
}
export const loadPost: AsyncThunk<LoadPostResult, LoadPost, any> = createAsyncThunk<LoadPostResult, LoadPost>(
  "posts/loadOne",
  async (request) => {
    const client = await getCredentialClient(request);
    const response = await client.getPosts(GetPostsRequest.create({ postId: request.id }), client.credential);
    if (response.posts.length == 0) throw 'Post not found';
    const post = response.posts[0]!;
    const preview = post.previewImage
      ? URL.createObjectURL(new Blob([post.previewImage!], { type: 'image/png' }))
      : '';
    return { post: { ...post, previewImage: undefined }, preview };
  }
);

export type LoadPostReplies = AccountOrServer & {
  postIdPath: string[];
}
export const loadPostReplies: AsyncThunk<GetPostsResponse, LoadPostReplies, any> = createAsyncThunk<GetPostsResponse, LoadPostReplies>(
  "posts/loadReplies",
  async (repliesRequest) => {
    console.log("loadPostReplies:", repliesRequest)
    const getPostsRequest = GetPostsRequest.create({
      postId: repliesRequest.postIdPath.at(-1),
      replyDepth: 2,
    })

    const client = await getCredentialClient(repliesRequest);
    const replies = await client.getPosts(getPostsRequest, client.credential);
    return replies;
  }
);
