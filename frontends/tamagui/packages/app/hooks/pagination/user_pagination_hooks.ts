import { Moderation, UserListingType } from "@jonline/api";
import { useDebounce } from "@jonline/ui";
import { FederatedUser, getMembersPage, getServersMissingUsersPage, getUsersPage, loadGroupMembers, loadUsersPage, parseFederatedId } from "app/store";
import { useEffect, useMemo, useState } from "react";
import { PaginationResults } from ".";
import { useFederatedAccountOrServer } from "../account_or_server";
import { usePinnedAccountsAndServers } from '../account_or_server/use_pinned_accounts_and_servers';
import { useAppDispatch, useAppSelector } from "../store_hooks";
import { PagesStatus, someLoading } from '../../store/pagination/federated_pages_status';

export function useUsersPage(
  listingType: UserListingType | undefined,
  page: number,
): PaginationResults<FederatedUser> {
  const dispatch = useAppDispatch();
  const servers = usePinnedAccountsAndServers();
  const usersState = useAppSelector(state => state.users);

  const loading = someLoading(usersState.pagesStatus, servers);
  const effectiveListingType = listingType ?? UserListingType.EVERYONE;
  function reload(force?: boolean) {
    if (loading) return;

    const serversToUpdate = force
      ? servers
      : getServersMissingUsersPage(usersState, effectiveListingType, 0, servers);
    Promise.all(
      serversToUpdate.map(pinnedServer =>
        dispatch(loadUsersPage({ listingType, ...pinnedServer })))
    ).then((results) => {
      console.log("Loaded users", effectiveListingType, results);
      // setLoadingUsers(false);
    });
  }

  const state = useAppSelector(state => state.users);
  const { users, hadUndefinedServers } = useMemo(
    () => getUsersPage(state, effectiveListingType, page, servers),
    [
      state.ids,
      servers.map(s => s.server?.host),
      listingType
    ])
  // const debounceReload = useDebounce(reload, 1000, { leading: true });
  useEffect(() => {
    if (listingType !== undefined && hadUndefinedServers && !loading) {
      console.log("Loading users...");
      reload();
    }
  }, [listingType, users, loading]);

  return {
    results: users,
    loading: loading,
    reload: reload,
    firstPageLoaded: users !== undefined,
  };
}

export function useMembersPage(
  groupId: string,
  page: number,
  groupModeration?: Moderation
): PaginationResults<FederatedUser> {
  const dispatch = useAppDispatch();
  const { serverHost } = parseFederatedId(groupId);
  const accountOrServer = useFederatedAccountOrServer(serverHost);

  const [loadingMembers, setLoadingMembers] = useState(false);
  function reloadMembers() {
    dispatch(loadGroupMembers({ id: groupId, ...accountOrServer })).then((results) => {
      console.log("Loaded members", results);
      setLoadingMembers(false);
    });
  }

  const { users, hadUndefinedServers } = useAppSelector(state => getMembersPage(state, groupId, page, groupModeration))
  useEffect(() => {
    if (groupId && hadUndefinedServers && !loadingMembers && accountOrServer?.server) {
      console.log("Loading members...");
      setLoadingMembers(true);
      reloadMembers();
    }
  }, [groupId, users, loadingMembers]);

  // console.log("members page", groupId, page, users);
  return {
    results: groupId ? users : [],
    loading: loadingMembers,
    reload: reloadMembers,
    firstPageLoaded: groupId ? users !== undefined : true,
  };
}