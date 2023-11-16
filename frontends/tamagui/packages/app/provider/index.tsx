import config from '../tamagui.config'
import { NavigationProvider } from './navigation'
import { TamaguiProvider, TamaguiProviderProps, ToastProvider, CustomToast } from '@jonline/ui'
import { PersistGate } from 'redux-persist/integration/react'
import { store, persistor } from "app/store";
import { Provider as ReduxProvider } from "react-redux";
import { ToastViewport } from './ToastViewport'


export function Provider({ children, ...rest }: Omit<TamaguiProviderProps, 'config'>) {
  // When/if redux-persist is updated to support React 18, this shim can be removed.
  const PersistGateShim = PersistGate as any;
  return (
    <ReduxProvider store={store}>
      <PersistGateShim loading={null} persistor={persistor}>
        <TamaguiProvider
          config={config}
          disableInjectCSS
          {...rest}
        >
          <ToastProvider
            swipeDirection="horizontal"
            duration={6000}
            native={
              [
                /* uncomment the next line to do native toasts on mobile. NOTE: it'll require you making a dev build and won't work with Expo Go */
                // 'mobile'
              ]
            }
          >
            {children}

            <CustomToast />
            {/* <ToastViewport multipleToasts flexDirection="column" bottom={75} right={5} /> */}
          </ToastProvider>
          {/* <NavigationProvider>{children}</NavigationProvider> */}
        </TamaguiProvider>
      </PersistGateShim>
    </ReduxProvider>
  )
}
