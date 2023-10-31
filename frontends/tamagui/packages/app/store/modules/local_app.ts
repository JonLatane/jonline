import {
  createSlice, PayloadAction
} from "@reduxjs/toolkit";
import { Platform } from 'react-native';
import { JonlineServer } from "../types";
import { Group } from "@jonline/api";
import { serverID } from './servers';

export type LocalAppConfiguration = {
  showIntro: boolean;
  darkModeAuto: boolean;
  darkMode: boolean;
  allowServerSelection: boolean;
  browsingServers: boolean;
  viewingRecommendedServers: boolean;
  separateAccountsByServer: boolean;
  showBetaNavigation: boolean;
  discussionChatUI: boolean;
  autoRefreshDiscussions: boolean;
  discussionRefreshIntervalSeconds: number;
  showUserIds: boolean;
  showEventsOnLatest: boolean;
  serverRecentGroups: { [serverId: string]: string[] };
  inlineFeatureNavigation: boolean | undefined;
}

const initialState: LocalAppConfiguration = {
  showIntro: true,
  darkModeAuto: true,
  darkMode: false,
  allowServerSelection: Platform.OS != 'web',
  browsingServers: false,
  viewingRecommendedServers: true,
  separateAccountsByServer: true,
  showBetaNavigation: false,
  discussionChatUI: true,
  autoRefreshDiscussions: true,
  discussionRefreshIntervalSeconds: 6,
  showUserIds: false,
  showEventsOnLatest: true,
  serverRecentGroups: {},
  inlineFeatureNavigation: undefined,
};

export const localAppSlice = createSlice({
  name: "localApp",
  initialState: initialState,
  reducers: {
    resetLocalApp: () => initialState,
    setShowIntro: (state, action: PayloadAction<boolean>) => {
      state.showIntro = action.payload;
    },
    setDarkMode: (state, action: PayloadAction<boolean>) => {
      state.darkMode = action.payload;
    },
    setDarkModeAuto: (state, action: PayloadAction<boolean>) => {
      state.darkModeAuto = action.payload;
    },
    setAllowServerSelection: (state, action: PayloadAction<boolean>) => {
      state.allowServerSelection = action.payload;
    },
    setBrowsingServers: (state, action: PayloadAction<boolean>) => {
      state.browsingServers = action.payload;
    },
    setViewingRecommendedServers: (state, action: PayloadAction<boolean>) => {
      state.viewingRecommendedServers = action.payload;
    },
    setSeparateAccountsByServer: (state, action: PayloadAction<boolean>) => {
      state.separateAccountsByServer = action.payload;
    },
    setShowBetaNavigation: (state, action: PayloadAction<boolean>) => {
      state.showBetaNavigation = action.payload;
    },
    setDiscussionChatUI: (state, action: PayloadAction<boolean>) => {
      state.discussionChatUI = action.payload;
    },
    setAutoRefreshDiscussions: (state, action: PayloadAction<boolean>) => {
      state.autoRefreshDiscussions = action.payload;
    },
    setDiscussionRefreshIntervalSeconds: (state, action: PayloadAction<number>) => {
      state.discussionRefreshIntervalSeconds = action.payload;
    },
    setShowUserIds: (state, action: PayloadAction<boolean>) => {
      state.showUserIds = action.payload;
    },
    setShowEventsOnLatest: (state, action: PayloadAction<boolean>) => {
      state.showEventsOnLatest = action.payload;
    },
    markGroupVisit: (state, action: PayloadAction<{ server: JonlineServer, group: Group }>) => {
      // state.showEventsOnLatest = action.payload;
      const serverId = serverID(action.payload.server);
      if (!state.serverRecentGroups) {
        state.serverRecentGroups = {};
      }
      const currentValue = state.serverRecentGroups[serverId] ?? [];

      state.serverRecentGroups[serverId] = [
        action.payload.group.id,
        ...currentValue.filter((g) => g != action.payload.group.id)
      ];
    },
    setInlineFeatureNavigation: (state, action: PayloadAction<boolean | undefined>) => {
      state.inlineFeatureNavigation = action.payload;
    },
  },
  extraReducers: (builder) => {
  },
});

export const { setShowIntro, setDarkMode, setDarkModeAuto, setAllowServerSelection,
  setSeparateAccountsByServer, setShowBetaNavigation, resetLocalApp, setDiscussionChatUI,
  setAutoRefreshDiscussions, setDiscussionRefreshIntervalSeconds, setShowUserIds, setShowEventsOnLatest, markGroupVisit,
  setInlineFeatureNavigation, setBrowsingServers, setViewingRecommendedServers
} = localAppSlice.actions;
export const localAppReducer = localAppSlice.reducer;
export default localAppReducer;
