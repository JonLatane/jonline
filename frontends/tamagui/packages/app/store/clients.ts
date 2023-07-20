import { ReactNativeTransport } from "@improbable-eng/grpc-web-react-native-transport";
import { GrpcWebImpl, Jonline, JonlineClientImpl } from "@jonline/api";
import { Platform } from "react-native";
import { serverID, upsertServer } from "./modules";
import { store } from "./store";
import { JonlineServer } from "./types";

const clients = new Map<string, JonlineClientImpl>();
const loadingClients = new Set<string>();

// Creates a client and upserts the server into the store.
export async function getServerClient(server: JonlineServer): Promise<Jonline> {
  const serverId = serverID(server);
  let retries = 5;
  while (!clients.has(serverId)) {
    if (loadingClients.has(serverId)) {
      await new Promise((res) => setTimeout(res, 200));
    } else {
      loadingClients.add(serverId);
      try {
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
        const host = `${serverID({ ...server, host: backendHost }).replace(":", "://")}:27707`;
        const client = await createClient(host, server);
        return client;
      } catch (e) {
        if (retries-- == 0) {
          throw e;
        } else {
          console.warn(`Failed to load Jonline client for ${serverId}, retrying ${retries} more times...`, e);
        }
      } finally {
        loadingClients.delete(serverId);
      }
    }
  }

  return clients.get(serverId)!;
}

async function createClient(host: string, server: JonlineServer) {
  const serverId = serverID(server);
  const client = new JonlineClientImpl(
    new GrpcWebImpl(host, {
      transport: Platform.OS == 'web' ? undefined : ReactNativeTransport({})
    })
  );
  clients.set(serverId, client);
  try {
    const serviceVersion = await Promise.race([client.getServiceVersion({}), timeout(5000, "service version")]);
    const serverConfiguration = await Promise.race([client.getServerConfiguration({}), timeout(5000, "server configuration")]);
    const frontendHost = serverConfiguration.externalCdnConfig?.frontendHost;
    if (frontendHost && frontendHost != '' && frontendHost != server.host) {
      console.warn("Created Jonline client with different frontend host than server host. Correcting server host.");
      // server.host = frontendHost;
    }
    store.dispatch(upsertServer({ ...server, serviceVersion, serverConfiguration }));
  } catch (e) {
    clients.delete(host);
  }
  return client;
}


const timeout = async (time: number, label: string) => {
  await new Promise((res) => setTimeout(res, time));
  throw `Timed out getting ${label}.`;
}
