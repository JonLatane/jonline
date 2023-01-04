import {
  ActionReducerMapBuilder,
  AsyncThunk,
  createAsyncThunk,
  createEntityAdapter,
  createSlice,
  Dictionary,
  EntityId,
  SerializedError,
} from "@reduxjs/toolkit";
import { RefreshTokenResponse, AccessTokenResponse, CreateAccountRequest, LoginRequest } from "../../../generated/authentication"
import { User } from "../../../generated/users"
import { JonlineServer } from "./Servers";

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
  pendingAccount?: JonlineAccount;
  ids: EntityId[];
  entities: Dictionary<JonlineAccount>;
}

const AccountsAdapter = createEntityAdapter<JonlineAccount>({
  selectId: (account) => account.id,
});

export type CreateAccount = JonlineServer & CreateAccountRequest;
export const createAccount = createAsyncThunk<JonlineAccount, CreateAccount>(
  "accounts/create",
  async (createAccountRequest) => {
    // const factString = await fetchFunFact(num);
    return {
      id: "generate-me",
      user: User.fromJSON({}),
      refreshToken: RefreshTokenResponse.fromJSON({}),
      accessToken: AccessTokenResponse.fromJSON({}),
      server: { host: "localhost", allowInsecure: true }
    };
  }
);

export type Login = JonlineServer & LoginRequest;
export const login = createAsyncThunk<JonlineAccount, Login>(
  "accounts/login",
  async (loginRequest) => {
    // const factString = await fetchFunFact(num);
    return {
      id: "generate-me",
      user: User.fromJSON({}),
      refreshToken: RefreshTokenResponse.fromJSON({}),
      accessToken: AccessTokenResponse.fromJSON({}),
      server: { host: "localhost", allowInsecure: true }
    };
  }
);

const initialState: AccountsState = {
  status: "unloaded",
  error: null,
  pendingAccount: undefined,
  ...AccountsAdapter.getInitialState(),
};

const AccountsSlice = createSlice({
  name: "accounts",
  initialState: { ...initialState, ...JSON.parse(localStorage.getItem("accounts")) },
  reducers: {
    // upsertFact: AccountsAdapter.upsertOne,
    reset: () => initialState
  },
  extraReducers: (builder) => {
    builder.addCase(createAccount.pending, (state) => {
      state.status = "loading";
      state.error = null;
    });
    builder.addCase(createAccount.fulfilled, (state, action) => {
      state.status = "loaded";
      state.pendingAccount = action.payload;
    });
    builder.addCase(createAccount.rejected, (state, action) => {
      state.status = "errored";
      state.error = action.error as Error;
    });
    builder.addCase(login.pending, (state) => {
      state.status = "loading";
      state.error = null;
    });
    builder.addCase(login.fulfilled, (state, action) => {
      state.status = "loaded";
      state.pendingAccount = action.payload;
    });
    builder.addCase(login.rejected, (state, action) => {
      state.status = "errored";
      state.error = action.error as Error;
    });
  },
});

// export const { upsertFact } = AccountsSlice.actions;

export const { selectAll: selectAllAccounts } = AccountsAdapter.getSelectors();

export default AccountsSlice.reducer;
