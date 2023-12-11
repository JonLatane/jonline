import { Post, PostListingType } from "@jonline/api";
import { useCredentialDispatch, useForceUpdate } from "app/hooks";
import { FederatedPost, RootState, getGroupPostPages, getHasGroupPostsPage, getHasMoreGroupPostPages, getHasMorePostPages, getHasPostsPage, getPostPages, loadGroupPostsPage, loadPostsPage, useRootSelector } from "app/store";
import { useEffect, useState } from "react";
import { useCurrentAndPinnedServers } from '../account_and_server_hooks';
import { someUnloaded } from '../../store/pagination/federated_pages_status';

export type PostPageParams = { onLoaded?: () => void };

export function usePostPages(listingType: PostListingType, throughPage: number, params?: PostPageParams) {
  const { dispatch, accountOrServer: currentAccountOrServer } = useCredentialDispatch();
  // const servers = pinnedServers ?? [currentAccountOrServer];
  const servers = useCurrentAndPinnedServers();
  const postsState = useRootSelector((state: RootState) => state.posts);
  const [loadingPosts, setLoadingPosts] = useState(false);

  const posts: FederatedPost[] = getPostPages(postsState, listingType, throughPage, servers);

  useEffect(() => {
    console.log('usePostPages', servers.map(s => s.server?.host).join(','), someUnloaded(postsState.pagesStatus, servers));
    if (!loadingPosts && someUnloaded(postsState.pagesStatus, servers)) {
      // debugger;
      setLoadingPosts(true);
      // debugger;
      // if (!accountOrServer.server) return;

      console.log("Loading posts...");
      setTimeout(reloadPosts, 1);
    }
    // else if (postsState.pagesStatus == 'loaded' && loadingPosts) {
    //   setLoadingPosts(false);
    //   onLoaded?.();
    // }
  }, [loadingPosts, postsState.pagesStatus, servers.map(s => s.server?.host).join(',')]);

  const firstPageLoaded = getHasPostsPage(postsState, listingType, 0, servers);
  const hasMorePages = getHasMorePostPages(postsState, listingType, throughPage, servers);

  const reloadPosts = () => {
    console.log('Reloading posts for servers', servers.map(s => s.server?.host));
    Promise.all(servers.map(server =>
      dispatch(loadPostsPage({ ...server, listingType })))
    )//.then(finishPagination(setLoadingPosts, params?.onLoaded))
      .then((results) => {
        console.log("Loaded posts", results);
        finishPagination(setLoadingPosts, params?.onLoaded);
      });
    // dispatch(loadPostsPage({ ...accountOrServer, listingType })).then(finishPagination(setLoadingPosts, params?.onLoaded));
  }

  return { posts, loadingPosts, reloadPosts, hasMorePages, firstPageLoaded };
}

export function onPageLoaded(setLoading: (v: boolean) => void, onLoaded?: () => void) {
  return () => finishPagination(setLoading, onLoaded);
}

export function finishPagination(setLoading: (v: boolean) => void, onLoaded?: () => void) {
  setLoading(false);
  onLoaded?.();
}

export function useGroupPostPages(groupId: string | undefined, throughPage: number, params?: PostPageParams) {
  const { dispatch, accountOrServer } = useCredentialDispatch();
  const state = useRootSelector((state: RootState) => state);
  const [loadingPosts, setLoadingPosts] = useState(false);

  if (!groupId) return { posts: [], loadingPosts: false, reloadPosts: () => { }, hasMorePages: false, firstPageLoaded: false };

  const postList: FederatedPost[] = getGroupPostPages(state, groupId, throughPage);

  const firstPageLoaded = getHasGroupPostsPage(state.groups, groupId, 0);
  useEffect(() => {
    if (!firstPageLoaded && !loadingPosts) {
      if (!accountOrServer.server) return;

      console.log("Loading group posts...");
      setLoadingPosts(true);
      reloadPosts();
    }
  });

  const hasMorePages = getHasMoreGroupPostPages(state.groups, groupId, throughPage);

  const reloadPosts = () => {
    dispatch(loadGroupPostsPage({ ...accountOrServer, groupId })).then(onPageLoaded(setLoadingPosts, params?.onLoaded));
  }

  return { posts: postList, loadingPosts: loadingPosts || state.groups.postPageStatus == 'loading', reloadPosts, hasMorePages, firstPageLoaded };
}
