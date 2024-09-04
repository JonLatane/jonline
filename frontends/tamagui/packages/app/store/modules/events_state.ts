import { Event, EventInstance, EventListingType, TimeFilter } from "@jonline/api";
import {
  Dictionary,
  EntityAdapter,
  EntityId, PayloadAction,
  createEntityAdapter,
  createSlice
} from "@reduxjs/toolkit";
import { publicVisibility } from "app/utils/visibility_utils";
import moment from "moment";
import { Federated, FederatedEntity, HasServer, createFederated, federateId, federatedEntities, federatedId, federatedPayload, getFederated, parseFederatedId, setFederated } from '../federation';
import { FederatedPagesStatus, PaginatedIds, createFederatedPagesStatus, getHasEventsPage } from "../pagination";
import { store } from "../store";
import { LoadEvent, LoadEventByInstance, createEvent, defaultEventListingType, deleteEvent, loadEvent, loadEventByInstance, loadEventsPage, updateEvent } from './event_actions';
import { loadGroupEventsPage } from "./group_actions";
import { loadUserEvents } from "./user_actions";
import { resetUserEvents, resetUsers } from "./users_state";
import { toProtoISOString } from "@jonline/ui/src";
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
  // Maps Post IDs to Event IDs.
  postEvents: Dictionary<string>;
  // Maps Post IDs to EventInstance IDs.
  postInstances: Dictionary<string>;
  upcomingEventsTime: string;
  upcomingEventsTimeFilter?: TimeFilter;
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
  postEvents: {},
  postInstances: {},
  upcomingEventsTime: moment(Date.now()).toISOString(true),
  ...eventsAdapter.getInitialState(),
};

export const eventsSlice = createSlice({
  name: "events",
  initialState: initialState,
  reducers: {
    upsertEvent: eventsAdapter.upsertOne,
    removeEvent: eventsAdapter.removeOne,
    resetEvents: (state, action: PayloadAction<{ serverHost: string | undefined }>) => {
      if (!action.payload.serverHost) return;

      // const eventsIdsToRemove = state.ids
      //   .filter(id => parseFederatedId(id as string).serverHost === action.payload.serverHost);
      // eventsAdapter.removeMany(state, eventsIdsToRemove);
      // Object.keys(state.instanceEvents)
      //   .filter(id => parseFederatedId(id).serverHost === action.payload.serverHost)
      //   .forEach(id => delete state.instanceEvents[id]);
      // Object.keys(state.postEvents)
      //   .filter(id => parseFederatedId(id).serverHost === action.payload.serverHost)
      //   .forEach(id => delete state.postEvents[id]);
      // Object.keys(state.postInstances)
      //   .filter(id => parseFederatedId(id).serverHost === action.payload.serverHost)
      //   .forEach(id => delete state.postInstances[id]);
      // state.failedEventIds = state.failedEventIds.filter(id => parseFederatedId(id).serverHost !== action.payload.serverHost);
      // state.failedInstanceIds = state.failedInstanceIds.filter(id => parseFederatedId(id).serverHost !== action.payload.serverHost);
      // delete state.eventInstancePages.values[action.payload.serverHost];
      // delete state.pagesStatus.values[action.payload.serverHost];
    },
    setUpcomingEventsTimeFilter: (state, action: PayloadAction<{ timeFilter: TimeFilter }>) => {
      state.upcomingEventsTimeFilter = action.payload.timeFilter;
      // if (!state.upcomingEventsTimeFilter) {
      //   const pageLoadTime = moment(Date.now()).toISOString(true);
      //   const endsAfter = moment(pageLoadTime).subtract(1, "week").toISOString(true);
      //   const timeFilter: TimeFilter = { endsAfter: endsAfter ? toProtoISOString(endsAfter) : undefined };
      //   state.upcomingEventsTimeFilter = timeFilter;
      // }
      // return state.upcomingEventsTimeFilter;
    }
  },
  extraReducers: (builder) => {
    builder.addCase(createEvent.fulfilled, (state, action) => {
      const payload = federatedPayload(action);
      eventsAdapter.upsertOne(state, payload);
      const instanceIds = payload.instances.map(instance => federateId(instance.id, action));
      state.instanceEvents = {
        ...state.instanceEvents,
        ...Object.fromEntries(
          instanceIds.map(instanceId => [instanceId, federateId(payload.id, action)])
        )
      };

      const pagesStatus = getFederated(state.pagesStatus, action);
      if (pagesStatus === 'loaded') {
        // Append the Events to ALL pages for any/all timefilters, etc.
        // This could be better done later, maybe. Refresh page data only without the
        // rest of the EventsState maybe?
        const eventInstancePages = getFederated(state.eventInstancePages, action);
        for (const listingTypeStr of Object.keys(eventInstancePages)) {
          const listingType = parseInt(listingTypeStr) as EventListingType;
          for (const filterStr of Object.keys(eventInstancePages[listingType]!)) {
            for (const pageStr of Object.keys(eventInstancePages[listingType]![filterStr]!)) {
              eventInstancePages[listingType]![filterStr]![pageStr]!.unshift(...instanceIds);
            }
          }
        }

        setFederated(state.eventInstancePages, action, eventInstancePages);
      }
    });
    builder.addCase(updateEvent.fulfilled, (state, action) => {
      const event = federatedPayload(action);
      mergeEvent(state, event, action);
      // setTimeout(() => {
      //   store.dispatch(loadEventsPage({ page: 0, listingType: defaultEventListingType, filter: undefined }));
      // }, 1);
    });
    builder.addCase(loadEventsPage.pending, (state, action) => {
      // if (!action.meta.arg.force && getFederated(state.pagesStatus, action) === "loading") {
      //     throw 'Events already loading';
      // }
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
      const eventId = (action.meta.arg as LoadEvent).id;
      if (eventId) {
        state.failedEventIds.push(federateId((action.meta.arg as LoadEvent).id ?? '', action));
      }
    });

    builder.addCase(loadEventByInstance.rejected, (state, action) => {
      if (action.meta.arg.server) {
        state.failedInstanceIds.push(federateId((action.meta.arg as LoadEventByInstance).instanceId, action));
      }
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
    builder.addCase(deleteEvent.fulfilled, (state, action) => {
      eventsAdapter.removeOne(state, federatedId(federatedPayload(action)));
    });
  },
});

const mergeEvent = (state: EventsState, event: FederatedEvent, action: HasServer) => {
  // console.log('merging event', event);
  const federatedEventId = federateId(event.id, action);
  const oldEvent = selectEventById(state, federatedId(event));
  if (event.post) {
    state.postEvents[federateId(event.post!.id, action)] = federatedEventId;
  }
  let instances = event.instances;
  instances.forEach(instance => {
    const federatedInstanceId = federateId(instance.id, action);
    const federatedInstancePostId = federateId(instance.post!.id, action);
    state.instanceEvents[federatedInstanceId] = federatedEventId;
    state.postInstances[federatedInstancePostId] = federatedInstanceId;
  });
  if (oldEvent) {
    instances = oldEvent.instances.filter(oi => !instances.find(ni => ni.id == oi.id)).concat(event.instances);
  }
  event.instances.sort((a, b) => moment.utc(a.startsAt).unix() - moment.utc(b.startsAt).unix());
  eventsAdapter.upsertOne(state, { ...event, instances });
};

export const { removeEvent, resetEvents, setUpcomingEventsTimeFilter } = eventsSlice.actions;
export const { selectAll: selectAllEvents, selectById: selectEventById } = eventsAdapter.getSelectors();
export const eventsReducer = eventsSlice.reducer;
export const upsertEvent = eventsAdapter.upsertOne;
export const upsertEvents = eventsAdapter.upsertMany;
export default eventsReducer;
