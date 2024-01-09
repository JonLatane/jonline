import { EventListingType, TimeFilter } from "@jonline/api";
import { useCredentialDispatch, useCurrentAndPinnedServers, useFederatedDispatch } from "app/hooks";

import { FederatedEvent, FederatedGroup, RootState, getEventPages, getGroupEventPages, getHasEventsPage, getHasGroupEventsPage, getHasMoreEventPages, getHasMoreGroupEventPages, loadEventsPage, loadGroupEventsPage, serializeTimeFilter, someUnloaded, useRootSelector } from "app/store";
import { useEffect, useState } from "react";
import { optServerID } from '../../store/modules/servers_state';
import { PaginationResults } from "./pagination_hooks";
import { PostPageParams, finishPagination, onPageLoaded } from "./post_pagination_hooks";

export type EventPageParams = PostPageParams & { timeFilter?: TimeFilter };

export function useEventPages(
  listingType: EventListingType,
  selectedGroup: FederatedGroup | undefined,
  params?: EventPageParams,
): PaginationResults<FederatedEvent> {
  const [currentPage, setCurrentPage] = useState(0);

  const mainPostPages = useServerEventPages(listingType, currentPage, params);
  const groupPostPages = useGroupEventPages(selectedGroup, currentPage, params);

  return selectedGroup
    ? groupPostPages
    : mainPostPages;
}

export function useServerEventPages(
  listingType: EventListingType,
  throughPage: number,
  params?: EventPageParams
): PaginationResults<FederatedEvent> {
  const { dispatch, accountOrServer: currentAccountOrServer } = useCredentialDispatch();
  const servers = useCurrentAndPinnedServers();
  const eventsState = useRootSelector((state: RootState) => state.events);
  const [loading, setLoadingEvents] = useState(false);

  const timeFilter = serializeTimeFilter(params?.timeFilter);

  const results: FederatedEvent[] = getEventPages(eventsState, listingType, timeFilter, throughPage, servers);

  const firstPageLoaded = getHasEventsPage(eventsState, listingType, timeFilter, 0, servers);
  const someUnloadedServers = someUnloaded(eventsState.pagesStatus, servers);
  // console.log('useServerEventPages', firstPageLoaded, someUnloadedServers);
  // debugger;
  useEffect(() => {
    if (!loading && (someUnloadedServers || !firstPageLoaded)) {
      setLoadingEvents(true);
      console.log("Loading events...");
      reload();
    }
  }, [loading, eventsState.pagesStatus, servers.map(s => s.server?.host).join(','), firstPageLoaded, someUnloadedServers]);
  const hasMorePages = getHasMoreEventPages(eventsState, listingType, timeFilter, throughPage, servers);

  function reload() {
    // dispatch(loadEventsPage({ ...accountOrServer, listingType, filter: params?.filter })).then(onPageLoaded(setLoadingEvents, params?.onLoaded));
    console.log('Reloading events for servers', servers.map(s => s.server?.host));
    Promise.all(servers.map(server =>
      dispatch(loadEventsPage({ ...server, listingType, filter: params?.timeFilter })))
    ).then((results) => {
      console.log("Loaded events", results);
      finishPagination(setLoadingEvents);
    });
  }

  return { results, loading, reload, hasMorePages, firstPageLoaded };
}

export function useGroupEventPages(
  group: FederatedGroup | undefined,
  throughPage: number,
  params?: EventPageParams
): PaginationResults<FederatedEvent> {
  if (!group) return { results: [], loading: false, reload: () => { }, hasMorePages: false, firstPageLoaded: false };

  const { dispatch, accountOrServer } = useFederatedDispatch(group);
  const state = useRootSelector((state: RootState) => state);
  const [loading, setLoadingEvents] = useState(false);


  const timeFilter = serializeTimeFilter(params?.timeFilter);

  const results: FederatedEvent[] = getGroupEventPages(state, group, timeFilter, throughPage);

  const firstPageLoaded = getHasGroupEventsPage(state, group, timeFilter, 0);
  useEffect(() => {
    if (!firstPageLoaded && !loading) {
      if (!accountOrServer.server) return;

      console.log("Loading events...");
      setLoadingEvents(true);
      reload();
    }
  }, [loading, optServerID(accountOrServer.server), group, timeFilter]);
  const hasMorePages = getHasMoreGroupEventPages(state.groups, group, timeFilter, throughPage);

  const reload = () => {
    dispatch(loadGroupEventsPage({ ...accountOrServer, groupId: group.id!, filter: params?.timeFilter }))
      .then(onPageLoaded(setLoadingEvents));
  }

  // debugger;
  console.log("useGroupEventPages", group, throughPage, results, hasMorePages, firstPageLoaded);
  return { results, loading, reload, hasMorePages, firstPageLoaded };
}
