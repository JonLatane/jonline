import { ReactNativeTransport } from "@improbable-eng/grpc-web-react-native-transport";
import { Jonline, JonlineClientImpl } from "@jonline/ui/src";
import { GrpcWebImpl } from "@jonline/ui/src/generated/jonline";
import AsyncStorage from '@react-native-async-storage/async-storage';
import { AnyAction, combineReducers, configureStore, Store, ThunkDispatch } from "@reduxjs/toolkit";
import { Platform } from 'react-native';
import { createSelectorHook, useDispatch } from "react-redux";
import { FLUSH, PAUSE, PERSIST, persistReducer, persistStore, PURGE, REGISTER, REHYDRATE } from 'redux-persist';
import storage from 'redux-persist/lib/storage';
import thunkMiddleware from 'redux-thunk';
import { accountsReducer, groupsReducer, localAppReducer, postsReducer, resetAccounts, resetGroups, resetLocalApp, resetPosts, resetServers, serversReducer, serverUrl, upsertServer, usersReducer } from "./modules";
import { AccountOrServer, JonlineServer } from './types';

const serversPersistConfig = {
  key: 'servers',
  storage: Platform.OS == 'web' ? storage : AsyncStorage,
  blacklist: ['status', 'successMessage', 'errorMessage', 'error']
}
const accountsPersistConfig = {
  key: 'accounts',
  storage: Platform.OS == 'web' ? storage : AsyncStorage,
  blacklist: ['status', 'successMessage', 'errorMessage', 'error']
}
const postsPersistConfig = {
  key: 'posts',
  storage: Platform.OS == 'web' ? storage : AsyncStorage,
  blacklist: ['status', 'successMessage', 'errorMessage', 'error', 'previews'],
}
const usersPersistConfig = {
  key: 'users',
  storage: Platform.OS == 'web' ? storage : AsyncStorage,
  blacklist: ['status', 'successMessage', 'errorMessage', 'error', 'avatars'],
}
const groupsPersistConfig = {
  key: 'groups',
  storage: Platform.OS == 'web' ? storage : AsyncStorage,
  blacklist: ['status', 'successMessage', 'errorMessage', 'error', 'avatars'],
}

const rootReducer = combineReducers({
  app: localAppReducer,
  accounts: persistReducer(accountsPersistConfig, accountsReducer),
  servers: persistReducer(serversPersistConfig, serversReducer),
  posts: persistReducer(postsPersistConfig, postsReducer),
  users: persistReducer(usersPersistConfig, usersReducer),
  groups: persistReducer(groupsPersistConfig, groupsReducer)
});

const rootPersistConfig = {
  key: 'root',
  storage: Platform.OS == 'web' ? storage : AsyncStorage,
  blacklist: ['accounts', 'servers', 'posts'],
  // transforms: [RemovePostPreviews]
}
const persistedReducer = persistReducer(rootPersistConfig, rootReducer)

export type RootState = ReturnType<typeof rootReducer>;
export const useTypedSelector = createSelectorHook();

export type AppDispatch = ThunkDispatch<RootState, any, AnyAction>;
export function useTypedDispatch(): AppDispatch {
  return useDispatch<AppDispatch>()
};

export type CredentialDispatch = {
  dispatch: AppDispatch;
  accountOrServer: AccountOrServer;
};
export function useCredentialDispatch(): CredentialDispatch {
  let dispatch: AppDispatch = useTypedDispatch();
  let accountOrServer = {
    account: useTypedSelector((state: RootState) => state.accounts.account),
    server: useTypedSelector((state: RootState) => state.servers.server)
  }
  return { dispatch, accountOrServer };
}

export type AppStore = Omit<Store<RootState, AnyAction>, "dispatch"> & {
  dispatch: AppDispatch;
};

export const store: AppStore = configureStore({
  reducer: persistedReducer,
  middleware: (getDefaultMiddleware) => [...getDefaultMiddleware({
    serializableCheck: {
      ignoredActions: [FLUSH, REHYDRATE, PAUSE, PERSIST, PURGE, REGISTER],
    }
  }), thunkMiddleware]
});

export const persistor = persistStore(store);

// Reset store data that depends on selected server/account.
export function resetCredentialedData() {
  setTimeout(() => {
    store.dispatch(resetPosts!());
    store.dispatch(resetGroups!());
  }, 1);
  setTimeout(() => {
    store.dispatch(resetPosts!());
    store.dispatch(resetGroups!());
  }, 500);
}
// Reset store data that depends on selected server/account.
export function resetAllData() {
  // setTimeout(() => {
  store.dispatch(resetServers());
  store.dispatch(resetAccounts());
  store.dispatch(resetPosts!());
  store.dispatch(resetGroups!());
  store.dispatch(resetLocalApp());
  // }, 1);
}

export default store;


const clients = new Map<string, JonlineClientImpl>();
export async function getServerClient(server: JonlineServer): Promise<Jonline> {
  let host = `${serverUrl(server).replace(":", "://")}:27707`;
  if (!clients.has(host)) {
    let client = new JonlineClientImpl(
      new GrpcWebImpl(host, {
        transport: Platform.OS == 'web' ? undefined : ReactNativeTransport({})
      })
    );
    clients.set(host, client);
    try {
      let serviceVersion = await Promise.race([client.getServiceVersion({}), timeout(5000, "service version")]);
      let serverConfiguration = await Promise.race([client.getServerConfiguration({}), timeout(5000, "server configuration")]);
      store.dispatch(upsertServer({ ...server, serviceVersion, serverConfiguration }));
    } catch (e) {
      clients.delete(host);
    }
    return client;
  }
  return clients.get(host)!;
}
const timeout = async (time: number, label: string) => {
  await new Promise((res) => setTimeout(res, time));
  throw `Timed out getting ${label}.`;
}