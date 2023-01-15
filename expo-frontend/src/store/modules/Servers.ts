import {
  createAsyncThunk,
  createEntityAdapter,
  createSlice,
  Dictionary,
  EntityId,
} from "@reduxjs/toolkit";
import { GetServiceVersionResponse } from "../../../generated/federation";
// import { fetchFunFact } from "../../api";
// import { FunFact } from "../../types";
// import { RefreshTokenResponse, AccessTokenResponse, CreateAccountRequest, LoginRequest } from "../../../generated/authentication"
// import { User } from "../../../generated/users"
import { GrpcWebImpl, JonlineClientImpl } from "../../../generated/jonline"
import { ServerConfiguration } from "../../../generated/server_configuration"
// import 'localstorage-polyfill';

export type JonlineServer = {
  host: string;
  allowInsecure: boolean;
  serviceVersion?: GetServiceVersionResponse;
  serverConfiguration?: ServerConfiguration;
}

const clients = new Map<JonlineServer, JonlineClientImpl>();
function getClient(server: JonlineServer) {
  if (!clients.has(server)) {
    let host = `http${server.allowInsecure ? "" : "s"}://${server.host}}:27707`
    let client = new JonlineClientImpl(
      new GrpcWebImpl(host, {})
    );
    clients.set(server, client);
    return client;
  }
  return clients.get(server);
}

interface ServersState {
  status: "unloaded" | "loading" | "loaded" | "errored";
  error?: Error;
  // Current server the app is pointing to.
  server: JonlineServer;
  pendingServer?: JonlineServer;
  ids: EntityId[];
  entities: Dictionary<JonlineServer>;
}

const ServersAdapter = createEntityAdapter<JonlineServer>({
  selectId: (server) => server.host,
});

export const createServer = createAsyncThunk<JonlineServer, JonlineServer>(
  "servers/create",
  async (server) => {
    let client = getClient(server);
    let serviceVersion = await client.getServiceVersion({});
    let serverConfiguration = await client.getServerConfiguration({});
    return {...server, serviceVersion, serverConfiguration};
  }
);

const initialServer: JonlineServer = { host: "localhost", allowInsecure: true };
const initialState: ServersState = {
  status: "unloaded",
  error: null,
  server: initialServer,
  ...ServersAdapter.getInitialState(),
};

const ServersSlice = createSlice({
  name: "servers",
  initialState: initialState,//{ ...initialState, ...JSON.parse(localStorage.getItem("servers"))},
  reducers: {
    upsertFact: ServersAdapter.upsertOne,
    reset: () => initialState
  },
  extraReducers: (builder) => {
    builder.addCase(createServer.pending, (state) => {
      state.status = "loading";
      state.error = null;
    });
    builder.addCase(createServer.fulfilled, (state, action) => {
      state.status = "loaded";
      state.server = action.payload;
    });
    builder.addCase(createServer.rejected, (state, action) => {
      state.status = "errored";
      state.error = action.error as Error;
    });
  },
});

export const { upsertFact } = ServersSlice.actions;

export const { selectAll: selectAllServers } = ServersAdapter.getSelectors();

export default ServersSlice.reducer;
