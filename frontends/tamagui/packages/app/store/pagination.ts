import { Event, EventInstance, EventListingType, Group, GroupListingType, Post, PostListingType } from "@jonline/api";
import { EventsState, GroupsState, PostsState, selectEventById, selectGroupById, selectPostById, serializeTimeFilter } from "./modules";
import { RootState } from "./store";
import { Dictionary } from "@reduxjs/toolkit";
import { TimeFilter } from '../../api/generated/events';


/**
 * Fundamental type for Jonline pagination. Stores IDs of paginated resources like Groups, People, Posts, Events, etc. used in the UI.
 * May be keyed by [Resource]ListingType or groupId.
 * Posts should be loaded from the adapter/slice's entities. An empty page indicates there is no more data to load.
 * Maps either: 
 *  * <code>PostListingType</code> -> <code>page</code> -> <code>postIds</code>, or
 *  * <code>groupId</code> -> <code>page</code> -> <code>postIds</code>
 * Access for page <code>0</code> looks like:
 *  * <code>postPages[PostListingType.ALL_ACCESSIBLE_POSTS][0]</code> -> <code>["postId1", "postId2"]</code>.
 *  * <code>groupPostPages['groupId1'][0]</code> -> <code>["postId1", "postId2"]</code>.
 */
export type GroupedPages = Dictionary<PaginatedIds>;

/**
 * Pagination state building block, accessed via <code>number</code> rather than <code>string</code> keys.
 * I.E: An array of the form: <code> [["postId1", "postId2"], ["postId3"]]</code> (with "implicit" pagesize 2), just as a `Dictionary`
 * for serializability. Access looks like: <code> pages[0] -> ["postId1", "postId2"], pages[1] -> ["postId3"]</code>.
 * 
 * We trust that the server will return the same consistent pagination data, and if not, "refresh the page to see the updated version"
 * is a reasonable fallback.
 */
export type PaginatedIds = string[][];

function getGroupsPage(groups: GroupsState, listingType: GroupListingType, page: number): Group[] {
  const pageGroupIds: string[] = (groups.pages[listingType] ?? {})[page] ?? [];
  const pageGroups = pageGroupIds.map(id => selectGroupById(groups, id))
    .filter(p => p) as Group[];
  return pageGroups;
}

export function getGroupPages(groups: GroupsState, listingType: GroupListingType, throughPage: number): Group[] {
  const result: Group[] = [];
  for (let page = 0; page <= throughPage; page++) {
    const pageGroups = getGroupsPage(groups, listingType, page);
    result.push(...pageGroups
      // .filter(p => p.author != undefined)
    );
  }
  return result;
}

export function getHasGroupsPage(groups: GroupsState, listingType: GroupListingType, page: number): boolean {
  return (groups.pages[listingType] ?? {})[page] != undefined;
}
export function getHasMoreGroupPages(groups: GroupsState, listingType: GroupListingType, currentPage: number): boolean {
  return ((groups.pages[listingType] ?? {})[currentPage]?.length ?? 0) > 0;
}

function getPostsPage(posts: PostsState, listingType: PostListingType, page: number): Post[] {
  const pagePostIds: string[] = (posts.postPages[listingType] ?? {})[page] ?? [];
  const pagePosts = pagePostIds.map(id => selectPostById(posts, id))
    .filter(p => p) as Post[];
  return pagePosts;
}

export function getPostPages(posts: PostsState, listingType: PostListingType, throughPage: number): Post[] {
  const result: Post[] = [];
  for (let page = 0; page <= throughPage; page++) {
    const pagePosts = getPostsPage(posts, listingType, page);
    result.push(...pagePosts
      // .filter(p => p.author != undefined)
    );
  }
  return result;
}

export function getHasPostsPage(posts: PostsState, listingType: PostListingType, page: number): boolean {
  return (posts.postPages[listingType] ?? {})[page] != undefined;
}
export function getHasMorePostPages(posts: PostsState, listingType: PostListingType, currentPage: number): boolean {
  return ((posts.postPages[listingType] ?? {})[currentPage]?.length ?? 0) > 0;
}

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


function getGroupPostsPage(state: RootState, groupId: string, page: number): Post[] {
  const { posts, groups } = state;
  const pagePostIds: string[] = (groups.groupPostPages[groupId] ?? {})[page] ?? [];
  const pagePosts = pagePostIds.map(id => selectPostById(posts, id)).filter(p => p) as Post[];
  return pagePosts;
}

export function getGroupPostPages(state: RootState, groupId: string, throughPage: number): Post[] {
  const result: Post[] = [];
  console.log('getGroupPostPages', groupId, throughPage);
  for (let page = 0; page <= throughPage; page++) {
    const pagePosts = getGroupPostsPage(state, groupId, page);
    result.push(...pagePosts);
  }
  return result;
}

export function getHasGroupPostsPage(groups: GroupsState, groupId: string, page: number): boolean {
  return (groups.groupPostPages[groupId] ?? {})[page] != undefined;
}

export function getHasMoreGroupPostPages(groups: GroupsState, groupId: string, currentPage: number): boolean {
  return ((groups.groupPostPages[groupId] ?? {})[currentPage]?.length ?? 0) > 0;
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

