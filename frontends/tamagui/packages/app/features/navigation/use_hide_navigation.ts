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
  const [hide, setHide] = useState(false);
  const [hideLock, setHideLock] = useState(false);
  // const doHide = mediaQuery.xShort && scrollDir === Direction.Down;
  const dispatch = useAppDispatch();
  useEffect(() => {
    if (!hideLock) {
      if (!hide && mediaQuery.xShort && scrollDir === Direction.Down) {
        setHideLock(true);
        setHide(true);
        setTimeout(() => setHideLock(false), 1000);
      } else if (hide && mediaQuery.xShort && scrollDir === Direction.Up) {
        setHideLock(true);
        setHide(false);
        setTimeout(() => setHideLock(false), 1000);
      }
    }
  }, [mediaQuery.xShort, scrollDir, hide, hideLock]);
  useEffect(() => {
    if (hide && showPinnedServers) {
      dispatch(setShowPinnedServers(false));
    }
  }, [hide, showPinnedServers]);
  return hide;
}