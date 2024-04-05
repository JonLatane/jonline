import { useDebounce } from "@jonline/ui";
import { useAppDispatch } from "app/hooks";
import { FederatedMedia, RootState, getHasMediaPage, getHasMoreMediaPages, getMediaPages, getServersMissingMediaPage, loadMediaPage, useRootSelector } from "app/store";
import { useEffect, useState } from "react";
import { someUnloaded } from '../../store/pagination/federated_pages_status';
import { useProvidedDispatch } from '../credential_dispatch_hooks';
import { usePinnedAccountsAndServers } from '../account_or_server/use_pinned_accounts_and_servers';
import { useCurrentAccountOrServer } from '../account_or_server/use_current_account_or_server';
import { PaginationResults, finishPagination } from "./pagination_hooks";
import { useAccountOrServerContext } from "app/contexts";

export type MediaPageParams = {};

export function useMediaPages(): PaginationResults<FederatedMedia> {
  const [currentPage, setCurrentPage] = useState(0);

  const mainMediaPages = useServerMediaPages(currentPage);
  return mainMediaPages;
}

export function useServerMediaPages(
  throughPage: number
): PaginationResults<FederatedMedia> {
  const dispatch = useAppDispatch();
  //TODO: Eventually we should be able to show
  // media from multiple servers at once, but for now
  // keep it simple.
  // const servers = useCurrentAndPinnedServers();
  const accountOrServerContext = useAccountOrServerContext();
  const currentAccountOrServer = useCurrentAccountOrServer();
  const accountOrServer = accountOrServerContext ?? currentAccountOrServer;
  const servers = accountOrServer.account ? [accountOrServer] : [];
  //END TODO

  const mediaState = useRootSelector((state: RootState) => state.media);
  const [loading, setLoading] = useState(false);

  const results: FederatedMedia[] = getMediaPages(mediaState, throughPage, servers);
  const firstPageLoaded = getHasMediaPage(mediaState, 0, servers);
  const hasMorePages = getHasMoreMediaPages(mediaState, throughPage, servers);
  const serversAllDefined = !servers.some(s => !s.server);

  const reload = () => {
    setLoading(true);
    const serversToUpdate = servers;//getServersMissingMediaPage(mediaState, 0, servers);
    console.log('Reloading media for servers', serversToUpdate.map(s => s.server?.host));
    Promise.all(serversToUpdate.map(server => {
      const userId = server.account?.user.id;
      if (userId) {
        dispatch(loadMediaPage({ ...server, userId }));
      }
    })
    ).then((results) => {
      console.log("Loaded media", results);
      finishPagination(setLoading);
    });
  }
  const debounceReload = useDebounce(reload, 1000, { leading: true });

  useEffect(() => {
    if (!loading && serversAllDefined
      && someUnloaded(mediaState.pagesStatus, servers.filter(s => s.account))) {
      setLoading(true);
      // debugger;
      console.log("Loading media...");
      setTimeout(debounceReload, 1);
    }
  }, [serversAllDefined, loading, mediaState.pagesStatus, servers.map(s => s.server?.host).join(',')]);

  return { results, loading, reload, hasMorePages, firstPageLoaded };
}
