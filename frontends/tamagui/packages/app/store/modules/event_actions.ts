import {  GetEventsRequest, GetEventsResponse, Event, EventListingType } from "@jonline/api";
import {
  AsyncThunk,
  createAsyncThunk
} from "@reduxjs/toolkit";
import { AccountOrServer } from "../types";
import { getCredentialClient } from "./accounts";

export type CreateEvent = AccountOrServer & Event;
export const createEvent: AsyncThunk<Event, CreateEvent, any> = createAsyncThunk<Event, CreateEvent>(
  "events/create",
  async (request) => {
    const client = await getCredentialClient(request);
    return await client.createEvent(request, client.credential);
  }
);

// export type ReplyToEvent = AccountOrServer & { eventIdPath: string[], content: string };
// export const replyToEvent: AsyncThunk<Event, ReplyToEvent, any> = createAsyncThunk<Event, ReplyToEvent>(
//   "events/reply",
//   async (request) => {
//     const client = await getCredentialClient(request);
//     const createEventRequest: CreateEventRequest = {
//       replyToEventId: request.eventIdPath[request.eventIdPath.length - 1],
//       content: request.content,
//     };
//     // TODO: Why doesn't the BE return the correct created date? We "estimate" it here.
//     const result = await client.createEvent(createEventRequest, client.credential);
//     return { ...result, createdAt: new Date().toISOString() }
//   }
// );

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
    return result;
  }
);

export type LoadEventPreview = Event & AccountOrServer;
export const loadEventPreview: AsyncThunk<string, LoadEventPreview, any> = createAsyncThunk<string, LoadEventPreview>(
  "events/loadPreview",
  async (request) => {
    let client = await getCredentialClient(request);
    let response = await client.getEvents(GetEventsRequest.create({ eventId: request.id }), client.credential);
    let event = response.events[0]!;
    return event.post?.previewImage
      ? URL.createObjectURL(new Blob([event.post!.previewImage!], { type: 'image/png' }))
      : '';
  }
);

export type LoadEvent = { id: string } & AccountOrServer;
export type LoadEventResult = {
  event: Event;
  preview: string;
}
export const loadEvent: AsyncThunk<LoadEventResult, LoadEvent, any> = createAsyncThunk<LoadEventResult, LoadEvent>(
  "events/loadOne",
  async (request) => {
    const client = await getCredentialClient(request);
    const response = await client.getEvents(GetEventsRequest.create({ eventId: request.id }), client.credential);
    if (response.events.length == 0) throw 'Event not found';
    const event = response.events[0]!;
    const preview = event.post?.previewImage
      ? URL.createObjectURL(new Blob([event.post!.previewImage!], { type: 'image/png' }))
      : '';
    return { event: { ...event, previewImage: undefined }, preview };
  }
);

// export type LoadEventReplies = AccountOrServer & {
//   eventIdPath: string[];
// }
// export const loadEventReplies: AsyncThunk<GetEventsResponse, LoadEventReplies, any> = createAsyncThunk<GetEventsResponse, LoadEventReplies>(
//   "events/loadReplies",
//   async (repliesRequest) => {
//     console.log("loadEventReplies:", repliesRequest)
//     const getEventsRequest = GetEventsRequest.create({
//       eventId: repliesRequest.eventIdPath.at(-1),
//       replyDepth: 2,
//     })

//     const client = await getCredentialClient(repliesRequest);
//     const replies = await client.getEvents(getEventsRequest, client.credential);
//     return replies;
//   }
// );
