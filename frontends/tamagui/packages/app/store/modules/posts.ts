import { Post, PostContext } from "@jonline/api";
import { formatError } from "@jonline/ui";
import {
  Dictionary,
  Draft,
  EntityAdapter,
  EntityId, Slice,
  createEntityAdapter,
  createSlice
} from "@reduxjs/toolkit";
import { publicVisibility } from "app/utils/visibility_utils";
import moment from "moment";
import { loadGroupPostsPage } from "./group_actions";
import { LoadPost, createPost, defaultPostListingType, deletePost, loadPost, loadPostReplies, loadPostsPage, replyToPost, updatePost } from './post_actions';
import { loadUserPosts } from "./user_actions";
import { loadEvent, loadEventsPage } from "./event_actions";
import { GroupedPages } from "../pagination";
import { eventsAdapter, eventsSlice } from './events';
import { store } from "../store";
export * from './post_actions';

export interface PostsState {
  baseStatus: "unloaded" | "loading" | "loaded" | "errored";
  status: "unloaded" | "loading" | "loaded" | "errored";
  sendReplyStatus?: "sending" | "sent" | "errored";
  createPostStatus?: "posting" | "posted" | "errored";
  updatePostStatus?: "updating" | "updated" | "errored";
  deletePostStatus?: "deleting" | "deleted" | "errored";
  error?: Error;
  successMessage?: string;
  errorMessage?: string;
  draftPost: DraftPost;
  ids: EntityId[];
  entities: Dictionary<Post>;
  postPages: GroupedPages;
  failedPostIds: string[];
}

export interface DraftPost {
  newPost: Post;
  groupId?: string;
}

const postsAdapter: EntityAdapter<Post> = createEntityAdapter<Post>({
  selectId: (post) => post.id,
  sortComparer: (a, b) => moment.utc(b.createdAt).unix() - moment.utc(a.createdAt).unix(),
});

const initialState: PostsState = {
  status: "unloaded",
  baseStatus: "unloaded",
  draftPost: {
    newPost: Post.fromPartial({})
  },
  sendReplyStatus: undefined,
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
      state.createPostStatus = undefined;
      state.sendReplyStatus = undefined;
    },
    confirmReplySent: (state) => {
      state.sendReplyStatus = undefined;
    },
  },
  extraReducers: (builder) => {
    builder.addCase(createPost.pending, (state) => {
      state.status = "loading";
      state.createPostStatus = "posting";
      state.error = undefined;
    });
    builder.addCase(createPost.fulfilled, (state, action) => {
      state.status = "loaded";
      state.createPostStatus = "posted";
      postsAdapter.upsertOne(state, action.payload);
      if (publicVisibility(action.payload.visibility)) {
        state.postPages[defaultPostListingType] = state.postPages[defaultPostListingType] || {};
        const firstPage = state.postPages[defaultPostListingType][0] || [];
        state.postPages[defaultPostListingType][0] = [action.payload.id, ...firstPage];
      }
      state.successMessage = `Post created.`;
    });
    builder.addCase(createPost.rejected, (state, action) => {
      state.status = "errored";
      state.createPostStatus = "errored";
      state.error = action.error as Error;
      state.errorMessage = formatError(action.error as Error);
      state.error = action.error as Error;
    });
    builder.addCase(updatePost.pending, (state) => {
      state.updatePostStatus = "updating";
      state.error = undefined;
    });
    builder.addCase(updatePost.fulfilled, (state, action) => {
      state.updatePostStatus = "updated";
      postsAdapter.upsertOne(state, action.payload);
    });
    builder.addCase(updatePost.rejected, (state, action) => {
      state.updatePostStatus = "errored";
      state.error = action.error as Error;
      state.errorMessage = formatError(action.error as Error);
      state.error = action.error as Error;
    });
    builder.addCase(deletePost.pending, (state) => {
      state.deletePostStatus = "deleting";
      state.error = undefined;
    });
    builder.addCase(deletePost.fulfilled, (state, action) => {
      state.deletePostStatus = "deleted";
      postsAdapter.upsertOne(state, action.payload);
    });
    builder.addCase(deletePost.rejected, (state, action) => {
      state.deletePostStatus = "errored";
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
      const listingType = action.meta.arg.listingType ?? defaultPostListingType;

      if (!state.postPages[listingType] || page === 0) state.postPages[listingType] = {};
      const postPages: Dictionary<string[]> = state.postPages[listingType]!;
      // Sensible approach:
      // postPages[page] = postIds;

      // Chunked approach: (note that we re-initialize `postPages` when `page` == 0)
      let initialPage: number = 0;
      while (action.meta.arg.page && postPages[initialPage]) {
        initialPage++;
      }
      const chunkSize = 7;
      for (let i = 0; i < postIds.length; i += chunkSize) {
        const chunk = postIds.slice(i, i + chunkSize);
        state.postPages[listingType]![initialPage + (i / chunkSize)] = chunk;
      }
      if (state.postPages[listingType]![0] == undefined) {
        state.postPages[listingType]![0] = [];
      }

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
      const oldPost = selectPostById(state, action.payload.id);
      postsAdapter.upsertOne(state, { ...action.payload, replies: oldPost?.replies ?? action.payload.replies });
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

    builder.addCase(loadUserPosts.fulfilled, (state, action) => {
      const { posts } = action.payload;
      upsertPosts(state, posts);
    });
    builder.addCase(loadGroupPostsPage.fulfilled, (state, action) => {
      const { posts } = action.payload;
      upsertPosts(state, posts);
    });
    builder.addCase(loadEvent.fulfilled, (state, action) => {
      postsAdapter.upsertOne(state, action.payload.post!);
    });
    builder.addCase(loadEventsPage.fulfilled, (state, action) => {
      const posts = action.payload.events.map(event => event.post!);
      upsertPosts(state, posts);
    });
  },
});

export const { removePost, clearPostAlerts: clearPostAlerts, confirmReplySent, resetPosts } = postsSlice.actions;
export const { selectAll: selectAllPosts, selectById: selectPostById } = postsAdapter.getSelectors();
export const postsReducer = postsSlice.reducer;
export const upsertPost = postsAdapter.upsertOne;
export const upsertPosts = postsAdapter.upsertMany;
export default postsReducer;
