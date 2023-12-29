import { Post, PostListingType } from "@jonline/api";
import { useCredentialDispatch, useForceUpdate } from "app/hooks";
import { FederatedGroup, FederatedPost, RootState, getGroupPostPages, getHasGroupPostsPage, getHasMoreGroupPostPages, getHasMorePostPages, getHasPostsPage, getPostPages, loadGroupPostsPage, loadPostsPage, useRootSelector } from "app/store";
import { useEffect, useState } from "react";
import { useCurrentAndPinnedServers } from '../account_and_server_hooks';
import { someUnloaded } from '../../store/pagination/federated_pages_status';
import { PaginationResults } from "./pagination_hooks";

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

export function useServerPostPages(
  listingType: PostListingType,
  throughPage: number
): PaginationResults<FederatedPost> {
  const { dispatch, accountOrServer: currentAccountOrServer } = useCredentialDispatch();
  const servers = useCurrentAndPinnedServers();
  const postsState = useRootSelector((state: RootState) => state.posts);
  const [loading, setLoadingPosts] = useState(false);

  const results: FederatedPost[] = getPostPages(postsState, listingType, throughPage, servers);

  useEffect(() => {
    // console.log('usePostPages', servers.map(s => s.server?.host).join(','), someUnloaded(postsState.pagesStatus, servers));
    if (!loading && someUnloaded(postsState.pagesStatus, servers)) {
      setLoadingPosts(true);
      console.log("Loading posts...");
      setTimeout(reload, 1);
    }
  }, [loading, postsState.pagesStatus, servers.map(s => s.server?.host).join(',')]);

  const firstPageLoaded = getHasPostsPage(postsState, listingType, 0, servers);
  const hasMorePages = getHasMorePostPages(postsState, listingType, throughPage, servers);

  const reload = () => {
    console.log('Reloading posts for servers', servers.map(s => s.server?.host));
    Promise.all(servers.map(server =>
      dispatch(loadPostsPage({ ...server, listingType })))
    ).then((results) => {
      console.log("Loaded posts", results);
      finishPagination(setLoadingPosts);
    });
  }

  return { results, loading, reload, hasMorePages, firstPageLoaded };
}

export function onPageLoaded(setLoading: (v: boolean) => void, onLoaded?: () => void) {
  return () => finishPagination(setLoading, onLoaded);
}

export function finishPagination(setLoading: (v: boolean) => void, onLoaded?: () => void) {
  setLoading(false);
  onLoaded?.();
}

export function useGroupPostPages(
  group: FederatedGroup | undefined,
  throughPage: number
): PaginationResults<FederatedPost> {
  const { dispatch, accountOrServer } = useCredentialDispatch();
  const state = useRootSelector((state: RootState) => state);
  const [loading, setLoadingPosts] = useState(false);

  if (!group) return { results: [], loading: false, reload: () => { }, hasMorePages: false, firstPageLoaded: true };

  const results: FederatedPost[] = getGroupPostPages(state, group, throughPage);

  const firstPageLoaded = getHasGroupPostsPage(state.groups, group, 0);
  useEffect(() => {
    if (!firstPageLoaded && !loading) {
      if (!accountOrServer.server) return;

      console.log("Loading group posts...");
      setLoadingPosts(true);
      reload();
    }
  });

  const hasMorePages = getHasMoreGroupPostPages(state.groups, group, throughPage);

  const reload = () => {
    dispatch(loadGroupPostsPage({ ...accountOrServer, groupId: group.id })).then(onPageLoaded(setLoadingPosts));
  }

  return { results, loading, reload, hasMorePages, firstPageLoaded };
}
