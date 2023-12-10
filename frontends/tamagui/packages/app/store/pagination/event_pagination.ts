import { Event, EventListingType } from "@jonline/api";
import { EventsState, GroupsState, selectEventById } from "../modules";
import { RootState } from "../store";


function getEventsPage(events: EventsState, listingType: EventListingType, timeFilter: string, page: number): Event[] {
  const pageInstanceIds: string[] = ((events.eventInstancePages[listingType] ?? {})[timeFilter] ?? {})[page] ?? [];
  const pageEvents = instancesToEvents(events, pageInstanceIds);
  return pageEvents;
}

export function getEventPages(events: EventsState, listingType: EventListingType, timeFilter: string, throughPage: number): Event[] {
  const result: Event[] = [];
  for (let page = 0; page <= throughPage; page++) {
    const pageEvents = getEventsPage(events, listingType, timeFilter, page);
    // debugger;
    result.push(...pageEvents.filter(e => e.post?.author != undefined));
  }
  return result;
}

export function getHasEventsPage(events: EventsState, listingType: EventListingType, timeFilter: string, page: number): boolean {
  return ((events.eventInstancePages[listingType] ?? {})[timeFilter] ?? {})[page] != undefined;
}

export function getHasMoreEventPages(events: EventsState, listingType: EventListingType, timeFilter: string, currentPage: number): boolean {
  return (((events.eventInstancePages[listingType] ?? {})[timeFilter] ?? {})[currentPage]?.length ?? 0) > 0;
}

export function getGroupEventPages(state: RootState, groupId: string, timeFilter: string, throughPage: number): Event[] {
  const result: Event[] = [];

  for (let page = 0; page <= throughPage; page++) {
    const pageEvents = getGroupEventsPage(state, groupId, timeFilter, page);
    // debugger;
    result.push(...pageEvents);
  }
  return result;
}

function getGroupEventsPage(state: RootState, groupId: string, timeFilter: string, page: number): Event[] {
  const { events, groups } = state;
  const pageInstanceIds: string[] = ((groups.groupEventPages[groupId] ?? {})[timeFilter] ?? {})[page] ?? [];
  const pageEvents = instancesToEvents(events, pageInstanceIds);
  console.log('pageInstanceIds.length', pageInstanceIds.length, pageInstanceIds, 'pageEvents.length', pageEvents.length);
  return pageEvents;
}

function instancesToEvents(events: EventsState, instanceIds: string[]) {
  return instanceIds.map(instanceId => {
    const eventId = events.instanceEvents[instanceId];
    // console.log('eventId', eventId, events.instanceEvents)
    if (!eventId) return undefined;

    const event = selectEventById(events, eventId)
    if (!event) return undefined;

    return { ...event, instances: event.instances.filter(i => i.id == instanceId) };
  }).filter(p => p).map(p => p as Event);
}

export function getHasGroupEventsPage(state: RootState, groupId: string, timeFilter: string, page: number): boolean {
  const { events, groups } = state;
  const data = ((groups.groupEventPages[groupId] ?? {})[timeFilter] ?? {})[page];
  return data != undefined// && instancesToEvents(events, data).length > 0;
}

export function getHasMoreGroupEventPages(groups: GroupsState, groupId: string, timeFilter: string, currentPage: number): boolean {
  return (((groups.groupEventPages[groupId] ?? {})[timeFilter] ?? {})[currentPage]?.length ?? 0) > 0;
}

