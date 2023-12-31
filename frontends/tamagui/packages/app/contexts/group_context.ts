import { FederatedGroup } from "app/store";
import { createContext, useContext } from "react";

type GroupContextType = FederatedGroup | undefined;

export const GroupContext = createContext<GroupContextType>(undefined);

export const GroupContextProvider = GroupContext.Provider;
export const useGroupContext = () => useContext(GroupContext);