import { Federated, createFederated, getFederated } from "../federation";
import { AccountOrServer } from "../types";


export type PagesStatus = "unloaded" | "loading" | "loaded" | "errored";

export type FederatedPagesStatus = Federated<PagesStatus>;

/**
 * Create a `FederatedValue` with a default value and no server-specific values.
 * @param defaultValue 
 * @returns 
 */
export const createFederatedPagesStatus: () => FederatedPagesStatus = () => createFederated("unloaded" as PagesStatus);

export function someLoading(pagesStatus: FederatedPagesStatus, servers: AccountOrServer[]): boolean {
  return someWithStatus('loading', pagesStatus, servers);
}

export function someUnloaded(pagesStatus: FederatedPagesStatus, servers: AccountOrServer[]): boolean {
  return someWithStatus('unloaded', pagesStatus, servers);
}

function someWithStatus(status: PagesStatus, pagesStatus: FederatedPagesStatus, servers: AccountOrServer[]): boolean {
  for (const server of servers) {
    if (!server.server) continue;

    const serverStatus = getFederated(pagesStatus, server.server);
    if (serverStatus === status) {
      return true;
    }
  }
  return false;
}