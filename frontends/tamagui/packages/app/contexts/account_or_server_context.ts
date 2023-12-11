import { AccountOrServer } from "app/store";
import { createContext, useContext } from "react";

export const AccountOrServerContext = createContext<AccountOrServer | undefined>(undefined);

export const AccountOrServerContextProvider = AccountOrServerContext.Provider;
export const useAccountOrServerContext = () => useContext(AccountOrServerContext);
