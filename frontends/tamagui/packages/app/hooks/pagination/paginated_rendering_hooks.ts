import { FederatedEntity, HasIdFromServer, federatedId } from "app/store";
import { useEffect, useMemo, useState } from "react";
import { createParam } from "solito";

export interface Pagination<T extends HasIdFromServer> {
  results: FederatedEntity<T>[];
  page: number;
  pageCount: number;
  pageSize: number;
  resultCount: number;
  loadingPage: boolean;
  hasNextPage?: boolean;
  setPage: (page: number) => void;
  reset(): void;
}

const { useParam, useUpdateParams } = createParam<{ page: string | undefined }>()
export function usePageParam(): [number, (page: number) => void] {
  const updateParams = useUpdateParams();

  const [pageParam, config] = useParam('page');
  // console.log('pageParam', pageParam, config)
  let parsedPage: number | undefined;
  try {
    parsedPage = Math.max(0, parseInt(pageParam ?? '1') - 1);
  } catch (e) {
    console.warn("Error parsing page param", e);
  }

  const page = parsedPage ?? 0;
  const setPage = (p: number) => {
    if (page === p) return;
    updateParams(
      { page: p === 0 ? undefined : (p + 1).toString() },
      { web: { replace: true } }
    );
  }

  return [page, setPage] as const;
}

const { useParam: _useEventPageParam, useUpdateParams: useUpdateEventPageParams } = createParam<{ eventPage: string | undefined }>()
export function useEventPageParam(): [number, (page: number) => void] {
  const updateParams = useUpdateEventPageParams();

  const [pageParam] = _useEventPageParam('eventPage');
  let parsedPage: number | undefined;
  try {
    parsedPage = Math.max(0, parseInt(pageParam ?? '1') - 1);
  } catch (e) {
    console.warn("Error parsing page param", e);
  }

  const page = parsedPage ?? 0;
  const setPage = (p: number) => {
    if (page === p) return;
    updateParams(
      { eventPage: p === 0 ? undefined : (p + 1).toString() },
      { web: { replace: true } }
    );
  }

  return [page, setPage] as const;
}

const { useParam: _usePostPageParam, useUpdateParams: useUpdatePostPageParams } = createParam<{ postPage: string | undefined }>()
export function usePostPageParam(): [number, (page: number) => void] {
  const updateParams = useUpdatePostPageParams();

  const [pageParam] = _usePostPageParam('postPage');
  // console.log('postPageParam', pageParam)
  let parsedPage: number | undefined;
  try {
    parsedPage = Math.max(0, parseInt(pageParam ?? '1') - 1);
  } catch (e) {
    console.warn("Error parsing page param", e);
  }

  const page = parsedPage ?? 0;
  const setPage = (p: number) => {
    if (page === p) return;
    updateParams(
      { postPage: p === 0 ? undefined : (p + 1).toString() },
      { web: { replace: true } }
    );
  }

  return [page, setPage] as const;
}

export const maxPagesToRender = 1;
export function usePaginatedRendering<T extends HasIdFromServer>(
  dataSet: FederatedEntity<T>[],
  pageSize: number,
  args?: {
    itemIdResolver?: (item: FederatedEntity<T>) => string;
    pageParamHook?: typeof usePageParam;
  }
): Pagination<T> {
  const pageCount = Math.ceil(dataSet.length / pageSize);
  // const standardPageParams = usePageParam();
  const [page, setPage] = args?.pageParamHook?.() ?? usePageParam();
  const [loadingPage, setLoadingPage] = useState(false);

  // useEffect(() => {
  //   if (page >= pageCount && !loadingPage) {
  //     setPage(Math.max(0, pageCount - 1));
  //   }
  // }, [page, pageCount, loadingPage]);

  const result = useMemo(() => {
    const lowerBoundPage = Math.max(0, page - maxPagesToRender + 1);
    const upperBoundPage = page + 1;
    const results = dataSet.slice(lowerBoundPage * pageSize, upperBoundPage * pageSize);
    const hasNextPage = dataSet.length > upperBoundPage * pageSize;

    // const lastItem = results[results.length - 1];
    // const onPageLoaded = args?.itemIdResolver && lastItem
    //   ? (page: number) => setTimeout(
    //     () => document.getElementById(args.itemIdResolver!(lastItem))
    //       ?.scrollIntoView({ block: 'center', behavior: 'smooth' }),
    //     3000
    //   ) : undefined;

    const reset = () => {
      if (loadingPage) return;
      if (results.length === 0) return;

      setLoadingPage(true);
      const startPage = 0;
      setPage(startPage);
      setTimeout(() => setLoadingPage(false), 1000);
    };


    return {
      results,
      pageSize,
      resultCount: dataSet.length,
      page,
      setPage,
      pageCount,
      loadingPage,
      hasNextPage,
      reset
    };
  }, [
    dataSet.map(federatedId),
    // dataSet.length,
    // dataSet[0]?.id,
    // dataSet[0]?.serverHost,
    // dataSet[dataSet.length - 1]?.id,
    // dataSet[dataSet.length - 1]?.serverHost,
    pageSize,
    page,
    loadingPage
  ]);

  return result;
}

// export function useLoadablePaginatedRendering<T extends HasIdFromServer>(
//   dataSet: FederatedEntity<T>[] | undefined,
//   pageSize: number,
//   loadData: () => void,
//   args?: {
//     itemIdResolver?: (item: FederatedEntity<T>) => string;
//   }
// ): Pagination<T> {

//   const data = dataSet ?? [];
//   const pageCount = Math.ceil(data.length / pageSize);
//   const [page, setPage] = usePageParam();

//   const lowerBoundPage = Math.max(0, page - maxPagesToRender + 1);
//   const upperBoundPage = page + 1;
//   const results = data.slice(lowerBoundPage * pageSize, upperBoundPage * pageSize);
//   const hasNextPage = !!dataSet && dataSet.length > upperBoundPage * pageSize;

//   const [loadingPage, setLoadingPage] = useState(false);

//   const lastItem = results[results.length - 1];
//   const onPageLoaded = args?.itemIdResolver && lastItem
//     ? (page: number) => setTimeout(
//       () => document.getElementById(args.itemIdResolver!(lastItem))
//         ?.scrollIntoView({ block: 'center', behavior: 'smooth' }),
//       3000
//     ) : undefined;

//   const reset = () => {
//     if (loadingPage) return;
//     if (results.length === 0) return;

//     setLoadingPage(true);
//     const startPage = 0;
//     setPage(startPage);
//     setTimeout(() => setLoadingPage(false), 1000);
//   };

//   function loadNextPage() {
//     if (loadingPage) return;
//     setLoadingPage(true);
//     const targetPage = page + 1;
//     const maxPage = Math.max(0, Math.min(pageCount - 1, maxPagesToRender - 1));
//     if (targetPage < maxPage) {
//       setPage(maxPage);
//       onPageLoaded?.(maxPage);
//     } else {
//       setPage(targetPage);
//       onPageLoaded?.(targetPage);
//     }
//     setTimeout(() => setLoadingPage(false), 1000);
//   }

//   return { results, page, pageCount, loadingPage: dataSet === undefined, hasNextPage, loadNextPage, reset };
// }