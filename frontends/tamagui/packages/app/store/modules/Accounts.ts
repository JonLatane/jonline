import {
  createAsyncThunk,
  createEntityAdapter,
  createSlice,
  Dictionary,
  EntityId,
  PayloadAction,
} from "@reduxjs/toolkit";
import { RefreshTokenResponse, AccessTokenResponse, CreateAccountRequest, LoginRequest } from "@jonline/ui/src/generated/authentication"
import { User } from "@jonline/ui/src/generated/users"
import { getServerClient, JonlineServer } from "./servers";
import { grpc } from "@improbable-eng/grpc-web";
import 'react-native-get-random-values';
import {v4 as uuidv4} from 'uuid';
import { Jonline } from "@jonline/ui/src";
import { formatError } from "@jonline/ui/src";

// The type used to store accounts locally.
export type JonlineAccount = {
  id: string;
  user: User;
  refreshToken: RefreshTokenResponse;
  accessToken: AccessTokenResponse;
  server: JonlineServer;
}

export type AccountOrServer = JonlineAccount | JonlineServer;
// A Jonline client with an optional credentials field bolted on.
export type JonlineCredentialClient = Jonline & {
  credential?: grpc.Metadata;
}
export function getCredentialClient(accountOrServer: AccountOrServer): JonlineCredentialClient {
  if ('server' in accountOrServer) {
    let client = getServerClient(accountOrServer.server);
    let metadata = new grpc.Metadata();
    metadata.append('authorization', accountOrServer.accessToken.accessToken!);
    return { ...client, credential: metadata };
  } else {
    return getServerClient(accountOrServer);
  }
}

export interface AccountsState {
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
    let client = getServerClient(createAccountRequest);
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
    let client = getServerClient(loginRequest);
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
  ...accountsAdapter.getInitialState(),
};

export const accountsSlice = createSlice({
  name: "accounts",
  initialState: initialState,//{ ...initialState, ...JSON.parse(localStorage.getItem("accounts")) },
  reducers: {
    upsertAccount: accountsAdapter.upsertOne,
    removeAccount: (state, action: PayloadAction<string>) => { 
      if (state.account?.id === action.payload) {
        state.account = undefined;
      }
      accountsAdapter.removeOne(state, action);
    },
    reset: () => initialState,
    selectAccount: (state, action: PayloadAction<JonlineAccount | undefined>) => {
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
      state.successMessage = `Account ${action.payload.user.username} added.`;
    });
    builder.addCase(createAccount.rejected, (state, action) => {
      state.status = "errored";
      state.error = action.error as Error;
      state.errorMessage = formatError(action.error as Error);
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
      state.successMessage = `Account ${action.payload.user.username} added.`;
    });
    builder.addCase(login.rejected, (state, action) => {
      state.status = "errored";
      state.error = action.error as Error;
      state.status = "errored";
      state.error = action.error as Error;
      state.errorMessage = formatError(action.error as Error);
      state.error = action.error as Error;
    });
  },
});

export const { selectAccount, removeAccount, clearAlerts } = accountsSlice.actions;

export const { selectAll: selectAllAccounts } = accountsAdapter.getSelectors();

export default accountsSlice.reducer;
