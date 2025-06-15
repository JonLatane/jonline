import { Group, Permission, Post } from '@jonline/api';
import { useCreationDispatch, useCredentialDispatch } from 'app/hooks';
import { FederatedGroup, FederatedPost, createGroupPost, createPost } from 'app/store';
import React, { useCallback } from 'react';
import { BaseCreatePostSheet } from './base_create_post_sheet';
import PostCard from './post_card';
import { AccountOrServerContext, AccountOrServerContextProvider } from 'app/contexts';

export type CreatePostSheetProps = {
  selectedGroup?: FederatedGroup;
  button?: (onPress: () => void) => React.JSX.Element;
};

export function CreatePostSheet({ selectedGroup, button }: CreatePostSheetProps) {
  const { dispatch, accountOrServer } = useCreationDispatch();

  const canPublishLocally = accountOrServer.account?.user?.permissions?.includes(Permission.PUBLISH_POSTS_LOCALLY);
  const canPublishGlobally = accountOrServer.account?.user?.permissions?.includes(Permission.PUBLISH_POSTS_GLOBALLY);

  const doCreate = useCallback((
    post: Post,
    group: Group | undefined,
    resetPost: () => void,
    onComplete: () => void,
    onErrored: (error: any) => void,
  ) => {
    dispatch(createPost({ ...post, ...accountOrServer })).then((action) => {
      if (action.type == createPost.fulfilled.type) {
        const post = action.payload as Post;
        if (group) {
          dispatch(createGroupPost({ groupId: group.id, postId: (post).id, ...accountOrServer }))
            .then(resetPost);
        } else {
          resetPost();
        }
        onComplete();
      } else {
        if ('error' in action) {
          onErrored(action.error);
        } else {
          onErrored('Error creating Post');
        }
      }
    });
  }, [accountOrServer]);

  const preview = useCallback((post: Post) => <AccountOrServerContextProvider value={accountOrServer}>
    <PostCard post={post} />
  </AccountOrServerContextProvider>, [accountOrServer]);

  const feedPreview = useCallback((post: Post) => <AccountOrServerContextProvider value={accountOrServer}>
    <PostCard post={post} isPreview />
  </AccountOrServerContextProvider>, [accountOrServer]);

  return <BaseCreatePostSheet
    requiredPermissions={[Permission.CREATE_POSTS]}
    {...{ canPublishGlobally, canPublishLocally, selectedGroup, doCreate, button, preview, feedPreview }}
  />;
}
