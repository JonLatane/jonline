import { GroupListingType } from "@jonline/api";
import { FederatedGroup, RootState, getGroupPages, getHasGroupsPage, getHasMoreGroupPages, loadGroupsPage, someUnloaded, useRootSelector } from "app/store";
import { useEffect, useState } from "react";
import { useCredentialDispatch, useCurrentAndPinnedServers } from "../account_and_server_hooks";
import { finishPagination } from './post_pagination_hooks';

export type GroupPageParams = { onLoaded?: () => void, disableLoading?: boolean };

export function useGroupPages(listingType: GroupListingType, throughPage: number, params?: GroupPageParams) {
  const { dispatch, accountOrServer: currentAccountOrServer } = useCredentialDispatch();
  const servers = useCurrentAndPinnedServers();
  const groupsState = useRootSelector((state: RootState) => state.groups);
  const [loadingGroups, setLoadingGroups] = useState(false);

  const groups: FederatedGroup[] = getGroupPages(groupsState, listingType, throughPage, servers);

  useEffect(() => {
    if (!loadingGroups && !params?.disableLoading && someUnloaded(groupsState.pagesStatus, servers)) {
      setLoadingGroups(true);
      reloadGroups();
    }
    // else if (loadingGroups && !['unloaded', 'loading'].includes(groupsState.pagesStatus)) {
    //   setLoadingGroups(false);
    // }
  }, [loadingGroups, groupsState.pagesStatus, servers.map(s => s.server?.host).join(',')]);

  function reloadGroups() {
    console.log('Reloading groups for servers', servers.map(s => s.server?.host));
    Promise.all(servers.map(server =>
      dispatch(loadGroupsPage({ ...server, listingType })))
    ).then((results) => {
      console.log("Loaded groups", results);
      finishPagination(setLoadingGroups, params?.onLoaded);
    });
  }

  const firstPageLoaded = getHasGroupsPage(groupsState, listingType, 0, servers);
  const hasMorePages = getHasMoreGroupPages(groupsState, listingType, throughPage, servers);

  // function reloadGroups() {
  //   dispatch(loadGroupsPage({ ...accountOrServer, listingType })).then(onPageLoaded(setLoadingGroups, params?.onLoaded));
  // }

  return { groups, loadingGroups, reloadGroups, hasMorePages, firstPageLoaded };
}
