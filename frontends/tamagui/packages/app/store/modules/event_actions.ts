import { Event, EventAttendances, EventInstance, EventListingType, GetEventAttendancesRequest, GetEventsRequest, GetEventsResponse, TimeFilter } from "@jonline/api";
import {
  AsyncThunk,
  createAsyncThunk
} from "@reduxjs/toolkit";
import { AccountOrServer, getCredentialClient } from "..";
import { HasIdFromServer } from "../federation";

// `Event`/`EventInstance` no longer carry their own surrogate `id` -- each one's identity *is* its
// own `post.id`. The Redux store's federation machinery (`FederatedEntity<T>`/`federatedId`/etc.,
// see `../federation.ts`) is generic over `T extends HasIdFromServer` (`{ id: string }`) and reads
// `.id` directly at runtime, so every `Event`/`EventInstance` gets a synthetic top-level `id`
// stamped on here, at the API boundary, copied from its own `post.id` -- once stamped, the rest of
// the store (and any code reading a `FederatedEvent`/`FederatedEventInstance` out of it) can keep
// treating `.id` as a normal field, same as any other entity (User, Post, Group, etc.).
export type IdentifiedEventInstance = EventInstance & HasIdFromServer;
export type IdentifiedEvent = Omit<Event, "instances"> & HasIdFromServer & { instances: IdentifiedEventInstance[] };
export type IdentifiedGetEventsResponse = Omit<GetEventsResponse, "events"> & { events: IdentifiedEvent[] };

export function identifyEventInstance(instance: EventInstance): IdentifiedEventInstance {
  return { ...instance, id: instance.post!.id };
}
export function identifyEvent(event: Event): IdentifiedEvent {
  return { ...event, id: event.post!.id, instances: event.instances.map(identifyEventInstance) };
}
export function identifyGetEventsResponse(response: GetEventsResponse): IdentifiedGetEventsResponse {
  return { ...response, events: response.events.map(identifyEvent) };
}

export type CreateEvent = AccountOrServer & Event;
export const createEvent: AsyncThunk<IdentifiedEvent, CreateEvent, any> = createAsyncThunk<IdentifiedEvent, CreateEvent>(
  "events/create",
  async (request) => {
    const client = await getCredentialClient(request);
    return identifyEvent(await client.createEvent(request, client.credential));
  }
);

export type UpdateEvent = AccountOrServer & Event;
export const updateEvent: AsyncThunk<IdentifiedEvent, CreateEvent, any> = createAsyncThunk<IdentifiedEvent, UpdateEvent>(
  "events/update",
  async (request) => {
    const client = await getCredentialClient(request);
    return identifyEvent(await client.updateEvent(request, client.credential));
  }
);

export type DeleteEvent = AccountOrServer & Event;
export const deleteEvent: AsyncThunk<IdentifiedEvent, CreateEvent, any> = createAsyncThunk<IdentifiedEvent, DeleteEvent>(
  "events/delete",
  async (request) => {
    const client = await getCredentialClient(request);
    return identifyEvent(await client.deleteEvent(request, client.credential));
  }
);

export type LoadEventsRequest = AccountOrServer & {
  listingType?: EventListingType,
  page?: number
  filter?: TimeFilter
  force?: boolean
};
export const defaultEventListingType = EventListingType.ALL_ACCESSIBLE_EVENTS;
export const loadEventsPage: AsyncThunk<IdentifiedGetEventsResponse, LoadEventsRequest, any> = createAsyncThunk<IdentifiedGetEventsResponse, LoadEventsRequest>(
  "events/loadPage",
  async (request) => {
    let client = await getCredentialClient(request);
    let response = await client.getEvents({
      ...request,
      listingType: request.listingType ?? defaultEventListingType,
      timeFilter: request.filter
    }, client.credential);
    // console.log('loadEventsPage', request.server?.host, response);
    return identifyGetEventsResponse(response);
  },
  // {
  //   condition: (request, { getState }) => {
  //     const state = getState() as EventsState;
  //     return request.force || getFederated(state.pagesStatus, request) !== "loading";
  //   }
  // }
);

export type LoadEvent = { id?: string, postId?: string, instanceId?: string } & AccountOrServer;
export const loadEvent: AsyncThunk<IdentifiedEvent, LoadEvent, any> = createAsyncThunk<IdentifiedEvent, LoadEvent>(
  "events/loadOne",
  async (request) => {
    const client = await getCredentialClient(request);
    // `event_id`/`event_instance_id` were removed from `GetEventsRequest` -- `post_id` is a
    // strict superset (looks up by the Event's own Post ID *or* any of its EventInstances' Post
    // ID), so any of `id`/`postId`/`instanceId` (all historically post ids under the hood) works.
    const response = await client.getEvents(GetEventsRequest.create({
      postId: request.id ?? request.postId ?? request.instanceId
    }), client.credential);
    if (response.events.length == 0) throw 'Event not found';
    const event = response.events[0]!;
    return identifyEvent(event);
  }
);

export type LoadRsvpData = GetEventAttendancesRequest & AccountOrServer;
export const loadRsvpData: AsyncThunk<EventAttendances, LoadRsvpData, any> = createAsyncThunk<EventAttendances, LoadRsvpData>(
  "events/loadRsvpData",
  async (request) => {
    const client = await getCredentialClient(request);

    const eventAttendancesResponse = await client.getEventAttendances({
      eventInstanceId: request.eventInstanceId,
      anonymousAttendeeAuthToken: request.anonymousAttendeeAuthToken
    }, client.credential);

    return eventAttendancesResponse;
  }
);
