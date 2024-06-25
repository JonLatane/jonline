import { AppDispatch, LocalAppConfiguration, RootState, useRootSelector } from "app/store";
import { useDispatch } from "react-redux";

export function useAppDispatch(): AppDispatch {
  return useDispatch<AppDispatch>()
};

export type Selector<S> = (state: RootState) => S;
export const useAppSelector = useRootSelector;

export function useLocalConfiguration(): LocalAppConfiguration {
  return useAppSelector(state => state.app);
}
