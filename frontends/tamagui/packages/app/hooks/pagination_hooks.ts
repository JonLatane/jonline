import { Event, EventListingType, Post, PostListingType } from "@jonline/api";
import { RootState, getEventPages, getGroupEventPages, getGroupPostPages, getHasEventsPage, getHasGroupEventsPage, getHasGroupPostsPage, getHasMoreEventPages, getHasMoreGroupEventPages, getHasMoreGroupPostPages, getHasMorePostPages, getHasPostsPage, getPostPages, loadEventsPage, loadGroupEventsPage, loadGroupPostsPage, loadPostsPage, useCredentialDispatch, useTypedSelector } from "app/store";
import { useEffect, useState } from "react";

export function usePostPages(listingType: PostListingType, throughPage: number, onLoaded?: () => void) {
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
    } else if (postsState.baseStatus == 'loaded' && loadingPosts) {
      setLoadingPosts(false);
      onLoaded?.();
    }
  });

  const firstPageLoaded = getHasPostsPage(postsState, listingType, 0);
  const hasMorePages = getHasMorePostPages(postsState, listingType, throughPage);

  function reloadPosts() {
    dispatch(loadPostsPage({ ...accountOrServer, listingType }))
  }

  return { posts, loadingPosts, reloadPosts, hasMorePages, firstPageLoaded };
}

export function useEventPages(listingType: EventListingType, throughPage: number, onLoaded?: () => void) {
  const { dispatch, accountOrServer } = useCredentialDispatch();
  const eventsState = useTypedSelector((state: RootState) => state.events);
  const [loadingEvents, setLoadingEvents] = useState(false);

  const events: Event[] = getEventPages(eventsState, listingType, throughPage);

  useEffect(() => {
    if (eventsState.loadStatus == 'unloaded' && !loadingEvents) {
      if (!accountOrServer.server) return;

      console.log("Loading events...");
      setLoadingEvents(true);
      reloadEvents();
    } else if (eventsState.loadStatus == 'loaded' && loadingEvents) {
      setLoadingEvents(false);
      onLoaded?.();
    }
  });
  const firstPageLoaded = getHasEventsPage(eventsState, listingType, 0)
  const hasMorePages = getHasMoreEventPages(eventsState, listingType, throughPage);

  function reloadEvents() {
    dispatch(loadEventsPage({ ...accountOrServer, listingType }))
  }

  return { events, loadingEvents, reloadEvents, hasMorePages, firstPageLoaded };
}


export function useGroupPostPages(groupId: string, throughPage: number, onLoaded?: () => void) {
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
    } else if (state.posts.baseStatus == 'loaded' && loadingPosts) {
      setLoadingPosts(false);
      onLoaded?.();
    }
  });

  const hasMorePages = getHasMoreGroupPostPages(state.groups, groupId, throughPage);

  function reloadPosts() {
    dispatch(loadGroupPostsPage({ ...accountOrServer, groupId }))
  }

  return { posts: postList, loadingPosts, reloadPosts, hasMorePages, firstPageLoaded };
}

export function useGroupEventPages(groupId: string, throughPage: number, onLoaded?: () => void) {
  const { dispatch, accountOrServer } = useCredentialDispatch();
  const state = useTypedSelector((state: RootState) => state);
  const [loadingEvents, setLoadingEvents] = useState(false);

  const events: Event[] = getGroupEventPages(state, groupId, throughPage);

  const firstPageLoaded = getHasGroupEventsPage(state.groups, groupId, 0);
  useEffect(() => {
    if (!firstPageLoaded && !loadingEvents) {
      if (!accountOrServer.server) return;

      console.log("Loading events...");
      setLoadingEvents(true);
      reloadEvents();
    } else if (state.events.loadStatus == 'loaded' && loadingEvents) {
      setLoadingEvents(false);
      onLoaded?.();
    }
  });

  const hasMorePages = getHasMoreGroupEventPages(state.groups, groupId, throughPage);

  function reloadEvents() {
    dispatch(loadGroupEventsPage({ ...accountOrServer, groupId }))
  }

  return { events, loadingEvents, reloadEvents, hasMorePages, firstPageLoaded };
}
