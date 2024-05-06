import { Moderation, User, UserListingType } from "@jonline/api";
import { AccountOrServer, FederatedUser, getMembersPage, getUsersPage, loadGroupMembers, loadUsersPage, parseFederatedId, selectAllServers } from "app/store";
import { useEffect, useMemo, useState } from "react";
import { usePinnedAccountsAndServers } from '../account_or_server/use_pinned_accounts_and_servers';
import { useCurrentAccountOrServer } from '../account_or_server/use_current_account_or_server';
import { useAppDispatch, useAppSelector } from "../store_hooks";
import { PaginationResults } from ".";
import { useFederatedAccountOrServer } from "../account_or_server";

export function useUsersPage(
  listingType: UserListingType,
  page: number,
): PaginationResults<FederatedUser> {
  const dispatch = useAppDispatch();
  const servers = usePinnedAccountsAndServers();

  const [loadingUsers, setLoadingUsers] = useState(false);
  function reloadUsers() {
    Promise.all(
      servers.map(pinnedServer =>
        dispatch(loadUsersPage({ listingType, ...pinnedServer })))
    ).then((results) => {
      console.log("Loaded users", results);
      setLoadingUsers(false);
    });
  }

  const state = useAppSelector(state => state.users);
  const { users, hadUndefinedServers } = useMemo(
    () => getUsersPage(state, listingType, page, servers),
    [
      state.ids,
      servers.map(s => s.server?.host),
      listingType
    ])
  useEffect(() => {
    if (listingType === UserListingType.EVERYONE && hadUndefinedServers && !loadingUsers) {
      console.log("Loading users...");
      setLoadingUsers(true);
      reloadUsers();
    }
  }, [users, loadingUsers]);

  return {
    results: users,
    loading: loadingUsers,
    reload: reloadUsers,
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
    if (hadUndefinedServers && !loadingMembers && accountOrServer?.server) {
      console.log("Loading members...");
      setLoadingMembers(true);
      reloadMembers();
    }
  }, [users, loadingMembers]);

  // console.log("members page", groupId, page, users);
  return {
    results: users,
    loading: loadingMembers,
    reload: reloadMembers,
    firstPageLoaded: users !== undefined,
  };
}