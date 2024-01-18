import { useMedia } from '@jonline/ui';
import useDetectScroll, { Axis, Direction } from '@smakss/react-scroll-direction';
import { useAppDispatch, useLocalConfiguration } from 'app/hooks';
import { setShowPinnedServers } from 'app/store';
import { useEffect } from 'react';

export function useHideNavigation() {
  const mediaQuery = useMedia();
  const { scrollDir, scrollPosition } = useDetectScroll({
    thr: 100,
    axis: Axis.Y,
    scrollUp: Direction.Up,
    scrollDown: Direction.Down,
    still: Direction.Still
  })
  const { showPinnedServers } = useLocalConfiguration();
  const doHide = mediaQuery.xShort && scrollDir === Direction.Down && scrollPosition.top > 100;
  const dispatch = useAppDispatch();
  useEffect(() => {
    if (doHide && showPinnedServers) {
      dispatch(setShowPinnedServers(false));
    }
  }, [doHide, showPinnedServers]);
  return doHide;
}