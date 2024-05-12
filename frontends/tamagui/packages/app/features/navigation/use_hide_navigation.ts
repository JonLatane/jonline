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
  const { alwaysShowHideButton,
    showPinnedServers,
    autoHideNavigation: autoHideSetting,
    hideNavigation: hide
  } = useLocalConfiguration();

  const [hideLock, setHideLock] = useState(false);
  function setHide(value: boolean) {
    setHideLock(true);
    dispatch(setHideNavigation(value));
    setTimeout(() => setHideLock(false), 1000);
  }

  const forceAutoHide = mediaQuery.xShort;
  const autoHide = forceAutoHide || autoHideSetting;

  useEffect(() => {
    if (hide && !autoHide && !alwaysShowHideButton) {
      setHide(false);
    }
  }, [hide, autoHide]);

  const [lastScrollDir, setLastScrollDir] = useState(Direction.Still);
  useEffect(() => {
    if (autoHide && !hideLock) {
      const atTop = scrollPosition.top === 0;
      const directionChanged = scrollDir !== lastScrollDir
      const isUp = scrollDir === Direction.Up;
      const isDown = scrollDir === Direction.Down;

      if (!hide && isDown && directionChanged) {
        setHide(true);
      } else if (hide && (isUp || atTop)) {
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
    if (hideDebounce !== hide) {
      dispatch(setHideNavigation(hideDebounce));
    }
  }, [hideDebounce]);


  return hide;
}