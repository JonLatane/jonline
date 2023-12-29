import { PostListingType } from '@jonline/api';
import { Heading, Spinner, YStack, dismissScrollPreserver, needsScrollPreservers, useWindowDimensions } from '@jonline/ui';
import { useCurrentAndPinnedServers, usePaginatedRendering } from 'app/hooks';
import { useGroupPostPages, usePostPages, useServerPostPages } from 'app/hooks/pagination/post_pagination_hooks';
import { RootState, federatedId, useRootSelector, useServerTheme } from 'app/store';
import { setDocumentTitle } from 'app/utils';
import React, { useEffect, useState } from 'react';
import StickyBox from "react-sticky-box";
import { AppSection } from '../navigation/features_navigation';
import { TabsNavigation } from '../navigation/tabs_navigation';
import PostCard from '../post/post_card';
import { HomeScreenProps } from './home_screen';
import { PaginationIndicator } from './pagination_indicator';
import { StickyCreateButton } from './sticky_create_button';

export function PostsScreen() {
  return <BasePostsScreen />;
}

export const BasePostsScreen: React.FC<HomeScreenProps> = ({ selectedGroup }: HomeScreenProps) => {
  // const servers = useCurrentAndPinnedServers();
  // const postsState = useRootSelector((state: RootState) => state.posts);

  const [showScrollPreserver, setShowScrollPreserver] = useState(needsScrollPreservers());
  const { server, primaryColor, navColor, navTextColor } = useServerTheme();

  const dimensions = useWindowDimensions();

  // const [loadingPosts, setLoadingPosts] = useState(false);

  useEffect(() => {
    const serverName = server?.serverConfiguration?.serverInfo?.name || '...';
    const title = selectedGroup ? `${selectedGroup.name} | ${serverName}` : serverName;
    setDocumentTitle(`Posts | ${title}`);
  });

  const { results: allPosts, loading: loadingPosts, reload: reloadPosts, hasMorePages, firstPageLoaded } =
    usePostPages(PostListingType.ALL_ACCESSIBLE_POSTS, selectedGroup);

  const pagination = usePaginatedRendering(allPosts, 10);
  const paginatedPosts = pagination.results;

  // console.log('mainPostPages', loadingPosts, mainPostPages);

  useEffect(() => {
    if (firstPageLoaded) {
      dismissScrollPreserver(setShowScrollPreserver);
    }
  }, [firstPageLoaded]);

  // console.log(`Current page: ${currentPage}, Total Posts: ${posts.length}`);

  return (
    <TabsNavigation
      appSection={AppSection.POSTS}
      selectedGroup={selectedGroup}
      groupPageForwarder={(groupIdentifier) => `/g/${groupIdentifier}/posts`}
      withServerPinning
    >
      {loadingPosts ? <StickyBox style={{ zIndex: 10, height: 0 }}>
        <YStack space="$1" opacity={0.92}>
          <Spinner size='large' color={navColor} scale={2}
            top={dimensions.height / 2 - 50}
          />
        </YStack>
      </StickyBox> : undefined}
      <YStack f={1} w='100%' jc="center" ai="center" py="$2" px='$3' mt='$3' maw={800} space>
        {firstPageLoaded
          ? allPosts.length == 0
            ? <YStack width='100%' maw={600} jc="center" ai="center">
              <Heading size='$5' mb='$3'>No posts found.</Heading>
              <Heading size='$3' ta='center'>The posts you're looking for may either not exist, not be visible to you, or be hidden by moderators.</Heading>
            </YStack>
            : <YStack w='100%'>
              {paginatedPosts.map((post) => {
                return <PostCard key={`post-${federatedId(post)}`} post={post} isPreview />;
              })}
              <PaginationIndicator {...pagination}/>
            </YStack>
          : undefined
        }
        {showScrollPreserver ? <YStack h={100000} /> : undefined}
      </YStack>
      <StickyCreateButton selectedGroup={selectedGroup} showPosts />
    </TabsNavigation>
  )
}
