import { serverID, upsertServer } from "./modules";
import { store } from "./store";
import { JonlineServer } from "./types";
import { createChannel, createClient } from 'nice-grpc-web';
import { JonlineDefinition, JonlineClient } from "@jonline/api/generated/jonline";

const clients = new Map<string, JonlineClient>();
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

// Creates a client and upserts the server into the store.
export async function getServerClient(server: JonlineServer, args?: JonlineClientCreationArgs): Promise<JonlineClient> {
  const serverId = serverID(server);
  // TODO: Why does this fail miserable if using port 443?
  const ports = [27707, 443];
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
        const client = await clientForServer(
          server,
          port,
          args
        );
        if (client) {

          return client;
        }
        throw "Failed to load client";
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

  return clients.get(serverId)!;
}

async function clientForServer(server: JonlineServer, port: number, args?: JonlineClientCreationArgs): Promise<JonlineClient | undefined> {
  // Resolve the actual backend server from its backend_host endpoint
  const backendHost = await window.fetch(
    `${server.secure ? 'https' : 'http'}://${server.host}/backend_host`
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
  const client = await doCreateClient(host, server, args);

  return client;
}

async function doCreateClient(host: string, server: JonlineServer, args?: JonlineClientCreationArgs) {
  const serverId = serverID(server);

  const channel = createChannel(host);

  const client: JonlineClient = createClient(
    JonlineDefinition,
    channel,
  );

  console.log(`Getting service version and server configuration for ${host}...`);

  const serviceVersionFuture = async () => {
    try {
      return await client.getServiceVersion({});
    } catch (e) {
      console.error('Failed to get service version', e);
      return 'Failed to get service version.'
    }
  };
  const serviceVersion = await Promise.race([
    timeout(5000, "service version"),
    serviceVersionFuture()
  ]);
  console.log('Got service version of type', typeof serviceVersion, serviceVersion);
  if (typeof serviceVersion == 'string') throw new Error(serviceVersion);

  const serverConfiguration = await Promise.race([client.getServerConfiguration({}), timeout(5000, "server configuration")]);
  console.log('Got server configuration', serverConfiguration);
  if (typeof serverConfiguration == 'string') throw new Error(serverConfiguration);

  const frontendHost = serverConfiguration.externalCdnConfig?.frontendHost;
  if (frontendHost && frontendHost != '' && frontendHost != server.host) {
    console.warn("Created Jonline client with different frontend host than server host. Correcting server host.");
  }

  const updatedServer = { ...server, serviceVersion, serverConfiguration };
  if (!args?.skipUpsert) {
    clients.set(serverId, client);
    console.log("doCreateClient: upserting server", updatedServer);
    // debugger;
    store.dispatch(upsertServer(updatedServer));
  };
  args?.onServerConfigured?.(updatedServer);
  return client;
}


const timeout = async (time: number, label: string) => {
  await new Promise((res) => setTimeout(res, time));
  return `Timed out getting ${label}.`;
}
