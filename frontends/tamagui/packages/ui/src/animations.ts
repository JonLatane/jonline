import { createAnimations } from '@tamagui/animations-react-native';
// import { AnimationDriver } from '@tamagui/use-presence';
// import { createAnimations } from '@tamagui/animations-css';


// export const animations = createAnimations({
//   bouncy: 'ease-in 300ms',
//   lazy: 'ease-in 500ms',
//   quick: 'ease-in 100ms',
// });

export const animations = createAnimations({

  // TODO: Maybe standard for web, bouncy for native/iOS?
  // Only worth any effort if we wanted to ship the iOS version of the Tamagui app...
  standard: {
    type: 'timing',
    duration: 300,
  },
  '100ms': {
    type: 'timing',
    duration: 100,
  },
  bouncy: {
    damping: 9,
    mass: 0.9,
    stiffness: 150,
  },
  lazy: {
    damping: 18,
    stiffness: 50,
  },
  medium: {
    damping: 15,
    stiffness: 120,
    mass: 1,
  },
  slow: {
    damping: 15,
    stiffness: 40,
  },
  quick: {
    damping: 20,
    mass: 1.2,
    stiffness: 250,
  },
  tooltip: {
    damping: 10,
    mass: 0.9,
    stiffness: 100,
  },
});

export const standardAnimation = {
  o: 1,
  y: 0,
  enterStyle: { y: -29, o: 0, },
  exitStyle: { y: -29, o: 0, },
}

export const reverseStandardAnimation = {
  o: 1,
  y: 0,
  enterStyle: { y: 29, o: 0, },
  exitStyle: { y: 29, o: 0, },
}

export const standardHorizontalAnimation = {
  o: 1,
  x: 0,
  enterStyle: { x: -29, o: 0, },
  exitStyle: { x: -29, o: 0, },
}

export const reverseHorizontalAnimation = {
  o: 1,
  x: 0,
  enterStyle: { x: 29, o: 0, },
  exitStyle: { x: -29, o: 0, },
}

export const standardFadeAnimation = createFadeAnimation(1);

export function createFadeAnimation(opacity: number) {
  return {
    o: opacity,
    enterStyle: { o: 0, },
    exitStyle: { o: 0, },
  };
}

export const overlayAnimation = {
  ...standardFadeAnimation,
  o: 0.5,
}

export function sheetOverlayAnimation(open: boolean) {
  return {
    o: open ? 0.7 : 0,
  }
}