import AsyncStorage from '@react-native-async-storage/async-storage';
import { AnyAction, PayloadAction, Store, ThunkDispatch, combineReducers, configureStore } from "@reduxjs/toolkit";
import { Platform } from 'react-native';
import { createSelectorHook } from "react-redux";
import { FLUSH, PAUSE, PERSIST, PURGE, REGISTER, REHYDRATE, persistReducer, persistStore } from 'redux-persist';
import storage from 'redux-persist/lib/storage';
import thunkMiddleware from 'redux-thunk';
import { accountsReducer, eventsReducer, groupsReducer, localAppReducer, mediaReducer, postsReducer, resetAccounts, resetGroups, resetLocalConfiguration, resetMedia, resetPosts, resetServers, resetUsers, serversReducer, usersReducer } from "./modules";
import { postsApi } from './apis/posts_api';

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
  blacklist: ['status', 'pagesStatus', 'successMessage', 'errorMessage', 'error', 'previews'],
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
  media: mediaReducer,
  posts: postsReducer, // persistReducer(postsPersistConfig, postsReducer),
  events: eventsReducer,
  users: usersReducer, // persistReducer(usersPersistConfig, usersReducer),
  groups: groupsReducer, // persistReducer(groupsPersistConfig, groupsReducer)
  [postsApi.reducerPath]: postsApi.reducer
});

const rootPersistConfig = {
  key: 'root',
  storage: Platform.OS == 'web' ? storage : AsyncStorage,
  whitelist: ['app'],
  // blacklist: ['accounts', 'servers', 'posts', 'users', 'groups'],
  // transforms: [RemovePostPreviews]
}
const persistedReducer = persistReducer(rootPersistConfig, rootReducer)

export type RootState = ReturnType<typeof rootReducer>;
const useTypedSelector = createSelectorHook();
export function useRootSelector<T>(selector: (state: RootState) => T): T {
  return useTypedSelector(selector);
}

export type AppDispatch = ThunkDispatch<RootState, any, AnyAction>;

export type AppStore = Omit<Store<RootState, AnyAction>, "dispatch"> & {
  dispatch: AppDispatch;
};

export const store: AppStore = configureStore({
  reducer: persistedReducer,
  middleware: (getDefaultMiddleware) => [...getDefaultMiddleware({
    serializableCheck: {
      ignoredActions: [FLUSH, REHYDRATE, PAUSE, PERSIST, PURGE, REGISTER],
    }
  }), thunkMiddleware, postsApi.middleware],
});

export const persistor = persistStore(store);

export const actionSucceeded = (action: PayloadAction<any, string, any, any> | undefined | unknown) => !actionFailed(action);
export const actionFailed = (action: PayloadAction<any, string, any, any> | undefined | unknown) =>
  action && Object.keys(action).includes('type') && (action as PayloadAction<any, string, any, any>).type.endsWith('rejected');
// !!(action?.type.endsWith('rejected'));

// Reset store data that depends on selected server/account.
export function resetAllData() {
  const serverHosts = store.getState().servers
    .ids.map(id => (id as string).split(':')[1]);
  store.dispatch(resetServers());
  store.dispatch(resetAccounts());
  serverHosts.forEach(serverHost => {
    store.dispatch(resetPosts({ serverHost }));
    store.dispatch(resetGroups({ serverHost }));
    store.dispatch(resetUsers({ serverHost }));
    store.dispatch(resetMedia({ serverHost }));
  });
  store.dispatch(resetLocalConfiguration());
}
