import { useDebounceValue, useMedia } from '@jonline/ui';
import useDetectScroll, { Axis, Direction } from '@smakss/react-scroll-direction';
import { useAppDispatch, useLocalConfiguration } from 'app/hooks';
import { setHideNavigation, setShowPinnedServers } from 'app/store';
import { useEffect, useState } from 'react';

export function useHideNavigation() {
  const mediaQuery = useMedia();
  const { scrollDir, scrollPosition } = useDetectScroll({
    thr: 30,
    axis: Axis.Y,
    scrollUp: Direction.Up,
    scrollDown: Direction.Down,
    still: Direction.Still
  })
  const { showPinnedServers, autoHideNavigation, hideNavigation: hideNavigationSetting } = useLocalConfiguration();
  const autoHide = mediaQuery.xShort || autoHideNavigation;
  const [hideLock, setHideLock] = useState(false);
  // const [hide, _setHide] = useState(false);
  const hide = hideNavigationSetting;
  function setHide(value: boolean) {
    setHideLock(true);
    dispatch(setHideNavigation(value));
    setTimeout(() => setHideLock(false), 1000);
  }
  const [lastScrollDir, setLastScrollDir] = useState(Direction.Still);
  const dispatch = useAppDispatch();
  useEffect(() => {
    if (!hideLock) {
      const atTop = scrollPosition.top === 0;
      const directionChanged = scrollDir !== lastScrollDir
      const isUp = scrollDir === Direction.Up;
      const isDown = scrollDir === Direction.Down;

      if (!hide && autoHide && isDown && directionChanged) {
        setHide(true);
      } else if (hide && autoHide && !mediaQuery.xShort && (isUp || atTop)) {
        setHide(false);
      }
    }
    setLastScrollDir(scrollDir);
  }, [autoHide, scrollDir, lastScrollDir, hide, hideLock, scrollPosition]);

  const hideDebounce = useDebounceValue(hide, 1000);
  useEffect(() => {
    if (hideDebounce && showPinnedServers) {
      dispatch(setShowPinnedServers(false));
    }
    if (hideDebounce !== hideNavigationSetting) {
      dispatch(setHideNavigation(hideDebounce));
    }
  }, [hideDebounce]);


  return hide;
}