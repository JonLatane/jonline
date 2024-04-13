import { Moderation, User, UserListingType } from "@jonline/api";
import { federateId, federatedEntities, getFederated, parseFederatedId } from "../federation";
import { FederatedUser, UsersState, selectUserById } from "../modules";
import { AccountOrServer } from "../types";
import { RootState } from "../store";

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
    if (!server) continue;

    const federatedPages = getFederated(state.userPages, server);
    const serverUserIds: string[] | undefined = (federatedPages[listingType] ?? [])[page];
    if (serverUserIds === undefined) {
      // return undefined;
      hadUndefinedServers = true;
      // console.log("Undefined server", server);
      continue;
    }
    const serverUsers = serverUserIds.map(id => selectUserById(state, id)).filter(u => u) as User[];
    users.push(...federatedEntities(serverUsers, server));
  }
  // if (hadUndefinedServers && users.length === 0) return undefined;

  return { users, hadUndefinedServers };
}

export function getMembersPage(
  state: RootState,
  groupId: string,
  page: number,
  groupModeration?: Moderation
): { users: FederatedUser[], hadUndefinedServers: boolean } {
  const moderation = groupModeration ?? Moderation.MODERATION_UNKNOWN;
  const memberships = state.groups.groupMembershipPages[groupId]?.[moderation]?.[page];
  const { serverHost } = parseFederatedId(groupId);
  const users = memberships?.map(m => {
    const user = selectUserById(state.users, federateId(m.userId, serverHost));
    if (!user) {
      return undefined;
    }

    return {
      ...user,
      currentGroupMembership: m
    } as FederatedUser;
  })?.filter(u => u) as FederatedUser[] | undefined;

  console.log("members page", groupId, page, memberships, users);

  return {
    users: users ?? [],
    hadUndefinedServers: users === undefined
  };
}
