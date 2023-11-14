/* eslint-disable */
import _m0 from "protobufjs/minimal";
import { Timestamp } from "./google/protobuf/timestamp";
import { Location } from "./location";
import { Post } from "./posts";
import { Author, ContactMethod } from "./users";
import { Moderation, moderationFromJSON, moderationToJSON } from "./visibility_moderation";

export const protobufPackage = "jonline";

export enum EventListingType {
  /**
   * PUBLIC_EVENTS - Gets SERVER_PUBLIC and GLOBAL_PUBLIC events as is sensible.
   * Also usable for getting replies anywhere.
   */
  PUBLIC_EVENTS = 0,
  /** FOLLOWING_EVENTS - Returns events from users the user is following. */
  FOLLOWING_EVENTS = 1,
  /** MY_GROUPS_EVENTS - Returns events from any group the user is a member of. */
  MY_GROUPS_EVENTS = 2,
  /** DIRECT_EVENTS - Returns `DIRECT` events that are directly addressed to the user. */
  DIRECT_EVENTS = 3,
  EVENTS_PENDING_MODERATION = 4,
  /** GROUP_EVENTS - group_id parameter is required for these. */
  GROUP_EVENTS = 10,
  GROUP_EVENTS_PENDING_MODERATION = 11,
  UNRECOGNIZED = -1,
}

export function eventListingTypeFromJSON(object: any): EventListingType {
  switch (object) {
    case 0:
    case "PUBLIC_EVENTS":
      return EventListingType.PUBLIC_EVENTS;
    case 1:
    case "FOLLOWING_EVENTS":
      return EventListingType.FOLLOWING_EVENTS;
    case 2:
    case "MY_GROUPS_EVENTS":
      return EventListingType.MY_GROUPS_EVENTS;
    case 3:
    case "DIRECT_EVENTS":
      return EventListingType.DIRECT_EVENTS;
    case 4:
    case "EVENTS_PENDING_MODERATION":
      return EventListingType.EVENTS_PENDING_MODERATION;
    case 10:
    case "GROUP_EVENTS":
      return EventListingType.GROUP_EVENTS;
    case 11:
    case "GROUP_EVENTS_PENDING_MODERATION":
      return EventListingType.GROUP_EVENTS_PENDING_MODERATION;
    case -1:
    case "UNRECOGNIZED":
    default:
      return EventListingType.UNRECOGNIZED;
  }
}

export function eventListingTypeToJSON(object: EventListingType): string {
  switch (object) {
    case EventListingType.PUBLIC_EVENTS:
      return "PUBLIC_EVENTS";
    case EventListingType.FOLLOWING_EVENTS:
      return "FOLLOWING_EVENTS";
    case EventListingType.MY_GROUPS_EVENTS:
      return "MY_GROUPS_EVENTS";
    case EventListingType.DIRECT_EVENTS:
      return "DIRECT_EVENTS";
    case EventListingType.EVENTS_PENDING_MODERATION:
      return "EVENTS_PENDING_MODERATION";
    case EventListingType.GROUP_EVENTS:
      return "GROUP_EVENTS";
    case EventListingType.GROUP_EVENTS_PENDING_MODERATION:
      return "GROUP_EVENTS_PENDING_MODERATION";
    case EventListingType.UNRECOGNIZED:
    default:
      return "UNRECOGNIZED";
  }
}

/**
 * EventInstance attendance statuses. State transitions may generally happen
 * in any direction, but:
 * * `REQUESTED` can only be selected if another user invited the user whose attendance is being described.
 * * `GOING` and `NOT_GOING` cannot be selected if the EventInstance has ended (end time is in the past).
 * * `WENT` and `DID_NOT_GO` cannot be selected if the EventInstance has not started (start time is in the future).
 * `INTERESTED` and `REQUESTED` can apply regardless of whether an event has started or ended.
 */
export enum AttendanceStatus {
  /** INTERESTED - The user is (or was) interested in attending. This is the default status. */
  INTERESTED = 0,
  /** REQUESTED - Another user has invited the user to the event. */
  REQUESTED = 1,
  /** GOING - The user plans to go to the event, or went to the event. */
  GOING = 2,
  /** NOT_GOING - The user does not plan to go to the event, or did not go to the event. */
  NOT_GOING = 3,
  UNRECOGNIZED = -1,
}

export function attendanceStatusFromJSON(object: any): AttendanceStatus {
  switch (object) {
    case 0:
    case "INTERESTED":
      return AttendanceStatus.INTERESTED;
    case 1:
    case "REQUESTED":
      return AttendanceStatus.REQUESTED;
    case 2:
    case "GOING":
      return AttendanceStatus.GOING;
    case 3:
    case "NOT_GOING":
      return AttendanceStatus.NOT_GOING;
    case -1:
    case "UNRECOGNIZED":
    default:
      return AttendanceStatus.UNRECOGNIZED;
  }
}

export function attendanceStatusToJSON(object: AttendanceStatus): string {
  switch (object) {
    case AttendanceStatus.INTERESTED:
      return "INTERESTED";
    case AttendanceStatus.REQUESTED:
      return "REQUESTED";
    case AttendanceStatus.GOING:
      return "GOING";
    case AttendanceStatus.NOT_GOING:
      return "NOT_GOING";
    case AttendanceStatus.UNRECOGNIZED:
    default:
      return "UNRECOGNIZED";
  }
}

/**
 * Valid GetEventsRequest formats:
 * - {[listing_type: PublicEvents]}                  (TODO: get ServerPublic/GlobalPublic events you can see)
 * - {listing_type:MyGroupsEvents|FollowingEvents}   (TODO: get events for groups joined or user followed; auth required)
 * - {event_id:}                                     (TODO: get single event including preview data)
 * - {listing_type: GroupEvents|
 *      GroupEventsPendingModeration,
 *      group_id:}                                  (TODO: get events/events needing moderation for a group)
 * - {author_user_id:, group_id:}                   (TODO: get events by a user for a group)
 * - {listing_type: AuthorEvents, author_user_id:}  (TODO: get events by a user)
 */
export interface GetEventsRequest {
  /** Returns the single event with the given ID. */
  eventId?:
    | string
    | undefined;
  /**
   * Limits results to replies to the given event.
   * optional string replies_to_event_id = 2;
   * Limits results to those by the given author user ID.
   */
  authorUserId?: string | undefined;
  groupId?: string | undefined;
  eventInstanceId?: string | undefined;
  timeFilter?: TimeFilter | undefined;
  listingType: EventListingType;
}

/** Time filter that simply works on the starts_at and ends_at fields. */
export interface TimeFilter {
  startsAfter?: string | undefined;
  endsAfter?: string | undefined;
  startsBefore?: string | undefined;
  endsBefore?: string | undefined;
}

export interface GetEventsResponse {
  events: Event[];
}

export interface Event {
  id: string;
  post: Post | undefined;
  info: EventInfo | undefined;
  instances: EventInstance[];
}

/**
 * To be used for ticketing, RSVPs, etc.
 * Stored as JSON in the database.
 */
export interface EventInfo {
  allowsRsvps?: boolean | undefined;
  allowsAnonymousRsvps?: boolean | undefined;
}

export interface EventInstance {
  id: string;
  eventId: string;
  post?: Post | undefined;
  info: EventInstanceInfo | undefined;
  startsAt: string | undefined;
  endsAt: string | undefined;
  location?: Location | undefined;
}

/**
 * To be used for ticketing, RSVPs, etc.
 * Stored as JSON in the database.
 */
export interface EventInstanceInfo {
}

export interface GetEventAttendancesRequest {
  eventInstanceId: string;
  anonymousAttendeeAuthToken?: string | undefined;
}

export interface EventAttendances {
  attendances: EventAttendance[];
}

/**
 * Describes the attendance of a user at an `EventInstance`. Such as:
 * * A user's RSVP to an `EventInstance`.
 * * Invitation status of a user to an `EventInstance`.
 * * `ContactMethod`-driven management for anonymous RSVPs to an `EventInstance`.
 *
 * `EventAttendance.status` works like a state machine, but state transitions are governed only
 * by the current time and the start/end times of `EventInstance`s:
 * * Before an event starts, EventAttendance essentially only describes RSVPs and invitations.
 * * After an event ends, EventAttendance describes what RSVPs were before the event ended, and users can also indicate
 * they `WENT` or `DID_NOT_GO`. Invitations can no longer be created.
 * * During an event, invites, can be sent, RSVPs can be made, *and* users can indicate they `WENT` or `DID_NOT_GO`.
 */
export interface EventAttendance {
  id: string;
  eventInstanceId: string;
  userAttendee?: Author | undefined;
  anonymousAttendee?: AnonymousAttendee | undefined;
  numberOfGuests: number;
  status: AttendanceStatus;
  invitingUserId?: string | undefined;
  privateNote: string;
  publicNote: string;
  moderation: Moderation;
  createdAt: string | undefined;
  updatedAt?: string | undefined;
}

/**
 * The visibility on `AnonymousAttendee` `ContactMethod`s support the `LIMITED` visibility, which will
 * make them visible to the event creator.
 */
export interface AnonymousAttendee {
  name: string;
  /** Contact methods for anonymous attendees. Currently not linked to Contact methods for users. */
  contactMethods: ContactMethod[];
  /**
   * Used to allow anonymous users to RSVP to an event. Generated by the server
   * when an event attendance is upserted for the first time. Subsequent attendance
   * upserts, with the same event_instance_id and anonymous_attendee.auth_token,
   * will update existing anonymous attendance records.
   */
  authToken?: string | undefined;
}

function createBaseGetEventsRequest(): GetEventsRequest {
  return {
    eventId: undefined,
    authorUserId: undefined,
    groupId: undefined,
    eventInstanceId: undefined,
    timeFilter: undefined,
    listingType: 0,
  };
}

export const GetEventsRequest = {
  encode(message: GetEventsRequest, writer: _m0.Writer = _m0.Writer.create()): _m0.Writer {
    if (message.eventId !== undefined) {
      writer.uint32(10).string(message.eventId);
    }
    if (message.authorUserId !== undefined) {
      writer.uint32(18).string(message.authorUserId);
    }
    if (message.groupId !== undefined) {
      writer.uint32(26).string(message.groupId);
    }
    if (message.eventInstanceId !== undefined) {
      writer.uint32(34).string(message.eventInstanceId);
    }
    if (message.timeFilter !== undefined) {
      TimeFilter.encode(message.timeFilter, writer.uint32(42).fork()).ldelim();
    }
    if (message.listingType !== 0) {
      writer.uint32(80).int32(message.listingType);
    }
    return writer;
  },

  decode(input: _m0.Reader | Uint8Array, length?: number): GetEventsRequest {
    const reader = input instanceof _m0.Reader ? input : _m0.Reader.create(input);
    let end = length === undefined ? reader.len : reader.pos + length;
    const message = createBaseGetEventsRequest();
    while (reader.pos < end) {
      const tag = reader.uint32();
      switch (tag >>> 3) {
        case 1:
          if (tag !== 10) {
            break;
          }

          message.eventId = reader.string();
          continue;
        case 2:
          if (tag !== 18) {
            break;
          }

          message.authorUserId = reader.string();
          continue;
        case 3:
          if (tag !== 26) {
            break;
          }

          message.groupId = reader.string();
          continue;
        case 4:
          if (tag !== 34) {
            break;
          }

          message.eventInstanceId = reader.string();
          continue;
        case 5:
          if (tag !== 42) {
            break;
          }

          message.timeFilter = TimeFilter.decode(reader, reader.uint32());
          continue;
        case 10:
          if (tag !== 80) {
            break;
          }

          message.listingType = reader.int32() as any;
          continue;
      }
      if ((tag & 7) === 4 || tag === 0) {
        break;
      }
      reader.skipType(tag & 7);
    }
    return message;
  },

  fromJSON(object: any): GetEventsRequest {
    return {
      eventId: isSet(object.eventId) ? globalThis.String(object.eventId) : undefined,
      authorUserId: isSet(object.authorUserId) ? globalThis.String(object.authorUserId) : undefined,
      groupId: isSet(object.groupId) ? globalThis.String(object.groupId) : undefined,
      eventInstanceId: isSet(object.eventInstanceId) ? globalThis.String(object.eventInstanceId) : undefined,
      timeFilter: isSet(object.timeFilter) ? TimeFilter.fromJSON(object.timeFilter) : undefined,
      listingType: isSet(object.listingType) ? eventListingTypeFromJSON(object.listingType) : 0,
    };
  },

  toJSON(message: GetEventsRequest): unknown {
    const obj: any = {};
    if (message.eventId !== undefined) {
      obj.eventId = message.eventId;
    }
    if (message.authorUserId !== undefined) {
      obj.authorUserId = message.authorUserId;
    }
    if (message.groupId !== undefined) {
      obj.groupId = message.groupId;
    }
    if (message.eventInstanceId !== undefined) {
      obj.eventInstanceId = message.eventInstanceId;
    }
    if (message.timeFilter !== undefined) {
      obj.timeFilter = TimeFilter.toJSON(message.timeFilter);
    }
    if (message.listingType !== 0) {
      obj.listingType = eventListingTypeToJSON(message.listingType);
    }
    return obj;
  },

  create<I extends Exact<DeepPartial<GetEventsRequest>, I>>(base?: I): GetEventsRequest {
    return GetEventsRequest.fromPartial(base ?? ({} as any));
  },
  fromPartial<I extends Exact<DeepPartial<GetEventsRequest>, I>>(object: I): GetEventsRequest {
    const message = createBaseGetEventsRequest();
    message.eventId = object.eventId ?? undefined;
    message.authorUserId = object.authorUserId ?? undefined;
    message.groupId = object.groupId ?? undefined;
    message.eventInstanceId = object.eventInstanceId ?? undefined;
    message.timeFilter = (object.timeFilter !== undefined && object.timeFilter !== null)
      ? TimeFilter.fromPartial(object.timeFilter)
      : undefined;
    message.listingType = object.listingType ?? 0;
    return message;
  },
};

function createBaseTimeFilter(): TimeFilter {
  return { startsAfter: undefined, endsAfter: undefined, startsBefore: undefined, endsBefore: undefined };
}

export const TimeFilter = {
  encode(message: TimeFilter, writer: _m0.Writer = _m0.Writer.create()): _m0.Writer {
    if (message.startsAfter !== undefined) {
      Timestamp.encode(toTimestamp(message.startsAfter), writer.uint32(10).fork()).ldelim();
    }
    if (message.endsAfter !== undefined) {
      Timestamp.encode(toTimestamp(message.endsAfter), writer.uint32(18).fork()).ldelim();
    }
    if (message.startsBefore !== undefined) {
      Timestamp.encode(toTimestamp(message.startsBefore), writer.uint32(26).fork()).ldelim();
    }
    if (message.endsBefore !== undefined) {
      Timestamp.encode(toTimestamp(message.endsBefore), writer.uint32(34).fork()).ldelim();
    }
    return writer;
  },

  decode(input: _m0.Reader | Uint8Array, length?: number): TimeFilter {
    const reader = input instanceof _m0.Reader ? input : _m0.Reader.create(input);
    let end = length === undefined ? reader.len : reader.pos + length;
    const message = createBaseTimeFilter();
    while (reader.pos < end) {
      const tag = reader.uint32();
      switch (tag >>> 3) {
        case 1:
          if (tag !== 10) {
            break;
          }

          message.startsAfter = fromTimestamp(Timestamp.decode(reader, reader.uint32()));
          continue;
        case 2:
          if (tag !== 18) {
            break;
          }

          message.endsAfter = fromTimestamp(Timestamp.decode(reader, reader.uint32()));
          continue;
        case 3:
          if (tag !== 26) {
            break;
          }

          message.startsBefore = fromTimestamp(Timestamp.decode(reader, reader.uint32()));
          continue;
        case 4:
          if (tag !== 34) {
            break;
          }

          message.endsBefore = fromTimestamp(Timestamp.decode(reader, reader.uint32()));
          continue;
      }
      if ((tag & 7) === 4 || tag === 0) {
        break;
      }
      reader.skipType(tag & 7);
    }
    return message;
  },

  fromJSON(object: any): TimeFilter {
    return {
      startsAfter: isSet(object.startsAfter) ? globalThis.String(object.startsAfter) : undefined,
      endsAfter: isSet(object.endsAfter) ? globalThis.String(object.endsAfter) : undefined,
      startsBefore: isSet(object.startsBefore) ? globalThis.String(object.startsBefore) : undefined,
      endsBefore: isSet(object.endsBefore) ? globalThis.String(object.endsBefore) : undefined,
    };
  },

  toJSON(message: TimeFilter): unknown {
    const obj: any = {};
    if (message.startsAfter !== undefined) {
      obj.startsAfter = message.startsAfter;
    }
    if (message.endsAfter !== undefined) {
      obj.endsAfter = message.endsAfter;
    }
    if (message.startsBefore !== undefined) {
      obj.startsBefore = message.startsBefore;
    }
    if (message.endsBefore !== undefined) {
      obj.endsBefore = message.endsBefore;
    }
    return obj;
  },

  create<I extends Exact<DeepPartial<TimeFilter>, I>>(base?: I): TimeFilter {
    return TimeFilter.fromPartial(base ?? ({} as any));
  },
  fromPartial<I extends Exact<DeepPartial<TimeFilter>, I>>(object: I): TimeFilter {
    const message = createBaseTimeFilter();
    message.startsAfter = object.startsAfter ?? undefined;
    message.endsAfter = object.endsAfter ?? undefined;
    message.startsBefore = object.startsBefore ?? undefined;
    message.endsBefore = object.endsBefore ?? undefined;
    return message;
  },
};

function createBaseGetEventsResponse(): GetEventsResponse {
  return { events: [] };
}

export const GetEventsResponse = {
  encode(message: GetEventsResponse, writer: _m0.Writer = _m0.Writer.create()): _m0.Writer {
    for (const v of message.events) {
      Event.encode(v!, writer.uint32(10).fork()).ldelim();
    }
    return writer;
  },

  decode(input: _m0.Reader | Uint8Array, length?: number): GetEventsResponse {
    const reader = input instanceof _m0.Reader ? input : _m0.Reader.create(input);
    let end = length === undefined ? reader.len : reader.pos + length;
    const message = createBaseGetEventsResponse();
    while (reader.pos < end) {
      const tag = reader.uint32();
      switch (tag >>> 3) {
        case 1:
          if (tag !== 10) {
            break;
          }

          message.events.push(Event.decode(reader, reader.uint32()));
          continue;
      }
      if ((tag & 7) === 4 || tag === 0) {
        break;
      }
      reader.skipType(tag & 7);
    }
    return message;
  },

  fromJSON(object: any): GetEventsResponse {
    return { events: globalThis.Array.isArray(object?.events) ? object.events.map((e: any) => Event.fromJSON(e)) : [] };
  },

  toJSON(message: GetEventsResponse): unknown {
    const obj: any = {};
    if (message.events?.length) {
      obj.events = message.events.map((e) => Event.toJSON(e));
    }
    return obj;
  },

  create<I extends Exact<DeepPartial<GetEventsResponse>, I>>(base?: I): GetEventsResponse {
    return GetEventsResponse.fromPartial(base ?? ({} as any));
  },
  fromPartial<I extends Exact<DeepPartial<GetEventsResponse>, I>>(object: I): GetEventsResponse {
    const message = createBaseGetEventsResponse();
    message.events = object.events?.map((e) => Event.fromPartial(e)) || [];
    return message;
  },
};

function createBaseEvent(): Event {
  return { id: "", post: undefined, info: undefined, instances: [] };
}

export const Event = {
  encode(message: Event, writer: _m0.Writer = _m0.Writer.create()): _m0.Writer {
    if (message.id !== "") {
      writer.uint32(10).string(message.id);
    }
    if (message.post !== undefined) {
      Post.encode(message.post, writer.uint32(18).fork()).ldelim();
    }
    if (message.info !== undefined) {
      EventInfo.encode(message.info, writer.uint32(26).fork()).ldelim();
    }
    for (const v of message.instances) {
      EventInstance.encode(v!, writer.uint32(34).fork()).ldelim();
    }
    return writer;
  },

  decode(input: _m0.Reader | Uint8Array, length?: number): Event {
    const reader = input instanceof _m0.Reader ? input : _m0.Reader.create(input);
    let end = length === undefined ? reader.len : reader.pos + length;
    const message = createBaseEvent();
    while (reader.pos < end) {
      const tag = reader.uint32();
      switch (tag >>> 3) {
        case 1:
          if (tag !== 10) {
            break;
          }

          message.id = reader.string();
          continue;
        case 2:
          if (tag !== 18) {
            break;
          }

          message.post = Post.decode(reader, reader.uint32());
          continue;
        case 3:
          if (tag !== 26) {
            break;
          }

          message.info = EventInfo.decode(reader, reader.uint32());
          continue;
        case 4:
          if (tag !== 34) {
            break;
          }

          message.instances.push(EventInstance.decode(reader, reader.uint32()));
          continue;
      }
      if ((tag & 7) === 4 || tag === 0) {
        break;
      }
      reader.skipType(tag & 7);
    }
    return message;
  },

  fromJSON(object: any): Event {
    return {
      id: isSet(object.id) ? globalThis.String(object.id) : "",
      post: isSet(object.post) ? Post.fromJSON(object.post) : undefined,
      info: isSet(object.info) ? EventInfo.fromJSON(object.info) : undefined,
      instances: globalThis.Array.isArray(object?.instances)
        ? object.instances.map((e: any) => EventInstance.fromJSON(e))
        : [],
    };
  },

  toJSON(message: Event): unknown {
    const obj: any = {};
    if (message.id !== "") {
      obj.id = message.id;
    }
    if (message.post !== undefined) {
      obj.post = Post.toJSON(message.post);
    }
    if (message.info !== undefined) {
      obj.info = EventInfo.toJSON(message.info);
    }
    if (message.instances?.length) {
      obj.instances = message.instances.map((e) => EventInstance.toJSON(e));
    }
    return obj;
  },

  create<I extends Exact<DeepPartial<Event>, I>>(base?: I): Event {
    return Event.fromPartial(base ?? ({} as any));
  },
  fromPartial<I extends Exact<DeepPartial<Event>, I>>(object: I): Event {
    const message = createBaseEvent();
    message.id = object.id ?? "";
    message.post = (object.post !== undefined && object.post !== null) ? Post.fromPartial(object.post) : undefined;
    message.info = (object.info !== undefined && object.info !== null) ? EventInfo.fromPartial(object.info) : undefined;
    message.instances = object.instances?.map((e) => EventInstance.fromPartial(e)) || [];
    return message;
  },
};

function createBaseEventInfo(): EventInfo {
  return { allowsRsvps: undefined, allowsAnonymousRsvps: undefined };
}

export const EventInfo = {
  encode(message: EventInfo, writer: _m0.Writer = _m0.Writer.create()): _m0.Writer {
    if (message.allowsRsvps !== undefined) {
      writer.uint32(8).bool(message.allowsRsvps);
    }
    if (message.allowsAnonymousRsvps !== undefined) {
      writer.uint32(16).bool(message.allowsAnonymousRsvps);
    }
    return writer;
  },

  decode(input: _m0.Reader | Uint8Array, length?: number): EventInfo {
    const reader = input instanceof _m0.Reader ? input : _m0.Reader.create(input);
    let end = length === undefined ? reader.len : reader.pos + length;
    const message = createBaseEventInfo();
    while (reader.pos < end) {
      const tag = reader.uint32();
      switch (tag >>> 3) {
        case 1:
          if (tag !== 8) {
            break;
          }

          message.allowsRsvps = reader.bool();
          continue;
        case 2:
          if (tag !== 16) {
            break;
          }

          message.allowsAnonymousRsvps = reader.bool();
          continue;
      }
      if ((tag & 7) === 4 || tag === 0) {
        break;
      }
      reader.skipType(tag & 7);
    }
    return message;
  },

  fromJSON(object: any): EventInfo {
    return {
      allowsRsvps: isSet(object.allowsRsvps) ? globalThis.Boolean(object.allowsRsvps) : undefined,
      allowsAnonymousRsvps: isSet(object.allowsAnonymousRsvps)
        ? globalThis.Boolean(object.allowsAnonymousRsvps)
        : undefined,
    };
  },

  toJSON(message: EventInfo): unknown {
    const obj: any = {};
    if (message.allowsRsvps !== undefined) {
      obj.allowsRsvps = message.allowsRsvps;
    }
    if (message.allowsAnonymousRsvps !== undefined) {
      obj.allowsAnonymousRsvps = message.allowsAnonymousRsvps;
    }
    return obj;
  },

  create<I extends Exact<DeepPartial<EventInfo>, I>>(base?: I): EventInfo {
    return EventInfo.fromPartial(base ?? ({} as any));
  },
  fromPartial<I extends Exact<DeepPartial<EventInfo>, I>>(object: I): EventInfo {
    const message = createBaseEventInfo();
    message.allowsRsvps = object.allowsRsvps ?? undefined;
    message.allowsAnonymousRsvps = object.allowsAnonymousRsvps ?? undefined;
    return message;
  },
};

function createBaseEventInstance(): EventInstance {
  return {
    id: "",
    eventId: "",
    post: undefined,
    info: undefined,
    startsAt: undefined,
    endsAt: undefined,
    location: undefined,
  };
}

export const EventInstance = {
  encode(message: EventInstance, writer: _m0.Writer = _m0.Writer.create()): _m0.Writer {
    if (message.id !== "") {
      writer.uint32(10).string(message.id);
    }
    if (message.eventId !== "") {
      writer.uint32(18).string(message.eventId);
    }
    if (message.post !== undefined) {
      Post.encode(message.post, writer.uint32(26).fork()).ldelim();
    }
    if (message.info !== undefined) {
      EventInstanceInfo.encode(message.info, writer.uint32(34).fork()).ldelim();
    }
    if (message.startsAt !== undefined) {
      Timestamp.encode(toTimestamp(message.startsAt), writer.uint32(42).fork()).ldelim();
    }
    if (message.endsAt !== undefined) {
      Timestamp.encode(toTimestamp(message.endsAt), writer.uint32(50).fork()).ldelim();
    }
    if (message.location !== undefined) {
      Location.encode(message.location, writer.uint32(58).fork()).ldelim();
    }
    return writer;
  },

  decode(input: _m0.Reader | Uint8Array, length?: number): EventInstance {
    const reader = input instanceof _m0.Reader ? input : _m0.Reader.create(input);
    let end = length === undefined ? reader.len : reader.pos + length;
    const message = createBaseEventInstance();
    while (reader.pos < end) {
      const tag = reader.uint32();
      switch (tag >>> 3) {
        case 1:
          if (tag !== 10) {
            break;
          }

          message.id = reader.string();
          continue;
        case 2:
          if (tag !== 18) {
            break;
          }

          message.eventId = reader.string();
          continue;
        case 3:
          if (tag !== 26) {
            break;
          }

          message.post = Post.decode(reader, reader.uint32());
          continue;
        case 4:
          if (tag !== 34) {
            break;
          }

          message.info = EventInstanceInfo.decode(reader, reader.uint32());
          continue;
        case 5:
          if (tag !== 42) {
            break;
          }

          message.startsAt = fromTimestamp(Timestamp.decode(reader, reader.uint32()));
          continue;
        case 6:
          if (tag !== 50) {
            break;
          }

          message.endsAt = fromTimestamp(Timestamp.decode(reader, reader.uint32()));
          continue;
        case 7:
          if (tag !== 58) {
            break;
          }

          message.location = Location.decode(reader, reader.uint32());
          continue;
      }
      if ((tag & 7) === 4 || tag === 0) {
        break;
      }
      reader.skipType(tag & 7);
    }
    return message;
  },

  fromJSON(object: any): EventInstance {
    return {
      id: isSet(object.id) ? globalThis.String(object.id) : "",
      eventId: isSet(object.eventId) ? globalThis.String(object.eventId) : "",
      post: isSet(object.post) ? Post.fromJSON(object.post) : undefined,
      info: isSet(object.info) ? EventInstanceInfo.fromJSON(object.info) : undefined,
      startsAt: isSet(object.startsAt) ? globalThis.String(object.startsAt) : undefined,
      endsAt: isSet(object.endsAt) ? globalThis.String(object.endsAt) : undefined,
      location: isSet(object.location) ? Location.fromJSON(object.location) : undefined,
    };
  },

  toJSON(message: EventInstance): unknown {
    const obj: any = {};
    if (message.id !== "") {
      obj.id = message.id;
    }
    if (message.eventId !== "") {
      obj.eventId = message.eventId;
    }
    if (message.post !== undefined) {
      obj.post = Post.toJSON(message.post);
    }
    if (message.info !== undefined) {
      obj.info = EventInstanceInfo.toJSON(message.info);
    }
    if (message.startsAt !== undefined) {
      obj.startsAt = message.startsAt;
    }
    if (message.endsAt !== undefined) {
      obj.endsAt = message.endsAt;
    }
    if (message.location !== undefined) {
      obj.location = Location.toJSON(message.location);
    }
    return obj;
  },

  create<I extends Exact<DeepPartial<EventInstance>, I>>(base?: I): EventInstance {
    return EventInstance.fromPartial(base ?? ({} as any));
  },
  fromPartial<I extends Exact<DeepPartial<EventInstance>, I>>(object: I): EventInstance {
    const message = createBaseEventInstance();
    message.id = object.id ?? "";
    message.eventId = object.eventId ?? "";
    message.post = (object.post !== undefined && object.post !== null) ? Post.fromPartial(object.post) : undefined;
    message.info = (object.info !== undefined && object.info !== null)
      ? EventInstanceInfo.fromPartial(object.info)
      : undefined;
    message.startsAt = object.startsAt ?? undefined;
    message.endsAt = object.endsAt ?? undefined;
    message.location = (object.location !== undefined && object.location !== null)
      ? Location.fromPartial(object.location)
      : undefined;
    return message;
  },
};

function createBaseEventInstanceInfo(): EventInstanceInfo {
  return {};
}

export const EventInstanceInfo = {
  encode(_: EventInstanceInfo, writer: _m0.Writer = _m0.Writer.create()): _m0.Writer {
    return writer;
  },

  decode(input: _m0.Reader | Uint8Array, length?: number): EventInstanceInfo {
    const reader = input instanceof _m0.Reader ? input : _m0.Reader.create(input);
    let end = length === undefined ? reader.len : reader.pos + length;
    const message = createBaseEventInstanceInfo();
    while (reader.pos < end) {
      const tag = reader.uint32();
      switch (tag >>> 3) {
      }
      if ((tag & 7) === 4 || tag === 0) {
        break;
      }
      reader.skipType(tag & 7);
    }
    return message;
  },

  fromJSON(_: any): EventInstanceInfo {
    return {};
  },

  toJSON(_: EventInstanceInfo): unknown {
    const obj: any = {};
    return obj;
  },

  create<I extends Exact<DeepPartial<EventInstanceInfo>, I>>(base?: I): EventInstanceInfo {
    return EventInstanceInfo.fromPartial(base ?? ({} as any));
  },
  fromPartial<I extends Exact<DeepPartial<EventInstanceInfo>, I>>(_: I): EventInstanceInfo {
    const message = createBaseEventInstanceInfo();
    return message;
  },
};

function createBaseGetEventAttendancesRequest(): GetEventAttendancesRequest {
  return { eventInstanceId: "", anonymousAttendeeAuthToken: undefined };
}

export const GetEventAttendancesRequest = {
  encode(message: GetEventAttendancesRequest, writer: _m0.Writer = _m0.Writer.create()): _m0.Writer {
    if (message.eventInstanceId !== "") {
      writer.uint32(10).string(message.eventInstanceId);
    }
    if (message.anonymousAttendeeAuthToken !== undefined) {
      writer.uint32(18).string(message.anonymousAttendeeAuthToken);
    }
    return writer;
  },

  decode(input: _m0.Reader | Uint8Array, length?: number): GetEventAttendancesRequest {
    const reader = input instanceof _m0.Reader ? input : _m0.Reader.create(input);
    let end = length === undefined ? reader.len : reader.pos + length;
    const message = createBaseGetEventAttendancesRequest();
    while (reader.pos < end) {
      const tag = reader.uint32();
      switch (tag >>> 3) {
        case 1:
          if (tag !== 10) {
            break;
          }

          message.eventInstanceId = reader.string();
          continue;
        case 2:
          if (tag !== 18) {
            break;
          }

          message.anonymousAttendeeAuthToken = reader.string();
          continue;
      }
      if ((tag & 7) === 4 || tag === 0) {
        break;
      }
      reader.skipType(tag & 7);
    }
    return message;
  },

  fromJSON(object: any): GetEventAttendancesRequest {
    return {
      eventInstanceId: isSet(object.eventInstanceId) ? globalThis.String(object.eventInstanceId) : "",
      anonymousAttendeeAuthToken: isSet(object.anonymousAttendeeAuthToken)
        ? globalThis.String(object.anonymousAttendeeAuthToken)
        : undefined,
    };
  },

  toJSON(message: GetEventAttendancesRequest): unknown {
    const obj: any = {};
    if (message.eventInstanceId !== "") {
      obj.eventInstanceId = message.eventInstanceId;
    }
    if (message.anonymousAttendeeAuthToken !== undefined) {
      obj.anonymousAttendeeAuthToken = message.anonymousAttendeeAuthToken;
    }
    return obj;
  },

  create<I extends Exact<DeepPartial<GetEventAttendancesRequest>, I>>(base?: I): GetEventAttendancesRequest {
    return GetEventAttendancesRequest.fromPartial(base ?? ({} as any));
  },
  fromPartial<I extends Exact<DeepPartial<GetEventAttendancesRequest>, I>>(object: I): GetEventAttendancesRequest {
    const message = createBaseGetEventAttendancesRequest();
    message.eventInstanceId = object.eventInstanceId ?? "";
    message.anonymousAttendeeAuthToken = object.anonymousAttendeeAuthToken ?? undefined;
    return message;
  },
};

function createBaseEventAttendances(): EventAttendances {
  return { attendances: [] };
}

export const EventAttendances = {
  encode(message: EventAttendances, writer: _m0.Writer = _m0.Writer.create()): _m0.Writer {
    for (const v of message.attendances) {
      EventAttendance.encode(v!, writer.uint32(10).fork()).ldelim();
    }
    return writer;
  },

  decode(input: _m0.Reader | Uint8Array, length?: number): EventAttendances {
    const reader = input instanceof _m0.Reader ? input : _m0.Reader.create(input);
    let end = length === undefined ? reader.len : reader.pos + length;
    const message = createBaseEventAttendances();
    while (reader.pos < end) {
      const tag = reader.uint32();
      switch (tag >>> 3) {
        case 1:
          if (tag !== 10) {
            break;
          }

          message.attendances.push(EventAttendance.decode(reader, reader.uint32()));
          continue;
      }
      if ((tag & 7) === 4 || tag === 0) {
        break;
      }
      reader.skipType(tag & 7);
    }
    return message;
  },

  fromJSON(object: any): EventAttendances {
    return {
      attendances: globalThis.Array.isArray(object?.attendances)
        ? object.attendances.map((e: any) => EventAttendance.fromJSON(e))
        : [],
    };
  },

  toJSON(message: EventAttendances): unknown {
    const obj: any = {};
    if (message.attendances?.length) {
      obj.attendances = message.attendances.map((e) => EventAttendance.toJSON(e));
    }
    return obj;
  },

  create<I extends Exact<DeepPartial<EventAttendances>, I>>(base?: I): EventAttendances {
    return EventAttendances.fromPartial(base ?? ({} as any));
  },
  fromPartial<I extends Exact<DeepPartial<EventAttendances>, I>>(object: I): EventAttendances {
    const message = createBaseEventAttendances();
    message.attendances = object.attendances?.map((e) => EventAttendance.fromPartial(e)) || [];
    return message;
  },
};

function createBaseEventAttendance(): EventAttendance {
  return {
    id: "",
    eventInstanceId: "",
    userAttendee: undefined,
    anonymousAttendee: undefined,
    numberOfGuests: 0,
    status: 0,
    invitingUserId: undefined,
    privateNote: "",
    publicNote: "",
    moderation: 0,
    createdAt: undefined,
    updatedAt: undefined,
  };
}

export const EventAttendance = {
  encode(message: EventAttendance, writer: _m0.Writer = _m0.Writer.create()): _m0.Writer {
    if (message.id !== "") {
      writer.uint32(10).string(message.id);
    }
    if (message.eventInstanceId !== "") {
      writer.uint32(18).string(message.eventInstanceId);
    }
    if (message.userAttendee !== undefined) {
      Author.encode(message.userAttendee, writer.uint32(26).fork()).ldelim();
    }
    if (message.anonymousAttendee !== undefined) {
      AnonymousAttendee.encode(message.anonymousAttendee, writer.uint32(34).fork()).ldelim();
    }
    if (message.numberOfGuests !== 0) {
      writer.uint32(40).uint32(message.numberOfGuests);
    }
    if (message.status !== 0) {
      writer.uint32(48).int32(message.status);
    }
    if (message.invitingUserId !== undefined) {
      writer.uint32(58).string(message.invitingUserId);
    }
    if (message.privateNote !== "") {
      writer.uint32(66).string(message.privateNote);
    }
    if (message.publicNote !== "") {
      writer.uint32(74).string(message.publicNote);
    }
    if (message.moderation !== 0) {
      writer.uint32(80).int32(message.moderation);
    }
    if (message.createdAt !== undefined) {
      Timestamp.encode(toTimestamp(message.createdAt), writer.uint32(90).fork()).ldelim();
    }
    if (message.updatedAt !== undefined) {
      Timestamp.encode(toTimestamp(message.updatedAt), writer.uint32(98).fork()).ldelim();
    }
    return writer;
  },

  decode(input: _m0.Reader | Uint8Array, length?: number): EventAttendance {
    const reader = input instanceof _m0.Reader ? input : _m0.Reader.create(input);
    let end = length === undefined ? reader.len : reader.pos + length;
    const message = createBaseEventAttendance();
    while (reader.pos < end) {
      const tag = reader.uint32();
      switch (tag >>> 3) {
        case 1:
          if (tag !== 10) {
            break;
          }

          message.id = reader.string();
          continue;
        case 2:
          if (tag !== 18) {
            break;
          }

          message.eventInstanceId = reader.string();
          continue;
        case 3:
          if (tag !== 26) {
            break;
          }

          message.userAttendee = Author.decode(reader, reader.uint32());
          continue;
        case 4:
          if (tag !== 34) {
            break;
          }

          message.anonymousAttendee = AnonymousAttendee.decode(reader, reader.uint32());
          continue;
        case 5:
          if (tag !== 40) {
            break;
          }

          message.numberOfGuests = reader.uint32();
          continue;
        case 6:
          if (tag !== 48) {
            break;
          }

          message.status = reader.int32() as any;
          continue;
        case 7:
          if (tag !== 58) {
            break;
          }

          message.invitingUserId = reader.string();
          continue;
        case 8:
          if (tag !== 66) {
            break;
          }

          message.privateNote = reader.string();
          continue;
        case 9:
          if (tag !== 74) {
            break;
          }

          message.publicNote = reader.string();
          continue;
        case 10:
          if (tag !== 80) {
            break;
          }

          message.moderation = reader.int32() as any;
          continue;
        case 11:
          if (tag !== 90) {
            break;
          }

          message.createdAt = fromTimestamp(Timestamp.decode(reader, reader.uint32()));
          continue;
        case 12:
          if (tag !== 98) {
            break;
          }

          message.updatedAt = fromTimestamp(Timestamp.decode(reader, reader.uint32()));
          continue;
      }
      if ((tag & 7) === 4 || tag === 0) {
        break;
      }
      reader.skipType(tag & 7);
    }
    return message;
  },

  fromJSON(object: any): EventAttendance {
    return {
      id: isSet(object.id) ? globalThis.String(object.id) : "",
      eventInstanceId: isSet(object.eventInstanceId) ? globalThis.String(object.eventInstanceId) : "",
      userAttendee: isSet(object.userAttendee) ? Author.fromJSON(object.userAttendee) : undefined,
      anonymousAttendee: isSet(object.anonymousAttendee)
        ? AnonymousAttendee.fromJSON(object.anonymousAttendee)
        : undefined,
      numberOfGuests: isSet(object.numberOfGuests) ? globalThis.Number(object.numberOfGuests) : 0,
      status: isSet(object.status) ? attendanceStatusFromJSON(object.status) : 0,
      invitingUserId: isSet(object.invitingUserId) ? globalThis.String(object.invitingUserId) : undefined,
      privateNote: isSet(object.privateNote) ? globalThis.String(object.privateNote) : "",
      publicNote: isSet(object.publicNote) ? globalThis.String(object.publicNote) : "",
      moderation: isSet(object.moderation) ? moderationFromJSON(object.moderation) : 0,
      createdAt: isSet(object.createdAt) ? globalThis.String(object.createdAt) : undefined,
      updatedAt: isSet(object.updatedAt) ? globalThis.String(object.updatedAt) : undefined,
    };
  },

  toJSON(message: EventAttendance): unknown {
    const obj: any = {};
    if (message.id !== "") {
      obj.id = message.id;
    }
    if (message.eventInstanceId !== "") {
      obj.eventInstanceId = message.eventInstanceId;
    }
    if (message.userAttendee !== undefined) {
      obj.userAttendee = Author.toJSON(message.userAttendee);
    }
    if (message.anonymousAttendee !== undefined) {
      obj.anonymousAttendee = AnonymousAttendee.toJSON(message.anonymousAttendee);
    }
    if (message.numberOfGuests !== 0) {
      obj.numberOfGuests = Math.round(message.numberOfGuests);
    }
    if (message.status !== 0) {
      obj.status = attendanceStatusToJSON(message.status);
    }
    if (message.invitingUserId !== undefined) {
      obj.invitingUserId = message.invitingUserId;
    }
    if (message.privateNote !== "") {
      obj.privateNote = message.privateNote;
    }
    if (message.publicNote !== "") {
      obj.publicNote = message.publicNote;
    }
    if (message.moderation !== 0) {
      obj.moderation = moderationToJSON(message.moderation);
    }
    if (message.createdAt !== undefined) {
      obj.createdAt = message.createdAt;
    }
    if (message.updatedAt !== undefined) {
      obj.updatedAt = message.updatedAt;
    }
    return obj;
  },

  create<I extends Exact<DeepPartial<EventAttendance>, I>>(base?: I): EventAttendance {
    return EventAttendance.fromPartial(base ?? ({} as any));
  },
  fromPartial<I extends Exact<DeepPartial<EventAttendance>, I>>(object: I): EventAttendance {
    const message = createBaseEventAttendance();
    message.id = object.id ?? "";
    message.eventInstanceId = object.eventInstanceId ?? "";
    message.userAttendee = (object.userAttendee !== undefined && object.userAttendee !== null)
      ? Author.fromPartial(object.userAttendee)
      : undefined;
    message.anonymousAttendee = (object.anonymousAttendee !== undefined && object.anonymousAttendee !== null)
      ? AnonymousAttendee.fromPartial(object.anonymousAttendee)
      : undefined;
    message.numberOfGuests = object.numberOfGuests ?? 0;
    message.status = object.status ?? 0;
    message.invitingUserId = object.invitingUserId ?? undefined;
    message.privateNote = object.privateNote ?? "";
    message.publicNote = object.publicNote ?? "";
    message.moderation = object.moderation ?? 0;
    message.createdAt = object.createdAt ?? undefined;
    message.updatedAt = object.updatedAt ?? undefined;
    return message;
  },
};

function createBaseAnonymousAttendee(): AnonymousAttendee {
  return { name: "", contactMethods: [], authToken: undefined };
}

export const AnonymousAttendee = {
  encode(message: AnonymousAttendee, writer: _m0.Writer = _m0.Writer.create()): _m0.Writer {
    if (message.name !== "") {
      writer.uint32(10).string(message.name);
    }
    for (const v of message.contactMethods) {
      ContactMethod.encode(v!, writer.uint32(18).fork()).ldelim();
    }
    if (message.authToken !== undefined) {
      writer.uint32(26).string(message.authToken);
    }
    return writer;
  },

  decode(input: _m0.Reader | Uint8Array, length?: number): AnonymousAttendee {
    const reader = input instanceof _m0.Reader ? input : _m0.Reader.create(input);
    let end = length === undefined ? reader.len : reader.pos + length;
    const message = createBaseAnonymousAttendee();
    while (reader.pos < end) {
      const tag = reader.uint32();
      switch (tag >>> 3) {
        case 1:
          if (tag !== 10) {
            break;
          }

          message.name = reader.string();
          continue;
        case 2:
          if (tag !== 18) {
            break;
          }

          message.contactMethods.push(ContactMethod.decode(reader, reader.uint32()));
          continue;
        case 3:
          if (tag !== 26) {
            break;
          }

          message.authToken = reader.string();
          continue;
      }
      if ((tag & 7) === 4 || tag === 0) {
        break;
      }
      reader.skipType(tag & 7);
    }
    return message;
  },

  fromJSON(object: any): AnonymousAttendee {
    return {
      name: isSet(object.name) ? globalThis.String(object.name) : "",
      contactMethods: globalThis.Array.isArray(object?.contactMethods)
        ? object.contactMethods.map((e: any) => ContactMethod.fromJSON(e))
        : [],
      authToken: isSet(object.authToken) ? globalThis.String(object.authToken) : undefined,
    };
  },

  toJSON(message: AnonymousAttendee): unknown {
    const obj: any = {};
    if (message.name !== "") {
      obj.name = message.name;
    }
    if (message.contactMethods?.length) {
      obj.contactMethods = message.contactMethods.map((e) => ContactMethod.toJSON(e));
    }
    if (message.authToken !== undefined) {
      obj.authToken = message.authToken;
    }
    return obj;
  },

  create<I extends Exact<DeepPartial<AnonymousAttendee>, I>>(base?: I): AnonymousAttendee {
    return AnonymousAttendee.fromPartial(base ?? ({} as any));
  },
  fromPartial<I extends Exact<DeepPartial<AnonymousAttendee>, I>>(object: I): AnonymousAttendee {
    const message = createBaseAnonymousAttendee();
    message.name = object.name ?? "";
    message.contactMethods = object.contactMethods?.map((e) => ContactMethod.fromPartial(e)) || [];
    message.authToken = object.authToken ?? undefined;
    return message;
  },
};

type Builtin = Date | Function | Uint8Array | string | number | boolean | undefined;

export type DeepPartial<T> = T extends Builtin ? T
  : T extends globalThis.Array<infer U> ? globalThis.Array<DeepPartial<U>>
  : T extends ReadonlyArray<infer U> ? ReadonlyArray<DeepPartial<U>>
  : T extends {} ? { [K in keyof T]?: DeepPartial<T[K]> }
  : Partial<T>;

type KeysOfUnion<T> = T extends T ? keyof T : never;
export type Exact<P, I extends P> = P extends Builtin ? P
  : P & { [K in keyof P]: Exact<P[K], I[K]> } & { [K in Exclude<keyof I, KeysOfUnion<P>>]: never };

function toTimestamp(dateStr: string): Timestamp {
  const date = new globalThis.Date(dateStr);
  const seconds = date.getTime() / 1_000;
  const nanos = (date.getTime() % 1_000) * 1_000_000;
  return { seconds, nanos };
}

function fromTimestamp(t: Timestamp): string {
  let millis = (t.seconds || 0) * 1_000;
  millis += (t.nanos || 0) / 1_000_000;
  return new globalThis.Date(millis).toISOString();
}

function isSet(value: any): boolean {
  return value !== null && value !== undefined;
}
