import { EventListingType, Group, TimeFilter } from "@jonline/api";
import { Selector, useAppSelector, useCredentialDispatch, useFederatedDispatch, usePinnedAccountsAndServers } from "app/hooks";

import { useDebounce, useForceUpdate } from "@jonline/ui";
import { createSelector } from "@reduxjs/toolkit";
import { FederatedEvent, FederatedGroup, RootState, getEventsPages, getGroupEventPages, getHasEventsPage, getHasGroupEventsPage, getHasMoreEventPages, getHasMoreGroupEventPages, getServersMissingEventsPage, loadEventsPage, loadGroupEventsPage, serializeTimeFilter, someLoading, someUnloaded } from "app/store";
import { useEffect, useMemo, useState } from "react";
import { optServerID } from '../../store/modules/servers_state';
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

export type LoadingMutex = { loading: boolean };
export const createLoadingManager = (): LoadingMutex => ({ loading: false });
export const startLoading = (mutex: LoadingMutex) => mutex.loading = true;
export const finishLoading = (mutex: LoadingMutex) => mutex.loading = false;
export const isLoading = (mutex: LoadingMutex) => mutex.loading;
// export async function loadingDone(mutex: LoadingMutex, pagesStatusCheck: () => FederatedPagesStatus, servers: AccountOrServer[]) {
//   while (mutex.loading || someLoading(pagesStatusCheck(), servers)) {
//     await new Promise(resolve => setTimeout(resolve, 100));
//   }
// }

const loadingMutex: LoadingMutex = createLoadingManager();

export function useServerEventPages(
  listingType: EventListingType,
  throughPage: number,
  params?: EventPageParams
): PaginationResults<FederatedEvent> {
  const { dispatch, accountOrServer: currentAccountOrServer } = useCredentialDispatch();
  const servers = usePinnedAccountsAndServers();
  // const eventsState = useAppSelector(state => state.events);
  const loading = useAppSelector(state => someLoading(state.events.pagesStatus, servers));
  // const [loading, setLoadingEvents] = useState(false);

  const serversAllDefined = !servers.some(s => !s.server);
  const timeFilter = serializeTimeFilter(params?.timeFilter);
  const serversMissingEventsPage = useAppSelector(state =>
    getServersMissingEventsPage(state.events, listingType, timeFilter, 0, servers)
  );
  const needsLoading = serversMissingEventsPage.length > 0 && !loading && serversAllDefined;

  const results: FederatedEvent[] =
    // useMemo(
    //   () => 
    useAppSelector(state => {
      // console.trace('useServerEventPages: selecting events', state.events.ids.length);

      return getEventsPages(state.events, listingType, timeFilter, throughPage, servers);
    });
  //   ,
  //   [
  //     eventsState.ids,
  //     eventsState.pagesStatus,
  //     servers.map(s => [s.account?.user?.id, s.server?.host]),
  //     timeFilter,
  //     listingType,
  //     serversAllDefined,
  //     serversMissingEventsPage,
  //     needsLoading
  //   ]
  // );
  // console.trace('useServerEventPages: events', results.length);

  const firstPageLoaded = useAppSelector(state => getHasEventsPage(state.events, listingType, timeFilter, 0, servers));
  const someUnloadedServers = useAppSelector(state => someUnloaded(state.events.pagesStatus, servers));
  const hasMorePages = useAppSelector(state => getHasMoreEventPages(state.events, listingType, timeFilter, throughPage, servers));

  const forceUpdate = useForceUpdate();
  // console.log('useServerEventPages', {results, listingType, throughPage, params});
  const tryReload = () => {
    // console.log('useServerEventPages tryReload', { listingType, results, hasMorePages, firstPageLoaded, loading, serversAllDefined, someUnloadedServers, serversMissingEventsPage });

    setTimeout(forceUpdate, 100);
    // if (isLoading(loadingMutex)) {
    //   // setAwaitTime(awaitTime + 1);
    //   // setTimeout(tryReload, 100);
    //   // forceUpdate();
    //   requestAnimationFrame(forceUpdate);
    // } else {
    //   // forceUpdate();
    //   setTimeout(forceUpdate, 100);
    // }
  };//, [awaitTime, awaitTime, listingType, results, hasMorePages, firstPageLoaded, loading, serversAllDefined, someUnloadedServers, serversMissingEventsPage]);
  const [initiatedLoading, setInitiatedLoading] = useState(false);
  useEffect(() => { isLoading(loadingMutex) && !initiatedLoading ? tryReload() : undefined });

  const reload = (force?: boolean) => {
    if (loading) return;
    if (isLoading(loadingMutex)) {
      tryReload();
      // setTimeout(tryReload, 300);
      return;
    };

    setInitiatedLoading(true);
    startLoading(loadingMutex);
    const serversToUpdate = force ? servers : serversMissingEventsPage;
    if (serversToUpdate.length === 0) return;

    console.log('Reloading events for servers', serversToUpdate.map(s => s.server?.host));
    Promise.all(serversToUpdate.map(server => {
      return dispatch(loadEventsPage({ ...server, listingType, filter: params?.timeFilter, force }));
    })).then((results) => {
      console.log("Loaded events", results);
    }).finally(() => {
      finishLoading(loadingMutex);
      setInitiatedLoading(false);
    });
  }

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
