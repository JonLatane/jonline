import { Media } from "@jonline/api";
import { formatError } from "@jonline/ui";
import {
  Dictionary,
  Draft,
  EntityAdapter,
  EntityId, Slice,
  createEntityAdapter,
  createSlice
} from "@reduxjs/toolkit";
import moment from "moment";
import { LoadMedia, loadMedia, loadMediaPage } from './media_actions';
export * from './media_actions';

export interface MediaState {
  loadStatus: "unloaded" | "loading" | "loaded" | "errored";
  createStatus: "creating" | "created" | "errored" | undefined;
  updateStatus: "creating" | "created" | "errored" | undefined;
  error?: Error;
  successMessage?: string;
  errorMessage?: string;
  ids: EntityId[];
  entities: Dictionary<Media>;
  // Stores pages of listed media for Users.
  // i.e.: mediaPages["userId1"][0] -> ["mediaId1", "mediaId2"].
  // Media should be loaded from the adapter/slice's entities.
  // Maps MediaListingType -> page (as a number) -> mediaInstanceIds
  userMediaPages: Dictionary<Dictionary<string[]>>;
  failedMediaIds: string[];
}

const mediaAdapter: EntityAdapter<Media> = createEntityAdapter<Media>({
  selectId: (media) => media.id,
  sortComparer: (a, b) => moment.utc(b.createdAt).unix() - moment.utc(a.createdAt).unix(),
});

const initialState: MediaState = {
  loadStatus: "unloaded",
  createStatus: undefined,
  updateStatus: undefined,
  userMediaPages: {},
  failedMediaIds: [],
  ...mediaAdapter.getInitialState(),
};

export const mediaSlice: Slice<Draft<MediaState>, any, "media"> = createSlice({
  name: "media",
  initialState: initialState,
  reducers: {
    upsertMedia: mediaAdapter.upsertOne,
    removeMedia: mediaAdapter.removeOne,
    resetMedia: () => initialState,
    clearMediaAlerts: (state) => {
      state.errorMessage = undefined;
      state.successMessage = undefined;
      state.error = undefined;
      state.createStatus = undefined;
      state.updateStatus = undefined;
    }
  },
  extraReducers: (builder) => {
    builder.addCase(loadMediaPage.pending, (state) => {
      state.loadStatus = "loading";
      state.error = undefined;
    });
    builder.addCase(loadMediaPage.fulfilled, (state, action) => {
      state.loadStatus = "loaded";
      mediaAdapter.upsertMany(state, action.payload.media);

      const userId = action.meta.arg.userId!;
      const page = action.meta.arg.page ?? 0;

      if (!state.userMediaPages[userId]) state.userMediaPages[userId] = {};
      state.userMediaPages[userId]![page] = action.payload.media.map(media => media.id);

      state.successMessage = `Media loaded.`;
    });
    builder.addCase(loadMediaPage.rejected, (state, action) => {
      state.loadStatus = "errored";
      state.error = action.error as Error;
      state.errorMessage = formatError(action.error as Error);
      state.error = action.error as Error;
    });
    builder.addCase(loadMedia.pending, (state) => {
      state.loadStatus = "loading";
      state.error = undefined;
    });
    builder.addCase(loadMedia.fulfilled, (state, action) => {
      state.loadStatus = "loaded";
      const media = action.payload;
      mediaAdapter.upsertOne(state, media);
      state.successMessage = `Post data loaded.`;
    });
    builder.addCase(loadMedia.rejected, (state, action) => {
      state.loadStatus = "errored";
      state.error = action.error as Error;
      state.errorMessage = formatError(action.error as Error);
      state.error = action.error as Error;
      state.failedMediaIds = [...state.failedMediaIds, (action.meta.arg as LoadMedia).id];
    });
  },
});

export const { removeMedia, clearMediaAlerts, resetMedia } = mediaSlice.actions;
export const { selectAll: selectAllMedia, selectById: selectMediaById } = mediaAdapter.getSelectors();
export const mediaReducer = mediaSlice.reducer;
export const upsertMedia = mediaAdapter.upsertOne;
export const upsertManyMedia = mediaAdapter.upsertMany;
export default mediaReducer;

export function getMediaPage(state: MediaState, userId: string, page: number): Media[] {
  const pageMediaIds: string[] = (state.userMediaPages[userId] ?? {})[page] ?? [];
  const pageMedia = pageMediaIds.map(id => selectMediaById(state, id)).filter(p => p) as Media[];
  return pageMedia;
}
