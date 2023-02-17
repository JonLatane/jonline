import { Anchor, Button, H1, Heading, Paragraph, XStack, YStack } from '@jonline/ui';
import { GetPostsRequest, isClient, Spinner, useWindowDimensions, ZStack } from '@jonline/ui/src';
import { dismissScrollPreserver, needsScrollPreservers } from '@jonline/ui/src/global';
import { RootState, selectAllPosts, setShowIntro, loadPostsPage, useCredentialDispatch, useTypedSelector } from 'app/store';
import React, { useState, useEffect } from 'react';
import { FlatList, Linking, Platform } from 'react-native';
import PostCard from '../post/post_card';
import { TabsNavigation } from '../tabs/tabs_navigation';
import StickyBox from "react-sticky-box";

export function HomeScreen() {
  const [showTechDetails, setShowTechDetails] = useState(false);
  const serversState = useTypedSelector((state: RootState) => state.servers);
  const postsState = useTypedSelector((state: RootState) => state.posts);
  const app = useTypedSelector((state: RootState) => state.app);
  const posts = useTypedSelector((state: RootState) => selectAllPosts(state.posts));
  const [showScrollPreserver, setShowScrollPreserver] = useState(needsScrollPreservers());
  let { dispatch, accountOrServer } = useCredentialDispatch();
  let primaryColorInt = serversState.server?.serverConfiguration?.serverInfo?.colors?.primary;
  let primaryColor = `#${(primaryColorInt)?.toString(16).slice(-6) || '424242'}`;
  let navColorInt = serversState.server?.serverConfiguration?.serverInfo?.colors?.navigation;
  let navColor = `#${(navColorInt)?.toString(16).slice(-6) || 'fff'}`;
  const dimensions = useWindowDimensions();

  const [loadingPosts, setLoadingPosts] = useState(false);
  useEffect(() => {
    if (postsState.baseStatus == 'unloaded' && !loadingPosts) {
      if (!accountOrServer.server) return;
      setLoadingPosts(true);
      reloadPosts();
    } else if (postsState.baseStatus == 'loaded') {
      setLoadingPosts(false);
      dismissScrollPreserver(setShowScrollPreserver);
    }
  });

  function reloadPosts() {
    setTimeout(() => dispatch(loadPostsPage({ ...accountOrServer })), 1);
  }

  function onHomePressed() {
    if (isClient && window.scrollY > 0) {
      window.scrollTo({ top: 0, behavior: 'smooth' });
    } else {
      reloadPosts();
    }
  }

  function hideIntro() {
    dispatch(setShowIntro(false));
  }

  return (
    <TabsNavigation customHomeAction={onHomePressed}>
      {postsState.baseStatus == 'loading' ? <StickyBox style={{ zIndex: 10, height: 0 }}>
        <YStack space="$1" opacity={0.92}>
          <Spinner size='large' color={navColor} scale={2}
            top={dimensions.height / 2 - 50}
          />
        </YStack>
      </StickyBox> : undefined}
      {/* <ZStack f={1} w='100%' jc="center" ai="center" p="$0"> */}
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

      {/* </ZStack> */}
    </TabsNavigation>
  )
}
