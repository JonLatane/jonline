import { Post } from '@jonline/api';
import { Button, Heading, Spinner, Tooltip, XStack, YStack, dismissScrollPreserver, isClient, needsScrollPreservers, standardAnimation, useWindowDimensions } from '@jonline/ui';
import { ListEnd } from '@tamagui/lucide-icons';
import { useFederatedDispatch, useLocalConfiguration } from 'app/hooks';
import { FederatedPost, federatedId, loadPostReplies, setDiscussionChatUI, useServerTheme } from 'app/store';
import moment, { Moment } from 'moment';
import React, { useCallback, useEffect, useMemo, useReducer, useState } from 'react';
import { AutoAnimatedList } from '.';
import { ConversationContextType, useConversationContext } from './conversation_context';
import PostCard from './post_card';
import { usePostInteractionType } from './post_details_screen';

interface ConversationManagerProps {
  post: FederatedPost | undefined;
  disableScrollPreserver?: boolean;
  forStarredPost?: boolean;
  conversationContext?: ConversationContextType;
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

export const ConversationManager: React.FC<ConversationManagerProps> = ({ post, disableScrollPreserver, forStarredPost }) => {
  const { dispatch, accountOrServer } = useFederatedDispatch(post);
  const { navColor, navTextColor } = useServerTheme(accountOrServer.server);
  const app = useLocalConfiguration();
  const [showScrollPreserver, setShowScrollPreserver] = useState(needsScrollPreservers());
  const chatUI = app?.discussionChatUI;

  const [interactionType] = usePostInteractionType();
  const conversationContext = useConversationContext()!;
  const commentList = useConversationCommentList({ post, disableScrollPreserver, forStarredPost, conversationContext });
  return <YStack w='100%' key='comments'>
    <AutoAnimatedList>
      {interactionType === 'post'
        ? <XStack animation='standard' {...standardAnimation}>
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
                    scrollToCommentsBottom(post ? federatedId(post) : undefined);
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
        : undefined}
      {/* <ConversationCommentList post={post} /> */}
      {...commentList}
    </AutoAnimatedList>
  </YStack>;
}

const regexp = new RegExp(/[^\w]/, 'g');
const getTopId = (postId: string | undefined) => `conversation-top-${postId?.replaceAll(regexp, '-')}`;
const getBottomId = (postId: string | undefined) => `conversation-bottom-${postId?.replaceAll(regexp, '-')}`;

export function scrollToCommentsBottom(postId: string | undefined) {
  if (!isClient) return;

  console.log('scrollToCommentsBottom', postId, getBottomId(postId), document.querySelectorAll(`#${getBottomId(postId)}`));

  document.querySelectorAll(`#${getBottomId(postId)}`)
    .forEach(e => e.scrollIntoView({ block: 'center', behavior: 'smooth' }));
}

export function scrollToCommentsTop(postId: string | undefined) {
  if (!isClient) return;

  console.log('scrollToCommentsTop', getTopId(postId), document.querySelectorAll(`#${getTopId(postId)}`));

  document.querySelectorAll(`#${getTopId(postId)}`)
    .forEach(e => e.scrollIntoView({ block: 'center', behavior: 'smooth' }));
}
export function useConversationCommentList({
  post, disableScrollPreserver, forStarredPost, conversationContext
}: ConversationManagerProps) {
  const { dispatch, accountOrServer } = useFederatedDispatch(post);
  // console.log('conversationContext', conversationContext);
  const { replyPostIdPath, setReplyPostIdPath, editHandler } = conversationContext!;
  const { primaryColor, primaryTextColor, navColor, navTextColor } = useServerTheme(accountOrServer.server);
  const rootPostId = post ? federatedId(post) : undefined;
  const app = useLocalConfiguration();
  const [loadingRepliesFor, setLoadingRepliesFor] = useState(undefined as string | undefined);
  const [collapsedReplies, setCollapsedReplies] = useState(new Set<string>());
  // const [expandAnimation, setExpandAnimation] = useState(true);

  const [showScrollPreserver, setShowScrollPreserver] = useState(needsScrollPreservers());
  const chatUI = app?.discussionChatUI;
  // const [chatUI, setChatUI] = useState(false);
  const [_, forceUpdate] = useReducer((x) => x + 1, 0);

  const autoRefresh = app?.autoRefreshDiscussions ?? true;
  useEffect(() => {
    if (chatUI && autoRefresh) {
      if (!_nextChatReplyRefresh || moment().isAfter(_nextChatReplyRefresh)) {
        const intervalSeconds = app?.discussionRefreshIntervalSeconds || 6;
        _nextChatReplyRefresh = moment().add(intervalSeconds, 'second');
        const wasAtBottom = isClient && !showScrollPreserver &&
          document.body.scrollHeight - _viewportHeight - window.scrollY < 100;
        const scrollYAtBottom = window.scrollY;
        setTimeout(() => {
          if (rootPostId?.split('@')[0]) {
            dispatch(loadPostReplies({ ...accountOrServer, postIdPath: [rootPostId!] })).then(() => {
              if (wasAtBottom && chatUI && (Math.abs(scrollYAtBottom - window.scrollY) < 10)) {
                scrollToCommentsBottom(rootPostId);
              }
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
      }
    }
  });

  useEffect(() => {
    if (rootPostId && (replyPostIdPath.length == 0 || replyPostIdPath[0] != rootPostId)) {
      setReplyPostIdPath([rootPostId]);
    }
    // console.log('postId', post?.id, 'post.replyCount', post?.replyCount, 'post.replies.length', post?.replies.length, 'loadingReplies', loadingRepliesFor);
    if (post && post?.id && post.replyCount > 0 && post.replies.length === 0 && (!loadingRepliesFor || loadingRepliesFor != rootPostId)) {
      setLoadingRepliesFor(rootPostId!);
      // console.log('loadReplies', rootPostId, post.replyCount, post.replies.length, loadingReplies);
      setTimeout(
        () => dispatch(loadPostReplies({ ...accountOrServer, postIdPath: [rootPostId!] }))
          .then(() => setLoadingRepliesFor(undefined)),
        1
      );
    } else if (!post && loadingRepliesFor) {
      setLoadingRepliesFor(undefined);
    }
  }, [post, post?.replyCount, post?.replies.length, rootPostId, replyPostIdPath, loadingRepliesFor]);

  useEffect(() => {
    if (post && (post.replyCount == 0 || post.replies.length > 0) && showScrollPreserver) {
      dismissScrollPreserver(setShowScrollPreserver);
    }
  }, [post, post?.replyCount, post?.replies.length, showScrollPreserver]);

  const toggleCollapseReplies = useCallback((postId: string) => {
    if (collapsedReplies.has(postId)) {
      collapsedReplies.delete(postId);
    } else {
      collapsedReplies.add(postId);
    }
    setCollapsedReplies(new Set(collapsedReplies));
  }, [collapsedReplies]);

  type FlattenedReply = {
    postIdPath: string[];
    reply: Post;
    parentPost?: Post;
    lastReplyTo?: string;
  }

  const flattenedReplies: FlattenedReply[] = useMemo(() => {
    const result = [] as FlattenedReply[];
    function flattenReplies(
      reply: Post, postIdPath: string[], includeSelf: boolean = false, parentPost?: Post,
      lastReplyTo?: string, isLastReply?: boolean
    ) {
      if (includeSelf) {
        result.push({
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
      flattenReplies(post, rootPostId ? [rootPostId] : []);
    }
    if (chatUI) {
      result.sort((a, b) => a.reply.createdAt!.localeCompare(b.reply.createdAt!));
    }
    return result;
  }, [chatUI, post?.replies, collapsedReplies]);
  const dimensions = useWindowDimensions();

  let replyAboveCurrent: Post | undefined = undefined;
  const [interactionType] = usePostInteractionType();
  return [
    <XStack key='top' id={post ? getTopId(federatedId(post)) : undefined} />,
    flattenedReplies.length == 0
      ? post && !loadingRepliesFor
        ? <Heading key='no-replies' size='$3' mx='auto' w='100%'
          pt={forStarredPost ? 50
            : interactionType === 'post' ? 100
              : window.innerHeight / 2 - 200}
          pb={forStarredPost ? 50
            : window.innerHeight / 2}
        >No replies yet.</Heading>
        : <XStack key='no-replies' w='100%'
          pt={forStarredPost ? 50
            : interactionType === 'post' ? 100
              : window.innerHeight / 2 - 200}
          pb={forStarredPost ? 50
            : window.innerHeight / 2}>
          <Spinner size='large' mx='auto' color={primaryColor} />
        </XStack>
      : undefined,
    ...flattenedReplies.map(({ reply, postIdPath, parentPost, lastReplyTo }) => {
      let stripeColor = navColor;
      const lastReplyToIndex = lastReplyTo ? postIdPath.indexOf(lastReplyTo!) : undefined;
      const showParentPreview = chatUI && parentPost?.id != post?.id
        && parentPost?.id != replyAboveCurrent?.id
        && parentPost?.id != replyAboveCurrent?.replyToPostId;
      const hideTopMargin = chatUI && parentPost?.id != post?.id && (parentPost?.id == replyAboveCurrent?.id || parentPost?.id == replyAboveCurrent?.replyToPostId);
      const result = <XStack key={`post-reply-${reply.id}`} id={`comment-${reply.id}`} w='100%'
        // w='100%' f={1}
        mt={(chatUI && !hideTopMargin) || (!chatUI && parentPost?.id == post?.id) ? '$3' : 0}
      // animation='standard'
      // opacity={1}
      // scale={1}
      // y={0}
      // enterStyle={{
      //   // scale: 1.5,
      //   y: expandAnimation ? -50 : 50,
      //   opacity: 0,
      // }}
      // exitStyle={{
      //   // scale: 1.5,
      //   // y: 50,
      //   opacity: 0,
      // }}
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
            // onLoadReplies={() => setExpandAnimation(true)}
            toggleCollapseReplies={() => {
              // setExpandAnimation(collapsedReplies.has(reply.id));
              toggleCollapseReplies(reply.id);
            }}
            onPressReply={() => {
              if (replyPostIdPath[replyPostIdPath.length - 1] == postIdPath[postIdPath.length - 1]) {
                setReplyPostIdPath([rootPostId!]);
              } else {
                setReplyPostIdPath(postIdPath);
              }
            }}
            onEditingChange={editHandler(reply.id)}
            onPressParentPreview={() => {
              const parentPostIdPath = postIdPath.slice(0, -1);
              if (replyPostIdPath[replyPostIdPath.length - 1] == parentPostIdPath[parentPostIdPath.length - 1]) {
                setReplyPostIdPath([rootPostId!]);
              } else {
                setReplyPostIdPath(parentPostIdPath);
              }
            }}
          />
        </XStack>
      </XStack>;
      replyAboveCurrent = reply;
      return result;
    }),
    <XStack key='bottom' id={post ? getBottomId(federatedId(post)) : undefined} f={1} />,
    <YStack key='scrollPreserver' h={showScrollPreserver && !disableScrollPreserver ? 100000 : 0} ></YStack>
  ];
}
