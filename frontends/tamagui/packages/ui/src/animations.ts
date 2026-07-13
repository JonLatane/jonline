import { createAnimations } from '@tamagui/animations-react-native';

// NOTE: tried switching to @tamagui/animations-css here to avoid the array-style
// crash on Button's raw <button> render target (see git history), but its
// `transition: all` output broke layout site-wide on any element whose non-animated
// style props (e.g. height) change across renders, and enter/exit transitions got
// stuck mid-offset app-wide. Reverted; the render-target crash needs a narrower fix.
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
  '200ms': {
    type: 'timing',
    duration: 200,
  },
  '300ms': {
    type: 'timing',
    duration: 300,
  },
  '400ms': {
    type: 'timing',
    duration: 400,
  },
  '500ms': {
    type: 'timing',
    duration: 500,
  },
  '600ms': {
    type: 'timing',
    duration: 600,
  },
  '700ms': {
    type: 'timing',
    duration: 700,
  },
  '800ms': {
    type: 'timing',
    duration: 800,
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
  exitStyle: { y: -29, o: 0},
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