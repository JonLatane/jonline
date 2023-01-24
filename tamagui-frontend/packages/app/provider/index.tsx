import config from '../tamagui.config'
import { NavigationProvider } from './navigation'
import { TamaguiProvider, TamaguiProviderProps } from '@jonline/ui'
import { PersistGate } from 'redux-persist/integration/react'
import store, { persistor } from "../store/store";
import { Provider as ReduxProvider } from "react-redux";


export function Provider({ children, ...rest }: Omit<TamaguiProviderProps, 'config'>) {
  return (
    <ReduxProvider store={store}>
      <PersistGate loading={null} persistor={persistor}>
        <TamaguiProvider config={config} disableInjectCSS {...rest}>
          <NavigationProvider>{children}</NavigationProvider>
        </TamaguiProvider>
      </PersistGate>
    </ReduxProvider>
  )
}
