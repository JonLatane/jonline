import { Event, EventInstance } from "@jonline/api";
import { formatError } from "@jonline/ui";
import {
  Dictionary,
  Draft,
  EntityAdapter,
  EntityId, Slice,
  createEntityAdapter,
  createSlice
} from "@reduxjs/toolkit";
import { publicVisibility } from "app/utils/visibility_utils";
import moment from "moment";
import { LoadEvent, createEvent, defaultEventListingType, deleteEvent, loadEvent, loadEventsPage, updateEvent } from './event_actions';
import { loadGroupEventsPage } from "./group_actions";
import { loadUserEvents } from "./user_actions";
export * from './event_actions';

export interface EventsState {
  loadStatus: "unloaded" | "loading" | "loaded" | "errored";
  createStatus: "creating" | "created" | "errored" | undefined;
  updateStatus: "updating" | "updated" | "errored" | undefined;
  deleteStatus: "deleting" | "deleted" | "errored" | undefined;
  error?: Error;
  successMessage?: string;
  errorMessage?: string;
  ids: EntityId[];
  entities: Dictionary<Event>;
  // Links instance IDs to Event IDs.
  instanceEvents: Dictionary<string>;
  instances: Dictionary<EventInstance>;
  eventInstancePages: GroupedEventInstancePages;
  failedEventIds: string[];
}

// Stores pages of listed event *instances* for listing types used in the UI.
// i.e.: eventPages[EventListingType.PUBLIC_EVENTS][0] -> ["eventInstanceId1", "eventInstanceId2"].
// Events should be loaded from the adapter/slice's entities.
// Maps EventListingType -> page (as a number) -> eventInstanceIds
export type GroupedEventInstancePages = Dictionary<Dictionary<string[]>>


export const eventsAdapter: EntityAdapter<Event> = createEntityAdapter<Event>({
  selectId: (event) => event.id,
  sortComparer: (a, b) => moment.utc(b.post!.createdAt).unix() - moment.utc(a.post!.createdAt).unix(),
});

const initialState: EventsState = {
  loadStatus: "unloaded",
  createStatus: undefined,
  updateStatus: undefined,
  deleteStatus: undefined,
  failedEventIds: [],
  eventInstancePages: {},
  instances: {},
  instanceEvents: {},
  ...eventsAdapter.getInitialState(),
};

export const eventsSlice: Slice<Draft<EventsState>, any, "events"> = createSlice({
  name: "events",
  initialState: initialState,
  reducers: {
    upsertEvent: eventsAdapter.upsertOne,
    removeEvent: eventsAdapter.removeOne,
    resetEvents: () => initialState,
    clearEventAlerts: (state) => {
      state.errorMessage = undefined;
      state.successMessage = undefined;
      state.error = undefined;
      state.createStatus = undefined;
      state.updateStatus = undefined;
    }
  },
  extraReducers: (builder) => {
    builder.addCase(createEvent.pending, (state) => {
      state.createStatus = "creating";
      state.error = undefined;
    });
    builder.addCase(createEvent.fulfilled, (state, action) => {
      state.createStatus = "created";
      eventsAdapter.upsertOne(state, action.payload);
      if (publicVisibility(action.payload.post?.visibility)) {
        state.eventInstancePages[defaultEventListingType] = state.eventInstancePages[defaultEventListingType] || {};
        const firstPage = state.eventInstancePages[defaultEventListingType][0] || [];
        state.eventInstancePages[defaultEventListingType][0] = [action.payload.id, ...firstPage];
      }
      state.successMessage = `Event created.`;
    });
    builder.addCase(createEvent.rejected, (state, action) => {
      state.createStatus = "errored";
      state.error = action.error as Error;
      state.errorMessage = formatError(action.error as Error);
      state.error = action.error as Error;
    });
    builder.addCase(updateEvent.pending, (state) => {
      state.updateStatus = "updating";
      state.error = undefined;
    });
    builder.addCase(updateEvent.fulfilled, (state, action) => {
      state.updateStatus = "updated";
      eventsAdapter.upsertOne(state, action.payload);
    });
    builder.addCase(updateEvent.rejected, (state, action) => {
      state.updateStatus = "errored";
      state.error = action.error as Error;
      state.errorMessage = formatError(action.error as Error);
      state.error = action.error as Error;
    });
    builder.addCase(deleteEvent.pending, (state) => {
      state.deleteStatus = "deleting";
      state.error = undefined;
    });
    builder.addCase(deleteEvent.fulfilled, (state, action) => {
      state.deleteStatus = "deleted";
      eventsAdapter.upsertOne(state, action.payload);
    });
    builder.addCase(deleteEvent.rejected, (state, action) => {
      state.deleteStatus = "errored";
      state.error = action.error as Error;
      state.errorMessage = formatError(action.error as Error);
      state.error = action.error as Error;
    });
    builder.addCase(loadEventsPage.pending, (state) => {
      state.loadStatus = "loading";
      state.error = undefined;
    });
    builder.addCase(loadEventsPage.fulfilled, (state, action) => {
      state.loadStatus = "loaded";
      action.payload.events.forEach(event => {
        const oldEvent = selectEventById(state, event.id);
        let instances = event.instances;
        for (let instance of instances) {
          state.instanceEvents[instance.id] = event.id;
          state.instances[instance.id] = instance;
        }
        if (oldEvent) {
          instances = oldEvent.instances.filter(oi => !instances.find(ni => ni.id == oi.id)).concat(event.instances);
        }
        eventsAdapter.upsertOne(state, { ...event, instances });
      });

      const instanceIds = action.payload.events.map(event => event.instances[0]!.id);
      const page = action.meta.arg.page || 0;
      const listingType = action.meta.arg.listingType ?? defaultEventListingType;

      if (!state.eventInstancePages[listingType] || page === 0) state.eventInstancePages[listingType] = {};
      const eventPages: Dictionary<string[]> = state.eventInstancePages[listingType]!;
      // Sensible approach:
      // eventPages[page] = postIds;

      // Chunked approach: (note that we re-initialize `postPages` when `page` == 0)
      let initialPage: number = 0;
      while (action.meta.arg.page && eventPages[initialPage]) {
        initialPage++;
      }
      const chunkSize = 7;
      for (let i = 0; i < instanceIds.length; i += chunkSize) {
        const chunk = instanceIds.slice(i, i + chunkSize);
        state.eventInstancePages[listingType]![initialPage + (i / chunkSize)] = chunk;
      }
      if (state.eventInstancePages[listingType]![0] == undefined) {
        state.eventInstancePages[listingType]![0] = [];
      }

      state.successMessage = `Events loaded.`;
    });
    builder.addCase(loadEventsPage.rejected, (state, action) => {
      state.loadStatus = "errored";
      state.error = action.error as Error;
      state.errorMessage = formatError(action.error as Error);
      state.error = action.error as Error;
    });
    builder.addCase(loadEvent.pending, (state) => {
      state.loadStatus = "loading";
      state.error = undefined;
    });
    builder.addCase(loadEvent.fulfilled, (state, action) => {
      state.loadStatus = "loaded";
      // const oldPost = selectEventById(state, action.payload.event.id);
      const event = action.payload;
      eventsAdapter.upsertOne(state, event);
      state.successMessage = `Post data loaded.`;
    });
    builder.addCase(loadEvent.rejected, (state, action) => {
      state.loadStatus = "errored";
      state.error = action.error as Error;
      state.errorMessage = formatError(action.error as Error);
      state.error = action.error as Error;
      state.failedEventIds = [...state.failedEventIds, (action.meta.arg as LoadEvent).id];
    });

    builder.addCase(loadUserEvents.fulfilled, (state, action) => {
      const { events } = action.payload;
      if (!events) return;

      upsertEvents(state, events);
    });
    builder.addCase(loadGroupEventsPage.fulfilled, (state, action) => {
      const { events } = action.payload;
      upsertEvents(state, events);
    });
  },
});

export const { removeEvent, clearEventAlerts, resetEvents } = eventsSlice.actions;
export const { selectAll: selectAllEvents, selectById: selectEventById } = eventsAdapter.getSelectors();
export const eventsReducer = eventsSlice.reducer;
export const upsertEvent = eventsAdapter.upsertOne;
export const upsertEvents = eventsAdapter.upsertMany;
export default eventsReducer;
