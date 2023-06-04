import { createAnimations } from '@tamagui/animations-react-native'
// import { createAnimations } from '@tamagui/animations-css'

export const animations = createAnimations({
  // fast: 'ease-in 150ms',
  // medium: 'ease-in 300ms',
  // slow: 'ease-in 450ms',
  bouncy: {
    type: 'spring',
    damping: 10,
    mass: 0.9,
    stiffness: 100,
  },
  lazy: {
    type: 'spring',
    damping: 20,
    stiffness: 60,
  },
  quick: {
    type: 'spring',
    damping: 20,
    mass: 1.2,
    stiffness: 250,
  }
})
