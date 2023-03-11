import { Permission, Post } from '@jonline/api'
import { Button, dismissScrollPreserver, Heading, isClient, isWeb, needsScrollPreservers, ScrollView, Spinner, TextArea, Tooltip, useWindowDimensions, XStack, YStack, ZStack } from '@jonline/ui'
import { Edit, Eye, ListEnd, Send as SendIcon } from '@tamagui/lucide-icons'
import { confirmReplySent, loadPost, loadPostReplies, replyToPost, RootState, selectGroupById, selectPostById, setDiscussionChatUI, useCredentialDispatch, useLocalApp, useServerTheme, useTypedSelector } from 'app/store'
import moment, { Moment } from 'moment'
import React, { useEffect, useReducer, useState } from 'react'
import { FlatList, View } from 'react-native'
import StickyBox from 'react-sticky-box'
import { createParam } from 'solito'
import { AddAccountSheet } from '../accounts/add_account_sheet'
import { TabsNavigation } from '../tabs/tabs_navigation'
import PostCard from './post_card'
import { TamaguiMarkdown } from './tamagui_markdown'

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

  const { server, primaryColor, primaryTextColor, navColor, navTextColor } = useServerTheme();
  const app = useLocalApp();
  const groupId = useTypedSelector((state: RootState) =>
    shortname ? state.groups.shortnameIds[shortname!] : undefined);
  const group = useTypedSelector((state: RootState) =>
    groupId ? selectGroupById(state.groups, groupId) : undefined);
  const { dispatch, accountOrServer } = useCredentialDispatch();
  const postsState = useTypedSelector((state: RootState) => state.posts);
  const subjectPost = useTypedSelector((state: RootState) => selectPostById(state.posts, postId!));
  const [loadingPost, setLoadingPost] = useState(false);
  const [loadingReplies, setLoadingReplies] = useState(false);
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
      _nextChatReplyRefresh = moment().add(intervalSeconds, 'second');
      const wasAtBottom = isClient && !showScrollPreserver &&
        document.body.scrollHeight - _viewportHeight - window.scrollY < 100;
      const scrollYAtBottom = window.scrollY;
      // console.log('wasAtBottom', wasAtBottom, document.body.scrollHeight, _viewportHeight, window.scrollY)
      setTimeout(() => {
        if (postId) {
          dispatch(loadPostReplies({ ...accountOrServer, postIdPath: [postId!] })).then(() => {
            if (wasAtBottom && chatUI && (Math.abs(scrollYAtBottom - window.scrollY) < 10)) {
              scrollToBottom();
            }
            // forceUpdate();
            setTimeout(() => {
              forceUpdate();
            }, intervalSeconds * 1000);
          });
        } else {
          setTimeout(() => {
            forceUpdate();
          }, intervalSeconds * 1000);
        }
      }, 1);
      // if (wasAtBottom) {
      //   setTimeout(() => {
      //     if (chatUI && (Math.abs(scrollYAtBottom - window.scrollY) < 10)) {
      //       scrollToBottom();
      //     }
      //   }, 1000);
      // }
      // _nextChatReplyRefresh = moment().add(intervalSeconds, 'second');
      // setTimeout(() => {
      //   forceUpdate();
      // }, intervalSeconds * 1000);
    }
  }
  const [replyPostIdPath, setReplyPostIdPath] = useState<string[]>(postId ? [postId] : []);

  const failedToLoadPost = postId != undefined &&
    postsState.failedPostIds.includes(postId!);

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
        subjectPost.replies.length == 0 && !loadingReplies) {
        setLoadingReplies(true);
        console.log('loadReplies', subjectPost.id, subjectPost.replyCount, subjectPost.replies.length, loadingReplies);
        setTimeout(() =>
          dispatch(loadPostReplies({ ...accountOrServer, postIdPath: [postId!] })), 1);
      } else if (!subjectPost && loadingReplies) {
        setLoadingReplies(false);
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
  const dimensions = useWindowDimensions();

  let logicallyReplyingTo: Post | undefined = undefined;
  return (
    <TabsNavigation selectedGroup={group}>
      {!subjectPost
        ? failedToLoadPost
          ? <>
            <Heading size='$5'>Post not found.</Heading>
            <Heading size='$3' ta='center'>It may either not exist, not be visible to you, or be hidden by moderators.</Heading>
          </>
          : <Spinner size='large' color={navColor} scale={2} />
        : <YStack f={1} jc="center" ai="center" mt='$3' space w='100%' maw={800}>
          <ScrollView w='100%'>
            <XStack w='100%' paddingHorizontal='$3'>
              {subjectPost ? <PostCard post={subjectPost!} /> : undefined}
            </XStack>
            <XStack>
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
                    mt={(chatUI && !hideTopMargin) || (!chatUI && parentPost?.id == subjectPost?.id) ? '$3' : 0}
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
                        selectedPostId={replyPostIdPath[replyPostIdPath.length - 1]}
                        collapseReplies={collapsedReplies.has(post.id)}
                        previewParent={showParentPreview ? parentPost : undefined}
                        toggleCollapseReplies={() => toggleCollapseReplies(post.id)}
                        onPress={() => {
                          if (replyPostIdPath[replyPostIdPath.length - 1] == postIdPath[postIdPath.length - 1]) {
                            setReplyPostIdPath([postId!]);
                          } else {
                            setReplyPostIdPath(postIdPath);
                          }
                        }}
                        onPressParentPreview={() => {
                          const parentPostIdPath = postIdPath.slice(0, -1);
                          if (replyPostIdPath[replyPostIdPath.length - 1] == parentPostIdPath[parentPostIdPath.length - 1]) {
                            setReplyPostIdPath([postId!]);
                          } else {
                            setReplyPostIdPath(parentPostIdPath);
                          }
                        }}
                      // onPressParentPreview={() => setReplyPostIdPath(postIdPath.slice(0, -1))}
                      />
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
            <ReplyArea replyingToPath={replyPostIdPath} />
            : undefined}

        </YStack>
      }
    </TabsNavigation >
  )
}

interface ReplyAreaProps {
  replyingToPath: string[];
}

export const ReplyArea: React.FC<ReplyAreaProps> = ({ replyingToPath }) => {
  const { dispatch, accountOrServer } = useCredentialDispatch();
  const { server, primaryColor, primaryTextColor, navColor, navTextColor } = useServerTheme();
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
      postIdPath: replyingToPath,
      content: replyText
    }));
  }
  // const replyingToPost = 
  let pathIndex = 0;
  const rootPost = useTypedSelector((state: RootState) => selectPostById(state.posts, replyingToPath[pathIndex++]!));
  const targetPostId = replyingToPath[replyingToPath.length - 1];
  let targetPost = rootPost;
  while (targetPost != null && targetPost?.id != targetPostId) {
    const replyId = replyingToPath[pathIndex++];
    // debugger;
    targetPost = targetPost?.replies?.find(reply => reply.id == replyId);
    // debugger;
  }
  const replyingToPost = targetPost;
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
      ? <YStack w='100%' pl='$2' opacity={.92} paddingVertical='$2' backgroundColor='$background' alignContent='center'>
        {replyingToPath.length > 1
          ? <Heading size='$1'>Replying to {replyingToPost?.author?.username ?? ''}</Heading>
          : undefined}
        <XStack>
          <ZStack f={1}>
            <TextArea f={1} value={replyText} ref={textAreaRef}
              disabled={isSendingReply} opacity={isSendingReply ? 0.5 : 1}
              onChangeText={t => setReplyText(t)}
              onFocus={() => { _replyTextFocused = true; /*window.scrollTo({ top: window.scrollY - _viewportHeight/2, behavior: 'smooth' });*/ }}
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
        <Heading size='$1'>You do not have permission to {chatUI ? 'chat' : 'comment'}.</Heading>
      </YStack>
        : <YStack w='100%' opacity={.92} p='$3' backgroundColor='$background' alignContent='center'>
          {/* <Button backgroundColor={primaryColor} color={primaryTextColor}>
            Login or Create Account to Comment
          </Button> */}
          <AddAccountSheet operation={chatUI ? 'Chat' : 'Comment'} />
        </YStack>}
  </StickyBox>
    : <Button mt='$3' circular icon={SendIcon} backgroundColor={primaryColor} onPress={() => { }} />

}
// var lastScrollTop = 0;

// // element should be replaced with the actual target element on which you have applied scroll, use window in case of no target element.
// isClient && window.addEventListener("scroll", function(){ // or window.addEventListener("scroll"....
//    var st = window.pageYOffset || document.documentElement.scrollTop; // Credits: "https://github.com/qeremy/so/blob/master/so.dom.js#L426"
//    if (st > lastScrollTop) {
//       // downscroll code
//    } else if (st < lastScrollTop) {
//       // upscroll code
//    } // else was horizontal scroll
//    lastScrollTop = st <= 0 ? 0 : st; // For Mobile or negative scrolling
// }, false);
