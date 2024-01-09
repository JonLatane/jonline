import { GroupListingType } from "@jonline/api";
import { debounce, useDebounce } from "@jonline/ui";
import { FederatedGroup, RootState, getServersMissingGroupsPage, getGroupsPages, getHasGroupsPage, getHasMoreGroupPages, loadGroupsPage, someUnloaded, useRootSelector } from "app/store";
import { useEffect, useState } from "react";
import { useCredentialDispatch, useCurrentAndPinnedServers } from "../account_and_server_hooks";
import { finishPagination } from './post_pagination_hooks';

export type GroupPageParams = { onLoaded?: () => void, disableLoading?: boolean };

export function useGroupPages(listingType: GroupListingType, throughPage: number, params?: GroupPageParams) {
  const { dispatch, accountOrServer: currentAccountOrServer } = useCredentialDispatch();
  const servers = useCurrentAndPinnedServers();
  const groupsState = useRootSelector((state: RootState) => state.groups);
  const [loadingGroups, setLoadingGroups] = useState(false);

  const groups: FederatedGroup[] = getGroupsPages(groupsState, listingType, throughPage, servers);

  const debounceReload = useDebounce(reload, 1000, {leading: true});
  useEffect(() => {
    if (!loadingGroups && !params?.disableLoading && someUnloaded(groupsState.pagesStatus, servers)) {
      setLoadingGroups(true);
      // reload();
      setTimeout(debounceReload, 1);
    }
    // else if (loadingGroups && !['unloaded', 'loading'].includes(groupsState.pagesStatus)) {
    //   setLoadingGroups(false);
    // }
  }, [loadingGroups, groupsState.pagesStatus, servers.map(s => s.server?.host).join(',')]);

  function reload() {
    setLoadingGroups(true);
    const serversToUpdate = getServersMissingGroupsPage(groupsState, listingType, 0, servers);
    console.log('Reloading groups for servers', serversToUpdate.map(s => s.server?.host));
    Promise.all(serversToUpdate.map(server =>
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

  return { groups, loadingGroups, reloadGroups: reload, hasMorePages, firstPageLoaded };
}
