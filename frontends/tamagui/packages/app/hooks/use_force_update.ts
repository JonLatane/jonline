import { useReducer } from "react";

export function useForceUpdate() {
  const forceUpdate = useReducer(() => ({}), {})[1] as () => void
  return forceUpdate;
}
