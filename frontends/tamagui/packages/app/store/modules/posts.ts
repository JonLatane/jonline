import {
  AsyncThunk,
  createAsyncThunk,
  createEntityAdapter,
  createSlice,
  Dictionary,
  Draft,
  EntityAdapter,
  EntityId,
  Slice,
} from "@reduxjs/toolkit";
import { CreatePostRequest, GetPostsRequest, GetPostsResponse, Post, formatError } from "@jonline/ui/src";
import { getCredentialClient } from "./accounts";
import { createTransform } from "redux-persist";
import moment from "moment";
import { AccountOrServer } from "../types";

export interface PostsState {
  status: "unloaded" | "loading" | "loaded" | "errored";
  error?: Error;
  successMessage?: string;
  errorMessage?: string;
  draftPost: Post;
  ids: EntityId[];
  entities: Dictionary<Post>;
  previews: Dictionary<string>;
}

const postsAdapter: EntityAdapter<Post> = createEntityAdapter<Post>({
  selectId: (post) => post.id,
  sortComparer: (a, b) => moment.utc(b.createdAt).unix() - moment.utc(a.createdAt).unix(),
});

export type CreatePost = AccountOrServer & CreatePostRequest;
export const createPost: AsyncThunk<Post, CreatePost, any> = createAsyncThunk<Post, CreatePost>(
  "posts/create",
  async (createPostRequest) => {
    let client = await getCredentialClient(createPostRequest);
    return client.createPost(createPostRequest, client.credential);
  }
);

export type UpdatePosts = AccountOrServer & GetPostsRequest;
export const updatePosts: AsyncThunk<GetPostsResponse, UpdatePosts, any> = createAsyncThunk<GetPostsResponse, UpdatePosts>(
  "posts/update",
  async (getPostsRequest) => {
    let client = await getCredentialClient(getPostsRequest);
    let result = await client.getPosts(getPostsRequest, client.credential);
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
    let client = await getCredentialClient(request);
    let response = await client.getPosts(GetPostsRequest.create({ postId: request.id }), client.credential);
    let post = response.posts[0]!;
    let preview = post.previewImage
      ? URL.createObjectURL(new Blob([post.previewImage!], { type: 'image/png' }))
      : '';
    return { post, preview };
  }
);

export type LoadPostReplies = AccountOrServer & {
  postIdPath: string[];
}
export const loadPostReplies: AsyncThunk<GetPostsResponse, LoadPostReplies, any> = createAsyncThunk<GetPostsResponse, LoadPostReplies>(
  "posts/loadReplies",
  async (repliesRequest) => {
    let getPostsRequest = GetPostsRequest.create({
      postId: repliesRequest.postIdPath.at(-1),
      replyDepth: 1
    })

    let client = await getCredentialClient(repliesRequest);
    return client.getPosts(getPostsRequest, client.credential);
  }
);

const initialState: PostsState = {
  status: "unloaded",
  draftPost: Post.create(),
  previews: {},
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
    builder.addCase(updatePosts.pending, (state) => {
      state.status = "loading";
      state.error = undefined;
    });
    builder.addCase(updatePosts.fulfilled, (state, action) => {
      state.status = "loaded";
      postsAdapter.upsertMany(state, action.payload.posts);
      state.successMessage = `Posts loaded.`;
    });
    builder.addCase(updatePosts.rejected, (state, action) => {
      state.status = "errored";
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
      postsAdapter.upsertOne(state, action.payload.post);
      state.previews[action.meta.arg.id] = action.payload.preview;
      state.successMessage = `Post data loaded.`;
    });
    builder.addCase(loadPost.rejected, (state, action) => {
      state.status = "errored";
      state.error = action.error as Error;
      state.errorMessage = formatError(action.error as Error);
      state.error = action.error as Error;
    });
    builder.addCase(loadPostReplies.pending, (state) => {
      state.status = "loading";
      state.error = undefined;
    });
    builder.addCase(loadPostReplies.fulfilled, (state, action) => {
      state.status = "loaded";

      // Load the replies into the post tree.
      let postIdPath = action.meta.arg.postIdPath;
      let rootPost = postsAdapter.getSelectors().selectById(state, postIdPath[0]!);
      if (!rootPost) {
        console.error(`Root post ID (${postIdPath[0]}) not found.`);
        return;
      }

      let post: Post = rootPost;
      for (let postId in postIdPath.slice(1)) {
        let nextPost = post.replies.find((reply) => reply.id === postId);
        if (!nextPost) {
          console.error(`Post ID (${postId}) not found along path ${postIdPath}.`);
          return;
        }
        post = nextPost;
      }
      post = { ...post, replies: action.payload.posts };
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

export const { removePost, clearPostAlerts: clearPostAlerts, resetPosts } = postsSlice.actions;
export const { selectAll: selectAllPosts, selectById: selectPostById } = postsAdapter.getSelectors();
export const postsReducer = postsSlice.reducer;
export const upsertPost = postsAdapter.upsertOne;
export const upsertPosts = postsAdapter.upsertMany;
export default postsReducer;
