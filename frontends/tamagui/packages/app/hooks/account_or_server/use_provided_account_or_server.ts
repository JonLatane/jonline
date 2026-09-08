import { useAccountOrServerContext } from 'app/contexts';
import { AccountOrServer, RellmServer } from 'app/store';
import { useCurrentAccountOrServer } from './use_current_account_or_server';


export function useProvidedAccountOrServer(serverOverride?: RellmServer): AccountOrServer {
  const currentAccountOrServer = useCurrentAccountOrServer();
  const accountOrServerContext = useAccountOrServerContext();
  const accountOrServer = accountOrServerContext ?? currentAccountOrServer;
  if (serverOverride) {
    if (serverOverride.host === accountOrServer.server?.host) {
      return accountOrServer;
    } else {
      return { account: undefined, server: serverOverride };
    }
  }
  return accountOrServer;
}
