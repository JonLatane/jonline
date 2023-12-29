import { PostListingType } from "@jonline/api";
import { federatedId, getFederated } from "../federation";
import { FederatedGroup, FederatedPost, GroupsState, PostsState, selectPostById } from "../modules";
import { RootState } from "../store";
import { AccountOrServer } from "../types";



/**
 * Pagination state building block, accessed via <code>number</code> rather than <code>string</code> keys.
 * I.E: An array of the form: <code> [["postId1", "postId2"], ["postId3"]]</code> (with "implicit" pagesize 2), just as a `Dictionary`
 * for serializability. Access looks like: <code> pages[0] -> ["postId1", "postId2"], pages[1] -> ["postId3"]</code>.
 * 
 * We trust that the server will return the same consistent pagination data, and if not, "refresh the page to see the updated version"
 * is a reasonable fallback.
 */
export function getPostPages(posts: PostsState, listingType: PostListingType, throughPage: number, servers: AccountOrServer[]): FederatedPost[] {
  const result: FederatedPost[] = [];
  for (let page = 0; page <= throughPage; page++) {
    const pagePosts = getPostsPage(posts, listingType, page, servers);
    result.push(...pagePosts);
  }
  return result;
}

function getPostsPage(posts: PostsState, listingType: PostListingType, page: number, servers: AccountOrServer[]): FederatedPost[] {
  const pagePostIds: string[] = servers.flatMap(server => {
    const serverPostPages = getFederated(posts.postPages, server.server);
    return (serverPostPages[listingType] ?? {})[page] ?? [];
  });
  const pagePosts = pagePostIds.map(id => selectPostById(posts, id))
    .filter(p => p) as FederatedPost[];
  pagePosts.sort((a, b) => (b.createdAt ?? '').localeCompare(a.createdAt ?? ''));
  return pagePosts;
}

export function getHasPostsPage(posts: PostsState, listingType: PostListingType, page: number, servers: AccountOrServer[]): boolean {
  return !servers.some(server => {
    const serverPostPages = getFederated(posts.postPages, server.server);
    return (serverPostPages[listingType] ?? {})[page] === undefined;
  });
}
export function getHasMorePostPages(posts: PostsState, listingType: PostListingType, currentPage: number, servers: AccountOrServer[]): boolean {
  return servers.some(server => server.server && ((posts.postPages[server.server!.host]?.[listingType] ?? {})[currentPage]?.length ?? 0) > 0);
}

export function getGroupPostPages(state: RootState, group: FederatedGroup, throughPage: number): FederatedPost[] {
  const result: FederatedPost[] = [];
  console.log('getGroupPostPages', group, throughPage);
  for (let page = 0; page <= throughPage; page++) {
    const pagePosts = getGroupPostsPage(state, group, page);
    result.push(...pagePosts);
  }
  return result;
}

function getGroupPostsPage(state: RootState, group: FederatedGroup, page: number): FederatedPost[] {
  const groupId = federatedId(group);
  const { posts, groups } = state;
  const pagePostIds: string[] = (groups.groupPostPages[groupId] ?? {})[page] ?? [];
  const pagePosts = pagePostIds.map(id => selectPostById(posts, id)).filter(p => p) as FederatedPost[];
  debugger;
  return pagePosts;
}

export function getHasGroupPostsPage(groups: GroupsState, group: FederatedGroup, page: number): boolean {
  const groupId = federatedId(group);
  return (groups.groupPostPages[groupId] ?? {})[page] != undefined;
}

export function getHasMoreGroupPostPages(groups: GroupsState, group: FederatedGroup, currentPage: number): boolean {
  const groupId = federatedId(group);
  return ((groups.groupPostPages[groupId] ?? {})[currentPage]?.length ?? 0) > 0;
}
