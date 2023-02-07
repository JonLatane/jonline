import { GetPostsRequest, Heading, Paragraph, XStack, YStack } from '@jonline/ui'
import { Post } from '@jonline/ui/src'
import { clearPostAlerts, loadPost, loadPostReplies, RootState, selectGroupById, selectPostById, updatePosts, useCredentialDispatch, useTypedSelector } from 'app/store'
import React, { useState } from 'react'
import { FlatList } from 'react-native'
import { createParam } from 'solito'
import { TabsNavigation } from '../tabs/tabs_navigation'
import PostCard from './post_card'

const { useParam } = createParam<{ postId: string, shortname: string | undefined }>()

export function PostDetailsScreen() {
  const [postId] = useParam('postId');
  const [shortname] = useParam('shortname');

  const server = useTypedSelector((state: RootState) => state.servers.server);
  const primaryColorInt = server?.serverConfiguration?.serverInfo?.colors?.primary;
  const primaryColor = `#${(primaryColorInt)?.toString(16).slice(-6) || '424242'}`;
  const navColorInt = server?.serverConfiguration?.serverInfo?.colors?.navigation;
  const navColor = `#${(navColorInt)?.toString(16).slice(-6) || 'FFFFFF'}`;
  const groupId = useTypedSelector((state: RootState) =>
    shortname ? state.groups.shortnameIds[shortname!] : undefined);
  const group = useTypedSelector((state: RootState) =>
    groupId ? selectGroupById(state.groups, groupId) : undefined);
  const { dispatch, accountOrServer } = useCredentialDispatch();
  const postsState = useTypedSelector((state: RootState) => state.posts);
  const post = useTypedSelector((state: RootState) => selectPostById(state.posts, postId!));
  const [loadedPost, setLoadedPost] = useState(false);
  if (!post && postsState.status != 'loading' && !loadedPost) {
    setLoadedPost(true);
    console.log('loadPost', postId!)
    setTimeout(() =>
      dispatch(loadPost({ ...accountOrServer, id: postId! })));
  }
  const [loadedReplies, setLoadedReplies] = useState(false);
  if (post && postsState.status != 'loading' && post.replyCount > 0 &&
    post.replies.length == 0 && !loadedReplies) {
    setLoadedReplies(true);
    console.log('loadReplies', post.id, post.replyCount, post.replies.length, loadedReplies);
    setTimeout(() =>
      dispatch(loadPostReplies({ ...accountOrServer, postIdPath: [postId!] })), 1);
  } else if (!post && loadedReplies) {
    // setLoadedReplies(false);
  }

  type FlattenedReply = {
    postIdPath: string[];
    post: Post;
  }
  // const [flattenedReplies, setFlattenedReplies] = useState<FlattenedReply[] | undefined>(undefined);
  // const [updatingReplies, setUpdatingReplies] = useState(false);
  // if (postsState.successMessage == 'Replies loaded.' && !updatingReplies) {
  //   setTimeout(() => dispatch(clearPostAlerts!()), 1);
  //   setUpdatingReplies(true);
  //   setFlattenedReplies(undefined);
  // } else if (postsState.successMessage != 'Replies loaded.' && updatingReplies) {
  //   setUpdatingReplies(false);
  // }
  // if (postsState.status != 'loading' && !flattenedReplies && post && post.replies.length > 0 && !updatingReplies) {
    // debugger;
    const flattenedReplies: FlattenedReply[] = [];
    function flattenReplies(post: Post, postIdPath: string[], includeSelf: boolean = false) {
      if (includeSelf) {
        flattenedReplies.push({ post, postIdPath });
      }
      for (const reply of post.replies) {
        flattenReplies(reply, postIdPath.concat(reply.id), true);
      }
    }
    if(post) {
    flattenReplies(post, [post.id]);
    }
    // debugger;
    // setFlattenedReplies(_flattenedReplies);
  // }

  const [loadedPosts, setLoadedPosts] = useState(false);
  if (postsState.status == 'unloaded' && !loadedPosts) {
    setLoadedPosts(true);
    setTimeout(() =>
      dispatch(updatePosts({ ...accountOrServer, ...GetPostsRequest.create() })), 5000);
  }

  if (postsState.status == 'unloaded') {
    // setLoadedPost(false);
    // setLoadedPosts(false);
    // setLoadedReplies(false);
    // setFlattenedReplies(undefined);
  }

  return (
    <TabsNavigation selectedGroup={group}>
      <YStack f={1} jc="center" ai="center" mt='$3' marginHorizontal='$3' space w='100%' maw={800}>
        {!post ? <Paragraph ta="center" fow="800">{`Loading...`}</Paragraph> : undefined}
        <XStack w='100%' paddingHorizontal='$3'>
          {post ? <PostCard post={post!} /> : undefined}
        </XStack>
        <Heading size='$4'>Discussion</Heading>
        <XStack w='100%'>
          <FlatList data={flattenedReplies}
            renderItem={({ item }) => {
              let stripeColor = navColor;
              return <XStack>
                {item.postIdPath.slice(1).map(() => {
                  stripeColor = (stripeColor == primaryColor) ? navColor : primaryColor;
                  return <YStack w={7} bg={stripeColor} />
                })}
                <PostCard post={item.post} replyPostIdPath={item.postIdPath} />
              </XStack>
            }}
          />
        </XStack>
        {/* <Button {...linkProps} icon={ChevronLeft}>
          Go Home
        </Button> */}
      </YStack>
    </TabsNavigation>
  )
}
