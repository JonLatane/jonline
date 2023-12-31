import { createContext, useContext, useState } from "react";

export interface NavigationContextType {
  pinnedServersHeight: number;
  setPinnedServersHeight: (height: number) => void;
}

export const NavigationContext = createContext<NavigationContextType | undefined>(undefined);

export const NavigationContextProvider = NavigationContext.Provider;
export const NavigationContextConsumer = NavigationContext.Consumer;
export const useNavigationContext = () => useContext(NavigationContext);

export function useOrCreateNavigationContext(): NavigationContextType {
  const [pinnedServersHeight, setPinnedServersHeight] = useState(0);
  const navigationContext: NavigationContextType = useNavigationContext() ?? { pinnedServersHeight, setPinnedServersHeight };
  return navigationContext;
}
