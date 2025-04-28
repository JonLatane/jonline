import { JonlineServer } from "app/store";
import { createContext, useContext, useState } from "react";

export type GetSet<T> = [T, (v: T) => void];

type AccountsSheetContextType = {
  open: GetSet<boolean>;//[boolean, (v: boolean) => void];  
};

export const AccountsSheetContext = createContext<AccountsSheetContextType>({
  open: [false, () => { console.warn('AccountsSheetContextProvider not set.') }]
  // selectedAccountsSheett: undefined,
  // setSharingPostId: () => { console.warn('AccountsSheettContextProvider not set.') },
  // setInfoAccountsSheettId: () => { console.warn('AccountsSheettContextProvider not set.') },
});

export const AccountsSheetContextProvider = AccountsSheetContext.Provider;
export const AccountsSheetContextConsumer = AccountsSheetContext.Consumer;
export const useAccountsSheetContext = () => useContext(AccountsSheetContext);
export function useNewAccountsSheetContext(): AccountsSheetContextType {
  const [open, setOpen] = useState(false);
  return { open: [open, setOpen] };
}
