import { PostListingType } from '@jonline/api';
import { Heading, Spinner, XStack, YStack, dismissScrollPreserver, needsScrollPreservers, standardAnimation, useWindowDimensions } from '@jonline/ui';
import { usePinnedAccountsAndServers, usePaginatedRendering } from 'app/hooks';
import { useGroupPostPages, usePostPages, useServerPostPages } from 'app/hooks/pagination/post_pagination_hooks';
import { RootState, federatedId, useRootSelector, useServerTheme } from 'app/store';
import { setDocumentTitle } from 'app/utils';
import React, { useEffect, useState } from 'react';
import StickyBox from "react-sticky-box";
import { AppSection } from '../navigation/features_navigation';
import { TabsNavigation } from '../navigation/tabs_navigation';
import PostCard from '../post/post_card';
import { HomeScreenProps } from './home_screen';
import { PaginationIndicator, PaginationResetIndicator } from './pagination_indicator';
import { DynamicCreateButton } from './dynamic_create_button';
import FlipMove from 'react-flip-move';
import { PageChooser } from './page_chooser';

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

  // console.log(`Posts pagination: ${pagination}`);

  return (
    <TabsNavigation
      appSection={AppSection.POSTS}
      selectedGroup={selectedGroup}
      groupPageForwarder={(groupIdentifier) => `/g/${groupIdentifier}/posts`}
      groupPageReverse='/posts'
      withServerPinning
      showShrinkPreviews
      // bottomChrome={<DynamicCreateButton selectedGroup={selectedGroup} showPosts />}
      loading={loadingPosts}
    >
      <YStack f={1} w='100%' jc="center" ai="center" py="$2" px='$3' maw={800} space>
        <YStack w='100%'>
          <FlipMove>

            <div id='pages-create' key='pages-create' style={{ display: 'flex' }}>
              <XStack w='100%'>
                <PageChooser {...pagination} width='auto' />
                <XStack f={1} />
                <XStack>
                  <DynamicCreateButton showPosts />
                </XStack>
              </XStack>
              {/* <div style={{ marginLeft: 'auto' }}>
              </div> */}
            </div>

            {/* <div key='pagination-reset'>
              <PaginationResetIndicator {...pagination} />
            </div> */}
            {firstPageLoaded || allPosts.length > 0
              ? allPosts.length === 0
                ? <div key='no-posts-found' style={{ width: '100%', marginLeft: 'auto', marginRight: 'auto' }}>
                  <YStack width='100%' maw={600} jc="center" ai="center" mx='auto'>
                    <Heading size='$5' o={0.5} mb='$3'>No posts found.</Heading>
                    {/* <Heading size='$2' o={0.5} ta='center'>The posts you're looking for may either not exist, not be visible to you, or be hidden by moderators.</Heading> */}
                  </YStack>
                </div>
                : undefined
              : undefined}
            {paginatedPosts.map((post) => {
              return <div key={`post-${federatedId(post)}`} style={{ width: '100%' }}>
                <XStack w='100%'
                  animation='standard' {...standardAnimation}>
                  <PostCard post={post} isPreview />
                </XStack>
              </div>;
            })}
            {pagination.pageCount > 1
              ? <div key='page-chooser-bottom'
                style={{ width: '100%', maxWidth: 800, paddingLeft: 18, paddingRight: 18 }}>
                <PageChooser {...pagination} pageTopId='pages-create' showResultCounts
                entityName={{ singular: 'post', plural: 'posts' }}
                 />
              </div>
              : undefined}
            {/* <div key='pagination'>
              <PaginationIndicator {...pagination} />
            </div> */}
          </FlipMove>
        </YStack>
        {showScrollPreserver ? <YStack h={100000} /> : undefined}
      </YStack>
    </TabsNavigation>
  )
}
