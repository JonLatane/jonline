import { AppDispatch, Config, RootState, useRootSelector } from "app/store";
import { useDispatch } from "react-redux";

export function useAppDispatch(): AppDispatch {
  return useDispatch<AppDispatch>()
};

export type Selector<S> = (state: RootState) => S;
export const useAppSelector = useRootSelector;

export function useLocalConfiguration(): Config {
  return useAppSelector(state => state.config);
}
