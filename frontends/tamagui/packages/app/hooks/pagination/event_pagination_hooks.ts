import { Event, EventListingType, TimeFilter } from "@jonline/api";
import { useCredentialDispatch } from "app/hooks";

import { RootState, getEventPages, getGroupEventPages, getHasEventsPage, getHasGroupEventsPage, getHasMoreEventPages, getHasMoreGroupEventPages, loadEventsPage, loadGroupEventsPage, serializeTimeFilter, useRootSelector } from "app/store";
import { useEffect, useState } from "react";
import { optServerID } from '../../store/modules/servers_state';
import { PostPageParams, onPageLoaded } from "./post_pagination_hooks";

export type EventPageParams = PostPageParams & { filter?: TimeFilter };

export function useEventPages(listingType: EventListingType, throughPage: number, params?: EventPageParams) {
  const { dispatch, accountOrServer } = useCredentialDispatch();
  const eventsState = useRootSelector((state: RootState) => state.events);
  const [loadingEvents, setLoadingEvents] = useState(false);

  const timeFilter = serializeTimeFilter(params?.filter);

  const events: Event[] = getEventPages(eventsState, listingType, timeFilter, throughPage);

  const firstPageLoaded = getHasEventsPage(eventsState, listingType, timeFilter, 0);
  useEffect(() => {
    if (!firstPageLoaded && eventsState.loadStatus !== 'loading' && !loadingEvents) {
      if (!accountOrServer.server) return;

      console.log("Loading events...");
      setLoadingEvents(true);
      reloadEvents();
    }
  });
  const hasMorePages = getHasMoreEventPages(eventsState, listingType, timeFilter, throughPage);

  function reloadEvents() {
    dispatch(loadEventsPage({ ...accountOrServer, listingType, filter: params?.filter })).then(onPageLoaded(setLoadingEvents, params?.onLoaded));
  }

  return { events, loadingEvents, reloadEvents, hasMorePages, firstPageLoaded };
}

export function useGroupEventPages(groupId: string, throughPage: number, params?: EventPageParams) {
  const { dispatch, accountOrServer } = useCredentialDispatch();
  const state = useRootSelector((state: RootState) => state);
  const [loadingEvents, setLoadingEvents] = useState(false);

  const timeFilter = serializeTimeFilter(params?.filter);

  const events: Event[] = getGroupEventPages(state, groupId, timeFilter, throughPage);

  const firstPageLoaded = getHasGroupEventsPage(state, groupId, timeFilter, 0);
  useEffect(() => {
    if (!firstPageLoaded && !loadingEvents) {
      if (!accountOrServer.server) return;

      console.log("Loading events...");
      setLoadingEvents(true);
      reloadEvents();
    }
  }, [loadingEvents, optServerID(accountOrServer.server), groupId, timeFilter]);
  const hasMorePages = getHasMoreGroupEventPages(state.groups, groupId, timeFilter, throughPage);

  function reloadEvents() {
    dispatch(loadGroupEventsPage({ ...accountOrServer, groupId, filter: params?.filter }))
      .then(onPageLoaded(setLoadingEvents, params?.onLoaded));
  }

  console.log("useGroupEventPages", groupId, throughPage, events, hasMorePages, firstPageLoaded);
  return { events, loadingEvents, reloadEvents, hasMorePages, firstPageLoaded };
}
