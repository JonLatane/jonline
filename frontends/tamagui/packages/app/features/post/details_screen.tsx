import { Button, GetPostsRequest, Paragraph, YStack } from '@jonline/ui'
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
  const { dispatch, account_or_server } = useCredentialDispatch();
  const postsState = useTypedSelector((state: RootState) => state.posts);
  const post = useTypedSelector((state: RootState) => selectPostById(state.posts, id!));
  if (postsState.status == 'unloaded') {
    setTimeout(() =>
      dispatch(updatePosts({ ...account_or_server, ...GetPostsRequest.create() })), 5000);
  }
  if (!post && postsState.status != 'loading') {
    setTimeout(() =>
      dispatch(loadPost({ ...account_or_server, id: id! })));
  }

  return (
    <TabsNavigation>
      <YStack f={1} jc="center" ai="center" mt='$3' marginHorizontal='$3' space maw={800}>
        {!post ? <Paragraph ta="center" fow="800">{`Loading...`}</Paragraph> : undefined}
        {post ? <PostCard post={post!}/> : undefined}
        {/* <Button {...linkProps} icon={ChevronLeft}>
          Go Home
        </Button> */}
      </YStack>
    </TabsNavigation>
  )
}
