import { Group, GroupListingType } from "@jonline/api";
import { GroupsState, selectGroupById } from "../modules";

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
