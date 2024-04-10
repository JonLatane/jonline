import {
  createSlice, PayloadAction
} from "@reduxjs/toolkit";
import { Platform } from 'react-native';
import { JonlineServer } from "../types";
import { Group } from "@jonline/api";
import { serverID } from './servers_state';
import { federatedId, federateId, parseFederatedId } from "../federation";
import { isSafari } from "@jonline/ui";
import { store } from "../store";
// import { Dictionary } from "@fullcalendar/core/internal";
import { Dictionary } from "@reduxjs/toolkit";
import { getServerClient } from "../clients";
import { FederatedGroup } from "./groups_state";

export type DateTimeRenderer = 'custom' | 'native';

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
  recentGroups: string[];
  // Here, undefined means "auto" (i.e. based on screen/window width)
  inlineFeatureNavigation: boolean | undefined;
  // Here, undefined means "auto" (i.e. based on screen/window width)
  shrinkFeatureNavigation: boolean | undefined;
  browseRsvpsFromPreviews: boolean;
  showHelp: boolean;
  showPinnedServers: boolean;
  autoHideNavigation: boolean;
  hideNavigation: boolean;
  imagePostBackgrounds: boolean;
  fancyPostBackgrounds: boolean;
  shrinkPreviews: boolean;
  dateTimeRenderer?: DateTimeRenderer;
  showBigCalendar: boolean;
  starredPostIds: string[];
  starredPostLastOpenedResponseCounts: Dictionary<number>;
  openedStarredPostId?: string | undefined;
  eventPagesOnHome: boolean;
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
  recentGroups: [],
  inlineFeatureNavigation: undefined,
  shrinkFeatureNavigation: undefined,
  browseRsvpsFromPreviews: true,
  showHelp: true,
  showPinnedServers: true,
  autoHideNavigation: false,
  hideNavigation: false,
  imagePostBackgrounds: true,
  fancyPostBackgrounds: false,
  shrinkPreviews: false,
  dateTimeRenderer: 'native',
  showBigCalendar: true,
  starredPostIds: [],
  starredPostLastOpenedResponseCounts: {},
  eventPagesOnHome: false
};

setTimeout(async () => {
  if (store.getState().app.dateTimeRenderer === undefined) {
    // while (!globalThis.navigator) {
    //   await new Promise((resolve) => setTimeout(resolve, 100));
    // }

    store.dispatch(setDateTimeRenderer(
      'native'
      // isSafari() ? 'native' : 'custom'
    ))
  }
  if (store.getState().app.starredPostIds === undefined) {
    store.dispatch(setStarredPostIds([]))
  }
  if (store.getState().app.starredPostLastOpenedResponseCounts === undefined) {
    store.dispatch(updateStarredPostLastOpenedResponseCount({
      postId: 'data-migration-artifact',
      count: 0
    }))
  }
}, 1000);

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
    markGroupVisit: (state, action: PayloadAction<{ group: FederatedGroup }>) => {
      if (!state.recentGroups) {
        state.recentGroups = [];
      }
      const groupId = federatedId(action.payload.group);
      state.recentGroups = [groupId, ...state.recentGroups.filter((g) => g !== groupId)]
    },
    setInlineFeatureNavigation: (state, action: PayloadAction<boolean | undefined>) => {
      state.inlineFeatureNavigation = action.payload;
    },
    setShrinkFeatureNavigation: (state, action: PayloadAction<boolean | undefined>) => {
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
    setHideNavigation: (state, action: PayloadAction<boolean>) => {
      state.hideNavigation = action.payload;
      // if (action.payload && ) {
      //   state.autoHideNavigation = false;
      // }
    },
    setFancyPostBackgrounds: (state, action: PayloadAction<boolean>) => {
      state.fancyPostBackgrounds = action.payload;
    },
    setShrinkPreviews: (state, action: PayloadAction<boolean>) => {
      state.shrinkPreviews = action.payload;
    },
    setDateTimeRenderer: (state, action: PayloadAction<DateTimeRenderer>) => {
      state.dateTimeRenderer = action.payload;
    },
    setShowBigCalendar: (state, action: PayloadAction<boolean>) => {
      state.showBigCalendar = action.payload;
    },
    setImagePostBackgrounds: (state, action: PayloadAction<boolean>) => {
      state.imagePostBackgrounds = action.payload;
    },
    setStarredPostIds: (state, action: PayloadAction<string[]>) => {
      state.starredPostIds = action.payload;
    },
    starPost: (state, action: PayloadAction<string>) => {
      const { serverHost } = parseFederatedId(action.payload);
      state.starredPostIds = [action.payload, ...state.starredPostIds];
    },
    unstarPost: (state, action: PayloadAction<string>) => {
      state.starredPostIds = state.starredPostIds.filter((id) => id !== action.payload);
      delete state.starredPostLastOpenedResponseCounts[action.payload];
    },
    setOpenedStarredPost: (state, action: PayloadAction<string | undefined>) => {
      state.openedStarredPostId = action.payload;
    },
    moveStarredPostUp: (state, action: PayloadAction<string>) => {
      const index = state.starredPostIds.indexOf(action.payload);
      if (index > 0) {
        const element = state.starredPostIds.splice(index, 1)[0]!;
        state.starredPostIds.splice(index - 1, 0, element);
      }
    },
    moveStarredPostDown: (state, action: PayloadAction<string>) => {
      const index = state.starredPostIds.indexOf(action.payload);
      if (index < state.starredPostIds.length - 1) {
        const element = state.starredPostIds.splice(index, 1)[0]!;
        state.starredPostIds.splice(index + 1, 0, element);
      }
    },
    updateStarredPostLastOpenedResponseCount: (state, action: PayloadAction<{ postId: string, count: number }>) => {
      if (state.starredPostLastOpenedResponseCounts === undefined) {
        state.starredPostLastOpenedResponseCounts = {};
      }
      if (state.starredPostIds.includes(action.payload.postId)) {
        state.starredPostLastOpenedResponseCounts[action.payload.postId] = action.payload.count;
      }
    },

    setEventPagesOnHome: (state, action: PayloadAction<boolean>) => {
      state.eventPagesOnHome = action.payload;
    },
  },
  extraReducers: (builder) => {
  },
});

export const { setShowIntro, setDarkMode, setDarkModeAuto, setAllowServerSelection,
  setSeparateAccountsByServer, setShowBetaNavigation, resetLocalConfiguration, setDiscussionChatUI,
  setAutoRefreshDiscussions, setDiscussionRefreshIntervalSeconds, setShowUserIds, setShowEventsOnLatest, markGroupVisit,
  setInlineFeatureNavigation, setShrinkFeatureNavigation, setBrowsingServers, setViewingRecommendedServers, setBrowseRsvpsFromPreviews,
  setShowHelp, setShowPinnedServers, setAutoHideNavigation, setHideNavigation, setFancyPostBackgrounds, setShrinkPreviews,
  setDateTimeRenderer, setShowBigCalendar, setImagePostBackgrounds, setStarredPostIds, starPost, unstarPost,
  moveStarredPostDown, moveStarredPostUp, setOpenedStarredPost, updateStarredPostLastOpenedResponseCount,
  setEventPagesOnHome
} = localAppSlice.actions;
export const localAppReducer = localAppSlice.reducer;
export default localAppReducer;
