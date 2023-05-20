import { serverUrl, useCredentialDispatch } from 'app/store';

export function useMediaUrl(mediaId: string | undefined): string | undefined {
  const { accountOrServer: { account, server } } = useCredentialDispatch();
  if (!mediaId || mediaId == '') return undefined;

  if (account) {
    return `${serverUrl(account.server)}/media/${mediaId}?authorizaton=${account.accessToken.token}`;
  }
  return `${serverUrl(server!)}/media/${mediaId}`;
}
