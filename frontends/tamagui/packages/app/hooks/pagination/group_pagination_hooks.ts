import { GroupListingType } from "@jonline/api";
import { useDebounce } from "@jonline/ui";
import { FederatedGroup, RootState, getGroupsPages, getHasGroupsPage, getHasMoreGroupPages, getServersMissingGroupsPage, loadGroupsPage, someUnloaded, useRootSelector } from "app/store";
import { useEffect, useMemo, useState } from "react";
import { usePinnedAccountsAndServers } from '../account_or_server/use_pinned_accounts_and_servers';
import { useCredentialDispatch } from "../credential_dispatch_hooks";
import { finishPagination } from './pagination_hooks';

export type GroupPageParams = { onLoaded?: () => void, disableLoading?: boolean };

export function useGroupPages(listingType: GroupListingType, throughPage: number, params?: GroupPageParams) {
  const { dispatch, accountOrServer: currentAccountOrServer } = useCredentialDispatch();
  const servers = usePinnedAccountsAndServers();
  const groupsState = useRootSelector((state: RootState) => state.groups);
  const [loadingGroups, setLoadingGroups] = useState(false);

  const groups: FederatedGroup[] = useMemo(
    () => getGroupsPages(groupsState, listingType, throughPage, servers),
    [
      groupsState.ids,
      servers.map(s => [s.account?.user?.id, s.server?.host]),,
      listingType
    ]
  );

  const debounceReload = useDebounce(reload, 1000, { leading: true });
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
