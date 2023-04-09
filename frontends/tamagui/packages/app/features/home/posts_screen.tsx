import { Post, PostListingType } from '@jonline/api';
import { dismissScrollPreserver, Heading, isClient, needsScrollPreservers, Spinner, useWindowDimensions, YStack } from '@jonline/ui';
import { getPostsPage, loadPostsPage, RootState, useCredentialDispatch, useServerTheme, useTypedSelector } from 'app/store';
import React, { useEffect, useState } from 'react';
import { FlatList } from 'react-native';
import StickyBox from "react-sticky-box";
import { StickyCreateButton } from '../post/create_post_sheet';
import PostCard from '../post/post_card';
import { TabsNavigation } from '../tabs/tabs_navigation';
import { AppSection } from '../tabs/features_navigation';

export function PostsScreen() {
  const serversState = useTypedSelector((state: RootState) => state.servers);
  const postsState = useTypedSelector((state: RootState) => state.posts);
  const app = useTypedSelector((state: RootState) => state.app);

  const posts: Post[] = useTypedSelector((state: RootState) =>
    getPostsPage(state.posts, PostListingType.PUBLIC_POSTS, 0));
  // const posts = useTypedSelector((state: RootState) => selectAllPosts(state.posts));
  // const posts: Post[] = [];
  const [showScrollPreserver, setShowScrollPreserver] = useState(needsScrollPreservers());
  let { dispatch, accountOrServer } = useCredentialDispatch();
  const { server, primaryColor, navColor, navTextColor } = useServerTheme();
  // let primaryColorInt = serversState.server?.serverConfiguration?.serverInfo?.colors?.primary;
  // let primaryColor = `#${(primaryColorInt)?.toString(16).slice(-6) || '424242'}`;
  // let navColorInt = serversState.server?.serverConfiguration?.serverInfo?.colors?.navigation;
  // let navColor = `#${(navColorInt)?.toString(16).slice(-6) || 'fff'}`;
  const dimensions = useWindowDimensions();

  const [loadingPosts, setLoadingPosts] = useState(false);
  useEffect(() => {
    if (postsState.baseStatus == 'unloaded' && !loadingPosts) {
      if (!accountOrServer.server) return;

      console.log("Loading posts...");
      setLoadingPosts(true);
      reloadPosts();
    } else if (postsState.baseStatus == 'loaded' && loadingPosts) {
      setLoadingPosts(false);
      dismissScrollPreserver(setShowScrollPreserver);
    }
    document.title = server?.serverConfiguration?.serverInfo?.name || 'Jonline';
  });

  function reloadPosts() {
    // setTimeout(() => 
    dispatch(loadPostsPage({ ...accountOrServer }))
    // , 1);
  }

  function onHomePressed() {
    if (isClient && window.scrollY > 0) {
      window.scrollTo({ top: 0, behavior: 'smooth' });
    } else {
      reloadPosts();
    }
  }

  return (
    <TabsNavigation appSection={AppSection.POSTS}>
      {postsState.baseStatus == 'loading' ? <StickyBox style={{ zIndex: 10, height: 0 }}>
        <YStack space="$1" opacity={0.92}>
          <Spinner size='large' color={navColor} scale={2}
            top={dimensions.height / 2 - 50}
          />
        </YStack>
      </StickyBox> : undefined}
      <YStack f={1} w='100%' jc="center" ai="center" p="$0" paddingHorizontal='$3' mt='$3' maw={800} space>
        {posts.length == 0
          ? postsState.baseStatus != 'loading' && postsState.baseStatus != 'unloaded'
            ? <YStack width='100%' maw={600} jc="center" ai="center">
              <Heading size='$5' mb='$3'>No posts found.</Heading>
              <Heading size='$3' ta='center'>The posts you're looking for may either not exist, not be visible to you, or be hidden by moderators.</Heading>
            </YStack>
            : undefined
          : <FlatList data={posts}
            // onRefresh={reloadPosts}
            // refreshing={postsState.status == 'loading'}
            // Allow easy restoring of scroll position
            ListFooterComponent={showScrollPreserver ? <YStack h={100000} /> : undefined}
            keyExtractor={(post) => post.id}
            renderItem={({ item: post }) => {
              return <PostCard post={post} isPreview />;
            }} />}
      </YStack>
      <StickyCreateButton />
    </TabsNavigation>
  )
}
