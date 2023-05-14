import { Post, PostListingType, Media } from '@jonline/api';
import { dismissScrollPreserver, Text, Heading, isClient, needsScrollPreservers, Spinner, useWindowDimensions, YStack } from '@jonline/ui';
import { getMediaPage, getPostsPage, loadPostsPage, loadMediaPage, RootState, useCredentialDispatch, useServerTheme, useTypedSelector, getCredentialClient, serverID, serverUrl } from 'app/store';
import React, { useEffect, useState } from 'react';
import { FlatList } from 'react-native';
import StickyBox from "react-sticky-box";
// import { StickyCreateButton } from '../post/create_post_sheet';
import PostCard from '../post/post_card';
import { AppSection, AppSubsection } from '../tabs/features_navigation';
import { TabsNavigation } from '../tabs/tabs_navigation';
import { MediaCard } from './media_card';
import { useAccountOrServer } from '../../store/store';
import { FileUploader } from "react-drag-drop-files";


export function MediaScreen() {
  const serversState = useTypedSelector((state: RootState) => state.servers);
  const mediaState = useTypedSelector((state: RootState) => state.media);
  const app = useTypedSelector((state: RootState) => state.app);
  const { dispatch, accountOrServer } = useCredentialDispatch();

  // const media: Media[] | undefined = useTypedSelector((state: RootState) =>
  //   accountOrServer.account
  //     ? getMediaPage(state.media, accountOrServer.account?.user?.id, 0)
  //     : undefined);
  const [showScrollPreserver, setShowScrollPreserver] = useState(needsScrollPreservers());
  const { server, primaryColor, navColor, navTextColor } = useServerTheme();
  const dimensions = useWindowDimensions();

  useEffect(() => {
    let title = 'Media';
    title += ` - ${server?.serverConfiguration?.serverInfo?.name || 'Jonline'}`;
    document.title = title;
  });

  const { media, loadingMedia, reloadMedia } = useMediaPage(
    accountOrServer.account?.user?.id,
    0,
    () => dismissScrollPreserver(setShowScrollPreserver)
  );

  function handleUpload(arg: File | Array<File>) {
    if(!server) return;

    const currentServer = server;
    console.log("Uploading file...");

    function uploadFile(file: File) {
      // Updates the access token in case it needs updating.
      getCredentialClient(accountOrServer);

      const uploadUrl = `${serverUrl(currentServer)}/media`
      fetch(uploadUrl,
      {
        method: 'POST',
        headers: {
          'Authorization': accountOrServer.account?.accessToken?.token || '',
          'Content-Type': file.type,
          'Filename': file.name
        }
      }
      ).then(reloadMedia)
    }
    
    if (arg instanceof File) {
      uploadFile(arg);
    } else {
      for (const file of arg) {
        uploadFile(file);
      }
    }
  }

  return (
    <TabsNavigation appSection={AppSection.MEDIA}>
      {mediaState.loadStatus == 'loading' ? <StickyBox style={{ zIndex: 10, height: 0 }}>
        <YStack space="$1" opacity={0.92}>
          <Spinner size='large' color={navColor} scale={2}
            top={dimensions.height / 2 - 50}
          />
        </YStack>
      </StickyBox> : undefined}
      <YStack f={1} w='100%' jc="center" ai="center" p="$0" paddingHorizontal='$3' mt='$3' maw={800} space>
        {
          accountOrServer.account
            ? <Text fontFamily='$body' fontSize='$3' mr='$4'>
              <FileUploader handleChange={handleUpload} name="file" 
              label='Click or drag/drop to add media.'
              width={550}
              maxSize={250} types={["JPG", "PNG", "GIF", "PDF", "MOV", "AVI"]} />
            </Text>
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
            {/* <FlatList data={media}
            // onRefresh={reloadMedia}
            // refreshing={mediaState.loadStatus == 'loading'}
            // Allow easy restoring of scroll position
            contentContainerStyle={{width:'100%'}}
            ListFooterComponent={showScrollPreserver ? <YStack h={100000} /> : undefined}
            keyExtractor={(user) => user.id}
            renderItem={({ item: user }) => {
              return <YStack w='100%' mb='$3'><MediaCard user={user} isPreview /></YStack>;
            }} /> */}
            {media?.map((item) => {
              return <YStack w='100%' mb='$3'><MediaCard media={item} /></YStack>;
            })}
            {showScrollPreserver ? <YStack h={100000} /> : undefined}
          </>}
      </YStack>
      {/* <StickyCreateButton /> */}
    </TabsNavigation>
  )
}


export function useMediaPage(userId: string | undefined, page: number, onLoaded?: () => void) {
  const { dispatch, accountOrServer } = useCredentialDispatch();
  const postsState = useTypedSelector((state: RootState) => state.posts);
  const [loadingMedia, setLoadingMedia] = useState(false);

  const media: Media[] | undefined = useTypedSelector((state: RootState) => userId ? getMediaPage(state.media, userId, 0) : undefined);

  useEffect(() => {
    if (postsState.baseStatus == 'unloaded' && !loadingMedia) {
      if (!accountOrServer.server) return;

      console.log("Loading posts...");
      setLoadingMedia(true);
      reloadMedia();
    } else if (postsState.baseStatus == 'loaded' && loadingMedia) {
      setLoadingMedia(false);
      onLoaded?.();
    }
  });

  function reloadMedia() {
    dispatch(loadMediaPage({ ...accountOrServer, userId, page }))
  }

  return { media, loadingMedia, reloadMedia };
}
