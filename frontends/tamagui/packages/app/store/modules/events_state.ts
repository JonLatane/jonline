import { Event, EventInstance, TimeFilter } from "@jonline/api";
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
import { loadUserEvents } from "./user_actions";
import { Federated, FederatedEntity, HasServer, createFederated, federateId, federatedEntities, federatedId, federatedPayload, getFederated, setFederated } from '../federation';
export * from './event_actions';

export type FederatedEvent = FederatedEntity<Event>;
export type FederatedEventInstance = FederatedEntity<EventInstance>;
export interface EventsState {
  pagesStatus: FederatedPagesStatus;
  ids: EntityId[];
  entities: Dictionary<FederatedEvent>;
  // Links instance IDs to Event IDs.
  instanceEvents: Dictionary<string>;
  // instances: Dictionary<EventInstance>;
  eventInstancePages: Federated<GroupedEventInstancePages>;
  failedEventIds: string[];
  failedInstanceIds: string[];
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
  failedEventIds: [],
  failedInstanceIds: [],
  eventInstancePages: createFederated({}),
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
      // console.log('loaded events page', action.payload.events.length);
      const events = federatedEntities(action.payload.events, action);
      events.forEach((e) => mergeEvent(state, e, action));

      const instanceIds = action.payload.events.flatMap(event => event.instances.map(instance => federateId(instance.id, action)));

      const page = action.meta.arg.page || 0;
      const listingType = action.meta.arg.listingType ?? defaultEventListingType;
      const serializedFilter = serializeTimeFilter(action.meta.arg.filter);

      const serverEventPages = getFederated(state.eventInstancePages, action);
      if (!serverEventPages[listingType]) serverEventPages[listingType] = {};
      if (!serverEventPages[listingType]![serializedFilter] || page === 0) serverEventPages[listingType]![serializedFilter] = [];

      const eventPages: string[][] = serverEventPages[listingType]![serializedFilter]!;
      eventPages[page] = instanceIds;
      setFederated(state.eventInstancePages, action, serverEventPages);
    });
    builder.addCase(loadEventsPage.rejected, (state, action) => {
      setFederated(state.pagesStatus, action, "errored");
    });
    const saveSingleEvent = (state: EventsState, action: PayloadAction<Event, any, any>) => {
      const event = federatedPayload(action);
      mergeEvent(state, event, action);
    };
    builder.addCase(loadEvent.fulfilled, saveSingleEvent);
    builder.addCase(loadEventByInstance.fulfilled, saveSingleEvent);
    builder.addCase(loadEvent.rejected, (state, action) => {
      state.failedEventIds.push(federateId((action.meta.arg as LoadEvent).id, action));
    });

    builder.addCase(loadEventByInstance.rejected, (state, action) => {
      state.failedInstanceIds.push(federateId((action.meta.arg as LoadEventByInstance).instanceId, action));
    });

    builder.addCase(loadUserEvents.fulfilled, (state, action) => {
      const events = federatedEntities(action.payload.events, action);
      if (!events) return;

      events.forEach((e) => mergeEvent(state, e, action));
      // upsertEvents(state, events);
      events.forEach((e) => mergeEvent(state, e, action));
    });
    builder.addCase(loadGroupEventsPage.fulfilled, (state, action) => {
      const events = federatedEntities(action.payload.events, action);
      // upsertEvents(state, events);
      events.forEach((e) => mergeEvent(state, e, action));
    });
  },
});

const mergeEvent = (state: EventsState, event: FederatedEvent, action: HasServer) => {
  // console.log('merging event', event);
  const oldEvent = selectEventById(state, federatedId(event));
  let instances = event.instances;
  instances.forEach(instance => {
    state.instanceEvents[federateId(instance.id, action)] = federateId(event.id, action);
  });
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
