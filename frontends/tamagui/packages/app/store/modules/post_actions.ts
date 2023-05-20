import { Post, GetPostsRequest, GetPostsResponse, PostListingType } from "@jonline/api";
import {
  AsyncThunk,
  createAsyncThunk
} from "@reduxjs/toolkit";
import { AccountOrServer } from "../types";
import { getCredentialClient } from "./accounts";

export type CreatePost = AccountOrServer & Post;
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
    const newPost: Post = Post.fromPartial({
      replyToPostId: request.postIdPath[request.postIdPath.length - 1],
      content: request.content,
    });
    // TODO: Why doesn't the BE return the correct created date? We "estimate" it here.
    const result = await client.createPost(newPost, client.credential);
    return { ...result, createdAt: new Date().toISOString() }
  }
);

export type LoadPostsRequest = AccountOrServer & {
  listingType?: PostListingType,
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

export type LoadPost = { id: string } & AccountOrServer;
export const loadPost: AsyncThunk<Post, LoadPost, any> = createAsyncThunk<Post, LoadPost>(
  "posts/loadOne",
  async (request) => {
    const client = await getCredentialClient(request);
    const response = await client.getPosts(GetPostsRequest.create({ postId: request.id }), client.credential);
    if (response.posts.length == 0) throw 'Post not found';
    const post = response.posts[0]!;
    return post;
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
