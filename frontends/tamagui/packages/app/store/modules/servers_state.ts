import {
  createAsyncThunk,
  createEntityAdapter,
  createSlice,
  Dictionary,
  EntityId,
  PayloadAction
} from "@reduxjs/toolkit";
import { Platform } from 'react-native';
import { accountIDHost, deleteClient, getServerClient, pinServer, resetCredentialedData, selectAccount, store } from "..";
import { JonlineServer } from "../types";
import { FederatedServer } from "@jonline/api";

export function optServerID(server: JonlineServer | undefined): string | undefined {
  return server ? serverID(server) : undefined;
}

export function serverID(server: JonlineServer): string {
  return `http${server.secure ? "s" : ""}:${server.host}`;
}

export function serverIDHost(serverId: string): string {
  // console.log(serverId);
  return serverId.split(':')[1]!;
}

export function serverUrl(server: JonlineServer): string {
  return `http${server.secure ? "s" : ""}://${server.host}`;
}

export function frontendServerUrl(server: JonlineServer): string {
  const host = server.serverConfiguration?.externalCdnConfig?.frontendHost ?? server.host;
  return `http${server.secure ? "s" : ""}://${host}`;
}

// export function backendServerUrl(server: JonlineServer): string {
//   const host = server.serverConfiguration?.externalCdnConfig?.backendHost ?? server.host;
//   return `http${server.secure ? "s" : ""}://${host}`;
// }

export interface ServersState {
  status: "unloaded" | "loading" | "loaded" | "errored";
  configuringFederation: boolean;
  error?: Error;
  successMessage?: string;
  errorMessage?: string;
  // Current "root" server the app is pointing to.
  // On web, if this doesn't match the location.host, we'll show a warning in the
  // AccountsSheet.
  currentServerId?: string;

  // When creating users (login/create account), posts, events, media, and groups,
  // we need to know which server to send the request to.
  // The account for the server is stored in the accounts module, in accounts.pinnedServers.
  creationServerId?: string;
  // server?: JonlineServer;
  ids: EntityId[];
  entities: Dictionary<JonlineServer>;
}

export const serversAdapter = createEntityAdapter<JonlineServer>({
  selectId: serverID,
});

export const upsertServer = createAsyncThunk<JonlineServer, JonlineServer>(
  "servers/create",
  async (server, state) => {
    // getServerClient will update/upsert the server as a side effect.
    let _client = await getServerClient(server);
    // let serviceVersion: GetServiceVersionResponse = await Promise.race([client.getServiceVersion({}), timeout(5000, "service version")]);
    // let serverConfiguration = await Promise.race([client.getServerConfiguration({}), timeout(5000, "server configuration")]);
    return server;
  }
);

// Initialize the app with a server asynchronously, after the store has already
// been initialized.
setTimeout(async () => {
  if (Platform.OS !== 'web') {
    const initialServer = {
      host: 'jonline.io',
      secure: true,
    };
    initializeWithServer(initialServer);
    return;
  }

  while (!globalThis.window) {
    await new Promise((resolve) => setTimeout(resolve, 100));
  }

  if (!store.getState().servers.currentServerId) {
    const initialServer: JonlineServer = Platform.OS == 'web' && globalThis.window?.location
      ? {
        host: window.location.hostname,
        secure: window.location.protocol === 'https:',
      }
      : {
        host: 'jonline.io',
        secure: true,
      };

    initializeWithServer(initialServer);
  } else {
    // Just in case we get in a weird state where there's a server setup but federation wasn't fully configured...
    store.dispatch(finishConfiguringFederation());
  }
}, 1);

function initializeWithServer(initialServer: JonlineServer) {
  store.dispatch(startConfiguringFederation());
  getServerClient(initialServer).then(async () => {
    if (!store.getState().servers.currentServerId) {
      const getPrimaryServer = () => store.getState().servers.entities[serverID(initialServer)];
      while (!getPrimaryServer()) {
        console.warn('polling for initial server configuration');
        await new Promise((resolve) => setTimeout(resolve, 100));
      }
      const primaryServer = getPrimaryServer();
      if (!primaryServer) return;

      store.dispatch(selectServer(primaryServer));

      const federatedServers: FederatedServer[] = primaryServer.serverConfiguration?.federationInfo?.servers ?? [];

      const allFederatedServers = [
        { host: primaryServer.host, configuredByDefault: true, pinnedByDefault: true },
        ...federatedServers.filter(s => s.host != primaryServer.host),
      ]
      // Configure federated servers in order with a 100ms delay between each.
      for (const { host, configuredByDefault, pinnedByDefault } of allFederatedServers) {
        const recommendedServer = { host: host, secure: host !== 'localhost' };
        const pinnedServer = { serverId: serverID(recommendedServer), pinned: true };
        if (configuredByDefault) {
          await getServerClient(recommendedServer)
            .then(async () => {
              if (pinnedByDefault) {
                store.dispatch(pinServer(pinnedServer));
                await new Promise((resolve) => setTimeout(resolve, 25));
              }
            }).catch(() => {
              console.error(`Failed to configure federated server ${host}`);
            });
        }
      };
    }
    store.dispatch(finishConfiguringFederation());
  });
}

const initialState: ServersState = {
  status: "unloaded",
  configuringFederation: true,
  error: undefined,
  currentServerId: undefined,
  ...serversAdapter.getInitialState(),
};

const serversSlice = createSlice({
  name: "servers",
  initialState: initialState,
  reducers: {
    upsertServer: (state, action: PayloadAction<JonlineServer>) => {
      const isAdd = !serversAdapter.getSelectors().selectById(state, serverID(action.payload));
      serversAdapter.upsertOne(state, action);
      if (isAdd) {
        setTimeout(() => store.dispatch(pinServer({
          serverId: serverID(action.payload),
          pinned: true
        })), 1);
      }
    },
    removeServer: (state, action: PayloadAction<JonlineServer>) => {
      // if (state.currentServerId === serverID(action.payload)) {
      //   state.currentServerId = serversAdapter.getSelectors().selectAll(state)
      //     .filter(s => serverID(s) !== serverID(action.payload)).map(serverID)[0];
      //   //[serverID(action.payload)];//serversAdapter(state, serverID(action.payload));
      // }
      deleteClient(action.payload);
      serversAdapter.removeOne(state, serverID(action.payload));
      setTimeout(() => {
        store.dispatch(pinServer({
          serverId: serverID(action.payload),
          pinned: false
        }))
      }, 1);
      resetCredentialedData(action.payload.host);
    },
    resetServers: () => initialState,
    clearServerAlerts: (state) => {
      state.errorMessage = undefined;
      state.successMessage = undefined;
      state.error = undefined;
    },
    selectServer: (state, action: PayloadAction<JonlineServer | undefined>) => {
      const oldServerId = state.currentServerId;
      const newServerId = serverID(action.payload!);
      if (newServerId === undefined && state.ids.length > 0) return;
      if (!state.ids.includes(newServerId)) return;

      state.currentServerId = newServerId;
      state.creationServerId = newServerId;

      // This is no longer necessary with the refactor to remove currentAccountId from AccountsState!
      // The notion of "current account" in Jonline's store derives purely from 
      // state.servers.currentServerId and state.accounts.pinnedServers.

      // setTimeout(() => {
      //   const currentAccountId = store.getState().accounts.pinnedServers.find(ps => ps.serverId === oldServerId)?.accountId;
      //   if (currentAccountId && newServerId && oldServerId != newServerId &&
      //     accountIDHost(currentAccountId) !== serverIDHost(newServerId)) {
      //     store.dispatch(selectAccount(undefined));
      //   }
      // }, 1);
    },
    selectCreationServer: (state, action: PayloadAction<JonlineServer | undefined>) => {
      const creationServerId = serverID(action.payload!);
      state.creationServerId = creationServerId;

      setTimeout(() => {
        const pinnedServer = store.getState().accounts.pinnedServers.find(
          ps => ps.serverId === creationServerId
        );
        if (!pinnedServer?.pinned) {
          store.dispatch(pinServer({
            serverId: creationServerId!,
            accountId: pinnedServer?.accountId,
            pinned: true
          }));
        }
      }, 1);
    },
    moveServerUp: (state, action: PayloadAction<string>) => {
      const index = state.ids.indexOf(action.payload);
      if (index > 0) {
        const element = state.ids.splice(index, 1)[0]!;
        state.ids.splice(index - 1, 0, element);
      }
    },
    moveServerDown: (state, action: PayloadAction<string>) => {
      const index = state.ids.indexOf(action.payload);
      if (index < state.ids.length - 1) {
        const element = state.ids.splice(index, 1)[0]!;
        state.ids.splice(index + 1, 0, element);
      }
    },
    startConfiguringFederation: (state) => {
      state.configuringFederation = true;
    },
    finishConfiguringFederation: (state) => {
      state.configuringFederation = false;
    },
  },
  extraReducers: (builder) => {
    builder.addCase(upsertServer.pending, (state) => {
      state.status = "loading";
      state.error = undefined;
    });
    builder.addCase(upsertServer.fulfilled, (state, action) => {
      state.status = "loaded";
      // let server = action.payload;
      serversAdapter.upsertOne(state, action.payload);
      // if (!state.server || serverID(server) == serverID(state.server!)) {
      //   state.currentServerId = serverId(server);
      // }
      console.log(`Server ${action.payload.host} running Jonline v${action.payload.serviceVersion?.version} added.`);
      state.successMessage = `Server added.`;
    });
    builder.addCase(upsertServer.rejected, (state, action) => {
      state.status = "errored";
      console.error(`Error connecting to ${action.meta.arg.host}.`, action.error);
      state.errorMessage = `Error connecting to ${action.meta.arg.host}.`;
      state.error = action.error as Error;
    });
  },
});
const {
  startConfiguringFederation,
  finishConfiguringFederation
} = serversSlice.actions;

export const {
  selectServer,
  removeServer,
  clearServerAlerts,
  resetServers,
  moveServerUp,
  moveServerDown,
  selectCreationServer
  // startConfiguringFederation,
  // finishConfiguringFederation
} = serversSlice.actions;


export const {
  selectAll: selectAllServers,
  selectById: selectServerById,
  selectTotal: selectServerTotal
} = serversAdapter.getSelectors();

export const serversReducer = serversSlice.reducer;
export default serversReducer;
