import { Post, PostListingType } from '@jonline/api';
import { Heading, Spinner, YStack, dismissScrollPreserver, needsScrollPreservers, useWindowDimensions } from '@jonline/ui';
import { RootState, getPostPages, loadPostsPage, useCredentialDispatch, useServerTheme, useTypedSelector } from 'app/store';
import React, { useEffect, useState } from 'react';
import StickyBox from "react-sticky-box";
import { getHasMorePostPages } from '../../store/modules/posts';
import PostCard from '../post/post_card';
import { AppSection } from '../tabs/features_navigation';
import { TabsNavigation } from '../tabs/tabs_navigation';
import { PaginationIndicator } from './pagination_indicator';
import { StickyCreateButton } from './sticky_create_button';

export function PostsScreen() {
  const postsState = useTypedSelector((state: RootState) => state.posts);

  const [showScrollPreserver, setShowScrollPreserver] = useState(needsScrollPreservers());
  const { server, primaryColor, navColor, navTextColor } = useServerTheme();

  const dimensions = useWindowDimensions();

  useEffect(() => {
    document.title = server?.serverConfiguration?.serverInfo?.name || 'Jonline';
  });

  const [currentPage, setCurrentPage] = useState(0);
  const { posts, loadingPosts, reloadPosts } = usePostPages(
    PostListingType.PUBLIC_POSTS,
    currentPage,
    () => dismissScrollPreserver(setShowScrollPreserver)
  );
  const hasMorePostPages = getHasMorePostPages(postsState, PostListingType.PUBLIC_POSTS, currentPage);
  console.log(`Current page: ${currentPage}, Total Posts: ${posts.length}`);

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
          : <YStack>
            {posts.map((post) => {
              return <PostCard post={post} isPreview />;
            })}
            <PaginationIndicator page={currentPage} loadingPage={loadingPosts || postsState.baseStatus == 'loading'}
              hasNextPage={hasMorePostPages}
              loadNextPage={() => setCurrentPage(currentPage + 1)}
            />
          </YStack>
        }
      </YStack>
      <StickyCreateButton />
    </TabsNavigation>
  )
}

export function usePostPages(listingType: PostListingType, throughPage: number, onLoaded?: () => void) {
  const { dispatch, accountOrServer } = useCredentialDispatch();
  const postsState = useTypedSelector((state: RootState) => state.posts);
  const [loadingPosts, setLoadingPosts] = useState(false);

  const posts: Post[] = useTypedSelector((state: RootState) => getPostPages(state.posts, PostListingType.PUBLIC_POSTS, throughPage));

  useEffect(() => {
    if (postsState.baseStatus == 'unloaded' && !loadingPosts) {
      if (!accountOrServer.server) return;

      console.log("Loading posts...");
      setLoadingPosts(true);
      reloadPosts();
    } else if (postsState.baseStatus == 'loaded' && loadingPosts) {
      setLoadingPosts(false);
      onLoaded?.();
    }
  });

  function reloadPosts() {
    dispatch(loadPostsPage({ ...accountOrServer, listingType }))
  }

  return { posts, loadingPosts, reloadPosts };
}
