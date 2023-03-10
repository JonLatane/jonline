import { Follow, formatError, GetPostsResponse, GetUsersRequest, GetUsersResponse, Moderation, PostListingType, User } from "@jonline/ui/src";
import { Empty } from "@jonline/ui/src/generated/google/protobuf/empty";
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
import { getCredentialClient } from "./accounts";

export interface UsersState {
  status: "unloaded" | "loading" | "loaded" | "errored";
  error?: Error;
  successMessage?: string;
  errorMessage?: string;
  ids: EntityId[];
  entities: Dictionary<User>;
  usernameIds: Dictionary<string>;
  avatars: Dictionary<string>;
  failedUsernames: string[];
  failedUserIds: string[];
  idPosts: Dictionary<string[]>;
}

export interface UsersSlice {
  adapter: EntityAdapter<User>;
}

const usersAdapter: EntityAdapter<User> = createEntityAdapter<User>({
  selectId: (user) => user.id,
  sortComparer: (a, b) => moment.utc(b.createdAt).unix() - moment.utc(a.createdAt).unix(),
});

export type LoadUsersRequest = AccountOrServer & { page: number };
export const loadUsersPage: AsyncThunk<GetUsersResponse, LoadUsersRequest, any> = createAsyncThunk<GetUsersResponse, LoadUsersRequest>(
  "users/loadPage",
  async (getUsersRequest) => {
    let client = await getCredentialClient(getUsersRequest);
    return await client.getUsers(getUsersRequest, client.credential);
  }
);

// export type LoadUserAvatar = User & AccountOrServer;
// export const loadUserAvatar: AsyncThunk<string, LoadUserAvatar, any> = createAsyncThunk<string, LoadUserAvatar>(
//   "users/loadAvatar",
//   async (request) => {
//     let client = await getCredentialClient(request);
//     let response = await client.getUsers(GetUsersRequest.create({ userId: request.id }), client.credential);
//     let user = response.users[0]!;
//     return user.avatar
//       ? URL.createObjectURL(new Blob([user.avatar!], { type: 'image/png' }))
//       : '';
//   }
// );

export type LoadUser = { id: string } & AccountOrServer;
export type LoadUserResult = {
  user: User;
  avatar: string;
}
const _loadingUserIds = new Set<string>();
export const loadUser: AsyncThunk<LoadUserResult, LoadUser, any> = createAsyncThunk<LoadUserResult, LoadUser>(
  "users/loadById",
  async (request) => {
    let user: User | undefined = undefined;
    let avatar: string | undefined = undefined;
    while (_loadingUserIds.has(request.id)) {
      await new Promise(resolve => setTimeout(resolve, 100));
      user = usersAdapter.getSelectors().selectById(store.getState().users, request.id);
      if (user) {
        avatar = store.getState().users.avatars[request.id];
      }
    }
    if (!user) {
      _loadingUserIds.add(request.id);
      const client = await getCredentialClient(request);
      const response = await client.getUsers(GetUsersRequest.create({ userId: request.id }), client.credential);
      _loadingUserIds.delete(request.id);
      if (response.users.length == 0) throw 'User not found';

      user = response.users[0]!;
      avatar = user.avatar
        ? URL.createObjectURL(new Blob([user.avatar!], { type: 'image/png' }))
        : '';
    }
    return { user: { ...user!, avatar: undefined }, avatar: avatar! };
  }
);

export type LoadUsername = { username: string } & AccountOrServer;
const _loadingUsernames = new Set<string>();
export const loadUsername: AsyncThunk<LoadUserResult, LoadUsername, any> = createAsyncThunk<LoadUserResult, LoadUsername>(
  "users/loadByName",
  async (request) => {
    let user: User | undefined = undefined;
    let avatar: string | undefined = undefined;
    while (_loadingUsernames.has(request.username)) {
      await new Promise(resolve => setTimeout(resolve, 100));
      const userId = store.getState().users.usernameIds[request.username];
      user = userId ? usersAdapter.getSelectors().selectById(store.getState().users, userId) : undefined;
      if (user) {
        avatar = store.getState().users.avatars[user.id];
      }
    }
    if (!user) {
      _loadingUsernames.add(request.username);
      const client = await getCredentialClient(request);
      const response = await client.getUsers(GetUsersRequest.create({ username: request.username }), client.credential);
      _loadingUsernames.delete(request.username);
      if (response.users.length == 0) throw 'User not found';

      user = response.users[0]!;
      avatar = user.avatar
        ? URL.createObjectURL(new Blob([user.avatar!], { type: 'image/png' }))
        : '';
    }
    return { user: { ...user!, avatar: undefined }, avatar: avatar! };
  }
);

export type LoadUserPosts = AccountOrServer & { userId: string };
export const loadUserPosts: AsyncThunk<GetPostsResponse, LoadUserPosts, any> = createAsyncThunk<GetPostsResponse, LoadUserPosts>(
  "users/loadPosts",
  async (request) => {
    let client = await getCredentialClient(request);
    const result = await client.getPosts({ authorUserId: request.userId, listingType: PostListingType.GROUP_POSTS }, client.credential);
    return result;
  }
);


export type UpdateUser = { user: User, avatar?: string } & AccountOrServer;
// export type LoadUserResult = {
//   user: User;
//   avatar: string;
// }
export const updateUser: AsyncThunk<LoadUserResult, UpdateUser, any> = createAsyncThunk<LoadUserResult, UpdateUser>(
  "users/update",
  async (request) => {
    const client = await getCredentialClient(request);
    const updatedUser = { ...request.user };
    if (request.avatar) {
      const updatedAvatar = await (await fetch(request.avatar)).arrayBuffer().then(buffer => {
        const uint = new Uint8Array(buffer);
        console.log("Uint8Array", uint);
        return uint;
      });
      updatedUser.avatar = updatedAvatar;
    }
    const user = await client.updateUser(updatedUser, client.credential);
    const avatar = user.avatar
      ? URL.createObjectURL(new Blob([user.avatar!], { type: 'image/png' }))
      : '';
    return { user: { ...user, avatar: undefined }, avatar };
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
  avatars: {},
  usernameIds: {},
  failedUsernames: [],
  failedUserIds: [],
  idPosts: {},
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
    removeAvatarById: (state, action: PayloadAction<string>) => {
      state.avatars[action.payload] = undefined;
    },
  },
  extraReducers: (builder) => {
    builder.addCase(loadUsersPage.pending, (state) => {
      state.status = "loading";
      state.error = undefined;
    });
    builder.addCase(loadUsersPage.fulfilled, (state, action) => {
      state.status = "loaded";
      usersAdapter.upsertMany(state, action.payload.users);
      state.successMessage = `Users loaded.`;
    });
    builder.addCase(loadUsersPage.rejected, (state, action) => {
      state.status = "errored";
      state.error = action.error as Error;
      state.errorMessage = formatError(action.error as Error);
      state.error = action.error as Error;
    });
    [loadUser, loadUsername, updateUser].forEach((loader) => {
      builder.addCase(loader.pending, (state) => {
        // debugger;
        state.status = "loading";
        state.error = undefined;
      });
      builder.addCase(loader.fulfilled, (state, action) => {
        state.status = "loaded";
        usersAdapter.upsertOne(state, action.payload.user);
        state.avatars[action.payload.user.id] = action.payload.avatar;
        state.usernameIds[action.payload.user.username] = action.payload.user.id;
        state.successMessage = `User data for ${action.payload.user.id}:${action.payload.user.username} loaded.`;
      });
      builder.addCase(loader.rejected, (state, action) => {
        state.status = "errored";
        if (loader === loadUsername) {
          state.failedUsernames = [...state.failedUsernames, (action.meta.arg as LoadUsername).username];
        } else if (loader == loadUser) {
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

    builder.addCase(followUnfollowUser.fulfilled, (state, action) => {
      let user = usersAdapter.getSelectors().selectById(state, action.meta.arg.userId)!;
      if (action.meta.arg.follow) {
        const result = action.payload as Follow;
        if (passes(result.targetUserModeration)) {
          user = { ...user, followerCount: (user.followerCount || 0) + 1 };
        }
        user = { ...user, currentUserFollow: result };
      } else {
        if (passes(user.currentUserFollow?.targetUserModeration)) {
          user = { ...user, followerCount: (user.followerCount || 0) - 1 };
        }
        user = { ...user, currentUserFollow: undefined };
      }
      usersAdapter.upsertOne(state, user);
    });
    builder.addCase(respondToFollowRequest.fulfilled, (state, action) => {
      let user = usersAdapter.getSelectors().selectById(state, action.meta.arg.userId)!;
      if (action.meta.arg.accept) {
        const result = action.payload as Follow;
        user = { ...user, followingCount: (user.followingCount || 0) + 1, targetCurrentUserFollow: result };
      } else {
        user = { ...user, targetCurrentUserFollow: undefined };
      }
      usersAdapter.upsertOne(state, user);
    });
  },
});

export const { removeUser, clearUserAlerts, resetUsers } = usersSlice.actions;

export const { selectAll: selectAllUsers, selectById: selectUserById } = usersAdapter.getSelectors();
export const usersReducer = usersSlice.reducer;
export default usersReducer;
