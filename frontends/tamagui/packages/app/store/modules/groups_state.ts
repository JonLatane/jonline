import { Group, GroupPost, Membership } from "@jonline/api";

import {
  createEntityAdapter,
  createSlice,
  Dictionary,
  Draft,
  EntityAdapter,
  EntityId,
  Slice
} from "@reduxjs/toolkit";
import { passes } from "app/utils/moderation_utils";
import moment from "moment";
import { createFederated, Federated, federatedEntities, FederatedEntity, federatedId, federatedPayload, federateId, getFederated, setFederated } from "../federation";
import { createFederatedPagesStatus, GroupedPages, PaginatedIds } from "../pagination";
import { store } from "../store";
import { GroupedEventInstancePages, serializeTimeFilter } from "./events_state";
import { createGroup, createGroupPost, defaultGroupListingType, deleteGroup, deleteGroupPost, joinLeaveGroup, loadGroup, loadGroupEventsPage, loadGroupPostsPage, loadGroupsPage, loadPostGroupPosts, respondToMembershipRequest, updateGroup } from "./group_actions";

export type FederatedGroup = FederatedEntity<Group>;

export interface GroupsState {
  pagesStatus: Federated<"unloaded" | "loading" | "loaded" | "errored">;
  ids: EntityId[];
  entities: Dictionary<FederatedGroup>;
  // By GroupListingType -> page (as a number) -> groupIds
  pages: Federated<GroupedPages>;
  shortnameIds: Federated<Dictionary<string>>;
  groupPostPages: Federated<GroupedPages>;
  groupEventPages: Federated<GroupedEventInstancePages>;
  postIdGroupPosts: Federated<Dictionary<GroupPost[]>>;
  failedShortnames: Federated<string[]>;
  mutatingGroupIds: string[];
}


const groupsAdapter: EntityAdapter<FederatedGroup> = createEntityAdapter<FederatedGroup>({
  selectId: (group) => federatedId(group),
  sortComparer: (a, b) => moment.utc(b.createdAt).unix() - moment.utc(a.createdAt).unix(),
});

const initialState: GroupsState = {
  pagesStatus: createFederatedPagesStatus(),
  shortnameIds: createFederated({}),
  failedShortnames: createFederated([]),
  pages: createFederated({}),
  groupPostPages: createFederated({}),
  groupEventPages: createFederated({}),
  postIdGroupPosts: createFederated({}),
  mutatingGroupIds: [],
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
  },
  extraReducers: (builder) => {
    // builder.addCase(createGroup.pending, (state) => {
    //   state.status = "loading";
    // });
    builder.addCase(createGroup.fulfilled, (state, action) => {
      // console.log("createGroup.fulfilled");
      // state.status = "loaded";
      const group = federatedPayload(action);
      groupsAdapter.upsertOne(state, group);
      state.shortnameIds[group.shortname] = group.id;
    });
    // builder.addCase(createGroup.rejected, (state, action) => {
    //   console.log("createGroup.rejected");
    //   state.status = "errored";
    //   state.error = action.error as Error;
    //   state.errorMessage = formatError(action.error as Error);
    //   state.error = action.error as Error;
    // });
    builder.addCase(updateGroup.fulfilled, (state, action) => {
      const group = federatedPayload(action);
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
    builder.addCase(loadGroupsPage.pending, (state, action) => {
      setFederated(state.pagesStatus, action, "loading");
    });
    builder.addCase(loadGroupsPage.fulfilled, (state, action) => {
      setFederated(state.pagesStatus, action, "loaded");
      const groups = federatedEntities(action.payload.groups, action);
      groupsAdapter.upsertMany(state, groups);
      const shortnameIds = getFederated(state.shortnameIds, action);
      action.payload.groups.forEach(g => shortnameIds[g.shortname] = g.id);
      setFederated(state.shortnameIds, action, shortnameIds);

      const page = action.meta.arg.page || 0;
      const listingType = action.meta.arg.listingType ?? defaultGroupListingType;


      const serverPages: GroupedPages = getFederated(state.pages, action);
      if (!serverPages[listingType] || page === 0) serverPages[listingType] = [];

      const pages: PaginatedIds = serverPages[listingType]!;
      // Sensible approach:
      pages[page] = groups.map(g => federatedId(g));
      setFederated(state.pages, action, serverPages);
    });
    builder.addCase(loadGroupsPage.rejected, (state, action) => {
      setFederated(state.pagesStatus, action, "errored");
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

    builder.addCase(loadGroupPostsPage.fulfilled, (state, action) => {
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
    });

    builder.addCase(loadGroupEventsPage.fulfilled, (state, action) => {
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
    });
    // builder.addCase(loadGroupEventsPage.rejected, (state, action) => {
    //   state.eventPageStatus = "errored";
    //   state.error = action.error as Error;
    //   state.errorMessage = formatError(action.error as Error);
    //   state.error = action.error as Error;
    // });

    builder.addCase(loadGroup.fulfilled, (state, action) => {
      const group = federatedPayload(action);
      groupsAdapter.upsertOne(state, group);
      state.shortnameIds[group.shortname] = group.id;
    });
    builder.addCase(joinLeaveGroup.pending, (state, action) => {
      lockGroup(state, federateId(action.meta.arg.groupId, action));
    });
    builder.addCase(joinLeaveGroup.rejected, (state, action) => {
      unlockGroup(state, federateId(action.meta.arg.groupId, action));
    });
    builder.addCase(joinLeaveGroup.fulfilled, (state, action) => {
      unlockGroup(state, federateId(action.meta.arg.groupId, action));
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
      lockGroup(state, federateId(action.meta.arg.groupId, action));
    });
    builder.addCase(respondToMembershipRequest.rejected, (state, action) => {
      unlockGroup(state, federateId(action.meta.arg.groupId, action));
    });
    builder.addCase(respondToMembershipRequest.fulfilled, (state, action) => {
      unlockGroup(state, federateId(action.meta.arg.groupId, action));
      const currentUserId = action.meta.arg.account?.user?.id;
      let group: FederatedGroup = groupsAdapter.getSelectors().selectById(state, action.meta.arg.groupId)!;
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

export const { removeGroup, resetGroups } = groupsSlice.actions;

export const { selectAll: selectAllGroups, selectById: selectGroupById } = groupsAdapter.getSelectors();
export const groupsReducer = groupsSlice.reducer;
export default groupsReducer;
