import { PostContext } from '@jonline/api/index'
import { Button, Heading, Paragraph, ScrollView, Spinner, Tooltip, XStack, YStack, ZStack, useDebounce, useDebounceValue, useMedia } from '@jonline/ui'
import { createSelector } from '@reduxjs/toolkit'
import { ChevronRight, ChevronUp, CircleEllipsis, ListEnd } from '@tamagui/lucide-icons'
import { AccountOrServerContextProvider } from 'app/contexts'
import { useGroupFromPath } from 'app/features/groups/group_home_screen'
import { AppSection } from 'app/features/navigation/features_navigation'
import { TabsNavigation } from 'app/features/navigation/tabs_navigation'
import { Selector, useAppDispatch, useAppSelector, useCurrentServer, useFederatedDispatch, useHash, useLocalConfiguration } from 'app/hooks'
import { FederatedPost, RootState, accountID, loadEvent, loadPost, parseFederatedId, selectEventById, selectPostById, serverID, setDiscussionChatUI, useDebouncedAccountOrServer, useServerTheme } from 'app/store'
import { HasServer, federateId } from 'app/store/federation'
import { setDocumentTitle, themedButtonBackground } from 'app/utils'
import React, { useEffect, useState } from 'react'
import FlipMove from 'lumen5-react-flip-move'
import { createParam } from 'solito'
import { StarredPostCard } from '../navigation/starred_post_card'
import { ConversationContextProvider, useStatefulConversationContext } from './conversation_context'
import { ConversationManager, scrollToCommentsBottom } from './conversation_manager'
import PostCard from './post_card'
import { ReplyArea } from './reply_area'

const { useParam } = createParam<{ postId: string, shortname: string | undefined }>()

export type PostDetailsInteractionType = 'post' | 'discussion' | 'chat';
export function usePostInteractionType(): [PostDetailsInteractionType, (interactionType: PostDetailsInteractionType) => void] {
  const [_, _setInteractionType] = useHash();
  const interactionTypeParam = window.location.hash;
  // console.log('usePostInteractionType', {interactionTypeParam, other: window.location.hash})
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


const selectReplyAncestors = (
  ancestorPostIds: string[],
  server: HasServer
): Selector<(FederatedPost | undefined)[]> =>
  createSelector(
    [(state: RootState) => ancestorPostIds.map(id => {
      const federatedId = federateId(id, server);
      return selectPostById(state.posts, federatedId);
    })],
    (data) => data
  );


export function useReplyAncestors(subjectPost?: FederatedPost) {
  const { dispatch, accountOrServer } = useFederatedDispatch(subjectPost);
  const { server } = accountOrServer;

  const [ancestorPostIds, setAncestorPostIds] = useState([] as string[]);
  const ancestorPosts = useAppSelector(selectReplyAncestors(ancestorPostIds, server));
  useEffect(() => {
    if (subjectPost) {
      if (subjectPost.replyToPostId) {
        setAncestorPostIds([subjectPost.replyToPostId]);
      } else if (ancestorPostIds.length > 0) {
        setAncestorPostIds([]);
      }
    }
  }, [subjectPost?.id, subjectPost?.serverHost]);


  const debouncedAccountOrServer = useDebouncedAccountOrServer(accountOrServer);
  useEffect(() => {
    for (const idx in ancestorPostIds) {
      const postId = ancestorPostIds[idx]!;
      const post = ancestorPosts[idx];

      if (!post) {
        dispatch(loadPost({ ...accountOrServer, id: postId }));
      }
    }

  }, [ancestorPostIds, debouncedAccountOrServer]);

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
  // console.log('PostDetailsScreen', { interactionType })
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
      if (!subjectPost && !loadingPost && !failedToLoadPost) {
        setLoadingPost(true);
        // console.log('loadPost', postId!)
        requestAnimationFrame(() =>
          dispatch(loadPost({ ...accountOrServer, id: serverPostId! }))
            .then(() => setLoadingPost(false)));
      } else if (subjectPost && loadingPost) {
        setLoadingPost(false);
      }
    }
  }, [serverPostId, server, subjectPost, loadingPost, failedToLoadPost]);

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
    if (interactionType === 'post') {
      setShowContext(false);
    }
  }, [interactionType, pathPostId]);
  useEffect(() => {
    let title = undefined as string | undefined;
    if (subjectPost) {
      if (subjectPostTitle && subjectPostTitle.length > 0) {
        title = subjectPostTitle;
      } else {
        title = `Post Details (#${subjectPost.id})`;
      }
    } else if (failedToLoadPost) {
      title = 'Post Not Found';
    } else {
      // This doesn't really work. The idea is, when the BE server set the title
      // on the page, we don't want to display "Loading Post...". But we'd like
      // it to behave well both with and without the BE server's magic!
      if (!document.title.includes(serverName)) {
        title = 'Loading Post...';
      }
    }

    if (title === undefined) return;

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
                    {subjectPostTitle ?? (failedToLoadPost ? 'Post Not Found' : 'Loading...')}
                  </Paragraph>
                  : <Heading size='$4' color={interactionType == 'post' ? navTextColor : undefined}>{subjectPost?.context === PostContext.REPLY ? 'Comments' : 'Post'}</Heading>}
              </Button>
            </Tooltip.Trigger>
            <Tooltip.Content>
              <Heading size='$2'>{subjectPost?.context === PostContext.REPLY ? showContext ? 'Comment Context' : 'Comment Details' : 'Post Details'}</Heading>
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
        accountOrServer.account || interactionType !== 'post' ?
          <AccountOrServerContextProvider value={accountOrServer}>
            <ReplyArea replyingToPath={replyPostIdPath}
              onStopReplying={() => serverPostId && setReplyPostIdPath([serverPostId])}
              hidden={!showReplyArea} />
          </AccountOrServerContextProvider>
          : undefined}
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
            <YStack f={1} jc="center" ai="center" gap='$2' w='100%' maw={800}>
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

                      federatedAncestorPostIds.length > 0
                        ? <div key='show-hide-context' style={{ paddingLeft: 15, paddingRight: 15 }}>
                          <Button onPress={() => setShowContext(!showContext)} mx='auto' px='$2' py='$1'
                            animation='slow' mt={showContext ? '$3' : undefined}
                            w='100%'
                            icon={<ZStack w='$2' h='$2'>
                              <XStack m='auto' animation='standard' o={!showContext ? 1 : 0} transform={[{ rotate: !showContext ? '0deg' : '-180deg' }]}><CircleEllipsis transform={[{ rotate: '90deg' }]} /></XStack>
                              <XStack m='auto' animation='standard' o={showContext ? 1 : 0} transform={[{ rotate: showContext ? '0deg' : '180deg' }]}><ChevronUp /></XStack>
                            </ZStack>}
                          // backgroundColor={navColor} color={navTextColor} hoverStyle={{ backgroundColor: navColor }}
                          >
                            <ZStack w='$15' h='$2'>
                              <XStack m='auto' animation='standard' o={!showContext ? 1 : 0}>
                                <Heading size='$4'>Show Context</Heading>
                              </XStack>
                              <XStack m='auto' animation='standard' o={showContext ? 1 : 0}>
                                <Heading size='$4'>Hide Context</Heading>
                              </XStack>
                            </ZStack>
                          </Button>
                        </div>
                        : undefined,
                      <div key='subjectPost'>
                        <XStack w='100%' px={mediaQuery.gtXxs ? '$3' : 0}
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
