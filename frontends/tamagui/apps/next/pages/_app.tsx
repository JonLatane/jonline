import '@tamagui/core/reset.css'
// import '@tamagui/font-inter/css/400.css'
// import '@tamagui/font-inter/css/700.css'
import 'raf/polyfill'

import { NextThemeProvider, useRootTheme } from '@tamagui/next-theme'
import { Provider } from 'app/provider'
import Head from 'next/head'
import React, { startTransition } from 'react'
import type { SolitoAppProps } from 'solito'
import { isSafari } from '@jonline/ui'
import { QueryClient, QueryClientProvider, useQuery } from '@tanstack/react-query';

const queryClient = new QueryClient();

if (process.env.NODE_ENV === 'production') {
  require('../public/tamagui.css')
}
require('../public/select-fix.css')

function MyApp({ Component, pageProps }: SolitoAppProps) {
  // usePreserveScroll();
  React.useEffect(() => {
    // Taken from StackOverflow. Trying to detect both Safari desktop and mobile.
    // const isSafari = /^((?!chrome|android).)*safari/i.test(navigator.userAgent);
    if (isSafari()) {
      // This is kind of a lie.
      // We still rely on the manual Next.js scrollRestoration logic.
      // However, we *also* don't want Safari grey screen during the back swipe gesture.
      // Seems like it doesn't hurt to enable auto restore *and* Next.js logic at the same time.
      history.scrollRestoration = 'auto';
    } else {
      // For other browsers, let Next.js set scrollRestoration to 'manual'.
      // It seems to work better for Chrome and Firefox which don't animate the back swipe.
    }
  }, []);

  const SolitoComponentShim = Component as any;

  return (
    <>
      <Head>
        <title>Jonline</title>
        <meta name="description" content="Jonline is a decentralized, federated, easy-to-deploy social network built in Rust and gRPC, with Flutter and Web frontends." />
        {/* <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1" /> */}
        {/* <meta name="viewport" content="viewport-fit=cover" /> */}
        <link rel="icon" href="/favicon.ico" />
        <link rel="apple-touch-icon" href="/favicon.ico" />

        <meta httpEquiv="X-UA-Compatible" content="IE=edge" />

        {/** Note that these tags must be findable by tamagui_web.rs, so Jonline's Rust server 
         * can override them with Post/Event titles, images, etc. */}
        <meta property="og:title" content="Jonline Social Link" />
        <meta property="og:description" content="A link from a fediverse community with events, posts, and realtime chat" />
        <meta property="og:image" content="/favicon.ico" />
        <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, viewport-fit=cover" />

        <link rel="manifest" href="/manifest.json" />


        {/* <link rel="icon" href="/favicon.ico" sizes="any" type="image/svg+xml" />
        <link rel="apple-touch-icon" href="/favicon.ico"/>
        <link rel="manifest" href="/site.webmanifest" /> */}

        {/* <link rel="icon" href="/favicon.ico" /> */}
        {/* <link rel="mask-icon" href="/favicon.ico" color="#000000" /> */}

      </Head>

      <QueryClientProvider client={queryClient}>
        <ThemeProvider>
          <SolitoComponentShim {...pageProps} />
        </ThemeProvider>
      </QueryClientProvider>
    </>
  )
}

function ThemeProvider({ children }: { children: React.ReactNode }) {
  const [theme, setTheme] = useRootTheme()

  return (
    <NextThemeProvider
      onChangeTheme={(next) => {
        setTheme(next as any)
      }}
    >
      <Provider disableRootThemeClass defaultTheme={theme}>
        {children}
      </Provider>
    </NextThemeProvider>
  )
}

export default MyApp
