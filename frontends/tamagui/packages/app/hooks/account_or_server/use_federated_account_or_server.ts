import { AccountOrServer, FederatedEntity, HasIdFromServer, JonlineServer, getCachedServerClient } from 'app/store';
import { useCurrentAccountOrServer } from './use_current_account_or_server';
import { usePinnedAccountsAndServers } from './use_pinned_accounts_and_servers';



export function useFederatedAccountOrServer<T extends HasIdFromServer>(entity: FederatedEntity<T> | string | undefined): AccountOrServer {
  const currentAndPinnedServers = usePinnedAccountsAndServers({ includeUnpinned: true });
  const currentAccountOrServer = useCurrentAccountOrServer();
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
