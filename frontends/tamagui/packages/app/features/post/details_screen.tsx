import { GetPostsRequest, Heading, Paragraph, Permission, XStack, YStack, } from '@jonline/ui'
import { Button, isWeb, isClient, Post, ScrollView, TextArea, useWindowDimensions, Tooltip, ZStack } from '@jonline/ui/src'
import { clearPostAlerts, loadPost, loadPostReplies, RootState, selectGroupById, selectPostById, loadPostsPage, useCredentialDispatch, useTypedSelector, useServerInfo, useLocalApp, setDiscussionChatUI, useTypedDispatch, confirmReplySent, replyToPost } from 'app/store'
import React, { useState, useEffect, useReducer } from 'react'
import { FlatList, View } from 'react-native'
import { createParam } from 'solito'
import { TabsNavigation } from '../tabs/tabs_navigation'
import PostCard, { TamaguiMarkdown } from './post_card'
import StickyBox from 'react-sticky-box'
import { Edit, Eye, ListEnd, ListStart, Send as SendIcon } from '@tamagui/lucide-icons'
import moment, { Moment } from 'moment'
import { dismissScrollPreserver, needsScrollPreservers } from '@jonline/ui/src/global'
import { AddAccountSheet } from '../accounts/add_account_sheet'

const { useParam } = createParam<{ postId: string, shortname: string | undefined }>()

let _nextChatReplyRefresh: Moment | undefined = undefined;
let _replyTextFocused = false;
let _viewportHeight = 0;
if (isClient) {
  visualViewport?.addEventListener('resize', (event) => {
    if (!event.target) return;

    const viewport: VisualViewport = event.target as VisualViewport;
    _viewportHeight = viewport.height ?? 0;
  });
}

export function PostDetailsScreen() {
  const [postId] = useParam('postId');
  const [shortname] = useParam('shortname');

  const { server, primaryColor, primaryTextColor, navColor, navTextColor } = useServerInfo();
  const app = useLocalApp();
  const groupId = useTypedSelector((state: RootState) =>
    shortname ? state.groups.shortnameIds[shortname!] : undefined);
  const group = useTypedSelector((state: RootState) =>
    groupId ? selectGroupById(state.groups, groupId) : undefined);
  const { dispatch, accountOrServer } = useCredentialDispatch();
  const postsState = useTypedSelector((state: RootState) => state.posts);
  const subjectPost = useTypedSelector((state: RootState) => selectPostById(state.posts, postId!));
  const [loadingPost, setLoadingPost] = useState(false);
  const [loadedReplies, setLoadedReplies] = useState(false);
  const [collapsedReplies, setCollapsedReplies] = useState(new Set<string>());

  const [showScrollPreserver, setShowScrollPreserver] = useState(needsScrollPreservers());
  const chatUI = app?.discussionChatUI;
  // const [chatUI, setChatUI] = useState(false);
  const showReplyArea = subjectPost != undefined;
  const [_, forceUpdate] = useReducer((x) => x + 1, 0);
  const { width, height: windowHeight } = useWindowDimensions();
  function scrollToBottom() {
    if (!isClient) return;
    if (_replyTextFocused && windowHeight > 0) {
      window.scrollTo({ top: document.body.scrollHeight - _viewportHeight, behavior: 'smooth' });
    } else {
      window.scrollTo({ top: document.body.scrollHeight, behavior: 'smooth' });
    }
  }
  function scrollToTop() {
    if (!isClient) return;

    window.scrollTo({ top: 0, behavior: 'smooth' });
  }

  if (chatUI && (app?.autoRefreshDiscussions ?? true)) {
    if (!_nextChatReplyRefresh || moment().isAfter(_nextChatReplyRefresh)) {
      const intervalSeconds = app?.discussionRefreshIntervalSeconds || 6;
      const wasAtBottom = isClient && !showScrollPreserver &&
        document.body.scrollHeight - _viewportHeight - window.scrollY < 100;
      const scrollYAtBottom = window.scrollY;
      // console.log('wasAtBottom', wasAtBottom, document.body.scrollHeight, _viewportHeight, window.scrollY)
      setTimeout(() => {
        dispatch(loadPostReplies({ ...accountOrServer, postIdPath: [postId!] }));
      }, 1);
      if (wasAtBottom) {
        setTimeout(() => {
          if (chatUI && (Math.abs(scrollYAtBottom - window.scrollY) < 10)) {
            scrollToBottom();
          }
        }, 1000);
      }
      _nextChatReplyRefresh = moment().add(intervalSeconds, 'second');
      setTimeout(() => {
        forceUpdate();
      }, intervalSeconds * 1000);
    }
  }

  useEffect(() => {
    if (postId) {
      if ((!subjectPost || postsState.status == 'unloaded') && postsState.status != 'loading' && !loadingPost) {
        setLoadingPost(true);
        // useEffect(() => {
        console.log('loadPost', postId!)
        setTimeout(() =>
          dispatch(loadPost({ ...accountOrServer, id: postId! })));
        // });
      } else if (subjectPost && loadingPost) {
        setLoadingPost(false);
      }
      if (subjectPost && postsState.status != 'loading' && subjectPost.replyCount > 0 &&
        subjectPost.replies.length == 0 && !loadedReplies) {
        setLoadedReplies(true);
        console.log('loadReplies', subjectPost.id, subjectPost.replyCount, subjectPost.replies.length, loadedReplies);
        setTimeout(() =>
          dispatch(loadPostReplies({ ...accountOrServer, postIdPath: [postId!] })), 1);
      } else if (!subjectPost && loadedReplies) {
        setLoadedReplies(false);
      }
      if (subjectPost && (subjectPost.replyCount == 0 || subjectPost.replies.length > 0) && showScrollPreserver) {
        dismissScrollPreserver(setShowScrollPreserver);
      }
    }
  });

  function toggleCollapseReplies(postId: string) {
    if (collapsedReplies.has(postId)) {
      collapsedReplies.delete(postId);
    } else {
      collapsedReplies.add(postId);
    }
    setCollapsedReplies(new Set(collapsedReplies));
  }

  type FlattenedReply = {
    postIdPath: string[];
    reply: Post;
    parentPost?: Post;
    lastReplyTo?: string;
  }

  const flattenedReplies: FlattenedReply[] = [];
  function flattenReplies(reply: Post, postIdPath: string[], includeSelf: boolean = false, parentPost?: Post,
    lastReplyTo?: string, isLastReply?: boolean) {
    if (includeSelf) {
      flattenedReplies.push({
        reply, postIdPath, parentPost,
        lastReplyTo: isLastReply && (collapsedReplies.has(reply.id) || reply.replyCount == 0 || reply.replies.length == 0)
          ? lastReplyTo : undefined,
      });
    }
    if (collapsedReplies.has(reply.id)) return;

    for (const [index, child] of reply.replies.entries()) {
      const isChildLastReply = (index == reply.replies.length - 1 && includeSelf)
        || (!includeSelf && collapsedReplies.has(child.id) || child.replyCount == 0 || (child.replies ?? []).length == 0);
      const childIsLastReplyTo = isChildLastReply ? lastReplyTo ?? reply.id : undefined;
      flattenReplies(child, postIdPath.concat(child.id), true, reply, childIsLastReplyTo, isChildLastReply);
    }
  }
  if (subjectPost) {
    flattenReplies(subjectPost, [subjectPost.id]);
  }
  if (chatUI) {
    flattenedReplies.sort((a, b) => a.reply.createdAt!.localeCompare(b.reply.createdAt!));
  }

  let logicallyReplyingTo: Post | undefined = undefined;
  return (
    <TabsNavigation selectedGroup={group}>
      <YStack f={1} jc="center" ai="center" mt='$3' marginHorizontal='$3' space w='100%' maw={800}>
        {!subjectPost ? <Heading ta="center" fow="800">{`Loading...`}</Heading>
          : <>

            <ScrollView w='100%'>
              <XStack w='100%' paddingHorizontal='$3'>
                {subjectPost ? <PostCard post={subjectPost!} /> : undefined}
              </XStack>
              <XStack mb={chatUI ? 0 : '$3'}>
                <XStack f={1} />

                <Tooltip placement="bottom">
                  <Tooltip.Trigger>
                    <Button backgroundColor={chatUI ? undefined : navColor} transparent={chatUI} onPress={() => dispatch(setDiscussionChatUI(false))}>
                      <Heading size='$4' color={chatUI ? undefined : navTextColor}>Discussion</Heading>
                    </Button>
                  </Tooltip.Trigger>
                  <Tooltip.Content>
                    <Heading size='$2'>Newest on top.</Heading>
                    <Heading size='$1'>Grouped into threads.</Heading>
                  </Tooltip.Content>
                </Tooltip>

                <Tooltip placement="bottom">
                  <Tooltip.Trigger>
                    <Button backgroundColor={!chatUI ? undefined : navColor}
                      transparent={!chatUI}
                      borderTopRightRadius={0} borderBottomRightRadius={0}
                      onPress={() => dispatch(setDiscussionChatUI(true))}>
                      <Heading size='$4' color={!chatUI ? undefined : navTextColor}>Chat</Heading>
                    </Button>
                  </Tooltip.Trigger>
                  <Tooltip.Content>
                    <Heading size='$2'>Newest on bottom.</Heading>
                    <Heading size='$1'>Sorted by time.</Heading>
                  </Tooltip.Content>
                </Tooltip>
                <Tooltip placement="bottom-end">
                  <Tooltip.Trigger>
                    <Button transparent={!chatUI} icon={ListEnd}
                      borderTopLeftRadius={0} borderBottomLeftRadius={0}
                      opacity={!chatUI || showScrollPreserver ? 0.5 : 1}
                      onPress={() => {
                        if (chatUI) {
                          scrollToBottom();
                        } else {
                          dispatch(setDiscussionChatUI(true))
                        }
                      }} />
                  </Tooltip.Trigger>
                  <Tooltip.Content>
                    <Heading size='$2'>Go to newest.</Heading>
                  </Tooltip.Content>
                </Tooltip>
                <XStack f={1} />
              </XStack>
              <XStack w='100%'>
                <FlatList data={flattenedReplies}
                  renderItem={({ item: { reply: post, postIdPath, parentPost, lastReplyTo } }) => {
                    let stripeColor = navColor;
                    const lastReplyToIndex = lastReplyTo ? postIdPath.indexOf(lastReplyTo!) : undefined;
                    const showParentPreview = chatUI && parentPost?.id != subjectPost?.id
                      && parentPost?.id != logicallyReplyingTo?.id
                      && parentPost?.id != logicallyReplyingTo?.replyToPostId;
                    const hideTopMargin = chatUI && parentPost?.id != subjectPost?.id && (parentPost?.id == logicallyReplyingTo?.id || parentPost?.id == logicallyReplyingTo?.replyToPostId);
                    const result = <XStack key={`reply-${post.id}`} id={`reply-${post.id}`}
                      mt={chatUI && !hideTopMargin ? '$3' : 0}
                      animation="bouncy"
                      opacity={1}
                      scale={1}
                      y={0}
                      enterStyle={{
                        // scale: 1.5,
                        y: -50,
                        opacity: 0,
                      }}
                      exitStyle={{
                        // scale: 1.5,
                        // y: 50,
                        opacity: 0,
                      }}
                    >
                      {postIdPath.slice(1).map(() => {
                        stripeColor = (stripeColor == primaryColor) ? navColor : primaryColor;
                        return <YStack w={7} bg={stripeColor} />
                      })}
                      {/* {lastReplyToIndex == undefined && lastReplyToIndex != 0 ?
                  postIdPath.slice(1).map(() => {
                    stripeColor = (stripeColor == primaryColor) ? navColor : primaryColor;
                    return <YStack w={7} bg={stripeColor} />
                  })
                  : postIdPath.slice(1, lastReplyToIndex).map(() => {
                    stripeColor = (stripeColor == primaryColor) ? navColor : primaryColor;
                    return <YStack w={7} bg={stripeColor} />
                  })} */}
                      <XStack f={1}
                      // mb={lastReplyToIndex != undefined ? '$3' : 0}
                      >
                        {/* {lastReplyToIndex != undefined
                    ? postIdPath.slice(Math.max(1,lastReplyToIndex)).map(() => {
                      stripeColor = (stripeColor == primaryColor) ? navColor : primaryColor;
                      return <YStack w={7} bg={stripeColor} />
                    })
                    : undefined} */}
                        <PostCard post={post} replyPostIdPath={postIdPath}
                          collapseReplies={collapsedReplies.has(post.id)}
                          previewParent={showParentPreview ? parentPost : undefined}
                          toggleCollapseReplies={() => toggleCollapseReplies(post.id)} />
                      </XStack>
                    </XStack>;
                    logicallyReplyingTo = post;
                    return result;
                  }}
                  ListFooterComponent={
                    <YStack h={showScrollPreserver ? 100000 : chatUI ? 0 : 150} >

                      {/* <XStack w='100%' mt='$2'>
                    <XStack f={1} />
                    <Tooltip placement="top">
                      <Tooltip.Trigger>
                        <Button circular icon={ListStart}
                          // borderTopLeftRadius={0} borderBottomLeftRadius={0}
                          // opacity={!chatUI || showScrollPreserver ? 0.5 : 1}
                          onPress={scrollToTop} />
                      </Tooltip.Trigger>
                      <Tooltip.Content>
                        <Heading size='$2'>Go to top.</Heading>
                      </Tooltip.Content>
                    </Tooltip>
                    <XStack f={1} />
                  </XStack> */}
                    </YStack>
                  }
                />
              </XStack>
            </ScrollView>
            {showReplyArea ?
              <ReplyArea subject={subjectPost!} subjectPath={[subjectPost!.id]} />
              : undefined}
          </>}
      </YStack>
    </TabsNavigation >
  )
}

interface ReplyAreaProps {
  subject: Post;
  subjectPath: string[];
}

export const ReplyArea: React.FC<ReplyAreaProps> = ({ subject, subjectPath }) => {
  const { dispatch, accountOrServer } = useCredentialDispatch();
  const { server, primaryColor, primaryTextColor, navColor, navTextColor } = useServerInfo();
  const [replyText, setReplyText] = useState('');
  const [previewReply, setPreviewReply] = useState(false);
  const maxPreviewHeight = useWindowDimensions().height * 0.5;
  // const [isReplying, setIsReplying] = useState(false);
  const [isSendingReply, setIsSendingReply] = useState(false);
  const textAreaRef = React.useRef() as React.MutableRefObject<HTMLElement | View>;
  const chatUI = useTypedSelector((state: RootState) => state.app.discussionChatUI);
  function sendReply() {
    setIsSendingReply(true);
    dispatch(replyToPost({
      ...accountOrServer,
      postIdPath: subjectPath,
      content: replyText
    }));
  }
  const sendReplyStatus = useTypedSelector((state: RootState) => state.posts.sendReplyStatus);
  useEffect(() => {
    if (isSendingReply && sendReplyStatus == 'sent') {
      setIsSendingReply(false);
      setReplyText('');
      dispatch(confirmReplySent!());
      if (chatUI && isClient) {
        window.scrollTo({ top: document.body.scrollHeight, behavior: 'smooth' });
      }
    }
    if (!isSendingReply && previewReply && replyText == '') {
      setPreviewReply(false);
    }
  });
  const canComment = (accountOrServer.account?.user?.permissions?.includes(Permission.REPLY_TO_POSTS)
    || accountOrServer.account?.user?.permissions?.includes(Permission.CREATE_POSTS));
  return isWeb ? <StickyBox bottom offsetBottom={0} className='blur' style={{ width: '100%' }}>
    {canComment
      ? <YStack w='100%' opacity={.92} paddingVertical='$2' backgroundColor='$background' alignContent='center'>
        <XStack>
          <ZStack f={1}>
            <TextArea f={1} value={replyText} ref={textAreaRef}
              disabled={isSendingReply} opacity={isSendingReply ? 0.5 : 1}
              onChangeText={t => setReplyText(t)}
              onFocus={() => _replyTextFocused = true}
              onBlur={() => _replyTextFocused = false}
              placeholder={`Reply to this post. Markdown is supported.`} />
            {previewReply
              ? <YStack p='$3' f={1} backgroundColor='$background'>
                <ScrollView maxHeight={maxPreviewHeight} height={maxPreviewHeight}>
                  <TamaguiMarkdown text={replyText} />
                </ScrollView>
              </YStack>
              : undefined}
          </ZStack>
          <YStack mr='$2' ml='$2' mt='auto' ac='flex-end' >
            <YStack f={1} />
            <Tooltip placement="top-end">
              <Tooltip.Trigger>
                <Button circular mb='$2' icon={previewReply ? Edit : Eye}
                  backgroundColor={navColor} color={navTextColor}
                  disabled={replyText == ''} opacity={replyText == '' ? 0.5 : 1}
                  onPress={() => {
                    setPreviewReply(!previewReply);
                    if (previewReply) {
                      setTimeout(() => textAreaRef.current.focus(), 100);
                    }
                  }} />
              </Tooltip.Trigger>
              <Tooltip.Content>
                <Heading size='$2' ta='center' als='center'>{previewReply ? 'Edit reply' : 'Preview reply'}</Heading>
              </Tooltip.Content>
            </Tooltip>
            {/* <YStack f={1}/> */}
            <Button circular icon={SendIcon}
              backgroundColor={primaryColor} color={primaryTextColor}
              disabled={isSendingReply} opacity={isSendingReply ? 0.5 : 1}
              onPress={sendReply} />
          </YStack>
        </XStack>
      </YStack>
      : accountOrServer.account ? <YStack w='100%' opacity={.92} paddingVertical='$2' backgroundColor='$background' alignContent='center'>
        <Heading size='$1'>You do not have permission to comment</Heading>
      </YStack>
        : <YStack w='100%' opacity={.92} p='$3' backgroundColor='$background' alignContent='center'>
          {/* <Button backgroundColor={primaryColor} color={primaryTextColor}>
            Login or Create Account to Comment
          </Button> */}
          <AddAccountSheet />
        </YStack>}
  </StickyBox>
    : <Button mt='$3' circular icon={SendIcon} backgroundColor={primaryColor} onPress={() => { }} />

}