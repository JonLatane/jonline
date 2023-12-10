import { Group, GroupListingType } from "@jonline/api";
import { RootState, getGroupPages, getHasGroupsPage, getHasMoreGroupPages, loadGroupsPage, useRootSelector } from "app/store";
import { useEffect, useState } from "react";
import { useCredentialDispatch } from "./account_and_server_hooks";
import { finishPagination } from './post_pagination_hooks';

export type GroupPageParams = { onLoaded?: () => void };

export function useGroupPages(listingType: GroupListingType, throughPage: number, params?: GroupPageParams) {
  const { dispatch, accountOrServer } = useCredentialDispatch();
  const groupsState = useRootSelector((state: RootState) => state.groups);
  const [loadingGroups, setLoadingGroups] = useState(false);

  const groups: Group[] = getGroupPages(groupsState, listingType, throughPage);

  useEffect(() => {
    if (groupsState.status == 'unloaded' && !loadingGroups) {
      if (!accountOrServer.server) return;

      console.log("Loading groups...");
      setLoadingGroups(true);
      reloadGroups();
    }
    // else if (groupsState.pagesStatus == 'loaded' && loadingGroups) {
    //   setLoadingGroups(false);
    //   onLoaded?.();
    // }
  });

  const firstPageLoaded = getHasGroupsPage(groupsState, listingType, 0);
  const hasMorePages = getHasMoreGroupPages(groupsState, listingType, throughPage);

  function reloadGroups() {
    dispatch(loadGroupsPage({ ...accountOrServer, listingType })).then(finishPagination(setLoadingGroups, params?.onLoaded));
  }

  return { groups, loadingGroups, reloadGroups, hasMorePages, firstPageLoaded };
}
