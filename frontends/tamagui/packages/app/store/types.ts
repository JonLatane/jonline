import { grpc } from "@improbable-eng/grpc-web";
import { ExpirableToken, GetServiceVersionResponse, ServerConfiguration, User } from "@jonline/api";
import { accountID, serverID } from "./modules";
import { CallOptions } from "nice-grpc-web";
import { JonlineClient } from "@jonline/api/generated/jonline";

export type JonlineServer = {
  host: string;
  secure: boolean;
  serviceVersion?: GetServiceVersionResponse;
  serverConfiguration?: ServerConfiguration;
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
}

// Note that this is inclusive-or. The account, if provided, should always have the same server as the server field.
export type AccountOrServer = {
  account?: JonlineAccount;
  server?: JonlineServer;
};

export function accountOrServerId(accountOrServer: AccountOrServer) {
  if (accountOrServer.account) {
    return `account-${accountID(accountOrServer.account)}`;
  }
  return `server-${serverID(accountOrServer.server!)}`;
}

// A Jonline client with an optional credentials field bolted on.
export type JonlineCredentialClient = JonlineClient & {
  credential?: CallOptions;
}
