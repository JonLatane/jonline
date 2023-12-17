import { GroupListingType } from "@jonline/api";
import { getFederated } from "../federation";
import { FederatedGroup, GroupsState, selectGroupById } from "../modules";
import { AccountOrServer } from "../types";

export function getGroupPages(groups: GroupsState, listingType: GroupListingType, throughPage: number, servers: AccountOrServer[]): FederatedGroup[] {
  const result: FederatedGroup[] = [];
  for (let page = 0; page <= throughPage; page++) {
    const pageGroups = getGroupsPage(groups, listingType, page, servers);
    result.push(...pageGroups);
  }
  return result;
}

function getGroupsPage(groups: GroupsState, listingType: GroupListingType, page: number, servers: AccountOrServer[]): FederatedGroup[] {

  const pageGroupIds: string[] = servers.flatMap(server => {
    const serverPages = getFederated(groups.pages, server.server);
    return (serverPages[listingType] ?? {})[page] ?? [];
  });
  const pageGroups = pageGroupIds.map(id => selectGroupById(groups, id))
    .filter(p => p) as FederatedGroup[];
  return pageGroups;
  // const pageGroupIds: string[] = (groups.pages[listingType] ?? {})[page] ?? [];
  // const pageGroups = pageGroupIds.map(id => selectGroupById(groups, id))
  //   .filter(p => p) as Group[];
  // return pageGroups;
}

export function getHasGroupsPage(groups: GroupsState, listingType: GroupListingType, page: number, servers: AccountOrServer[]): boolean {
  return !servers.some(server => {
    const serverPages = getFederated(groups.pages, server.server);
    return (serverPages[listingType] ?? {})[page] === undefined;
  });
  // return (groups.pages[listingType] ?? {})[page] != undefined;
}
export function getHasMoreGroupPages(groups: GroupsState, listingType: GroupListingType, currentPage: number, servers: AccountOrServer[]): boolean {
  return servers.some(server => ((groups.pages[server.server!.host]?.[listingType] ?? {})[currentPage]?.length ?? 0) > 0);
  // return ((groups.pages[listingType] ?? {})[currentPage]?.length ?? 0) > 0;
}
