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
          backdrop-filter: blur(3px);
          -webkit-backdrop-filter: blur(3px);
        }
        .bottomChrome {
            padding-bottom: env(safe-area-inset-bottom, 0);
        }
        .keyboard-open .bottomChrome {
            padding-bottom: 0!important;
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
        </Head>
        <body>
          <Main />
          <NextScript />
        </body>
      </Html>
    )
  }
}
