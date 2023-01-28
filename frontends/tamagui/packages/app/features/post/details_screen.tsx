import { Button, GetPostsRequest, Paragraph, XStack, YStack } from '@jonline/ui'
import { ChevronLeft } from '@tamagui/lucide-icons'
import { loadPost, selectPostById, updatePosts } from 'app/store/modules/posts'
import { RootState, useCredentialDispatch, useTypedSelector } from 'app/store/store'
import React from 'react'
import { createParam } from 'solito'
import { useLink } from 'solito/link'
import { TabsNavigation } from '../tabs/tabs_navigation'
import PostCard from './post_card'

const { useParam } = createParam<{ id: string }>()

export function PostDetailsScreen() {
  const [id] = useParam('id')
  const { dispatch, accountOrServer } = useCredentialDispatch();
  const postsState = useTypedSelector((state: RootState) => state.posts);
  const post = useTypedSelector((state: RootState) => selectPostById(state.posts, id!));
  if (postsState.status == 'unloaded') {
    setTimeout(() =>
      dispatch(updatePosts({ ...accountOrServer, ...GetPostsRequest.create() })), 5000);
  }
  if (!post && postsState.status != 'loading') {
    setTimeout(() =>
      dispatch(loadPost({ ...accountOrServer, id: id! })));
  }

  return (
    <TabsNavigation>
      <YStack f={1} jc="center" ai="center" mt='$3' marginHorizontal='$3' space w='100%' maw={800}>
        {!post ? <Paragraph ta="center" fow="800">{`Loading...`}</Paragraph> : undefined}
        <XStack w='100%' paddingHorizontal='$3'>
        {post ? <PostCard post={post!}/> : undefined}
        </XStack>
        {/* <Button {...linkProps} icon={ChevronLeft}>
          Go Home
        </Button> */}
      </YStack>
    </TabsNavigation>
  )
}
