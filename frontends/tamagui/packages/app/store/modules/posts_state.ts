import { Post, Event } from "@jonline/api";
import {
  Dictionary,
  Draft,
  EntityAdapter,
  EntityId, PayloadAction, Slice,
  createEntityAdapter,
  createSlice
} from "@reduxjs/toolkit";
import { publicVisibility } from "app/utils/visibility_utils";
import moment from "moment";
import { Federated, FederatedEntity, createFederated, federateId, federatedEntities, federatedEntity, federatedId, federatedPayload, getFederated, setFederated } from '../federation';
import { FederatedPagesStatus, GroupedPages, PaginatedIds, createFederatedPagesStatus } from "../pagination";
import { createEvent, loadEvent, loadEventByInstance, loadEventsPage, updateEvent } from "./event_actions";
import { loadGroupPostsPage } from "./group_actions";
import { LoadPost, createPost, defaultPostListingType, loadPost, loadPostReplies, loadPostsPage, replyToPost } from './post_actions';
import { loadUserPosts } from "./user_actions";
export * from './post_actions';

export type FederatedPost = FederatedEntity<Post>;
export interface PostsState {
  pagesStatus: FederatedPagesStatus;
  ids: EntityId[];
  entities: Dictionary<FederatedPost>;
  postPages: Federated<GroupedPages>;
  failedPostIds: string[];
}

export interface DraftPost {
  newPost: Post;
  groupId?: string;
}

export const postsAdapter: EntityAdapter<FederatedPost> = createEntityAdapter<FederatedPost>({
  selectId: (post) => federatedId(post),
  sortComparer: (a, b) => moment.utc(b.createdAt).unix() - moment.utc(a.createdAt).unix(),
});

const initialState: PostsState = {
  pagesStatus: createFederatedPagesStatus(),
  failedPostIds: [],
  postPages: createFederated({}),
  ...postsAdapter.getInitialState(),
};

export const postsSlice: Slice<Draft<PostsState>, any, "posts"> = createSlice({
  name: "posts",
  initialState: initialState,
  reducers: {
    removePost: postsAdapter.removeOne,
    resetPosts: () => initialState,
    upsertPost: (state, action: PayloadAction<FederatedPost>) => {
      if (action.payload.id) {
        postsAdapter.upsertOne(state, action.payload);
      }
      // if (accountID(state.account) === accountID(action.payload)) {
      //   state.account = action.payload;
      // }
    },
  },
  extraReducers: (builder) => {
    builder.addCase(createPost.pending, (state, action) => {
      // setFederated(state.status, action, "loading");
    });
    builder.addCase(createPost.fulfilled, (state, action) => {
      // setFederated(state.status, action, "loaded");
      postsAdapter.upsertOne(state, federatedPayload(action));
      if (publicVisibility(action.payload.visibility)) {
        state.postPages[defaultPostListingType] = state.postPages[defaultPostListingType] || [];
        const firstPage = state.postPages[defaultPostListingType][0] || [];
        state.postPages[defaultPostListingType][0] = [action.payload.id, ...firstPage];
      }
    });
    // builder.addCase(locallyUpsertPost.fulfilled, (state, action) => {
    //   // state.status = "loaded";
    //   postsAdapter.upsertOne(state, federatedPayload(action));
    // });
    // builder.addCase(createPost.rejected, (state, action) => {
    //   setFederated(state.status, action, "errored");
    // });
    builder.addCase(replyToPost.fulfilled, (state, action) => {
      // postsAdapter.upsertOne(state, action.payload);
      const reply = action.payload;
      const postIdPath = action.meta.arg.postIdPath;
      const basePostId = federateId(postIdPath[0]!, action);
      const basePost = postsAdapter.getSelectors().selectById(state, basePostId);
      if (!basePost) {
        console.error(`Root post ID (${basePostId}) not found.`);
        return;
      }
      const rootPost: Post = { ...basePost }

      let parentPost: Post = rootPost;
      for (const postId of postIdPath.slice(1)) {
        parentPost.replies = parentPost.replies.map(p => ({ ...p }));
        parentPost.responseCount += 1;
        if (postId === postIdPath[postIdPath.length - 1]) {
          parentPost.replyCount += 1;
        }
        const nextPost = parentPost.replies.find((reply) => reply.id === postId);
        if (!nextPost) {
          console.error(`Post ID (${postId}) not found along path ${JSON.stringify(postIdPath)}.`);
          return;
        }
        parentPost = nextPost;
      }
      parentPost.replies = [reply].concat(...parentPost.replies);
      postsAdapter.upsertOne(state, federatedEntity(rootPost, action));
    });
    builder.addCase(loadPostsPage.fulfilled, (state, action) => {
      setFederated(state.pagesStatus, action, "loaded");
      const federatedPosts = federatedEntities(action.payload.posts, action);
      federatedPosts.forEach(post => {
        const oldPost = selectPostById(state, post.id);
        postsAdapter.upsertOne(state, { ...post, replies: oldPost?.replies ?? post.replies });
      });

      const postIds = federatedPosts.map(post => federatedId(post));
      const page = action.meta.arg.page || 0;
      const listingType = action.meta.arg.listingType ?? defaultPostListingType;

      const serverPostPages: GroupedPages = getFederated(state.postPages, action);
      if (!serverPostPages[listingType] || page === 0) serverPostPages[listingType] = [];

      const postPages: PaginatedIds = serverPostPages[listingType]!;
      postPages[page] = postIds;
      setFederated(state.postPages, action, serverPostPages);
    });
    builder.addCase(loadPostsPage.rejected, (state, action) => {
      setFederated(state.pagesStatus, action, "errored");
    });
    builder.addCase(loadPost.fulfilled, (state, action) => {
      const federatedPost = federatedPayload(action);
      const oldPost = selectPostById(state, federatedId(federatedPost));
      postsAdapter.upsertOne(state, { ...federatedPost, replies: oldPost?.replies ?? action.payload.replies });
    });
    builder.addCase(loadPost.rejected, (state, action) => {
      state.failedPostIds.push(federateId((action.meta.arg as LoadPost).id, action));
    });
    builder.addCase(loadPostReplies.fulfilled, (state, action) => {
      console.log('loaded post replies', action.payload)
      // debugger;
      // Load the replies into the post tree.
      const postIdPath = action.meta.arg.postIdPath;
      const basePostId = federateId(postIdPath[0]!, action);
      const basePost = postsAdapter.getSelectors().selectById(state, basePostId);
      if (!basePost) {
        console.error(`Root post ID (${basePostId}) not found.`);
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
      // debugger;
      postsAdapter.upsertOne(state, federatedEntity(rootPost, action));
    });

    builder.addCase(loadUserPosts.fulfilled, (state, action) => {
      const { posts } = action.payload;
      upsertPosts(state, federatedEntities(posts, action));
    });
    builder.addCase(loadGroupPostsPage.fulfilled, (state, action) => {
      const { posts } = action.payload;
      upsertPosts(state, federatedEntities(posts, action));
    });

    const saveEventPost = (state: PostsState, action: PayloadAction<Event, any, any>) => {
      postsAdapter.upsertOne(state, federatedEntity(action.payload.post!, action));
    };
    builder.addCase(loadEvent.fulfilled, saveEventPost);
    builder.addCase(loadEventByInstance.fulfilled, saveEventPost);
    builder.addCase(updateEvent.fulfilled, saveEventPost);
    builder.addCase(createEvent.fulfilled, saveEventPost);
    builder.addCase(loadEventsPage.fulfilled, (state, action) => {
      const posts = action.payload.events.map(event => event.post!);
      upsertPosts(state, federatedEntities(posts, action));
    });
  },
});

export const { removePost, clearPostAlerts: clearPostAlerts, resetPosts, upsertPost } = postsSlice.actions;
export const { selectAll: selectAllPosts, selectById: selectPostById } = postsAdapter.getSelectors();
export const postsReducer = postsSlice.reducer;
// export const upsertPost = postRe;
const upsertPosts = postsAdapter.upsertMany;
export default postsReducer;
