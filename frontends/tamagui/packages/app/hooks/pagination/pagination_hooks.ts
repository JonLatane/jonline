
// export function is

import { Federated, FederatedEntity, HasIdFromServer } from "app/store";

export type FederatedPaginationHooks<F extends FederatedEntity<any>> = {
  results: F[] | undefined;
  loading: boolean;
  reload: () => void;
};
