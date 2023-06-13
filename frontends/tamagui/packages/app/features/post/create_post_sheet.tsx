import { Group, Post } from '@jonline/api';
import { createGroupPost, createPost, useCredentialDispatch } from 'app/store';
import React from 'react';
import { BaseCreatePostSheet } from './base_create_post_sheet';
import PostCard from './post_card';

export type CreatePostSheetProps = {
  selectedGroup?: Group;
};

export function CreatePostSheet({ selectedGroup }: CreatePostSheetProps) {
  const { dispatch, accountOrServer } = useCredentialDispatch();

  function doCreate(
    post: Post,
    group: Group | undefined,
    resetPost: () => void,
    onComplete: () => void
  ) {
    dispatch(createPost({ ...post, ...accountOrServer })).then((action) => {
      if (action.type == createPost.fulfilled.type) {
        const post = action.payload as Post;
        if (group) {
          dispatch(createGroupPost({ groupId: group.id, postId: (post).id, ...accountOrServer }))
            .then(resetPost);
        } else {
          resetPost();
        }
      } else {
        onComplete();
      }
    });
  }

  return <BaseCreatePostSheet
    selectedGroup={selectedGroup}
    doCreate={doCreate}
    preview={(post) => <PostCard post={post} />}
    feedPreview={(post) => <PostCard post={post} isPreview />}
  />;
}
