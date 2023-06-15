import { createAnimations } from '@tamagui/animations-react-native';
// import { createAnimations } from '@tamagui/animations-css';


// export const animations = createAnimations({
//   bouncy: 'ease-in 300ms',
//   lazy: 'ease-in 500ms',
//   quick: 'ease-in 100ms',
// });

export const animations = createAnimations({
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
});


export const standardAnimation = {
  o: 1,
  scale: 1,
  y: 0,
  enterStyle: { y: -50, o: 0, },
  exitStyle: { y: -50, o: 0, },
}