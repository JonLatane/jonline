import { Group, MediaReference, Permission, Post, Visibility } from '@jonline/api';
import { Button, Heading, Input, Paragraph, Sheet, TextArea, Tooltip, XStack, YStack, ZStack, standardAnimation, useDebounceValue, useMedia, useToastController } from '@jonline/ui';
import { CalendarPlus, ChevronLeft, Cog, Image as ImageIcon, Plus } from '@tamagui/lucide-icons';
import { AutoAnimatedList, ToggleRow, VisibilityPicker } from 'app/components';
import { useCreationAccountOrServer } from 'app/hooks';
import { FederatedGroup, JonlineServer, RootState, selectAllAccounts, serverID, useRootSelector, useServerTheme } from 'app/store';
import { highlightedButtonBackground, themedButtonBackground } from 'app/utils';
import { publicVisibility } from 'app/utils/visibility_utils';
import React, { useEffect, useState } from 'react';
import { TextInput } from 'react-native';
import { CreationServerSelector, useAvailableCreationServers } from '../accounts/creation_server_selector';
import { GroupsSheet, GroupsSheetButton } from '../groups/groups_sheet';
import { PostMediaManager } from './post_media_manager';
import { AccountOrServerContext, AccountOrServerContextProvider } from 'app/contexts';

export type BaseCreatePostSheetProps = {
  selectedGroup?: FederatedGroup;
  entityName?: string;
  doCreate: (
    post: Post,
    group: Group | undefined,
    resetPost: () => void,
    onComplete: () => void,
    onErrored: (error: any) => void,
  ) => void;
  preview: (
    post: Post,
    group: Group | undefined) => React.JSX.Element;
  feedPreview: (
    post: Post,
    group: Group | undefined) => React.JSX.Element;
  additionalFields?: (
    post: Post,
    group: Group | undefined) => React.JSX.Element;
  onFreshOpen?: () => void;
  invalid?: boolean;
  canPublishLocally?: boolean;
  canPublishGlobally?: boolean;
  button?: (onPress: () => void) => React.JSX.Element;
  requiredPermissions?: Permission[];
}

export const postVisibilityDescription = (
  v: Visibility,
  group: Group | undefined,
  server: JonlineServer | undefined,
  entity: string = 'Post'
) => {
  switch (v) {
    case Visibility.PRIVATE:
      return `Only you can see this ${entity}.`;
    case Visibility.LIMITED:
      return group
        ? `Only your followers and members of ${group.name} can see this ${entity}.`
        : `Only your followers and groups you choose can see this ${entity}.`;
    case Visibility.SERVER_PUBLIC:
      return `Anyone on ${server?.serverConfiguration?.serverInfo?.name ?? 'this server'} can see this ${entity}.`;
    case Visibility.GLOBAL_PUBLIC:
      return `Anyone on the internet can see this ${entity}.`;
    default:
      return 'Unknown';
  }
}

export enum RenderType { Edit, FullPreview, ShortPreview }
const edit = (r: RenderType) => r == RenderType.Edit;
const fullPreview = (r: RenderType) => r == RenderType.FullPreview;
const shortPreview = (r: RenderType) => r == RenderType.ShortPreview;

export function BaseCreatePostSheet({
  selectedGroup,
  entityName = 'Post',
  doCreate,
  preview,
  feedPreview,
  additionalFields,
  invalid,
  onFreshOpen,
  canPublishLocally,
  canPublishGlobally,
  button,
  requiredPermissions
}: BaseCreatePostSheetProps) {
  const mediaQuery = useMedia();
  const accountOrServer = useCreationAccountOrServer();
  // const currentServer = useCurrentServer();
  const server = accountOrServer?.server;
  const account = accountOrServer.account!;

  const [open, _setOpen] = useState(false);
  const openDebounced = useDebounceValue(open, 3000);
  const [position, setPosition] = useState(0);

  const [renderType, setRenderType] = useState(RenderType.Edit);
  const [showSettings, _setShowSettings] = useState(true);
  const [showMedia, _setShowMedia] = useState(false);
  // const [hasOpened, setHasOpened] = useState(true);
  function setOpen(v: boolean) {
    if (onFreshOpen && v && !open && title.length === 0) {
      onFreshOpen();
    }
    // if (v && !hasOpened) {
    // setHasOpened(true);
    //   _setOpen(true);
    // } else {
    _setOpen(v);
    // }
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
  const defaultVisibility = canPublishGlobally ? Visibility.GLOBAL_PUBLIC
    : canPublishLocally ? Visibility.SERVER_PUBLIC
      : Visibility.LIMITED;
  const [group, setGroup] = useState<FederatedGroup | undefined>(selectedGroup);
  const [visibility, _setVisibility] = useState(defaultVisibility);
  const [shareable, setShareable] = useState(!selectedGroup);
  const [title, setTitle] = useState('');
  const [link, setLink] = useState('');
  useEffect(() => {
    if (link && !link.startsWith('http')) {
      setLink(`https://${link}`);
    } else if (link === 'https://' || link === 'http://') {
      setLink('');
    }
  }, [link]);
  const [content, setContent] = useState('');
  const [embedLink, setEmbedLink] = useState(false);
  const [media, setMedia] = useState<MediaReference[]>([]);

  function resetPost() {
    setOpen(false);

    setGroup(selectedGroup);
    setVisibility(defaultVisibility);
    setShareable(!selectedGroup);
    setTitle('');
    setLink('');
    setContent('');
    setEmbedLink(false);
    setMedia([]);

    setRenderType(RenderType.Edit);
    window.scrollTo({ top: 0, behavior: 'smooth' });

    // dispatch(clearPostAlerts!());
    setPosting(false);
    // setShowSettings(true);
  }

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

  const previewPost = Post.create({
    title, link, content, shareable, embedLink, media, visibility,
    author: { userId: account?.user.id, username: account?.user.username }
  })
  const textAreaRef = React.createRef<TextInput>();

  const [posting, setPosting] = useState(false);
  const [postingError, setPostingError] = useState(undefined as string | undefined);
  const toast = useToastController();
  const serversState = useRootSelector((state: RootState) => state.servers);

  const serverTheme = useServerTheme(server);
  const { primaryColor, primaryTextColor, primaryAnchorColor, navColor, navTextColor, navAnchorColor, textColor } = serverTheme;
  const accountsState = useRootSelector((state: RootState) => state.accounts);
  const accounts = useRootSelector((state: RootState) => selectAllAccounts(state.accounts));
  // const primaryServer = onlyShowServer || serversState.server;
  // const accountsOnPrimaryServer = server ? accounts.filter(a => serverUrl(a.server) == serverUrl(server!)) : [];
  const accountsOnServer = server ? accounts.filter(a => serverID(a.server) == serverID(server!)) : [];

  const postsState = useRootSelector((state: RootState) => state.posts);
  const accountsLoading = accountsState.status == 'loading';
  const valid = title.length > 0 && !invalid;

  const supportsSplitView = mediaQuery.gtMd;
  const showEditor = edit(renderType) || supportsSplitView;
  const showFullPreview = fullPreview(renderType);
  const showShortPreview = shortPreview(renderType);
  const inSplitView = supportsSplitView && (showFullPreview || showShortPreview);

  const canCreate = !requiredPermissions || (
    account &&
    !requiredPermissions.some(p => !account.user.permissions.includes(p))
  );
  useEffect(() => {
    if (openDebounced) {
      // setHasOpened(true);
    } else {
      // setTimeout(() => 
      setShowSettings(true)
      // , 1000);
      // if (renderSheet) {
      // setTimeout(() => {
      //   if (!open && renderSheet) {
      //     setRenderSheet(false);
      //   }
      // },1500)
      // }
    }
  }, [openDebounced]);

  const canEmbedLink = ['instagram', 'facebook', 'linkedin', 'tiktok', 'youtube', 'twitter', 'pinterest']
    .map(x => link.includes(x)).reduce((a, b) => a || b, false);

  const isPosting = posting;
  const disableInputs = isPosting;
  const disablePreview = disableInputs || !valid;
  const disableCreate = disableInputs || !valid || !canCreate;

  const availableCreationServers = useAvailableCreationServers(requiredPermissions);
  const otherServerCount = availableCreationServers.filter(s => s.host != server?.host).length;
  const serverText = server?.serverConfiguration?.serverInfo?.name ?? server?.host ?? 'this server';
  const text = otherServerCount
    ? `Create a new ${entityName} on ${serverText} (or ${otherServerCount} other ${otherServerCount === 1 ? 'server' : 'servers'})`
    : `Create a new ${entityName} on ${serverText}`;

  // return <></>;

  const [groupsSheetOpen, setGroupsSheetOpen] = useState(false);
  const groupsSheetOpenDebounced = useDebounceValue(groupsSheetOpen, 3000);
  const onCreatePressed = () => doCreate(
    previewPost,
    group,
    resetPost,
    () => setPosting(false),
    (e) => {
      console.error('Error creating post/event', e);
      setPostingError(e?.toString());
    });
  return (
    <>
      {button?.(() => setOpen(!open)) ??
        // <Tooltip>
        //   <Tooltip.Trigger>
        <Button //{...themedButtonBackground(primaryColor)} 
          w='$3'
          p={0}
          disabled={server === undefined}
          transparent
          onPress={() => setOpen(!open)}>
          {entityName === 'Post'
            ? <Plus color={navAnchorColor} />
            : <CalendarPlus color={navAnchorColor} />}
          {/* <Heading size='$2' ta='center' color={primaryTextColor}>
            Create {entityName}
          </Heading> */}
        </Button>
        //   </Tooltip.Trigger>
        //   <Tooltip.Content>
        //     <Paragraph>
        //       {text}
        //     </Paragraph>
        //   </Tooltip.Content>
        // </Tooltip>
      }
      {true //true && (open || renderSheet)
        ? <Sheet
          modal
          open={open}
          onOpenChange={setOpen}
          // snapPoints={[80]}
          snapPoints={[95]} dismissOnSnapToBottom
          position={position}
          onPositionChange={setPosition}
        // zIndex={100000}
        // dismissOnSnapToBottom
        >
          <Sheet.Overlay zi={999} />
          <Sheet.Frame zi={999}>
            <YStack h='100%'>
              {open || openDebounced
                ? <>
                  <Sheet.Handle />
                  <XStack als='center' w='100%' pr='$5' pl='$2' mb='$2' maw={inSplitView ? 1200 : 800} ai='center'>
                    <Button
                      // alignSelf='center'
                      // my='auto'
                      size="$2"
                      mr='$2'
                      circular
                      icon={ChevronLeft}
                      // mb='$2'
                      onPress={() => {
                        setOpen(false)
                      }}
                    />
                    <Heading marginVertical='auto' f={1} size='$7'>New {entityName}</Heading>
                    {/* <Button {...themedButtonBackground(showSettings ? navColor : undefined)}
                  onPress={() => setShowSettings(!showSettings)} circular mr='$2'>
                  <Cog color={showSettings ? navTextColor : textColor} />
                </Button> */}
                    <Tooltip>
                      <Tooltip.Trigger>
                        <Button
                          {...themedButtonBackground(primaryColor, primaryTextColor, disableCreate ? 0.5 : 1)}
                          disabled={disableCreate}
                          // o={disableCreate ? 0.5 : 1}
                          onPress={onCreatePressed}>
                          <Heading size='$1' color={primaryTextColor}>Create</Heading>
                        </Button>
                      </Tooltip.Trigger>
                      {!canCreate
                        ? <Tooltip.Content>
                          <Paragraph>
                            You do not have permission to create this {entityName}.
                          </Paragraph>
                        </Tooltip.Content>
                        : undefined}
                    </Tooltip>
                  </XStack>
                  <CreationServerSelector requiredPermissions={requiredPermissions} showUser />
                  {/* {postsState.createPostStatus == "errored" && postsState.errorMessage ?
                <Heading size='$1' color='red' p='$2' ac='center' jc='center' ta='center'>{postsState.errorMessage}</Heading> : undefined} */}

                  <XStack ml='auto' mr={supportsSplitView ? '20%' : 'auto'} marginTop='$3'>
                    {supportsSplitView
                      ? undefined
                      : <Button
                        {...themedButtonBackground(showEditor ? navColor : undefined)}
                        transparent={!showEditor}
                        borderTopRightRadius={0}
                        borderBottomRightRadius={0}
                        onPress={() => setRenderType(RenderType.Edit)}>
                        <Heading size='$4' color={showEditor ? navTextColor : textColor}>Edit</Heading>
                      </Button>}
                    <Tooltip>
                      <Tooltip.Trigger>
                        <Button backgroundColor={showFullPreview ? navColor : undefined}
                          hoverStyle={{ backgroundColor: showFullPreview ? navColor : undefined }}
                          transparent={!showFullPreview}
                          // borderRadius={0}
                          borderTopLeftRadius={supportsSplitView ? undefined : 0}
                          borderBottomLeftRadius={supportsSplitView ? undefined : 0}
                          borderTopRightRadius={0}
                          borderBottomRightRadius={0}
                          disabled={disablePreview}
                          opacity={disablePreview ? 0.5 : 1}
                          // borderTopRightRadius={0} borderBottomRightRadius={0}
                          onPress={() => setRenderType(renderType === RenderType.FullPreview && inSplitView ? RenderType.Edit : RenderType.FullPreview)}>
                          <Heading size='$4' color={showFullPreview ? navTextColor : textColor}>Preview</Heading>
                        </Button>
                      </Tooltip.Trigger>
                      <Tooltip.Content>
                        <Paragraph>
                          {disablePreview
                            ? `Enter a title to preview your ${entityName}.`
                            : `Preview your ${entityName} as it will appear to others.`}
                        </Paragraph>
                      </Tooltip.Content>
                    </Tooltip>
                    <Tooltip>
                      <Tooltip.Trigger>
                        <Button backgroundColor={showShortPreview ? navColor : undefined}
                          hoverStyle={{ backgroundColor: showShortPreview ? navColor : undefined }}
                          transparent={!showShortPreview}
                          borderTopLeftRadius={0} borderBottomLeftRadius={0}
                          disabled={disablePreview}
                          opacity={disablePreview ? 0.5 : 1}
                          onPress={() => setRenderType(renderType === RenderType.ShortPreview && inSplitView ? RenderType.Edit : RenderType.ShortPreview)}>
                          <Heading size='$4' color={showShortPreview ? navTextColor : textColor}>Feed Preview</Heading>
                        </Button>
                      </Tooltip.Trigger>
                      <Tooltip.Content>
                        <Paragraph>
                          {disablePreview
                            ? `Enter a title to preview your ${entityName}.`
                            : `Preview your ${entityName} as it will appear to others in feeds (i.e., shortened).`}
                        </Paragraph>
                      </Tooltip.Content>
                    </Tooltip>
                  </XStack>

                  {/* <AnimatePresence> */}
                  {/* </AnimatePresence> */}
                  {/* <Sheet.ScrollView> */}
                  <XStack f={1} mb='$4' gap="$2" maw={inSplitView ? 1200 : 600} w='100%' als='center'>
                    {showEditor
                      ? <Sheet.ScrollView>
                        <AutoAnimatedList style={{ width: '100%', paddingLeft: 24, paddingRight: 24, marginTop: 12 }}>
                          {/* <YStack gap="$2" w='100%' px="$5" marginTop='$3'> */}
                          {/* <Heading size="$6">{server?.host}/</Heading> */}
                          <YStack gap='$2' key='title-etc' w='100%'>
                            <XStack gap='$2'>
                              <Input f={1} textContentType="name"
                                placeholder={`${entityName} Title (required)`}
                                placeholderTextColor={navAnchorColor}
                                disabled={disableInputs} opacity={disableInputs || title == '' ? 0.5 : 1}
                                borderColor={title == '' ? navAnchorColor : undefined}
                                // color={title == '' ? primaryAnchorColor : undefined}
                                onFocus={() => setShowSettings(false)}
                                // autoCapitalize='words'
                                value={title}
                                onChange={(data) => { setTitle(data.nativeEvent.text) }} />
                              <Button ml='$2'
                                {...highlightedButtonBackground(serverTheme, 'nav', showSettings)}
                                // {...themedButtonBackground(showSettings ? navColor : undefined)}
                                onPress={() => setShowSettings(!showSettings)} circular>
                                <Cog color={showSettings ? navTextColor : textColor} />
                              </Button>
                            </XStack>
                            {additionalFields?.(previewPost, group)}
                            <XStack gap='$2'>
                              <Input f={1} textContentType="URL" autoCorrect={false} placeholder="Link (optional)"
                                disabled={disableInputs} opacity={disableInputs || link == '' ? 0.5 : 1}
                                onFocus={() => setShowSettings(false)}
                                // autoCapitalize='words'
                                value={link}
                                onChange={(data) => { setLink(data.nativeEvent.text) }} />

                              <ZStack w='$4' ml='$2'>
                                <Paragraph zi={1000} pointerEvents='none' size='$1' mt='auto' ml='auto' px={5} o={media.length > 0 ? 0.93 : 0.5}
                                  borderRadius={5}
                                  backgroundColor={showMedia ? primaryColor : navColor}
                                  color={showMedia ? primaryTextColor : navTextColor}>
                                  {media.length}
                                </Paragraph>
                                <Button {...themedButtonBackground(showMedia ? navColor : undefined)}
                                  onPress={() => setShowMedia(!showMedia)} circular mr='$2'>
                                  <ImageIcon color={showMedia ? navTextColor : textColor} />
                                </Button>
                              </ZStack>
                            </XStack>
                          </YStack>
                          {showSettings
                            ? <YStack key='create-post-settings' ac='center' jc='center' ai='center' w='100%' p='$2'
                              mt='$2'
                              animation='standard' {...standardAnimation} backgroundColor={'$backgroundHover'} borderRadius='$5'
                            >
                              {visibility != Visibility.PRIVATE
                                ? <YStack w='100%' mb='$2' ai='center'>
                                  <GroupsSheetButton
                                    open={groupsSheetOpen}
                                    setOpen={setGroupsSheetOpen}
                                    groupNamePrefix='Share to '
                                    noGroupSelectedText={publicVisibility(visibility)
                                      ? 'Share Everywhere' : 'Share To A Group'}
                                    selectedGroup={group}
                                    onGroupSelected={(g) => group?.id == g.id ? setGroup(undefined) : setGroup(g)}
                                  />
                                </YStack>
                                : undefined}
                              <VisibilityPicker
                                label='Post Visibility'
                                visibility={visibility}
                                onChange={setVisibility}
                                canPublishGlobally={canPublishGlobally}
                                canPublishLocally={canPublishLocally}
                                visibilityDescription={v => postVisibilityDescription(v, group, server, entityName)} />
                              <ToggleRow
                                name={
                                  publicVisibility(visibility) || visibility == Visibility.LIMITED ?
                                    `Allow sharing to ${group ? 'other ' : ''}Groups`
                                    : 'Allow sharing to other users'
                                }
                                value={shareable}
                                setter={(v) => setShareable(v)}
                                disabled={disableInputs || visibility == Visibility.PRIVATE} />
                            </YStack>
                            : undefined}
                          {showMedia
                            ? <AccountOrServerContextProvider key='media' value={accountOrServer}>
                              {/* <XStack w='auto' maw='100%' mx='auto'> */}
                              <PostMediaManager key='post-media-manager'
                                {...{ link, media, setMedia, embedLink, setEmbedLink }} />
                              {/* </XStack> */}
                            </AccountOrServerContextProvider>
                            : undefined}


                          <TextArea key='content' w='100%' pt='$1' mt='$2' value={content} ref={textAreaRef}
                            onFocus={() => setShowSettings(false)}
                            disabled={posting} opacity={posting || content == '' ? 0.5 : 1}
                            onChangeText={t => setContent(t)}
                            // onFocus={() => { _replyTextFocused = true; /*window.scrollTo({ top: window.scrollY - _viewportHeight/2, behavior: 'smooth' });*/ }}
                            // onBlur={() => _replyTextFocused = false}
                            placeholder={`Text content (optional). Markdown is supported.`} />
                          {/* </YStack> */}
                        </AutoAnimatedList>
                      </Sheet.ScrollView>
                      : undefined}
                    {showFullPreview
                      ? <Sheet.ScrollView>
                        <YStack w='100%' my='auto' p='$5' marginTop='$3'>{preview(previewPost, group)}</YStack>
                      </Sheet.ScrollView>
                      : undefined}
                    {showShortPreview
                      ? <Sheet.ScrollView>
                        <YStack w='100%' my='auto' p='$5' marginTop='$3'>{feedPreview(previewPost, group)}</YStack>
                      </Sheet.ScrollView>
                      : undefined}
                  </XStack>
                </>
                : undefined}
            </YStack>
          </Sheet.Frame>
        </Sheet>
        : undefined}


      {groupsSheetOpen || groupsSheetOpenDebounced
        ? <GroupsSheet
          open={groupsSheetOpen}
          setOpen={setGroupsSheetOpen}
          groupNamePrefix='Share to '
          noGroupSelectedText={publicVisibility(visibility)
            ? 'Share Everywhere' : 'Share To A Group'}
          serverHostFilter={server?.host}
          selectedGroup={group}
          onGroupSelected={(g) => group?.id == g.id ? setGroup(undefined) : setGroup(g)}
        />
        : undefined}
    </>
  )
}
