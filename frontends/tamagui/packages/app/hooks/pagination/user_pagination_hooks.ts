import { User, UserListingType } from "@jonline/api";
import { AccountOrServer, FederatedUser, getUsersPage, loadUsersPage } from "app/store";
import { useEffect, useState } from "react";
import { useAccountOrServer, useCurrentAndPinnedServers } from "../account_and_server_hooks";
import { useAppDispatch, useAppSelector } from "../store_hooks";
import { PaginationResults } from ".";

export function useUsersPage(
  listingType: UserListingType,
  page: number,
): PaginationResults<FederatedUser> {
  const dispatch = useAppDispatch();
  const servers = useCurrentAndPinnedServers();

  const [loadingUsers, setLoadingUsers] = useState(false);
  function reloadUsers() {
    Promise.all(servers.map(pinnedServer =>
      dispatch(loadUsersPage({ listingType, ...pinnedServer })))).then((results) => {
        console.log("Loaded users", results);
        setLoadingUsers(false);
      });
  }

  const state = useAppSelector(state => state.users);
  const {users, hadUndefinedServers} = getUsersPage(state, listingType, page, servers);
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

