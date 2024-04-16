import { JonlineServer } from "app/store";
import { createContext, useContext, useState } from "react";

export type GetSet<T> = [T, (v: T) => void];

type AuthSheetContextType = {
  open: GetSet<boolean>;//[boolean, (v: boolean) => void];  
};

export const AuthSheetContext = createContext<AuthSheetContextType>({
  open: [false, () => { console.warn('AuthSheetContextProvider not set.') }]
  // selectedAuthSheet: undefined,
  // setSharingPostId: () => { console.warn('AuthSheetContextProvider not set.') },
  // setInfoAuthSheetId: () => { console.warn('AuthSheetContextProvider not set.') },
});

export const AuthSheetContextProvider = AuthSheetContext.Provider;
export const AuthSheetContextConsumer = AuthSheetContext.Consumer;
export const useAuthSheetContext = () => useContext(AuthSheetContext);
export function useNewAuthSheetContext(): AuthSheetContextType {
  const [open, setOpen] = useState(false);
  return { open: [open, setOpen] };
}
