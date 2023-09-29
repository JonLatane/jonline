import { Event, EventInstance, EventListingType, Post, PostListingType } from "@jonline/api";
import { EventsState, GroupsState, PostsState, selectEventById, selectPostById } from "./modules";
import { RootState } from "./store";
import { Dictionary } from "@reduxjs/toolkit";


/**
 * Fundamental type for Jonline pagination. Stores IDs of paginated resources like Groups, People, Posts, Events, etc. used in the UI.
 * May be keyed by [Resource]ListingType or groupId.
 * Posts should be loaded from the adapter/slice's entities. An empty page indicates there is no more data to load.
 * Maps either: 
 *  * <code>PostListingType</code> -> <code>page</code> -> <code>postIds</code>, or
 *  * <code>groupId</code> -> <code>page</code> -> <code>postIds</code>
 * Access for page <code>0</code> looks like:
 *  * <code>postPages[PostListingType.PUBLIC_POSTS][0]</code> -> <code>["postId1", "postId2"]</code>.
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
export type PaginatedIds = Dictionary<string[]>;

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
    result.push(...pagePosts.filter(p => p.author != undefined));
  }
  return result;
}

export function getHasPostsPage(posts: PostsState, listingType: PostListingType, page: number): boolean {
  return (posts.postPages[listingType] ?? {})[page] != undefined;
}
export function getHasMorePostPages(posts: PostsState, listingType: PostListingType, currentPage: number): boolean {
  return ((posts.postPages[listingType] ?? {})[currentPage]?.length ?? 0) > 0;
}

function getEventsPage(events: EventsState, listingType: EventListingType, page: number): Event[] {
  const pageInstaceIds: string[] = (events.eventInstancePages[listingType] ?? {})[page] ?? [];
  const pageInstances = pageInstaceIds.map(id => events.instances[id]).filter(p => p) as EventInstance[];
  const pageEvents = pageInstances.map(instance => {
    const event = selectEventById(events, instance.eventId);
    return event ? { ...event, instances: [instance] } : undefined;
  }).filter(p => p) as Event[];
  return pageEvents;
}

export function getEventPages(events: EventsState, listingType: EventListingType, throughPage: number): Event[] {
  const result: Event[] = [];
  for (let page = 0; page <= throughPage; page++) {
    const pageEvents = getEventsPage(events, listingType, page);
    result.push(...pageEvents.filter(e => e.post?.author != undefined));
  }
  return result;
}

export function getHasEventsPage(events: EventsState, listingType: EventListingType, page: number): boolean {
  return (events.eventInstancePages[listingType] ?? {})[page] != undefined;
}

export function getHasMoreEventPages(events: EventsState, listingType: EventListingType, currentPage: number): boolean {
  return ((events.eventInstancePages[listingType] ?? {})[currentPage]?.length ?? 0) > 0;
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


function getGroupEventsPage(state: RootState, groupId: string, page: number): Event[] {
  const { events, groups } = state;
  const pageInstaceIds: string[] = (groups.groupEventPages[groupId] ?? {})[page] ?? [];
  const pageInstances = pageInstaceIds.map(id => events.instances[id]).filter(p => p) as EventInstance[];
  const pageEvents = pageInstances.map(instance => {
    const event = selectEventById(events, instance.eventId);
    return event ? { ...event, instances: [instance] } : undefined;
  }).filter(p => p) as Event[];
  return pageEvents;
}

export function getGroupEventPages(state: RootState, groupId: string, throughPage: number): Event[] {
  const result: Event[] = [];
  for (let page = 0; page <= throughPage; page++) {
    const pageEvents = getGroupEventsPage(state, groupId, page);
    result.push(...pageEvents);
  }
  return result;
}

export function getHasGroupEventsPage(groups: GroupsState, groupId: string, page: number): boolean {
  return (groups.groupEventPages[groupId] ?? {})[page] != undefined;
}

export function getHasMoreGroupEventPages(groups: GroupsState, groupId: string, currentPage: number): boolean {
  return ((groups.groupEventPages[groupId] ?? {})[currentPage]?.length ?? 0) > 0;
}

