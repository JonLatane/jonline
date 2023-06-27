import { Media } from '@jonline/api';
import { Heading, Spinner, YStack, dismissScrollPreserver, needsScrollPreservers, useWindowDimensions } from '@jonline/ui';
import { RootState, getMediaPage, loadMediaPage, useAccountOrServer, useCredentialDispatch, useServerTheme, useTypedSelector } from 'app/store';
import React, { useEffect, useState } from 'react';
import StickyBox from "react-sticky-box";
// import { StickyCreateButton } from '../post/create_post_sheet';
import { useAccount } from 'app/store';
import { AppSection } from '../tabs/features_navigation';
import { TabsNavigation } from '../tabs/tabs_navigation';
import { MediaCard } from './media_card';
import { MediaUploader } from './media_uploader';


export function MediaScreen() {

  const mediaState = useTypedSelector((state: RootState) => state.media);
  const accountOrServer = useAccountOrServer();
  const {account} = accountOrServer;

  const [showScrollPreserver, setShowScrollPreserver] = useState(needsScrollPreservers());
  const { server, primaryColor, primaryTextColor, navColor, navTextColor } = useServerTheme();
  const dimensions = useWindowDimensions();
  const [uploading, setUploading] = useState(false);
  const [uploadProgress, setUploadProgress] = useState<number | undefined>(undefined);

  useEffect(() => {
    let title = 'My Media';
    title += ` | ${server?.serverConfiguration?.serverInfo?.name || 'Jonline'}`;
    document.title = title;
  });

  const { media, loadingMedia, reloadMedia } = useMediaPage(
    accountOrServer.account?.user?.id,
    0,
    () => dismissScrollPreserver(setShowScrollPreserver)
  );

  const showSpinnerForUploading = uploading && (uploadProgress == undefined || uploadProgress < 0.1 || uploadProgress > 0.9);
  return (
    <TabsNavigation appSection={AppSection.MEDIA}>
      {account && (mediaState.loadStatus == 'loading' || loadingMedia || showSpinnerForUploading) ? <StickyBox style={{ zIndex: 10, height: 0 }}>
        <YStack space="$1" opacity={0.92}>
          <Spinner size='large' color={navColor} scale={2}
            top={dimensions.height / 2 - 50}
          />
        </YStack>
      </StickyBox> : undefined}
      <YStack f={1} w='100%' jc="center" ai="center" p="$0" paddingHorizontal='$3' mt='$3' maw={800} space>
        {
          accountOrServer.account
            ? <MediaUploader {...{ uploading, setUploading, uploadProgress, setUploadProgress }} />
            : <YStack width='100%' maw={600} jc="center" ai="center">
              <Heading size='$5' mb='$3'>You must be logged in to view media.</Heading>
              <Heading size='$3' ta='center'>You can log in by clicking the button in the top right corner.</Heading>
            </YStack>
        }
        {media && media.length == 0
          ? mediaState.loadStatus != 'loading' && mediaState.loadStatus != 'unloaded'
            ? <YStack width='100%' maw={600} jc="center" ai="center">
              <Heading size='$5' mb='$3'>No media found.</Heading>
              <Heading size='$3' ta='center'>The media you're looking for may either not exist, not be visible to you, or be hidden by moderators.</Heading>
            </YStack>
            : undefined
          : <>
            {media?.map((item) => {
              return <YStack w='100%' mb='$3'><MediaCard media={item} /></YStack>;
            })}
            {showScrollPreserver ? <YStack h={100000} /> : undefined}
          </>}
      </YStack>
      {/* <StickyCreateButton /> */}
    </TabsNavigation >
  )
}


export function useMediaPage(userId: string | undefined, page: number, onLoaded?: () => void) {
  const { dispatch, accountOrServer } = useCredentialDispatch();
  const mediaState = useTypedSelector((state: RootState) => state.media);
  const [loadingMedia, setLoadingMedia] = useState(false);

  const media: Media[] | undefined = useTypedSelector((state: RootState) => userId ? getMediaPage(state.media, userId, 0) : undefined);

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

  function reloadMedia() {
    dispatch(loadMediaPage({ ...accountOrServer, userId, page }))
  }

  return { media, loadingMedia, reloadMedia };
}
