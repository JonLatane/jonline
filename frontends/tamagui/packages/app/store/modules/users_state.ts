import { Follow, User, UserListingType } from "@jonline/api";
import {
  Dictionary,
  Draft,
  EntityAdapter,
  EntityId,
  PayloadAction,
  Slice,
  createEntityAdapter,
  createSlice
} from "@reduxjs/toolkit";
import { passes } from "app/utils/moderation_utils";
import moment from "moment";
import { AccountOrServer, FederatedPagesStatus, PaginatedIds, createFederatedPagesStatus, notifyUserDeleted, store, upsertUserData } from "..";
import { Federated, FederatedAction, FederatedEntity, HasServer, createFederated, federateId, federatedEntities, federatedEntity, federatedEntityId, federatedId, getFederated, setFederated } from '../federation';
import { LoadUser, LoadUsername, defaultUserListingType, deleteUser, followUnfollowUser, loadUser, loadUserEvents, loadUserPosts, loadUserReplies, loadUsername, loadUsersPage, respondToFollowRequest, updateUser } from "./user_actions";
import { useAccountOrServer } from "app/hooks";

export type FederatedUser = FederatedEntity<User>;
export function federatedUsername(user: FederatedUser): string {
  return `${user.username}@${user.serverHost}`;
}

export interface UsersState {
  pagesStatus: FederatedPagesStatus;
  ids: EntityId[];
  entities: Dictionary<FederatedUser>;
  usernameIds: Federated<Dictionary<string>>;
  failedUsernames: Federated<string[]>;
  failedUserIds: string[];
  idPosts: Dictionary<string[]>;
  idReplies: Dictionary<string[]>;
  idEventInstances: Dictionary<string[]>;
  // Stores pages of listed users for listing types used in the UI.
  // i.e.: userPages[PostListingType.ALL_ACCESSIBLE_POSTS][1] -> ["userId1", "userId2"].
  // Users should be loaded from the adapter/slice's entities.
  // Maps UserListingType -> page -> userIds
  userPages: Federated<Dictionary<PaginatedIds>>;
  mutatingUserIds: string[];
}


export interface UsersSlice {
  adapter: EntityAdapter<User>;
}

export const usersAdapter: EntityAdapter<FederatedUser> = createEntityAdapter<FederatedUser>({
  selectId: (user) => federatedId(user),
  sortComparer: (a, b) => moment.utc(b.createdAt).unix() - moment.utc(a.createdAt).unix(),
});

export function federateUserId(action: FederatedAction & PayloadAction<any, any, { arg: AccountOrServer & { userId: string } }>): string {
  return federateId(action.meta.arg.userId, action);
}

export const selectors = usersAdapter.getSelectors();

const initialState: UsersState = {
  pagesStatus: createFederatedPagesStatus(),
  usernameIds: createFederated({}),
  failedUsernames: createFederated([]),
  failedUserIds: [],
  idPosts: {},
  idReplies: {},
  idEventInstances: {},
  userPages: createFederated({}),
  mutatingUserIds: [],
  ...usersAdapter.getInitialState(),
};

export const usersSlice: Slice<Draft<UsersState>, any, "users"> = createSlice({
  name: "users",
  initialState: initialState,
  reducers: {
    upsertUser: usersAdapter.upsertOne,
    removeUser: usersAdapter.removeOne,
    resetUsers: () => initialState,
  },
  extraReducers: (builder) => {
    function accountUserId(action: PayloadAction<any, any, { arg: AccountOrServer }>) {
      return federatedEntityId(action.meta.arg.account!.user, action);
    }
    builder.addCase(loadUsersPage.pending, (state, action) => {
      setFederated(state.pagesStatus, action, "loading");
    });
    builder.addCase(loadUsersPage.fulfilled, (state, action) => {
      setFederated(state.pagesStatus, action, "loaded");
      usersAdapter.upsertMany(state, federatedEntities(action.payload.users, action));

      const userIds = action.payload.users.map(u => federatedEntityId(u, action));
      const page = action.meta.arg.page ?? 0;
      const listingType = action.meta.arg.listingType ?? defaultUserListingType;

      const userPages = getFederated(state.userPages, action);
      if (!userPages[listingType]) userPages[listingType] = [];
      userPages[listingType]![page] = userIds;
      setFederated(state.userPages, action, userPages);

      // Update the users in any relevant accounts.
      const server = action.meta.arg.server!;

      setTimeout(() => {
        for (const user of action.payload.users) {
          store.dispatch(upsertUserData({ server, user }));
        }
      }, 1);
    });
    builder.addCase(loadUsersPage.rejected, (state, action) => {
      setFederated(state.pagesStatus, action, "errored");
    });
    [loadUser, loadUsername, updateUser].forEach((loader) => {
      builder.addCase(loader.pending, (_state) => { });
      builder.addCase(loader.fulfilled, (state, action) => {
        const user = action.payload;
        usersAdapter.upsertOne(state, federatedEntity(user, action));
        const usernameIds = getFederated(state.usernameIds, action);
        usernameIds[action.payload.username.split('@')[0]!] = federatedEntityId(user, action);
        setFederated(state.usernameIds, action, usernameIds);

        // Update the user in any relevant accounts.
        const server = action.meta.arg.server!;
        setTimeout(() => {
          store.dispatch(upsertUserData({ server, user }));
        }, 1);
      });
      builder.addCase(loader.rejected, (state, action) => {
        const requestUserId = loader == loadUser
          ? federateId((action.meta.arg as LoadUser).userId, action)
          : undefined;
        if (loader === loadUsername) {
          const failedUsernames = getFederated(state.failedUsernames, action);
          const updatedFailedUsernames = [...failedUsernames, (action.meta.arg as LoadUsername).username];
          setFederated(state.failedUsernames, action, updatedFailedUsernames);
        } else if (requestUserId && !state.failedUserIds.includes(requestUserId)) {
          state.failedUserIds = [...state.failedUserIds, requestUserId];
        }
      });
    });

    builder.addCase(deleteUser.fulfilled, (state, action) => {
      // Update the user in any relevant accounts.
      const server = action.meta.arg.server!;
      const user = action.meta.arg as User;
      setTimeout(() => {
        store.dispatch(notifyUserDeleted({ server, user }));
      }, 1);
    });
    builder.addCase(loadUserPosts.fulfilled, (state, action) => {
      const posts = federatedEntities(action.payload.posts, action);
      const newPostIds = new Set(posts.map(federatedId));
      const userId = federateUserId(action);
      const updatedUserPostIds = state.idPosts[userId]
        ?.filter((p) => !newPostIds.has(p))
        || [];
      updatedUserPostIds.push(...newPostIds);
      state.idPosts[userId] = updatedUserPostIds;
    });
    builder.addCase(loadUserReplies.fulfilled, (state, action) => {
      const replies = federatedEntities(action.payload.posts, action);
      const newPostIds = new Set(replies.map(federatedId));
      const updatedUserReplyIds = state.idReplies[federateUserId(action)]
        ?.filter((p) => !newPostIds.has(p))
        || [];
      updatedUserReplyIds.push(...newPostIds);
      state.idReplies[federateUserId(action)] = updatedUserReplyIds;
    });
    builder.addCase(loadUserEvents.fulfilled, (state, action) => {
      const events = federatedEntities(action.payload.events, action);
      const userId = federateUserId(action);
      const newEventInstanceIds = new Set(events.map(e => federateId(e.instances[0]!.id, action)));
      const updatedUserEventInstanceIds = state.idEventInstances[userId]
        ?.filter((p) => !newEventInstanceIds.has(p))
        || [];
      updatedUserEventInstanceIds.push(...newEventInstanceIds);
      state.idEventInstances[userId] = updatedUserEventInstanceIds;
    });
    builder.addCase(followUnfollowUser.pending, (state, action) => {
      lockUser(state, federateUserId(action));
    });
    builder.addCase(followUnfollowUser.rejected, (state, action) => {
      unlockUser(state, federateUserId(action));
    });
    builder.addCase(followUnfollowUser.fulfilled, (state, action) => {
      unlockUser(state, federateUserId(action));
      let user = selectors.selectById(state, federateId(federateUserId(action), action))!;
      let currentUser = selectors.selectById(state, accountUserId(action));
      if (action.meta.arg.follow) {
        const result = action.payload as Follow;
        if (passes(result.targetUserModeration)) {
          user = { ...user, followerCount: (user.followerCount || 0) + 1 };
          if (currentUser) {
            currentUser = { ...currentUser, followingCount: (currentUser.followingCount || 0) + 1 };
          }
        }
        user = { ...user, currentUserFollow: result };
      } else {
        if (passes(user.currentUserFollow?.targetUserModeration)) {
          user = { ...user, followerCount: (user.followerCount || 0) - 1 };
          if (currentUser) {
            currentUser = { ...currentUser, followingCount: (currentUser.followingCount || 0) - 1 };
          }
        }
        user = { ...user, currentUserFollow: undefined };
      }
      usersAdapter.upsertOne(state, user);
      if (currentUser) {
        usersAdapter.upsertOne(state, currentUser);
      }
    });

    builder.addCase(respondToFollowRequest.pending, (state, action) => {
      lockUser(state, federateUserId(action));
    });
    builder.addCase(respondToFollowRequest.rejected, (state, action) => {
      unlockUser(state, federateUserId(action));
    });
    builder.addCase(respondToFollowRequest.fulfilled, (state, action) => {
      unlockUser(state, federateUserId(action));
      let user = selectors.selectById(state, federateUserId(action))!;
      if (action.meta.arg.accept) {
        const result = action.payload as Follow;
        user = { ...user, followingCount: (user.followingCount || 0) + 1, targetCurrentUserFollow: result };
        let currentUser = selectors.selectById(state, accountUserId(action));
        if (currentUser) {
          currentUser = { ...currentUser, followerCount: (currentUser.followerCount || 0) + 1 };
          usersAdapter.upsertOne(state, currentUser);
        }
      } else {
        user = { ...user, targetCurrentUserFollow: undefined };
      }
      usersAdapter.upsertOne(state, user);
    });
  },
});

export const { removeUser, resetUsers, upsertUser } = usersSlice.actions;

export const { selectAll: selectAllUsers, selectById: selectUserById } = selectors;
export const usersReducer = usersSlice.reducer;
export default usersReducer;


function lockUser(state: UsersState, userId: string) {
  state.mutatingUserIds = [userId, ...state.mutatingUserIds];
}
function unlockUser(state: UsersState, userId: string) {
  state.mutatingUserIds = state.mutatingUserIds.filter(u => u != userId);
}

export function isUserLocked(state: UsersState, userId: string): boolean {
  return state.mutatingUserIds.includes(userId);
}
