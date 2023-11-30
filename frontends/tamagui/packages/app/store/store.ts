import AsyncStorage from '@react-native-async-storage/async-storage';
import { AnyAction, PayloadAction, Store, ThunkDispatch, combineReducers, configureStore } from "@reduxjs/toolkit";
import { Platform } from 'react-native';
import { createSelectorHook, useDispatch } from "react-redux";
import { FLUSH, PAUSE, PERSIST, PURGE, REGISTER, REHYDRATE, persistReducer, persistStore } from 'redux-persist';
import storage from 'redux-persist/lib/storage';
import thunkMiddleware from 'redux-thunk';
import { LocalAppConfiguration, accountsReducer, eventsReducer, groupsReducer, localAppReducer, mediaReducer, postsReducer, resetAccounts, resetGroups, resetLocalConfiguration, resetMedia, resetPosts, resetServers, resetUsers, serversReducer, usersReducer } from "./modules";

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
  media: mediaReducer,
  posts: postsReducer, // persistReducer(postsPersistConfig, postsReducer),
  events: eventsReducer,
  users: usersReducer, // persistReducer(usersPersistConfig, usersReducer),
  groups: groupsReducer, // persistReducer(groupsPersistConfig, groupsReducer)
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
export function useAppDispatch(): AppDispatch {
  return useDispatch<AppDispatch>()
};

export function useLocalConfiguration(): LocalAppConfiguration {
  return useTypedSelector((state: RootState) => state.app);
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

export const actionSucceeded = (action: PayloadAction<any, string, any, any> | undefined | unknown) => !actionFailed(action);
export const actionFailed = (action: PayloadAction<any, string, any, any> | undefined | unknown) =>
  action && Object.keys(action).includes('type') && (action as PayloadAction<any, string, any, any>).type.endsWith('rejected');
// !!(action?.type.endsWith('rejected'));

// Reset store data that depends on selected server/account.
export function resetAllData() {
  store.dispatch(resetServers());
  store.dispatch(resetAccounts());
  store.dispatch(resetPosts!());
  store.dispatch(resetGroups!());
  store.dispatch(resetUsers!());
  store.dispatch(resetMedia!());
  store.dispatch(resetLocalConfiguration());
}
