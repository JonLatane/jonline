import { ReactNativeTransport } from "@improbable-eng/grpc-web-react-native-transport";
import { GrpcWebImpl, Jonline, JonlineClientImpl } from "@jonline/api";
import { Platform } from "react-native";
import { serverID, upsertServer } from "./modules";
import { store } from "./store";
import { JonlineServer } from "./types";

const clients = new Map<string, JonlineClientImpl>();
export async function getServerClient(server: JonlineServer): Promise<Jonline> {
  const host = `${serverID(server).replace(":", "://")}:27707`;
  if (!clients.has(host)) {
    const client = new JonlineClientImpl(
      new GrpcWebImpl(host, {
        transport: Platform.OS == 'web' ? undefined : ReactNativeTransport({})
      })
    );
    clients.set(host, client);
    try {
      const serviceVersion = await Promise.race([client.getServiceVersion({}), timeout(5000, "service version")]);
      const serverConfiguration = await Promise.race([client.getServerConfiguration({}), timeout(5000, "server configuration")]);
      store.dispatch(upsertServer({ ...server, serviceVersion, serverConfiguration }));
    } catch (e) {
      clients.delete(host);
    }
    return client;
  }
  return clients.get(host)!;
}
const timeout = async (time: number, label: string) => {
  await new Promise((res) => setTimeout(res, time));
  throw `Timed out getting ${label}.`;
}
