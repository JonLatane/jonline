import { formatError, GetUsersRequest, GetUsersResponse, User } from "@jonline/ui/src";
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
}

export interface UsersSlice {
  adapter: EntityAdapter<User>;
}

const usersAdapter: EntityAdapter<User> = createEntityAdapter<User>({
  selectId: (user) => user.id,
  sortComparer: (a, b) => moment.utc(b.createdAt).unix() - moment.utc(a.createdAt).unix(),
});

export type UpdateUsers = AccountOrServer & { page: number };
export const updateUsers: AsyncThunk<GetUsersResponse, UpdateUsers, any> = createAsyncThunk<GetUsersResponse, UpdateUsers>(
  "users/update",
  async (getUsersRequest) => {
    let client = await getCredentialClient(getUsersRequest);
    return await client.getUsers(getUsersRequest, client.credential);
  }
);

export type LoadUserAvatar = User & AccountOrServer;
export const loadUserAvatar: AsyncThunk<string, LoadUserAvatar, any> = createAsyncThunk<string, LoadUserAvatar>(
  "users/loadAvatar",
  async (request) => {
    let client = await getCredentialClient(request);
    let response = await client.getUsers(GetUsersRequest.create({ userId: request.id }), client.credential);
    let user = response.users[0]!;
    return user.avatar
      ? URL.createObjectURL(new Blob([user.avatar!], { type: 'image/png' }))
      : '';
  }
);

export type LoadUser = { id: string } & AccountOrServer;
export type LoadUserResult = {
  user: User;
  avatar: string;
}
export const loadUser: AsyncThunk<LoadUserResult, LoadUser, any> = createAsyncThunk<LoadUserResult, LoadUser>(
  "users/loadById",
  async (request) => {
    let client = await getCredentialClient(request);
    let response = await client.getUsers(GetUsersRequest.create({ userId: request.id }), client.credential);
    if (response.users.length == 0) throw 'User not found';

    let user = response.users[0]!;
    let avatar = user.avatar
      ? URL.createObjectURL(new Blob([user.avatar!], { type: 'image/png' }))
      : '';
    return { user: { ...user, avatar: undefined }, avatar };
  }
);
export type LoadUsername = { username: string } & AccountOrServer;
export const loadUsername: AsyncThunk<LoadUserResult, LoadUsername, any> = createAsyncThunk<LoadUserResult, LoadUsername>(
  "users/loadByName",
  async (request) => {
    let client = await getCredentialClient(request);
    let getUsersRequest = GetUsersRequest.create({ username: request.username });
    // debugger;
    let response = await client.getUsers(getUsersRequest, client.credential);
    if (response.users.length == 0) throw 'User not found';

    // debugger;

    let user = response.users[0]!;
    let avatar = user.avatar
      ? URL.createObjectURL(new Blob([user.avatar!], { type: 'image/png' }))
      : '';
    return { user: { ...user, avatar: undefined }, avatar };
  }
);

const initialState: UsersState = {
  status: "unloaded",
  avatars: {},
  usernameIds: {},
  failedUsernames: [],
  failedUserIds: [],
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
    builder.addCase(updateUsers.pending, (state) => {
      state.status = "loading";
      state.error = undefined;
    });
    builder.addCase(updateUsers.fulfilled, (state, action) => {
      state.status = "loaded";
      usersAdapter.upsertMany(state, action.payload.users);
      state.successMessage = `Users loaded.`;
    });
    builder.addCase(updateUsers.rejected, (state, action) => {
      state.status = "errored";
      state.error = action.error as Error;
      state.errorMessage = formatError(action.error as Error);
      state.error = action.error as Error;
    });
    [loadUser, loadUsername].forEach((loader) => {
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
    builder.addCase(loadUserAvatar.fulfilled, (state, action) => {
      state.avatars[action.meta.arg.id] = action.payload;
      state.successMessage = `Avatar image for ${action.meta.arg.id} loaded.`;
    });
  },
});

export const { removeUser, clearUserAlerts, resetUsers } = usersSlice.actions;

export const { selectAll: selectAllUsers, selectById: selectUserById } = usersAdapter.getSelectors();
export const usersReducer = usersSlice.reducer;
export default usersReducer;
