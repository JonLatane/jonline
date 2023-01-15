import { combineReducers, configureStore } from "@reduxjs/toolkit";
import { createSelectorHook, useDispatch } from "react-redux";
import thunkMiddleware from 'redux-thunk';
import FactsReducer from "./modules/Facts";
import AccountsReducer from "./modules/Accounts";
import ServersReducer from "./modules/Servers";
import { persistStore, persistReducer } from 'redux-persist'
import storage from 'redux-persist/lib/storage' // defaults to localStorage for web

// import 'localstorage-polyfill';

const rootReducer = combineReducers({
  facts: FactsReducer,
  accounts: AccountsReducer,
  servers: ServersReducer
});
const persistConfig = {
  key: 'root',
  storage,
}

const persistedReducer = persistReducer(persistConfig, rootReducer)

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

