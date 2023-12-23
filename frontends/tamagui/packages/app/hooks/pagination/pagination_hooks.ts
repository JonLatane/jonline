
import { FederatedEntity } from "app/store";

export type PaginationResults<F extends FederatedEntity<any>> = {
  results: F[];
  loading: boolean;
  reload: () => void;
  hasMorePages?: boolean;
  firstPageLoaded?: boolean;
};
