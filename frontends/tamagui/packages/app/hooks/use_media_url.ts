import { AccountOrServer, JonlineServer, serverUrl, frontendServerUrl } from 'app/store';
import { useCredentialDispatch, useProvidedDispatch } from './credential_dispatch_hooks';

// Accepts either a bare media ID (for local Jonline media, fetched via `/media/{id}`) or a
// `Media`/`MediaReference`-like object, whose `url` (if set) is used directly instead -- used
// for media Jonline doesn't store locally, e.g. from federated ActivityPub/Mastodon or AT
// Protocol/Bluesky content.
type MediaUrlSource = string | { id?: string; url?: string } | undefined;

export function useMediaUrl(media?: MediaUrlSource, override?: AccountOrServer): string | undefined {
  try {
    const { accountOrServer: { account: currentAccount, server: currentServer } } = useProvidedDispatch();

    const { mediaId, url } = typeof media === 'string' ? { mediaId: media, url: undefined } : { mediaId: media?.id, url: media?.url };
    if (url) return url;
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
