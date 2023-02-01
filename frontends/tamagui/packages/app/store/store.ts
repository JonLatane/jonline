import { AnyAction, combineReducers, configureStore, Dispatch, Store, ThunkDispatch } from "@reduxjs/toolkit";
import { createSelectorHook, useDispatch } from "react-redux";
import thunkMiddleware from 'redux-thunk';
import {AccountOrServer, JonlineServer} from './types'
import accountsReducer, { resetAccounts } from "./modules/accounts";
import serversReducer, {resetServers, serverUrl, upsertServer} from "./modules/servers";
import localAppReducer, {resetLocalApp} from "./modules/local_app";
import postsReducer, { resetPosts } from "./modules/posts";
import { persistStore, persistReducer, FLUSH, REHYDRATE, PAUSE, PERSIST, PURGE, REGISTER } from 'redux-persist'
import storage from 'redux-persist/lib/storage'
import { Platform } from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { Jonline, JonlineClientImpl } from "@jonline/ui/src";
import { GrpcWebImpl } from "@jonline/ui/src/generated/jonline";
import { ReactNativeTransport } from "@improbable-eng/grpc-web-react-native-transport";

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

const rootReducer = combineReducers({
  app: localAppReducer,
  accounts: persistReducer(accountsPersistConfig, accountsReducer),
  servers: persistReducer(serversPersistConfig, serversReducer),
  posts: persistReducer(postsPersistConfig, postsReducer)
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
const store: AppStore = configureStore({
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
  }, 1);
}
// Reset store data that depends on selected server/account.
export function resetAllData() {
  // setTimeout(() => {
    store.dispatch(resetServers());
    store.dispatch(resetAccounts());
    store.dispatch(resetPosts!());
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