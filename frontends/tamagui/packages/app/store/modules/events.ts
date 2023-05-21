import { Event, EventInstance, EventListingType } from "@jonline/api";
import { formatError } from "@jonline/ui";
import {
  Dictionary,
  Draft,
  EntityAdapter,
  EntityId, Slice,
  createEntityAdapter,
  createSlice
} from "@reduxjs/toolkit";
import { publicVisibility } from "app/utils/visibility";
import moment from "moment";
import { LoadEvent, createEvent, defaultEventListingType, loadEvent, loadEventsPage } from './event_actions';
import { loadUserEvents } from "./users";
// import { loadEventsPage } from "./event_actions";
export * from './event_actions';

export interface EventsState {
  loadStatus: "unloaded" | "loading" | "loaded" | "errored";
  createStatus: "creating" | "created" | "errored" | undefined;
  updateStatus: "creating" | "created" | "errored" | undefined;
  error?: Error;
  successMessage?: string;
  errorMessage?: string;
  ids: EntityId[];
  entities: Dictionary<Event>;
  // Links instance IDs to Event IDs.
  instanceEvents: Dictionary<string>;
  instances: Dictionary<EventInstance>;
  // Stores pages of listed event *instances* for listing types used in the UI.
  // i.e.: eventPages[EventListingType.PUBLIC_EVENTS][0] -> ["eventId1", "eventId2"].
  // Events should be loaded from the adapter/slice's entities.
  // Maps EventListingType -> page (as a number) -> eventInstanceIds
  eventPages: Dictionary<Dictionary<string[]>>;
  failedEventIds: string[];
}


const eventsAdapter: EntityAdapter<Event> = createEntityAdapter<Event>({
  selectId: (event) => event.id,
  sortComparer: (a, b) => moment.utc(b.post!.createdAt).unix() - moment.utc(a.post!.createdAt).unix(),
});

const initialState: EventsState = {
  loadStatus: "unloaded",
  createStatus: undefined,
  updateStatus: undefined,
  failedEventIds: [],
  eventPages: {},
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
        state.eventPages[defaultEventListingType] = state.eventPages[defaultEventListingType] || {};
        const firstPage = state.eventPages[defaultEventListingType][0] || [];
        state.eventPages[defaultEventListingType][0] = [action.payload.id, ...firstPage];
      }
      state.successMessage = `Event created.`;
    });
    builder.addCase(createEvent.rejected, (state, action) => {
      state.createStatus = "errored";
      state.error = action.error as Error;
      state.errorMessage = formatError(action.error as Error);
      state.error = action.error as Error;
    });
    // builder.addCase(replyToPost.pending, (state) => {
    //   state.sendReplyStatus = "sending";
    //   state.error = undefined;
    // });
    // builder.addCase(replyToPost.fulfilled, (state, action) => {
    //   state.sendReplyStatus = "sent";
    //   // eventsAdapter.upsertOne(state, action.payload);
    //   const reply = action.payload;
    //   const postIdPath = action.meta.arg.postIdPath;
    //   const basePost = eventsAdapter.getSelectors().selectById(state, postIdPath[0]!);
    //   if (!basePost) {
    //     console.error(`Root post ID (${postIdPath[0]}) not found.`);
    //     return;
    //   }
    //   const rootPost: Post = { ...basePost }

    //   let parentPost: Post = rootPost;
    //   for (const postId of postIdPath.slice(1)) {
    //     parentPost.replies = parentPost.replies.map(p => ({ ...p }));
    //     const nextPost = parentPost.replies.find((reply) => reply.id === postId);
    //     if (!nextPost) {
    //       console.error(`Post ID (${postId}) not found along path ${JSON.stringify(postIdPath)}.`);
    //       return;
    //     }
    //     parentPost = nextPost;
    //   }
    //   parentPost.replies = [reply].concat(...parentPost.replies);
    //   eventsAdapter.upsertOne(state, rootPost);
    //   state.successMessage = `Reply created.`;
    // });
    // builder.addCase(replyToPost.rejected, (state, action) => {
    //   state.sendReplyStatus = "errored";
    //   state.error = action.error as Error;
    //   state.errorMessage = formatError(action.error as Error);
    //   state.error = action.error as Error;
    // });
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
        eventsAdapter.upsertOne(state, {...event, instances});
      });

      const instanceIds = action.payload.events.map(event => event.instances[0]!.id);
      const page = action.meta.arg.page || 0;
      const listingType = action.meta.arg.listingType ?? defaultEventListingType;

      if (!state.eventPages[listingType] || page ===0) state.eventPages[listingType] = {};
      const eventPages: Dictionary<string[]> = state.eventPages[listingType]!;
      // Sensible approach:
      // eventPages[page] = postIds;

      // Chunked approach: (note that we re-initialize `postPages` when `page` == 0)
      let initialPage: number = 0;
      while (eventPages[initialPage]) {
        initialPage++;
      }
      const chunkSize = 10;
      for (let i = 0; i < instanceIds.length; i += chunkSize) {
        const chunk = instanceIds.slice(i, i + chunkSize);
        state.eventPages[listingType]![initialPage + (i/chunkSize)] = chunk;
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
    // builder.addCase(loadGroupEvents.fulfilled, (state, action) => {
    //   const { events } = action.payload;
    //   upsertEvents(state, posts);
    // });
  },
});

export const { removeEvent, clearEventAlerts, resetEvents } = eventsSlice.actions;
export const { selectAll: selectAllEvents, selectById: selectEventById } = eventsAdapter.getSelectors();
export const eventsReducer = eventsSlice.reducer;
export const upsertEvent = eventsAdapter.upsertOne;
export const upsertEvents = eventsAdapter.upsertMany;
export default eventsReducer;

export function getEventsPage(state: EventsState, listingType: EventListingType, page: number): Event[] {
  const pageInstaceIds: string[] = (state.eventPages[listingType] ?? {})[page] ?? [];
  const pageInstances = pageInstaceIds.map(id => state.instances[id]).filter(p => p) as EventInstance[];
  const pageEvents = pageInstances.map(instance => {
    const event = selectEventById(state, instance.eventId);
    return event ? { ...event, instances: [instance] } : undefined;
  }).filter(p => p) as Event[];
  return pageEvents;
}

export function getEventPages(state: EventsState, listingType: EventListingType, throughPage: number): Event[] {
  const result: Event[] = [];
  for (let page = 0; page <= throughPage; page++) {
    const pageEvents = getEventsPage(state, listingType, page);
    result.push(...pageEvents);
  }
  return result;
}
