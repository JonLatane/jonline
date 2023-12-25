import { Event, EventListingType } from "@jonline/api";
import { EventsState, FederatedEvent, GroupsState, selectEventById } from "../modules";
import { RootState} from "../store";
import { AccountOrServer } from "../types";
import { defederateId, getFederated } from "../federation";
import moment from "moment";


export function getEventPages(events: EventsState, listingType: EventListingType, timeFilter: string, throughPage: number, servers: AccountOrServer[]): FederatedEvent[] {
  const result: FederatedEvent[] = [];
  for (let page = 0; page <= throughPage; page++) {
    const pagePosts = getEventsPage(events, listingType, timeFilter, page, servers);
    result.push(...pagePosts);
  }
  return result;
}

function getEventsPage(events: EventsState, listingType: EventListingType, timeFilter: string, page: number, servers: AccountOrServer[]): FederatedEvent[] {
  const pageInstanceIds: string[] = servers.flatMap(server => {
    const serverEventInstancePages = getFederated(events.eventInstancePages, server.server);
    return ((serverEventInstancePages[listingType] ?? {})[timeFilter] ?? {})[page] ?? [];
  });

  const pageEvents = instancesToEvents(events, pageInstanceIds);
  pageEvents.sort((a,b) => (a.instances[0]?.startsAt ?? '').localeCompare(b.instances[0]?.startsAt ?? ''));
  // pageEvents.sort((a, b) => moment(a.instances[0]?.startsAt).diff(b.instances[0]?.startsAt));
  return pageEvents;
}

export function getHasEventsPage(events: EventsState, listingType: EventListingType, timeFilter: string, page: number, servers: AccountOrServer[]): boolean {
  return !servers.some(server => {
    const serverEventInstancePages = getFederated(events.eventInstancePages, server.server);
    return ((serverEventInstancePages[listingType] ?? {})[timeFilter] ?? {})[page] === undefined;
  });
}

export function getHasMoreEventPages(events: EventsState, listingType: EventListingType, timeFilter: string, currentPage: number, servers: AccountOrServer[]): boolean {
  return servers.some(server => server.server && ((events.eventInstancePages[server.server!.host]?.[listingType] ?? {})[currentPage]?.length ?? 0) > 0);

}

export function getGroupEventPages(state: RootState, groupId: string, timeFilter: string, throughPage: number): FederatedEvent[] {
  const result: FederatedEvent[] = [];

  for (let page = 0; page <= throughPage; page++) {
    const pageEvents = getGroupEventsPage(state, groupId, timeFilter, page);
    // debugger;
    result.push(...pageEvents);
  }
  return result;
}

function getGroupEventsPage(state: RootState, groupId: string, timeFilter: string, page: number): FederatedEvent[] {
  const { events, groups } = state;
  const pageInstanceIds: string[] = ((groups.groupEventPages[groupId] ?? {})[timeFilter] ?? {})[page] ?? [];
  const pageEvents = instancesToEvents(events, pageInstanceIds);
  console.log('pageInstanceIds.length', pageInstanceIds.length, pageInstanceIds, 'pageEvents.length', pageEvents.length);
  return pageEvents;
}

function instancesToEvents(events: EventsState, instanceIds: string[]) {
  return instanceIds.map(instanceId => {
    const eventId = events.instanceEvents[instanceId];
    // debugger;
    // console.log('eventId', eventId, events.instanceEvents)
    if (!eventId) return undefined;

    const event = selectEventById(events, eventId)
    if (!event) return undefined;

    const singletonInstanceEvent = { ...event, instances: event.instances.filter(i => i.id == defederateId(instanceId)) };
    // debugger;
    return singletonInstanceEvent;
  }).filter(p => p).map(p => p as FederatedEvent);
}

export function getHasGroupEventsPage(state: RootState, groupId: string, timeFilter: string, page: number): boolean {
  const { events, groups } = state;
  const data = ((groups.groupEventPages[groupId] ?? {})[timeFilter] ?? {})[page];
  return data != undefined// && instancesToEvents(events, data).length > 0;
}

export function getHasMoreGroupEventPages(groups: GroupsState, groupId: string, timeFilter: string, currentPage: number): boolean {
  return (((groups.groupEventPages[groupId] ?? {})[timeFilter] ?? {})[currentPage]?.length ?? 0) > 0;
}

