import {
  createAsyncThunk,
  createEntityAdapter,
  createSlice,
  Dictionary,
  EntityId,
  PayloadAction,
} from "@reduxjs/toolkit";
import { GetServiceVersionResponse } from "@jonline/ui/src/generated/federation";
import { GrpcWebImpl, Jonline, JonlineClientImpl } from "@jonline/ui/src/generated/jonline"
import { ServerConfiguration } from "@jonline/ui/src/generated/server_configuration"
import { Platform } from 'react-native';
import { ReactNativeTransport } from '@improbable-eng/grpc-web-react-native-transport';
import { upsertServer, JonlineServer, selectAllServers } from "./servers";
import store, { RootState, useTypedDispatch, useTypedSelector } from "../store";

export type LocalAppConfiguration = {
}

const initialState: LocalAppConfiguration = {
};

export const localAppSlice = createSlice({
  name: "servers",
  initialState: initialState,
  reducers: {
    reset: () => initialState,
  },
  extraReducers: (builder) => {
  },
});

export default localAppSlice.reducer;
