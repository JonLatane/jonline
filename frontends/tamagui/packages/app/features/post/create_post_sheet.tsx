import { Post, Permission, Visibility, Media } from '@jonline/api';
import { Button, Heading, Input, isClient, isWeb, Paragraph, ScrollView, Sheet, TextArea, useMedia, XStack, YStack, ZStack } from '@jonline/ui';
import { ArrowLeft, ArrowRight, ChevronDown, Image as ImageIcon, Send as SendIcon, Settings, Unlock } from '@tamagui/lucide-icons';
import { clearPostAlerts, createPost, RootState, selectAllAccounts, selectAllServers, serverID, useCredentialDispatch, useServerTheme, useTypedSelector } from 'app/store';
import React, { useEffect, useState } from 'react';
import { Platform, View } from 'react-native';
import StickyBox from 'react-sticky-box';
import { AddAccountSheet } from '../accounts/add_account_sheet';
// import AccountCard from './account_card';
// import ServerCard from './server_card';
import PostCard from './post_card';
import { VisibilityPicker } from './visibility_picker';
import { ToggleRow } from '../settings_sheet';
import { MediaChooser } from '../media/media_chooser';
import { MediaRenderer } from '../media/media_renderer';

export type CreatePostSheetProps = {
  // primaryServer?: JonlineServer;
  // operation: string;
}

enum RenderType { Edit, FullPreview, ShortPreview }
const edit = (r: RenderType) => r == RenderType.Edit;
const fullPreview = (r: RenderType) => r == RenderType.FullPreview;
const shortPreview = (r: RenderType) => r == RenderType.ShortPreview;

// export enum LoginMethod {
//   Login = 'login',
//   CreateAccount = 'create_account',
// }
export function CreatePostSheet({ }: CreatePostSheetProps) {
  const mediaQuery = useMedia();
  const { dispatch, accountOrServer } = useCredentialDispatch();
  const account = accountOrServer.account!;
  const [open, setOpen] = useState(false);
  const [position, setPosition] = useState(0);

  const [renderType, setRenderType] = useState(RenderType.Edit);
  const [showSettings, _setShowSettings] = useState(false);
  const [showMedia, _setShowMedia] = useState(true);
  function setShowSettings(value: boolean) {
    _setShowSettings(value);
    if (value) {
      _setShowMedia(false);
    }
  }
  function setShowMedia(value: boolean) {
    _setShowMedia(value);
    if (value) {
      _setShowSettings(false);
    }
  }

  // Form fields
  const [visibility, setVisibility] = useState(Visibility.GLOBAL_PUBLIC);
  const [shareable, setShareable] = useState(true);
  const [title, setTitle] = useState('');
  const [link, setLink] = useState('');
  const [content, setContent] = useState('');
  const [embedLink, setEmbedLink] = useState(false);
  const [media, setMedia] = useState<string[]>([]);

  useEffect(() => {
    if (!open) {
      setTimeout(() => setShowMedia(true), 1000);
    }
  }, [open]);

  const previewPost = Post.create({
    title, link, content, shareable, embedLink, media, visibility,
    author: { userId: account?.user.id, username: account?.user.username }
  })
  const textAreaRef = React.useRef() as React.MutableRefObject<HTMLElement | View>;

  const [posting, setPosting] = useState(false);

  const app = useTypedSelector((state: RootState) => state.app);
  const serversState = useTypedSelector((state: RootState) => state.servers);
  const servers = useTypedSelector((state: RootState) => selectAllServers(state.servers));
  const browsingOn = Platform.OS == 'web' ? window.location.hostname : undefined

  const { server, primaryColor, primaryTextColor, navColor, navTextColor, textColor } = useServerTheme();
  const accountsState = useTypedSelector((state: RootState) => state.accounts);
  const accounts = useTypedSelector((state: RootState) => selectAllAccounts(state.accounts));
  // const primaryServer = onlyShowServer || serversState.server;
  // const accountsOnPrimaryServer = server ? accounts.filter(a => serverUrl(a.server) == serverUrl(server!)) : [];
  const accountsOnServer = server ? accounts.filter(a => serverID(a.server) == serverID(server!)) : [];

  const postsState = useTypedSelector((state: RootState) => state.posts);
  const accountsLoading = accountsState.status == 'loading';
  const valid = title.length > 0;

  const showEditor = edit(renderType);
  const showFullPreview = fullPreview(renderType);
  const showShortPreview = shortPreview(renderType);

  function doCreate() {
    const newPost: Post = Post.create({ title, link, content, shareable, embedLink, media, visibility });

    dispatch(createPost({ ...newPost, ...accountOrServer })).then((action) => {
      if (action.type == createPost.fulfilled.type) {
        setOpen(false);
        setTitle('');
        setContent('');
        setLink('');
        setRenderType(RenderType.Edit);
        window.scrollTo({ top: 0, behavior: 'smooth' });
        dispatch(clearPostAlerts!());
      }
    });
  }

  const canEmbedLink = ['instagram', 'facebook', 'linkedin', 'tiktok', 'youtube', 'twitter', 'pinterest']
    .map(x => link.includes(x)).reduce((a, b) => a || b, false);

  const disableInputs = ['posting', 'posted'].includes(postsState.createPostStatus!);
  const disablePreview = disableInputs || !valid;
  const disableCreate = disableInputs || !valid;
  return (
    <>
      <Button backgroundColor={primaryColor} color={primaryTextColor} f={1}
        disabled={serversState.server === undefined}
        onPress={() => setOpen((x) => !x)}>
        <Heading size='$2' color={primaryTextColor}>Create Post</Heading>
      </Button>
      <Sheet
        modal
        open={open}
        onOpenChange={setOpen}
        // snapPoints={[80]}
        snapPoints={[90]} dismissOnSnapToBottom
        position={position}
        onPositionChange={setPosition}
      // dismissOnSnapToBottom
      >
        <Sheet.Overlay backgroundColor='$colorTranslucent' />
        <Sheet.Frame>
          <Sheet.Handle />
          <Button
            alignSelf='center'
            size="$3"
            circular
            icon={ChevronDown}
            mb='$2'
            onPress={() => {
              setOpen(false)
            }}
          />
          <XStack als='center' w='100%' px='$5' mb='$2' maw={800}>
            <Heading marginVertical='auto' f={1} size='$7'>Create Post</Heading>
            <Button backgroundColor={showSettings ? navColor : undefined} onPress={() => setShowSettings(!showSettings)} circular mr='$2'>
              <Unlock color={showSettings ? navTextColor : textColor} />
            </Button>
            <Button backgroundColor={primaryColor} disabled={disableCreate} opacity={disableCreate ? 0.5 : 1} onPress={doCreate}>
              <Heading size='$1' color={primaryTextColor}>Create</Heading>
            </Button>
          </XStack>
          {postsState.createPostStatus == "errored" && postsState.errorMessage ?
            <Heading size='$1' color='red' p='$2' ac='center' jc='center' ta='center'>{postsState.errorMessage}</Heading> : undefined}
          {showSettings
            ? <YStack ac='center' jc='center' mx='auto' animation="bouncy"
              p='$3'
              opacity={1}
              scale={1}
              y={0}
              enterStyle={{ y: -50, opacity: 0, }}
              exitStyle={{ opacity: 0, }}>
              {/* <Heading marginVertical='auto' f={1} size='$2'>Visibility</Heading> */}
              <VisibilityPicker label='Post Visibility' visibility={visibility} onChange={setVisibility}
                visibilityDescription={(v) => {
                  switch (v) {
                    case Visibility.PRIVATE:
                      return 'Only you can see this post.';
                    case Visibility.LIMITED:
                      return 'Only your followers and groups you choose can see this post.';
                    case Visibility.SERVER_PUBLIC:
                      return 'Anyone on this server can see this post.';
                    case Visibility.GLOBAL_PUBLIC:
                      return 'Anyone on the internet can see this post.';
                    default:
                      return 'Unknown';
                  }
                }} />
              <ToggleRow name='Allow others to share this Post'
                value={shareable}
                setter={(v) => setShareable(v)}
                disabled={disableInputs} />
            </YStack> : undefined}
          <XStack marginHorizontal='auto' marginVertical='$3'>
            <Button backgroundColor={showEditor ? navColor : undefined}
              transparent={!showEditor}
              borderTopRightRadius={0} borderBottomRightRadius={0}
              onPress={() => setRenderType(RenderType.Edit)}>
              <Heading size='$4' color={showEditor ? navTextColor : textColor}>Edit</Heading>
            </Button>
            <Button backgroundColor={showFullPreview ? navColor : undefined}
              transparent={!showFullPreview}
              borderRadius={0}
              disabled={disablePreview}
              opacity={disablePreview ? 0.5 : 1}
              // borderTopRightRadius={0} borderBottomRightRadius={0}
              onPress={() => setRenderType(RenderType.FullPreview)}>
              <Heading size='$4' color={showFullPreview ? navTextColor : textColor}>Preview</Heading>
            </Button>
            <Button backgroundColor={showShortPreview ? navColor : undefined}
              transparent={!showShortPreview}
              borderTopLeftRadius={0} borderBottomLeftRadius={0}
              disabled={disablePreview}
              opacity={disablePreview ? 0.5 : 1}
              onPress={() => setRenderType(RenderType.ShortPreview)}>
              <Heading size='$4' color={showShortPreview ? navTextColor : textColor}>Feed Preview</Heading>
            </Button>
          </XStack>
          <Sheet.ScrollView>
            <XStack space="$2" maw={600} w='100%' als='center' paddingHorizontal="$5">
              {showEditor
                ? <YStack space="$2" w='100%'>
                  {/* <Heading size="$6">{server?.host}/</Heading> */}
                  <Input textContentType="name" placeholder="Post Title"
                    disabled={disableInputs} opacity={disableInputs ? 0.5 : 1}
                    onFocus={() => setShowSettings(false)}
                    autoCapitalize='words'
                    value={title}
                    onChange={(data) => { setTitle(data.nativeEvent.text) }} />
                  <XStack space='$2'>
                    <Input f={1} textContentType="URL" autoCorrect={false} placeholder="Optional Link"
                      disabled={disableInputs} opacity={disableInputs ? 0.5 : 1}
                      onFocus={() => setShowSettings(false)}
                      // autoCapitalize='words'
                      value={link}
                      onChange={(data) => { setLink(data.nativeEvent.text) }} />

                    <ZStack w='$4' ml='$2'>
                      <Paragraph zi={1000} pointerEvents='none' size='$1' mt='auto' ml='auto' px={5} o={media.length > 0 ? 0.93 : 0.5}
                        borderRadius={5}
                        backgroundColor={media.length > 0 ? primaryColor : navColor} color={media.length > 0 ? primaryTextColor : navTextColor}>
                        {media.length}
                      </Paragraph>
                      <Button backgroundColor={showMedia ? navColor : undefined}
                        onPress={() => setShowMedia(!showMedia)} circular mr='$2'>
                        <ImageIcon color={showMedia ? navTextColor : textColor} />
                      </Button>
                    </ZStack>
                  </XStack>

                  {showMedia
                    ? <YStack ac='center' jc='center' marginHorizontal='$5' animation="bouncy"
                      p='$3'
                      opacity={1}
                      scale={1}
                      y={0}
                    // enterStyle={{ y: -50, opacity: 0, }}
                    // exitStyle={{ opacity: 0, }}
                    >
                      {media.length > 0 ? <ScrollView horizontal w='100%'>
                        <XStack space='$2'>
                          {media.map((mediaId, index) =>
                            <ZStack w={mediaQuery.gtXs ? 350 : 148} h={mediaQuery.gtXs ? 280 : 195}>
                              {/* <ZStack> */}
                              <MediaRenderer key={mediaId} media={Media.create({ id: mediaId })} />
                              <XStack w='100%' my='auto' zi={1000}>
                                <Button ml='$2' circular o={index == 0 ? 0.3 : 0.9} icon={ArrowLeft} onPress={() => {
                                  const updatedMedia = new Array<string>(...media);
                                  const leftValue = updatedMedia[index - 1]!;
                                  updatedMedia[index - 1] = mediaId;
                                  updatedMedia[index] = leftValue;
                                  setMedia(updatedMedia);
                                }} />
                                <YStack f={1} />
                                <Button mr='$2' circular o={index < media.length - 1 ? 0.9 : 0.3} icon={ArrowRight} onPress={() => {
                                  const updatedMedia = new Array<string>(...media);
                                  const rightValue = updatedMedia[index + 1]!;
                                  updatedMedia[index + 1] = mediaId;
                                  updatedMedia[index] = rightValue;
                                  setMedia(updatedMedia);
                                }} />
                              </XStack>
                              {/* </ZStack> */}
                            </ZStack>
                          )}
                        </XStack>
                      </ScrollView> : undefined}
                      {/* <Heading marginVertical='auto' f={1} size='$2'>Visibility</Heading> */}
                      <MediaChooser selectedMedia={media} onMediaSelected={setMedia} multiselect />
                      <YStack h='$0' mt='$2' />
                      {canEmbedLink
                        ? <ToggleRow name='Embed Link'
                          value={embedLink && canEmbedLink}
                          setter={(v) => setEmbedLink(v)}
                          disabled={disableInputs || !canEmbedLink} />
                        : undefined}
                    </YStack> : undefined}

                  <TextArea f={1} h='$19' value={content} ref={textAreaRef}
                    onFocus={() => setShowSettings(false)}
                    disabled={posting} opacity={posting ? 0.5 : 1}
                    onChangeText={t => setContent(t)}
                    // onFocus={() => { _replyTextFocused = true; /*window.scrollTo({ top: window.scrollY - _viewportHeight/2, behavior: 'smooth' });*/ }}
                    // onBlur={() => _replyTextFocused = false}
                    placeholder={`Optional Content. Markdown is supported.`} />
                  {accountsState.errorMessage ? <Heading size="$2" color="red" alignSelf='center' ta='center'>{accountsState.errorMessage}</Heading> : undefined}
                  {accountsState.successMessage ? <Heading size="$2" color="green" alignSelf='center' ta='center'>{accountsState.successMessage}</Heading> : undefined}
                </YStack>
                : undefined}
              {showFullPreview
                ? <PostCard post={previewPost} />
                : undefined}
              {showShortPreview
                ? <PostCard post={previewPost} isPreview />
                : undefined}
            </XStack>
          </Sheet.ScrollView>
        </Sheet.Frame>
      </Sheet>
    </>
  )
}
