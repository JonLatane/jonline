import { Paragraph, YStack } from '@jonline/ui'
import { Anchor, Card, Group, GroupPost, Heading, Spinner, useWindowDimensions, XStack } from '@jonline/ui/src'
import { dismissScrollPreserver, needsScrollPreservers } from '@jonline/ui/src/global'
import { loadPost, RootState, selectGroupById, selectPostById, loadGroupPosts, useCredentialDispatch, useServerTheme, useTypedSelector } from 'app/store'
import React, { useState, useEffect } from 'react'
import ReactMarkdown from 'react-markdown'
import { FlatList } from 'react-native'
import { createParam } from 'solito'
import { useLink } from 'solito/link'
import PostCard from './post_card'
import { TabsNavigation } from '../tabs/tabs_navigation'
import StickyBox from "react-sticky-box";

export type AsyncPostCardProps = {
  postId: string;
}
export function AsyncPostCard({ postId }: AsyncPostCardProps) {
  const { dispatch, accountOrServer } = useCredentialDispatch();
  const post = useTypedSelector((state: RootState) => selectPostById(state.posts, postId!));
  const postsState = useTypedSelector((state: RootState) => state.posts);
  const { primaryColor } = useServerTheme();
  const [loadingPost, setLoadingPost] = useState(false);
  useEffect(() => {
    if (!post && !loadingPost) {
      setLoadingPost(true);
      // setTimeout(() =>
      //   dispatch(loadPost({ ...accountOrServer, id: postId! })), 1);
    } else if (postsState.status == 'loaded') {
      // setLoadingPost(false);
    }
  });
  return post ? <PostCard post={post} isPreview /> : <>
    <Card w='100%' h={200}
      theme="dark" elevate size="$4" bordered
      margin='$0'
      // marginBottom={replyPostIdPath ? '$0' : '$3'}
      mb='$3'
      mt='$3'
      // marginTop={replyPostIdPath ? '$0' : '$3'}
      padding='$0'
      f={1}
      // f={isPreview ? undefined : 1}
      animation="bouncy"
      pressStyle={{ scale: 0.990 }}
    // ref={ref!}
    >
      <Spinner f={1} size='large' color={primaryColor} mt={50} />
    </Card>
  </>;
}
