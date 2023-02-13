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
import { accountsReducer, groupsReducer, LocalAppConfiguration, localAppReducer, postsReducer, resetAccounts, resetGroups, resetLocalApp, resetPosts, resetServers, resetUsers, serversReducer, serverUrl, upsertServer, usersReducer } from "./modules";
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
  blacklist: ['status', 'baseStatus', 'successMessage', 'errorMessage', 'error', 'previews'],
}
const usersPersistConfig = {
  key: 'users',
  storage: Platform.OS == 'web' ? storage : AsyncStorage,
  blacklist: ['status', 'successMessage', 'errorMessage', 'error', 'avatars', 'usernameIds', 'failedUsernames', 'failedUserIds'],
}

const groupsPersistConfig = {
  key: 'groups',
  storage: Platform.OS == 'web' ? storage : AsyncStorage,
  blacklist: ['status', 'successMessage', 'errorMessage', 'error', 'avatars', 'shortnameIds', 'failedShortnames'],
}

const rootReducer = combineReducers({
  app: localAppReducer,
  accounts: persistReducer(accountsPersistConfig, accountsReducer),
  servers: persistReducer(serversPersistConfig, serversReducer),
  posts: postsReducer, // persistReducer(postsPersistConfig, postsReducer),
  users: usersReducer, // persistReducer(usersPersistConfig, usersReducer),
  groups: groupsReducer, // persistReducer(groupsPersistConfig, groupsReducer)
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

export type ServerInfo = {
  server?: JonlineServer;
  primaryColor: string;
  navColor: string;
  primaryTextColor: string;
  navTextColor: string;
}
export function useServerInfo(): ServerInfo {
  const server = useTypedSelector((state: RootState) => state.servers.server);
  const primaryColorInt = server?.serverConfiguration?.serverInfo?.colors?.primary;
  const primaryColor = `#${(primaryColorInt)?.toString(16).slice(-6) || '424242'}`;
  const navColorInt = server?.serverConfiguration?.serverInfo?.colors?.navigation;
  const navColor = `#${(navColorInt)?.toString(16).slice(-6) || 'FFFFFF'}`;

  const primaryTextColor = textColor(primaryColor);
  const navTextColor = textColor(navColor);

  return { server, primaryColor, navColor, primaryTextColor, navTextColor };
}

export function useLocalApp(): LocalAppConfiguration {
  return useTypedSelector((state: RootState) => state.app);
}

const _textColors = new Map<string, string>();
function textColor(hex: string) {
  if (_textColors.has(hex)) {
    return _textColors[hex];
  }
  const parsed = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
  const rgb = parsed ? {
    r: parseInt(parsed[1]!, 16),
    g: parseInt(parsed[2]!, 16),
    b: parseInt(parsed[3]!, 16)
  } : null;
  const { r, g, b } = rgb!;
  const red = r / 255;
  const green = g / 255;
  const blue = b / 255;
  const luma = 0.2126 * red + 0.7152 * green + 0.0722 * blue;
  const result = luma > 0.5 ? '#000000' : '#ffffff';
  _textColors[hex] = result;
  return result;
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
    store.dispatch(resetUsers!());
  }, 1);
}
export function loadingCredentialedData() {
  return useTypedSelector((state: RootState) => state.posts.status == 'loading'
    || state.groups.status == 'loading'
    || state.users.status == 'loading');
}
// Reset store data that depends on selected server/account.
export function resetAllData() {
  store.dispatch(resetServers());
  store.dispatch(resetAccounts());
  store.dispatch(resetPosts!());
  store.dispatch(resetGroups!());
  store.dispatch(resetUsers!());
  store.dispatch(resetLocalApp());
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