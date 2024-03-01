import { getFederated } from "../federation";
import { FederatedMedia, MediaState, selectMediaById } from "../modules";
import { AccountOrServer } from "../types";

/**
 * Pagination state building block, accessed via <code>number</code> rather than <code>string</code> keys.
 * I.E: An array of the form: <code> [["mediaId1", "mediaId2"], ["mediaId3"]]</code> (with "implicit" pagesize 2), just as a `Dictionary`
 * for serializability. Access looks like: <code> pages[0] -> ["mediaId1", "mediaId2"], pages[1] -> ["mediaId3"]</code>.
 * 
 * We trust that the server will return the same consistent pagination data, and if not, "refresh the page to see the updated version"
 * is a reasonable fallback.
 */
export function getMediaPages(media: MediaState, throughPage: number, servers: AccountOrServer[]): FederatedMedia[] {
  const result: FederatedMedia[] = [];
  for (let page = 0; page <= throughPage; page++) {
    const pageMedia = getMediaPage(media, page, servers);
    result.push(...pageMedia);
  }
  return result;
}

function getMediaPage(media: MediaState, page: number, servers: AccountOrServer[]): FederatedMedia[] {
  const pageMediaIds: string[] = servers.flatMap(server => {
    const serverMediaPages = getFederated(media.userMediaPages, server.server);
    const userId = server.account?.user.id ?? '';
    return (serverMediaPages[userId] ?? {})[page] ?? [];
  });
  const pageMedia = pageMediaIds.map(id => selectMediaById(media, id))
    .filter(p => p) as FederatedMedia[];
  pageMedia.sort((a, b) => (b.createdAt ?? '').localeCompare(a.createdAt ?? ''));
  return pageMedia;
}

export function getHasMediaPage(media: MediaState, page: number, servers: AccountOrServer[]): boolean {
  return !servers.some(isMissingServerPage(media, page));
}

export function getServersMissingMediaPage(media: MediaState, page: number, servers: AccountOrServer[]): AccountOrServer[] {
  return servers.filter(isMissingServerPage(media, page));
}

function isMissingServerPage(media: MediaState, page: number) {
  return (server: AccountOrServer) => {
    if (!server.account) return false;

    const serverMediaPages = getFederated(media.userMediaPages, server.server);
    const userId = server.account?.user.id ?? '';
    // debugger;
    return (serverMediaPages[userId] ?? {})[page] === undefined;
  }
}

export function getHasMoreMediaPages(media: MediaState, currentPage: number, servers: AccountOrServer[]): boolean {
  return servers.some(server => {
    const userId = server.account?.user.id ?? '';
    return server.server
      ? ((media.userMediaPages[server.server!.host]?.[userId] ?? {})[currentPage]?.length ?? 0) > 0
      : false;
  });
}
