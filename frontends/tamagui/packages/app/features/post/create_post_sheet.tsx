import { CreatePostRequest, Permission, Post, Visibility } from '@jonline/api';
import { Button, Heading, Input, isClient, isWeb, Sheet, TextArea, useMedia, XStack, YStack } from '@jonline/ui';
import { ChevronDown, Send as SendIcon, Settings } from '@tamagui/lucide-icons';
import { clearPostAlerts, createPost, RootState, selectAllAccounts, selectAllServers, serverUrl, useCredentialDispatch, useServerTheme, useTypedSelector } from 'app/store';
import React, { useEffect, useState } from 'react';
import { Platform, View } from 'react-native';
import StickyBox from 'react-sticky-box';
import { AddAccountSheet } from '../accounts/add_account_sheet';
// import AccountCard from './account_card';
// import ServerCard from './server_card';
import PostCard from './post_card';
import { VisibilityPicker } from './visibility_picker';


interface StickyCreateButtonProps {
  // replyingToPath: string[];
}

export const StickyCreateButton: React.FC<StickyCreateButtonProps> = ({ }: StickyCreateButtonProps) => {
  const { dispatch, accountOrServer } = useCredentialDispatch();
  const { server, primaryColor, primaryTextColor, navColor, navTextColor } = useServerTheme();
  const [replyText, setReplyText] = useState('');
  const [previewReply, setPreviewReply] = useState(false);
  // const maxPreviewHeight = useWindowDimensions().height * 0.5;
  // const [isReplying, setIsReplying] = useState(false);
  const [isSendingReply, setIsSendingReply] = useState(false);
  // const textAreaRef = React.useRef() as React.MutableRefObject<HTMLElement | View>;
  const chatUI = useTypedSelector((state: RootState) => state.app.discussionChatUI);
  function sendReply() {
    setIsSendingReply(true);
    // dispatch(replyToPost({
    //   ...accountOrServer,
    //   postIdPath: replyingToPath,
    //   content: replyText
    // }));
  }
  // const replyingToPost = 
  // let pathIndex = 0;
  // const rootPost = useTypedSelector((state: RootState) => selectPostById(state.posts, replyingToPath[pathIndex++]!));
  // const targetPostId = replyingToPath[replyingToPath.length - 1];
  // let targetPost = rootPost;
  // while (targetPost != null && targetPost?.id != targetPostId) {
  //   const replyId = replyingToPath[pathIndex++];
  //   // debugger;
  //   targetPost = targetPost?.replies?.find(reply => reply.id == replyId);
  //   // debugger;
  // }
  // const replyingToPost = targetPost;
  const sendReplyStatus = useTypedSelector((state: RootState) => state.posts.sendReplyStatus);
  useEffect(() => {
    if (isSendingReply && sendReplyStatus == 'sent') {
      setIsSendingReply(false);
      setReplyText('');
      // dispatch(confirmReplySent!());
      if (chatUI && isClient) {
        window.scrollTo({ top: document.body.scrollHeight, behavior: 'smooth' });
      }
    }
    if (!isSendingReply && previewReply && replyText == '') {
      setPreviewReply(false);
    }
  });
  const canPost = (accountOrServer.account?.user?.permissions?.includes(Permission.CREATE_POSTS)
    || accountOrServer.account?.user?.permissions?.includes(Permission.CREATE_POSTS));

  return isWeb ? <StickyBox bottom offsetBottom={0} className='blur' style={{ width: '100%' }}>
    {canPost
      ? <YStack w='100%' p='$2' opacity={.92} backgroundColor='$background' alignContent='center'>
        <CreatePostSheet />
      </YStack>
      : accountOrServer.account ? <YStack w='100%' opacity={.92} paddingVertical='$2' backgroundColor='$background' alignContent='center'>
        <Heading size='$1'>You do not have permission to create posts.</Heading>
      </YStack>
        : <YStack w='100%' opacity={.92} p='$3' backgroundColor='$background' alignContent='center'>
          {/* <Button backgroundColor={primaryColor} color={primaryTextColor}>
            Login or Create Account to Comment
          </Button> */}
          <AddAccountSheet operation='Post' />
        </YStack>}
  </StickyBox>
    : <Button mt='$3' circular icon={SendIcon} backgroundColor={primaryColor} onPress={() => { }} />

}

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
  const media = useMedia();
  const { dispatch, accountOrServer } = useCredentialDispatch();
  const account = accountOrServer.account!;
  const [open, setOpen] = useState(false);
  const [position, setPosition] = useState(0);

  const [renderType, setRenderType] = useState(RenderType.Edit);
  const [showSettings, setShowSettings] = useState(false);

  // Form fields
  const [visibility, setVisibility] = useState(Visibility.GLOBAL_PUBLIC);
  const [title, setTitle] = useState('');
  const [link, setLink] = useState('');
  const [content, setContent] = useState('');

  const previewPost = Post.create({ title, link, content, author: { userId: account?.user.id, username: account?.user.username } })
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
  const accountsOnServer = server ? accounts.filter(a => serverUrl(a.server) == serverUrl(server!)) : [];

  const postsState = useTypedSelector((state: RootState) => state.posts);
  const accountsLoading = accountsState.status == 'loading';
  const valid = title.length > 0;

  const showEditor = edit(renderType);
  const showFullPreview = fullPreview(renderType);
  const showShortPreview = shortPreview(renderType);

  function doCreate() {
    const createPostRequest: CreatePostRequest = { title, link, content };

    dispatch(createPost({ ...createPostRequest, ...accountOrServer })).then((action) => {
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
  const disableInputs = ['posting', 'posted'].includes(postsState.createPostStatus!);
  return (
    <>
      <Button backgroundColor={primaryColor} color={primaryTextColor}
        disabled={serversState.server === undefined}
        onPress={() => setOpen((x) => !x)}>
        <Heading size='$2'>Create A Post</Heading>
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
        <Sheet.Overlay />
        <Sheet.Frame>
          <Sheet.Handle />
          <Button
            alignSelf='center'
            size="$6"
            circular
            icon={ChevronDown}
            onPress={() => {
              setOpen(false)
            }}
          />
          <XStack marginHorizontal='$5' mb='$2'>
            <Heading marginVertical='auto' f={1} size='$7'>Create Post</Heading>
            <Button backgroundColor={showSettings ? navColor : undefined} onPress={() => setShowSettings(!showSettings)} circular mr='$2'>
              <Settings color={showSettings ? navTextColor : textColor} />
            </Button>
            <Button backgroundColor={primaryColor} disabled={disableInputs} opacity={disableInputs ? 0.5 : 1} onPress={doCreate}>
              <Heading size='$1' color={primaryTextColor}>Create</Heading>
            </Button>
          </XStack>
          {postsState.createPostStatus == "errored" && postsState.errorMessage ?
            <Heading size='$1' color='red' p='$2' ac='center' jc='center' ta='center'>{postsState.errorMessage}</Heading> : undefined}
          {showSettings
            ? <XStack ac='center' jc='center' marginHorizontal='$5' animation="bouncy"
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
            </XStack> : undefined}
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
              // borderTopRightRadius={0} borderBottomRightRadius={0}
              onPress={() => setRenderType(RenderType.FullPreview)}>
              <Heading size='$4' color={showFullPreview ? navTextColor : textColor}>Preview</Heading>
            </Button>
            <Button backgroundColor={showShortPreview ? navColor : undefined}
              transparent={!showShortPreview}
              borderTopLeftRadius={0} borderBottomLeftRadius={0}
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
                    autoCapitalize='words'
                    value={title}
                    onChange={(data) => { setTitle(data.nativeEvent.text) }} />
                  <Input textContentType="URL" autoCorrect={false} placeholder="Optional Link"
                    disabled={disableInputs} opacity={disableInputs ? 0.5 : 1}
                    // autoCapitalize='words'
                    value={link}
                    onChange={(data) => { setLink(data.nativeEvent.text) }} />

                  <TextArea f={1} h='$19' value={content} ref={textAreaRef}
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
