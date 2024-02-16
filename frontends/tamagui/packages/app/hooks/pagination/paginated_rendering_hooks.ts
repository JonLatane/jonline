import { FederatedEntity, HasIdFromServer } from "app/store";
import { useState } from "react";
import { createParam } from "solito";
import { onPageLoaded } from './pagination_hooks';

export interface Pagination<T extends HasIdFromServer> {
  results: FederatedEntity<T>[];
  page: number;
  pageCount: number;
  loadingPage: boolean;
  hasNextPage?: boolean;
  loadNextPage: () => void;
  reset(): void;
}


const { useParam, useUpdateParams } = createParam<{ page: string | undefined }>()
export function usePageParam() {
  const updateParams = useUpdateParams();

  const [pageParam] = useParam('page');
  let parsedPage: number | undefined;
  try {
    parsedPage = parseInt(pageParam ?? '1') - 1;
  } catch (e) {
    console.warn("Error parsing page param", e);
  }

  const page = parsedPage ?? 0;
  const setPage = (p: number) => updateParams(
    { page: p === 0 ? undefined : (p + 1).toString() },
    { web: { replace: true } }
  );

  return [page, setPage] as const;
}
export const maxPagesToRender = 5;
export function usePaginatedRendering<T extends HasIdFromServer>(
  dataSet: FederatedEntity<T>[],
  pageSize: number,
  args?: {
    itemIdResolver?: (item: FederatedEntity<T>) => string;
    // onPageLoaded?: (page: number, oldLastItem?: FederatedEntity<T>) => void;
  }
): Pagination<T> {
  const pageCount = Math.ceil(dataSet.length / pageSize);
  // const [page, setPage] = useState(0);
  const [page, setPage] = usePageParam();

  const lowerBoundPage = Math.max(0, page - maxPagesToRender + 1);
  const upperBoundPage = page + 1;
  const results = dataSet.slice(lowerBoundPage * pageSize, upperBoundPage * pageSize);
  const hasNextPage = dataSet.length > upperBoundPage * pageSize;

  const [loadingPage, setLoadingPage] = useState(false);

  const lastItem = results[results.length - 1];
  const onPageLoaded = args?.itemIdResolver && lastItem
    ? (page: number) => setTimeout(
      () => document.getElementById(args.itemIdResolver!(lastItem))
        ?.scrollIntoView({ block: 'center', behavior: 'smooth' }),
      3000
    ) : undefined;

  const reset = () => {
    if (loadingPage) return;
    setLoadingPage(true);
    // setTimeout(() => {
    const startPage = 0; //Math.max(0, Math.min(pageCount - 1, maxPagesToRender - 1))
    setPage(startPage);
    // args?.onPageLoaded?.(startPage, lastItem);
    setTimeout(() => setLoadingPage(false), 1000);
    // setLoadingPage(false);
    // }, 500);
  };

  function loadNextPage() {
    if (loadingPage) return;
    setLoadingPage(true);
    // setTimeout(() => {
    setPage(page + 1);
    onPageLoaded?.(page + 1);
    setTimeout(() => setLoadingPage(false), 1000);
    // setLoadingPage(false);
    // }, 500);
  }

  return { results, page, pageCount, loadingPage, hasNextPage, loadNextPage, reset };
}
