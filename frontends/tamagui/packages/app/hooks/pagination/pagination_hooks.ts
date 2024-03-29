
import { FederatedEntity } from "app/store";

export type PaginationResults<F extends FederatedEntity<any>> = {
  results: F[];
  loading: boolean;
  reload: () => void;
  hasMorePages?: boolean;
  firstPageLoaded?: boolean;
};


export function onPageLoaded(setLoading: (v: boolean) => void, onLoaded?: () => void) {
  return () => finishPagination(setLoading, onLoaded);
}

export function finishPagination(setLoading: (v: boolean) => void, onLoaded?: () => void) {
  setTimeout(() => {
    setLoading(false);
    onLoaded?.();
  }, 1000);
}
