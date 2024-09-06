import {
  createSlice, PayloadAction
} from "@reduxjs/toolkit";

// Config values that should *not* be persisted (should revert to defaults on app restart).
export type TemporaryConfig = {
  forceHideAccountSheetGuide: boolean;
}

const initialState: TemporaryConfig = {
  forceHideAccountSheetGuide: false,
};

export const temporaryConfigSlice = createSlice({
  name: "temporaryConfig",
  initialState: initialState,
  reducers: {
    resetTemporaryConfig: () => initialState,
    setForceHideAccountSheetGuide: (state, action: PayloadAction<boolean>) => {
      state.forceHideAccountSheetGuide = action.payload;
    },
  },
  extraReducers: (builder) => {
  },
});

export const { setForceHideAccountSheetGuide,
} = temporaryConfigSlice.actions;
export const temporaryConfigReducer = temporaryConfigSlice.reducer;
export default temporaryConfigReducer;
