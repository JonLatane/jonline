import { Heading, YStack, dismissScrollPreserver, needsScrollPreservers, useWindowDimensions } from '@jonline/ui';
import { useAccountOrServer } from 'app/hooks';
import { useMediaPages } from 'app/hooks/pagination/media_pagination_hooks';
import { RootState, useRootSelector, useServerTheme } from 'app/store';
import { setDocumentTitle } from 'app/utils';
import React, { useEffect, useState } from 'react';
import { AppSection } from '../navigation/features_navigation';
import { TabsNavigation } from '../navigation/tabs_navigation';
import { MediaCard } from './media_card';
import { MediaUploader } from './media_uploader';


export function MediaScreen() {

  const mediaState = useRootSelector((state: RootState) => state.media);
  const accountOrServer = useAccountOrServer();
  const { account } = accountOrServer;

  const [showScrollPreserver, setShowScrollPreserver] = useState(needsScrollPreservers());
  const { server, primaryColor, primaryTextColor, navColor, navTextColor } = useServerTheme();
  const dimensions = useWindowDimensions();
  const [uploading, setUploading] = useState(false);
  const [uploadProgress, setUploadProgress] = useState<number | undefined>(undefined);

  useEffect(() => {
    let title = 'My Media';
    title += ` | ${server?.serverConfiguration?.serverInfo?.name || '...'}`;
    setDocumentTitle(title)
  });

  const { results: allMedia, loading: loadingMedia, reload: reloadMedia, hasMorePages, firstPageLoaded } =
    useMediaPages();

  useEffect(() => {
    if (firstPageLoaded) {
      dismissScrollPreserver(setShowScrollPreserver);
    }
  }, [firstPageLoaded]);
  console.log('allMedia', allMedia, 'loadingMedia', loadingMedia, 'reloadMedia', reloadMedia, 'hasMorePages', hasMorePages, 'firstPageLoaded', firstPageLoaded);

  const showSpinnerForUploading = uploading && (uploadProgress == undefined || uploadProgress < 0.1 || uploadProgress > 0.9);
  return (
    <TabsNavigation appSection={AppSection.MEDIA}
      loading={account && (loadingMedia || showSpinnerForUploading)}>
      <YStack f={1} w='100%' jc="center" ai="center" p="$0" paddingHorizontal='$3' mt='$3' maw={800} space>
        {
          accountOrServer.account
            ? <MediaUploader {...{ uploading, setUploading, uploadProgress, setUploadProgress }} />
            : <YStack width='100%' maw={600} jc="center" ai="center">
              <Heading size='$5' o={0.5} mb='$3'>You must be logged in to view media.</Heading>
              <Heading size='$3' o={0.5} ta='center'>You can log in by clicking the button in the top right corner.</Heading>
            </YStack>
        }
        {allMedia && allMedia.length == 0
          ? loadingMedia
            ? <YStack width='100%' maw={600} jc="center" ai="center">
              <Heading size='$5' o={0.5} mb='$3'>No media found.</Heading>
              <Heading size='$3' o={0.5} ta='center'>The media you're looking for may either not exist, not be visible to you, or be hidden by moderators.</Heading>
            </YStack>
            : undefined
          : <>
            {allMedia?.map((item) => {
              return <YStack w='100%' mb='$3'><MediaCard media={item} /></YStack>;
            })}
            {showScrollPreserver ? <YStack h={100000} /> : undefined}
          </>}
      </YStack>
    </TabsNavigation >
  )
}
