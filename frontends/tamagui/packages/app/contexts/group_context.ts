import { FederatedGroup } from "app/store";
import { createContext, useContext } from "react";

type GroupContextType = {
  selectedGroup?: FederatedGroup;
  // The UI implicitly displays the GroupsSheet iff sharingPostId is defined.
  sharingPostId?: string;
  // The UI implicitly displays the GroupsSheet iff sharingPostId is defined.
  setSharingPostId: (postId: string | undefined) => void;
  // The UI implicitly displays the GroupInfoSheet iff infoGroupId is defined.
  infoGroupId?: string;
  // The UI implicitly displays the GroupInfoSheet iff infoGroupId is defined.
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
