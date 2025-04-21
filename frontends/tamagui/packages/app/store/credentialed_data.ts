import { AccessTokenResponse, ExpirableToken } from "@jonline/api";
import { useDebounceValue } from "@jonline/ui";
import moment from "moment";
import { Metadata } from "nice-grpc-web";
import 'react-native-get-random-values';
import { JonlineClientCreationArgs, accountID, accountsSlice, getServerClient, resetEvents, resetGroups, resetMedia, resetPosts, resetUsers, serverID } from ".";
import { store } from "./store";
import { AccountOrServer, JonlineAccount, JonlineCredentialClient } from "./types";

const updatedTokenKey = (accountOrServer: AccountOrServer) => `${accountOrServer.account ? accountID(accountOrServer.account) : ""}@${accountOrServer.server ? serverID(accountOrServer.server) : ""}`;
const updatedAccessTokens = new Map<string, { accessToken: ExpirableToken, refreshToken: ExpirableToken | undefined }>();
export function resetAccessTokens() {
  updatedAccessTokens.clear();
}
export async function getCredentialClient(accountOrServer: AccountOrServer, args?: JonlineClientCreationArgs): Promise<JonlineCredentialClient> {
  const { account: account, server } = accountOrServer;
  const client = await getServerClient(server!, args);
  if (!account) {
    return client;
  } else {
    let updatedAccount: JonlineAccount = { ...account };
    const metadata = Metadata();
    const accessExpiresAt = moment.utc(account.accessToken.expiresAt);
    const now = moment.utc();
    const expired = true;//accessExpiresAt.subtract(2, 'minutes').isBefore(now);

    if (expired) {
      const updatedAccessToken: ExpirableToken | undefined = updatedAccessTokens.get(updatedTokenKey(accountOrServer))?.accessToken;
      if (updatedAccessToken) {
        metadata.append('authorization', updatedAccessToken.token);
      } else {
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
              return result;
            })
            .catch(async (e) => {
              console.log("failed to load access token with refresh token ", { error: e, token: account.refreshToken, tokenKey: updatedTokenKey(accountOrServer) });

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

        updatedAccessTokens.set(updatedTokenKey(accountOrServer), { accessToken: accessTokenResult.accessToken!, refreshToken: accessTokenResult.refreshToken });
        metadata.append('authorization', accessTokenResult.accessToken!.token);

        setTimeout(() => {
          store.dispatch(accountsSlice.actions.upsertAccount(updatedAccount));
        }, 1000);
      }
    } else {
      metadata.append('authorization', account.accessToken.token);
    }

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