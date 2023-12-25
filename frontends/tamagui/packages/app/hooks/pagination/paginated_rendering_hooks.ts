import { HasIdFromServer } from "app/store";
import { useState } from "react";

export interface Pagination<T extends HasIdFromServer> {
  results: T[];
  page: number;
  loadingPage: boolean;
  hasNextPage?: boolean;
  loadNextPage: () => void;
}

export function usePaginatedRendering<T extends HasIdFromServer>(dataSet: T[], pageSize: number): Pagination<T> {
  const [page, setPage] = useState(0);
  const results = dataSet.slice(0, (page + 1) * pageSize);
  const hasNextPage = dataSet.length > results.length;

  const [loadingPage, setLoadingPage] = useState(false);
  function loadNextPage() {
    if (loadingPage) return;
    setLoadingPage(true);
    setTimeout(() => {
      setPage(page + 1);
      setLoadingPage(false);
    }, 500);
  }

  return { results, page, loadingPage, hasNextPage, loadNextPage };
}
