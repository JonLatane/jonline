import { EventListingType, PostListingType } from '@jonline/api';
import { AnimatePresence, Button, Heading, ScrollView, Spinner, XStack, YStack, dismissScrollPreserver, isClient, needsScrollPreservers, standardAnimation, standardHorizontalAnimation, useMedia, useWindowDimensions } from '@jonline/ui';
import { ChevronRight } from '@tamagui/lucide-icons';
import { useAppDispatch, useEventPages, usePaginatedRendering, usePostPages } from 'app/hooks';
import { FederatedGroup, RootState, federatedId, setShowEventsOnLatest, useRootSelector, useServerTheme } from 'app/store';
import { setDocumentTitle, themedButtonBackground } from 'app/utils';
import React, { useEffect, useState } from 'react';
import StickyBox from "react-sticky-box";
import { useLink } from 'solito/link';
import EventCard from '../event/event_card';
import { TabsNavigation } from '../navigation/tabs_navigation';
import PostCard from '../post/post_card';
import { PaginationIndicator } from './pagination_indicator';
import { StickyCreateButton } from './sticky_create_button';

export function HomeScreen() {
  return <BaseHomeScreen />;
}

export type HomeScreenProps = {
  selectedGroup?: FederatedGroup
};

export const BaseHomeScreen: React.FC<HomeScreenProps> = ({ selectedGroup }) => {
  const dispatch = useAppDispatch();
  const postsState = useRootSelector((state: RootState) => state.posts);
  const eventsState = useRootSelector((state: RootState) => state.events);
  const media = useMedia();
  const app = useRootSelector((state: RootState) => state.app);
  const showEventsOnLatest = app.showEventsOnLatest ?? true;

  const [showScrollPreserver, setShowScrollPreserver] = useState(needsScrollPreservers());
  const { server, primaryColor, navColor, navTextColor } = useServerTheme();
  const eventsLink = useLink({ href: selectedGroup ? `/g/${selectedGroup.shortname}/events` : '/events' });

  const dimensions = useWindowDimensions();

  useEffect(() => {
    const serverName = server?.serverConfiguration?.serverInfo?.name || '...';
    const title = selectedGroup ? `${selectedGroup.name} | ${serverName}` : serverName;
    setDocumentTitle(`Latest | ${title}`)
  });

  const { results: allPosts, loading: loadingPosts, reload: reloadPosts, hasMorePages, firstPageLoaded: postsLoaded } =
    usePostPages(PostListingType.ALL_ACCESSIBLE_POSTS, selectedGroup);

  const postPagination = usePaginatedRendering(allPosts, 7);
  const paginatedPosts = postPagination.results;

  // Only load the first page of events on this screen.
  const { results: allEvents, loading: loadingEvents, reload: reloadEvents, firstPageLoaded: eventsLoaded } =
    useEventPages(EventListingType.ALL_ACCESSIBLE_EVENTS, selectedGroup);

  const eventPagination = usePaginatedRendering(allEvents, 7);
  const paginatedEvents = eventPagination.results;

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

  const eventCardWidth = media.gtSm ? 400 : 323;
  return (
    <TabsNavigation
      customHomeAction={selectedGroup ? undefined : onHomePressed}
      selectedGroup={selectedGroup}
      withServerPinning
    >
      {loadingPosts || loadingEvents ? <StickyBox style={{ zIndex: 10, height: 0 }}>
        <YStack space="$1" opacity={0.92}>
          <Spinner size='large' color={navColor} scale={2}
            top={dimensions.height / 2 - 50}
          />
        </YStack>
      </StickyBox> : undefined}
      <YStack f={1} w='100%' jc="center" ai="center" p="$0" mt='$3' maw={1400} space>
        <AnimatePresence>
          {(eventsLoaded || postsLoaded) || allEvents.length > 0
            ? <XStack key='latest-events-header' w='100%' px='$3'>
              <Button mr='auto' onPress={() => dispatch(setShowEventsOnLatest(!showEventsOnLatest))}>
                <Heading size='$6'>Upcoming Events</Heading>
                <XStack animation='quick' rotate={showEventsOnLatest ? '90deg' : '0deg'}>
                  <ChevronRight />
                </XStack>
              </Button>
              {/* <XStack f={1} /> */}
              <Button ml='auto' transparent {...themedButtonBackground(navColor)}
                {...eventsLink}>
                {/* <ChevronRight color={navTextColor} /> */}
                <Heading size='$4' color={navTextColor} textDecorationLine='none'>Events</Heading>
                {/* <XStack animation='quick' rotate={showEventsOnLatest ? '90deg' : '0deg'}> */}
                {/* <ChevronRight color={navTextColor} /> */}
                {/* </XStack> */}
              </Button>
              {/* <XStack my='auto'><DarkModeToggle /></XStack> */}
            </XStack>
            : undefined}
          {showEventsOnLatest ?
            ((eventsLoaded && postsLoaded) || allEvents.length > 0) ?
              <YStack key='latest-events'
                w='100%'
                // h={showEventsOnLatest && eventsLoaded && postsLoaded ? undefined : 0}
                // overflow={showEventsOnLatest && eventsLoaded && postsLoaded ? undefined : 'visible'}
                animation='standard'
                {...standardAnimation}
              >
                {allEvents.length == 0
                  ? eventsLoaded
                    ? <YStack width='100%' maw={600} jc="center" ai="center" mx='auto'>
                      <Heading size='$5' mb='$3'>No events found.</Heading>
                      <Heading size='$3' ta='center'>The events you're looking for may either not exist, not be visible to you, or be hidden by moderators.</Heading>
                    </YStack>
                    : undefined
                  : <ScrollView horizontal w='100%'>
                    <XStack w={eventCardWidth} space='$2' mx='$2' pl={media.gtMd ? '$5' : undefined} my='auto'>
                      {paginatedEvents.map((event) =>
                        <XStack key={`event-preview-${event.id}-${event.instances[0]!.id}`} pb='$5' animation='standard' {...standardHorizontalAnimation}>
                          <EventCard event={event} isPreview horizontal xs />
                        </XStack>)}
                      <Button my='auto' p='$5' ml='$3' mr='$10' h={200} {...eventsLink}>
                        <YStack ai='center' py='$3' jc='center'>
                          <Heading size='$4'>More</Heading>
                          <Heading size='$5'>Events</Heading>
                          <ChevronRight />
                        </YStack>
                      </Button>
                    </XStack>
                  </ScrollView>}
              </YStack>
              : <Spinner color={navColor} />
            : undefined}
        </AnimatePresence>

        <YStack f={1} w='100%' jc="center" ai="center" maw={800} space>
          {(eventsLoaded && postsLoaded) || (allPosts.length > 0 || allEvents.length > 0)
            ? allPosts.length === 0
              ? <YStack key='no-posts-found' width='100%' maw={600} jc="center" ai="center" f={1}
              // animation='quick'
              // {...standardAnimation}
              >
                <Heading size='$5' mb='$3'>No posts found.</Heading>
                <Heading size='$3' ta='center'>The posts you're looking for may either not exist, not be visible to you, or be hidden by moderators.</Heading>
              </YStack>
              : <YStack f={1} px='$3' w='100%' key={`post-list`}>
                <Heading size='$5' mb='$3' mx='auto'>Posts</Heading>
                {paginatedPosts.map((post) => {
                  return <PostCard key={`post-preview-${federatedId(post)}`} post={post} isPreview />;
                })}
                <PaginationIndicator {...postPagination} />
              </YStack>
            : undefined
          }
        </YStack>
        {showScrollPreserver ? <YStack h={100000} /> : undefined}
      </YStack>
      <StickyCreateButton selectedGroup={selectedGroup} showPosts showEvents />
    </TabsNavigation>
  )
}
