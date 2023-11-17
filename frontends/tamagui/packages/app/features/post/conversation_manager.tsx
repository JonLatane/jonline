import { Post } from '@jonline/api'
import { Button, Heading, Tooltip, XStack, YStack, dismissScrollPreserver, isClient, needsScrollPreservers, useWindowDimensions } from '@jonline/ui'
import { ListEnd } from '@tamagui/lucide-icons'
import { RootState, loadPostReplies, setDiscussionChatUI, useCredentialDispatch, useLocalApp, useServerTheme, useTypedSelector } from 'app/store'
import moment, { Moment } from 'moment'
import React, { useEffect, useReducer, useState } from 'react'
import { useConversationContext } from './conversation_context'
import PostCard from './post_card'

interface ConversationManagerProps {
  post: Post;
}

let _nextChatReplyRefresh: Moment | undefined = undefined;
let _viewportHeight = 0;
if (isClient) {
  visualViewport?.addEventListener('resize', (event) => {
    if (!event.target) return;

    const viewport: VisualViewport = event.target as VisualViewport;
    _viewportHeight = viewport.height ?? 0;
  });
}

export const ConversationManager: React.FC<ConversationManagerProps> = ({
  post,
}) => {
  const { replyPostIdPath, setReplyPostIdPath, editHandler } = useConversationContext()!;
  const { server, primaryColor, primaryTextColor, navColor, navTextColor } = useServerTheme();
  const app = useLocalApp();
  const { dispatch, accountOrServer } = useCredentialDispatch();
  const postsState = useTypedSelector((state: RootState) => state.posts);
  // const post = useTypedSelector((state: RootState) => selectPostById(state.posts, postId!));
  const [loadingPost, setLoadingPost] = useState(false);
  const [loadingReplies, setLoadingReplies] = useState(false);
  const [collapsedReplies, setCollapsedReplies] = useState(new Set<string>());
  const [expandAnimation, setExpandAnimation] = useState(true);

  const [showScrollPreserver, setShowScrollPreserver] = useState(needsScrollPreservers());
  const chatUI = app?.discussionChatUI;
  // const [chatUI, setChatUI] = useState(false);
  const [_, forceUpdate] = useReducer((x) => x + 1, 0);

  function scrollToBottom() {
    if (!isClient) return;
    // if (isReplyTextFocused() && windowHeight > 0) {
    //   window.scrollTo({ top: document.body.scrollHeight - _viewportHeight, behavior: 'smooth' });
    // } else {
    window.scrollTo({ top: document.body.scrollHeight, behavior: 'smooth' });
    // }
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
        dispatch(loadPostReplies({ ...accountOrServer, postIdPath: [post.id!] })).then(() => {
          if (wasAtBottom && chatUI && (Math.abs(scrollYAtBottom - window.scrollY) < 10)) {
            scrollToBottom();
          }
          // forceUpdate();
          setTimeout(() => {
            forceUpdate();
          }, intervalSeconds * 1000);
        });
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
  // const [replyPostIdPath, setReplyPostIdPath] = useState<string[]>(post.id ? [post.id] : []);

  const failedToLoadPost = post.id != undefined &&
    postsState.failedPostIds.includes(post.id!);

  useEffect(() => {
    if (replyPostIdPath.length == 0) {
      setReplyPostIdPath([post.id]);
    }
    // if ((!post || postsState.status == 'unloaded') && postsState.status != 'loading' && !loadingPost) {
    //   setLoadingPost(true);
    //   // useEffect(() => {
    //   console.log('loadPost', post.id!)
    //   setTimeout(() =>
    //     dispatch(loadPost({ ...accountOrServer, id: post.id! })));
    //   // });
    // } else if (post && loadingPost) {
    //   setLoadingPost(false);
    // }
    if (post && postsState.status != 'loading' && post.replyCount > 0 &&
      post.replies.length == 0 && !loadingReplies) {
      setLoadingReplies(true);
      console.log('loadReplies', post.id, post.replyCount, post.replies.length, loadingReplies);
      setTimeout(() =>
        dispatch(loadPostReplies({ ...accountOrServer, postIdPath: [post.id!] })), 1);
    } else if (!post && loadingReplies) {
      setLoadingReplies(false);
    }
    if (post && (post.replyCount == 0 || post.replies.length > 0) && showScrollPreserver) {
      dismissScrollPreserver(setShowScrollPreserver);
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
  if (post) {
    flattenReplies(post, [post.id]);
  }
  if (chatUI) {
    flattenedReplies.sort((a, b) => a.reply.createdAt!.localeCompare(b.reply.createdAt!));
  }
  const dimensions = useWindowDimensions();

  let replyAboveCurrent: Post | undefined = undefined;
  return <YStack>
    <XStack>
      <XStack f={1} />
      <Tooltip placement="bottom">
        <Tooltip.Trigger>
          <Button backgroundColor={chatUI ? undefined : navColor}
            hoverStyle={{ backgroundColor: chatUI ? undefined : navColor }}
            transparent={chatUI}
            onPress={() => dispatch(setDiscussionChatUI(false))} mr='$2'>
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
            hoverStyle={{ backgroundColor: !chatUI ? undefined : navColor }}
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
    {/* <XStack w='100%'>
              <> */}
    <YStack w='100%' key='comments'>
      {flattenedReplies.map(({ reply, postIdPath, parentPost, lastReplyTo }) => {
        let stripeColor = navColor;
        const lastReplyToIndex = lastReplyTo ? postIdPath.indexOf(lastReplyTo!) : undefined;
        const showParentPreview = chatUI && parentPost?.id != post?.id
          && parentPost?.id != replyAboveCurrent?.id
          && parentPost?.id != replyAboveCurrent?.replyToPostId;
        const hideTopMargin = chatUI && parentPost?.id != post?.id && (parentPost?.id == replyAboveCurrent?.id || parentPost?.id == replyAboveCurrent?.replyToPostId);
        const result = <XStack key={`post-reply-${reply.id}`} id={`comment-${reply.id}`}
          // w='100%' f={1}
          mt={(chatUI && !hideTopMargin) || (!chatUI && parentPost?.id == post?.id) ? '$3' : 0}
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
          {postIdPath.slice(1).map((_, index) => {
            stripeColor = (stripeColor == primaryColor) ? navColor : primaryColor;
            return <YStack key={`stripes-index-${index}`} w={7} bg={stripeColor} />
          })}
          <XStack key={`comment-postid-${reply.id}-container`} f={1}>
            <PostCard key={`comment-postid-${reply.id}`}
              post={reply} replyPostIdPath={postIdPath}
              selectedPostId={replyPostIdPath[replyPostIdPath.length - 1]}
              collapseReplies={collapsedReplies.has(reply.id)}
              previewParent={showParentPreview ? parentPost : undefined}
              onLoadReplies={() => setExpandAnimation(true)}
              toggleCollapseReplies={() => {
                setExpandAnimation(collapsedReplies.has(reply.id));
                toggleCollapseReplies(reply.id);
              }}
              onPressReply={() => {
                if (replyPostIdPath[replyPostIdPath.length - 1] == postIdPath[postIdPath.length - 1]) {
                  setReplyPostIdPath([post.id!]);
                } else {
                  setReplyPostIdPath(postIdPath);
                }
              }}
              onEditingChange={editHandler(reply.id)}
              onPressParentPreview={() => {
                const parentPostIdPath = postIdPath.slice(0, -1);
                if (replyPostIdPath[replyPostIdPath.length - 1] == parentPostIdPath[parentPostIdPath.length - 1]) {
                  setReplyPostIdPath([post.id!]);
                } else {
                  setReplyPostIdPath(parentPostIdPath);
                }
              }}
            />
          </XStack>
        </XStack>;
        replyAboveCurrent = reply;
        return result;
      })}
      <YStack key='scrollPreserver' h={showScrollPreserver ? 100000 : chatUI ? 0 : 150} ></YStack>
    </YStack>
  </YStack>;
}