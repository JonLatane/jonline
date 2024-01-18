import { useMedia } from '@jonline/ui';
import useDetectScroll, { Axis, Direction } from '@smakss/react-scroll-direction';
import { useAppDispatch, useLocalConfiguration } from 'app/hooks';
import { setShowPinnedServers } from 'app/store';
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
  const { showPinnedServers } = useLocalConfiguration();
  const [hideLock, setHideLock] = useState(false);
  const [hide, _setHide] = useState(false);
  function setHide(value: boolean) {
    setHideLock(true);
    _setHide(value);
    setTimeout(() => setHideLock(false), 1000);
  }
  const [lastScrollDir, setLastScrollDir] = useState(Direction.Still);
  const dispatch = useAppDispatch();
  useEffect(() => {
    if (!hideLock) {
      const atTop = scrollPosition.top === 0;
      if (scrollDir !== lastScrollDir) {
        if (!hide && mediaQuery.xShort && scrollDir === Direction.Down) {
          setHide(true);
        } else if (hide && (!mediaQuery.xShort || scrollDir === Direction.Up || atTop)) {
          setHide(false);
        }
      } else if (hide && atTop) {
        setHide(false);
      }
    }
    setLastScrollDir(scrollDir);
  }, [mediaQuery.xShort, scrollDir, lastScrollDir, hide, hideLock, scrollPosition]);
  useEffect(() => {
    if (hide && showPinnedServers) {
      dispatch(setShowPinnedServers(false));
    }
  }, [hide, showPinnedServers]);
  return hide;
}