import { Group, GroupPost } from "@jonline/api";
import { formatError } from "@jonline/ui";

import {
  createEntityAdapter,
  createSlice,
  Dictionary,
  Draft,
  EntityAdapter,
  EntityId,
  Slice
} from "@reduxjs/toolkit";
import moment from "moment";
import { GroupedEventInstancePages } from "./events";
import { createGroup, createGroupPost, deleteGroupPost, loadGroup, loadGroupEventsPage, loadGroupPostsPage, loadPostGroupPosts, updateGroups } from "./group_actions";
import { GroupedPostPages } from "./posts";
import { store } from "../store";

export interface GroupsState {
  status: "unloaded" | "loading" | "loaded" | "errored";
  postPageStatus: "unloaded" | "loading" | "loaded" | "errored";
  eventPageStatus: "unloaded" | "loading" | "loaded" | "errored";
  groupPostsStatus: undefined | "loading" | "loaded" | "errored";
  error?: Error;
  successMessage?: string;
  errorMessage?: string;
  draftGroup: Group;
  ids: EntityId[];
  entities: Dictionary<Group>;
  shortnameIds: Dictionary<string>;
  groupPostPages: GroupedPostPages;
  groupEventPages: GroupedEventInstancePages;
  postIdGroupPosts: Dictionary<GroupPost[]>;
  failedShortnames: string[];
  recentGroups: EntityId[];
}


const groupsAdapter: EntityAdapter<Group> = createEntityAdapter<Group>({
  selectId: (group) => group.id,
  sortComparer: (a, b) => moment.utc(b.createdAt).unix() - moment.utc(a.createdAt).unix(),
});

const initialState: GroupsState = {
  status: "unloaded",
  postPageStatus: "unloaded",
  eventPageStatus: "unloaded",
  groupPostsStatus: undefined,
  draftGroup: Group.create(),
  shortnameIds: {},
  recentGroups: [],
  failedShortnames: [],
  groupPostPages: {},
  groupEventPages: {},
  postIdGroupPosts: {},
  ...groupsAdapter.getInitialState(),
};

export const groupsSlice: Slice<Draft<GroupsState>, any, "groups"> = createSlice({
  name: "groups",
  initialState: initialState,
  reducers: {
    upsertGroup: groupsAdapter.upsertOne,
    removeGroup: groupsAdapter.removeOne,
    resetGroups: () => initialState,
    clearGroupAlerts: (state) => {
      state.errorMessage = undefined;
      state.successMessage = undefined;
      state.error = undefined;
    },
  },
  extraReducers: (builder) => {
    builder.addCase(createGroup.pending, (state) => {
      state.status = "loading";
      state.error = undefined;
    });
    builder.addCase(createGroup.fulfilled, (state, action) => {
      state.status = "loaded";
      const group = action.payload;
      groupsAdapter.upsertOne(state, group);
      state.shortnameIds[group.shortname] = group.id;
      state.successMessage = `Group created.`;
    });
    builder.addCase(createGroup.rejected, (state, action) => {
      state.status = "errored";
      state.error = action.error as Error;
      state.errorMessage = formatError(action.error as Error);
      state.error = action.error as Error;
    });
    builder.addCase(updateGroups.pending, (state) => {
      state.status = "loading";
      state.error = undefined;
    });
    builder.addCase(updateGroups.fulfilled, (state, action) => {
      state.status = "loaded";
      groupsAdapter.upsertMany(state, action.payload.groups);
      action.payload.groups.forEach(g => state.shortnameIds[g.shortname] = g.id);
      state.successMessage = `Groups loaded.`;
    });
    builder.addCase(updateGroups.rejected, (state, action) => {
      state.status = "errored";
      state.error = action.error as Error;
      state.errorMessage = formatError(action.error as Error);
      state.error = action.error as Error;
    });


    builder.addCase(loadPostGroupPosts.fulfilled, (state, action) => {
      const { groupPosts } = action.payload;
      state.postIdGroupPosts[action.meta.arg.postId] = groupPosts;
      // state.successMessage = `${groupPosts.length} Group Posts loaded for PostID=${action.meta.arg.postId}.`;
    });

    builder.addCase(createGroupPost.fulfilled, (state, action) => {
      const groupPost = action.payload;

      state.postIdGroupPosts[groupPost.postId] = [groupPost,
        ...(state.postIdGroupPosts[groupPost.postId] ?? [])];

      setTimeout(() => {
        store.dispatch(loadGroupPostsPage({ groupId: action.payload.groupId, page: 0 }));
      }, 1);
    });

    builder.addCase(deleteGroupPost.fulfilled, (state, action) => {
      const { postId, groupId } = action.meta.arg;
      state.postIdGroupPosts[postId] = (state.postIdGroupPosts[postId] ?? [])
        .filter(gp => gp.groupId !== groupId);
    });

    builder.addCase(loadGroupPostsPage.pending, (state) => {
      state.postPageStatus = "loading";
      state.error = undefined;
    });
    builder.addCase(loadGroupPostsPage.fulfilled, (state, action) => {
      state.postPageStatus = "loaded";
      const { posts } = action.payload;
      const postIds = posts.map(p => p.id);

      // NOTE: PostsState adds the post data from this same response
      // on loadGroupPostsPage.fulfilled.

      const groupId = action.meta.arg.groupId;
      const page = action.meta.arg.page;
      if (!state.groupPostPages[groupId] || page === 0) state.groupPostPages[groupId] = {};
      const postPages: Dictionary<string[]> = state.groupPostPages[groupId]!;
      // Sensible approach:
      // postPages[page] = postIds;

      // Chunked approach: (note that we re-initialize `postPages` when `page` == 0)
      let initialPage: number = 0;
      while (action.meta.arg.page && postPages[initialPage]) {
        initialPage++;
      }
      const chunkSize = 10;
      for (let i = 0; i < postIds.length; i += chunkSize) {
        const chunk = postIds.slice(i, i + chunkSize);
        state.groupPostPages[groupId]![initialPage + (i / chunkSize)] = chunk;
      }
      if (state.groupPostPages[groupId]![0] == undefined) {
        state.groupPostPages[groupId]![0] = [];
      }

      state.successMessage = `Group Posts for ${action.meta.arg.groupId} loaded.`;
    });
    builder.addCase(loadGroupPostsPage.rejected, (state, action) => {
      state.postPageStatus = "errored";
      state.error = action.error as Error;
      state.errorMessage = formatError(action.error as Error);
      state.error = action.error as Error;
    });

    builder.addCase(loadGroupEventsPage.pending, (state) => {
      state.eventPageStatus = "loading";
      state.error = undefined;
    });
    builder.addCase(loadGroupEventsPage.fulfilled, (state, action) => {
      state.eventPageStatus = "loaded";
      const { events } = action.payload;
      const eventInstanceIds = events.map(e => e.instances[0]!.id);

      // NOTE: EventsState adds the post data from this same response
      // on loadGroupPostsPage.fulfilled.

      const groupId = action.meta.arg.groupId;
      const page = action.meta.arg.page;
      if (!state.groupEventPages[groupId] || page === 0) state.groupEventPages[groupId] = {};
      const eventPages: Dictionary<string[]> = state.groupEventPages[groupId]!;
      // Sensible approach:
      // postPages[page] = postIds;

      // Chunked approach: (note that we re-initialize `postPages` when `page` == 0)
      let initialPage: number = 0;
      while (action.meta.arg.page && eventPages[initialPage]) {
        initialPage++;
      }
      const chunkSize = 10;
      for (let i = 0; i < eventInstanceIds.length; i += chunkSize) {
        const chunk = eventInstanceIds.slice(i, i + chunkSize);
        state.groupEventPages[groupId]![initialPage + (i / chunkSize)] = chunk;
      }
      if (state.groupEventPages[groupId]![0] == undefined) {
        state.groupEventPages[groupId]![0] = [];
      }

      state.successMessage = `Group Events for ${action.meta.arg.groupId} loaded.`;
    });
    builder.addCase(loadGroupEventsPage.rejected, (state, action) => {
      state.eventPageStatus = "errored";
      state.error = action.error as Error;
      state.errorMessage = formatError(action.error as Error);
      state.error = action.error as Error;
    });

    builder.addCase(loadGroup.pending, (state) => {
      state.status = "loading";
      state.error = undefined;
    });
    builder.addCase(loadGroup.fulfilled, (state, action) => {
      state.status = "loaded";
      const group = action.payload;
      groupsAdapter.upsertOne(state, group);
      state.shortnameIds[group.shortname] = group.id;
      state.successMessage = `Group data loaded.`;
    });
    builder.addCase(loadGroup.rejected, (state, action) => {
      state.status = "errored";
      state.error = action.error as Error;
      state.errorMessage = formatError(action.error as Error);
      state.error = action.error as Error;
    });
  },
});

export const { removeGroup, clearGroupAlerts, resetGroups } = groupsSlice.actions;

export const { selectAll: selectAllGroups, selectById: selectGroupById } = groupsAdapter.getSelectors();
export const groupsReducer = groupsSlice.reducer;
export default groupsReducer;
