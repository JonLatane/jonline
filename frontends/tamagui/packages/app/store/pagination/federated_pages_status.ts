import { Federated, createFederated } from "../federation";
import { AccountOrServer } from "../types";


export type PagesStatus = "unloaded" | "loading" | "loaded" | "errored";

export type FederatedPagesStatus = Federated<PagesStatus>;

/**
 * Create a `FederatedValue` with a default value and no server-specific values.
 * @param defaultValue 
 * @returns 
 */
export const createFederatedPagesStatus: () => FederatedPagesStatus = () => createFederated("unloaded");

export function someUnloaded(pagesStatus: FederatedPagesStatus, servers: AccountOrServer[]): boolean {
  for (const [server, status] of Object.entries(pagesStatus.values)) {
    if (["unloaded", undefined].includes(status) && servers.some(s => s.server?.host === server)) {
      console.log("server is unloaded", server);
      return true;
    }
  }
  for (const server of servers) {
    if (!server.server || !pagesStatus.values[server.server.host]) {
      console.log("server is unloaded", server.server!.host);
      return true;
    }
  }
  return false;
}