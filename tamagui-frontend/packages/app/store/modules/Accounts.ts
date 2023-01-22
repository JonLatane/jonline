import {
  ActionReducerMapBuilder,
  AsyncThunk,
  createAsyncThunk,
  createEntityAdapter,
  createSlice,
  Dictionary,
  EntityId,
  PayloadAction,
  SerializedError,
} from "@reduxjs/toolkit";
import { RefreshTokenResponse, AccessTokenResponse, CreateAccountRequest, LoginRequest } from "@jonline/ui/src/generated/authentication"
import { User } from "@jonline/ui/src/generated/users"
import { getClient, JonlineServer } from "./Servers";
import { grpc } from "@improbable-eng/grpc-web";
import {v4 as uuidv4} from 'uuid';

// The type used to store accounts locally.
export type JonlineAccount = {
  id: string;
  user: User;
  refreshToken: RefreshTokenResponse;
  accessToken: AccessTokenResponse;
  server: JonlineServer;
}

interface AccountsState {
  status: "unloaded" | "loading" | "loaded" | "errored";
  error?: Error;
  successMessage?: string;
  errorMessage?: string;
  account?: JonlineAccount;
  ids: EntityId[];
  entities: Dictionary<JonlineAccount>;
}

const accountsAdapter = createEntityAdapter<JonlineAccount>({
  selectId: (account) => account.id,
});

export type CreateAccount = JonlineServer & CreateAccountRequest;
export const createAccount = createAsyncThunk<JonlineAccount, CreateAccount>(
  "accounts/create",
  async (createAccountRequest) => {
    let client = getClient(createAccountRequest);
    let refreshToken = await client.createAccount(createAccountRequest);
    let accessToken = refreshToken.accessToken!;
    let metadata = new grpc.Metadata();
    metadata.append('authorization', accessToken.token)
    let user = await client.getCurrentUser({}, metadata);
    return {
      id: uuidv4(),
      user: user,
      refreshToken: refreshToken,
      accessToken: accessToken,
      server: { ...createAccountRequest }
    };
  }
);

export type Login = JonlineServer & LoginRequest;
export const login = createAsyncThunk<JonlineAccount, Login>(
  "accounts/login",
  async (loginRequest) => {
    let client = getClient(loginRequest);
    let refreshToken = await client.login(loginRequest);
    let accessToken = refreshToken.accessToken!;
    let metadata = new grpc.Metadata();
    metadata.append('authorization', accessToken.token)
    let user = await client.getCurrentUser({}, metadata);
    return {
      id: uuidv4(),
      user: user,
      refreshToken: refreshToken,
      accessToken: accessToken,
      server: { ...loginRequest }
    };
  }
);

const initialState: AccountsState = {
  status: "unloaded",
  error: undefined,
  // pendingAccount: undefined,
  ...accountsAdapter.getInitialState(),
};

const accountsSlice = createSlice({
  name: "accounts",
  initialState: initialState,//{ ...initialState, ...JSON.parse(localStorage.getItem("accounts")) },
  reducers: {
    // upsertFact: AccountsAdapter.upsertOne,
    upsertAccount: accountsAdapter.upsertOne,
    removeAccount: accountsAdapter.removeOne,
    reset: () => initialState,
    selectAccount: (state, action: PayloadAction<JonlineAccount>) => {
      state.account = action.payload;
    },
    clearAlerts: (state) => {
      state.errorMessage = undefined;
      state.successMessage = undefined;
      state.error = undefined;
    },
  },
  extraReducers: (builder) => {
    builder.addCase(createAccount.pending, (state) => {
      state.status = "loading";
      state.error = undefined;
    });
    builder.addCase(createAccount.fulfilled, (state, action) => {
      state.status = "loaded";
      state.account = action.payload;
      accountsAdapter.upsertOne(state, action.payload);
      console.log(`Account ${action.payload.user.username} added.`);
      state.successMessage = `Account ${action.payload.user.username} added.`;
    });
    builder.addCase(createAccount.rejected, (state, action) => {
      state.status = "errored";
      state.error = action.error as Error;
      console.error(`Error creating account ${action.meta.arg.username}.`, action.error);
      state.errorMessage = `Error creating account ${action.meta.arg.username}.`;
      state.error = action.error as Error;
    });
    builder.addCase(login.pending, (state) => {
      state.status = "loading";
      state.error = undefined;
    });
    builder.addCase(login.fulfilled, (state, action) => {
      state.status = "loaded";
      state.account = action.payload;
      accountsAdapter.upsertOne(state, action.payload);
      console.log(`Account ${action.payload.user.username} added.`);
      state.successMessage = `Account ${action.payload.user.username} added.`;
    });
    builder.addCase(login.rejected, (state, action) => {
      state.status = "errored";
      state.error = action.error as Error;
      state.status = "errored";
      state.error = action.error as Error;
      console.error(`Error logging in as ${action.meta.arg.username}.`, action.error);
      state.errorMessage = `Error logging in as ${action.meta.arg.username}.`;
      state.error = action.error as Error;
    });
  },
});

// export const { upsertFact } = accountsSlice.actions;
export const { selectAccount, removeAccount, clearAlerts } = accountsSlice.actions;

export const { selectAll: selectAllAccounts } = accountsAdapter.getSelectors();

export default accountsSlice.reducer;
