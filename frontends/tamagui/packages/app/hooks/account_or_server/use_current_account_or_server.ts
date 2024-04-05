import { AccountOrServer, selectAccount, selectAccountById, selectServerById } from 'app/store';
import { useAppDispatch, useAppSelector } from "../store_hooks";
import { useEffect } from 'react';
import { current } from '@reduxjs/toolkit';


export function useCurrentAccountId() {
  const currentAccountId = useAppSelector(state => {
    const currentServerId = state.servers.currentServerId;
    const result = state.accounts.pinnedServers.find(
      ps => ps.serverId === currentServerId
    )?.accountId;
    // debugger;
    // console.log('useCurrentAccountId state.accounts.pinnedServers', currentServerId, result, state.accounts.pinnedServers);
    return result;
  });

  return currentAccountId;
}
export const useCurrentAccount = () => {
  const currentAccountId = useCurrentAccountId();
  const dispatch = useAppDispatch();
  const account = useAppSelector(state => currentAccountId
    ? selectAccountById(state.accounts, currentAccountId)
    : undefined);

  useEffect(() => {
    if (account?.needsReauthentication) {
      dispatch(selectAccount(undefined));
    }
  }, [account?.needsReauthentication]);
  return account;
};

export const useCurrentServer = () => useAppSelector(state => state.servers.currentServerId ? selectServerById(state.servers, state.servers.currentServerId) : undefined);

export function useCurrentAccountOrServer(): AccountOrServer {
  return {
    account: useCurrentAccount(),
    server: useCurrentServer()
  };
}
