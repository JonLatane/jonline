import config from '../tamagui.config'
import { NavigationProvider } from './navigation'
import { TamaguiProvider, TamaguiProviderProps } from '@jonline/ui'
import { PersistGate } from 'redux-persist/integration/react'
import {store, persistor} from "app/store";
import { Provider as ReduxProvider } from "react-redux";


export function Provider({ children, ...rest }: Omit<TamaguiProviderProps, 'config'>) {
  // When/if redux-persist is updated to support React 18, this shim can be removed.
  const PersistGateShim = PersistGate as any;
  return (
    <ReduxProvider store={store}>
      <PersistGateShim loading={null} persistor={persistor}>
        <TamaguiProvider config={config} disableInjectCSS {...rest}>
          <NavigationProvider>{children}</NavigationProvider>
        </TamaguiProvider>
      </PersistGateShim>
    </ReduxProvider>
  )
}
