import { FederatedEntity, HasIdFromServer } from "app/store";
import { useState } from "react";

export interface Pagination<T extends HasIdFromServer> {
  results: FederatedEntity<T>[];
  page: number;
  pageCount: number;
  loadingPage: boolean;
  hasNextPage?: boolean;
  loadNextPage: () => void;
  reset(): void;
}

export const maxPagesToRender = 5;
export function usePaginatedRendering<T extends HasIdFromServer>(
  dataSet: FederatedEntity<T>[], 
  pageSize: number
): Pagination<T> {
  const [page, setPage] = useState(0);
  const reset = () => setPage(0);
  const lowerBoundPage = Math.max(0, page - maxPagesToRender + 1);
  const upperBoundPage = page + 1;
  const results = dataSet.slice(lowerBoundPage * pageSize, upperBoundPage * pageSize);
  const hasNextPage = dataSet.length > upperBoundPage * pageSize;
  const pageCount = Math.ceil(dataSet.length / pageSize);

  const [loadingPage, setLoadingPage] = useState(false);
  function loadNextPage() {
    if (loadingPage) return;
    setLoadingPage(true);
    setTimeout(() => {
      setPage(page + 1);
      setLoadingPage(false);
    }, 500);
  }

  return { results, page, pageCount, loadingPage, hasNextPage, loadNextPage, reset };
}
