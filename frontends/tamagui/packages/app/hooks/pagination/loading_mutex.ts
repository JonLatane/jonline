
import { useForceUpdate } from "@jonline/ui";
import { useEffect, useState } from "react";

// A LoadingMutex in the *global* context, along with the React state
// management in useLoadingLock (really just 'initiatedLoading' at the component level),
// is used to achieve something akin to React-Saga's takeLeading effect 
// (or the behavior of Tanstack Query, RTK Query, etc.).
//
// The advantage of this approach is that it works for *arbitrary* numbers of servers.
// It's built for:
//
// - fetching data from multiple servers in parallel
// - displaying per-server results as they come in
// - displaying per-server load statuses for the data being loaded (handled separately by the FederatedPagesStatus type)
// - preventing multiple requests for the same data
//
// This is used to prevent multiple requests
// for the same sets of posts/events/users/other entities on a server.
export type LoadingMutex = { loading: boolean };
export const createLoadingMutex = (): LoadingMutex => ({ loading: false });

const startLoading = (mutex: LoadingMutex) => mutex.loading = true;
const finishLoading = (mutex: LoadingMutex) => mutex.loading = false;

export const useLoadingLock = (mutex: LoadingMutex) => {
  const forceUpdate = useForceUpdate();
  const tryReload = () => setTimeout(forceUpdate, 100);
  const [initiatedLoading, setInitiatedLoading] = useState(false);
  useEffect(() => { mutex.loading && !initiatedLoading ? tryReload() : undefined }, [mutex.loading && !initiatedLoading]);

  const pollForLoadingLocked = () => {
    const result = mutex.loading;
    if (result) tryReload();
    return result;
  };

  const lockLoading = () => {
    setInitiatedLoading(true);
    startLoading(mutex);
  };

  const unlockLoading = () => {
    finishLoading(mutex);
    setInitiatedLoading(false);
  };

  return {
    // pollForLoadingLocked, lockLoading, unlockLoading,
    createReload: (loading: boolean, reload: (force?: boolean) => Promise<void>) => (force?: boolean) => {
      if (loading) return;
      if (pollForLoadingLocked()) {
        return;
      };

      lockLoading();
      reload(force).finally(unlockLoading);
    }
  };
}
