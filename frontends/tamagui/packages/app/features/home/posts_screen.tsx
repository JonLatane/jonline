import { PostListingType } from '@jonline/api';
import { Heading, XStack, YStack, dismissScrollPreserver, needsScrollPreservers, standardAnimation, useMedia, useWindowDimensions } from '@jonline/ui';
import { usePaginatedRendering } from 'app/hooks';
import { usePostPages } from 'app/hooks/pagination/post_pagination_hooks';
import { federatedId, useServerTheme } from 'app/store';
import { setDocumentTitle } from 'app/utils';
import React, { useEffect, useState } from 'react';
import { AppSection } from '../navigation/features_navigation';
import { TabsNavigation } from '../navigation/tabs_navigation';
import PostCard from '../post/post_card';
import { DynamicCreateButton } from './dynamic_create_button';
import { HomeScreenProps } from './home_screen';
import { PageChooser } from './page_chooser';
import { AutoAnimatedList } from '../post';

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

  const documentTitle = (() => {
    const serverName = server?.serverConfiguration?.serverInfo?.name || '...';
    const title = selectedGroup ? `${selectedGroup.name} | ${serverName}` : serverName;
    return title;
  })();
  useEffect(() => {
    setDocumentTitle(documentTitle);
  }, [documentTitle]);

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

  const mediaQuery = useMedia();
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
      <YStack f={1} w='100%' jc="center" ai="center" py="$2"
        maw={800} space>
        <YStack w='100%'>
          <AutoAnimatedList>
            <XStack id='pages-create' key='pages-create' w='100%'>
              <PageChooser {...pagination} width='auto' />
              <XStack f={1} />
              <XStack>
                <DynamicCreateButton showPosts />
              </XStack>
            </XStack>

            {firstPageLoaded || allPosts.length > 0
              ? allPosts.length === 0
                ? <YStack key='no-posts-found' width='100%' maw={600} jc="center" ai="center" mx='auto'>
                  <Heading size='$5' o={0.5} mb='$3'>No posts found.</Heading>
                </YStack>
                : undefined
              : undefined}
            {paginatedPosts.map((post) => {
              return <XStack key={`post-${federatedId(post)}`} w='100%'
                animation='standard' {...standardAnimation}>
                <PostCard post={post} isPreview />
              </XStack>
                ;
            })}
            {pagination.pageCount > 1
              ? <PageChooser key='page-chooser-bottom' {...pagination} pageTopId='pages-create' showResultCounts
                entityName={{ singular: 'post', plural: 'posts' }}
              />
              : undefined}
          </AutoAnimatedList>
        </YStack>
        {showScrollPreserver ? <YStack h={100000} /> : undefined}
      </YStack>
    </TabsNavigation>
  )
}
