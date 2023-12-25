import { Event, EventListingType, TimeFilter } from "@jonline/api";
import { useCredentialDispatch, useCurrentAndPinnedServers } from "app/hooks";

import { FederatedEvent, RootState, getEventPages, getGroupEventPages, getHasEventsPage, getHasGroupEventsPage, getHasMoreEventPages, getHasMoreGroupEventPages, loadEventsPage, loadGroupEventsPage, serializeTimeFilter, someUnloaded, useRootSelector } from "app/store";
import { useEffect, useState } from "react";
import { optServerID } from '../../store/modules/servers_state';
import { PostPageParams, finishPagination, onPageLoaded } from "./post_pagination_hooks";
import { PaginationResults } from "./pagination_hooks";

export type EventPageParams = PostPageParams & { filter?: TimeFilter };

export function useEventPages(
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
      finishPagination(setLoadingEvents, params?.onLoaded);
    });
  }

  return { results, loading, reload, hasMorePages, firstPageLoaded };
}

export function useGroupEventPages(groupId: string | undefined, throughPage: number, params?: EventPageParams): PaginationResults<FederatedEvent> {
  const { dispatch, accountOrServer } = useCredentialDispatch();
  const state = useRootSelector((state: RootState) => state);
  const [loading, setLoadingEvents] = useState(false);

  if (!groupId) return { results: [], loading: false, reload: () => { }, hasMorePages: false, firstPageLoaded: false };

  const timeFilter = serializeTimeFilter(params?.filter);

  const results: FederatedEvent[] = getGroupEventPages(state, groupId, timeFilter, throughPage);

  const firstPageLoaded = getHasGroupEventsPage(state, groupId, timeFilter, 0);
  useEffect(() => {
    if (!firstPageLoaded && !loading) {
      if (!accountOrServer.server) return;

      console.log("Loading events...");
      setLoadingEvents(true);
      reload();
    }
  }, [loading, optServerID(accountOrServer.server), groupId, timeFilter]);
  const hasMorePages = getHasMoreGroupEventPages(state.groups, groupId, timeFilter, throughPage);

  function reload() {
    dispatch(loadGroupEventsPage({ ...accountOrServer, groupId: groupId!, filter: params?.filter }))
      .then(onPageLoaded(setLoadingEvents, params?.onLoaded));
  }

  console.log("useGroupEventPages", groupId, throughPage, results, hasMorePages, firstPageLoaded);
  return { results, loading, reload, hasMorePages, firstPageLoaded };
}
