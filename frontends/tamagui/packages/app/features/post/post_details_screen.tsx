import { AnimatePresence, Button, Heading, Paragraph, ScrollView, Spinner, Tooltip, XStack, YStack, standardHorizontalAnimation, useMedia } from '@jonline/ui'
import { ChevronRight, CircleEllipsis, ListEnd } from '@tamagui/lucide-icons'
import { AccountOrServerContextProvider } from 'app/contexts'
import { useAppDispatch, useAppSelector, useCurrentServer, useFederatedDispatch, useHash, useLocalConfiguration } from 'app/hooks'
import { FederatedEvent, FederatedPost, loadEvent, loadPost, parseFederatedId, selectEventById, selectPostById, setDiscussionChatUI, useServerTheme } from 'app/store'
import { setDocumentTitle, themedButtonBackground } from 'app/utils'
import React, { useEffect, useState } from 'react'
import { createParam } from 'solito'
import { federateId, federatedId } from '../../store/federation';
import { useGroupFromPath } from '../groups/group_home_screen'
import { AppSection } from '../navigation/features_navigation'
import { TabsNavigation } from '../navigation/tabs_navigation'
import { ConversationContextProvider, useStatefulConversationContext } from './conversation_context'
import { ConversationManager, scrollToCommentsBottom } from './conversation_manager'
import PostCard from './post_card'
import { ReplyArea } from './reply_area'
import { StarredPostCard } from '../navigation/starred_posts'
import FlipMove from 'react-flip-move';
import { PostContext } from '@jonline/api/index'

const { useParam } = createParam<{ postId: string, shortname: string | undefined }>()

export type PostDetailsInteractionType = 'post' | 'discussion' | 'chat';
export function usePostInteractionType(): [PostDetailsInteractionType, (interactionType: PostDetailsInteractionType) => void] {
  const [interactionTypeParam, _setInteractionType] = useHash();
  const chatUI = useLocalConfiguration().discussionChatUI;
  const dispatch = useAppDispatch();

  function setInteractionType(interactionType: PostDetailsInteractionType) {
    _setInteractionType(interactionType);
    if (interactionType === 'chat' && !chatUI) {
      dispatch(setDiscussionChatUI(true));
    } else if (interactionType === 'discussion' && chatUI) {
      dispatch(setDiscussionChatUI(false));
    }
  }

  switch (interactionTypeParam.replace(/[^a-z]/g, '')) {
    case 'post': return ['post', setInteractionType];
    case 'discussion': return ['discussion', setInteractionType];
    case 'chat': return ['chat', setInteractionType];
    default: return ['post', setInteractionType];
  }
}

export function useReplyAncestors(subjectPost?: FederatedPost) {
  const { dispatch, accountOrServer } = useFederatedDispatch(subjectPost);
  const { server } = accountOrServer;

  const [ancestorPostIds, setAncestorPostIds] = useState([] as string[]);
  const ancestorPosts = useAppSelector(state => ancestorPostIds.map(id => {
    const federatedId = federateId(id, server);
    return selectPostById(state.posts, federatedId);
  }));
  useEffect(() => {
    if (subjectPost && subjectPost.replyToPostId) {
      setAncestorPostIds([subjectPost.replyToPostId]);
    }
  }, [subjectPost]);
  useEffect(() => {
    for (const idx in ancestorPostIds) {
      const postId = ancestorPostIds[idx]!;
      const post = ancestorPosts[idx];

      if (!post) {
        dispatch(loadPost({ ...accountOrServer, id: postId }));
      }
    }

  }, [ancestorPostIds]);

  useEffect(() => {
    if (ancestorPosts[0]?.replyToPostId) {
      setAncestorPostIds([ancestorPosts[0].replyToPostId, ...ancestorPostIds]);
    }
  }, [ancestorPosts]);

  const ancestorEventInstanceId = useAppSelector(state => state.events.postInstances[federateId(ancestorPosts[0]?.id ?? '', server)]);
  const ancestorEventId = useAppSelector(state => ancestorEventInstanceId ? state.events.instanceEvents[ancestorEventInstanceId] : undefined);
  const ancestorEvent = useAppSelector(state => ancestorEventId ? selectEventById(state.events, ancestorEventId) : undefined);
  useEffect(() => {
    if (ancestorPosts[0]?.context === PostContext.EVENT_INSTANCE && !ancestorEvent) {
      dispatch(loadEvent({ ...accountOrServer, postId: ancestorPosts[0]!.id }));
    }
  }, [ancestorPosts[0]?.context, ancestorEvent?.id]);

  const federatedAncestorPostIds = ancestorPostIds.map(id => federateId(id, server));

  return { ancestorPost: ancestorPosts[0], ancestorEvent, federatedAncestorPostIds };
}

export function PostDetailsScreen() {
  const mediaQuery = useMedia();
  const [pathPostId] = useParam('postId');
  // const [postId] = useParam('postId');
  // const [postId, erverHost] = (pathPostId ?? '').split('@');
  const currentServer = useCurrentServer();
  const { id: serverPostId, serverHost } = parseFederatedId(pathPostId ?? '', currentServer?.host);

  const { dispatch, accountOrServer } = useFederatedDispatch(serverHost);
  const server = accountOrServer.server;
  // console.log('PostDetailsScreen', serverPostId, serverHost, accountOrServer);

  const [interactionType, setInteractionType] = usePostInteractionType();
  const { group, pathShortname } = useGroupFromPath();

  const { primaryColor, primaryTextColor, navColor, navTextColor, navAnchorColor } = useServerTheme(accountOrServer.server);
  const app = useLocalConfiguration();

  const postsState = useAppSelector(state => state.posts);
  const federatedPostId = federateId(serverPostId!, server);
  const subjectPost = useAppSelector(state => selectPostById(state.posts, federatedPostId));
  const [loadingPost, setLoadingPost] = useState(false);
  const conversationContext = useStatefulConversationContext();
  const { editingPosts, replyPostIdPath, setReplyPostIdPath, editHandler } = conversationContext;

  // const [showScrollPreserver, setShowScrollPreserver] = useState(needsScrollPreservers());
  // const chatUI = app?.discussionChatUI;
  // const [chatUI, setChatUI] = useState(false);
  const showReplyArea = subjectPost != undefined && editingPosts.length == 0;

  const failedToLoadPost = serverPostId && postsState.failedPostIds.includes(federateId(serverPostId, server));

  useEffect(() => {
    if (serverPostId && server) {
      if (!subjectPost && !loadingPost) {
        setLoadingPost(true);
        // console.log('loadPost', postId!)
        setTimeout(() =>
          dispatch(loadPost({ ...accountOrServer, id: serverPostId! })));
      } else if (subjectPost && loadingPost) {
        setLoadingPost(false);
      }
    }
  }, [serverPostId, server, subjectPost, loadingPost]);

  const serverName = server?.serverConfiguration?.serverInfo?.name || '...';

  // function scrollToBottom() {
  //   window.scrollTo({ top: document.body.scrollHeight, behavior: 'smooth' });
  // }
  function scrollToTop() {
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }
  const chatUI = app?.discussionChatUI;

  // const [ancestorPostIds, setAncestorPostIds] = useState([] as string[]);
  // const ancestorPosts = useAppSelector(state => ancestorPostIds.map(id => {
  //   const federatedId = federateId(id, server);
  //   return selectPostById(state.posts, federatedId);
  // }));
  // useEffect(() => {
  //   if (subjectPost && subjectPost.replyToPostId) {
  //     setAncestorPostIds([subjectPost.replyToPostId]);
  //   }
  // }, [subjectPost]);
  // useEffect(() => {
  //   for (const idx in ancestorPostIds) {
  //     const postId = ancestorPostIds[idx]!;
  //     const post = ancestorPosts[idx];

  //     if (!post) {
  //       dispatch(loadPost({ ...accountOrServer, id: postId }));
  //     }
  //   }

  // }, [ancestorPostIds]);

  // useEffect(() => {
  //   if (ancestorPosts[0]?.replyToPostId) {
  //     setAncestorPostIds([ancestorPosts[0].replyToPostId, ...ancestorPostIds]);
  //   }
  // }, [ancestorPosts]);

  // const ancestorEventInstanceId = useAppSelector(state => state.events.postInstances[federateId(ancestorPosts[0]?.id ?? '', server)]);
  // const ancestorEventId = useAppSelector(state => ancestorEventInstanceId ? state.events.instanceEvents[ancestorEventInstanceId] : undefined);
  // const ancestorEvent = useAppSelector(state => ancestorEventId ? selectEventById(state.events, ancestorEventId) : undefined);
  // useEffect(() => {
  //   if (ancestorPosts[0]?.context === PostContext.EVENT_INSTANCE && !ancestorEvent) {
  //     dispatch(loadEvent({ ...accountOrServer, postId: ancestorPosts[0]!.id }));
  //   }
  // }, [ancestorPosts[0]?.context, ancestorEvent?.id]);

  // const federatedAncestorPostIds = ancestorPostIds.map(id => federateId(id, server));

  const { ancestorPost, ancestorEvent, federatedAncestorPostIds } = useReplyAncestors(subjectPost);

  const ancestorTitle = ancestorEvent?.post?.title || ancestorPost?.title;
  const subjectPostTitle = subjectPost?.title || (ancestorTitle ? `Comments - ${ancestorTitle}` : '');
  const [showContext, setShowContext] = useState(false);
  useEffect(() => {
    let title = '';
    if (subjectPost) {
      if (subjectPostTitle && subjectPostTitle.length > 0) {
        title = subjectPostTitle;
      } else {
        title = `Post Details (#${subjectPost.id})`;
      }
    } else if (failedToLoadPost) {
      title = 'Post Not Found';
    } else {
      title = 'Loading Post...';
    }
    title += ` - ${serverName}`;
    if (pathShortname && pathShortname.length > 0 && group && group.name.length > 0) {
      title += `- ${group.name}`;
    }
    setDocumentTitle(title)
  });

  return (
    <TabsNavigation appSection={AppSection.POSTS} selectedGroup={group}
      primaryEntity={subjectPost ?? { serverHost: serverHost ?? currentServer?.host }}
      groupPageForwarder={(groupIdentifier) => `/g/${groupIdentifier}/p/${pathPostId}`}
      groupPageReverse={`/post/${pathPostId}`}
      topChrome={
        <XStack w='100%' maw={800} mx='auto' mt='$1' ai='center'>
          <Tooltip placement="bottom">
            <Tooltip.Trigger>
              <Button {...themedButtonBackground(interactionType === 'post' ? navColor : undefined)}
                transparent={interactionType !== 'post'} mr='$2'
                px='$2'
                onPress={() => {
                  scrollToTop();
                  if (interactionType === 'post') {
                    setShowContext(!showContext);
                  } else {
                    setInteractionType('post');
                  }
                }}>
                {mediaQuery.gtSm
                  ? <Paragraph size='$1' color={interactionType == 'post' ? navTextColor : undefined} fontWeight='bold' my='auto' animation='standard' o={0.5} f={1}>
                    {subjectPostTitle || 'Loading...'}
                  </Paragraph>
                  : <Heading size='$4' color={interactionType == 'post' ? navTextColor : undefined}>{subjectPost?.context === PostContext.REPLY ? 'Comments' : 'Post'}</Heading>}
              </Button>
            </Tooltip.Trigger>
            <Tooltip.Content>
              <Heading size='$2'>{subjectPost?.context === PostContext.REPLY ? showContext ? 'Comment Context' :'Comment Details' : 'Post Details'}</Heading>
            </Tooltip.Content>
          </Tooltip>

          <XStack f={1} />

          <Tooltip placement="bottom">
            <Tooltip.Trigger>
              <Button {...themedButtonBackground(interactionType === 'discussion' ? navColor : undefined)}
                transparent={interactionType !== 'discussion'}
                px='$2'
                onPress={() => setInteractionType('discussion')} mr='$2'>
                <Heading size='$4' color={interactionType == 'discussion' ? navTextColor : !chatUI ? navAnchorColor : undefined}>Discussion</Heading>
              </Button>
            </Tooltip.Trigger>
            <Tooltip.Content>
              <Heading size='$2'>Newest on top.</Heading>
              <Heading size='$1'>Grouped into threads.</Heading>
            </Tooltip.Content>
          </Tooltip>

          <Tooltip placement="bottom">
            <Tooltip.Trigger>
              <Button {...themedButtonBackground(interactionType === 'chat' ? navColor : undefined)}
                transparent={interactionType !== 'chat'}
                px='$2'
                borderTopRightRadius={0} borderBottomRightRadius={0}
                onPress={() => setInteractionType('chat')}>
                <Heading size='$4' color={interactionType == 'chat' ? navTextColor : chatUI ? navAnchorColor : undefined}>Chat</Heading>
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
                opacity={!chatUI ? 0.5 : 1}
                onPress={() => {
                  if (chatUI) {
                    scrollToCommentsBottom(federatedPostId);
                  } else {
                    setInteractionType('chat');
                    setTimeout(() => scrollToCommentsBottom(federatedPostId), 1000);
                  }
                }} />
            </Tooltip.Trigger>
            <Tooltip.Content>
              <Heading size='$2'>Go to newest.</Heading>
            </Tooltip.Content>
          </Tooltip>
        </XStack>
      }
      bottomChrome={
        <AccountOrServerContextProvider value={accountOrServer}>
          <ReplyArea replyingToPath={replyPostIdPath}
            onStopReplying={() => serverPostId && setReplyPostIdPath([serverPostId])}
            hidden={!showReplyArea} />
        </AccountOrServerContextProvider>}
    >
      {!subjectPost
        ? failedToLoadPost
          ? <>
            <Heading size='$5'>Post not found.</Heading>
            <Heading size='$3' ta='center'>It may either not exist, not be visible to you, or be hidden by moderators.</Heading>
          </>
          : <Spinner size='large' color={navColor} scale={2} />
        : <AccountOrServerContextProvider value={accountOrServer}>
          <ConversationContextProvider value={conversationContext}>
            <YStack f={1} jc="center" ai="center" mt='$3' space w='100%' maw={800}>
              <ScrollView w='100%'>
                <FlipMove>
                  {interactionType === 'post'
                    ? [
                      showContext
                        ? federatedAncestorPostIds.map(
                          id =>
                            <div key={`context-${id}`} style={{ display: 'flex', flexDirection: 'column' }}>
                              <YStack w='100%' px='$3'>
                                <XStack w='100%'>
                                  <XStack mt='$7'>
                                    <ChevronRight />
                                  </XStack>
                                  <YStack f={1} >
                                    <StarredPostCard key={`post-card-ancestor-${id}`}
                                      postId={id}
                                      fullSize
                                      showPermalink
                                      hideCurrentUser />
                                  </YStack>
                                </XStack>
                                <XStack ml='$7'><CircleEllipsis transform={[{ rotate: '90deg' }]} /></XStack>
                              </YStack>
                            </div>
                        )
                        : undefined,
                      <div key='subjectPost'>
                        <XStack w='100%' px='$3'
                        // animation='standard' {...standardHorizontalAnimation}
                        >
                          <PostCard key={`post-card-main-${serverPostId}`}
                            post={subjectPost}
                            onEditingChange={editHandler(subjectPost.id)}
                            isSubjectPost />
                        </XStack>
                      </div>
                    ]
                    : undefined}
                  <div key='convo'>
                    <ConversationManager key='convo' post={subjectPost} />
                  </div>
                </FlipMove>
              </ScrollView>


            </YStack>
          </ConversationContextProvider>
        </AccountOrServerContextProvider>
      }
    </TabsNavigation >
  )
}
