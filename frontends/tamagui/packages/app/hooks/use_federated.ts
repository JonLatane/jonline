import { Federated, getFederated } from "app/store/federation";
import { useServer } from "./account_and_server_hooks";

export function useFederated<T>(value: Federated<T>) {
  const server = useServer();
  return getFederated(value, server);
}
