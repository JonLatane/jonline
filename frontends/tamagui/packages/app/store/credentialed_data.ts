import { AccessTokenResponse, ExpirableToken } from "@jonline/api";
import { useDebounceValue } from "@jonline/ui";
import moment from "moment";
import { Metadata } from "nice-grpc-web";
import 'react-native-get-random-values';
import { JonlineClientCreationArgs, accountID, accountsSlice, getServerClient, resetEvents, resetGroups, resetMedia, resetPosts, resetUsers, serverID } from ".";
import { store } from "./store";
import { AccountOrServer, JonlineAccount, JonlineCredentialClient } from "./types";

// let _accessFetchLock = false;
// let _newAccessToken: ExpirableToken | undefined = undefined;
// let _newRefreshToken: ExpirableToken | undefined = undefined;
const updatedTokenKey = (accountOrServer: AccountOrServer) => `${accountOrServer.account ? accountID(accountOrServer.account) : ""}@${accountOrServer.server ? serverID(accountOrServer.server) : ""}`;
const updatedAccessTokens = new Map<string, { accessToken: ExpirableToken, refreshToken: ExpirableToken | undefined }>();
export function resetAccessTokens() {
  updatedAccessTokens.clear();
}
export async function getCredentialClient(accountOrServer: AccountOrServer, args?: JonlineClientCreationArgs): Promise<JonlineCredentialClient> {
  const { account: account, server } = accountOrServer;
  // debugger;
  if (!account) {
    return getServerClient(server!, args);
  } else {
    let updatedAccount: JonlineAccount = { ...account };
    const client = await getServerClient(account.server, args);
    const metadata = Metadata();
    const accessExpiresAt = moment.utc(account.accessToken.expiresAt);
    const now = moment.utc();
    const expired = accessExpiresAt.subtract(1, 'minutes').isBefore(now);
    // console.log(server?.host, "token expired:", expired);

    // function loadCurrentUser() {

    //   console.log("loading current user...");
    //   // Update the current user asynchronously.
    //   client.getCurrentUser({}, { metadata: Metadata({ authorization: updatedAccount.accessToken.token }) }).then(user => {
    //     console.log("loaded current user");
    //     updatedAccount = { ...updatedAccount, user, lastSyncFailed: false, needsReauthentication: false };
    //     store.dispatch(accountsSlice.actions.upsertAccount(updatedAccount));
    //     // debugger;
    //   }).catch((e) => {
    //     console.error("failed to load current user", updatedAccount.user.username, updatedAccount.accessToken.token, e);
    //     updatedAccount = { ...updatedAccount, lastSyncFailed: true, needsReauthentication: true };
    //     store.dispatch(accountsSlice.actions.upsertAccount(updatedAccount));
    //     // debugger;
    //   });
    // }
    if (expired) {
      let newAccessToken: ExpirableToken | undefined = updatedAccessTokens.get(updatedTokenKey(accountOrServer))?.accessToken;
      // let newRefreshToken: ExpirableToken | undefined = updatedAccessTokens.get(updatedTokenKey(accountOrServer))?.refreshToken;

      if (newAccessToken) {
        metadata.append('authorization', newAccessToken.token);
      } else {

        // console.log("blocking on access token refresh:", _accessFetchLock)
        // debugger;
        // while (_accessFetchLock) {
        //   await new Promise(resolve => setTimeout(resolve, 100));
        //   // newAccessToken = _newAccessToken;
        //   // newRefreshToken = _newRefreshToken;
        //   console.log("access token refresh blocking loop", { serverHost: server?.host });
        // }
        // _accessFetchLock = true;
        // try {
        // console.log("access token refresh unblocked", { serverHost: server?.host })
        // const newTokenExpired = !newAccessToken ||
        //   moment.utc(newAccessToken!.expiresAt).subtract(1, 'minutes').isBefore(now);

        // console.log("newTokenExpired:", newTokenExpired);
        // if (newTokenExpired) {
        // console.log(`Access token expired, refreshing..., now=${now}, expiresAt=${accessExpiresAt}`);
        let accessTokenResult: AccessTokenResponse | undefined = undefined;
        let retries = 0;
        const maxRetries = 3;
        while (!accessTokenResult && retries < maxRetries) {
          retries++;
          accessTokenResult = await client
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
              // store.dispatch(accountsSlice.actions.upsertAccount(updatedAccount));
              return result;
            })
            .catch(async (e) => {
              console.log("failed to load access token with refresh token ", { error: e, token: account.refreshToken, tokenKey: updatedTokenKey(accountOrServer) });
              // debugger;

              await new Promise((res) => setTimeout(res, 1000));

              return undefined;
            });
        }

        if (!accessTokenResult) {
          setTimeout(() => {
            updatedAccount = { ...account, lastSyncFailed: true, needsReauthentication: true };
            store.dispatch(accountsSlice.actions.upsertAccount(updatedAccount));
          }, 1000);
          return client;
        }

        // let { accessToken: fetchedAccessToken, refreshToken: fetchedRefreshToken } = accessTokenResult;
        // newAccessToken = fetchedAccessToken!;
        // _newAccessToken = newAccessToken;
        // newRefreshToken = fetchedRefreshToken!;
        // _newRefreshToken = newRefreshToken;
        updatedAccessTokens.set(updatedTokenKey(accountOrServer), { accessToken: accessTokenResult.accessToken!, refreshToken: accessTokenResult.refreshToken });

        // updatedAccount = { ...updatedAccount, accessToken: newAccessToken!, refreshToken: newRefreshToken ?? account.refreshToken! };
        metadata.append('authorization', account.accessToken.token);

        setTimeout(() => {
          store.dispatch(accountsSlice.actions.upsertAccount(updatedAccount));
          // loadCurrentUser()
        }, 1000);
        // } else {
        //   metadata.append('authorization', account.accessToken.token);
        // }
        // account = { ...account, accessToken: newAccessToken! };
        // store.dispatch(accountsSlice.actions.upsertAccount(account));
        // } finally {
        //   // console.log("unblocking access token refresh")
        //   // _accessFetchLock = false;
        // }
      }
    } else {
      // if (updatedAccount.lastSyncFailed || updatedAccount.needsReauthentication) {
      //   loadCurrentUser();
      // }
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
  }, 1000);
}
const pendingServerHostResets = new Set<string | undefined>();

// To be used when resetting data that depends on the selected server/account.
export function useDebouncedAccountOrServer(accountOrServer: AccountOrServer): { serverId: string | undefined, accountId: string | undefined } {
  const { server, account } = accountOrServer;
  return useDebounceValue({
    serverId: server ? serverID(server) : undefined,
    accountId: account ? accountID(account) : undefined
  }, 3000);
}