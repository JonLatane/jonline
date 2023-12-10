import { Group, GroupPost, Membership } from "@jonline/api";
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
import { GroupedEventInstancePages, serializeTimeFilter } from "./events_state";
import { createGroup, createGroupPost, deleteGroupPost, joinLeaveGroup, loadGroup, loadGroupEventsPage, loadGroupPostsPage, loadPostGroupPosts, respondToMembershipRequest, loadGroupsPage, updateGroup, deleteGroup } from "./group_actions";
import { store } from "../store";
import { passes } from "app/utils/moderation_utils";
import { usersAdapter } from "./users_state";
import { GroupedPages, PaginatedIds } from "../pagination/post_pagination";

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
  // By GroupListingType -> page (as a number) -> groupIds
  pages: GroupedPages;
  shortnameIds: Dictionary<string>;
  groupPostPages: GroupedPages;
  groupEventPages: GroupedEventInstancePages;
  postIdGroupPosts: Dictionary<GroupPost[]>;
  failedShortnames: string[];
  mutatingGroupIds: string[];
  membershipPages: Dictionary<Membership[][]>;
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
  failedShortnames: [],
  pages: {},
  groupPostPages: {},
  groupEventPages: {},
  postIdGroupPosts: {},
  mutatingGroupIds: [],
  membershipPages: {},
  ...groupsAdapter.getInitialState(),
};

function lockGroup(state: GroupsState, groupId: string) {
  state.mutatingGroupIds = [groupId, ...state.mutatingGroupIds];
}
function unlockGroup(state: GroupsState, groupId: string) {
  state.mutatingGroupIds = state.mutatingGroupIds.filter(u => u != groupId);
}
export function isGroupLocked(state: GroupsState, groupId: string): boolean {
  return state.mutatingGroupIds.includes(groupId);
}

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
      console.log("createGroup.fulfilled");
      state.status = "loaded";
      const group = action.payload;
      groupsAdapter.upsertOne(state, group);
      state.shortnameIds[group.shortname] = group.id;
      state.successMessage = `Group created.`;
    });
    builder.addCase(createGroup.rejected, (state, action) => {
      console.log("createGroup.rejected");
      state.status = "errored";
      state.error = action.error as Error;
      state.errorMessage = formatError(action.error as Error);
      state.error = action.error as Error;
    });
    builder.addCase(updateGroup.fulfilled, (state, action) => {
      const group = action.payload;
      groupsAdapter.upsertOne(state, group);
      state.shortnameIds[action.meta.arg.shortname] = undefined;
      state.shortnameIds[group.shortname] = group.id;
      setTimeout(() => {
        // TODO: Use separate dispatch to delete old shortname/ID link.
        //
        // state.shortnameIds[action.meta.arg.shortname] = undefined;
      }, 5000)
    });
    builder.addCase(deleteGroup.fulfilled, (state, action) => {
      groupsAdapter.removeOne(state, action.meta.arg.id);
    });
    builder.addCase(loadGroupsPage.pending, (state) => {
      state.status = "loading";
      state.error = undefined;
    });
    builder.addCase(loadGroupsPage.fulfilled, (state, action) => {
      state.status = "loaded";
      groupsAdapter.upsertMany(state, action.payload.groups);
      action.payload.groups.forEach(g => state.shortnameIds[g.shortname] = g.id);
      state.successMessage = `Groups loaded.`;
    });
    builder.addCase(loadGroupsPage.rejected, (state, action) => {
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
        store.dispatch(loadGroupEventsPage({ groupId: action.payload.groupId, page: 0 }));
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
      if (!state.groupPostPages[groupId] || page === 0) state.groupPostPages[groupId] = [];
      const postPages: PaginatedIds = state.groupPostPages[groupId]!;
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

      const serializedFilter = serializeTimeFilter(action.meta.arg.filter);
      if (!state.groupEventPages[groupId]) state.groupEventPages[groupId] = {};
      if (!state.groupEventPages[groupId]![serializedFilter] || page === 0) state.groupEventPages[groupId]![serializedFilter] = [];

      const eventPages: string[][] = state.groupEventPages[groupId]![serializedFilter]!;
      // Sensible approach:
      // postPages[page] = postIds;

      // Chunked approach: (note that we re-initialize `postPages` when `page` == 0)
      let initialPage: number = 0;
      while (action.meta.arg.page && eventPages[initialPage]) {
        initialPage++;
      }
      const chunkSize = 7;
      for (let i = 0; i < eventInstanceIds.length; i += chunkSize) {
        const chunk = eventInstanceIds.slice(i, i + chunkSize);
        state.groupEventPages[groupId]![serializedFilter]![initialPage + (i / chunkSize)] = chunk;
      }
      if (state.groupEventPages[groupId]![serializedFilter]![0] == undefined) {
        state.groupEventPages[groupId]![serializedFilter]![0] = [];
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
    builder.addCase(joinLeaveGroup.pending, (state, action) => {
      lockGroup(state, action.meta.arg.groupId);
    });
    builder.addCase(joinLeaveGroup.rejected, (state, action) => {
      unlockGroup(state, action.meta.arg.groupId);
    });
    builder.addCase(joinLeaveGroup.fulfilled, (state, action) => {
      unlockGroup(state, action.meta.arg.groupId);
      let group = groupsAdapter.getSelectors().selectById(state, action.meta.arg.groupId)!;
      // let currentUser = usersAdapter.getSelectors().selectById(state, action.meta.arg.account!.user.id);
      if (action.meta.arg.join) {
        const result = action.payload as Membership;
        if (passes(result.userModeration) && passes(result.groupModeration)) {
          group = { ...group, memberCount: (group.memberCount || 0) + 1 };
          // if (currentUser) {
          //   currentUser = { ...currentUser, groupCount: (currentUser.groupCount || 0) + 1 };
          // }
        }
        group = { ...group, currentUserMembership: result };
      } else {
        if (passes(group.currentUserMembership?.userModeration) && passes(group.currentUserMembership?.groupModeration)) {
          group = { ...group, memberCount: (group.memberCount || 0) - 1 };
          // if (currentUser) {
          //   currentUser = { ...currentUser, groupCount: (currentUser.groupCount || 0) - 1 };
          // }
        }
        group = { ...group, currentUserMembership: undefined };
      }
      groupsAdapter.upsertOne(state, group);
      // if (currentUser) {
      //   groupsAdapter.upsertOne(state, currentUser);
      // }
    });

    builder.addCase(respondToMembershipRequest.pending, (state, action) => {
      lockGroup(state, action.meta.arg.groupId);
    });
    builder.addCase(respondToMembershipRequest.rejected, (state, action) => {
      unlockGroup(state, action.meta.arg.groupId);
    });
    builder.addCase(respondToMembershipRequest.fulfilled, (state, action) => {
      unlockGroup(state, action.meta.arg.groupId);
      const currentUserId = action.meta.arg.account?.user?.id;
      let group: Group = groupsAdapter.getSelectors().selectById(state, action.meta.arg.groupId)!;
      if (action.meta.arg.accept) {
        const result = action.payload as Membership;
        const currentUserMembership = action.meta.arg.userId === currentUserId ? result : undefined;
        group = { ...group, memberCount: (group.memberCount || 0) + 1, currentUserMembership };
        groupsAdapter.upsertOne(state, group);
      } else if (action.meta.arg.userId === currentUserId) {
        group = { ...group, currentUserMembership: undefined };
      }
      groupsAdapter.upsertOne(state, group);
    });
  },
});

export const { removeGroup, clearGroupAlerts, resetGroups } = groupsSlice.actions;

export const { selectAll: selectAllGroups, selectById: selectGroupById } = groupsAdapter.getSelectors();
export const groupsReducer = groupsSlice.reducer;
export default groupsReducer;
