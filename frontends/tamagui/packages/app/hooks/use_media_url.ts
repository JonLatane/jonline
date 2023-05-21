import { AccountOrServer, JonlineServer, serverUrl, useCredentialDispatch } from 'app/store';

export function useMediaUrl(mediaId?: string, override?: AccountOrServer): string | undefined {
  const { accountOrServer: { account: currentAccount, server: currentServer } } = useCredentialDispatch();
  const {account: overrideAccount, server: overrideServer} = override ?? {};

  const account = overrideAccount ?? currentAccount;
  const server = overrideServer ?? currentServer;
  if (!mediaId || mediaId == '') return undefined;

  if (account) {
    return `${serverUrl(server!)}/media/${mediaId}?authorizaton=${account.accessToken.token}`;
  }
  return `${serverUrl(server!)}/media/${mediaId}`;
}
