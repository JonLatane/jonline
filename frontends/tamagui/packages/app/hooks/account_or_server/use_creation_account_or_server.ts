import { JonlineServer, selectCreationServer, selectServerById } from 'app/store';
import { useAppDispatch, useAppSelector } from "../store_hooks";
import { usePinnedAccountsAndServers } from './use_pinned_accounts_and_servers';



export const useCreationServer = () => {
  const dispatch = useAppDispatch();
  return useAppSelector(state => {
    const creationServer = state.servers.creationServerId
      ? selectServerById(state.servers, state.servers.creationServerId)
      : undefined;
    const setCreationServer = (s: JonlineServer | undefined) => dispatch(selectCreationServer(s));
    return { creationServer, setCreationServer };
  });
};

export const useCreationAccountOrServer = () => {
  const { creationServer } = useCreationServer();
  return usePinnedAccountsAndServers({ includeUnpinned: true })
    .find(aos => aos.server?.host === creationServer?.host)
    ?? {};
};
