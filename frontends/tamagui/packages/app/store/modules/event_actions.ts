import { Event, EventListingType, GetEventsRequest, GetEventsResponse } from "@jonline/api";
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

export type LoadEventsRequest = AccountOrServer & {
  listingType?: EventListingType,
  page?: number
};
export const defaultEventListingType = EventListingType.PUBLIC_EVENTS;
export const loadEventsPage: AsyncThunk<GetEventsResponse, LoadEventsRequest, any> = createAsyncThunk<GetEventsResponse, LoadEventsRequest>(
  "events/loadPage",
  async (request) => {
    let client = await getCredentialClient(request);
    let result = await client.getEvents({ listingType: defaultEventListingType, ...request }, client.credential);
    return {
      ...result,
      events: result.events.map(e => { return { ...e, post: { ...e.post!, previewImage: undefined } } })
    };
  }
);

export type LoadEvent = { id: string } & AccountOrServer;
export const loadEvent: AsyncThunk<Event, LoadEvent, any> = createAsyncThunk<Event, LoadEvent>(
  "events/loadOne",
  async (request) => {
    const client = await getCredentialClient(request);
    const response = await client.getEvents(GetEventsRequest.create({ eventId: request.id }), client.credential);
    if (response.events.length == 0) throw 'Event not found';
    const event = response.events[0]!;
    return event;
  }
);
