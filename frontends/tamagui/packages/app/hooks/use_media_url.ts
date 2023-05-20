import { JonlineServer, serverUrl, useCredentialDispatch } from 'app/store';

export function useMediaUrl(mediaId?: string, overrideServer?: JonlineServer): string | undefined {
  const { accountOrServer: { account, server: currentServer } } = useCredentialDispatch();
  const server = overrideServer ?? currentServer;
  if (!mediaId || mediaId == '') return undefined;

  if (account) {
    return `${serverUrl(account.server)}/media/${mediaId}?authorizaton=${account.accessToken.token}`;
  }
  return `${serverUrl(server!)}/media/${mediaId}`;
}
