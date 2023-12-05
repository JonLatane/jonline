
//TODO: Move hook from app/store to here

import { AccountOrServer, AppDispatch, useRootSelector } from "app/store";
import { useAppDispatch } from "./store_hooks";


export const useAccount = () => useRootSelector(state => state.accounts.account);
export const useServer = () => useRootSelector(state => state.servers.server);
export function useAccountOrServer(): AccountOrServer {
  return {
    account: useAccount(),
    server: useServer()
  };
}


export type CredentialDispatch = {
  dispatch: AppDispatch;
  accountOrServer: AccountOrServer;
};
export function useCredentialDispatch(): CredentialDispatch {
  return {
    dispatch: useAppDispatch(),
    accountOrServer: useAccountOrServer()
  };
}
