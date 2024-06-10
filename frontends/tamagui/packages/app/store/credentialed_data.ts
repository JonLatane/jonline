import { ExpirableToken } from "@jonline/api";
import moment from "moment";
import { Metadata } from "nice-grpc-web";
import 'react-native-get-random-values';
import { JonlineClientCreationArgs, accountsSlice, getServerClient, resetEvents, resetGroups, resetMedia, resetPosts, resetUsers } from ".";
import { store } from "./store";
import { AccountOrServer, JonlineAccount, JonlineCredentialClient } from "./types";

let _accessFetchLock = false;
let _newAccessToken: ExpirableToken | undefined = undefined;
let _newRefreshToken: ExpirableToken | undefined = undefined;

export function resetAccessTokens() {
  _newAccessToken = undefined;
  _newRefreshToken = undefined;
}
export async function getCredentialClient(accountOrServer: AccountOrServer, args?: JonlineClientCreationArgs): Promise<JonlineCredentialClient> {
  const { account: account, server } = accountOrServer;
  // debugger;
  if (!account) {
    return getServerClient(server!, args);
  } else {
    let updatedAccount: JonlineAccount = account;
    const client = await getServerClient(account.server, args);
    const metadata = Metadata();
    const accessExpiresAt = moment.utc(account.accessToken.expiresAt);
    const now = moment.utc();
    const expired = accessExpiresAt.subtract(1, 'minutes').isBefore(now);
    // console.log(server?.host, "token expired:", expired);

    function loadCurrentUser() {

      console.log("loading current user...");
      // Update the current user asynchronously.
      client.getCurrentUser({}, { metadata: Metadata({ authorization: updatedAccount.accessToken.token }) }).then(user => {
        console.log("loaded current user");
        updatedAccount = { ...updatedAccount, user, lastSyncFailed: false, needsReauthentication: false };
        store.dispatch(accountsSlice.actions.upsertAccount(updatedAccount));
        // debugger;
      }).catch((e) => {
        console.error("failed to load current user", updatedAccount.user.username, updatedAccount.accessToken.token, e);
        updatedAccount = { ...updatedAccount, lastSyncFailed: true, needsReauthentication: true };
        store.dispatch(accountsSlice.actions.upsertAccount(updatedAccount));
        // debugger;
      });
    }
    if (expired) {
      let newAccessToken: ExpirableToken | undefined = undefined;
      let newRefreshToken: ExpirableToken | undefined = undefined;
      // console.log("blocking on access token refresh:", _accessFetchLock)
      // debugger;
      while (_accessFetchLock) {
        await new Promise(resolve => setTimeout(resolve, 100));
        newAccessToken = _newAccessToken;
        newRefreshToken = _newRefreshToken;
      }
      _accessFetchLock = true;
      try {
        // console.log("access token refresh unblocked")
        const newTokenExpired = !newAccessToken ||
          moment.utc(newAccessToken!.expiresAt).subtract(1, 'minutes').isBefore(now);

        // console.log("newTokenExpired:", newTokenExpired);
        if (newTokenExpired) {
          console.log(`Access token expired, refreshing..., now=${now}, expiresAt=${accessExpiresAt}`);
          const accessTokenResult = await client
            .accessToken({ refreshToken: account.refreshToken!.token })
            .then((result) => {
              updatedAccount = {
                ...account,
                accessToken: result.accessToken ?? account.accessToken,
                refreshToken: result.refreshToken ?? account.refreshToken,
                lastSyncFailed: false,
                needsReauthentication: false
              };
              // debugger;
              store.dispatch(accountsSlice.actions.upsertAccount(updatedAccount));
              return result;
            })
            .catch((e) => {
              console.log("failed to load access token", e);
              // debugger;
              updatedAccount = { ...account, lastSyncFailed: true, needsReauthentication: true };
              store.dispatch(accountsSlice.actions.upsertAccount(updatedAccount));

              return undefined;
            });

          if (!accessTokenResult) {
            return getServerClient(server!);
          }

          let { accessToken: fetchedAccessToken, refreshToken: fetchedRefreshToken } = accessTokenResult;
          newAccessToken = fetchedAccessToken!;
          _newAccessToken = newAccessToken;
          newRefreshToken = fetchedRefreshToken!;
          _newRefreshToken = newRefreshToken;
          updatedAccount = { ...updatedAccount, accessToken: newAccessToken!, refreshToken: newRefreshToken ?? account.refreshToken! };
          store.dispatch(accountsSlice.actions.upsertAccount(updatedAccount));
          metadata.append('authorization', account.accessToken.token);

          loadCurrentUser();
        } else {
          metadata.append('authorization', account.accessToken.token);
        }
        // account = { ...account, accessToken: newAccessToken! };
        // store.dispatch(accountsSlice.actions.upsertAccount(account));
      } finally {
        // console.log("unblocking access token refresh")
        _accessFetchLock = false;
      }
    } else {
      if (updatedAccount.lastSyncFailed || updatedAccount.needsReauthentication) {
        loadCurrentUser();
      }
      metadata.append('authorization', account.accessToken.token);
    }
    // debugger;
    // setCookie('jonline_access_token', account.accessToken.token);
    return { ...client, credential: { metadata } };
  }
}

// Reset store data that depends on selected server/account. Debounced.
export function resetCredentialedData(serverHost: string | undefined) {
  if (pendingServerHostResets.has(serverHost)) return;
  if (!serverHost) return;

  pendingServerHostResets.add(serverHost);
  setTimeout(() => {
    console.log('resetting credentialed data for', serverHost)
    pendingServerHostResets.delete(serverHost);

    store.dispatch(resetMedia({ serverHost }));
    store.dispatch(resetEvents({ serverHost }));
    store.dispatch(resetPosts({ serverHost }));
    store.dispatch(resetGroups({ serverHost }));
    store.dispatch(resetUsers({ serverHost }));
  }, 2000);
}
const pendingServerHostResets = new Set<string | undefined>();
