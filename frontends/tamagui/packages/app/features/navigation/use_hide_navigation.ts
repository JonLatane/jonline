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
  const dispatch = useAppDispatch();
  const { showPinnedServers, autoHideNavigation: autoHideSetting, hideNavigation } = useLocalConfiguration();
  const forceAutoHide = mediaQuery.xShort;
  const autoHide = forceAutoHide || autoHideSetting;
  const [hideLock, setHideLock] = useState(false);
  // const [hide, _setHide] = useState(false);
  // const hideNavigation = hideNavigation;
  useEffect(() => {
    if (hideNavigation && !forceAutoHide && !autoHideSetting) {
      dispatch(setHideNavigation(false));
    }
  }, [hideNavigation, mediaQuery.xShort]);
  function setHide(value: boolean) {
    setHideLock(true);
    dispatch(setHideNavigation(value));
    setTimeout(() => setHideLock(false), 1000);
  }
  const [lastScrollDir, setLastScrollDir] = useState(Direction.Still);
  useEffect(() => {
    if (!hideLock) {
      const atTop = scrollPosition.top === 0;
      const directionChanged = scrollDir !== lastScrollDir
      const isUp = scrollDir === Direction.Up;
      const isDown = scrollDir === Direction.Down;

      if (!hideNavigation && autoHide && isDown && directionChanged) {
        setHide(true);
      } else if (hideNavigation && autoHide && !mediaQuery.xShort && (isUp || atTop)) {
        setHide(false);
      }
    }
    setLastScrollDir(scrollDir);
  }, [autoHide, scrollDir, lastScrollDir, hideNavigation, hideLock, scrollPosition]);

  const hideDebounce = useDebounceValue(hideNavigation, 1000);
  useEffect(() => {
    if (hideDebounce && showPinnedServers) {
      dispatch(setShowPinnedServers(false));
    }
    if (hideDebounce !== hideNavigation) {
      dispatch(setHideNavigation(hideDebounce));
    }
  }, [hideDebounce]);


  return hideNavigation;
}