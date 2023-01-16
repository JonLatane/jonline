import {
  createAsyncThunk,
  createEntityAdapter,
  createSlice,
  Dictionary,
  EntityId,
  PayloadAction,
} from "@reduxjs/toolkit";
import { toast } from "react-hot-toast";
import { GetServiceVersionResponse } from "../../../generated/federation";
// import { fetchFunFact } from "../../api";
// import { FunFact } from "../../types";
// import { RefreshTokenResponse, AccessTokenResponse, CreateAccountRequest, LoginRequest } from "../../../generated/authentication"
// import { User } from "../../../generated/users"
import { GrpcWebImpl, JonlineClientImpl } from "../../../generated/jonline"
import { ServerConfiguration } from "../../../generated/server_configuration"
import { useTypedDispatch } from "../store";
// import 'localstorage-polyfill';

export type JonlineServer = {
  host: string;
  allowInsecure: boolean;
  serviceVersion?: GetServiceVersionResponse;
  serverConfiguration?: ServerConfiguration;
}

export const timeout = async (time: number, label: string) => {
	await new Promise((res) => setTimeout(res, time));
  throw `Timed out getting ${label}.`;
}

const clients = new Map<JonlineServer, JonlineClientImpl>();
function getClient(server: JonlineServer) {
  if (!clients.has(server)) {
    let host = `http${server.allowInsecure ? "" : "s"}://${server.host}:27707`
    // debugger;
    let client = new JonlineClientImpl(
      new GrpcWebImpl(host, {})
    );
    // debugger;
    clients.set(server, client);
    return client;
  }
  return clients.get(server);
}

interface ServersState {
  status: "unloaded" | "loading" | "loaded" | "errored";
  error?: Error;
  // Current server the app is pointing to.
  server?: JonlineServer;
  ids: EntityId[];
  entities: Dictionary<JonlineServer>;
}

const serversAdapter = createEntityAdapter<JonlineServer>({
  selectId: (server) => server.host,
});

export const createServer = createAsyncThunk<JonlineServer, JonlineServer>(
  "servers/create",
  async (server) => {
    let client = getClient(server);
    let serviceVersion: GetServiceVersionResponse = await Promise.race([client.getServiceVersion({}), timeout(5000, "service version")]);
    let serverConfiguration = await Promise.race([client.getServerConfiguration({}), timeout(5000, "server configuration")]);
    return {...server, serviceVersion, serverConfiguration};
  }
);

const initialServer: JonlineServer = { host: "localhost", allowInsecure: true };
const initialState: ServersState = {
  status: "unloaded",
  error: null,
  server: initialServer,
  ...serversAdapter.getInitialState(),
};

const serversSlice = createSlice({
  name: "servers",
  initialState: initialState,//{ ...initialState, ...JSON.parse(localStorage.getItem("servers"))},
  reducers: {
    upsertServer: serversAdapter.upsertOne,
    reset: () => initialState,
    selectServer: (state, action: PayloadAction<JonlineServer>) => {
      state.server = action.payload;
    },
  },
  extraReducers: (builder) => {
    builder.addCase(createServer.pending, (state) => {
      state.status = "loading";
      state.error = null;
    });
    builder.addCase(createServer.fulfilled, (state, action) => {
      state.status = "loaded";
      state.server = action.payload;
      serversAdapter.upsertOne(state, action.payload);
      toast.success(`Server ${action.payload.host} running Jonline v${action.payload.serviceVersion!.version} added.`);
    });
    builder.addCase(createServer.rejected, (state, action) => {
      state.status = "errored";
      toast.error(`Error connecting to ${action.meta.arg.host}.`);
      state.error = action.error as Error;
    });
  },
});

export const { selectServer } = serversSlice.actions;

export const { selectAll: selectAllServers } = serversAdapter.getSelectors();

export default serversSlice.reducer;
