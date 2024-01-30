import {
  createSlice, PayloadAction
} from "@reduxjs/toolkit";
import { Platform } from 'react-native';
import { JonlineServer } from "../types";
import { Group } from "@jonline/api";
import { serverID } from './servers_state';
import { federateId } from "../federation";

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
  // serverRecentGroups: { [serverId: string]: string[] };
  recentGroups: string[];
  // Here, undefined means "auto" (i.e. based on screen/window width)
  inlineFeatureNavigation: boolean | undefined;
  shrinkFeatureNavigation: boolean;
  browseRsvpsFromPreviews: boolean;
  showHelp: boolean;
  showPinnedServers: boolean;
  autoHideNavigation: boolean;
  fancyPostBackgrounds: boolean;
}

const initialState: LocalAppConfiguration = {
  showIntro: true,
  darkModeAuto: true,
  darkMode: false,
  allowServerSelection: Platform.OS !== 'web',
  browsingServers: false,
  viewingRecommendedServers: false,
  separateAccountsByServer: true,
  showBetaNavigation: false,
  discussionChatUI: true,
  autoRefreshDiscussions: true,
  discussionRefreshIntervalSeconds: 6,
  showUserIds: false,
  showEventsOnLatest: true,
  // serverRecentGroups: {},
  recentGroups: [],
  inlineFeatureNavigation: undefined,
  shrinkFeatureNavigation: false,
  browseRsvpsFromPreviews: true,
  showHelp: true,
  showPinnedServers: true,
  autoHideNavigation: false,
  fancyPostBackgrounds: false,
};

export const localAppSlice = createSlice({
  name: "localApp",
  initialState: initialState,
  reducers: {
    resetLocalConfiguration: () => initialState,
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
      if (!state.recentGroups) {
        state.recentGroups = [];
      }
      const groupId = federateId(action.payload.group.id, action.payload.server);
      state.recentGroups = [groupId, ...state.recentGroups.filter((g) => g !== groupId)]
    },
    setInlineFeatureNavigation: (state, action: PayloadAction<boolean | undefined>) => {
      state.inlineFeatureNavigation = action.payload;
    },
    setShrinkFeatureNavigation: (state, action: PayloadAction<boolean>) => {
      state.shrinkFeatureNavigation = action.payload;
    },
    setBrowseRsvpsFromPreviews: (state, action: PayloadAction<boolean>) => {
      state.browseRsvpsFromPreviews = action.payload;
    },
    setShowHelp: (state, action: PayloadAction<boolean>) => {
      // console.log("setShowHelp", action.payload)
      state.showHelp = action.payload;
    },
    setShowPinnedServers: (state, action: PayloadAction<boolean>) => {
      console.log("setShowHelp", action.payload)
      state.showPinnedServers = action.payload;
    },
    setAutoHideNavigation: (state, action: PayloadAction<boolean>) => {
      state.autoHideNavigation = action.payload;
    },
    setFancyPostBackgrounds: (state, action: PayloadAction<boolean>) => {
      state.fancyPostBackgrounds = action.payload;
    },
  },
  extraReducers: (builder) => {
  },
});

export const { setShowIntro, setDarkMode, setDarkModeAuto, setAllowServerSelection,
  setSeparateAccountsByServer, setShowBetaNavigation, resetLocalConfiguration, setDiscussionChatUI,
  setAutoRefreshDiscussions, setDiscussionRefreshIntervalSeconds, setShowUserIds, setShowEventsOnLatest, markGroupVisit,
  setInlineFeatureNavigation, setShrinkFeatureNavigation, setBrowsingServers, setViewingRecommendedServers, setBrowseRsvpsFromPreviews,
  setShowHelp, setShowPinnedServers, setAutoHideNavigation,setFancyPostBackgrounds,
} = localAppSlice.actions;
export const localAppReducer = localAppSlice.reducer;
export default localAppReducer;
