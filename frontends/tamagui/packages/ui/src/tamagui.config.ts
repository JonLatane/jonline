import { createTamagui } from 'tamagui'
import { createInterFont } from '@tamagui/font-inter'
import { shorthands } from '@tamagui/shorthands'
import { themes, tokens } from '@tamagui/themes'
import { createMedia } from '@tamagui/react-native-media-driver'
import { createFont } from '@tamagui/core'

import { animations } from './animations'

const headingFont = createInterFont({
  size: {
    6: 15,
  },
  transform: {
    6: 'uppercase',
    7: 'none',
  },
  weight: {
    6: '400',
    7: '700',
  },
  color: {
    6: '$colorFocus',
    7: '$color',
  },
  letterSpacing: {
    5: 2,
    6: 1,
    7: 0,
    8: -1,
    9: -2,
    10: -3,
    12: -4,
    14: -5,
    15: -6,
  },
  face: {
    700: { normal: 'InterBold' },
  },
})

const bodyFont = createInterFont(
  {
    face: {
      700: { normal: 'InterBold' },
    },
  },
  {
    sizeSize: (size) => Math.round(size * 1.03),
    sizeLineHeight: (size) => Math.round(size * 1.03 + (size > 20 ? 10 : 10)),
  }
)

const monoFont = createFont({
  family: '"SFMono-Regular", "SF Mono", Menlo, Monaco, Consolas, Ubuntu Mono, "Liberation Mono", Fira Code, monospace',
  size: {
    1: 11,
    2: 12,
    3: 13,
    4: 14,
    5: 15,
    6: 16,
    7: 18,
    8: 21,
    9: 28,
    10: 42,
    11: 52,
    12: 62,
    13: 72,
    14: 92,
    15: 114,
    16: 124,
  },
  weight: {
    4: '400',
  },
});

export const config = createTamagui({
  defaultFont: 'body',
  animations,
  shouldAddPrefersColorThemes: true,
  themeClassNameOnRoot: true,
  shorthands,
  fonts: {
    heading: headingFont,
    body: bodyFont,
    mono: monoFont,
  },
  themes,
  tokens,
  media: createMedia({
    xxxxxxs: { maxWidth: 110 },
    gtXxxxxxs: { minWidth: 110 + 1 },
    xxxxxs: { maxWidth: 220 },
    gtXxxxxs: { minWidth: 220 + 1 },
    xxxxs: { maxWidth: 330 },
    gtXxxxs: { minWidth: 330 + 1 },
    xxxs: { maxWidth: 440 },
    gtXxxs: { minWidth: 440 + 1 },
    xxs: { maxWidth: 550 },
    gtXxs: { minWidth: 550 + 1 },
    xs: { maxWidth: 660 },
    gtXs: { minWidth: 660 + 1 },
    sm: { maxWidth: 800 },
    gtSm: { minWidth: 800 + 1 },
    md: { maxWidth: 1020 },
    gtMd: { minWidth: 1020 + 1 },
    lg: { maxWidth: 1280 },
    gtLg: { minWidth: 1280 + 1 },
    xl: { maxWidth: 1420 },
    gtXl: { minWidth: 1420 + 1 },
    xxl: { maxWidth: 1600 },
    gtXxl: { minWidth: 1600 + 1 },
    short: { maxHeight: 820 },
    tall: { minHeight: 820 },
    hoverNone: { hover: 'none' },
    pointerCoarse: { pointer: 'coarse' },
  }),
})
