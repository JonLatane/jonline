import { User } from "@jonline/api";
import { formatError } from "@jonline/ui";
import {
  Dictionary,
  EntityId,
  PayloadAction,
  createEntityAdapter,
  createSlice
} from "@reduxjs/toolkit";
import 'react-native-get-random-values';
import { resetAccessTokens, resetCredentialedData } from "..";
import { JonlineAccount, JonlineServer } from "../types";
import { createAccount, login } from "./account_actions";
import { serverID, upsertServer } from "./servers";

export interface AccountsState {
  status: "unloaded" | "loading" | "loaded" | "errored";
  error?: Error;
  successMessage?: string;
  errorMessage?: string;
  account?: JonlineAccount;
  ids: EntityId[];
  entities: Dictionary<JonlineAccount>;
}

export function accountId(account: JonlineAccount | undefined): string | undefined {
  if (!account) return undefined;

  return `${serverID(account.server)}-${account.user.id}`;
}
const accountsAdapter = createEntityAdapter<JonlineAccount>({
  selectId: (account) => accountId(account)!,
});

const initialState: AccountsState = {
  status: "unloaded",
  error: undefined,
  ...accountsAdapter.getInitialState(),
};

export const accountsSlice = createSlice({
  name: "accounts",
  initialState: initialState,//{ ...initialState, ...JSON.parse(localStorage.getItem("accounts")) },
  reducers: {
    upsertAccount: (state, action: PayloadAction<JonlineAccount>) => {
      accountsAdapter.upsertOne(state, action.payload);
      if (accountId(state.account) === accountId(action.payload)) {
        state.account = action.payload;
      }
    },
    removeAccount: (state, action: PayloadAction<string>) => {
      if (accountId(state.account) === action.payload) {
        state.account = undefined;
      }
      accountsAdapter.removeOne(state, action);
    },
    resetAccounts: () => initialState,
    selectAccount: (state, action: PayloadAction<JonlineAccount | undefined>) => {
      if (accountId(state.account) != accountId(action.payload)) {
        resetCredentialedData();
      }
      resetAccessTokens();
      state.account = action.payload;
    },
    clearAccountAlerts: (state) => {
      state.errorMessage = undefined;
      state.successMessage = undefined;
      state.error = undefined;
    },
    upsertUserData(state, action: PayloadAction<{ user: User, server: JonlineServer }>) {
      for (const accountId in state.entities) {
        const account = state.entities[accountId]!;
        const { user: accountUser, server: accountServer } = account;
        const { user: payloadUser, server: payloadServer } = action.payload;
        if (serverID(accountServer) === serverID(payloadServer) && accountUser.id == payloadUser.id) {
          account.user = action.payload.user;
        }
        //TODO does this work as expected?
      }
    }
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
      state.successMessage = `Created account ${action.payload.user.username}`;
      resetCredentialedData();
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
      state.successMessage = `Logged in as ${action.payload.user.username}`;
      resetCredentialedData();
    });
    builder.addCase(login.rejected, (state, action) => {
      state.status = "errored";
      state.error = action.error as Error;
      state.status = "errored";
      state.error = action.error as Error;
      state.errorMessage = formatError(action.error as Error);
      state.error = action.error as Error;
    });
    builder.addCase(upsertServer.fulfilled, (state, action) => {
      for (const accountId in state.entities) {
        const account = state.entities[accountId]!;
        if (serverID(account.server) === serverID(action.payload)) {
          account.server = action.payload;
        }
      }
    });
  },
});

export const { selectAccount, removeAccount, clearAccountAlerts, resetAccounts, upsertUserData } = accountsSlice.actions;

export const { selectAll: selectAllAccounts, selectTotal: selectAccountTotal } = accountsAdapter.getSelectors();
export const accountsReducer = accountsSlice.reducer;
export default accountsReducer;
