import { Event, EventListingType, Post, PostListingType, TimeFilter } from "@jonline/api";
import { RootState, getEventPages, getGroupEventPages, getGroupPostPages, getHasEventsPage, getHasGroupEventsPage, getHasGroupPostsPage, getHasMoreEventPages, getHasMoreGroupEventPages, getHasMoreGroupPostPages, getHasMorePostPages, getHasPostsPage, getPostPages, loadEventsPage, loadGroupEventsPage, loadGroupPostsPage, loadPostsPage, useCredentialDispatch, useTypedSelector } from "app/store";
import { useEffect, useState } from "react";

export type PostPageParams = { onLoaded?: () => void };

export function usePostPages(listingType: PostListingType, throughPage: number, params?: PostPageParams) {
  const { dispatch, accountOrServer } = useCredentialDispatch();
  const postsState = useTypedSelector((state: RootState) => state.posts);
  const [loadingPosts, setLoadingPosts] = useState(false);

  const posts: Post[] = getPostPages(postsState, listingType, throughPage);

  useEffect(() => {
    if (postsState.baseStatus == 'unloaded' && !loadingPosts) {
      if (!accountOrServer.server) return;

      console.log("Loading posts...");
      setLoadingPosts(true);
      reloadPosts();
    }
    // else if (postsState.baseStatus == 'loaded' && loadingPosts) {
    //   setLoadingPosts(false);
    //   onLoaded?.();
    // }
  });

  const firstPageLoaded = getHasPostsPage(postsState, listingType, 0);
  const hasMorePages = getHasMorePostPages(postsState, listingType, throughPage);

  function reloadPosts() {
    dispatch(loadPostsPage({ ...accountOrServer, listingType })).then(finishPagination(setLoadingPosts, params?.onLoaded));
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
  const state = useTypedSelector((state: RootState) => state);
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
