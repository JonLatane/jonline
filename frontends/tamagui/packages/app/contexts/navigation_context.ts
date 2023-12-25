import { createContext, useContext } from "react";

export interface NavigationContextType {
  pinnedServersHeight: number;
  setPinnedServersHeight: (height: number) => void;
}


export const NavigationContext = createContext<NavigationContextType>(
  { pinnedServersHeight: 0, setPinnedServersHeight: () => { } }
);

export const NavigationContextProvider = NavigationContext.Provider;
export const useNavigationContext = () => useContext(NavigationContext);
