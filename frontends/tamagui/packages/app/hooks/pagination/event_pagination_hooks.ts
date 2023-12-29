import { Event, EventListingType, TimeFilter } from "@jonline/api";
import { useCredentialDispatch, useCurrentAndPinnedServers } from "app/hooks";

import { FederatedEvent, FederatedGroup, RootState, getEventPages, getGroupEventPages, getHasEventsPage, getHasGroupEventsPage, getHasMoreEventPages, getHasMoreGroupEventPages, loadEventsPage, loadGroupEventsPage, serializeTimeFilter, someUnloaded, useRootSelector } from "app/store";
import { useEffect, useState } from "react";
import { optServerID } from '../../store/modules/servers_state';
import { PostPageParams, finishPagination, onPageLoaded } from "./post_pagination_hooks";
import { PaginationResults } from "./pagination_hooks";

export type EventPageParams = PostPageParams & { filter?: TimeFilter };

export function useEventPages(
  listingType: EventListingType,
  selectedGroup: FederatedGroup | undefined,
): PaginationResults<FederatedEvent> {
  const [currentPage, setCurrentPage] = useState(0);

  const mainPostPages = useServerEventPages(listingType, currentPage);
  const groupPostPages = useGroupEventPages(selectedGroup, currentPage);

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

  const timeFilter = serializeTimeFilter(params?.filter);

  const results: FederatedEvent[] = getEventPages(eventsState, listingType, timeFilter, throughPage, servers);

  const firstPageLoaded = getHasEventsPage(eventsState, listingType, timeFilter, 0, servers);
  // debugger;
  useEffect(() => {
    if (!loading && someUnloaded(eventsState.pagesStatus, servers)) {
      setLoadingEvents(true);
      console.log("Loading events...");
      reload();
    }
  }, [loading, eventsState.pagesStatus, servers.map(s => s.server?.host).join(',')]);
  const hasMorePages = getHasMoreEventPages(eventsState, listingType, timeFilter, throughPage, servers);

  function reload() {
    // dispatch(loadEventsPage({ ...accountOrServer, listingType, filter: params?.filter })).then(onPageLoaded(setLoadingEvents, params?.onLoaded));
    console.log('Reloading events for servers', servers.map(s => s.server?.host));
    Promise.all(servers.map(server =>
      dispatch(loadEventsPage({ ...server, listingType })))
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
  const { dispatch, accountOrServer } = useCredentialDispatch();
  const state = useRootSelector((state: RootState) => state);
  const [loading, setLoadingEvents] = useState(false);

  if (!group) return { results: [], loading: false, reload: () => { }, hasMorePages: false, firstPageLoaded: false };

  const timeFilter = serializeTimeFilter(params?.filter);

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
    dispatch(loadGroupEventsPage({ ...accountOrServer, groupId: group.id!, filter: params?.filter }))
      .then(onPageLoaded(setLoadingEvents));
  }

  console.log("useGroupEventPages", group, throughPage, results, hasMorePages, firstPageLoaded);
  return { results, loading, reload, hasMorePages, firstPageLoaded };
}
