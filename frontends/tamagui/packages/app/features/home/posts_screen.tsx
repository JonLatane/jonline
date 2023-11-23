import { PostListingType } from '@jonline/api';
import { Heading, Spinner, YStack, dismissScrollPreserver, needsScrollPreservers, useWindowDimensions } from '@jonline/ui';
import { useGroupPostPages, usePostPages } from 'app/hooks/post_pagination_hooks';
import { RootState, useServerTheme, useTypedSelector } from 'app/store';
import { setDocumentTitle } from 'app/utils/set_title';
import React, { useEffect, useState } from 'react';
import StickyBox from "react-sticky-box";
import PostCard from '../post/post_card';
import { AppSection } from '../tabs/features_navigation';
import { TabsNavigation } from '../tabs/tabs_navigation';
import { HomeScreenProps } from './home_screen';
import { PaginationIndicator } from './pagination_indicator';
import { StickyCreateButton } from './sticky_create_button';

export function PostsScreen() {
  return <BasePostsScreen />;
}

export const BasePostsScreen: React.FC<HomeScreenProps> = ({ selectedGroup }: HomeScreenProps) => {
  const postsState = useTypedSelector((state: RootState) => state.posts);

  const [showScrollPreserver, setShowScrollPreserver] = useState(needsScrollPreservers());
  const { server, primaryColor, navColor, navTextColor } = useServerTheme();

  const dimensions = useWindowDimensions();

  useEffect(() => {
    const serverName = server?.serverConfiguration?.serverInfo?.name || '...';
    const title = selectedGroup ? `${selectedGroup.name} | ${serverName}` : serverName;
    setDocumentTitle(`Posts | ${title}`);
  });

  const [currentPage, setCurrentPage] = useState(0);
  const { posts, loadingPosts, reloadPosts, hasMorePages, firstPageLoaded } = selectedGroup
    ? useGroupPostPages(selectedGroup.id, currentPage)
    : usePostPages(PostListingType.ALL_ACCESSIBLE_POSTS, currentPage);

  useEffect(() => {
    if (firstPageLoaded) {
      dismissScrollPreserver(setShowScrollPreserver);
    }
  }, [firstPageLoaded]);

  console.log(`Current page: ${currentPage}, Total Posts: ${posts.length}`);

  return (
    <TabsNavigation
      appSection={AppSection.POSTS}
      selectedGroup={selectedGroup}
      groupPageForwarder={(group) => `/g/${group.shortname}/posts`}
    >
      {postsState.baseStatus == 'loading' ? <StickyBox style={{ zIndex: 10, height: 0 }}>
        <YStack space="$1" opacity={0.92}>
          <Spinner size='large' color={navColor} scale={2}
            top={dimensions.height / 2 - 50}
          />
        </YStack>
      </StickyBox> : undefined}
      <YStack f={1} w='100%' jc="center" ai="center" p="$0" paddingHorizontal='$3' mt='$3' maw={800} space>
        {firstPageLoaded
          ? posts.length == 0
            ? <YStack width='100%' maw={600} jc="center" ai="center">
              <Heading size='$5' mb='$3'>No posts found.</Heading>
              <Heading size='$3' ta='center'>The posts you're looking for may either not exist, not be visible to you, or be hidden by moderators.</Heading>
            </YStack>
            : <YStack w='100%'>
              {posts.map((post) => {
                return <PostCard key={`post-${post.id}`} post={post} isPreview />;
              })}
              <PaginationIndicator page={currentPage} loadingPage={loadingPosts || postsState.baseStatus == 'loading'}
                hasNextPage={hasMorePages}
                loadNextPage={() => setCurrentPage(currentPage + 1)}
              />
            </YStack>
          : undefined
        }
      </YStack>
      <StickyCreateButton selectedGroup={selectedGroup} showPosts />
    </TabsNavigation>
  )
}
