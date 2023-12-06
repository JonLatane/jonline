
//TODO: Move hook from app/store to here

import { AccountOrServer, AppDispatch, FederatedEntity, HasIdFromServer, accountID, selectAllAccounts, selectAllServers, serverID } from 'app/store';
import { useAppDispatch, useAppSelector } from "./store_hooks";


export const useAccount = () =>
  useAppSelector(state =>
    // pinnedServer
    // ? selectAllAccounts(state.accounts).find(a => accountID(a) === pinnedServer.accountId)
    // : 
    state.accounts.account
  );
export const useServer = () =>
  useAppSelector(state =>
    // pinnedServer
    //   ? selectAllServers(state.servers).find(s => serverID(s) === pinnedServer.serverId)
    //   : 
    state.servers.server
  );
export function useAccountOrServer(): AccountOrServer {
  return {
    account: useAccount(),
    server: useServer()
  };
}

export function useCurrentAndPinnedServers(): AccountOrServer[] {
  const accountOrServer = useAccountOrServer();
  const { server } = accountOrServer;
  const pinnedServers = useAppSelector(state =>
    state.accounts.pinnedServers
      .filter(ps => ps.pinned && (!server || ps.serverId !== serverID(server)))
      .map(pinnedServer => ({
        account: selectAllAccounts(state.accounts).find(a => accountID(a) === pinnedServer.accountId),
        server: selectAllServers(state.servers).find(s => serverID(s) === pinnedServer.serverId)
      }))
      .filter(aos => aos.server)
  );
  return [accountOrServer, ...pinnedServers];
}

export function useFederatedAccountOrServer<T extends HasIdFromServer>(entity: FederatedEntity<T>): AccountOrServer {
  const currentAndPinnedServers = useCurrentAndPinnedServers();
  const hostname = entity.serverHost;
  return currentAndPinnedServers.find(aos => aos.server?.host === hostname) ?? {};
}

export type CredentialDispatch = {
  dispatch: AppDispatch;
  accountOrServer: AccountOrServer;
};
export function useCredentialDispatch(): CredentialDispatch {
  return {
    dispatch: useAppDispatch(),
    accountOrServer: useAccountOrServer()
  };
}
