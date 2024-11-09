import { EventListingType, Group, TimeFilter } from "@jonline/api";
import { Selector, useAppSelector, useCredentialDispatch, useFederatedDispatch, usePinnedAccountsAndServers } from "app/hooks";

import { useDebounce } from "@jonline/ui";
import { createSelector } from "@reduxjs/toolkit";
import { FederatedEvent, FederatedGroup, RootState, getGroupEventPages, getHasEventsPage, getHasGroupEventsPage, getHasMoreEventPages, getHasMoreGroupEventPages, loadEventsPage, loadGroupEventsPage, selectEventPages, selectEventsLoading, selectServersMissingEventsPage, serializeTimeFilter, someUnloaded } from "app/store";
import { useEffect, useMemo, useState } from "react";
import { optServerID } from '../../store/modules/servers_state';
import { createLoadingMutex, useLoadingLock } from "./loading_mutex";
import { PaginationResults } from "./pagination_hooks";
import { PostPageParams } from "./post_pagination_hooks";

export type EventPageParams = PostPageParams & { timeFilter?: TimeFilter };

export function useEventPages(
  listingType: EventListingType,
  selectedGroup?: FederatedGroup,
  params?: EventPageParams,
): PaginationResults<FederatedEvent> {
  const [currentPage, setCurrentPage] = useState(0);

  const mainPostPages = useServerEventPages(listingType, currentPage, params);
  const groupPostPages = useGroupEventPages(selectedGroup, currentPage, params);

  return selectedGroup
    ? groupPostPages
    : mainPostPages;
}

const loadingMutex = createLoadingMutex();

export function useServerEventPages(
  listingType: EventListingType,
  throughPage: number,
  params?: EventPageParams
): PaginationResults<FederatedEvent> {
  const { dispatch, accountOrServer: currentAccountOrServer } = useCredentialDispatch();
  const servers = usePinnedAccountsAndServers();
  const loading = useAppSelector(state => selectEventsLoading(state, servers));

  const timeFilter = serializeTimeFilter(params?.timeFilter);
  const serversMissingEventsPage = useAppSelector(state =>
    selectServersMissingEventsPage(state, listingType, timeFilter, 0, servers)
  );

  const serversAllDefined = !servers.some(s => !s.server);
  const needsLoading = serversMissingEventsPage.length > 0 && !loading && serversAllDefined;

  const results: FederatedEvent[] = useAppSelector(state =>
    selectEventPages(state, listingType, timeFilter, throughPage, servers)
  );

  const firstPageLoaded = useAppSelector(state => getHasEventsPage(state.events, listingType, timeFilter, 0, servers));
  const someUnloadedServers = useAppSelector(state => someUnloaded(state.events.pagesStatus, servers));
  const hasMorePages = useAppSelector(state => getHasMoreEventPages(state.events, listingType, timeFilter, throughPage, servers));

  const { createReload } = useLoadingLock(loadingMutex);

  const reload = createReload(loading, async (force) => {
    const serversToUpdate = force ? servers : serversMissingEventsPage;
    if (serversToUpdate.length === 0) return;

    console.log('Reloading events for servers', serversToUpdate.map(s => s.server?.host));

    await Promise.all(serversToUpdate.map(server => {
      return dispatch(loadEventsPage({ ...server, listingType, filter: params?.timeFilter, force }));
    })).then((results) => {
      console.log("Loaded events", results);
    });
  });

  useEffect(() => {
    if (needsLoading) {
      reload();
    }
  }, [needsLoading]);

  return { results, loading, reload, hasMorePages, firstPageLoaded };
}

export function useGroupEventPages(
  group: FederatedGroup | undefined,
  throughPage: number,
  params?: EventPageParams
): PaginationResults<FederatedEvent> {

  const { dispatch, accountOrServer } = useFederatedDispatch(group);
  const [loading, setLoadingEvents] = useState(false);

  const timeFilter = serializeTimeFilter(params?.timeFilter);

  const reload = (_force?: boolean) => {
    setLoadingEvents(true);
    if (group) dispatch(loadGroupEventsPage({
      ...accountOrServer,
      groupId: group.id,
      filter: params?.timeFilter
    })).then(() => setLoadingEvents(false));
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

  const { results, firstPageLoaded, hasMorePages } = useAppSelector(selectGroupPages(group, timeFilter, throughPage));

  if (!group) return { results: [], loading: false, reload: () => { }, hasMorePages: false, firstPageLoaded: false };

  // console.log("useGroupEventPages", group, throughPage, results, hasMorePages, firstPageLoaded);
  return { results, loading, reload, hasMorePages, firstPageLoaded };
}


const selectGroupPages = (
  group: FederatedGroup | undefined,
  timeFilter: string,
  throughPage: number,
): Selector<Pick<PaginationResults<FederatedEvent>, 'results' | 'firstPageLoaded' | 'hasMorePages'>> =>
  createSelector(
    [(state: RootState) => {
      const defaultGroup: FederatedGroup = useMemo(() => ({ ...Group.create(), serverHost: '' }), []);
      const results: FederatedEvent[] = getGroupEventPages(state, group ?? defaultGroup, timeFilter, throughPage);
      const firstPageLoaded = getHasGroupEventsPage(state, group ?? defaultGroup, timeFilter, 0);
      const hasMorePages = getHasMoreGroupEventPages(state.groups, group ?? defaultGroup, timeFilter, throughPage);
      return { results, firstPageLoaded, hasMorePages };
    }],
    (data) => data
  );
