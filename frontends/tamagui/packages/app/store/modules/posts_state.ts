import { Event, Post } from "@jonline/api";
import {
  Dictionary,
  EntityAdapter,
  EntityId, PayloadAction,
  createEntityAdapter,
  createSlice
} from "@reduxjs/toolkit";
import { publicOrPrivateVisibility } from "app/utils/visibility_utils";
import moment from "moment";
import { Federated, FederatedEntity, createFederated, federateId, federatedEntities, federatedEntity, federatedId, federatedPayload, getFederated, parseFederatedId, setFederated } from '../federation';
import { FederatedPagesStatus, GroupedPages, PaginatedIds, createFederatedPagesStatus } from "../pagination";
import { createEvent, loadEvent, loadEventsPage, updateEvent } from "./event_actions";
import { loadGroupPostsPage } from "./group_actions";
import { LoadPost, createPost, defaultPostListingType, deletePost, loadPost, loadPostReplies, loadPostsPage, replyToPost, updatePost } from './post_actions';
import { loadUserPosts, loadUserReplies } from "./user_actions";
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

export const postsSlice = createSlice({
  name: "posts",
  initialState: initialState,
  reducers: {
    removePost: postsAdapter.removeOne,
    // resetPosts: () => initialState,
    resetPosts: (state, action: PayloadAction<{ serverHost: string | undefined }>) => {
      if (!action.payload.serverHost) return;

      const postIdsToRemove = state.ids
        .filter(id => parseFederatedId(id as string).serverHost === action.payload.serverHost);
      postsAdapter.removeMany(state, postIdsToRemove);
      state.failedPostIds = state.failedPostIds.filter(id => parseFederatedId(id).serverHost !== action.payload.serverHost);
      delete state.postPages.values[action.payload.serverHost];
      delete state.pagesStatus.values[action.payload.serverHost];
    },
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
      const post = federatedPayload(action);
      postsAdapter.upsertOne(state, post);
      if (publicOrPrivateVisibility(action.payload.visibility)) {

        const serverPostPages: GroupedPages = getFederated(state.postPages, action);
        if (!serverPostPages[defaultPostListingType]) serverPostPages[defaultPostListingType] = [];

        const postPages: PaginatedIds = serverPostPages[defaultPostListingType]!;
        const firstPage = postPages[0] || [];
        postPages[0] = [federatedId(post), ...firstPage];
        setFederated(state.postPages, action, serverPostPages);
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

      const postIds = federatedPosts.map(federatedId);
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
    builder.addCase(updatePost.fulfilled, (state, action) => {
      const federatedPost = federatedPayload(action);
      const oldPost = selectPostById(state, federatedId(federatedPost));
      postsAdapter.upsertOne(state, { ...federatedPost, replies: oldPost?.replies ?? action.payload.replies });
      // if (action.meta.arg.postIdPath && action.meta.arg.postIdPath.length > 1) {
      //   debugger;
      //   const post = state.entities[action.meta.arg.postIdPath[0]!];
      //   if (post) {
      //     let parentPost: Post = { ...post };
      //     for (const postId of action.meta.arg.postIdPath.slice(1, -1)) {
      //       parentPost = parentPost.replies.find((reply) => reply.id === postId)!;
      //     }
      //     parentPost.replies = parentPost.replies.map(p => (
      //       p.id === action.payload.id
      //         ? action.payload
      //         : p
      //     ));
      //   }
      // }
    });
    builder.addCase(loadPost.rejected, (state, action) => {
      state.failedPostIds.push(federateId((action.meta.arg as LoadPost).id ?? '', action));
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
    builder.addCase(loadUserReplies.fulfilled, (state, action) => {
      const { posts } = action.payload;
      upsertPosts(state, federatedEntities(posts, action));
    });
    builder.addCase(loadGroupPostsPage.fulfilled, (state, action) => {
      const { posts } = action.payload;
      upsertPosts(state, federatedEntities(posts, action));
    });
    builder.addCase(deletePost.fulfilled, (state, action) => {
      postsAdapter.removeOne(state, federatedId(federatedPayload(action)));
    });

    const saveEventPosts = (state: PostsState, action: PayloadAction<Event, any, any>) => {
      const posts: Post[] = [action.payload.post!, ...action.payload.instances.map(i => i.post!)];
      // postsAdapter.upsertOne(state, federatedEntity(action.payload.post!, action));
      postsAdapter.upsertMany(state, federatedEntities(posts, action));
    };
    builder.addCase(loadEvent.fulfilled, saveEventPosts);
    builder.addCase(updateEvent.fulfilled, saveEventPosts);
    builder.addCase(createEvent.fulfilled, saveEventPosts);
    builder.addCase(loadEventsPage.fulfilled, (state, action) => {
      const posts: Post[] = action.payload.events.flatMap(event => [event.post!, ...event.instances.map(i => i.post!)]);
      upsertPosts(state, federatedEntities(posts, action));
    });
  },
});

export const { removePost, resetPosts, upsertPost } = postsSlice.actions;
export const { selectAll: selectAllPosts, selectById: selectPostById } = postsAdapter.getSelectors();
export const postsReducer = postsSlice.reducer;
// export const upsertPost = postRe;
const upsertPosts = postsAdapter.upsertMany;
export default postsReducer;
