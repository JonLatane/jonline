import { Event, TimeFilter } from "@jonline/api";
import { formatError } from "@jonline/ui";
import {
  Dictionary,
  Draft,
  EntityAdapter,
  EntityId, PayloadAction, Slice,
  createEntityAdapter,
  createSlice
} from "@reduxjs/toolkit";
import { publicVisibility } from "app/utils/visibility_utils";
import moment from "moment";
import { FederatedPagesStatus, PaginatedIds, createFederatedPagesStatus } from "../pagination";
import { store } from "../store";
import { LoadEvent, LoadEventByInstance, createEvent, defaultEventListingType, deleteEvent, loadEvent, loadEventByInstance, loadEventsPage, updateEvent } from './event_actions';
import { loadGroupEventsPage } from "./group_actions";
import { locallyUpsertPost } from "./posts_state";
import { loadUserEvents } from "./user_actions";
import { Federated, FederatedEntity, createFederated, federatedEntities, federatedId, federatedPayload, getFederated, setFederated } from '../federation';
export * from './event_actions';

export type FederatedEvent = FederatedEntity<Event>;
export interface EventsState {
  pagesStatus: FederatedPagesStatus;
  ids: EntityId[];
  entities: Dictionary<FederatedEvent>;
  // Links instance IDs to Event IDs.
  instanceEvents: Federated<Dictionary<string>>;
  // instances: Dictionary<EventInstance>;
  eventInstancePages: Federated<GroupedEventInstancePages>;
  failedEventIds: Federated<string[]>;
  failedInstanceIds: Federated<string[]>;
}

// Stores pages of listed event *instances* for listing types used in the UI.
// i.e.: eventPages[EventListingType.ALL_ACCESSIBLE_EVENTS]['{"ends_after":null}'][0]:  -> ["eventInstanceId1", "eventInstanceId2"].
// Events should be loaded from the adapter/slice's entities.
// Maps EventListingType -> serialized timeFilter-> page (as a number) -> eventInstanceIds
export type GroupedEventInstancePages = Dictionary<Dictionary<PaginatedIds>>
export const unfilteredTime = 'unfiltered';
export function serializeTimeFilter(filter: TimeFilter | undefined): string {
  if (!filter) return unfilteredTime;
  return JSON.stringify(TimeFilter.toJSON(filter ?? TimeFilter.create()));
};

export const eventsAdapter: EntityAdapter<FederatedEvent> = createEntityAdapter<FederatedEvent>({
  selectId: (event) => federatedId(event),
  sortComparer: (a, b) => moment.utc(b.post!.createdAt).unix() - moment.utc(a.post!.createdAt).unix(),
});

const initialState: EventsState = {
  pagesStatus: createFederatedPagesStatus(),
  failedEventIds: createFederated([]),
  failedInstanceIds: createFederated([]),
  eventInstancePages: createFederated({}),
  instanceEvents: createFederated({}),
  ...eventsAdapter.getInitialState(),
};

export const eventsSlice: Slice<Draft<EventsState>, any, "events"> = createSlice({
  name: "events",
  initialState: initialState,
  reducers: {
    upsertEvent: eventsAdapter.upsertOne,
    removeEvent: eventsAdapter.removeOne,
    resetEvents: () => initialState,
  },
  extraReducers: (builder) => {
    builder.addCase(createEvent.fulfilled, (state, action) => {
      const payload = federatedPayload(action);
      eventsAdapter.upsertOne(state, payload);
      console.log('created event from server', payload);
      if (publicVisibility(action.payload.post?.visibility)) {
        state.eventInstancePages[defaultEventListingType] = state.eventInstancePages[defaultEventListingType] || {};
        state.eventInstancePages[defaultEventListingType][unfilteredTime] = state.eventInstancePages[defaultEventListingType][unfilteredTime] || [];
        const firstPage = state.eventInstancePages[defaultEventListingType][unfilteredTime][0] || [];
        state.eventInstancePages[defaultEventListingType][unfilteredTime][0] = [action.payload.id, ...firstPage];
      }
    });
    builder.addCase(updateEvent.fulfilled, (state, action) => {
      const event = federatedPayload(action);
      eventsAdapter.upsertOne(state, event);
      if (event.post) {
        setTimeout(() => {
          console.log("upserting post", event.post);
          store.dispatch(locallyUpsertPost({ ...action.meta.arg, ...event.post! }));
        }, 1);
      }
      setTimeout(() => {
        store.dispatch(loadEventsPage({ page: 0, listingType: defaultEventListingType, filter: undefined }));
      }, 1);
    });
    builder.addCase(deleteEvent.fulfilled, (state, action) => {
      eventsAdapter.upsertOne(state, federatedPayload(action));
    });
    builder.addCase(loadEventsPage.pending, (state, action) => {
      setFederated(state.pagesStatus, action, "loading");
    });
    builder.addCase(loadEventsPage.fulfilled, (state, action) => {
      setFederated(state.pagesStatus, action, "loaded");
      console.log('loaded events page', action.payload.events.length);
      federatedEntities(action.payload.events, action).forEach((e) => mergeEvent(state, e));

      const instanceIds = action.payload.events.map(event => event.instances[0]!.id);
      // for (const instanceId of instanceIds) {
      //   state.instanceEvents[instanceId] = action.payload.events[0]!.id;
      // }
      const page = action.meta.arg.page || 0;
      const listingType = action.meta.arg.listingType ?? defaultEventListingType;

      const serializedFilter = serializeTimeFilter(action.meta.arg.filter);
      if (!state.eventInstancePages[listingType]) state.eventInstancePages[listingType] = {};
      if (!state.eventInstancePages[listingType]![serializedFilter] || page === 0) state.eventInstancePages[listingType]![serializedFilter] = [];
      const eventPages: string[][] = state.eventInstancePages[listingType]![serializedFilter] ?? [];
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
        state.eventInstancePages[listingType]![serializedFilter]![initialPage + (i / chunkSize)] = chunk;
      }
      if (state.eventInstancePages[listingType]![serializedFilter]![0] === undefined) {
        state.eventInstancePages[listingType]![serializedFilter]![0] = [];
      }
    });
    builder.addCase(loadEventsPage.rejected, (state, action) => {
      setFederated(state.pagesStatus, action, "errored");
    });
    const saveSingleEvent = (state: EventsState, action: PayloadAction<Event, any, any>) => {
      const event = federatedPayload(action);
      eventsAdapter.upsertOne(state, event);
      event.instances.forEach(instance => {
        state.instanceEvents[instance.id] = event.id;
      });
      if (event.post) {
        setTimeout(() => {
          // console.log("upserting event's post", event.post);
          store.dispatch(locallyUpsertPost({ ...action.meta.arg, ...event.post! }));
        }, 1);
      }
    };
    builder.addCase(loadEvent.fulfilled, saveSingleEvent);
    builder.addCase(loadEventByInstance.fulfilled, saveSingleEvent);
    builder.addCase(loadEvent.rejected, (state, action) => {
      const failedEventIds = getFederated(state.failedEventIds, action);
      setFederated(state.failedEventIds, action, [...failedEventIds, (action.meta.arg as LoadEvent).id]);
    });

    builder.addCase(loadEventByInstance.rejected, (state, action) => {
      const failedInstanceIds = getFederated(state.failedInstanceIds, action);
      setFederated(state.failedInstanceIds, action, [...failedInstanceIds, (action.meta.arg as LoadEventByInstance).instanceId]);
    });

    builder.addCase(loadUserEvents.fulfilled, (state, action) => {
      const events = federatedEntities(action.payload.events, action);
      if (!events) return;

      events.forEach((e) => mergeEvent(state, e));
      // upsertEvents(state, events);
      events.forEach((e) => mergeEvent(state, e));
    });
    builder.addCase(loadGroupEventsPage.fulfilled, (state, action) => {
      const events = federatedEntities(action.payload.events, action);
      // upsertEvents(state, events);
      events.forEach((e) => mergeEvent(state, e));
    });
  },
});

const mergeEvent = (state: EventsState, event: FederatedEvent) => {
  // console.log('merging event', event);
  const oldEvent = selectEventById(state, event.id);
  let instances = event.instances;
  for (const instance of instances) {
    state.instanceEvents[instance.id] = event.id;
    // state.instances[instance.id] = instance;
  }
  if (oldEvent) {
    instances = oldEvent.instances.filter(oi => !instances.find(ni => ni.id == oi.id)).concat(event.instances);
  }
  eventsAdapter.upsertOne(state, { ...event, instances });
};
export const { removeEvent, resetEvents } = eventsSlice.actions;
export const { selectAll: selectAllEvents, selectById: selectEventById } = eventsAdapter.getSelectors();
export const eventsReducer = eventsSlice.reducer;
export const upsertEvent = eventsAdapter.upsertOne;
export const upsertEvents = eventsAdapter.upsertMany;
export default eventsReducer;
