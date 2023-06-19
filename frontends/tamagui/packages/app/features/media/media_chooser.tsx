import { AlertDialog, Button, Heading, Paragraph, Progress, Sheet, Spinner, Text, XStack, YStack, dismissScrollPreserver, isTouchable, isWebTouchable, needsScrollPreservers, useMedia, useWindowDimensions } from '@jonline/ui';
import { RootState, deleteMedia, getCredentialClient, serverUrl, useCredentialDispatch, useServerTheme, useTypedSelector } from 'app/store';
import React, { useEffect, useState } from 'react';
// import { StickyCreateButton } from '../post/create_post_sheet';
import { overlayAnimation } from '@jonline/ui';
import { Image as ImageIcon, Trash, Upload, Wand2 } from '@tamagui/lucide-icons';
import { useAccount } from 'app/store';
import { FileUploader } from "react-drag-drop-files";
import { MediaRenderer } from './media_renderer';
import { useMediaPage } from './media_screen';


interface MediaChooserProps {
  children?: React.ReactNode;
  selectedMedia: string[];
  onMediaSelected?: (media: string[]) => void;
  multiselect?: boolean;
}

export const MediaChooser: React.FC<MediaChooserProps> = ({ children, selectedMedia, onMediaSelected, multiselect = false }) => {
  const mediaQuery = useMedia();
  const [open, _setOpen] = useState(false);
  const [position, setPosition] = useState(0);
  const serversState = useTypedSelector((state: RootState) => state.servers);
  const mediaState = useTypedSelector((state: RootState) => state.media);
  const app = useTypedSelector((state: RootState) => state.app);
  const { dispatch, accountOrServer } = useCredentialDispatch();
  const account = useAccount();

  // const media: Media[] | undefined = useTypedSelector((state: RootState) =>
  //   accountOrServer.account
  //     ? getMediaPage(state.media, accountOrServer.account?.user?.id, 0)
  //     : undefined);
  const [showScrollPreserver, setShowScrollPreserver] = useState(needsScrollPreservers());
  const { server, primaryColor, primaryTextColor, navColor, navTextColor } = useServerTheme();
  const dimensions = useWindowDimensions();
  const [dragging, setDragging] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [uploadProgress, setUploadProgress] = useState<number | undefined>(undefined);
  const [uploadedMediaId, setUploadedMediaId] = useState<string | undefined>(undefined);
  const [renderSheet, setRenderSheet] = useState(false);
  function setOpen(v: boolean) {
    if (v && !renderSheet) {
      setRenderSheet(true);
      setTimeout(() => _setOpen(true), 1);
    } else {
      _setOpen(v);
    }
  }

  const { media, loadingMedia, reloadMedia } = useMediaPage(
    accountOrServer.account?.user?.id,
    0,
    () => dismissScrollPreserver(setShowScrollPreserver)
  );

  function handleUpload(arg: File | Array<File>) {
    if (!server) return;

    const currentServer = server;
    console.log("Uploading file...");

    async function uploadFile(file: File) {
      // Updates the access token in case it needs updating.
      getCredentialClient(accountOrServer);

      const uploadUrl = `${serverUrl(currentServer)}/media`

      setUploading(true);
      const xhr = new XMLHttpRequest();
      xhr.upload.addEventListener("progress", (event) => {
        if (event.lengthComputable) {
          console.log("upload progress:", event.loaded / event.total);
          setUploadProgress(0.9 * (event.loaded / event.total));
        }
      });
      // xhr.addEventListener("progress", (event) => {
      //   if (event.lengthComputable) {
      //     console.log("download progress:", event.loaded / event.total);
      //     setUploadProgress(event.loaded / event.total;
      //   }
      // });
      xhr.addEventListener("loadend", () => {
        setUploading(false);
        setUploadProgress(1);
        setTimeout(() => setUploadProgress(undefined), 1000);
        reloadMedia();
      });
      xhr.onreadystatechange = () => {
        if (xhr.readyState === 4) {
          const newMediaId = xhr.responseText;
          setUploadedMediaId(newMediaId);
        }
      };
      xhr.open("POST", uploadUrl, true);
      xhr.setRequestHeader("Authorization", accountOrServer.account?.accessToken?.token || '');
      xhr.setRequestHeader("Filename", file.name);
      xhr.setRequestHeader("Content-Type", file.type);
      xhr.send(file);
    }

    if (arg instanceof File) {
      uploadFile(arg);
    } else {
      for (const file of arg) {
        uploadFile(file);
      }
    }
  }

  useEffect(() => {
    if (uploadedMediaId && (media ?? []).filter((m) => m.id == uploadedMediaId).length > 0) {
      selectMedia(uploadedMediaId);
      setUploadedMediaId(undefined);
    }
  }, [uploadedMediaId, media]);

  function selectMedia(itemId: string) {
    if (selectedMedia.includes(itemId)) {
      onMediaSelected?.(selectedMedia.filter((x) => x != itemId))
    } else {
      if (multiselect) {
        onMediaSelected?.([...selectedMedia, itemId])
      } else {
        onMediaSelected?.([itemId])
      }
    }
  }

  const showSpinnerForUploading = uploading && (uploadProgress == undefined || uploadProgress < 0.1 || uploadProgress > 0.9);
  return (
    <>
      <Button backgroundColor={navColor} color={navTextColor}
        onPress={() => setOpen(!open)}>
        {children ?? <XStack>
          <ImageIcon size={24} color={navTextColor} />
          <Paragraph ml='$2' color={navTextColor}>Choose Media</Paragraph>
        </XStack>}
      </Button>
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
        <Sheet.Overlay  />
        <Sheet.Frame>
          <Sheet.Handle />

          {account && (mediaState.loadStatus == 'loading' || mediaState.loadStatus == 'unloaded' || loadingMedia || showSpinnerForUploading) ?
            <YStack space="$1" opacity={0.92} zi={1000} position='absolute' als='center' pointerEvents='none'>
              <Spinner size='large' color={navColor} scale={2}
                top={dimensions.height / 2 - 50}
              />
            </YStack>
            : undefined}
          {/* <XStack space='$4' als='center' paddingHorizontal='$5' w='100%' maw={600}> */}

          {/* <Button size='$3' icon={RefreshCw} circular
              // disabled={isLoadingCredentialedData} opacity={isLoadingCredentialedData ? 0.5 : 1}
              onPress={resetCredentialedData} />
            <XStack f={1} /> */}
          {/* <Button
              alignSelf='center'
              size="$3"
              circular
              icon={ChevronDown}
              onPress={() => setOpen(false)} /> */}

          {/* <XStack f={1} />
            <SettingsSheet size='$3' /> */}

          {
            accountOrServer.account
              ? <YStack mb={-19} maw={600} p='$5' als='center' overflow='hidden'>
                <Text fontFamily='$body' fontSize='$3' mx='auto' mb='$3'>
                  <FileUploader handleChange={handleUpload} name="file"
                    label='Add Media'
                    width='250px'
                    onDraggingStateChange={setDragging}
                    types={["JPG", "JPEG", "PNG", "GIF", "PDF", "MOV", "AVI", "OGG", "MP3", "MP4", "MPG", "WEBM", "WEBP", "WMV"]}>
                    <Button onPress={() => { }} backgroundColor={dragging ? primaryColor : navColor}>
                      <XStack space='$2'>
                        <XStack my='auto'>
                          <Upload size={24} color={dragging ? primaryTextColor : navTextColor} />
                        </XStack>
                        <YStack jc="center" ai="center" f={1} my='auto' p='$3'>
                          <Heading size='$3' ta='center' color={dragging ? primaryTextColor : navTextColor}>
                            Upload Media
                          </Heading>
                          <Heading size='$1' ta='center' color={dragging ? primaryTextColor : navTextColor}>
                            {isTouchable || isWebTouchable ? 'Tap' : 'Drag/drop or click'} to choose
                          </Heading>
                        </YStack>
                      </XStack>
                    </Button>
                  </FileUploader>
                </Text>
                <Progress value={(uploadProgress ?? 0) * 100} >
                  <Progress.Indicator animation="quick" />
                </Progress>
              </YStack>
              : <YStack width='100%' maw={600} jc="center" ai="center">
                <Heading size='$5' mb='$3'>You must be logged in to view media.</Heading>
                <Heading size='$3' ta='center'>You can log in by clicking the button in the top right corner.</Heading>
              </YStack>
          }
          {/* </XStack> */}
          <Sheet.ScrollView p="$4" space>
            <YStack f={1} w='100%' jc="center" ai="center" p="$0" paddingHorizontal='$3' mt='$3' space>

              {media && media.length == 0
                ? mediaState.loadStatus != 'loading' && mediaState.loadStatus != 'unloaded'
                  ? <YStack width='100%' mx='auto' jc="center" ai="center">
                    <Heading size='$5' mb='$3'>No media found.</Heading>
                    <Heading size='$3' ta='center'>The media you're looking for may either not exist, not be visible to you, or be hidden by moderators.</Heading>
                  </YStack>
                  : undefined
                : <>
                  <XStack space='$0' flexWrap='wrap' als='center' mx='auto'>
                    {media?.map((item) => {
                      const _selectionIndex = selectedMedia.indexOf(item.id);
                      const selectionIndexBase1 = _selectionIndex == -1 ? undefined : _selectionIndex + 1;
                      const mediaName = item.name && item.name.length > 0 ? item.name : undefined;
                      const selected = selectedMedia.includes(item.id);
                      const onSelect = onMediaSelected ? () => selectMedia(item.id) : undefined;

                      return <YStack w={mediaQuery.gtXs ? '260px' : '105px'}
                        key={`media-chooser-item-${item.id}-${selected}`}
                        mih='160px'
                        mah={mediaQuery.gtXs ? '300px' : '260px'} mx='$1' my='$1'
                        borderColor={selected ? primaryColor : navColor} borderWidth={selected ? 2 : 1} borderRadius={5}
                        animation="bouncy" pressStyle={{ scale: 0.95 }}
                        backgroundColor={selected ? navColor : undefined} onPress={onSelect}>
                        {selectionIndexBase1
                          ? <Paragraph zi={1000} px={5} position='absolute' top='$2' right='$2'
                            borderRadius={5}
                            backgroundColor={media.length > 0 ? primaryColor : navColor} color={media.length > 0 ? primaryTextColor : navTextColor}>
                            {selectionIndexBase1}
                          </Paragraph>
                          : undefined}
                        <YStack f={1} pointerEvents='none' w='100%' jc='center' ac='center'>
                          <MediaRenderer media={item} />
                        </YStack>
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

                            <AlertDialog.Portal>
                              <AlertDialog.Overlay
                                key="overlay"
                                animation="quick"
                                {...overlayAnimation}
                              />
                              <AlertDialog.Content
                                bordered
                                elevate
                                key="content"
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
                                  <AlertDialog.Title>Confirmation</AlertDialog.Title>
                                  <AlertDialog.Description>
                                    Are you sure you want to delete {mediaName ?? 'this media'}? It will immediately be removed from your media, but it may continue to be available for the next 12 hours for some users.
                                  </AlertDialog.Description>

                                  <XStack space="$3" justifyContent="flex-end">
                                    <AlertDialog.Cancel asChild>
                                      <Button>Cancel</Button>
                                    </AlertDialog.Cancel>
                                    <AlertDialog.Action asChild>
                                      <Button backgroundColor={navColor} color={navTextColor} onPress={() => {
                                        console.log("calling deleteMedia!");
                                        onMediaSelected?.(selectedMedia.filter((id) => id != item.id));
                                        dispatch(deleteMedia({ id: item.id, ...accountOrServer }));
                                      }}>Delete</Button>
                                    </AlertDialog.Action>
                                  </XStack>
                                </YStack>
                              </AlertDialog.Content>
                            </AlertDialog.Portal>
                          </AlertDialog>
                        </XStack>
                      </YStack>;
                    })}
                  </XStack>
                </>}
            </YStack>
          </Sheet.ScrollView>
        </Sheet.Frame>
      </Sheet>
    </>
  )
}
