import {
  createAsyncThunk,
  createEntityAdapter,
  createSlice,
  Dictionary,
  EntityId,
  PayloadAction
} from "@reduxjs/toolkit";
import { Platform } from 'react-native';
import { deleteClient, getServerClient, pinServer, resetCredentialedData, store } from "..";
import { JonlineServer } from "../types";
import { FederatedServer } from "@jonline/api";

export function optServerID(server: JonlineServer | undefined): string | undefined {
  return server ? serverID(server) : undefined;
}

export function serverID(server: JonlineServer): string {
  return `http${server.secure ? "s" : ""}:${server.host}`;
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
  error?: Error;
  successMessage?: string;
  errorMessage?: string;
  // Current "root" server the app is pointing to.
  // On web, if this doesn't match the location.host, we'll show a warning in the
  // AccountsSheet.
  currentServerId?: string;
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
    let client = await getServerClient(server);
    // let serviceVersion: GetServiceVersionResponse = await Promise.race([client.getServiceVersion({}), timeout(5000, "service version")]);
    // let serverConfiguration = await Promise.race([client.getServerConfiguration({}), timeout(5000, "server configuration")]);
    return server;
  }
);

// Initialize the app with a server asynchronously, after the store has already
// been initialized. This lets us detect CDN changes.
let _backendHost: string | undefined = undefined;
let _frontendHost: string | undefined = undefined;

setTimeout(async () => {
  if (Platform.OS != 'web') {
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
  }
}, 1);

function initializeWithServer(initialServer: JonlineServer) {
  getServerClient(initialServer).then(async () => {
    if (!store.getState().servers.currentServerId) {
      const getPrimaryServer = () => store.getState().servers.entities[serverID(initialServer)];
      while (!getPrimaryServer()) {
        console.warn('polling for initial server configuration');
        await new Promise((resolve) => setTimeout(resolve, 100));
      }
      const server = getPrimaryServer();
      store.dispatch(selectServer(server));

      const federatedServers: FederatedServer[] = server?.serverConfiguration?.federationInfo?.servers?.length ?? 0 > 0
        ? server!.serverConfiguration!.federationInfo!.servers
        : (server?.serverConfiguration?.serverInfo?.recommendedServerHosts ?? []).map(host => ({ host, configuredByDefault: true, pinnedByDefault: true }));

      // Configure federated servers in order with a 100ms delay between each.
      for (const { host, configuredByDefault, pinnedByDefault } of federatedServers) {
        const recommendedServer = { host: host, secure: true };
        const pinnedServer = { serverId: serverID(recommendedServer), pinned: true };
        if (configuredByDefault) {
          await getServerClient(recommendedServer)
            .then(async () => {
              if (pinnedByDefault) {
                store.dispatch(pinServer(pinnedServer));
                await new Promise((resolve) => setTimeout(resolve, 100));
              }
            });
        }
      };
    }
  });
}

const initialState: ServersState = {
  status: "unloaded",
  error: undefined,
  currentServerId: undefined,
  ...serversAdapter.getInitialState(),
};

export const serversSlice = createSlice({
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
      if (state.currentServerId == serverID(action.payload)) {
        state.currentServerId = serversAdapter.getSelectors().selectAll(state)
          .filter(s => serverID(s) != serverID(action.payload)).map(serverID)[0];
        //[serverID(action.payload)];//serversAdapter(state, serverID(action.payload));
      }
      deleteClient(action.payload);
      serversAdapter.removeOne(state, serverID(action.payload));
    },
    resetServers: () => initialState,
    clearServerAlerts: (state) => {
      state.errorMessage = undefined;
      state.successMessage = undefined;
      state.error = undefined;
    },
    selectServer: (state, action: PayloadAction<JonlineServer | undefined>) => {

      if (state.currentServerId != serverID(action.payload!)) {
        resetCredentialedData();
      }
      state.currentServerId = serverID(action.payload!);
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
    }
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

export const { selectServer, removeServer, clearServerAlerts, resetServers, moveServerUp, moveServerDown } = serversSlice.actions;

export const { selectAll: selectAllServers, selectById: selectServerById, selectTotal: selectServerTotal } = serversAdapter.getSelectors();

export const serversReducer = serversSlice.reducer;
export default serversReducer;
