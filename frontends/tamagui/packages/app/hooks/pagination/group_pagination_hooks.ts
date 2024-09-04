import { GroupListingType } from "@jonline/api";
import { FederatedGroup, RootState, getGroupsPages, getHasGroupsPage, getHasMoreGroupPages, getServersMissingGroupsPage, loadGroupsPage, someLoading, someUnloaded, useRootSelector } from "app/store";
import { useEffect, useMemo } from "react";
import { usePinnedAccountsAndServers } from '../account_or_server/use_pinned_accounts_and_servers';
import { useCredentialDispatch } from "../credential_dispatch_hooks";

export type GroupPageParams = { onLoaded?: () => void, disableLoading?: boolean };

export function useGroupPages(listingType: GroupListingType, throughPage: number, params?: GroupPageParams) {
  const { dispatch, accountOrServer: currentAccountOrServer } = useCredentialDispatch();
  const servers = usePinnedAccountsAndServers();
  const groupsState = useRootSelector((state: RootState) => state.groups);
  const loading = someLoading(groupsState.pagesStatus, servers);
  // const [loadingGroups, setLoadingGroups] = useState(false);

  const groups: FederatedGroup[] = useMemo(
    () => getGroupsPages(groupsState, listingType, throughPage, servers),
    [
      groupsState.ids,
      servers.map(s => [s.account?.user?.id, s.server?.host]), ,
      listingType
    ]
  );

  useEffect(() => {
    if (!loading && !params?.disableLoading && someUnloaded(groupsState.pagesStatus, servers)) {
      reload();
    }
    // else if (loadingGroups && !['unloaded', 'loading'].includes(groupsState.pagesStatus)) {
    //   setLoadingGroups(false);
    // }
  }, [loading, groupsState.pagesStatus, servers.map(s => s.server?.host).join(',')]);

  function reload() {
    if (loading) return;

    const serversToUpdate = getServersMissingGroupsPage(groupsState, listingType, 0, servers);
    console.log('Reloading groups for servers', serversToUpdate.map(s => s.server?.host));
    Promise.all(serversToUpdate.map(server =>
      dispatch(loadGroupsPage({ ...server, listingType })))
    ).then((results) => {
      console.log("Loaded groups", results);
    });
  }

  const firstPageLoaded = getHasGroupsPage(groupsState, listingType, 0, servers);
  const hasMorePages = getHasMoreGroupPages(groupsState, listingType, throughPage, servers);

  // function reloadGroups() {
  //   dispatch(loadGroupsPage({ ...accountOrServer, listingType })).then(onPageLoaded(setLoadingGroups, params?.onLoaded));
  // }

  return { groups, loadingGroups: loading, reloadGroups: reload, hasMorePages, firstPageLoaded };
}
