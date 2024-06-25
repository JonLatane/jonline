import { createSelector } from '@reduxjs/toolkit';
import { AccountOrServer, JonlineServer, PinnedServer, RootState, accountID, selectAllAccounts, selectAllServers, serverID, unpinAccount } from 'app/store';
import { useEffect } from 'react';
import { Selector, useAppDispatch, useAppSelector } from "../store_hooks";
import { useCurrentAccountOrServer } from './use_current_account_or_server';



export function usePinnedAccountsAndServers(args?: { includeUnpinned?: boolean; }): AccountOrServer[] {
  const excludeCurrentServer = useAppSelector(state => state.accounts.excludeCurrentServer);
  const dispatch = useAppDispatch();
  const accountOrServer = useCurrentAccountOrServer();
  const { server } = accountOrServer;
  const pinnedServers = useAppSelector(state => state.accounts.pinnedServers);
  const pinnedAccountsAndServers: AccountOrServer[] = useAppSelector(selectPinnedAccountsAndServers(server, pinnedServers, args));
  // useAppSelector(state => pinnedServers
  //   .filter(ps => (ps.pinned || args?.includeUnpinned) && (!server || ps.serverId !== serverID(server)))
  //   .map(pinnedServer => ({
  //     account: selectAllAccounts(state.accounts).find(a => accountID(a) === pinnedServer.accountId /* && !a.needsReauthentication*/),
  //     server: selectAllServers(state.servers).find(s => serverID(s) === pinnedServer.serverId)
  //   }))
  //   .filter(aos => aos.server)
  // );
  const pinnedAccountNeedsReauthentication = pinnedAccountsAndServers
    .some(aos => aos.account?.needsReauthentication);
  // console.log('pinnedAccountNeedsReauthentication', pinnedAccountNeedsReauthentication);
  useEffect(() => {
    if (pinnedAccountNeedsReauthentication) {
      pinnedAccountsAndServers.filter(aos => aos.account?.needsReauthentication).forEach(aos => {
        if (!aos.server || !aos.account) return;

        const serverId = serverID(aos.server);
        const pinned = !!pinnedServers.find(ps => ps.serverId === serverId)?.pinned;
        if (pinned) {
          dispatch(unpinAccount(aos.account));
        }
      });
    }
  }, [pinnedAccountNeedsReauthentication]);


  return excludeCurrentServer && !args?.includeUnpinned
    ? pinnedAccountsAndServers
    : [accountOrServer, ...pinnedAccountsAndServers];
}

const selectPinnedAccountsAndServers = (
  server: JonlineServer | undefined,
  pinnedServers: PinnedServer[],
  args?: { includeUnpinned?: boolean; }
): Selector<AccountOrServer[]> =>
  createSelector(
    [(state: RootState) => pinnedServers
      .filter(ps => (ps.pinned || args?.includeUnpinned) && (!server || ps.serverId !== serverID(server)))
      .map(pinnedServer => ({
        account: selectAllAccounts(state.accounts).find(a => accountID(a) === pinnedServer.accountId /* && !a.needsReauthentication*/),
        server: selectAllServers(state.servers).find(s => serverID(s) === pinnedServer.serverId)
      }))
      .filter(aos => aos.server)],
    (data) => data
  );
