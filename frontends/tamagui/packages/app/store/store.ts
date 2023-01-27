import { AnyAction, combineReducers, configureStore, Dispatch, Store, ThunkDispatch } from "@reduxjs/toolkit";
import { createSelectorHook, useDispatch } from "react-redux";
import thunkMiddleware from 'redux-thunk';
import accountsReducer, { AccountOrServer, JonlineAccount } from "./modules/accounts";
import serversReducer, { JonlineServer } from "./modules/servers";
import localAppReducer, { LocalAppConfiguration } from "./modules/local_app";
import postsReducer, { RemovePostPreviews } from "./modules/posts";
import { persistStore, persistReducer, FLUSH, REHYDRATE, PAUSE, PERSIST, PURGE, REGISTER } from 'redux-persist'
import storage from 'redux-persist/lib/storage'
import { Platform } from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';

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
  blacklist: ['status', 'successMessage', 'errorMessage', 'error'],
  transforms: [RemovePostPreviews]
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
  account_or_server: AccountOrServer;
};
export function useCredentialDispatch(): CredentialDispatch {
  let dispatch: AppDispatch = useTypedDispatch();
  let account: AccountOrServer | undefined = useTypedSelector((state: RootState) => state.accounts.account);
  let server: JonlineServer = useTypedSelector((state: RootState) => state.servers.server)!;
  if (account) {
    return { dispatch, account_or_server: account };
  }
  return { dispatch, account_or_server: server };
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
export const persistor = persistStore(store, {

});


// store.subscribe(() => {
//   localStorage.setItem("servers", JSON.stringify({ ...store.getState().servers }));
//   localStorage.setItem("accounts", JSON.stringify({ ...store.getState().accounts }));
// })

export default store;
// export default () => {
//   let store = configureStore({ reducer: rootReducer, middleware: [thunkMiddleware] });
//   let persistor = persistStore(store);
//   return { store, persistor }
// }

