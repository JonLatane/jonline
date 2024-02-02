/** @type {import('next').NextConfig} */
const { withTamagui } = require('@tamagui/next-plugin')
// const withImages = require('next-images')
const { join } = require('path')

// process.env.IGNORE_TS_CONFIG_PATHS = 'true'
// process.env.TAMAGUI_TARGET = 'web'
// process.env.TAMAGUI_DISABLE_WARN_DYNAMIC_LOAD = '1'

const boolVals = {
  true: true,
  false: false,
}

const disableExtraction =
  boolVals[process.env.DISABLE_EXTRACTION] ?? process.env.NODE_ENV === 'development'

console.log(`
Building the Jonline Tamagui/React Frontend! Real distributions should be served by Rust/Rocket; this Next.js server is for dev only.

You can update this monorepo to the latest Tamagui release by running:

yarn upgrade:tamagui
`)
// We've set up a few things for you.

// See the "excludeReactNativeWebExports" setting in next.config.js, which omits these
// from the bundle: Switch, ProgressBar Picker, CheckBox, Touchable. To save more,
// you can add ones you don't need like: AnimatedFlatList, FlatList, SectionList,
// VirtualizedList, VirtualizedSectionList.

// Even better, enable "useReactNativeWebLite" and you can remove the
// excludeReactNativeWebExports setting altogether and get tree-shaking and
// concurrent mode support as well.

const plugins = [
  // withImages,
  withTamagui({
    config: './tamagui.config.ts',
    components: ['tamagui', '@jonline/ui'],
    importsWhitelist: ['constants.js', 'colors.js'],
    outputCSS: process.env.NODE_ENV === 'production' ? './public/tamagui.css' : null,
    logTimings: true,
    disableExtraction,
    // experiment - reduced bundle size react-native-web
    // useReactNativeWebLite: true,
    shouldExtract: (path) => {
      if (path.includes(join('packages', 'app'))) {
        return true
      }
    },
    
    // excludeReactNativeWebExports: ['Switch', 'ProgressBar', 'Picker', 'CheckBox', 'Touchable', 'FlatList', 'SectionList', 'VirtualizedList', 'VirtualizedSectionList'],
  }),
]

// module.exports = {
// }

module.exports = function () {
  /** @type {import('next').NextConfig} */
  let config = {
    output: 'export', //'export', 'standalone'
    typescript: {
      ignoreBuildErrors: true,
    },
    modularizeImports: {
      '@tamagui/lucide-icons': {
        transform: `@tamagui/lucide-icons/dist/esm/icons/{{kebabCase member}}`,
        skipDefaultConversion: true,
      },
    },
    // images: {
    //   disableStaticImages: true,
    // },
    transpilePackages: [
      'solito',
      'react-native-web',
      'expo-linking',
      'expo-constants',
      'expo-modules-core',
    ],
    webpack(webpackConfig) {
      return {
        ...webpackConfig,
        // Comment this out if you'd like to disable minification. Jonline typically
        // expects its HTML to come from a CDN which will do this, and leaving it unminified
        // on the server costs only about 300kB difference in first load JS. But it's
        // helpful for debugging, and non-minified JS is also meant to push the open web
        // and make it easy for anyone to get involved!
        //
        // To debug production jonline.io code, just go to jonline.io.getj.online
        // and you'll be running without the CDN and able to trace through the un-minified
        // (still-transpiled-from-TS, but very readable) JavaScript.
        optimization: {
          minimizer: [],
          minimize: true
        }
      };
    },
    experimental: {
      scrollRestoration: true,
    },
  }

  for (const plugin of plugins) {
    config = {
      ...config,
      ...plugin(config),
    }
  }

  return config
}
