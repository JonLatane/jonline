import { Card, Spinner } from '@jonline/ui'
import { RootState, selectPostById, useCredentialDispatch, useServerTheme, useTypedSelector } from 'app/store'
import React, { useEffect, useState } from 'react'
import PostCard from './post_card'

export type AsyncPostCardProps = {
  postId: string;
}
export function AsyncPostCard({ postId }: AsyncPostCardProps) {
  const { dispatch, accountOrServer } = useCredentialDispatch();
  const post = useTypedSelector((state: RootState) => selectPostById(state.posts, postId!));
  const postsState = useTypedSelector((state: RootState) => state.posts);
  const { primaryColor } = useServerTheme();
  const [loadingPost, setLoadingPost] = useState(false);
  const [loadingParentPost, setLoadingParentPost] = useState(false);
  const parentPost = useTypedSelector((state: RootState) => post?.replyToPostId ? selectPostById(state.posts, post?.replyToPostId) : undefined);
  useEffect(() => {
    if (!post && !loadingPost) {
      setLoadingPost(true);
      // setTimeout(() =>
      //   dispatch(loadPost({ ...accountOrServer, id: postId! })), 1);
    } else if (postsState.status == 'loaded') {
      // setLoadingPost(false);
    }

    // if (post?.replyToPostId && !parentPost && !loadingParentPost) {
    //   setLoadingParentPost(true);
    //   setTimeout(() =>
    //     dispatch(loadPost({ ...accountOrServer, id: post!.replyToPostId! })), 1);
    // } else if (postsState.status == 'loaded') {
    //   setLoadingParentPost(false);
    // }
  });
  return post ? <PostCard post={post} previewParent={parentPost} isPreview /> : <>
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
      animation='standard'
      pressStyle={{ scale: 0.990 }}
    // ref={ref!}
    >
      <Spinner f={1} size='large' color={primaryColor} mt={50} />
    </Card>
  </>;
}
