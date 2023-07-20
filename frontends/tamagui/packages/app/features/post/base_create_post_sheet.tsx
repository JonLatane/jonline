import { Group, Media, Post, Visibility } from '@jonline/api';
import { AnimatePresence, Button, Heading, Input, Paragraph, ScrollView, Sheet, TextArea, XStack, YStack, ZStack, standardAnimation, useMedia } from '@jonline/ui';
import { ArrowLeft, ArrowRight, ChevronDown, Image as ImageIcon, Unlock } from '@tamagui/lucide-icons';
import { RootState, clearPostAlerts, createGroupPost, createPost, selectAllAccounts, selectAllServers, serverID, useCredentialDispatch, useServerTheme, useTypedSelector } from 'app/store';
import { publicVisibility } from 'app/utils/visibility_utils';
import React, { useEffect, useState } from 'react';
import { Platform, TextInput, View } from 'react-native';
import { GroupsSheet } from '../groups/groups_sheet';
import { MediaChooser } from '../media/media_chooser';
import { MediaRenderer } from '../media/media_renderer';
import { ToggleRow } from '../settings_sheet';
import PostCard from './post_card';
import { VisibilityPicker } from './visibility_picker';

export type BaseCreatePostSheetProps = {
  selectedGroup?: Group;
  entityName?: string;
  doCreate: (
    post: Post,
    group: Group | undefined,
    resetPost: () => void,
    onComplete: () => void
  ) => void;
  preview: (
    post: Post,
    group: Group | undefined) => JSX.Element;
  feedPreview: (
    post: Post,
    group: Group | undefined) => JSX.Element;
  additionalFields?: (
    post: Post,
    group: Group | undefined) => JSX.Element;
  onFreshOpen?: () => void;
  invalid?: boolean;
}

enum RenderType { Edit, FullPreview, ShortPreview }
const edit = (r: RenderType) => r == RenderType.Edit;
const fullPreview = (r: RenderType) => r == RenderType.FullPreview;
const shortPreview = (r: RenderType) => r == RenderType.ShortPreview;

export function BaseCreatePostSheet({ selectedGroup, entityName = 'Post', doCreate, preview, feedPreview, additionalFields, invalid, onFreshOpen }: BaseCreatePostSheetProps) {
  const mediaQuery = useMedia();
  const { dispatch, accountOrServer } = useCredentialDispatch();
  const account = accountOrServer.account!;
  const [open, _setOpen] = useState(false);
  const [position, setPosition] = useState(0);

  const [renderType, setRenderType] = useState(RenderType.Edit);
  const [showSettings, _setShowSettings] = useState(true);
  const [showMedia, _setShowMedia] = useState(false);
  const [renderSheet, setRenderSheet] = useState(true);
  function setOpen(v: boolean) {
    if (onFreshOpen && v && !open && title.length == 0) {
      onFreshOpen();
    }
    if (v && !renderSheet) {
      setRenderSheet(true);
      setTimeout(() => _setOpen(true), 1);
    } else {
      _setOpen(v);
    }
  }

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
  const [group, setGroup] = useState<Group | undefined>(selectedGroup);
  const [visibility, _setVisibility] = useState(selectedGroup ? Visibility.LIMITED : Visibility.SERVER_PUBLIC);
  const [shareable, setShareable] = useState(!selectedGroup);
  const [title, setTitle] = useState('');
  const [link, setLink] = useState('');
  const [content, setContent] = useState('');
  const [embedLink, setEmbedLink] = useState(false);
  const [media, setMedia] = useState<string[]>([]);

  function setVisibility(v: Visibility) {
    const currentlyPublic = publicVisibility(visibility);
    const willBePublic = publicVisibility(v);
    const willBePrivate = v == Visibility.PRIVATE;
    if (shareable) {
      if (willBePrivate || (currentlyPublic && !willBePublic)) {
        setShareable(false);
      }
    } else if (!currentlyPublic && willBePublic) {
      setShareable(true);
    }
    _setVisibility(v);
  }
  function resetPost() {
    setOpen(false);
    setTitle('');
    setContent('');
    setLink('');
    setRenderType(RenderType.Edit);
    window.scrollTo({ top: 0, behavior: 'smooth' });
    dispatch(clearPostAlerts!());
    setPosting(false);
    // setShowSettings(true);
  }

  const previewPost = Post.create({
    title, link, content, shareable, embedLink, media, visibility,
    author: { userId: account?.user.id, username: account?.user.username }
  })
  const textAreaRef = React.createRef<TextInput>();

  const [posting, setPosting] = useState(false);
  const serversState = useTypedSelector((state: RootState) => state.servers);

  const { server, primaryColor, primaryTextColor, navColor, navTextColor, textColor } = useServerTheme();
  const accountsState = useTypedSelector((state: RootState) => state.accounts);
  const accounts = useTypedSelector((state: RootState) => selectAllAccounts(state.accounts));
  // const primaryServer = onlyShowServer || serversState.server;
  // const accountsOnPrimaryServer = server ? accounts.filter(a => serverUrl(a.server) == serverUrl(server!)) : [];
  const accountsOnServer = server ? accounts.filter(a => serverID(a.server) == serverID(server!)) : [];

  const postsState = useTypedSelector((state: RootState) => state.posts);
  const accountsLoading = accountsState.status == 'loading';
  const valid = title.length > 0 && !invalid;

  const showEditor = edit(renderType);
  const showFullPreview = fullPreview(renderType);
  const showShortPreview = shortPreview(renderType);

  useEffect(() => {
    if (open) {
      setRenderSheet(true);
    } else {
      setTimeout(() => setShowSettings(true), 1000);
      // if (renderSheet) {
      // setTimeout(() => {
      //   if (!open && renderSheet) {
      //     setRenderSheet(false);
      //   }
      // },1500)
      // }
    }
  }, [open]);

  const canEmbedLink = ['instagram', 'facebook', 'linkedin', 'tiktok', 'youtube', 'twitter', 'pinterest']
    .map(x => link.includes(x)).reduce((a, b) => a || b, false);

  const isPosting = posting || ['posting', 'posted'].includes(postsState.createPostStatus!);
  const disableInputs = isPosting;
  const disablePreview = disableInputs || !valid;
  const disableCreate = disableInputs || !valid;

  // return <></>;

  return (
    <>
      <Button backgroundColor={primaryColor} o={0.95} hoverStyle={{ backgroundColor: primaryColor, opacity: 1 }} color={primaryTextColor} f={1}
        disabled={serversState.server === undefined}
        onPress={() => setOpen(!open)}>
        <Heading size='$2' color={primaryTextColor}>Create {entityName}</Heading>
      </Button>
      {true && (open || renderSheet)
        ? <Sheet
          modal
          open={open}
          onOpenChange={setOpen}
          // snapPoints={[80]}
          snapPoints={[95]} dismissOnSnapToBottom
          position={position}
          onPositionChange={setPosition}
        // dismissOnSnapToBottom
        >
          <Sheet.Overlay />
          <Sheet.Frame>
            <YStack h='100%'>
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
                <Heading marginVertical='auto' f={1} size='$7'>Create {entityName}</Heading>
                <Button backgroundColor={showSettings ? navColor : undefined} onPress={() => setShowSettings(!showSettings)} circular mr='$2'>
                  <Unlock color={showSettings ? navTextColor : textColor} />
                </Button>
                <Button backgroundColor={primaryColor} disabled={disableCreate} opacity={disableCreate ? 0.5 : 1}
                  onPress={() => doCreate(previewPost, group, resetPost, () => setPosting(false))}>
                  <Heading size='$1' color={primaryTextColor}>Create</Heading>
                </Button>
              </XStack>
              {postsState.createPostStatus == "errored" && postsState.errorMessage ?
                <Heading size='$1' color='red' p='$2' ac='center' jc='center' ta='center'>{postsState.errorMessage}</Heading> : undefined}

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

              {/* <AnimatePresence> */}
              
              {/* </AnimatePresence> */}
              {/* <Sheet.ScrollView> */}
              <XStack f={1} mb='$4' space="$2" maw={600} w='100%' als='center' paddingHorizontal="$5">
                {showEditor
                  ? <YStack space="$2" w='100%'>
                    {/* <Heading size="$6">{server?.host}/</Heading> */}
                    <Input textContentType="name" placeholder={`${entityName} Title (required)`}
                      disabled={disableInputs} opacity={disableInputs || title == '' ? 0.5 : 1}
                      onFocus={() => setShowSettings(false)}
                      autoCapitalize='words'
                      value={title}
                      onChange={(data) => { setTitle(data.nativeEvent.text) }} />
                    {additionalFields?.(previewPost, group)}
                    <XStack space='$2'>
                      <Input f={1} textContentType="URL" autoCorrect={false} placeholder="Link (optional)"
                        disabled={disableInputs} opacity={disableInputs || link == '' ? 0.5 : 1}
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

                    {/* <AnimatePresence> */}
                    {showMedia
                      ? <YStack key='create-post-sheet-media' ac='center'
                        jc='center'
                        marginHorizontal='$5'
                        p='$3'
                        animation='quick'
                        {...standardAnimation}
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
                        <MediaChooser selectedMedia={media} onMediaSelected={setMedia} multiselect />
                        <YStack h='$0' mt='$2' />
                        {canEmbedLink
                          ? <ToggleRow name='Embed Link'
                            value={embedLink && canEmbedLink}
                            setter={(v) => setEmbedLink(v)}
                            disabled={disableInputs || !canEmbedLink} />
                          : undefined}
                      </YStack> : undefined}
                    {/* </AnimatePresence> */}

                    <TextArea f={1} pt='$2' value={content} ref={textAreaRef}
                      onFocus={() => setShowSettings(false)}
                      disabled={posting} opacity={posting || content == '' ? 0.5 : 1}
                      onChangeText={t => setContent(t)}
                      // onFocus={() => { _replyTextFocused = true; /*window.scrollTo({ top: window.scrollY - _viewportHeight/2, behavior: 'smooth' });*/ }}
                      // onBlur={() => _replyTextFocused = false}
                      placeholder={`Text content (optional). Markdown is supported.`} />
                    {accountsState.errorMessage ? <Heading size="$2" color="red" alignSelf='center' ta='center'>{accountsState.errorMessage}</Heading> : undefined}
                    {accountsState.successMessage ? <Heading size="$2" color="green" alignSelf='center' ta='center'>{accountsState.successMessage}</Heading> : undefined}
                  </YStack>
                  : undefined}
                {showFullPreview
                  ? <Sheet.ScrollView>
                    <YStack w='100%' my='auto'>{preview(previewPost, group)}</YStack>
                  </Sheet.ScrollView>
                  : undefined}
                {showShortPreview
                  ? <Sheet.ScrollView>
                    <YStack w='100%' my='auto'>{feedPreview(previewPost, group)}</YStack>
                  </Sheet.ScrollView>
                  : undefined}
              </XStack>
            </YStack>
            {/* </Sheet.ScrollView> */}
          </Sheet.Frame>
        </Sheet>
        : undefined}
    </>
  )
}
