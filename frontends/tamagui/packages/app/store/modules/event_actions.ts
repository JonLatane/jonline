import { Event, EventAttendances, EventListingType, GetEventAttendancesRequest, GetEventsRequest, GetEventsResponse, TimeFilter } from "@jonline/api";
import {
  AsyncThunk,
  createAsyncThunk
} from "@reduxjs/toolkit";
import { AccountOrServer, getCredentialClient } from "..";

export type CreateEvent = AccountOrServer & Event;
export const createEvent: AsyncThunk<Event, CreateEvent, any> = createAsyncThunk<Event, CreateEvent>(
  "events/create",
  async (request) => {
    const client = await getCredentialClient(request);
    return await client.createEvent(request, client.credential);
  }
);

export type UpdateEvent = AccountOrServer & Event;
export const updateEvent: AsyncThunk<Event, CreateEvent, any> = createAsyncThunk<Event, UpdateEvent>(
  "events/update",
  async (request) => {
    const client = await getCredentialClient(request);
    return await client.updateEvent(request, client.credential);
  }
);

export type DeleteEvent = AccountOrServer & Event;
export const deleteEvent: AsyncThunk<Event, CreateEvent, any> = createAsyncThunk<Event, DeleteEvent>(
  "events/delete",
  async (request) => {
    const client = await getCredentialClient(request);
    return await client.deleteEvent(request, client.credential);
  }
);

export type LoadEventsRequest = AccountOrServer & {
  listingType?: EventListingType,
  page?: number
  filter?: TimeFilter
  force?: boolean
};
export const defaultEventListingType = EventListingType.ALL_ACCESSIBLE_EVENTS;
export const loadEventsPage: AsyncThunk<GetEventsResponse, LoadEventsRequest, any> = createAsyncThunk<GetEventsResponse, LoadEventsRequest>(
  "events/loadPage",
  async (request) => {
    let client = await getCredentialClient(request);
    let response = await client.getEvents({
      ...request,
      listingType: request.listingType ?? defaultEventListingType,
      timeFilter: request.filter
    }, client.credential);
    // console.log('loadEventsPage', request.server?.host, response);
    return response;
  },
  // {
  //   condition: (request, { getState }) => {
  //     const state = getState() as EventsState;
  //     return request.force || getFederated(state.pagesStatus, request) !== "loading";
  //   }
  // }
);

export type LoadEvent = { id?: string, postId?: string, instanceId?: string } & AccountOrServer;
export const loadEvent: AsyncThunk<Event, LoadEvent, any> = createAsyncThunk<Event, LoadEvent>(
  "events/loadOne",
  async (request) => {
    const client = await getCredentialClient(request);
    const response = await client.getEvents(GetEventsRequest.create({
      eventId: request.id,
      postId: request.postId,
      eventInstanceId: request.instanceId
    }), client.credential);
    if (response.events.length == 0) throw 'Event not found';
    const event = response.events[0]!;
    return event;
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
