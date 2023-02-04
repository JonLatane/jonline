import {
  createSlice, PayloadAction
} from "@reduxjs/toolkit";
import { Platform } from 'react-native';

export type LocalAppConfiguration = {
  showIntro: boolean;
  darkModeAuto: boolean;
  darkMode: boolean;
  allowServerSelection: boolean;
  separateAccountsByServer: boolean;
}

const initialState: LocalAppConfiguration = {
  showIntro: true,
  darkModeAuto: true,
  darkMode: false,
  allowServerSelection: Platform.OS != 'web',
  separateAccountsByServer: false,
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
    setSeparateAccountsByServer: (state, action: PayloadAction<boolean>) => {
      state.separateAccountsByServer = action.payload;
    }
  },
  extraReducers: (builder) => {
  },
});

export const { setShowIntro, setDarkMode, setDarkModeAuto, setAllowServerSelection, setSeparateAccountsByServer, resetLocalApp } = localAppSlice.actions;
export const localAppReducer = localAppSlice.reducer;
export default localAppReducer;
