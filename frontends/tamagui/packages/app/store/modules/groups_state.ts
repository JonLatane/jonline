import { Group, GroupListingType, GroupPost, Membership, Moderation } from "@jonline/api";

import {
  createEntityAdapter,
  createSlice,
  Dictionary,
  EntityAdapter,
  EntityId,
  PayloadAction
} from "@reduxjs/toolkit";
import { passes } from "app/utils/moderation_utils";
import moment from "moment";
import { createFederated, Federated, federatedEntities, federatedEntity, FederatedEntity, federatedId, federatedPayload, federateId, getFederated, parseFederatedId, serverHost, setFederated, toFederatedId } from '../federation';
import { createFederatedPagesStatus, FederatedPagesStatus, GroupedPages, PaginatedIds } from "../pagination";
import { store } from "../store";
import { GroupedEventInstancePages, serializeTimeFilter } from "./events_state";
import { createGroup, createGroupPost, defaultGroupListingType, deleteGroup, deleteGroupPost, joinLeaveGroup, loadGroup, loadGroupByShortname, loadGroupEventsPage, loadGroupMembers, loadGroupPostsPage, loadGroupsPage, loadPostGroupPosts, respondToMembershipRequest, updateGroup, updateMembership } from "./group_actions";
import { markGroupVisit } from "./local_app_configuration";

export type FederatedGroup = FederatedEntity<Group>;
export function federatedShortname(group: FederatedGroup): string {
  return `${group.shortname}@${group.serverHost}`;
}
export interface GroupsState {
  pagesStatus: FederatedPagesStatus;
  ids: EntityId[];
  entities: Dictionary<FederatedGroup>;
  // By GroupListingType -> page (as a number) -> groupIds
  pages: Federated<GroupedPages>;
  shortnameIds: Dictionary<string>;
  // By group ID -> membership group moderation -> page (as a number) -> memberships
  groupMembershipPages: Dictionary<Dictionary<Membership[][]>>;
  groupPostPages: GroupedPages;
  groupEventPages: GroupedEventInstancePages;
  postIdGroupPosts: Dictionary<GroupPost[]>;
  failedShortnames: string[];
  failedPostIdGroupPosts: string[];
  mutatingGroupIds: string[];
}


const groupsAdapter: EntityAdapter<FederatedGroup> = createEntityAdapter<FederatedGroup>({
  selectId: (group) => federatedId(group),
  sortComparer: (a, b) => moment.utc(b.createdAt).unix() - moment.utc(a.createdAt).unix(),
});

const initialState: GroupsState = {
  pagesStatus: createFederatedPagesStatus(),
  shortnameIds: {},
  groupMembershipPages: {},
  failedShortnames: [],
  pages: createFederated({}),
  groupPostPages: {},
  groupEventPages: {},
  postIdGroupPosts: {},
  failedPostIdGroupPosts: [],
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

export const groupsSlice = createSlice({
  name: "groups",
  initialState: initialState,
  reducers: {
    upsertGroup: groupsAdapter.upsertOne,
    removeGroup: groupsAdapter.removeOne,
    resetGroups: (state, action: PayloadAction<{ serverHost: string | undefined }>) => {
      if (!action.payload.serverHost) return;

      const groupIdsToRemove = state.ids
        .filter(id => parseFederatedId(id as string).serverHost === action.payload.serverHost);
      groupsAdapter.removeMany(state, groupIdsToRemove);
      state.failedShortnames = state.failedShortnames.filter(id => parseFederatedId(id).serverHost !== action.payload.serverHost);
      state.failedPostIdGroupPosts = state.failedPostIdGroupPosts.filter(id => parseFederatedId(id).serverHost !== action.payload.serverHost);

      delete state.pages.values[action.payload.serverHost];
      Object.keys(state.groupPostPages)
        .filter(id => parseFederatedId(id).serverHost === action.payload.serverHost)
        .forEach(id => delete state.groupPostPages[id]);
      Object.keys(state.groupEventPages)
        .filter(id => parseFederatedId(id).serverHost === action.payload.serverHost)
        .forEach(id => delete state.groupEventPages[id]);
      Object.keys(state.postIdGroupPosts)
        .filter(id => parseFederatedId(id).serverHost === action.payload.serverHost)
        .forEach(id => delete state.postIdGroupPosts[id]);
      // state.mutatingGroupIds = state.mutatingGroupIds.filter(id => parseFederatedId(id).serverHost !== action.payload.serverHost);
      delete state.pagesStatus.values[action.payload.serverHost];
    },
  },
  extraReducers: (builder) => {
    builder.addCase(createGroup.fulfilled, (state, action) => {
      const group = federatedPayload(action);
      groupsAdapter.upsertOne(state, group);
      const federatedGroupId = federatedId(group);
      state.shortnameIds[federatedShortname(group).toLowerCase()] = federatedGroupId;
      const pages = getFederated(state.pages, action) ?? {};
      if (pages[GroupListingType.ALL_GROUPS]?.[0]) {
        pages[GroupListingType.ALL_GROUPS][0] = [federatedGroupId, ...pages[GroupListingType.ALL_GROUPS][0]];
        setFederated(state.pages, action, pages);
      }
      setTimeout(() => {
        store.dispatch(markGroupVisit({ group }));
      }, 1);
    });
    builder.addCase(updateGroup.fulfilled, (state, action) => {
      const group = federatedPayload(action);
      const federatedGroupId = federatedId(group);
      groupsAdapter.upsertOne(state, group);
      state.shortnameIds[federatedShortname(group).toLowerCase()] = federatedGroupId;
      setTimeout(() => {
        store.dispatch(markGroupVisit({ group }));
      }, 1);
      setTimeout(() => {
        // TODO: Use separate dispatch to delete old shortname/ID link.
        //
        // state.shortnameIds[action.meta.arg.shortname] = undefined;
      }, 5000)
    });
    builder.addCase(deleteGroup.fulfilled, (state, action) => {
      const federatedGroupId = federateId(action.meta.arg.id, action);
      groupsAdapter.removeOne(state, federatedGroupId);
      const pages = getFederated(state.pages, action);
      if (pages?.[GroupListingType.ALL_GROUPS]?.[0]) {
        pages[GroupListingType.ALL_GROUPS][0] = pages[GroupListingType.ALL_GROUPS][0]
          .filter(id => id !== federatedGroupId);
      }
    });
    builder.addCase(loadGroupsPage.pending, (state, action) => {
      setFederated(state.pagesStatus, action, "loading");
    });
    builder.addCase(loadGroupsPage.fulfilled, (state, action) => {
      setFederated(state.pagesStatus, action, "loaded");
      const groups = federatedEntities(action.payload.groups, action);
      groupsAdapter.upsertMany(state, groups);
      groups.forEach(group => state.shortnameIds[federatedShortname(group).toLowerCase()] = federatedId(group));

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
      const postId = federateId(action.meta.arg.postId, action);
      state.postIdGroupPosts[postId] = groupPosts;
    });
    builder.addCase(loadPostGroupPosts.rejected, (state, action) => {
      const postId = federateId(action.meta.arg.postId, action);
      state.failedPostIdGroupPosts = [postId, ...state.failedPostIdGroupPosts];
    });

    builder.addCase(createGroupPost.fulfilled, (state, action) => {
      const groupPost = action.payload;

      const postId = federateId(groupPost.postId, action);
      state.postIdGroupPosts[postId] = [groupPost,
        ...(state.postIdGroupPosts[postId] ?? [])];

      setTimeout(() => {
        store.dispatch(loadGroupPostsPage({ groupId: action.payload.groupId, page: 0 }));
        store.dispatch(loadGroupEventsPage({ groupId: action.payload.groupId, page: 0 }));
      }, 1);
    });

    builder.addCase(deleteGroupPost.fulfilled, (state, action) => {
      const { groupId } = action.meta.arg;
      const postId = federateId(action.meta.arg.postId, action);
      state.postIdGroupPosts[postId] = (state.postIdGroupPosts[postId] ?? [])
        .filter(gp => gp.groupId !== groupId);
    });

    builder.addCase(loadGroupPostsPage.fulfilled, (state, action) => {
      const { posts } = action.payload;
      const postIds = posts.map(p => federateId(p.id, action));

      const groupId = federateId(action.meta.arg.groupId, action);
      const page = action.meta.arg.page ?? 0;
      if (!state.groupPostPages[groupId] || page === 0) state.groupPostPages[groupId] = [];
      state.groupPostPages[groupId]![page] = postIds;
    });

    builder.addCase(loadGroupEventsPage.fulfilled, (state, action) => {
      const { events } = action.payload;
      const eventInstanceIds = events.map(e => federateId(e.instances[0]!.id, action));

      // NOTE: EventsState adds the post data from this same response
      // on loadGroupPostsPage.fulfilled.

      const groupId = federateId(action.meta.arg.groupId, action);
      const page = action.meta.arg.page ?? 0;

      const serializedFilter = serializeTimeFilter(action.meta.arg.filter);
      if (!state.groupEventPages[groupId]) state.groupEventPages[groupId] = {};
      if (!state.groupEventPages[groupId]![serializedFilter] || page === 0) state.groupEventPages[groupId]![serializedFilter] = [];
      state.groupEventPages[groupId]![serializedFilter]![page] = eventInstanceIds;
    });

    builder.addCase(loadGroup.fulfilled, (state, action) => {
      const group = federatedPayload(action);
      groupsAdapter.upsertOne(state, group);
      state.shortnameIds[federatedShortname(group).toLowerCase()] = federatedId(group);
    });
    builder.addCase(loadGroupByShortname.fulfilled, (state, action) => {
      action.payload.forEach(serverGroup => {
        const group = federatedEntity(serverGroup, action);
        groupsAdapter.upsertOne(state, group);
        state.shortnameIds[federatedShortname(group).toLowerCase()] = federatedId(group);  
      });
    });
    builder.addCase(joinLeaveGroup.pending, (state, action) => {
      lockGroup(state, federateId(parseFederatedId(action.meta.arg.groupId).id, action));
    });
    builder.addCase(joinLeaveGroup.rejected, (state, action) => {
      unlockGroup(state, federateId(parseFederatedId(action.meta.arg.groupId).id, action));
    });
    builder.addCase(joinLeaveGroup.fulfilled, (state, action) => {
      const federatedGroupId = federateId(parseFederatedId(action.meta.arg.groupId).id, action);
      unlockGroup(state, federatedGroupId);
      let group = groupsAdapter.getSelectors().selectById(state, federatedGroupId)!;
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

      if (state.groupMembershipPages[action.meta.arg.groupId]?.[Moderation.MODERATION_UNKNOWN]?.[0]) {
        state.groupMembershipPages[action.meta.arg.groupId]![Moderation.MODERATION_UNKNOWN]![0] =
          state.groupMembershipPages[action.meta.arg.groupId]![Moderation.MODERATION_UNKNOWN]![0]!.map(
            m => m.userId === action.payload?.userId ? action.payload : m
          );
      }
    });
    builder.addCase(updateMembership.fulfilled, (state, action) => {
      const federatedGroupId = federateId(action.meta.arg.groupId, action);
      unlockGroup(state, federatedGroupId);
      if (!state.groupMembershipPages[federatedGroupId]) return;

      const membership = action.payload;
      if (state.groupMembershipPages[federatedGroupId]?.[Moderation.MODERATION_UNKNOWN]?.[0]) {
        state.groupMembershipPages[federatedGroupId]![Moderation.MODERATION_UNKNOWN]![0] =
          state.groupMembershipPages[federatedGroupId]![Moderation.MODERATION_UNKNOWN]![0]!.map(
            m => m.userId === membership?.userId ? membership : m
          );
      }

      const group = groupsAdapter.getSelectors().selectById(state, federatedGroupId);
      if (group && group.currentUserMembership?.userId === membership?.userId) {
        groupsAdapter.upsertOne(state, { ...group, currentUserMembership: action.payload });
      }
      // if (action.meta.arg.accept) {
      //   const result = action.payload as Membership;
      //   const currentUserMembership = action.meta.arg.userId === currentUserId ? result : undefined;
      //   group = { ...group, memberCount: (group.memberCount || 0) + 1, currentUserMembership };
      //   groupsAdapter.upsertOne(state, group);
      // } else if (action.meta.arg.userId === currentUserId) {
      //   group = { ...group, currentUserMembership: undefined };
      // }
      // groupsAdapter.upsertOne(state, group);
    });

    builder.addCase(loadGroupMembers.fulfilled, (state, action) => {
      const actionServerHost = serverHost(action);
      const page = action.meta.arg.page ?? 0;
      const moderation = action.meta.arg.groupModeration ?? Moderation.MODERATION_UNKNOWN;
      const groupId = toFederatedId(parseFederatedId(action.meta.arg.id, actionServerHost));
      const memberships = action.payload.members
        .map(m => m.membership)
        .filter(m => m) as Membership[];

      if (!state.groupMembershipPages[groupId]) state.groupMembershipPages[groupId] = {};
      if (!state.groupMembershipPages[groupId]![moderation]) state.groupMembershipPages[groupId]![moderation] = [];
      state.groupMembershipPages[groupId]![moderation]![page] = memberships;
    });
  },
});

export const { removeGroup, resetGroups } = groupsSlice.actions;

export const { selectAll: selectAllGroups, selectById: selectGroupById } = groupsAdapter.getSelectors();
export const groupsReducer = groupsSlice.reducer;
export default groupsReducer;
