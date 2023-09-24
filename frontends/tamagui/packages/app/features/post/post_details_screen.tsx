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
import { AppSection } from '../tabs/features_navigation'
import { TextInput } from 'react-native'
import { ReplyArea, isReplyTextFocused } from './reply_area'

const { useParam } = createParam<{ postId: string, shortname: string | undefined }>()

let _nextChatReplyRefresh: Moment | undefined = undefined;
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
  const [expandAnimation, setExpandAnimation] = useState(true);

  const [editingPost, setEditingPost] = useState(undefined as Post | undefined);

  const [showScrollPreserver, setShowScrollPreserver] = useState(needsScrollPreservers());
  const chatUI = app?.discussionChatUI;
  // const [chatUI, setChatUI] = useState(false);
  const showReplyArea = subjectPost != undefined;
  const [_, forceUpdate] = useReducer((x) => x + 1, 0);
  const { width, height: windowHeight } = useWindowDimensions();
  function scrollToBottom() {
    if (!isClient) return;
    if (isReplyTextFocused() && windowHeight > 0) {
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
      if (replyPostIdPath.length == 0) {
        setReplyPostIdPath([postId]);
      }
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
    const serverName = server?.serverConfiguration?.serverInfo?.name || 'Jonline';
    let title = '';
    if (subjectPost) {
      if (subjectPost.title && subjectPost.title.length > 0) {
        title = subjectPost.title;
      } else {
        title = `Post Details (#${subjectPost.id})`;
      }
    } else if (failedToLoadPost) {
      title = 'Post Not Found';
    } else {
      title = 'Loading Post...';
    }
    title += ` - ${serverName}`;
    if (shortname && shortname.length > 0 && group && group.name.length > 0) {
      title += `- ${group.name}`;
    }
    document.title = title;
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
    <TabsNavigation appSection={AppSection.POST} selectedGroup={group}>
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
                  <Button backgroundColor={chatUI ? undefined : navColor} transparent={chatUI} onPress={() => dispatch(setDiscussionChatUI(false))} mr='$2'>
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
              <>
                <YStack w='100%'>
                  {flattenedReplies.map(({ reply: post, postIdPath, parentPost, lastReplyTo }) => {
                    let stripeColor = navColor;
                    const lastReplyToIndex = lastReplyTo ? postIdPath.indexOf(lastReplyTo!) : undefined;
                    const showParentPreview = chatUI && parentPost?.id != subjectPost?.id
                      && parentPost?.id != logicallyReplyingTo?.id
                      && parentPost?.id != logicallyReplyingTo?.replyToPostId;
                    const hideTopMargin = chatUI && parentPost?.id != subjectPost?.id && (parentPost?.id == logicallyReplyingTo?.id || parentPost?.id == logicallyReplyingTo?.replyToPostId);
                    const result = <XStack key={`reply-${post.id}`} id={`reply-${post.id}`}
                      // w='100%' f={1}
                      mt={(chatUI && !hideTopMargin) || (!chatUI && parentPost?.id == subjectPost?.id) ? '$3' : 0}
                      animation='standard'
                      opacity={1}
                      scale={1}
                      y={0}
                      enterStyle={{
                        // scale: 1.5,
                        y: expandAnimation ? -50 : 50,
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
                        <PostCard key={`comment-post-${post.id}`} post={post} replyPostIdPath={postIdPath}
                          selectedPostId={replyPostIdPath[replyPostIdPath.length - 1]}
                          collapseReplies={collapsedReplies.has(post.id)}
                          previewParent={showParentPreview ? parentPost : undefined}
                          onLoadReplies={() => setExpandAnimation(true)}
                          toggleCollapseReplies={() => {
                            setExpandAnimation(collapsedReplies.has(post.id));
                            toggleCollapseReplies(post.id);
                          }}
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
                  })}
                  <YStack h={showScrollPreserver ? 100000 : chatUI ? 0 : 150} ></YStack>
                </YStack>
              </>
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
