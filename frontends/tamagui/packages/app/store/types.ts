import { ExpirableToken, GetServiceVersionResponse, ServerConfiguration, User } from "@jonline/api";
import { JonlineClient } from "@jonline/api/generated/jonline";
import { CallOptions } from "nice-grpc-web";
import { FederatedUser, accountID, serverID } from "./modules";

export type JonlineServer = {
  host: string;
  secure: boolean;
  serviceVersion?: GetServiceVersionResponse;
  serverConfiguration?: ServerConfiguration;
  lastConnectionFailed?: boolean;
}

// The type used to store accounts locally. Keyed by server URL + user ID.
export type JonlineAccount = {
  user: User;
  refreshToken: ExpirableToken;
  accessToken: ExpirableToken;
  server: JonlineServer;
  lastSynced?: number;
  needsReauthentication?: boolean;
  lastSyncFailed?: boolean;
  pushSubscription?: PushSubscription;
}

// Note that this is inclusive-or. The account, if provided, should always have the same server as the server field.
export type AccountOrServer = {
  account?: JonlineAccount;
  server?: JonlineServer;
};

export function accountOrServerId(accountOrServer: AccountOrServer): string {
  if (accountOrServer.account) {
    return `account-${accountID(accountOrServer.account)}`;
  }
  if (accountOrServer.server) {
    return `server-${serverID(accountOrServer.server!)}`;
  }
  return 'undefined';
}

// A Jonline client with an optional credentials field bolted on.
export type JonlineCredentialClient = JonlineClient & {
  credential?: CallOptions;
}
