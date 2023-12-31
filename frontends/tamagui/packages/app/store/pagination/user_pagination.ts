import { User, UserListingType } from "@jonline/api";
import { useAccountOrServer } from "app/hooks";
import { federatedEntities, getFederated } from "../federation";
import { FederatedUser, UsersState, selectUserById } from "../modules";
import { AccountOrServer } from "../types";

export function getUsersPage(
  state: UsersState,
  listingType: UserListingType,
  page: number,
  pinnedServers: AccountOrServer[]
): FederatedUser[] | undefined {
  const servers = pinnedServers;
  const users = [] as FederatedUser[];
  for (const { server } of servers) {
    const federatedPages = getFederated(state.userPages, server);
    const serverUserIds: string[] | undefined = (federatedPages[listingType] ?? [])[page];
    if (serverUserIds === undefined) {
      return undefined;
    }
    const serverUsers = serverUserIds.map(id => selectUserById(state, id)).filter(u => u) as User[];
    users.push(...federatedEntities(serverUsers, server));
  }

  return users;
}
