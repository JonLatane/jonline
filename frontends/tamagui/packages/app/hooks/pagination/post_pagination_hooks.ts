import { Post, PostListingType } from "@jonline/api";
import { useCredentialDispatch, useForceUpdate } from "app/hooks";
import { FederatedPost, RootState, getGroupPostPages, getHasGroupPostsPage, getHasMoreGroupPostPages, getHasMorePostPages, getHasPostsPage, getPostPages, loadGroupPostsPage, loadPostsPage, useRootSelector } from "app/store";
import { useEffect, useState } from "react";
import { useCurrentAndPinnedServers } from '../account_and_server_hooks';
import { someUnloaded } from '../../store/pagination/federated_pages_status';
import { PaginationResults } from "./pagination_hooks";

export type PostPageParams = { onLoaded?: () => void };

export function usePostPages(
  listingType: PostListingType,
  throughPage: number,
  params?: PostPageParams
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
      finishPagination(setLoadingPosts, params?.onLoaded);
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
  groupId: string | undefined,
  throughPage: number,
  params?: PostPageParams
): PaginationResults<FederatedPost> {
  const { dispatch, accountOrServer } = useCredentialDispatch();
  const state = useRootSelector((state: RootState) => state);
  const [loading, setLoadingPosts] = useState(false);

  if (!groupId) return { results: [], loading: false, reload: () => { }, hasMorePages: false, firstPageLoaded: false };

  const results: FederatedPost[] = getGroupPostPages(state, groupId, throughPage);

  const firstPageLoaded = getHasGroupPostsPage(state.groups, groupId, 0);
  useEffect(() => {
    if (!firstPageLoaded && !loading) {
      if (!accountOrServer.server) return;

      console.log("Loading group posts...");
      setLoadingPosts(true);
      reload();
    }
  });

  const hasMorePages = getHasMoreGroupPostPages(state.groups, groupId, throughPage);

  const reload = () => {
    dispatch(loadGroupPostsPage({ ...accountOrServer, groupId })).then(onPageLoaded(setLoadingPosts, params?.onLoaded));
  }

  return { results, loading, reload, hasMorePages, firstPageLoaded };
}
