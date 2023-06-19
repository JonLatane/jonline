import { Group } from "@jonline/api";
import { createContext, useContext } from "react";

type GroupContextType = Group | undefined;

export const GroupContext = createContext<GroupContextType>(undefined);

export const GroupContextProvider = GroupContext.Provider;
export const useGroupContext = () => useContext(GroupContext);