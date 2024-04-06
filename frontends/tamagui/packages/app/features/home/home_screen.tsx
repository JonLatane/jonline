import { EventListingType, PostListingType } from '@jonline/api';
import { AnimatePresence, Button, Heading, ScrollView, Spinner, XStack, YStack, dismissScrollPreserver, isClient, needsScrollPreservers, standardAnimation, useMedia, useWindowDimensions } from '@jonline/ui';
import { ChevronRight } from '@tamagui/lucide-icons';
import { maxPagesToRender, useAppDispatch, useEventPageParam, useEventPages, usePaginatedRendering, usePostPages, useCurrentServer } from 'app/hooks';
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
import { PageChooser } from './page_chooser';

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
  const currentServer = useCurrentServer();
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

  const eventPagination = usePaginatedRendering(allEvents, 7, {
    pageParamHook: useEventPageParam,
  });
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
    //   bottomChrome={
    //   <DynamicCreateButton selectedGroup={selectedGroup} showPosts showEvents />
    // }
    >
      <FlipMove style={{
        width: '100%',
        margin: 'auto',
        display: 'flex', flexDirection: 'column', flex: 1,
        justifyContent: 'center', alignItems: 'center', marginTop: 5,
        maxWidth: 1400,
        paddingBottom: 20
      }}>
        {/* <div key='create' style={{ width: '100%', maxWidth: 800, paddingLeft: 18, paddingRight: 18 }}>
          <DynamicCreateButton selectedGroup={selectedGroup} showPosts showEvents />
        </div> */}
        <div key='latest-events-header' style={{ width: '100%' }}>
          <XStack w='100%' pt={0} px='$3' ai='center'
          // flexDirection='row-reverse'
          >

            <Button mr='auto' my='$2' onPress={() => dispatch(setShowEventsOnLatest(!showEventsOnLatest))}>
              <Heading size='$6'>Upcoming Events</Heading>
              <XStack animation='quick' rotate={showEventsOnLatest ? '90deg' : '0deg'}>
                <ChevronRight />
              </XStack>
            </Button>
            <div style={{ flex: 1 }} />
            <div key='create' style={{ marginTop: 5, marginBottom: 5, marginLeft: 'auto' }}>
              <DynamicCreateButton selectedGroup={selectedGroup} showPosts showEvents />
            </div>
          </XStack>
        </div>
        {showEventsOnLatest
          ? <div key='latest-events' style={{ width: '100%' }}>
            <YStack w='100%'>
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
                    {showEventsOnLatest
                      ? <div style={{ marginTop: 'auto', marginBottom: 'auto' }}>
                        <Button my='auto' p='$5' ml='$3' mr='$10' h={200} {...eventsLink}>
                          <YStack ai='center' py='$3' jc='center'>
                            <Heading size='$4'>More</Heading>
                            <Heading size='$5'>Events</Heading>
                            <ChevronRight />
                          </YStack>
                        </Button>
                      </div>
                      : undefined}
                  </FlipMove>
                </XStack>
              </ScrollView>
            </YStack>
          </div>
          : undefined}

        <div key='latest-posts-header' style={{width: '100%', maxWidth: 800, paddingLeft: 18, paddingRight: 18}}>
          <XStack ai='center' w='100%'>
            <Heading size='$5' pr='$3' mr='auto'>Posts</Heading>
            <PageChooser {...postPagination} width='auto' />
          </XStack>
        </div>
        {/* {postPagination.pageCount > 1 || true
          ? <div key='page-chooser-top'
            style={{ width: '100%', maxWidth: 800, paddingLeft: 18, paddingRight: 18 }}>
            <PageChooser {...postPagination} />
          </div>
          : undefined} */}
        {/* {maxPagesToRender < postPagination.page + 1
          ? <div key='pagination-reset'
            style={{ width: '100%', maxWidth: 800, paddingLeft: 18, paddingRight: 18 }}>
            <PaginationResetIndicator {...postPagination} />
          </div>
          : undefined} */}

        {postsLoaded || allPosts.length > 0
          ? allPosts.length === 0
            ? <div key='no-posts-found' style={{ width: '100%', margin: 'auto' }}>
              <YStack mt={(window.innerHeight - 200) * 0.2} width='100%' maw={600} jc="center" ai="center" mx='auto'>
                <Heading size='$5' o={0.5} mb='$3'>No posts found.</Heading>
                {/* <Heading size='$2' o={0.5} ta='center'>The posts you're looking for may either not exist, not be visible to you, or be hidden by moderators.</Heading> */}
              </YStack>
            </div>
            : undefined
          : undefined}
        {paginatedPosts.map((post) => {
          return <div key={`post-${federatedId(post)}`} id={`post-${federatedId(post)}`}
            style={{ width: '100%', maxWidth: 800, paddingLeft: 18, paddingRight: 18 }}>
            <PostCard post={post} isPreview />
          </div>;
        })}

        {postPagination.pageCount > 1
          ? <div key='page-chooser-bottom'
            style={{ width: '100%', maxWidth: 800, paddingLeft: 18, paddingRight: 18 }}>
            <PageChooser {...postPagination} />
          </div>
          : undefined}
        {/* 
        <div key='pagination-next'
          style={{ width: '100%', maxWidth: 800, paddingLeft: 18, paddingRight: 18 }}>
          <PaginationIndicator {...postPagination} />
        </div> */}
        {showScrollPreserver ? <div key='scroll-preserver' style={{ height: 100000 }} /> : undefined}
        {/* </YStack> */}
      </FlipMove>
    </TabsNavigation>
  )
}
