import { JonlineServer, RootState, selectCreationServer, selectServerById } from 'app/store';
import { Selector, useAppDispatch, useAppSelector } from "../store_hooks";
import { usePinnedAccountsAndServers } from './use_pinned_accounts_and_servers';
import { useCallback } from 'react';
import { createSelector } from '@reduxjs/toolkit';


export type AppCreationServer = {
  creationServer: JonlineServer | undefined;
  setCreationServer: (s: JonlineServer | undefined) => {
    payload: JonlineServer | undefined;
    type: "servers/selectCreationServer";
  };
};

export function useCreationServer(): AppCreationServer {
  const dispatch = useAppDispatch();
  const setCreationServer = useCallback((s: JonlineServer | undefined) => dispatch(selectCreationServer(s)), []);
  return useAppSelector(creationServerSelector(setCreationServer));
};

export const useCreationAccountOrServer = () => {
  const { creationServer } = useCreationServer();
  return usePinnedAccountsAndServers({ includeUnpinned: true })
    .find(aos => aos.server?.host === creationServer?.host)
    ?? {};
};

const creationServerSelector = (
  setCreationServer: (s: JonlineServer | undefined) => {
    payload: JonlineServer | undefined;
    type: "servers/selectCreationServer";
  }
): Selector<AppCreationServer> =>
  createSelector(
    [(state: RootState) => {
      const creationServer = state.servers.creationServerId
        ? selectServerById(state.servers, state.servers.creationServerId)
        : undefined;
      return { creationServer, setCreationServer };
    }],
    (data) => data
  );