import { Media } from "@jonline/api";
import {
  Dictionary,
  EntityAdapter,
  EntityId, PayloadAction,
  createEntityAdapter,
  createSlice
} from "@reduxjs/toolkit";
import moment from "moment";
import { Federated, FederatedEntity, createFederated, federatedEntities, federatedId, federatedPayload, getFederated, parseFederatedId, setFederated } from '../federation';
import { FederatedPagesStatus, GroupedPages, PaginatedIds, createFederatedPagesStatus } from "../pagination";
import { LoadMedia, deleteMedia, loadMedia, loadMediaPage } from './media_actions';
export * from './media_actions';

export type FederatedMedia = FederatedEntity<Media>;
export interface MediaState {
  pagesStatus: FederatedPagesStatus;
  // error?: Error;
  // errorMessage?: string;
  ids: EntityId[];
  entities: Dictionary<FederatedMedia>;
  // Stores pages of listed media for Users.
  // i.e.: mediaPages["userId1"][0] -> ["mediaId1", "mediaId2"].
  // Media should be loaded from the adapter/slice's entities.
  // Maps MediaListingType -> page (as a number) -> mediaInstanceIds
  userMediaPages: Federated<GroupedPages>;
  failedMediaIds: string[];
}
const mediaAdapter: EntityAdapter<FederatedMedia> = createEntityAdapter<FederatedMedia>({
  selectId: (media) => federatedId(media),
  sortComparer: (a, b) => moment.utc(b.createdAt).unix() - moment.utc(a.createdAt).unix(),
});

const initialState: MediaState = {
  pagesStatus: createFederatedPagesStatus(),
  // loadStatus: "unloaded",
  // createStatus: undefined,
  // updateStatus: undefined,
  // deleteStatus: undefined,
  userMediaPages: createFederated({}),
  failedMediaIds: [],
  ...mediaAdapter.getInitialState(),
};

export const mediaSlice = createSlice({
  name: "media",
  initialState: initialState,
  reducers: {
    upsertMedia: mediaAdapter.upsertOne,
    removeMedia: mediaAdapter.removeOne,
    // resetMedia: () => initialState,

    resetMedia: (state, action: PayloadAction<{ serverHost: string | undefined }>) => {
      if (!action.payload.serverHost) return;

      const mediaIdsToRemove = state.ids
        .filter(id => parseFederatedId(id as string).serverHost === action.payload.serverHost);
      mediaAdapter.removeMany(state, mediaIdsToRemove);
      state.failedMediaIds = state.failedMediaIds.filter(id => parseFederatedId(id).serverHost !== action.payload.serverHost);
      state.userMediaPages.values[action.payload.serverHost] = {};
    },
    clearMediaAlerts: (state) => {
      // state.errorMessage = undefined;
      // state.error = undefined;
      // state.createStatus = undefined;
      // state.updateStatus = undefined;
    }
  },
  extraReducers: (builder) => {
    builder.addCase(loadMediaPage.pending, (state, action) => {
      setFederated(state.pagesStatus, action, "loading");
      // state.error = undefined;
    });
    builder.addCase(loadMediaPage.fulfilled, (state, action) => {
      setFederated(state.pagesStatus, action, "loaded");
      const federatedMedia = federatedEntities(action.payload.media, action)
      mediaAdapter.upsertMany(state, federatedMedia);

      const mediaIds = federatedMedia.map(federatedId);
      const page = action.meta.arg.page ?? 0;
      const userId = action.meta.arg.userId!;

      const serverUserMediaPages: GroupedPages = getFederated(state.userMediaPages, action);
      if (!serverUserMediaPages[userId] || page === 0) serverUserMediaPages[userId] = [];

      const userMediaPages: PaginatedIds = serverUserMediaPages[userId]!;
      userMediaPages[page] = mediaIds;
      setFederated(state.userMediaPages, action, serverUserMediaPages);
    });
    builder.addCase(loadMediaPage.rejected, (state, action) => {
      setFederated(state.pagesStatus, action, "errored");
      // state.error = action.error as Error;
      // state.errorMessage = formatError(action.error as Error);
      // state.error = action.error as Error;
    });
    builder.addCase(loadMedia.pending, (state, action) => {
      setFederated(state.pagesStatus, action, "loading");
      // state.error = undefined;
    });
    builder.addCase(loadMedia.fulfilled, (state, action) => {
      setFederated(state.pagesStatus, action, "loaded");
      const media = federatedPayload(action);
      mediaAdapter.upsertOne(state, media);
      // state.successMessage = `Media loaded.`;
    });
    builder.addCase(loadMedia.rejected, (state, action) => {
      setFederated(state.pagesStatus, action, "errored");
      // state.error = action.error as Error;
      // state.errorMessage = formatError(action.error as Error);
      // state.error = action.error as Error;
      state.failedMediaIds = [...state.failedMediaIds, (action.meta.arg as LoadMedia).id];
    });
    builder.addCase(deleteMedia.pending, (state, action) => {
      setFederated(state.pagesStatus, action, "deleting");
      // state.error = undefined;
    });
    builder.addCase(deleteMedia.fulfilled, (state, action) => {
      setFederated(state.pagesStatus, action, "deleted");
      mediaAdapter.removeOne(state, action.meta.arg.id);
      const userMediaPages: GroupedPages = getFederated(state.userMediaPages, action);

      for (const i in userMediaPages) {
        const userPages = userMediaPages[i]!;
        for (const j in userPages) {
          const page = userPages[j]!;
          const filteredPage = page.filter(id => id !== action.meta.arg.id);
          userPages[j] = filteredPage;
        }
      }
      setFederated(state.userMediaPages, action, userMediaPages);
      // state.successMessage = `Media deleted.`;
    });
    builder.addCase(deleteMedia.rejected, (state, action) => {
      setFederated(state.pagesStatus, action, "errored");
      // state.error = action.error as Error;
      // state.errorMessage = formatError(action.error as Error);
      // state.error = action.error as Error;
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
