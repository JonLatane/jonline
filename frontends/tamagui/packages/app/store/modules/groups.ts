import { EventListingType, GetEventsResponse, GetGroupsRequest, GetGroupsResponse, GetPostsResponse, Group, GroupPost, Post, PostListingType } from "@jonline/api";
import { formatError } from "@jonline/ui";

import {
  AsyncThunk,
  createAsyncThunk,
  createEntityAdapter,
  createSlice,
  Dictionary,
  Draft,
  EntityAdapter,
  EntityId,
  Slice
} from "@reduxjs/toolkit";
import moment from "moment";
import { AccountOrServer } from "../types";
import { getCredentialClient } from "./accounts";
import { GroupedPostPages, PostsState, selectPostById } from "./posts";
import { GroupedEventInstancePages } from "./events";
import { RootState } from "../store";

export interface GroupsState {
  status: "unloaded" | "loading" | "loaded" | "errored";
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
  draftGroup: Group.create(),
  shortnameIds: {},
  recentGroups: [],
  failedShortnames: [],
  groupPostPages: {},
  groupEventPages: {},
  postIdGroupPosts: {},
  ...groupsAdapter.getInitialState()
};

export type CreateGroup = AccountOrServer & Group;
export const createGroup: AsyncThunk<Group, CreateGroup, any> = createAsyncThunk<Group, CreateGroup>(
  "groups/create",
  async (createGroupRequest) => {
    let client = await getCredentialClient(createGroupRequest);
    return client.createGroup(createGroupRequest, client.credential);
  }
);

export type UpdateGroups = AccountOrServer & GetGroupsRequest;
export const updateGroups: AsyncThunk<GetGroupsResponse, UpdateGroups, any> = createAsyncThunk<GetGroupsResponse, UpdateGroups>(
  "groups/update",
  async (getGroupsRequest) => {
    let client = await getCredentialClient(getGroupsRequest);
    return await client.getGroups(getGroupsRequest, client.credential);
  }
);

export type LoadGroupPostsPage = AccountOrServer & { groupId: string, page?: number };
export const loadGroupPostsPage: AsyncThunk<GetPostsResponse, LoadGroupPostsPage, any> = createAsyncThunk<GetPostsResponse, LoadGroupPostsPage>(
  "groups/loadPostsPage",
  async (request) => {
    let client = await getCredentialClient(request);
    const result = await client.getPosts({ groupId: request.groupId, listingType: PostListingType.GROUP_POSTS }, client.credential);
    return result;
  }
);

export type LoadGroupEventsPage = AccountOrServer & { groupId: string, page?: number };
export const loadGroupEventsPage: AsyncThunk<GetEventsResponse, LoadGroupEventsPage, any> = createAsyncThunk<GetEventsResponse, LoadGroupEventsPage>(
  "groups/loadEventsPage",
  async (request) => {
    let client = await getCredentialClient(request);
    const result = await client.getEvents({ groupId: request.groupId, listingType: EventListingType.GROUP_EVENTS }, client.credential);
    return result;
  }
);

export type LoadGroup = { id: string } & AccountOrServer;
export const loadGroup: AsyncThunk<Group, LoadGroup, any> = createAsyncThunk<Group, LoadGroup>(
  "groups/loadOne",
  async (request) => {
    let client = await getCredentialClient(request);
    let response = await client.getGroups(GetGroupsRequest.create({ groupId: request.id }), client.credential);
    let group = response.groups[0]!;
    return group;
  }
);

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



    builder.addCase(loadGroupPostsPage.pending, (state) => {
      state.status = "loading";
      state.error = undefined;
    });
    builder.addCase(loadGroupPostsPage.fulfilled, (state, action) => {
      state.status = "loaded";
      const { posts } = action.payload;
      const postIds = posts.map(p => p.id);

      // TODO: add GroupPosts to PostsState

      const groupId = action.meta.arg.groupId;
      const page = action.meta.arg.page;
      if (!state.groupPostPages[groupId] || page === 0) state.groupPostPages[groupId] = {};
      const postPages: Dictionary<string[]> = state.groupPostPages[groupId]!;
      // Sensible approach:
      // postPages[page] = postIds;

      // Chunked approach: (note that we re-initialize `postPages` when `page` == 0)
      let initialPage: number = 0;
      while (postPages[initialPage]) {
        initialPage++;
      }
      const chunkSize = 10;
      for (let i = 0; i < postIds.length; i += chunkSize) {
        const chunk = postIds.slice(i, i + chunkSize);
        state.groupPostPages[groupId]![initialPage + (i/chunkSize)] = chunk;
      }
      if (state.groupPostPages[groupId]![0] == undefined) {
        state.groupPostPages[groupId]![0] = [];
      }

      state.successMessage = `Group Posts for ${action.meta.arg.groupId} loaded.`;
    });
    builder.addCase(loadGroupPostsPage.rejected, (state, action) => {
      state.status = "errored";
      state.error = action.error as Error;
      state.errorMessage = formatError(action.error as Error);
      state.error = action.error as Error;
    });

    builder.addCase(loadGroupEventsPage.pending, (state) => {
      state.status = "loading";
      state.error = undefined;
    });
    builder.addCase(loadGroupEventsPage.fulfilled, (state, action) => {
      state.status = "loaded";
      const { events } = action.payload;
      const eventInstanceIds = events.map(e => e.instances[0]!.id);

      // TODO: add GroupPosts to PostsState

      const groupId = action.meta.arg.groupId;
      const page = action.meta.arg.page;
      if (!state.groupEventPages[groupId] || page === 0) state.groupEventPages[groupId] = {};
      const postPages: Dictionary<string[]> = state.groupEventPages[groupId]!;
      // Sensible approach:
      // postPages[page] = postIds;

      // Chunked approach: (note that we re-initialize `postPages` when `page` == 0)
      let initialPage: number = 0;
      while (postPages[initialPage]) {
        initialPage++;
      }
      const chunkSize = 10;
      for (let i = 0; i < eventInstanceIds.length; i += chunkSize) {
        const chunk = eventInstanceIds.slice(i, i + chunkSize);
        state.groupEventPages[groupId]![initialPage + (i/chunkSize)] = chunk;
      }
      if (state.groupEventPages[groupId]![0] == undefined) {
        state.groupEventPages[groupId]![0] = [];
      }

      state.successMessage = `Group Events for ${action.meta.arg.groupId} loaded.`;
    });
    builder.addCase(loadGroupEventsPage.rejected, (state, action) => {
      state.status = "errored";
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
