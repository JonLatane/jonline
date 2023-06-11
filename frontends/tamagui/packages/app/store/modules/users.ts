import { Follow, User, UserListingType } from "@jonline/api";
import { formatError } from "@jonline/ui";
import {
  Dictionary,
  Draft,
  EntityAdapter,
  EntityId,
  Slice,
  createEntityAdapter,
  createSlice
} from "@reduxjs/toolkit";
import { passes } from "app/utils/moderation";
import moment from "moment";
import { store, upsertUserDataToAccounts } from "..";
import { LoadUser, LoadUsername, defaultUserListingType, followUnfollowUser, loadUser, loadUserPosts, loadUsername, loadUsersPage, respondToFollowRequest, updateUser, userSaved } from "./user_actions";

export interface UsersState {
  status: "unloaded" | "loading" | "loaded" | "errored";
  pagesStatus: "unloaded" | "loading" | "loaded" | "errored";
  error?: Error;
  successMessage?: string;
  errorMessage?: string;
  ids: EntityId[];
  entities: Dictionary<User>;
  usernameIds: Dictionary<string>;
  failedUsernames: string[];
  failedUserIds: string[];
  idPosts: Dictionary<string[]>;
  // Stores pages of listed users for listing types used in the UI.
  // i.e.: userPages[PostListingType.PUBLIC_POSTS][1] -> ["userId1", "userId2"].
  // Users should be loaded from the adapter/slice's entities.
  // Maps UserListingType -> page -> userIds
  userPages: Dictionary<Dictionary<string[]>>;
  mutatingUserIds: string[];
}

export interface UsersSlice {
  adapter: EntityAdapter<User>;
}

export const usersAdapter: EntityAdapter<User> = createEntityAdapter<User>({
  selectId: (user) => user.id,
  sortComparer: (a, b) => moment.utc(b.createdAt).unix() - moment.utc(a.createdAt).unix(),
});

const initialState: UsersState = {
  status: "unloaded",
  pagesStatus: "unloaded",
  usernameIds: {},
  failedUsernames: [],
  failedUserIds: [],
  idPosts: {},
  userPages: {},
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
    clearUserAlerts: (state) => {
      state.errorMessage = undefined;
      state.successMessage = undefined;
      state.error = undefined;
    },
  },
  extraReducers: (builder) => {
    builder.addCase(loadUsersPage.pending, (state) => {
      state.status = "loading";
      state.pagesStatus = "loading";
      state.error = undefined;
    });
    builder.addCase(loadUsersPage.fulfilled, (state, action) => {
      state.status = "loaded";
      state.pagesStatus = "loaded";
      usersAdapter.upsertMany(state, action.payload.users);

      const userIds = action.payload.users.map(u => u.id);
      const page = action.meta.arg.page ?? 0;
      const listingType = action.meta.arg.listingType ?? defaultUserListingType;

      if (!state.userPages[listingType]) state.userPages[listingType] = {};
      state.userPages[listingType]![page] = userIds;

      state.successMessage = `Users loaded.`;

      // Update the users in any relevant accounts.
      const server = action.meta.arg.server!;

      setTimeout(() => {
        for (const user of action.payload.users) {
          store.dispatch(upsertUserDataToAccounts({ server, user }));
        }
      }, 1);
    });
    builder.addCase(loadUsersPage.rejected, (state, action) => {
      state.status = "errored";
      state.pagesStatus = "errored";
      state.error = action.error as Error;
      state.errorMessage = formatError(action.error as Error);
      state.error = action.error as Error;
    });
    [loadUser, loadUsername, updateUser].forEach((loader) => {
      builder.addCase(loader.pending, (state) => {
        state.status = "loading";
        state.error = undefined;
      });
      builder.addCase(loader.fulfilled, (state, action) => {
        state.status = "loaded";
        const user = action.payload;
        usersAdapter.upsertOne(state, user);
        state.usernameIds[action.payload.username] = user.id;
        state.successMessage = `User data for ${user.id}:${user.username} loaded.`;
        if (loader == updateUser) {
          state.successMessage = userSaved;
        }

        // Update the user in any relevant accounts.
        const server = action.meta.arg.server!;
        setTimeout(() => {
          store.dispatch(upsertUserDataToAccounts({ server, user }));
        }, 1);
      });
      builder.addCase(loader.rejected, (state, action) => {
        state.status = "errored";
        if (loader === loadUsername) {
          state.failedUsernames = [...state.failedUsernames, (action.meta.arg as LoadUsername).username];
        } else if (loader == loadUser && !state.failedUserIds.includes((action.meta.arg as LoadUser).id)) {
          state.failedUserIds = [...state.failedUserIds, (action.meta.arg as LoadUser).id];
        }
        state.error = action.error as Error;
        state.errorMessage = formatError(action.error as Error);
        state.error = action.error as Error;
      });
    });

    builder.addCase(loadUserPosts.pending, (state) => {
      state.status = "loading";
      state.error = undefined;
    });
    builder.addCase(loadUserPosts.fulfilled, (state, action) => {
      state.status = "loaded";
      const { posts } = action.payload;
      const newPostIds = new Set(posts.map(p => p.id));
      if (!state.idPosts) state.idPosts = {};
      const updatedUserPostIds = state.idPosts[action.meta.arg.userId]
        ?.filter((p) => !newPostIds.has(p))
        || [];
      updatedUserPostIds.push(...posts.map(p => p.id));
      state.idPosts[action.meta.arg.userId] = updatedUserPostIds;
      state.successMessage = `User Posts for ${action.meta.arg.userId} loaded.`;
    });
    builder.addCase(loadUserPosts.rejected, (state, action) => {
      state.status = "errored";
      state.error = action.error as Error;
      state.errorMessage = formatError(action.error as Error);
      state.error = action.error as Error;
    });

    builder.addCase(followUnfollowUser.pending, (state, action) => {
      lockUser(state, action.meta.arg.userId);
    });
    builder.addCase(followUnfollowUser.rejected, (state, action) => {
      unlockUser(state, action.meta.arg.userId);
    });
    builder.addCase(followUnfollowUser.fulfilled, (state, action) => {
      unlockUser(state, action.meta.arg.userId);
      let user = usersAdapter.getSelectors().selectById(state, action.meta.arg.userId)!;
      let currentUser = usersAdapter.getSelectors().selectById(state, action.meta.arg.account!.user.id);
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
      lockUser(state, action.meta.arg.userId);
    });
    builder.addCase(respondToFollowRequest.rejected, (state, action) => {
      unlockUser(state, action.meta.arg.userId);
    });
    builder.addCase(respondToFollowRequest.fulfilled, (state, action) => {
      unlockUser(state, action.meta.arg.userId);
      let user = usersAdapter.getSelectors().selectById(state, action.meta.arg.userId)!;
      if (action.meta.arg.accept) {
        const result = action.payload as Follow;
        user = { ...user, followingCount: (user.followingCount || 0) + 1, targetCurrentUserFollow: result };
        let currentUser = usersAdapter.getSelectors().selectById(state, action.meta.arg.account!.user.id);
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

export const { removeUser, clearUserAlerts, resetUsers, upsertUser } = usersSlice.actions;

export const { selectAll: selectAllUsers, selectById: selectUserById } = usersAdapter.getSelectors();
export const usersReducer = usersSlice.reducer;
export default usersReducer;

export function getUsersPage(state: UsersState, listingType: UserListingType, page: number): User[] | undefined {
  const pagePostIds: string[] | undefined = (state.userPages[listingType] ?? {})[page];
  if (!pagePostIds) return undefined;

  const pagePosts = pagePostIds.map(id => selectUserById(state, id)).filter(p => p) as User[];
  return pagePosts;
}

function lockUser(state: UsersState, userId: string) {
  state.mutatingUserIds = [userId, ...state.mutatingUserIds];
}
function unlockUser(state: UsersState, userId: string) {
  state.mutatingUserIds = state.mutatingUserIds.filter(u => u != userId);
}

export function isUserLocked(state: UsersState, userId: string): boolean {
  return state.mutatingUserIds.includes(userId);
}
