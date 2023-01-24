import { combineReducers, configureStore } from "@reduxjs/toolkit";
import { createSelectorHook, useDispatch } from "react-redux";
import thunkMiddleware from 'redux-thunk';
import accountsReducer from "./modules/accounts";
import serversReducer from "./modules/servers";
import postsReducer from "./modules/posts";
import { persistStore, persistReducer } from 'redux-persist'
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
  blacklist: ['status', 'successMessage', 'errorMessage', 'error']
}

const rootReducer = combineReducers({
  accounts: persistReducer(accountsPersistConfig, accountsReducer),
  servers: persistReducer(serversPersistConfig, serversReducer),
  posts: persistReducer(postsPersistConfig, postsReducer)
});

const rootPersistConfig = {
  key: 'root',
  storage: Platform.OS == 'web' ? storage : AsyncStorage,
  blacklist: ['accounts', 'servers', 'posts']
}
const persistedReducer = persistReducer(rootPersistConfig, rootReducer)

export type RootState = ReturnType<typeof rootReducer>;
export const useTypedSelector = createSelectorHook();
export const useTypedDispatch = () => useDispatch<any>();


const store = configureStore({ reducer: persistedReducer, middleware: [thunkMiddleware] });
export const persistor = persistStore(store);


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

