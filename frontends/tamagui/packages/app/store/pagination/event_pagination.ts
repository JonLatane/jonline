import { EventListingType } from "@jonline/api";
import { defederateId, federatedId, getFederated } from "../federation";
import { EventsState, FederatedEvent, FederatedGroup, GroupsState, selectEventById } from "../modules";
import { RootState } from "../store";
import { AccountOrServer } from "../types";


export function getEventsPages(events: EventsState, listingType: EventListingType, timeFilter: string, throughPage: number, servers: AccountOrServer[]): FederatedEvent[] {
  const result: FederatedEvent[] = [];
  for (let page = 0; page <= throughPage; page++) {
    const pagePosts = getEventsPage(events, listingType, timeFilter, page, servers);
    result.push(...pagePosts);
  }
  return result;
}

export function getEventsPage(events: EventsState, listingType: EventListingType, timeFilter: string, page: number, servers: AccountOrServer[]): FederatedEvent[] {
  const pageInstanceIds: string[] = servers.flatMap(server => {
    const serverEventInstancePages = getFederated(events.eventInstancePages, server.server);
    return ((serverEventInstancePages[listingType] ?? {})[timeFilter] ?? {})[page] ?? [];
  });

  const pageEvents = instancesToEvents(events, pageInstanceIds);
  pageEvents.sort((a, b) => (a.instances[0]?.startsAt ?? '').localeCompare(b.instances[0]?.startsAt ?? ''));
  // pageEvents.sort((a, b) => moment(a.instances[0]?.startsAt).diff(b.instances[0]?.startsAt));
  return pageEvents;
}

export function getHasEventsPage(events: EventsState, listingType: EventListingType, timeFilter: string, page: number, servers: AccountOrServer[]): boolean {
  return !servers.some(isMissingServerPage(events, listingType, timeFilter, page));
}

export function getServersMissingEventsPage(events: EventsState, listingType: EventListingType, timeFilter: string, page: number, servers: AccountOrServer[]): AccountOrServer[] {
  return servers.filter(isMissingServerPage(events, listingType, timeFilter, page));
}

function isMissingServerPage(events: EventsState, listingType: EventListingType, timeFilter: string, page: number) {
  return (server: AccountOrServer) => {
    const serverEventInstancePages = getFederated(events.eventInstancePages, server.server);
    return ((serverEventInstancePages[listingType] ?? {})[timeFilter] ?? {})[page] === undefined;
  }
}
export function getHasMoreEventPages(events: EventsState, listingType: EventListingType, timeFilter: string, currentPage: number, servers: AccountOrServer[]): boolean {
  return servers.some(server => server.server && ((events.eventInstancePages[server.server!.host]?.[listingType] ?? {})[currentPage]?.length ?? 0) > 0);

}

export function getGroupEventPages(state: RootState, group: FederatedGroup, timeFilter: string, throughPage: number): FederatedEvent[] {
  const result: FederatedEvent[] = [];

  for (let page = 0; page <= throughPage; page++) {
    const pageEvents = getGroupEventsPage(state, group, timeFilter, page);
    // debugger;
    result.push(...pageEvents);
  }
  return result;
}

function getGroupEventsPage(state: RootState, group: FederatedGroup, timeFilter: string, page: number): FederatedEvent[] {
  const groupId = federatedId(group);
  const { events, groups } = state;
  const pageInstanceIds: string[] = ((groups.groupEventPages[groupId] ?? {})[timeFilter] ?? {})[page] ?? [];
  // debugger;
  const pageEvents = instancesToEvents(events, pageInstanceIds);
  // console.log('pageInstanceIds.length', pageInstanceIds.length, pageInstanceIds, 'pageEvents.length', pageEvents.length);
  return pageEvents;
}
export function getHasGroupEventsPage(state: RootState, group: FederatedGroup, timeFilter: string, page: number): boolean {
  const { events, groups } = state;
  const groupId = federatedId(group);
  const data = ((groups.groupEventPages[groupId] ?? {})[timeFilter] ?? {})[page];
  // debugger;
  return data != undefined// && instancesToEvents(events, data).length > 0;
}

export function getHasMoreGroupEventPages(groups: GroupsState, group: FederatedGroup, timeFilter: string, currentPage: number): boolean {
  const groupId = federatedId(group);
  return (((groups.groupEventPages[groupId] ?? {})[timeFilter] ?? {})[currentPage]?.length ?? 0) > 0;
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
