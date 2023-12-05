import { Heading, ScrollView, Spinner, XStack, YStack } from '@jonline/ui'
import { useCredentialDispatch, useLocalConfiguration, } from 'app/hooks'
import { RootState, loadPost, selectGroupById, selectPostById, useRootSelector, useServerTheme } from 'app/store'
import { setDocumentTitle } from 'app/utils'
import React, { useEffect, useState } from 'react'
import { createParam } from 'solito'
import { AppSection } from '../navigation/features_navigation'
import { TabsNavigation } from '../navigation/tabs_navigation'
import { ConversationContextProvider, useStatefulConversationContext } from './conversation_context'
import { ConversationManager } from './conversation_manager'
import PostCard from './post_card'
import { ReplyArea } from './reply_area'

const { useParam } = createParam<{ postId: string, shortname: string | undefined }>()

export function PostDetailsScreen() {
  const [postId] = useParam('postId');
  const [shortname] = useParam('shortname');

  const { server, primaryColor, primaryTextColor, navColor, navTextColor } = useServerTheme();
  const app = useLocalConfiguration();
  const groupId = useRootSelector((state: RootState) =>
    shortname ? state.groups.shortnameIds[shortname!] : undefined);
  const group = useRootSelector((state: RootState) =>
    groupId ? selectGroupById(state.groups, groupId) : undefined);
  const { dispatch, accountOrServer } = useCredentialDispatch();
  const postsState = useRootSelector((state: RootState) => state.posts);
  const subjectPost = useRootSelector((state: RootState) => selectPostById(state.posts, postId!));
  const [loadingPost, setLoadingPost] = useState(false);
  const conversationContext = useStatefulConversationContext();
  const { editingPosts, replyPostIdPath, setReplyPostIdPath, editHandler } = conversationContext;

  // const [showScrollPreserver, setShowScrollPreserver] = useState(needsScrollPreservers());
  // const chatUI = app?.discussionChatUI;
  // const [chatUI, setChatUI] = useState(false);
  const showReplyArea = subjectPost != undefined && editingPosts.length == 0;

  const failedToLoadPost = postId != undefined &&
    postsState.failedPostIds.includes(postId!);

  useEffect(() => {
    if (postId) {
      if ((!subjectPost || postsState.status == 'unloaded') && postsState.status != 'loading' && !loadingPost) {
        setLoadingPost(true);
        // console.log('loadPost', postId!)
        setTimeout(() =>
          dispatch(loadPost({ ...accountOrServer, id: postId! })));
      } else if (subjectPost && loadingPost) {
        setLoadingPost(false);
      }
    }
    const serverName = server?.serverConfiguration?.serverInfo?.name || '...';
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
  });

  return (
    <TabsNavigation appSection={AppSection.POST} selectedGroup={group}>
      {!subjectPost
        ? failedToLoadPost
          ? <>
            <Heading size='$5'>Post not found.</Heading>
            <Heading size='$3' ta='center'>It may either not exist, not be visible to you, or be hidden by moderators.</Heading>
          </>
          : <Spinner size='large' color={navColor} scale={2} />
        :
        <ConversationContextProvider value={conversationContext}>
          <YStack f={1} jc="center" ai="center" mt='$3' space w='100%' maw={800}>
            <ScrollView w='100%'>
              <XStack w='100%' paddingHorizontal='$3'>
                <PostCard key={`post-card-main-${postId}`}
                  post={subjectPost}
                  onEditingChange={editHandler(subjectPost.id)} />
              </XStack>
              <ConversationManager post={subjectPost} />
            </ScrollView>


            <ReplyArea replyingToPath={replyPostIdPath}
              onStopReplying={() => postId && setReplyPostIdPath([postId])}
              hidden={!showReplyArea} />
          </YStack>
        </ConversationContextProvider>
      }
    </TabsNavigation >
  )
}
