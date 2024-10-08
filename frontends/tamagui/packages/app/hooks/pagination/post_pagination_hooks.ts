import { Group, PostListingType } from "@jonline/api";
import { useDebounce } from "@jonline/ui";
import { createSelector } from "@reduxjs/toolkit";
import { Selector, useAppDispatch } from "app/hooks";
import { FederatedGroup, FederatedPost, RootState, getGroupPostPages, getHasGroupPostsPage, getHasMoreGroupPostPages, getHasMorePostPages, getHasPostsPage, getServersMissingPostsPage, loadGroupPostsPage, loadPostsPage, selectPostPages, store, useRootSelector } from "app/store";
import { useEffect, useMemo, useState } from "react";
import { someLoading, someUnloaded } from '../../store/pagination/federated_pages_status';
import { usePinnedAccountsAndServers } from '../account_or_server/use_pinned_accounts_and_servers';
import { useFederatedDispatch } from '../credential_dispatch_hooks';
import { useAppSelector } from '../store_hooks';
import { PaginationResults } from "./pagination_hooks";
import { GetPostsWithServers, postsApi, useGetPostsPageQuery } from "app/store/apis";

export type PostPageParams = {};

export function usePostPages(
  listingType: PostListingType,
  selectedGroup: FederatedGroup | undefined,
): PaginationResults<FederatedPost> {
  const [currentPage, setCurrentPage] = useState(0);

  const mainPostPages = useServerPostPages(listingType, currentPage);
  const groupPostPages = useGroupPostPages(selectedGroup, currentPage);

  return selectedGroup
    ? groupPostPages
    : mainPostPages;
}

function useServerPostPages(
  listingType: PostListingType,
  throughPage: number
): PaginationResults<FederatedPost> {
  const dispatch = useAppDispatch();
  const servers = usePinnedAccountsAndServers();
  const postsState = useRootSelector((state: RootState) => state.posts);
  const loading = someLoading(postsState.pagesStatus, servers);
  // const [loading, setLoading] = useState(false);

  const results: FederatedPost[] = useAppSelector(state => selectPostPages(state, listingType, throughPage, servers));
  // useMemo(
  //   () => getPostsPages(postsState, listingType, throughPage, servers),
  //   [
  //     postsState.ids,
  //     postsState.pagesStatus,
  //     servers.map(s => [s.account?.user?.id, s.server?.host]), ,
  //     listingType
  //   ]
  // );
  const firstPageLoaded = getHasPostsPage(postsState, listingType, 0, servers);
  const hasMorePages = getHasMorePostPages(postsState, listingType, throughPage, servers);
  const serversAllDefined = !servers.some(s => !s.server);
  const serversMissingPostsPage = getServersMissingPostsPage(postsState, listingType, 0, servers);

  const reload = (force?: boolean) => {
    // if (loading) return;

    const serversToUpdate = force ? servers : serversMissingPostsPage;
    if (serversToUpdate.length === 0) return;

    console.log('Reloading posts for servers', serversToUpdate.map(s => s.server?.host));
    Promise.all(serversToUpdate.map(server =>
      dispatch(loadPostsPage({ ...server, listingType })))
    ).then((results) => {
      console.log("Loaded posts", results);
    });
  }
  // const debounceReload = useDebounce(reload, 1000, { leading: true });

  const needsLoading = serversMissingPostsPage.length > 0 && !loading && serversAllDefined;
  useEffect(() => {
    if (needsLoading) {
      // console.log("Loading posts...");
      reload();
    }
  }, [needsLoading]);

  return { results, loading, reload, hasMorePages, firstPageLoaded };
}

function useGroupPostPages(
  group: FederatedGroup | undefined,
  throughPage: number
): PaginationResults<FederatedPost> {

  const { dispatch, accountOrServer } = useFederatedDispatch(group);
  // const state = useRootSelector((state: RootState) => state);
  const [loading, setLoadingPosts] = useState(false);

  const reload = () => {
    setLoadingPosts(true);
    if (group) dispatch(loadGroupPostsPage({ ...accountOrServer, groupId: group.id }))
      .then(() => setLoadingPosts(false));
  }

  useEffect(() => {
    if (group && !firstPageLoaded && !loading) {
      if (!accountOrServer.server) return;

      console.log("Loading group posts...");
      setLoadingPosts(true);
      reload();
    }
  }, [group, accountOrServer]);

  const { results, firstPageLoaded, hasMorePages } = useAppSelector(selectGroupPages(group, throughPage));

  if (!group) return { results: [], loading: false, reload: () => { }, hasMorePages: false, firstPageLoaded: true };

  return { results, loading, reload, hasMorePages, firstPageLoaded };
}



const selectGroupPages = (
  group: FederatedGroup | undefined,
  throughPage: number,
): Selector<Pick<PaginationResults<FederatedPost>, 'results' | 'firstPageLoaded' | 'hasMorePages'>> =>
  createSelector(
    [(state: RootState) => {

      const defaultGroup: FederatedGroup = useMemo(() => ({ ...Group.create(), serverHost: '' }), []);
      const results: FederatedPost[] = getGroupPostPages(state, group ?? defaultGroup, throughPage);
      const firstPageLoaded = getHasGroupPostsPage(state.groups, group ?? defaultGroup, 0);
      const hasMorePages = getHasMoreGroupPostPages(state.groups, group ?? defaultGroup, throughPage);
      return { results, firstPageLoaded, hasMorePages };
    }],
    (data) => data
  );
