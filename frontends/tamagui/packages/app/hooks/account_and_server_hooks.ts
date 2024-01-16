import { Post } from '@jonline/api/index';
import { useAccountOrServerContext } from 'app/contexts';
import { AccountOrServer, AppDispatch, FederatedEntity, HasIdFromServer, JonlineServer, accountID, getCachedServerClient, selectAccountById, selectAllAccounts, selectAllServers, selectServerById, serverID } from 'app/store';
import { useAppDispatch, useAppSelector } from "./store_hooks";
import { server } from '../../../apps/expo/metro.config';


export const useAccount = () => useAppSelector(state => state.accounts.currentAccountId ? selectAccountById(state.accounts, state.accounts.currentAccountId) : undefined);
export const useServer = () => useAppSelector(state => state.servers.currentServerId ? selectServerById(state.servers, state.servers.currentServerId) : undefined);
export function useAccountOrServer(): AccountOrServer {
  return {
    account: useAccount(),
    server: useServer()
  };
}

export function useCurrentAndPinnedServers(args?: { includeUnpinned?: boolean; }): AccountOrServer[] {
  const accountOrServer = useAccountOrServer();
  const { server } = accountOrServer;
  const pinnedServers = useAppSelector(state =>
    state.accounts.pinnedServers
      .filter(ps => (ps.pinned || args?.includeUnpinned) && (!server || ps.serverId !== serverID(server)))
      .map(pinnedServer => ({
        account: selectAllAccounts(state.accounts).find(a => accountID(a) === pinnedServer.accountId && !a.needsReauthentication),
        server: selectAllServers(state.servers).find(s => serverID(s) === pinnedServer.serverId)
      }))
      .filter(aos => aos.server)
  );
  const excludeCurrentServer = useAppSelector(state => state.accounts.excludeCurrentServer);
  return excludeCurrentServer && !args?.includeUnpinned
    ? pinnedServers
    : [accountOrServer, ...pinnedServers];
}

export function useFederatedAccountOrServer<T extends HasIdFromServer>(entity: FederatedEntity<T> | string | undefined): AccountOrServer {
  const currentAndPinnedServers = useCurrentAndPinnedServers({includeUnpinned: true});
  const currentAccountOrServer = useAccountOrServer();
  if (!entity) return currentAccountOrServer;

  const host = typeof entity === 'string' ? entity : entity.serverHost;
  const pinnedAccountOrServer = currentAndPinnedServers.find(aos => aos.server?.host === host);

  const serverClient = getCachedServerClient({ host, secure: true });
  const temporaryServer: JonlineServer = serverClient
    ? { ...serverClient, host, secure: true, }
    : { host, secure: true };

  if (currentAccountOrServer.server?.host === host) {
    return currentAccountOrServer;
  }

  // debugger;

  return pinnedAccountOrServer ?? { server: temporaryServer };
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

/**
 * Returns 
 * @param entity Any Federated entity
 * @returns An AppDispatch and the appropriate AccountOrServer to view/edit the given entity
 */
export function useFederatedDispatch<T extends HasIdFromServer>(
  entity: FederatedEntity<T> | string | undefined
): CredentialDispatch {
  return {
    dispatch: useAppDispatch(),
    accountOrServer: useFederatedAccountOrServer(entity)
  };
}

/**
 * TODO: Implementation update: Maybe this should resolve from pinned accounts when server is overridden? Current functionality doesn't need this.
 * 
 * @param serverOverride An optional server to use instead of the one from the AccountOrServerContext or the Redux store state.
 * @returns 
 */
export function useProvidedDispatch(serverOverride?: JonlineServer): CredentialDispatch {
  const currentAccountOrServer = useAccountOrServer();
  const accountOrServerContext = useAccountOrServerContext();
  const accountOrServer = accountOrServerContext ?? currentAccountOrServer;
  const dispatch = useAppDispatch();
  if (serverOverride) {
    if (serverOverride.host === accountOrServer.server?.host) {
      return { dispatch, accountOrServer };
    } else {
      return { dispatch, accountOrServer: { account: undefined, server: serverOverride } };
    }
  }
  return { dispatch, accountOrServer };
}

export function usePostDispatch(post: Post): CredentialDispatch {
  const currentAccountOrServer = useAccountOrServer();
  const accountOrServerContext = useAccountOrServerContext();
  const serverHost = 'serverHost' in post
    ? post.serverHost as string
    : accountOrServerContext?.server?.host ?? currentAccountOrServer.server?.host;
  // const accountOrServer = useFederatedAccountOrServer(serverHost);

  return useFederatedDispatch(serverHost);
}
