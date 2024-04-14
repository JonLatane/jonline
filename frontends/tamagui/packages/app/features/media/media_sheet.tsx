import { AlertDialog, Text, Button, Heading, Paragraph, Sheet, Spinner, Tooltip, XStack, YStack, needsScrollPreservers, useMedia, useTheme, useWindowDimensions } from '@jonline/ui';
import { useCreationDispatch, usePaginatedRendering } from 'app/hooks';
import { RootState, deleteMedia, getServerTheme, selectMediaById, useRootSelector } from 'app/store';
import React, { useEffect, useState } from 'react';

import { overlayAnimation } from '@jonline/ui';

import { Trash, Wand2, Info } from '@tamagui/lucide-icons';

import { Permission } from '@jonline/api/index';
import { AccountOrServerContextProvider, MediaRef, useMediaContext } from 'app/contexts';
import { useMediaPages } from 'app/hooks/pagination/media_pagination_hooks';
import { CreationServerSelector } from '../accounts/creation_server_selector';
import { MediaRenderer } from './media_renderer';
import { MediaUploader } from './media_uploader';
import FlipMove from 'react-flip-move';
import { PageChooser } from '../home/page_chooser';
import { highlightedButtonBackground } from 'app/utils';

interface MediaSheetProps { }

export const MediaSheet: React.FC<MediaSheetProps> = ({ }) => {
  const mediaQuery = useMedia();
  const { mediaSheetOpen: open, setMediaSheetOpen: setOpen, isSelecting, isMultiselect, selectedMedia, setSelectedMedia, setSelecting, setMultiselect } = useMediaContext();
  const [position, setPosition] = useState(0);
  const serversState = useRootSelector((state: RootState) => state.servers);
  const mediaState = useRootSelector((state: RootState) => state.media);
  const app = useRootSelector((state: RootState) => state.app);
  const { dispatch, accountOrServer } = useCreationDispatch(); //useProvidedDispatch();// useCredentialDispatch();
  const { server, account } = accountOrServer;

  const serverTheme = getServerTheme(server, useTheme());
  const { primaryColor, primaryTextColor, navColor, navTextColor } = serverTheme;//getServerTheme(accountOrServer.server, useTheme());
  const dimensions = useWindowDimensions();
  const [uploading, setUploading] = useState(false);
  const [uploadProgress, setUploadProgress] = useState<number | undefined>(undefined);
  const [uploadedMediaId, setUploadedMediaId] = useState<string | undefined>(undefined);

  const { results: allMedia, loading: loadingMedia, reload: reloadMedia, hasMorePages, firstPageLoaded } =
    useMediaPages();

  const [page, setPage] = useState(0);
  const pagination = usePaginatedRendering(allMedia, 10, { pageParamHook: () => [page, setPage] });

  useEffect(() => {
    pagination.setPage(0);
  }, [server?.host, account?.user?.id])

  const uploadedMedia = useRootSelector(
    (state: RootState) => uploadedMediaId
      ? selectMediaById(state.media, uploadedMediaId) ?? { id: uploadedMediaId } as MediaRef
      : undefined
  );

  const [showInfo, setShowInfo] = useState(false);

  useEffect(() => {
    if (uploadedMediaId
      && (allMedia ?? []).filter((m) => m.id == uploadedMediaId).length > 0
      && uploadedMedia) {
      selectMedia(uploadedMedia);
      setUploadedMediaId(undefined);
    }
  }, [uploadedMediaId, allMedia, uploadedMedia]);

  async function selectMedia(item: MediaRef) {
    if (!isSelecting) {
      console.warn("No onMediaSelect or onMediaMultiSelect function provided to MediaSheet!");
      return;
    }

    if (selectedMedia.some(m => m.id === item.id)) {
      setSelectedMedia(selectedMedia.filter((m) => m.id != item.id));
    } else {
      if (isMultiselect) {
        setSelectedMedia([...selectedMedia, item]);
      } else {
        setSelectedMedia([item]);
      }
    }
  }

  const showSpinnerForUploading = uploading && (uploadProgress == undefined || uploadProgress < 0.1 || uploadProgress > 0.9);
  return (
    <AccountOrServerContextProvider value={accountOrServer}>
      <Sheet
        modal
        open={open}
        onOpenChange={setOpen}
        // snapPoints={[80]}
        snapPoints={[87, 57, 37]}
        position={position}
        onPositionChange={setPosition}
        dismissOnSnapToBottom
      >
        <Sheet.Overlay />
        <Sheet.Frame>
          <Sheet.Handle />

          {isSelecting
            ? undefined
            : <CreationServerSelector requiredPermissions={[Permission.CREATE_MEDIA]}
              showUser
            />
          }

          {account && (loadingMedia || showSpinnerForUploading) ?
            <YStack gap="$1" opacity={0.92} zi={1000} position='absolute' als='center' pointerEvents='none'>
              <Spinner size='large' color={navColor} scale={2}
                top={dimensions.height / 2 - 50}
              />
            </YStack>
            : undefined}

          <XStack w='100%' ai='center' px='$3'>
            <Button transparent circular icon={Info} disabled
              // onPress={() => setShowInfo(!showInfo)}
              {...highlightedButtonBackground(serverTheme, 'nav', showInfo)}
              o={0}
            />
            <XStack f={1} />
            <XStack f={1}>
              {
                accountOrServer.account
                  ? <MediaUploader {...{ uploading, setUploading, uploadProgress, setUploadProgress }}
                    onMediaUploaded={setUploadedMediaId} />
                  : <YStack width='100%' maw={600} jc="center" ai="center">
                    <Heading size='$5' o={0.5} mb='$3'>You must be logged in to view media.</Heading>
                    <Heading size='$3' o={0.5} ta='center'>You can log in by clicking the button in the top right corner.</Heading>
                  </YStack>
              }
            </XStack>
            {/* <XStack f={1} /> */}
            <Button transparent circular icon={Info}
              onPress={() => setShowInfo(!showInfo)}
              {...highlightedButtonBackground(serverTheme, 'nav', showInfo)}
            />
          </XStack>
          {/* </XStack> */}
          <Sheet.ScrollView p="$4" space>
            <YStack f={1} w='100%' jc="center" ai="center" p="$0" paddingHorizontal='$3' mt='$3' space>

              {allMedia && allMedia.length == 0
                ? loadingMedia//mediaState.loadStatus != 'loading' && mediaState.loadStatus != 'unloaded'
                  ? <YStack width='100%' mx='auto' jc="center" ai="center">
                    <Heading size='$5' o={0.5} mb='$3'>No media found.</Heading>
                    {/* <Heading size='$3' o={0.5} ta='center'>The media you're looking for may either not exist, not be visible to you, or be hidden by moderators.</Heading> */}
                  </YStack>
                  : undefined
                : <>
                  <FlipMove style={{ width: '100%', display: 'flex', flexWrap: 'wrap', justifyContent: 'center' }}>
                    {/* <XStack gap='$0' flexWrap='wrap' als='center' jc='center' mx='auto'> */}

                    <div id={'media-pagination-top'} key='pagination-top' style={{ width: '100%', justifyContent: 'center', display: 'flex', marginBottom: 5 }}>
                      <PageChooser {...pagination} width='auto' maxWidth='100%' />
                    </div>
                    {pagination.results.map((item) => {
                      const selectionIndex = selectedMedia.findIndex(selectedItem => selectedItem.id === item.id);
                      const selectionIndexBase1 = selectionIndex == -1 ? undefined : selectionIndex + 1;
                      const mediaName = item.name && item.name.length > 0 ? item.name : undefined;
                      const selected = selectedMedia.some(selectedItem => selectedItem.id === item.id);
                      const onSelect = isSelecting ? () => selectMedia(item) : undefined;

                      return <div key={`media-${server?.host}-${item.id}`} style={{ margin: 'auto', display: 'inline-block' }}>
                        <YStack w={mediaQuery.gtXs ? '260px' : '105px'}
                          key={`media-chooser-item-${item.id}-${selected}`}
                          mih='160px'
                          mah={mediaQuery.gtXs ? '300px' : '260px'} mx='$1' my='$1'
                          borderColor={selected ? primaryColor : navColor} borderWidth={selected ? 2 : 1} borderRadius={5}
                          animation='standard' pressStyle={{ scale: 0.95 }}
                          backgroundColor={selected ? navColor : undefined} onPress={onSelect}>
                          {selectionIndexBase1
                            ? <Paragraph zi={1000} px={5} position='absolute' top='$2' right='$2'
                              borderRadius={5}
                              backgroundColor={allMedia.length > 0 ? primaryColor : navColor} color={allMedia.length > 0 ? primaryTextColor : navTextColor}>
                              {selectionIndexBase1}
                            </Paragraph>
                            : undefined}
                          {showInfo
                            ? <XStack maw='100%' ai='center'
                              gap='$2'
                              px='$1' mx='$1' pb='$1' >
                              <Tooltip >
                                <Tooltip.Trigger maw='100%' f={1}>
                                  <Paragraph fontWeight='bold' size='$1' maw='100%' whiteSpace='nowrap' overflow='hidden' textOverflow='ellipsis'>
                                    {item.name}
                                  </Paragraph>
                                </Tooltip.Trigger>
                                <Tooltip.Content>
                                  <Paragraph>
                                    {item.name}
                                  </Paragraph>
                                </Tooltip.Content>
                              </Tooltip>
                              {mediaQuery.gtXs
                                ? <Paragraph ml='auto' size='$1' fontFamily='$mono'>
                                  {item.contentType}
                                </Paragraph>
                                : undefined}

                            </XStack>
                            : undefined}
                          <YStack f={1} overflow='hidden' pointerEvents='none' w='100%' jc='center' ac='center'>
                            <MediaRenderer media={item} />
                          </YStack>
                          {showInfo && !mediaQuery.gtXs
                            ? <XStack mt='$1' mx='$1' px='$1'>
                              <Paragraph ml='auto' size='$1' fontFamily='$mono'>
                                {item.contentType}
                              </Paragraph>
                            </XStack>
                            : undefined}
                          {/* <MediaCard media={item}
                          selected={selectedMedia.includes(item.id)}
                          onSelect={onMediaSelected ? () => selectMedia(item.id) : undefined}
                          chooser /> */}
                          <XStack>
                            {item.generated ?
                              <YStack my='auto' ml='$2'><Wand2 size='$1' opacity={0.8} color={selected ? navTextColor : undefined} /></YStack>
                              // <Paragraph size='$1' my='auto' ml='$2' color={selected?navTextColor:'$textColor'} ta='center'>Generated</Paragraph> 
                              : undefined}
                            <AlertDialog native>
                              <AlertDialog.Trigger asChild my='$2' mr='$2'>
                                <Button size='$2' onPress={(e) => e.stopPropagation()} circular icon={Trash} ml='auto' />
                              </AlertDialog.Trigger>

                              <AlertDialog.Portal zIndex={1000000}>
                                <AlertDialog.Overlay
                                  key="overlay"
                                  animation="quick"
                                  {...overlayAnimation}
                                />
                                <AlertDialog.Content
                                  bordered
                                  elevate
                                  key="content"
                                  maw={window.innerWidth - 20}
                                  animation={[
                                    'quick',
                                    {
                                      opacity: {
                                        overshootClamping: true,
                                      },
                                    },
                                  ]}
                                  // enterStyle={{ x: 0, y: -20, opacity: 0, scale: 0.9 }}
                                  // exitStyle={{ x: 0, y: 10, opacity: 0, scale: 0.95 }}
                                  x={0}
                                  scale={1}
                                  opacity={1}
                                  y={0}
                                >
                                  <YStack space>
                                    <AlertDialog.Title>Really Delete?</AlertDialog.Title>
                                    <AlertDialog.Description>
                                      Are you sure you want to delete <Text fontFamily='$mono'>{mediaName ?? 'this media'}</Text>? It will immediately be removed from your media, but it may continue to be available for the next 12 hours for some users.
                                    </AlertDialog.Description>

                                    <XStack gap="$3" justifyContent="flex-end">
                                      <AlertDialog.Cancel asChild>
                                        <Button>Cancel</Button>
                                      </AlertDialog.Cancel>
                                      <AlertDialog.Action asChild>
                                        <Button backgroundColor={navColor} color={navTextColor} onPress={() => {
                                          setSelectedMedia(selectedMedia.filter((selectedItem) => selectedItem.id != item.id));
                                          dispatch(deleteMedia({ id: item.id, ...accountOrServer }));
                                        }}>Delete</Button>
                                      </AlertDialog.Action>
                                    </XStack>
                                  </YStack>
                                </AlertDialog.Content>
                              </AlertDialog.Portal>
                            </AlertDialog>
                          </XStack>
                        </YStack>
                      </div>;

                    })}
                    <div key='pagination-bottom' style={{ width: '100%', justifyContent: 'center', display: 'flex', marginBottom: 5 }}>
                      <PageChooser {...pagination} width='auto' maxWidth='100%' pageTopId={'media-pagination-top'} />
                    </div>
                    {/* </XStack> */}
                  </FlipMove>
                </>}
            </YStack>
          </Sheet.ScrollView>
        </Sheet.Frame>
      </Sheet>
    </AccountOrServerContextProvider>
  )
}
