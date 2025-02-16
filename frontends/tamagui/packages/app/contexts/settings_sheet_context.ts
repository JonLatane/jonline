import { JonlineServer } from "app/store";
import { createContext, useContext, useState } from "react";

export type GetSet<T> = [T, (v: T) => void];

type SettingsSheetContextType = {
  open: GetSet<boolean>;//[boolean, (v: boolean) => void];  
};

export const SettingsSheetContext = createContext<SettingsSheetContextType>({
  open: [false, () => { console.warn('SettingsSheetContextProvider not set.') }]
  // selectedSettingsSheett: undefined,
  // setSharingPostId: () => { console.warn('SettingsSheettContextProvider not set.') },
  // setInfoSettingsSheettId: () => { console.warn('SettingsSheettContextProvider not set.') },
});

export const SettingsSheetContextProvider = SettingsSheetContext.Provider;
export const SettingsSheetContextConsumer = SettingsSheetContext.Consumer;
export const useSettingsSheetContext = () => useContext(SettingsSheetContext);
export function useNewSettingsSheetContext(): SettingsSheetContextType {
  const [open, setOpen] = useState(false);
  return { open: [open, setOpen] };
}
