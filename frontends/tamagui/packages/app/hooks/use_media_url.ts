import { AccountOrServer, JonlineServer, serverUrl, frontendServerUrl } from 'app/store';
import { useCredentialDispatch, useProvidedDispatch } from './account_and_server_hooks';

export function useMediaUrl(mediaId?: string, override?: AccountOrServer): string | undefined {
  try {
    const { accountOrServer: { account: currentAccount, server: currentServer } } = useProvidedDispatch();

    if (!mediaId || mediaId == '') return undefined;

    const { account: overrideAccount, server: overrideServer } = override ?? {};

    const account = overrideAccount ?? currentAccount;
    const server = overrideServer ?? currentServer;

    if (account && !override) {
      return `${frontendServerUrl(server!)}/media/${mediaId}?authorization=${account.accessToken.token}`;
    }
    return `${frontendServerUrl(server!)}/media/${mediaId}`;
  } catch (e) {
    console.warn("useMediaUrl error:", e);
    return undefined;
  }

}
