import { combineReducers, configureStore } from "@reduxjs/toolkit";
import { createSelectorHook, useDispatch } from "react-redux";
import FactsReducer from "./modules/Facts";
import AccountsReducer from "./modules/Accounts";
import ServersReducer from "./modules/Servers";

const rootReducer = combineReducers({
  facts: FactsReducer,
  accounts: AccountsReducer,
  servers: ServersReducer
});

export type RootState = ReturnType<typeof rootReducer>;
export const useTypedSelector = createSelectorHook();
export const useTypedDispatch = useDispatch;

const saver = (store) => next => action => {
  let stateToSave = store.getState();
  localStorage.setItem("servers", JSON.stringify({ ...stateToSave.servers }))
  localStorage.setItem("accounts", JSON.stringify({ ...stateToSave.accounts }))
  return next(action);
}
const store = configureStore({ reducer: rootReducer, middleware: [saver] });
export default store;
