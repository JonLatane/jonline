import { grpc } from "@improbable-eng/grpc-web";
import { ExpirableToken, GetServiceVersionResponse, Jonline, ServerConfiguration, User } from "@jonline/api";

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
}

// Note that this is inclusive-or
export type AccountOrServer = {
  account?: JonlineAccount;
  server?: JonlineServer;
};

// A Jonline client with an optional credentials field bolted on.
export type JonlineCredentialClient = Jonline & {
  credential?: grpc.Metadata;
}
