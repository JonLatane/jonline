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
import store, { RootState, useTypedDispatch, useTypedSelector } from "../store";

export type LocalAppConfiguration = {
  showIntro: boolean;
  darkModeAuto: boolean;
  darkMode: boolean;
}

const initialState: LocalAppConfiguration = {
  showIntro: true,
  darkModeAuto: true,
  darkMode: false,
};

export const localAppSlice = createSlice({
  name: "localApp",
  initialState: initialState,
  reducers: {
    reset: () => initialState,
    setShowIntro: (state, action: PayloadAction<boolean>) => {
      state.showIntro = action.payload;
    }
  },
  extraReducers: (builder) => {
  },
});

// export const { removePost, clearAlerts } = postsSlice.actions;

// export const { selectAll: selectAllPosts } = postsAdapter.getSelectors();

// export const postsReducer = postsSlice.reducer;

// export default postsSlice.reducer;

export const { setShowIntro } = localAppSlice.actions;
export default localAppSlice.reducer;
