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
import { pageInitializer } from "../../utils/page_initializer";

export type DateTimeRenderer = 'custom' | 'native';

export type CalendarImplementation = 'fullcalendar' | 'big-calendar' | 'daypilot';

export type Config = {
  deviceName: string;
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
  calendarImplementation: CalendarImplementation;
  hasOpenedAccounts: boolean;
  alwaysShowHideButton: boolean;
}

const generateDeviceName = () => {
  let device = "Unknown";
  const ua = {
    "Generic Linux": /Linux/i,
    "Android": /Android/i,
    "BlackBerry": /BlackBerry/i,
    "Bluebird": /EF500/i,
    "Chrome OS": /CrOS/i,
    "Datalogic": /DL-AXIS/i,
    "Honeywell": /CT50/i,
    "iPad": /iPad/i,
    "iPhone": /iPhone/i,
    "iPod": /iPod/i,
    "macOS": /Macintosh/i,
    "Windows": /IEMobile|Windows/i,
    "Zebra": /TC70|TC55/i,
  }
  Object.keys(ua).map(v => navigator.userAgent.match(ua[v]) && (device = v));

  return `${device} at ${location.hostname} (first accessed ${new Date().toISOString()})`;
}

const defaultDeviceName = `New Device (first accessed ${new Date().toISOString()})`;

const initialState: Config = {
  deviceName: defaultDeviceName,
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
  eventPagesOnHome: false,
  calendarImplementation: 'big-calendar',
  hasOpenedAccounts: false,
  alwaysShowHideButton: false,
};


pageInitializer(async () => {
  if (store.getState().config.deviceName === defaultDeviceName) {
    store.dispatch(setDeviceName(generateDeviceName()));
  }
});

pageInitializer(async () => {
  const state = store.getState();
  if (state.config.dateTimeRenderer === undefined) {

    store.dispatch(setDateTimeRenderer(
      'native'
      // isSafari() ? 'native' : 'custom'
    ))
  }
  if (state.config.starredPostIds === undefined) {
    store.dispatch(setStarredPostIds([]))
  }
  if (state.config.starredPostLastOpenedResponseCounts === undefined) {
    store.dispatch(updateStarredPostLastOpenedResponseCount({
      postId: 'data-migration-artifact',
      count: 0
    }))
  }
}, 1000);

export const configSlice = createSlice({
  name: "config",
  initialState: initialState,
  reducers: {
    resetConfig: () => initialState,
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
    setCalendarImplementation: (state, action: PayloadAction<CalendarImplementation>) => {
      state.calendarImplementation = action.payload;
    },
    setHasOpenedAccounts: (state, action: PayloadAction<boolean>) => {
      state.hasOpenedAccounts = action.payload;
    },
    setAlwaysShowHideButton: (state, action: PayloadAction<boolean>) => {
      state.alwaysShowHideButton = action.payload;
    },
    setDeviceName: (state, action: PayloadAction<string>) => {
      state.deviceName = action.payload;
    }
  },
  extraReducers: (builder) => {
  },
});

export const { setShowIntro, setDarkMode, setDarkModeAuto, setAllowServerSelection,
  setSeparateAccountsByServer, setShowBetaNavigation, resetConfig, setDiscussionChatUI,
  setAutoRefreshDiscussions, setDiscussionRefreshIntervalSeconds, setShowUserIds, setShowEventsOnLatest, markGroupVisit,
  setInlineFeatureNavigation, setShrinkFeatureNavigation, setBrowsingServers, setViewingRecommendedServers, setBrowseRsvpsFromPreviews,
  setShowHelp, setShowPinnedServers, setAutoHideNavigation, setHideNavigation, setFancyPostBackgrounds, setShrinkPreviews,
  setDateTimeRenderer, setShowBigCalendar, setImagePostBackgrounds, setStarredPostIds, starPost, unstarPost,
  moveStarredPostDown, moveStarredPostUp, setOpenedStarredPost, updateStarredPostLastOpenedResponseCount,
  setEventPagesOnHome, setCalendarImplementation, setHasOpenedAccounts, setAlwaysShowHideButton, setDeviceName
} = configSlice.actions;
export const configReducer = configSlice.reducer;
export default configReducer;
