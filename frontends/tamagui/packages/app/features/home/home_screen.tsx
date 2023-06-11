import { EventListingType, Group, PostListingType } from '@jonline/api';
import { AnimatePresence, Button, Heading, ScrollView, Spinner, XStack, YStack, dismissScrollPreserver, isClient, needsScrollPreservers, useMedia, useWindowDimensions } from '@jonline/ui';
import { ChevronRight } from '@tamagui/lucide-icons';
import { useEventPages, useGroupEventPages, useGroupPostPages, usePostPages } from 'app/hooks/pagination_hooks';
import { RootState, setShowEventsOnLatest, useServerTheme, useTypedDispatch, useTypedSelector } from 'app/store';
import React, { useEffect, useState } from 'react';
import StickyBox from "react-sticky-box";
import { useLink } from 'solito/link';
import EventCard from '../event/event_card';
import PostCard from '../post/post_card';
import { TabsNavigation } from '../tabs/tabs_navigation';
import { PaginationIndicator } from './pagination_indicator';
import { StickyCreateButton } from './sticky_create_button';

export function HomeScreen() {
  return <BaseHomeScreen />;
}

export type HomeScreenProps = {
  selectedGroup?: Group
};

export const BaseHomeScreen: React.FC<HomeScreenProps> = ({ selectedGroup }: HomeScreenProps) => {
  const dispatch = useTypedDispatch();
  const postsState = useTypedSelector((state: RootState) => state.posts);
  const eventsState = useTypedSelector((state: RootState) => state.events);
  const media = useMedia();
  const app = useTypedSelector((state: RootState) => state.app);
  const showEventsOnLatest = app.showEventsOnLatest ?? true;

  const [showScrollPreserver, setShowScrollPreserver] = useState(needsScrollPreservers());
  const { server, primaryColor, navColor, navTextColor } = useServerTheme();
  const eventsLink = useLink({ href: selectedGroup ? `/g/${selectedGroup.shortname}/events` : '/events' });

  const dimensions = useWindowDimensions();

  useEffect(() => {
    document.title = server?.serverConfiguration?.serverInfo?.name || 'Jonline';
  });

  const [currentPostsPage, setCurrentPostsPage] = useState(0);

  const { posts, loadingPosts, reloadPosts, hasMorePages, firstPageLoaded: postsLoaded } = selectedGroup
    ? useGroupPostPages(selectedGroup.id, currentPostsPage)
    : usePostPages(PostListingType.PUBLIC_POSTS, currentPostsPage);

  // Only load the first page of events on this screen.
  const { events, loadingEvents, reloadEvents, firstPageLoaded: eventsLoaded } = selectedGroup
    ? useGroupEventPages(selectedGroup.id, 0)
    : useEventPages(EventListingType.PUBLIC_EVENTS, 0);

  function onHomePressed() {
    if (isClient && window.scrollY > 0) {
      window.scrollTo({ top: 0, behavior: 'smooth' });
    } else {
      reloadPosts();
      reloadEvents();
    }
  }

  useEffect(() => {
    if (eventsLoaded && postsLoaded) {
      dismissScrollPreserver(setShowScrollPreserver);
    }
  }, [eventsLoaded, postsLoaded]);

  // console.log("BaseHomeScreen render", { posts: posts.length, events: events.length, loaded: [eventsLoaded, postsLoaded] })

  return (
    <TabsNavigation
      customHomeAction={selectedGroup ? undefined : onHomePressed}
      selectedGroup={selectedGroup}
    >
      {postsState.baseStatus == 'loading' ? <StickyBox style={{ zIndex: 10, height: 0 }}>
        <YStack space="$1" opacity={0.92}>
          <Spinner size='large' color={navColor} scale={2}
            top={dimensions.height / 2 - 50}
          />
        </YStack>
      </StickyBox> : undefined}
      <YStack f={1} w='100%' jc="center" ai="center" p="$0" paddingHorizontal='$3' mt='$3' maw={800} space>
        {eventsLoaded && postsLoaded
          ? <XStack w='100%'>
            <Button onPress={() => dispatch(setShowEventsOnLatest(!showEventsOnLatest))}>
              <Heading size='$6'>Upcoming Events</Heading>
              <XStack animation='quick' rotate={showEventsOnLatest ? '90deg' : '0deg'}>
                <ChevronRight />
              </XStack>
            </Button>
          </XStack>
          : undefined}
        {/* <AnimatePresence> */}
          {showEventsOnLatest && eventsLoaded && postsLoaded ?
            <YStack
              key='latest-events'
              w='100%'
              h={showEventsOnLatest && eventsLoaded && postsLoaded ? undefined : 0}
              overflow={showEventsOnLatest && eventsLoaded && postsLoaded ? undefined : 'visible'}
              animation='quick'
              opacity={1}
              scale={1}
              y={0}
              enterStyle={{ y: -50, opacity: 0, }}
              exitStyle={{ y: -50, opacity: 0, }}
            >
              {events.length == 0
                ? eventsLoaded
                  ? <YStack width='100%' maw={600} jc="center" ai="center">
                    <Heading size='$5' mb='$3'>No events found.</Heading>
                    <Heading size='$3' ta='center'>The events you're looking for may either not exist, not be visible to you, or be hidden by moderators.</Heading>
                  </YStack>
                  : undefined
                : <ScrollView horizontal
                  w='100%'>
                  <XStack w={media.gtSm ? 400 : 260} space='$2'>
                    {events.map((event) => <EventCard key={`event-preview-${event.id}-${event.instances[0]!.id}`} event={event} isPreview horizontal />)}
                    <Button my='auto' p='$5' mx='$3' h={200} {...eventsLink}>
                      <YStack ai='center' py='$3' jc='center'>
                        <Heading size='$4'>More</Heading>
                        <Heading size='$5'>Events</Heading>
                        <ChevronRight />
                      </YStack>
                    </Button>
                  </XStack>
                </ScrollView>}
            </YStack>
            : undefined}
          {eventsLoaded && postsLoaded
            ? posts.length === 0
              ? <YStack key='no-posts-found' width='100%' maw={600} jc="center" ai="center" f={1}
                animation='quick'
                opacity={1}
                scale={1}
                y={0}
                enterStyle={{ y: -50, opacity: 0, }}
                exitStyle={{ y: -50, opacity: 0, }}
                >
                <Heading size='$5' mb='$3'>No posts found.</Heading>
                <Heading size='$3' ta='center'>The posts you're looking for may either not exist, not be visible to you, or be hidden by moderators.</Heading>
              </YStack>
              : <YStack f={1} key={`post-list`}
                animation='quick'
                opacity={1}
                scale={1}
                y={0}
                enterStyle={{ y: -50, opacity: 0, }}
                exitStyle={{ y: -50, opacity: 0, }}
              >
                {posts.map((post) => {
                  return <PostCard key={`post-preview-${post.id}`} post={post} isPreview />;
                })}
                <PaginationIndicator page={currentPostsPage} loadingPage={loadingPosts || postsState.baseStatus == 'loading'}
                  hasNextPage={hasMorePages}
                  loadNextPage={() => setCurrentPostsPage(currentPostsPage + 1)}
                />
                {showScrollPreserver ? <YStack h={100000} /> : undefined}
              </YStack>
            : undefined
          }
        {/* </AnimatePresence> */}
      </YStack>
      <StickyCreateButton  selectedGroup={selectedGroup} showPosts showEvents />
    </TabsNavigation>
  )
}
