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

export interface PostsState {
  baseStatus: "unloaded" | "loading" | "loaded" | "errored";
  status: "unloaded" | "loading" | "loaded" | "errored";
  sendReplyStatus: "sending" | "sent" | "errored" | undefined;
  error?: Error;
  successMessage?: string;
  errorMessage?: string;
  draftPost: Post;
  ids: EntityId[];
  entities: Dictionary<Post>;
  previews: Dictionary<string>;
  // Stores pages of listed posts for listing types used in the UI.
  // i.e.: postPages[PostListingType.PUBLIC_POSTS][1] -> ["postId1", "postId2"].
  // Posts should be loaded from the adapter/slice's entities.
  // Maps PostListingType -> page -> postIds
  postPages: DictionaryNum<DictionaryNum<string[]>>;
  failedPostIds: string[];
}

const postsAdapter: EntityAdapter<Post> = createEntityAdapter<Post>({
  selectId: (post) => post.id,
  sortComparer: (a, b) => moment.utc(b.createdAt).unix() - moment.utc(a.createdAt).unix(),
});

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

const initialState: PostsState = {
  status: "unloaded",
  baseStatus: "unloaded",
  draftPost: Post.create(),
  sendReplyStatus: undefined,
  previews: {},
  failedPostIds: [],
  postPages: {},
  ...postsAdapter.getInitialState(),
};

export const postsSlice: Slice<Draft<PostsState>, any, "posts"> = createSlice({
  name: "posts",
  initialState: initialState,
  reducers: {
    upsertPost: postsAdapter.upsertOne,
    removePost: postsAdapter.removeOne,
    resetPosts: () => initialState,
    clearPostAlerts: (state) => {
      state.errorMessage = undefined;
      state.successMessage = undefined;
      state.error = undefined;
    },
    confirmReplySent: (state) => {
      state.sendReplyStatus = undefined;
    },
  },
  extraReducers: (builder) => {
    builder.addCase(createPost.pending, (state) => {
      state.status = "loading";
      state.error = undefined;
    });
    builder.addCase(createPost.fulfilled, (state, action) => {
      state.status = "loaded";
      postsAdapter.upsertOne(state, action.payload);
      state.successMessage = `Post created.`;
    });
    builder.addCase(createPost.rejected, (state, action) => {
      state.status = "errored";
      state.error = action.error as Error;
      state.errorMessage = formatError(action.error as Error);
      state.error = action.error as Error;
    });
    builder.addCase(replyToPost.pending, (state) => {
      state.sendReplyStatus = "sending";
      state.error = undefined;
    });
    builder.addCase(replyToPost.fulfilled, (state, action) => {
      state.sendReplyStatus = "sent";
      // postsAdapter.upsertOne(state, action.payload);
      const reply = action.payload;
      const postIdPath = action.meta.arg.postIdPath;
      const basePost = postsAdapter.getSelectors().selectById(state, postIdPath[0]!);
      if (!basePost) {
        console.error(`Root post ID (${postIdPath[0]}) not found.`);
        return;
      }
      const rootPost: Post = { ...basePost }

      let parentPost: Post = rootPost;
      for (const postId of postIdPath.slice(1)) {
        parentPost.replies = parentPost.replies.map(p => ({ ...p }));
        const nextPost = parentPost.replies.find((reply) => reply.id === postId);
        if (!nextPost) {
          console.error(`Post ID (${postId}) not found along path ${JSON.stringify(postIdPath)}.`);
          return;
        }
        parentPost = nextPost;
      }
      parentPost.replies = [reply].concat(...parentPost.replies);
      postsAdapter.upsertOne(state, rootPost);
      state.successMessage = `Reply created.`;
    });
    builder.addCase(replyToPost.rejected, (state, action) => {
      state.sendReplyStatus = "errored";
      state.error = action.error as Error;
      state.errorMessage = formatError(action.error as Error);
      state.error = action.error as Error;
    });
    builder.addCase(loadPostsPage.pending, (state) => {
      state.status = "loading";
      state.baseStatus = "loading";
      state.error = undefined;
    });
    builder.addCase(loadPostsPage.fulfilled, (state, action) => {
      state.status = "loaded";
      state.baseStatus = "loaded";
      action.payload.posts.forEach(post => {
        const oldPost = selectPostById(state, post.id);
        postsAdapter.upsertOne(state, { ...post, replies: oldPost?.replies ?? post.replies });
      });
      const postIds = action.payload.posts.map(post => post.id);
      const page = action.meta.arg.page || 0;
      const listingType = action.meta.arg.listingType || defaultPostListingType;
      if (!state.postPages[listingType]) state.postPages[listingType] = {};
      state.postPages[listingType]![page] = postIds;
      state.successMessage = `Posts loaded.`;
    });
    builder.addCase(loadPostsPage.rejected, (state, action) => {
      state.status = "errored";
      state.baseStatus = "errored";
      state.error = action.error as Error;
      state.errorMessage = formatError(action.error as Error);
      state.error = action.error as Error;
    });
    builder.addCase(loadPost.pending, (state) => {
      state.status = "loading";
      state.error = undefined;
    });
    builder.addCase(loadPost.fulfilled, (state, action) => {
      state.status = "loaded";
      const oldPost = selectPostById(state, action.payload.post.id);
      postsAdapter.upsertOne(state, { ...action.payload.post, replies: oldPost?.replies ?? action.payload.post.replies });
      state.previews[action.meta.arg.id] = action.payload.preview;
      state.successMessage = `Post data loaded.`;
    });
    builder.addCase(loadPost.rejected, (state, action) => {
      state.status = "errored";
      state.error = action.error as Error;
      state.errorMessage = formatError(action.error as Error);
      state.error = action.error as Error;
      state.failedPostIds = [...state.failedPostIds, (action.meta.arg as LoadPost).id];
    });
    builder.addCase(loadPostReplies.pending, (state) => {
      state.status = "loading";
      state.error = undefined;
    });
    builder.addCase(loadPostReplies.fulfilled, (state, action) => {
      state.status = "loaded";
      // Load the replies into the post tree.
      const postIdPath = action.meta.arg.postIdPath;
      const basePost = postsAdapter.getSelectors().selectById(state, postIdPath[0]!);
      if (!basePost) {
        console.error(`Root post ID (${postIdPath[0]}) not found.`);
        return;
      }
      const rootPost: Post = { ...basePost }

      let post: Post = rootPost;
      for (const postId of postIdPath.slice(1)) {
        post.replies = post.replies.map(p => ({ ...p }));
        const nextPost = post.replies.find((reply) => reply.id === postId);
        if (!nextPost) {
          console.error(`Post ID (${postId}) not found along path ${JSON.stringify(postIdPath)}.`);
          return;
        }
        post = nextPost;
      }
      const mergedReplies = action.payload.posts.map(reply => {
        const oldReply = post.replies.find(r => r.id === reply.id);
        return { ...reply, replies: oldReply?.replies ?? reply.replies };
      });
      post.replies = mergedReplies;
      postsAdapter.upsertOne(state, rootPost);
      state.successMessage = `Replies loaded.`;
    });
    builder.addCase(loadPostReplies.rejected, (state, action) => {
      state.status = "errored";
      state.error = action.error as Error;
      state.errorMessage = `Error loading replies: ${formatError(action.error as Error)}`;
      state.error = action.error as Error;
    });
    builder.addCase(loadPostPreview.fulfilled, (state, action) => {
      state.previews[action.meta.arg.id] = action.payload;
      state.successMessage = `Preview image loaded.`;
    });
  },
});

export const { removePost, clearPostAlerts: clearPostAlerts, confirmReplySent, resetPosts } = postsSlice.actions;
export const { selectAll: selectAllPosts, selectById: selectPostById } = postsAdapter.getSelectors();
export const postsReducer = postsSlice.reducer;
export const upsertPost = postsAdapter.upsertOne;
export const upsertPosts = postsAdapter.upsertMany;
export default postsReducer;

export function getPostsPage(state: PostsState, listingType: PostListingType, page: number): Post[] {
  const pagePostIds: string[] = (state.postPages[listingType] ?? {})[page] || [];
  const pagePosts = pagePostIds.map(id => selectPostById(state, id)).filter(p => p) as Post[];
  return pagePosts;
}
