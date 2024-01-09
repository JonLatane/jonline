import { Media } from '@jonline/api';
import { useAccountOrServer, useCredentialDispatch } from 'app/hooks';
import { RootState, getMediaPage, loadMediaPage, useRootSelector } from 'app/store';
import { useEffect, useState } from 'react';

export function useMediaPage(userId: string | undefined, page: number, onLoaded?: () => void) {
  console.log('useMediaPage');
  const accountOrServer = useAccountOrServer();
  const mediaState = useRootSelector((state: RootState) => state.media);
  const [loadingMedia, setLoadingMedia] = useState(false);

  const media: Media[] | undefined = useRootSelector((state: RootState) => userId ? getMediaPage(state.media, userId, 0) : undefined);
  const reloadMedia = useReloadMedia(userId, page);
  useEffect(() => {
    if (!loadingMedia && (mediaState.loadStatus == 'unloaded' || media == undefined)) {
      if (!accountOrServer.server) return;

      console.log("Loading media...");
      setLoadingMedia(true);
      reloadMedia();
    } else if (mediaState.loadStatus == 'loaded' && loadingMedia) {
      setLoadingMedia(false);
      onLoaded?.();
    }
  }, [media]);


  return { media, loadingMedia, reloadMedia };
}



export function useReloadMedia(userId: string | undefined, page: number) {
  const { dispatch, accountOrServer } = useCredentialDispatch();

  function reloadMedia() {
    dispatch(loadMediaPage({ ...accountOrServer, userId, page }))
  }

  return reloadMedia;
}

