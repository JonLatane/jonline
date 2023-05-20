import { Empty, Follow, GetEventsResponse, GetPostsResponse, GetUsersRequest, GetUsersResponse, Moderation, PostListingType, User } from "@jonline/api";
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
  PayloadAction,
  Slice
} from "@reduxjs/toolkit";
import { passes } from "app/utils/moderation";
import moment from "moment";
import store from "../store";
import { AccountOrServer } from "../types";
import { getCredentialClient, upsertUserDataToAccounts } from "./accounts";
import { UserListingType } from '../../../api/generated/users';

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

const usersAdapter: EntityAdapter<User> = createEntityAdapter<User>({
  selectId: (user) => user.id,
  sortComparer: (a, b) => moment.utc(b.createdAt).unix() - moment.utc(a.createdAt).unix(),
});

export type LoadUsersRequest = AccountOrServer & { page?: number, listingType?: UserListingType };
const defaultUserListingType = UserListingType.EVERYONE;
export const loadUsersPage: AsyncThunk<GetUsersResponse, LoadUsersRequest, any> = createAsyncThunk<GetUsersResponse, LoadUsersRequest>(
  "users/loadPage",
  async (request) => {
    let client = await getCredentialClient(request);
    const getUserRequest = GetUsersRequest.create({
      page: request.page,
      listingType: request.listingType ?? defaultUserListingType,
    });
    return await client.getUsers(getUserRequest, client.credential);
  }
);

export type LoadUser = { id: string } & AccountOrServer;
const _loadingUserIds = new Set<string>();
export const loadUser: AsyncThunk<User, LoadUser, any> = createAsyncThunk<User, LoadUser>(
  "users/loadById",
  async (request) => {
    let user: User | undefined = undefined;
    while (_loadingUserIds.has(request.id)) {
      await new Promise(resolve => setTimeout(resolve, 100));
      user = usersAdapter.getSelectors().selectById(store.getState().users, request.id);
    }
    if (store.getState().users.failedUserIds.includes(request.id)) {
      throw 'User not found';
    }
    if (!user) {
      _loadingUserIds.add(request.id);
      const client = await getCredentialClient(request);
      const response = await client.getUsers(GetUsersRequest.create({ userId: request.id }), client.credential);
      _loadingUserIds.delete(request.id);
      if (response.users.length == 0) throw 'User not found';

      user = response.users[0]!;
    }
    return user;
  }
);

export type LoadUsername = { username: string } & AccountOrServer;
const _loadingUsernames = new Set<string>();
export const loadUsername: AsyncThunk<User, LoadUsername, any> = createAsyncThunk<User, LoadUsername>(
  "users/loadByName",
  async (request) => {
    let user: User | undefined = undefined;
    while (_loadingUsernames.has(request.username)) {
      await new Promise(resolve => setTimeout(resolve, 100));
      const userId = store.getState().users.usernameIds[request.username];
      user = userId ? usersAdapter.getSelectors().selectById(store.getState().users, userId) : undefined;
    }
    if (!user) {
      _loadingUsernames.add(request.username);
      const client = await getCredentialClient(request);
      const response = await client.getUsers(GetUsersRequest.create({ username: request.username }), client.credential);
      _loadingUsernames.delete(request.username);
      if (response.users.length == 0) throw 'User not found';

      user = response.users[0]!;
    }
    return user;
  }
);

export type LoadUserPosts = AccountOrServer & { userId: string };
export const loadUserPosts: AsyncThunk<GetPostsResponse, LoadUserPosts, any> = createAsyncThunk<GetPostsResponse, LoadUserPosts>(
  "users/loadPosts",
  async (request) => {
    let client = await getCredentialClient(request);
    const result = await client.getPosts({ authorUserId: request.userId }, client.credential);
    return result;
  }
);
export type LoadUserEvents = AccountOrServer & { userId: string };
export const loadUserEvents: AsyncThunk<GetEventsResponse, LoadUserEvents, any> = createAsyncThunk<GetEventsResponse, LoadUserEvents>(
  "users/loadPosts",
  async (request) => {
    let client = await getCredentialClient(request);
    const result = await client.getEvents({ authorUserId: request.userId }, client.credential);
    return result;
  }
);


export type UpdateUser = User & AccountOrServer;
export const userSaved = 'User Saved';
export const updateUser: AsyncThunk<User, UpdateUser, any> = createAsyncThunk<User, UpdateUser>(
  "users/update",
  async (request) => {
    const client = await getCredentialClient(request);
    const updatedUser = { ...request };
    const user = await client.updateUser(updatedUser, client.credential);
    return user;
  }
);

export type FollowUnfollowUser = { userId: string, follow: boolean } & AccountOrServer;
export const followUnfollowUser: AsyncThunk<Follow | Empty, FollowUnfollowUser, any> = createAsyncThunk<Follow | Empty, FollowUnfollowUser>(
  "users/followUnfollow",
  async (request) => {
    const client = await getCredentialClient(request);
    const follow = { userId: request.account!.user.id, targetUserId: request.userId };
    const result: Follow | Empty = request.follow ? await client.createFollow(follow, client.credential) : await client.deleteFollow(follow, client.credential);
    return result;
  });

export type RespondToFollowRequest = { userId: string, accept: boolean } & AccountOrServer;
export const respondToFollowRequest: AsyncThunk<Follow | Empty, RespondToFollowRequest, any> = createAsyncThunk<Follow | Empty, RespondToFollowRequest>(
  "users/respondToFollowRequest",
  async (request) => {
    const client = await getCredentialClient(request);
    const follow = { targetUserId: request.account!.user.id, userId: request.userId, targetUserModeration: request.accept ? Moderation.APPROVED : Moderation.REJECTED };
    const result: Follow | Empty = request.accept ? await client.updateFollow(follow, client.credential) : await client.deleteFollow(follow, client.credential);
    return result;
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
