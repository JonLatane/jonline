import { User, UserListingType } from "@jonline/api";
import { federatedEntities, getFederated } from "../federation";
import { FederatedUser, UsersState, selectUserById } from "../modules";
import { AccountOrServer } from "../types";

export function getUsersPage(
  state: UsersState,
  listingType: UserListingType,
  page: number,
  pinnedServers: AccountOrServer[]
): { users: FederatedUser[], hadUndefinedServers: boolean } {
  const servers = pinnedServers;
  const users = [] as FederatedUser[];
  let hadUndefinedServers = false;
  for (const { server } of servers) {
    const federatedPages = getFederated(state.userPages, server);
    const serverUserIds: string[] | undefined = (federatedPages[listingType] ?? [])[page];
    if (serverUserIds === undefined) {
      // return undefined;
      hadUndefinedServers = true;
      continue;
    }
    const serverUsers = serverUserIds.map(id => selectUserById(state, id)).filter(u => u) as User[];
    users.push(...federatedEntities(serverUsers, server));
  }
  // if (hadUndefinedServers && users.length === 0) return undefined;

  return { users, hadUndefinedServers };
}
