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
import { AccountOrServer, getCredentialClient } from "./accounts";

export interface PostsState {
  status: "unloaded" | "loading" | "loaded" | "errored";
  error?: Error;
  successMessage?: string;
  errorMessage?: string;
  draftPost: Post;
  ids: EntityId[];
  entities: Dictionary<Post>;
}

export interface PostsSlice {
  adapter: EntityAdapter<Post>;

}

const postsAdapter: EntityAdapter<Post> = createEntityAdapter<Post>({
  selectId: (post) => post.id,
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
    return client.getPosts(getPostsRequest, client.credential);
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
  ...postsAdapter.getInitialState(),
};

export const postsSlice: Slice<Draft<PostsState>, any, "posts"> = createSlice({
  name: "posts",
  initialState: initialState,
  reducers: {
    upsertPost: postsAdapter.upsertOne,
    removePost: postsAdapter.removeOne,
    reset: () => initialState,
    clearAlerts: (state) => {
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
    builder.addCase(loadPostReplies.pending, (state) => {
      state.status = "loading";
      state.error = undefined;
    });
    builder.addCase(loadPostReplies.fulfilled, (state, action) => {
      state.status = "loaded";

      // Load the replies into the post tree.
      let postIdPath = action.meta.arg.postIdPath;
      let rootPost = postsAdapter.getSelectors().selectById(state, postIdPath[0]!);
      if(!rootPost) { 
        console.error(`Root post ID (${postIdPath[0]}) not found.`);
        return;
      }

      let post: Post = rootPost;
      for(let postId in postIdPath.slice(1)) {
        let nextPost = post.replies.find((reply) => reply.id === postId);
        if(!nextPost) { 
          console.error(`Post ID (${postId}) not found along path ${postIdPath}.`);
          return;
        }
        post = nextPost;
      }
      post.replies = action.payload.posts;
      postsAdapter.upsertOne(state, rootPost);
      state.successMessage = `Replies loaded.`;
    });
    builder.addCase(loadPostReplies.rejected, (state, action) => {
      state.status = "errored";
      state.error = action.error as Error;
      state.errorMessage = `Error loading replies: ${formatError(action.error as Error)}`;
      state.error = action.error as Error;
    });
  },
});

// export const { upsertFact } = postsSlice.actions;
export const { removePost, clearAlerts } = postsSlice.actions;

export const { selectAll: selectAllPosts } = postsAdapter.getSelectors();

export const postsReducer = postsSlice.reducer;

export default postsSlice.reducer;
