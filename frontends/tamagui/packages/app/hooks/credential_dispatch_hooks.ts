import { Post } from '@jonline/api/index';
import { useAccountOrServerContext } from 'app/contexts';
import { AccountOrServer, AppDispatch, FederatedEntity, HasIdFromServer, JonlineServer, pinServer } from 'app/store';
import { useAppDispatch } from "./store_hooks";
import { server } from '../../../apps/expo/metro.config';
import { useCurrentAccountOrServer } from './account_or_server/use_current_account_or_server';
import { useCreationAccountOrServer } from './account_or_server/use_creation_account_or_server';
import { useFederatedAccountOrServer } from './account_or_server/use_federated_account_or_server';

/**
 * An {@link AppDispatch} and the {@link AccountOrServer} to communicate with when dispatching actions.
 * 
 * (Many actions require an {@link AccountOrServer}, so this is a convenience type).
 */
export type CredentialDispatch = {
  dispatch: AppDispatch;
  accountOrServer: AccountOrServer;
};

export function useCredentialDispatch(): CredentialDispatch {
  return {
    dispatch: useAppDispatch(),
    accountOrServer: useCurrentAccountOrServer()
  };
}

/**
 * Like {@link useCredentialDispatch}, but for the {@link ServersState.creationServerId}.
 * 
 * Used in {@link CreateAccountOrLoginSheet} and {@link BaseCreatePostSheet}.
 */
export function useCreationDispatch(): CredentialDispatch {
  return {
    dispatch: useAppDispatch(),
    accountOrServer: useCreationAccountOrServer()
  };
}

/**
 * Returns the available {@link CredentialDispatch} for the given {@link FederatedEntity}.
 * 
 * @param entity Any Federated entity.
 * @returns An AppDispatch and the appropriate AccountOrServer to view/edit the given entity
 */
export function useFederatedDispatch<T extends HasIdFromServer>(
  entity: FederatedEntity<T> | string | undefined
): CredentialDispatch {
  return {
    dispatch: useAppDispatch(),
    accountOrServer: useFederatedAccountOrServer(entity)
  };
}

/**
 * Returns the available {@link CredentialDispatch} for the given {@link JonlineServer}, or the current account or server if none is provided.
 * 
 * TODO: Implementation update: Maybe this should resolve from pinned accounts when server is overridden? Current functionality doesn't need this.
 * 
 * @param serverOverride An optional server to use instead of the one from the AccountOrServerContext or the Redux store state.
 * @returns 
 */
export function useProvidedDispatch(serverOverride?: JonlineServer): CredentialDispatch {
  const currentAccountOrServer = useCurrentAccountOrServer();
  const accountOrServerContext = useAccountOrServerContext();
  const accountOrServer = accountOrServerContext ?? currentAccountOrServer;
  const dispatch = useAppDispatch();
  if (serverOverride) {
    if (serverOverride.host === accountOrServer.server?.host) {
      return { dispatch, accountOrServer };
    } else {
      return { dispatch, accountOrServer: { account: undefined, server: serverOverride } };
    }
  }
  return { dispatch, accountOrServer };
}

export function usePostDispatch(post: Post): CredentialDispatch {
  const currentAccountOrServer = useCurrentAccountOrServer();
  const accountOrServerContext = useAccountOrServerContext();
  const serverHost = 'serverHost' in post
    ? post.serverHost as string
    : accountOrServerContext?.server?.host ?? currentAccountOrServer.server?.host;
  // const accountOrServer = useFederatedAccountOrServer(serverHost);

  return useFederatedDispatch(serverHost);
}
