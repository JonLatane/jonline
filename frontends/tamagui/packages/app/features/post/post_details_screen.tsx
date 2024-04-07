import { AnimatePresence, Button, Heading, Paragraph, ScrollView, Spinner, Tooltip, XStack, YStack, standardHorizontalAnimation, useMedia } from '@jonline/ui'
import { useAppDispatch, useCredentialDispatch, useFederatedDispatch, useHash, useLocalConfiguration, useCurrentServer, } from 'app/hooks'
import { RootState, getServerTheme, loadPost, parseFederatedId, selectGroupById, selectPostById, setDiscussionChatUI, useRootSelector, useServerTheme } from 'app/store'
import { setDocumentTitle, themedButtonBackground } from 'app/utils'
import React, { useEffect, useState } from 'react'
import { createParam } from 'solito'
import { AppSection } from '../navigation/features_navigation'
import { TabsNavigation } from '../navigation/tabs_navigation'
import { ConversationContextProvider, useStatefulConversationContext } from './conversation_context'
import { ConversationManager, scrollToCommentsBottom } from './conversation_manager'
import PostCard from './post_card'
import { ReplyArea } from './reply_area'
import { federateId, getFederated } from '../../store/federation';
import { AccountOrServerContextProvider } from 'app/contexts'
import { ListEnd } from '@tamagui/lucide-icons'

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

  const [shortname] = useParam('shortname');
  const [interactionType, setInteractionType] = usePostInteractionType();

  const { primaryColor, primaryTextColor, navColor, navTextColor, navAnchorColor } = getServerTheme(accountOrServer.server);
  const app = useLocalConfiguration();
  const groupId = useRootSelector((state: RootState) =>
    shortname ? state.groups.shortnameIds[shortname!] : undefined);
  const group = useRootSelector((state: RootState) =>
    groupId ? selectGroupById(state.groups, groupId) : undefined);
  // const { dispatch, accountOrServer } = useCredentialDispatch();
  const postsState = useRootSelector((state: RootState) => state.posts);
  const federatedPostId = federateId(serverPostId!, server);
  const subjectPost = useRootSelector((state: RootState) => selectPostById(state.posts, federatedPostId));
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
  useEffect(() => {
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
    setDocumentTitle(title)
  }, [serverName, subjectPost, failedToLoadPost, shortname, group?.name]);

  // function scrollToBottom() {
  //   window.scrollTo({ top: document.body.scrollHeight, behavior: 'smooth' });
  // }
  function scrollToTop() {
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }
  const chatUI = app?.discussionChatUI;

  return (
    <TabsNavigation appSection={AppSection.POSTS} selectedGroup={group}
      primaryEntity={subjectPost ?? { serverHost: serverHost ?? currentServer?.host }}
      topChrome={
        <XStack w='100%' maw={800} mx='auto' mt='$1' ai='center'>
          <Tooltip placement="bottom">
            <Tooltip.Trigger>
              <Button {...themedButtonBackground(interactionType === 'post' ? navColor : undefined)}
                transparent={interactionType !== 'post'} mr='$2'
                onPress={() => {
                  setInteractionType('post');
                  scrollToTop();
                }}>
                {mediaQuery.gtSm
                  ? <Paragraph size='$1' color={interactionType == 'post' ? navTextColor : undefined} fontWeight='bold' my='auto' animation='standard' o={0.5} f={1}>
                    {subjectPost?.title || 'Loading...'}
                  </Paragraph>
                  : <Heading size='$4' color={interactionType == 'post' ? navTextColor : undefined}>Post</Heading>}
              </Button>
            </Tooltip.Trigger>
            <Tooltip.Content>
              <Heading size='$2'>Post Details</Heading>
            </Tooltip.Content>
          </Tooltip>

          <XStack f={1} />

          <Tooltip placement="bottom">
            <Tooltip.Trigger>
              <Button {...themedButtonBackground(interactionType === 'discussion' ? navColor : undefined)}
                transparent={interactionType !== 'discussion'}
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
                <AnimatePresence>
                  {interactionType === 'post'
                    ? <XStack w='100%' paddingHorizontal='$3'
                      animation='standard' {...standardHorizontalAnimation}>
                      <PostCard key={`post-card-main-${serverPostId}`}
                        post={subjectPost}
                        onEditingChange={editHandler(subjectPost.id)} />
                    </XStack>
                    : undefined}
                </AnimatePresence>
                <ConversationManager post={subjectPost} />
              </ScrollView>


            </YStack>
          </ConversationContextProvider>
        </AccountOrServerContextProvider>
      }
    </TabsNavigation >
  )
}
