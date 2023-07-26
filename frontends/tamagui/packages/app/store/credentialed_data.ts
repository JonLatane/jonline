import { grpc } from "@improbable-eng/grpc-web";
import { ExpirableToken } from "@jonline/api";
import moment from "moment";
import 'react-native-get-random-values';
import { accountsSlice, getServerClient, resetEvents, resetGroups, resetMedia, resetPosts, resetUsers } from ".";
import { AppDispatch, RootState, store, useTypedDispatch, useTypedSelector } from "./store";
import { AccountOrServer, JonlineAccount, JonlineCredentialClient } from "./types";

export const useAccount = () => useTypedSelector((state: RootState) => state.accounts.account);
export const useServer = () => useTypedSelector((state: RootState) => state.servers.server);

export function useAccountOrServer(): AccountOrServer {
  return { account: useAccount(), server: useServer() };
}

export type CredentialDispatch = {
  dispatch: AppDispatch;
  accountOrServer: AccountOrServer;
};
export function useCredentialDispatch(): CredentialDispatch {
  return { dispatch: useTypedDispatch(), accountOrServer: useAccountOrServer() };
}

let _accessFetchLock = false;
let _newAccessToken: ExpirableToken | undefined = undefined;
let _newRefreshToken: ExpirableToken | undefined = undefined;

export function resetAccessTokens() {
  _newAccessToken = undefined;
  _newRefreshToken = undefined;
}
export async function getCredentialClient(accountOrServer: AccountOrServer): Promise<JonlineCredentialClient> {
  const { account: currentAccount, server } = accountOrServer;
  if (!currentAccount) {
    return getServerClient(server!);
  } else {
    let account: JonlineAccount = currentAccount;
    const client = await getServerClient(account.server);
    const metadata = new grpc.Metadata();
    const accessExpiresAt = moment.utc(account.accessToken.expiresAt);
    const now = moment.utc();
    const expired = accessExpiresAt.subtract(1, 'minutes').isBefore(now);
    if (expired) {
      let newAccessToken: ExpirableToken | undefined = undefined;
      let newRefreshToken: ExpirableToken | undefined = undefined;
      while (_accessFetchLock) {
        await new Promise(resolve => setTimeout(resolve, 100));
        newAccessToken = _newAccessToken;
        newRefreshToken = _newRefreshToken;
      }
      const newTokenExpired = !newAccessToken ||
        moment.utc(newAccessToken!.expiresAt).subtract(1, 'minutes').isBefore(now);
      if (newTokenExpired) {
        console.log(`Access token expired, refreshing..., now=${now}, expiresAt=${accessExpiresAt}`);
        _accessFetchLock = true;
        let { accessToken: fetchedAccessToken, refreshToken: fetchedRefreshToken } = await client.accessToken({ refreshToken: account.refreshToken!.token });
        newAccessToken = fetchedAccessToken!;
        _newAccessToken = newAccessToken;
        newRefreshToken = fetchedRefreshToken!;
        _newRefreshToken = newRefreshToken;
        _accessFetchLock = false;
        account = { ...account, accessToken: newAccessToken!, refreshToken: newRefreshToken ?? account.refreshToken! };
        store.dispatch(accountsSlice.actions.upsertAccount(account));
        metadata.append('authorization', account.accessToken.token);

        // Update the current user asynchronously.
        client.getCurrentUser({}, metadata).then(user => {
          account = { ...account, user };
          store.dispatch(accountsSlice.actions.upsertAccount(account));
        });
      } else {
        metadata.append('authorization', account.accessToken.token);
      }
      // account = { ...account, accessToken: newAccessToken! };
      // store.dispatch(accountsSlice.actions.upsertAccount(account));
    } else {
      metadata.append('authorization', account.accessToken.token);
    }
    // setCookie('jonline_access_token', account.accessToken.token);
    return { ...client, credential: metadata };
  }
}

export function useLoadingCredentialedData() {
  return useTypedSelector((state: RootState) => state.posts.status == 'loading'
    || state.groups.status == 'loading'
    || state.users.status == 'loading');
}

// Reset store data that depends on selected server/account.
export function resetCredentialedData() {
  setTimeout(() => {
    store.dispatch(resetMedia!());
    store.dispatch(resetPosts!());
    store.dispatch(resetEvents!());
    store.dispatch(resetGroups!());
    store.dispatch(resetUsers!());
  }, 1);
}
