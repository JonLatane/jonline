import { serverID, upsertServer } from "./modules";
import { store } from "./store";
import { JonlineServer } from "./types";
import { createChannel as createGrpcChannel, createClient as createGrpcClient } from 'nice-grpc-web';
import { JonlineDefinition, JonlineClient } from "@jonline/api/generated/jonline";
import { GetServiceVersionResponse, ServerConfiguration } from "@jonline/api";

type ConfiguredClient = JonlineServer & {
  client: JonlineClient;
  // serviceVersion: GetServiceVersionResponse;
  // serverConfiguration: ServerConfiguration
};
const clients = new Map<string, ConfiguredClient>();
const loadingClients = new Set<string>();

export function deleteClient(server: JonlineServer) {
  const serverId = serverID(server);
  clients.delete(serverId);
  loadingClients.delete(serverId);
}

export type JonlineClientCreationArgs = {
  skipUpsert?: boolean;
  onServerConfigured?: (server: JonlineServer) => void
};

export function getCachedServerClient(server: JonlineServer): ConfiguredClient | undefined {
  const serverId = serverID(server);
  return clients.get(serverId);
}


// Creates a client and upserts the server into the store.
export async function getServerClient(server: JonlineServer, args?: JonlineClientCreationArgs): Promise<JonlineClient> {
  // if (!server) {
  //   debugger;
  // }
  if (server.host === 'default') {
    throw 'Server host is default';
  }
  const serverId = serverID(server);
  const configuredClient = await getConfiguredServerClient(server, args);
  if (!configuredClient) {
    setTimeout(() => store.dispatch(upsertServer({
      ...server,
      lastConnectionFailed: true
    })), 1);
    throw "Failed to load client";
  }

  const { client, serviceVersion, serverConfiguration } = configuredClient;
  const updatedServer = {
    ...server,
    serviceVersion,
    serverConfiguration,
    lastConnectionFailed: false
  };
  const latestServer = store.getState().servers.entities[serverId];
  if (!args?.skipUpsert && (
    JSON.stringify(latestServer?.serviceVersion) !== JSON.stringify(serviceVersion) ||
    JSON.stringify(latestServer?.serverConfiguration) !== JSON.stringify(serverConfiguration)
  )) {
    // console.log("getServerClient: upserting server", updatedServer);
    setTimeout(() => store.dispatch(upsertServer(updatedServer)), 1);
  };
  args?.onServerConfigured?.(updatedServer);

  return client;
}

// Creates a client and upserts the server into the store.
export async function getConfiguredServerClient(server: JonlineServer, args?: JonlineClientCreationArgs): Promise<ConfiguredClient> {
  if (!server) {
    console.error("Server is undefined");
    // debugger;
  }

  const serverId = serverID(server);
  // TODO: Why does this fail miserable if using port 443?
  const ports = [27707/*, 443*/];
  const totalRetries = 5 * ports.length;
  let remainingRetries = totalRetries;
  while (!clients.has(serverId)) {
    if (loadingClients.has(serverId)) {
      await new Promise((res) => setTimeout(res, 200));
    } else {
      loadingClients.add(serverId);
      try {
        const portIndex = (totalRetries - remainingRetries) % ports.length;
        const port = ports[portIndex]!;
        console.log(`Creating client for ${serverId} on port ${port} (${portIndex})`);
        await resolveHostAndCreateClient(
          server,
          port,
          args
        );
      } catch (e) {
        if (remainingRetries-- == 0) {
          throw e;
        } else {
          console.warn(`Failed to load Jonline client for ${serverId}, retrying ${remainingRetries} more times...`, e);
        }
      } finally {
        loadingClients.delete(serverId);
      }
    }
  }

  const configuredClient = clients.get(serverId);
  if (!configuredClient) throw "Failed to load client";

  return configuredClient;
}

async function resolveHostAndCreateClient(server: JonlineServer, port: number, args?: JonlineClientCreationArgs): Promise<JonlineClient | undefined> {
  // Resolve the actual backend server from its backend_host endpoint
  const backendHost = await window.fetch(
    `${server?.secure ? 'https' : 'http'}://${server?.host}/backend_host`
  ).then(async (r) => {
    const domain = await r.text();
    if (domain == '') return undefined;
    return domain;
  }).catch((e) => {
    console.error(e);
    return undefined;
  }) ?? server.host;

  // Get the gRPC client
  const host = `${serverID({ ...server, host: backendHost }).replace(":", "://")}:${port}`;
  const client = await createJonlineGrpcClient(host, server, args);

  return client;
}

async function createJonlineGrpcClient(host: string, server: JonlineServer, args?: JonlineClientCreationArgs) {
  const serverId = serverID(server);

  const channel = createGrpcChannel(host);
  const client: JonlineClient = createGrpcClient(
    JonlineDefinition,
    channel,
  );

  console.log(`Getting service version and server configuration for ${host}...`);

  async function timeoutFuture<T>(future: Promise<T>, name: string, timeoutMs: number): Promise<T | undefined> {
    const clientFuture = async () => {
      try {
        return await future;
      } catch (e) {
        console.error(`Failed to get ${name}`, e);
        return undefined;
      }
    };
    const timeout = async (time: number) => {
      await new Promise((res) => setTimeout(res, time));
      return undefined;
    }
    return await Promise.race([timeout(5000), clientFuture()]);
  }

  const serviceVersion = await timeoutFuture(client.getServiceVersion({}), 'service version', 5000)
  const serverConfiguration = await timeoutFuture(client.getServerConfiguration({}), 'service version', 5000);

  if (!serviceVersion || !serverConfiguration) {
    throw ["Failed to load service version or server configuration", serviceVersion, serverConfiguration];
  }

  clients.set(serverId, { ...server, host, client, serviceVersion, serverConfiguration, });

  return client;
}
