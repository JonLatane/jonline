import { GetPostsRequest, Heading, Paragraph, XStack, YStack } from '@jonline/ui'
import { Post } from '@jonline/ui/src'
import { clearPostAlerts, loadPost, loadPostReplies, RootState, selectGroupById, selectPostById, loadPostsPage, useCredentialDispatch, useTypedSelector } from 'app/store'
import React, { useState, useEffect } from 'react'
import { FlatList, } from 'react-native'
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
  const [loadingPost, setLoadingPost] = useState(false);
  const [loadedReplies, setLoadedReplies] = useState(false);
  const [collapsedReplies, setCollapsedReplies] = useState(new Set<string>());

  const isSafari = /^((?!chrome|android).)*safari/i.test(navigator.userAgent);
  const [showScrollPreserver, setShowScrollPreserver] = useState(isSafari);
  useEffect(() => {
    if (postId) {
      if ((!post || postsState.status == 'unloaded') && postsState.status != 'loading' && !loadingPost) {
        setLoadingPost(true);
        // useEffect(() => {
        console.log('loadPost', postId!)
        setTimeout(() =>
          dispatch(loadPost({ ...accountOrServer, id: postId! })));
        // });
      } else if (post && loadingPost) {
        setLoadingPost(false);
      }
      if (post && postsState.status != 'loading' && post.replyCount > 0 &&
        post.replies.length == 0 && !loadedReplies) {
        setLoadedReplies(true);
        console.log('loadReplies', post.id, post.replyCount, post.replies.length, loadedReplies);
        setTimeout(() =>
          dispatch(loadPostReplies({ ...accountOrServer, postIdPath: [postId!] })), 1);
      } else if (!post && loadedReplies) {
        setLoadedReplies(false);
      }
      if (post && (post.replyCount == 0 || post.replies.length > 0) && showScrollPreserver) {
        setTimeout(() => setShowScrollPreserver(false), 1500);
      }
    }
  });

  function toggleCollapseReplies(postId: string) {
    if (collapsedReplies.has(postId)) {
      collapsedReplies.delete(postId);
    } else {
      collapsedReplies.add(postId);
    }
    setCollapsedReplies(new Set(collapsedReplies));
  }

  type FlattenedReply = {
    postIdPath: string[];
    post: Post;
  }

  const flattenedReplies: FlattenedReply[] = [];
  function flattenReplies(post: Post, postIdPath: string[], includeSelf: boolean = false) {
    if (includeSelf) {
      flattenedReplies.push({ post, postIdPath });
    }
    if (collapsedReplies.has(post.id)) return;

    for (const reply of post.replies) {
      flattenReplies(reply, postIdPath.concat(reply.id), true);
    }
  }
  if (post) {
    flattenReplies(post, [post.id]);
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

              return <XStack key={`reply-${item.post.id}`}
                animation="bouncy"
                opacity={1}
                scale={1}
                y={0}
                enterStyle={{
                  // scale: 1.5,
                  y: -50,
                  opacity: 0,
                }}
              // exitStyle={{
              //   // scale: 1.5,
              //   y: -50,
              //   opacity: 0,
              // }}
              >
                {item.postIdPath.slice(1).map(() => {
                  stripeColor = (stripeColor == primaryColor) ? navColor : primaryColor;
                  return <YStack w={7} bg={stripeColor} />
                })}
                <PostCard post={item.post} replyPostIdPath={item.postIdPath}
                  collapseReplies={collapsedReplies.has(item.post.id)}
                  toggleCollapseReplies={() => toggleCollapseReplies(item.post.id)} />
              </XStack>
            }}
            ListFooterComponent={showScrollPreserver ? <YStack h={100000} /> : <YStack h={150} />}
          />
        </XStack>
      </YStack>
    </TabsNavigation>
  )
}
