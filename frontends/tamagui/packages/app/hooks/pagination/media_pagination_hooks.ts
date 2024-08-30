import { useDebounce } from "@jonline/ui";
import { useAccountOrServerContext } from "app/contexts";
import { useAppDispatch, useCreationAccountOrServer } from "app/hooks";
import { FederatedMedia, RootState, getHasMediaPage, getHasMoreMediaPages, getMediaPages, loadMediaPage, useRootSelector } from "app/store";
import { useEffect, useState } from "react";
import { someLoading, someUnloaded } from '../../store/pagination/federated_pages_status';
import { PaginationResults } from "./pagination_hooks";

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
  const currentAccountOrServer = useCreationAccountOrServer();
  const accountOrServer = accountOrServerContext ?? currentAccountOrServer;
  const servers = accountOrServer.account ? [accountOrServer] : [];
  //END TODO

  const mediaState = useRootSelector((state: RootState) => state.media);
  // const [loading, setLoading] = useState(false);
  const loading = someLoading(mediaState.pagesStatus, servers);

  const results: FederatedMedia[] = getMediaPages(mediaState, throughPage, servers);
  const firstPageLoaded = getHasMediaPage(mediaState, 0, servers);
  const hasMorePages = getHasMoreMediaPages(mediaState, throughPage, servers);
  const serversAllDefined = !servers.some(s => !s.server);

  const reload = () => {
    if (loading) return;

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
    });
  }

  useEffect(() => {
    if (!loading && serversAllDefined
      && someUnloaded(mediaState.pagesStatus, servers.filter(s => s.account))
    ) {

      console.log("Loading media...");
      reload();
    }
  }, [serversAllDefined, loading, mediaState.pagesStatus, servers.map(s => s.server?.host).join(',')]);

  return { results, loading, reload, hasMorePages, firstPageLoaded };
}
