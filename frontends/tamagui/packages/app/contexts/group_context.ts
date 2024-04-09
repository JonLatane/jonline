import { FederatedGroup } from "app/store";
import { createContext, useContext } from "react";

type GroupContextType = {
  selectedGroup?: FederatedGroup;
  sharingPostId?: string;
  setSharingPostId: (postId: string | undefined) => void;
  infoGroupId?: string;
  setInfoGroupId: (groupId: string | undefined) => void;
};

export const GroupContext = createContext<GroupContextType>({
  selectedGroup: undefined,
  setSharingPostId: () => { console.warn('GroupContextProvider not set.') },
  setInfoGroupId: () => { console.warn('GroupContextProvider not set.') },
});

export const GroupContextProvider = GroupContext.Provider;
export const GroupContextConsumer = GroupContext.Consumer;
export const useGroupContext = () => useContext(GroupContext);
