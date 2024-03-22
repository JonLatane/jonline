import { EventListingType, PostListingType } from '@jonline/api';
import { AnimatePresence, Button, Heading, ScrollView, Spinner, XStack, YStack, dismissScrollPreserver, isClient, needsScrollPreservers, standardAnimation, useMedia, useWindowDimensions } from '@jonline/ui';
import { ChevronRight } from '@tamagui/lucide-icons';
import { useAppDispatch, useEventPages, usePaginatedRendering, usePostPages, useServer } from 'app/hooks';
import { FederatedGroup, RootState, federateId, federatedId, setShowEventsOnLatest, useRootSelector, useServerTheme } from 'app/store';
import { setDocumentTitle, themedButtonBackground } from 'app/utils';
import React, { useEffect, useState } from 'react';
import FlipMove from 'react-flip-move';
import { useLink } from 'solito/link';
import EventCard from '../event/event_card';
import { TabsNavigation } from '../navigation/tabs_navigation';
import PostCard from '../post/post_card';
import { DynamicCreateButton } from './dynamic_create_button';
import { PaginationIndicator, PaginationResetIndicator } from './pagination_indicator';

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
  const mediaQuery = useMedia();
  const app = useRootSelector((state: RootState) => state.app);
  const showEventsOnLatest = app.showEventsOnLatest ?? true;

  const [showScrollPreserver, setShowScrollPreserver] = useState(needsScrollPreservers());
  const currentServer = useServer();
  const { server, primaryColor, navColor, navTextColor } = useServerTheme();
  const groupLinkId = !!selectedGroup
    ? (currentServer?.host === selectedGroup?.serverHost
      ? selectedGroup.shortname
      : federateId(selectedGroup.shortname, selectedGroup.serverHost))
    : undefined;
  const eventsLink = useLink({ href: selectedGroup ? `/g/${groupLinkId}/events` : '/events' });
  const allEventsLink = useLink({ href: selectedGroup ? `/g/${groupLinkId}/events` : '/events?endsAfter=1969-12-31T19%3A00%3A00.000-05%3A00' });

  const dimensions = useWindowDimensions();

  useEffect(() => {
    const serverName = server?.serverConfiguration?.serverInfo?.name || '...';
    const title = selectedGroup ? `${selectedGroup.name} | ${serverName}` : serverName;
    setDocumentTitle(`Latest | ${title}`)
  });

  const { results: allPosts, loading: loadingPosts, reload: reloadPosts, hasMorePages, firstPageLoaded: postsLoaded } =
    usePostPages(PostListingType.ALL_ACCESSIBLE_POSTS, selectedGroup);


  const postPagination = usePaginatedRendering(allPosts, 7, {
    // itemIdResolver: (oldLastPost) => `post-${federatedId(oldLastPost)}`
  });
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

  const eventCardWidth = mediaQuery.gtSm ? 400 : 323;
  const noEventsWidth = Math.max(300, Math.min(1400, window.innerWidth) - 180);
  return (
    <TabsNavigation
      customHomeAction={selectedGroup ? undefined : onHomePressed}
      selectedGroup={selectedGroup}
      withServerPinning
      showShrinkPreviews
      loading={loadingPosts || loadingEvents}
      bottomChrome={<DynamicCreateButton selectedGroup={selectedGroup} showPosts showEvents />}
    >
      <YStack f={1} w='100%' jc="center" ai="center" p="$0" mt='$3' maw={1400} space>

        <XStack key='latest-events-header' w='100%' px='$3' ai='center'>
          <Button mr='auto' onPress={() => dispatch(setShowEventsOnLatest(!showEventsOnLatest))}>
            <Heading size='$6'>Upcoming Events</Heading>
            <XStack animation='quick' rotate={showEventsOnLatest ? '90deg' : '0deg'}>
              <ChevronRight />
            </XStack>
          </Button>
          {/* {eventsLoaded && allEvents.length === 0
            ? <Button ml='auto' h='auto' transparent {...themedButtonBackground(navColor)}
              {...allEventsLink}>
              <YStack ai='center' w='100%'>
                <Heading size='$1' color={navTextColor} textDecorationLine='none'>All</Heading>
                <Heading size='$4' color={navTextColor} textDecorationLine='none'>Events</Heading>
              </YStack>
            </Button>
            : undefined} */}
        </XStack>
        <AnimatePresence>
          {showEventsOnLatest &&
            (eventsLoaded || allEvents.length > 0 || loadingEvents) ?
            <YStack key='latest-events'
              w='100%'
              // h={showEventsOnLatest && eventsLoaded && postsLoaded ? undefined : 0}
              // overflow={showEventsOnLatest && eventsLoaded && postsLoaded ? undefined : 'visible'}
              animation='standard'
              {...standardAnimation}
            >
              <ScrollView horizontal w='100%'>
                <XStack w={eventCardWidth} gap='$2' mx='auto' pl={mediaQuery.gtMd ? '$5' : undefined} my='auto'>

                  <FlipMove style={{ display: 'flex' }}>

                    {allEvents.length == 0 && !loadingEvents
                      ? <div style={{ width: noEventsWidth, marginTop: 'auto', marginBottom: 'auto' }} key='no-events-found'>
                        <YStack width='100%' maw={600} jc="center" ai="center" mx='auto' my='auto' px='$2' mt='$3'>
                          <Heading size='$5' o={0.5} ta='center' mb='$3'>No events found.</Heading>
                          {/* <Heading size='$2' o={0.5} ta='center'>The events you're looking for may either not exist, not be visible to you, or be hidden by moderators.</Heading> */}
                        </YStack>
                      </div>
                      : undefined}
                    {paginatedEvents.map((event) =>
                      <span key={`event-preview-${federatedId(event)}-${event.instances[0]!.id}`}>
                        <XStack mx='$1' px='$1' pb='$5'>
                          <EventCard event={event} isPreview horizontal xs />
                        </XStack>
                      </span>)}
                    {loadingEvents && allEvents.length == 0
                      ? <XStack key='spinner' mx={window.innerWidth / 2 - 50} my='auto'>
                        <Spinner size='large' color={navColor} />
                      </XStack>
                      : undefined}
                    <div style={{ marginTop: 'auto', marginBottom: 'auto' }}>
                      <Button my='auto' p='$5' ml='$3' mr='$10' h={200} {...eventsLink}>
                        <YStack ai='center' py='$3' jc='center'>
                          <Heading size='$4'>More</Heading>
                          <Heading size='$5'>Events</Heading>
                          <ChevronRight />
                        </YStack>
                      </Button>
                    </div>
                  </FlipMove>
                </XStack>
              </ScrollView>
            </YStack>
            : undefined}
        </AnimatePresence>
        {/* </AnimatePresence> */}

        <YStack f={1} w='100%' jc="center" ai="center" maw={800} space>
          <YStack f={1} px='$3' w='100%' key={`post-list`}>
            <Heading size='$5' mb='$3' mx='auto'>Posts</Heading>
            <PaginationResetIndicator {...postPagination} />
            <FlipMove>

              {(eventsLoaded && postsLoaded) || (allPosts.length > 0 || allEvents.length > 0)
                ? allPosts.length === 0
                  ? <div key='no-posts-found' style={{ width: '100%', margin: 'auto' }}>
                    <YStack mt={(window.innerHeight - 200) * 0.2} width='100%' maw={600} jc="center" ai="center" mx='auto'>
                      <Heading size='$5' o={0.5} mb='$3'>No posts found.</Heading>
                      {/* <Heading size='$2' o={0.5} ta='center'>The posts you're looking for may either not exist, not be visible to you, or be hidden by moderators.</Heading> */}
                    </YStack>
                  </div>
                  : undefined
                : undefined
              }
              {paginatedPosts.map((post) => {
                return <div key={`post-${federatedId(post)}`} id={`post-${federatedId(post)}`} style={{ width: '100%' }}>
                  {/* <XStack w='100%'> */}
                  <PostCard post={post} isPreview />
                  {/* </XStack> */}
                </div>;
              })}
            </FlipMove>
            <PaginationIndicator {...postPagination} />
          </YStack>
        </YStack>
        {showScrollPreserver ? <YStack h={100000} /> : undefined}
      </YStack>
    </TabsNavigation>
  )
}
