import { formatError, GetGroupsRequest, GetGroupsResponse, GetPostsRequest, GetPostsResponse, Group, GroupPost, PostListingType } from "@jonline/ui/src";
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
import store from "../store";
import { AccountOrServer } from "../types";
import { getCredentialClient } from "./accounts";
import { LoadPostsRequest, upsertPosts } from "./posts";

export interface GroupsState {
  status: "unloaded" | "loading" | "loaded" | "errored";
  error?: Error;
  successMessage?: string;
  errorMessage?: string;
  draftGroup: Group;
  ids: EntityId[];
  entities: Dictionary<Group>;
  avatars: Dictionary<string>;
  shortnameIds: Dictionary<string>;
  idGroupPosts: Dictionary<GroupPost[]>;
  failedShortnames: string[];
  recentGroups: EntityId[];
}

const groupsAdapter: EntityAdapter<Group> = createEntityAdapter<Group>({
  selectId: (group) => group.id,
  sortComparer: (a, b) => moment.utc(b.createdAt).unix() - moment.utc(a.createdAt).unix(),
});

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

export type LoadGroupAvatar = Group & AccountOrServer;
export const loadGroupAvatar: AsyncThunk<string, LoadGroupAvatar, any> = createAsyncThunk<string, LoadGroupAvatar>(
  "groups/loadAvatar",
  async (request) => {
    let client = await getCredentialClient(request);
    let response = await client.getGroups(GetGroupsRequest.create({ groupId: request.id }), client.credential);
    let group = response.groups[0]!;
    return group.avatar
      ? URL.createObjectURL(new Blob([group.avatar!], { type: 'image/png' }))
      : '';
  }
);

export type UpdateGroupPosts = AccountOrServer & { groupId: string };
export const updateGroupPosts: AsyncThunk<GetPostsResponse, UpdateGroupPosts, any> = createAsyncThunk<GetPostsResponse, UpdateGroupPosts>(
  "groups/updatePosts",
  async (request) => {
    let client = await getCredentialClient(request);
    const result = await client.getPosts({ groupId: request.groupId, listingType: PostListingType.GROUP_POSTS }, client.credential);
    return result;
  }
);


export type LoadGroup = { id: string } & AccountOrServer;
export type LoadGroupResult = {
  group: Group;
  avatar: string;
}
export const loadGroup: AsyncThunk<LoadGroupResult, LoadGroup, any> = createAsyncThunk<LoadGroupResult, LoadGroup>(
  "groups/loadOne",
  async (request) => {
    let client = await getCredentialClient(request);
    let response = await client.getGroups(GetGroupsRequest.create({ groupId: request.id }), client.credential);
    let group = response.groups[0]!;
    let avatar = group.avatar
      ? URL.createObjectURL(new Blob([group.avatar!], { type: 'image/png' }))
      : '';
    return { group: { ...group, avatar: undefined }, avatar };
  }
);

const initialState: GroupsState = {
  status: "unloaded",
  draftGroup: Group.create(),
  avatars: {},
  shortnameIds: {},
  idGroupPosts: {},
  recentGroups: [],
  failedShortnames: [],
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



    builder.addCase(updateGroupPosts.pending, (state) => {
      state.status = "loading";
      state.error = undefined;
    });
    builder.addCase(updateGroupPosts.fulfilled, (state, action) => {
      state.status = "loaded";
      const { posts } = action.payload;
      const newPostIds = new Set(posts.map(p => p.id));
      const newGroupPosts = posts.map((p) => p.currentGroupPost!);//.filter((p) => p);
      setTimeout(() => upsertPosts(store.getState().posts, posts), 1);
      const updatedGroupPosts = state.idGroupPosts[action.meta.arg.groupId]
        ?.filter((p) => !newPostIds.has(p.postId))
        || [];
      updatedGroupPosts.push(...newGroupPosts);
      updatedGroupPosts.sort((a, b) => a.createdAt! == b.createdAt! ? 0
        : a.createdAt! < b.createdAt! ? 1 : -1);
      state.idGroupPosts[action.meta.arg.groupId] = updatedGroupPosts;
      state.successMessage = `Group Posts loaded.`;
    });
    builder.addCase(updateGroupPosts.rejected, (state, action) => {
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
      const { group, avatar } = action.payload;
      groupsAdapter.upsertOne(state, group);
      state.shortnameIds[group.shortname] = group.id;
      state.avatars[action.meta.arg.id] = avatar;
      state.successMessage = `Group data loaded.`;
    });
    builder.addCase(loadGroup.rejected, (state, action) => {
      state.status = "errored";
      state.error = action.error as Error;
      state.errorMessage = formatError(action.error as Error);
      state.error = action.error as Error;
    });
    builder.addCase(loadGroupAvatar.fulfilled, (state, action) => {
      state.avatars[action.meta.arg.id] = action.payload;
      state.successMessage = `Avatar image loaded.`;
    });
  },
});

export const { removeGroup, clearGroupAlerts, resetGroups } = groupsSlice.actions;

export const { selectAll: selectAllGroups, selectById: selectGroupById } = groupsAdapter.getSelectors();
export const groupsReducer = groupsSlice.reducer;
export default groupsReducer;
