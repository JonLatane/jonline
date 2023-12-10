import { Post, PostListingType } from "@jonline/api";
import { useCredentialDispatch } from "app/hooks";
import { RootState, getGroupPostPages, getHasGroupPostsPage, getHasMoreGroupPostPages, getHasMorePostPages, getHasPostsPage, getPostPages, loadGroupPostsPage, loadPostsPage, useRootSelector } from "app/store";
import { useEffect, useState } from "react";
import { useCurrentAndPinnedServers } from './account_and_server_hooks';
import { someUnloaded } from '../store/pagination/federated_pages_status';

export type PostPageParams = { onLoaded?: () => void };

export function usePostPages(listingType: PostListingType, throughPage: number, params?: PostPageParams) {
  const { dispatch, accountOrServer: currentAccountOrServer } = useCredentialDispatch();
  // const servers = pinnedServers ?? [currentAccountOrServer];
  const servers = useCurrentAndPinnedServers();
  const postsState = useRootSelector((state: RootState) => state.posts);
  const [loadingPosts, setLoadingPosts] = useState(false);

  const posts: Post[] = getPostPages(postsState, listingType, throughPage, servers);

  useEffect(() => {
    if (someUnloaded(postsState.pagesStatus, servers) && !loadingPosts) {
      // if (!accountOrServer.server) return;

      console.log("Loading posts...");
      setLoadingPosts(true);
      reloadPosts();
    }
    // else if (postsState.pagesStatus == 'loaded' && loadingPosts) {
    //   setLoadingPosts(false);
    //   onLoaded?.();
    // }
  });

  const firstPageLoaded = getHasPostsPage(postsState, listingType, 0, servers);
  const hasMorePages = getHasMorePostPages(postsState, listingType, throughPage, servers);

  function reloadPosts() {
    Promise.all(servers.map(pinnedServer =>
      dispatch(loadPostsPage({ ...pinnedServer, listingType })).then(finishPagination(setLoadingPosts, params?.onLoaded))
        .then((results) => {
          console.log("Loaded posts", results);
          finishPagination(setLoadingPosts, params?.onLoaded);
        })));
    // dispatch(loadPostsPage({ ...accountOrServer, listingType })).then(finishPagination(setLoadingPosts, params?.onLoaded));
  }

  return { posts, loadingPosts, reloadPosts, hasMorePages, firstPageLoaded };
}

export function finishPagination(setLoading: (v: boolean) => void, onLoaded?: () => void) {
  return () => {
    setLoading(false);
    onLoaded?.();
  };
}

export function useGroupPostPages(groupId: string, throughPage: number, params?: PostPageParams) {
  const { dispatch, accountOrServer } = useCredentialDispatch();
  const state = useRootSelector((state: RootState) => state);
  const [loadingPosts, setLoadingPosts] = useState(false);

  const postList: Post[] = getGroupPostPages(state, groupId, throughPage);

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

  function reloadPosts() {
    dispatch(loadGroupPostsPage({ ...accountOrServer, groupId })).then(finishPagination(setLoadingPosts, params?.onLoaded));
  }

  return { posts: postList, loadingPosts: loadingPosts || state.groups.postPageStatus == 'loading', reloadPosts, hasMorePages, firstPageLoaded };
}
