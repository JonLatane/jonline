import NextDocument, { Head, Html, Main, NextScript } from 'next/document'
import { Children } from 'react'
import { AppRegistry } from 'react-native'

import Tamagui from '../tamagui.config'

export default class Document extends NextDocument {
  static async getInitialProps({ renderPage }: any) {
    AppRegistry.registerComponent('Main', () => Main)
    const page = await renderPage()

    // @ts-ignore
    const { getStyleElement } = AppRegistry.getApplication('Main')

    /**
     * Note: be sure to keep tamagui styles after react-native-web styles like it is here!
     * So Tamagui styles can override the react-native-web styles.
     */
    const styles = [
      getStyleElement(),
      <style key="tamagui-css" dangerouslySetInnerHTML={{ __html: Tamagui.getCSS() }} />,
      <style key='jonline-css' dangerouslySetInnerHTML={{
        __html: `
        .blur {
          backdrop-filter: blur(12px);
          -webkit-backdrop-filter: blur(12px);
        }
        .postMarkdown {
          color: white;
        }
        .postMarkdown ul li::before {
          color:white;
          content: "•";
          margin-right: 0.5em;
          margin-left: 0.5em;
        }
      `}} />
    ]

    return { ...page, styles: Children.toArray(styles) }
  }

  render() {
    return (
      <Html>
        <Head>
          <meta httpEquiv="X-UA-Compatible" content="IE=edge" />

          {/** Note that these tags must be findable by tamagui_web.rs, so Jonline's Rust server 
           * can override them with Post/Event titles, images, etc. */}
          <meta property="og:title" content="Jonline Social Link" />
          <meta property="og:description" content="A link from a fediverse community with events, posts, and realtime chat" />
          <meta property="og:image" content="/favicon.ico" />

          <link rel="manifest" href="/manifest.json" />
        </Head>
        <body>
          <Main />
          <NextScript />
        </body>
      </Html>
    )
  }
}
