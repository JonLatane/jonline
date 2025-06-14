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
import { getCredentialClient, loadUser, loadUsername, loadUsersPage, resetAccessTokens, resetCredentialedData, store } from "..";
import { PinnedServer } from '../federation';
import { JonlineAccount, JonlineServer } from "../types";
import { createAccount, login } from "./account_actions";
import { serverID, serverIDHost, upsertServer } from './servers_state';

export interface AccountsState {
  status: "unloaded" | "loading" | "loaded" | "errored";
  error?: Error;
  successMessage?: string;
  errorMessage?: string;
  // currentAccountId?: string;
  // account?: JonlineAccount;
  // Allows a user to be primarily signed into the above account,
  // but view data from other servers (and accounts on those servers).
  pinnedServers: PinnedServer[];
  excludeCurrentServer: boolean;
  ids: EntityId[];
  entities: Dictionary<JonlineAccount>;
}

export function accountID(account: JonlineAccount | undefined): string | undefined {
  if (!account) return undefined;

  return `${serverID(account.server)}-${account.user?.id}`;
}

export function accountIDHost(accountId: string): string {
  return accountId.split('-')[0]!.split(':')[1]!;
}

const accountsAdapter = createEntityAdapter<JonlineAccount>({
  selectId: (account) => accountID(account)!,
});

const initialState: AccountsState = {
  status: "unloaded",
  error: undefined,
  pinnedServers: [],
  excludeCurrentServer: false,
  ...accountsAdapter.getInitialState(),
};

function withAccountUnpinned(ps: PinnedServer, accountId: string) {
  const serverHost = serverIDHost(ps.serverId);
  const accountHost = accountIDHost(accountId);
  return ps.accountId === accountId || serverHost === accountHost
    ? { ...ps, accountId: undefined }
    : ps;
}
function withServerAccountUnpinned(ps: PinnedServer, serverId: string) {
  const pinnedServerHost = serverIDHost(ps.serverId);
  const serverHost = serverIDHost(serverId);
  return pinnedServerHost === serverHost
    ? { ...ps, accountId: undefined }
    : ps;
}
function withAccountPinned(ps: PinnedServer, accountId: string) {
  const serverHost = serverIDHost(ps.serverId);
  const accountHost = accountIDHost(accountId);

  return serverHost === accountHost
    ? { ...ps, accountId }
    : ps;
}
export const accountsSlice = createSlice({
  name: "accounts",
  initialState: initialState,
  reducers: {
    upsertAccount: (state, action: PayloadAction<JonlineAccount>) => {
      accountsAdapter.upsertOne(state, action.payload);
    },
    removeAccount: (state, action: PayloadAction<string>) => {
      state.pinnedServers = state.pinnedServers.map((ps) => withAccountUnpinned(ps, action.payload));
      accountsAdapter.removeOne(state, action);
    },
    resetAccounts: () => initialState,
    deselectAccount: (state, action: PayloadAction<string>) => {
      state.pinnedServers = state.pinnedServers.map((ps) => withAccountUnpinned(ps, action.payload));
    },
    selectAccount: (state, action: PayloadAction<JonlineAccount | undefined>) => {
      const account = action.payload;
      const accountId = accountID(account);

      setTimeout(() => {
        const currentServerId = store.getState().servers.currentServerId;
        if (!currentServerId) return;

        const currentServerHost = serverIDHost(currentServerId);
        console.log("Resetting credentialed data for", currentServerHost);
        resetCredentialedData(currentServerHost);

        if (currentServerHost !== action.payload?.server.host) {
          resetCredentialedData(account?.server.host);
        }
      }, 1);

      resetAccessTokens();

      if (account) {
        state.pinnedServers = state.pinnedServers.map((ps) => withAccountPinned(ps, accountID(account)!));
      }

      if (account) {
        console.log(`Verifying account ${accountId} auth still works...`);
        setTimeout(async () => {
          const client = await getCredentialClient({ account, server: account.server })
          client.getCurrentUser({}, client.credential).then(user => {
            console.log(`Account auth still works!`);
            store.dispatch(accountsSlice.actions.upsertAccount({ ...account, user }));
          }).catch(() => {
            console.warn(`Failed to load account user data for ${accountId}; user needs to reauthenticate.`);
            store.dispatch(accountsSlice.actions.upsertAccount({ ...account, lastSyncFailed: true, needsReauthentication: true }));

          });
        }, 1);
        state.pinnedServers = state.pinnedServers.map(s =>
          accountId && serverIDHost(s.serverId) === accountIDHost(accountId)
            ? { ...s, accountId }
            : s
        );
      } else {
        // debugger;
        setTimeout(() => {
          const currentServerId = store.getState().servers.currentServerId;
          if (!currentServerId) return;

          store.dispatch(unpinAccountByServerId(currentServerId));
        }, 1);
      }
    },
    setExcludeCurrentServer: (state, action: PayloadAction<boolean>) => {
      state.excludeCurrentServer = action.payload;
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
    },
    notifyUserDeleted: (state, action: PayloadAction<{ user: User, server: JonlineServer }>) => {
      for (const id in state.entities) {
        const account = state.entities[id]!;
        const { user: accountUser, server: accountServer } = account;
        const { user: payloadUser, server: payloadServer } = action.payload;
        if (serverID(accountServer) === serverID(payloadServer) && accountUser.id == payloadUser.id) {
          account.needsReauthentication = true;
          account.lastSyncFailed = true;

          // This is no longer necessary with the refactor to remove currentAccountId from AccountsState!
          // The notion of "current account" in Jonline's store derives purely from 
          // state.servers.currentServerId and state.accounts.pinnedServers.

          // if (state.currentAccountId === accountID(account)) {
          //   state.currentAccountId = undefined;
          // }
        }
      }
    },
    moveAccountUp: (state, action: PayloadAction<string>) => {
      const index = state.ids.indexOf(action.payload);
      if (index > 0) {
        const element = state.ids.splice(index, 1)[0]!;
        state.ids.splice(index - 1, 0, element);
      }
    },
    moveAccountDown: (state, action: PayloadAction<string>) => {
      const index = state.ids.indexOf(action.payload);
      if (index < state.ids.length - 1) {
        const element = state.ids.splice(index, 1)[0]!;
        state.ids.splice(index + 1, 0, element);
      }
    },
    pinServer: (state, action: PayloadAction<PinnedServer>) => {
      const existing = state.pinnedServers.find(s => s.serverId === action.payload.serverId);
      if (existing) {
        existing.accountId = action.payload.accountId ?? existing.accountId;
        existing.pinned = action.payload.pinned;
      } else {
        state.pinnedServers.push(action.payload);
      }
      setTimeout(() => {
        if (action.payload.serverId === store.getState().servers.currentServerId) {
          store.dispatch(accountsSlice.actions.setExcludeCurrentServer(!action.payload.pinned));
        }
      }, 1);
    },
    pinAccount: (state, action: PayloadAction<JonlineAccount>) => {
      const account = action.payload;
      const existing = state.pinnedServers.find(s => s.serverId === serverID(account.server));
      if (existing?.accountId !== accountID(account)) {
        resetCredentialedData(action.payload.server.host);
      }
      if (existing) {
        existing.accountId = accountID(account);
        // existing.pinned = ;
      } else {
        state.pinnedServers.push({
          serverId: serverID(account.server),
          accountId: accountID(account),
          pinned: true
        });

        setTimeout(async () => {
          const client = await getCredentialClient({ account, server: account.server })
          console.log("Loaded client");
          client.getCurrentUser({}, client.credential).then(user => {
            console.log("Account is still valid");
            store.dispatch(accountsSlice.actions.upsertAccount({ ...account, user }));
            resetCredentialedData(action.payload.server.host);
          }).catch(() => {
            console.warn("Failed to load account user data, account may have been deleted.");
            store.dispatch(accountsSlice.actions.upsertAccount({ ...account, lastSyncFailed: true, needsReauthentication: true }));
          });
        }, 1);
      }
    },
    unpinAccount: (state, action: PayloadAction<JonlineAccount>) => {
      const existing = state.pinnedServers.find(s => s.serverId === serverID(action.payload.server));
      if (existing) {
        existing.accountId = undefined;
      } else {
        state.pinnedServers.push({
          serverId: serverID(action.payload.server),
          accountId: undefined,
          pinned: true
        });
      }
      setTimeout(() => resetCredentialedData(action.payload.server.host), 1);
    },
    unpinAccountByServerId: (state, action: PayloadAction<string>) => {
      const serverId = action.payload;
      const existing = state.pinnedServers.find(s => s.serverId === serverId);
      if (existing) {
        existing.accountId = undefined;
      } else {
        state.pinnedServers.push({
          serverId: serverId,
          accountId: undefined,
          pinned: true
        });
      }
      setTimeout(() => resetCredentialedData(serverIDHost(serverId)), 1);
    },
  },
  extraReducers: (builder) => {
    builder.addCase(createAccount.pending, (state) => {
      state.status = "loading";
      state.error = undefined;
    });
    builder.addCase(createAccount.fulfilled, (state, action) => {
      const account = action.payload;
      state.status = "loaded";
      if (!action.meta.arg.skipSelection) {
        state.pinnedServers = state.pinnedServers.map((ps) => withAccountPinned(ps, accountID(account)!));
      }
      accountsAdapter.upsertOne(state, account);
      state.successMessage = `Created account ${account.user.username}`;
      setTimeout(() => {
        store.dispatch(clearAccountAlerts());
      }, 5000);
      resetCredentialedData(account.server.host);
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
      const account = action.payload;
      state.status = "loaded";

      // if (!action.meta.arg.skipSelection) {
      //   state.currentAccountId = accountID(action.payload);
      // }
      state.pinnedServers = state.pinnedServers.map((ps) => withAccountPinned(ps, accountID(account)!));

      accountsAdapter.upsertOne(state, { ...action.payload, lastSyncFailed: false, needsReauthentication: false });
      state.successMessage = `Logged in as ${action.payload.user.username}`;
      setTimeout(() => {
        store.dispatch(clearAccountAlerts());
      }, 5000);
      resetCredentialedData(action.payload.server.host);
    });
    builder.addCase(login.rejected, (state, action) => {
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

    // TODO: This is where we should be clearing auth tokens when they expire.
    [loadUsersPage, loadUser, loadUsername].forEach(thunk => {
      builder.addCase(thunk.rejected, (state, action) => {
        console.warn("Accounts error?", action.error);
        // if (!action.meta.arg.account) return;

        // const accountId = accountID(action.meta.arg.account)!;
        // if (state.currentAccountId === accountId) {
        //   state.currentAccountId = undefined;
        // }
        // for (const pinnedServer of state.pinnedServers) {
        //   if (pinnedServer.accountId === accountId) {
        //     pinnedServer.accountId = undefined;
        //   }
        // }
        // const account = selectAccountById(state, accountId);
        // if (!account) return;
        // accountsAdapter.upsertOne(state, { ...account, lastSyncFailed: true, needsReauthentication: true });
      });
    });
  },
});

export const { selectAccount, removeAccount, clearAccountAlerts,
  resetAccounts, upsertUserData, notifyUserDeleted,
  moveAccountUp, moveAccountDown,
  pinServer, pinAccount, unpinAccount, unpinAccountByServerId, setExcludeCurrentServer } = accountsSlice.actions;

export const { selectAll: selectAllAccounts, selectById: selectAccountById, selectTotal: selectAccountTotal } = accountsAdapter.getSelectors();
export const accountsReducer = accountsSlice.reducer;
export default accountsReducer;
