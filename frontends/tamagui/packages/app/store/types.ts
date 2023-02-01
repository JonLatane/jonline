import { grpc } from "@improbable-eng/grpc-web";
import { ExpirableToken, GetServiceVersionResponse, Jonline, RefreshTokenResponse, ServerConfiguration, User } from "@jonline/ui/src";

export type JonlineServer = {
  host: string;
  secure: boolean;
  serviceVersion?: GetServiceVersionResponse;
  serverConfiguration?: ServerConfiguration;
}

// The type used to store accounts locally.
export type JonlineAccount = {
  id: string;
  user: User;
  refreshToken: ExpirableToken;
  accessToken: ExpirableToken;
  server: JonlineServer;
}

export type AccountOrServer = {
  account?: JonlineAccount;
  server?: JonlineServer;
};

// A Jonline client with an optional credentials field bolted on.
export type JonlineCredentialClient = Jonline & {
  credential?: grpc.Metadata;
}
