import { EventListingType, TimeFilter } from "@jonline/api";
import { useCredentialDispatch, usePinnedAccountsAndServers, useFederatedDispatch } from "app/hooks";

import { debounce, useDebounce } from "@jonline/ui";
import { FederatedEvent, FederatedGroup, RootState, getEventsPages, getGroupEventPages, getHasEventsPage, getHasGroupEventsPage, getHasMoreEventPages, getHasMoreGroupEventPages, getServersMissingEventsPage, loadEventsPage, loadGroupEventsPage, serializeTimeFilter, someUnloaded, useRootSelector } from "app/store";
import { useEffect, useState } from "react";
import { optServerID } from '../../store/modules/servers_state';
import { PaginationResults } from "./pagination_hooks";
import { PostPageParams } from "./post_pagination_hooks";
import { finishPagination, onPageLoaded } from "./pagination_hooks";

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
  const servers = usePinnedAccountsAndServers();
  const eventsState = useRootSelector((state: RootState) => state.events);
  const [loading, setLoadingEvents] = useState(false);

  const timeFilter = serializeTimeFilter(params?.timeFilter);

  const results: FederatedEvent[] = getEventsPages(eventsState, listingType, timeFilter, throughPage, servers);

  const firstPageLoaded = getHasEventsPage(eventsState, listingType, timeFilter, 0, servers);
  const someUnloadedServers = someUnloaded(eventsState.pagesStatus, servers);
  const hasMorePages = getHasMoreEventPages(eventsState, listingType, timeFilter, throughPage, servers);
  const serversAllDefined = !servers.some(s => !s.server);

  const reload = () => {
    setLoadingEvents(true);
    const serversToUpdate = getServersMissingEventsPage(eventsState, listingType, timeFilter, 0, servers);
    console.log('Reloading events for servers', serversToUpdate.map(s => s.server?.host));
    Promise.all(serversToUpdate.map(server => {
      return dispatch(loadEventsPage({ ...server, listingType, filter: params?.timeFilter }));
    })).then((results) => {
      console.log("Loaded events", results);
      finishPagination(setLoadingEvents);
    });
  }
  const debounceReload = useDebounce(reload, 1000, { leading: true });

  useEffect(() => {
    if (!loading && serversAllDefined && (someUnloadedServers || !firstPageLoaded)) {
      setLoadingEvents(true);
      console.log("Loading events...");

      setTimeout(debounceReload, 1);
    }
  }, [serversAllDefined, loading, eventsState.pagesStatus, servers.map(s => s.server?.host).join(','), firstPageLoaded, someUnloadedServers]);

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


  const reload = () => {
    setLoadingEvents(true);
    if (group) dispatch(loadGroupEventsPage({
      ...accountOrServer,
      groupId: group.id,
      filter: params?.timeFilter
    })).then(onPageLoaded(setLoadingEvents));
  }
  const debounceReload = useDebounce(reload, 1000, { leading: true });

  useEffect(() => {
    if (group && !firstPageLoaded && !loading) {
      if (!accountOrServer.server) return;

      console.log("Loading events...");
      setLoadingEvents(true);
      setTimeout(debounceReload, 1);
    }
  }, [loading, optServerID(accountOrServer.server), group, timeFilter]);


  const results: FederatedEvent[] = getGroupEventPages(state, group, timeFilter, throughPage);
  const firstPageLoaded = getHasGroupEventsPage(state, group, timeFilter, 0);
  const hasMorePages = getHasMoreGroupEventPages(state.groups, group, timeFilter, throughPage);

  // console.log("useGroupEventPages", group, throughPage, results, hasMorePages, firstPageLoaded);
  return { results, loading, reload, hasMorePages, firstPageLoaded };
}
