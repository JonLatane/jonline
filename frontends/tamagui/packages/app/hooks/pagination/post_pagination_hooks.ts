import { PostListingType } from "@jonline/api";
import { useDebounce } from "@jonline/ui";
import { useAppDispatch, useCredentialDispatch } from "app/hooks";
import { FederatedGroup, FederatedPost, RootState, getGroupPostPages, getHasGroupPostsPage, getHasMoreGroupPostPages, getHasMorePostPages, getHasPostsPage, getPostsPages, getServersMissingPostsPage, loadGroupPostsPage, loadPostsPage, useRootSelector } from "app/store";
import { useEffect, useState } from "react";
import { someUnloaded } from '../../store/pagination/federated_pages_status';
import { useCurrentAndPinnedServers, useFederatedDispatch } from '../account_and_server_hooks';
import { PaginationResults, finishPagination, onPageLoaded } from "./pagination_hooks";

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
  const dispatch = useAppDispatch();
  const servers = useCurrentAndPinnedServers();
  const postsState = useRootSelector((state: RootState) => state.posts);
  const [loading, setLoading] = useState(false);

  const results: FederatedPost[] = getPostsPages(postsState, listingType, throughPage, servers);
  const firstPageLoaded = getHasPostsPage(postsState, listingType, 0, servers);
  const hasMorePages = getHasMorePostPages(postsState, listingType, throughPage, servers);
  const serversAllDefined = !servers.some(s => !s.server);

  const reload = () => {
    setLoading(true);
    const serversToUpdate = getServersMissingPostsPage(postsState, listingType, 0, servers);
    console.log('Reloading posts for servers', serversToUpdate.map(s => s.server?.host));
    Promise.all(serversToUpdate.map(server =>
      dispatch(loadPostsPage({ ...server, listingType })))
    ).then((results) => {
      console.log("Loaded posts", results);
      finishPagination(setLoading);
    });
  }
  const debounceReload = useDebounce(reload, 1000, { leading: true });

  useEffect(() => {
    if (!loading && serversAllDefined && someUnloaded(postsState.pagesStatus, servers)) {
      setLoading(true);
      console.log("Loading posts...");
      setTimeout(debounceReload, 1);
    }
  }, [serversAllDefined, loading, postsState.pagesStatus, servers.map(s => s.server?.host).join(',')]);

  return { results, loading, reload, hasMorePages, firstPageLoaded };
}

export function useGroupPostPages(
  group: FederatedGroup | undefined,
  throughPage: number
): PaginationResults<FederatedPost> {
  if (!group) return { results: [], loading: false, reload: () => { }, hasMorePages: false, firstPageLoaded: true };

  const { dispatch, accountOrServer } = useFederatedDispatch(group);
  const state = useRootSelector((state: RootState) => state);
  const [loading, setLoadingPosts] = useState(false);

  const reload = () => {
    setLoadingPosts(true);
    if (group) dispatch(loadGroupPostsPage({ ...accountOrServer, groupId: group.id })).then(onPageLoaded(setLoadingPosts));
  }
  const debounceReload = useDebounce(reload, 1000, { leading: true });

  useEffect(() => {
    if (!firstPageLoaded && !loading) {
      if (!accountOrServer.server) return;

      console.log("Loading group posts...");
      setLoadingPosts(true);
      setTimeout(debounceReload, 1);
    }
  });


  const results: FederatedPost[] = getGroupPostPages(state, group, throughPage);
  const firstPageLoaded = getHasGroupPostsPage(state.groups, group, 0);
  const hasMorePages = getHasMoreGroupPostPages(state.groups, group, throughPage);

  return { results, loading, reload, hasMorePages, firstPageLoaded };
}
