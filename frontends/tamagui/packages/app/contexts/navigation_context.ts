import { AppSection } from "app/features/navigation/features_navigation";
import { FederatedGroup } from "app/store";
import { createContext, useContext } from "react";
import { AppSubsection } from '../features/navigation/features_navigation';

type NavigationContextType = {
  appSection: AppSection;
  appSubsection?: AppSubsection;

  // Forwarder to link to a group page. Defaults to /g/:shortname.
  // But, for instance, post pages can link to /g/:shortname/p/:id.
  groupPageForwarder?: (groupIdentifier: string) => string;
  groupPageReverse?: string;
};

export const NavigationContext = createContext<NavigationContextType>({
  appSection: AppSection.NONE,
});

export const NavigationContextProvider = NavigationContext.Provider;
export const NavigationContextConsumer = NavigationContext.Consumer;
export const useNavigationContext = () => useContext(NavigationContext);
