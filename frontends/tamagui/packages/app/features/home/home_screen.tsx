import { EventListingType, PostListingType, TimeFilter } from '@jonline/api';
import { Button, Heading, ScrollView, Spinner, XStack, YStack, dismissScrollPreserver, needsScrollPreservers, toProtoISOString, useMedia, useWindowDimensions } from '@jonline/ui';
import { Calendar as CalendarIcon, ChevronRight } from '@tamagui/lucide-icons';
import { useAppDispatch, useCurrentServer, useEventPageParam, useEventPages, useLocalConfiguration, usePaginatedRendering, usePostPageParam, usePostPages } from 'app/hooks';
import { useBigCalendar, useShowEvents } from 'app/hooks/configuration_hooks';
import { FederatedGroup, RootState, federateId, federatedId, useRootSelector, useServerTheme } from 'app/store';
import { setDocumentTitle, themedButtonBackground } from 'app/utils';
import moment from 'moment';
import React, { useEffect, useState } from 'react';
import FlipMove from 'react-flip-move';
import { useLink } from 'solito/link';
import EventCard from '../event/event_card';
import { TabsNavigation } from '../navigation/tabs_navigation';
import PostCard from '../post/post_card';
import { DynamicCreateButton } from './dynamic_create_button';
import { EventsFullCalendar } from './events_full_calendar';
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
  // const showEvents = app.showEvents ?? true;
  const { showEvents, setShowEvents } = useShowEvents();
  const { bigCalendar, setBigCalendar } = useBigCalendar();

  const [showScrollPreserver, setShowScrollPreserver] = useState(needsScrollPreservers());
  const currentServer = useCurrentServer();
  const { server, primaryColor, navColor, navTextColor } = useServerTheme();
  const groupLinkId = !!selectedGroup
    ? (currentServer?.host === selectedGroup?.serverHost
      ? selectedGroup.shortname
      : federateId(selectedGroup.shortname, selectedGroup.serverHost))
    : undefined;
  const eventsLink = useLink({ href: selectedGroup ? `/g/${groupLinkId}/events` : '/events' });
  const allEventsLink = useLink({ href: selectedGroup ? `/g/${groupLinkId}/events` : '/events?endsAfter=1970-01-01T00%3A00%3A00.000Z' });

  const dimensions = useWindowDimensions();

  useEffect(() => {
    const serverName = server?.serverConfiguration?.serverInfo?.name || '...';
    const title = selectedGroup ? `${selectedGroup.name} | ${serverName}` : serverName;
    setDocumentTitle(`Latest | ${title}`)
  });

  const { results: allPosts, loading: loadingPosts, reload: reloadPosts, hasMorePages, firstPageLoaded: postsLoaded } =
    usePostPages(PostListingType.ALL_ACCESSIBLE_POSTS, selectedGroup);


  const postPagination = usePaginatedRendering(allPosts, 7, {
    pageParamHook: usePostPageParam,
    // itemIdResolver: (oldLastPost) => `post-${federatedId(oldLastPost)}`
  });
  const paginatedPosts = postPagination.results;

  const [pageLoadTime] = useState<string>(moment(Date.now()).toISOString(true));
  const endsAfter = moment(pageLoadTime).subtract(1, "week").toISOString(true);
  const timeFilter: TimeFilter = { endsAfter: endsAfter ? toProtoISOString(endsAfter) : undefined };

  // Only load the first page of events on this screen.
  const { results: eventResults, loading: loadingEvents, reload: reloadEvents, firstPageLoaded: eventsLoaded } =
    useEventPages(EventListingType.ALL_ACCESSIBLE_EVENTS, selectedGroup, { timeFilter });

  const { eventPagesOnHome } = useLocalConfiguration();
  const allEvents = bigCalendar
    ? eventResults
    : eventResults.filter(e => moment(e.instances[0]?.endsAt).isAfter(pageLoadTime))
  const eventPagination = usePaginatedRendering(allEvents, 7, {
    pageParamHook: useEventPageParam,
  });
  useEffect(() => {
    if (!eventPagesOnHome && eventPagination.page > 0) {
      eventPagination.setPage(0);
    }
  }, [eventPagesOnHome])
  const paginatedEvents = eventPagination.results;

  function onHomePressed() {
    // console.log('onHomePressed', document.getElementById('events-top'));
    setTimeout(
      () => document.getElementById('events-top')?.scrollIntoView({ behavior: 'smooth', block: 'center', inline: 'center' }),
      1
    );
    if (window.scrollY > 0) {
      window.scrollTo({ top: 0, behavior: 'smooth' });
    } else if (postPagination.page > 0 || eventPagination.page > 0) {
      setTimeout(() => {
        postPagination.setPage(0);
      }, 1);
      setTimeout(() => {
        eventPagination.setPage(0);
      }, 1);
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
        {/* <div key='create' style={{ width: '100%', max<Width>: 800, paddingLeft: 18, paddingRight: 18 }}>
          <DynamicCreateButton selectedGroup={selectedGroup} showPosts showEvents />
        </div> */}
        <div key='latest-events-header' style={{ width: '100%' }}>
          <XStack w='100%' pt={0} px='$3' ai='center'
          // flexDirection='row-reverse'
          >

            <Button mr='auto' my='$2' onPress={() => setShowEvents(!showEvents)}
            >
              <YStack ai='center'>
                <Heading size='$1' lh='$1'>Upcoming</Heading>
                <Heading size='$3' lh='$1'>Events</Heading>
              </YStack>
              <XStack animation='quick' rotate={showEvents ? '90deg' : '0deg'}>
                <ChevronRight />
              </XStack>
            </Button>
            <Button onPress={() => setBigCalendar(!bigCalendar)} ml='$2'
              icon={CalendarIcon}
              transparent
              {...themedButtonBackground(
                bigCalendar ? navColor : undefined, bigCalendar ? navTextColor : undefined)}
              animation='standard'
              disabled={!showEvents || allEvents.length === 0}
              o={showEvents && allEvents.length > 0 ? 1 : 0}
            />

            <div style={{ flex: 1 }} />
            <div key='create' style={{ marginTop: 5, marginBottom: 5, marginLeft: 'auto' }}>
              <DynamicCreateButton showPosts showEvents />
            </div>
          </XStack>
        </div>
        {showEvents
          ? bigCalendar && allEvents.length > 0
            ? [
              <div key='full-calendar' style={{ marginBottom: 10 }}>
                <EventsFullCalendar key='full-calendar' events={allEvents} weeklyOnly />
              </div>
            ]
            : [
              allEvents.length > 0 && eventPagesOnHome ?
                <div key='upcoming-events-pagination' style={{ width: '100%', paddingLeft: 8, paddingRight: 8 }}>

                  <PageChooser {...eventPagination} width='auto' />
                </div> : undefined,
              <div key='latest-events' style={{ width: '100%' }}>
                <YStack w='100%'>
                  <ScrollView horizontal w='100%'>
                    <XStack w={eventCardWidth} gap='$2' mx='auto' pl={mediaQuery.gtMd ? '$5' : undefined} my='auto'>

                      <FlipMove style={{ display: 'flex' }}>
                        <div id='events-top' />
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
                        {showEvents
                          ? <div style={{ marginTop: 'auto', marginBottom: 'auto' }}>
                            <Button my='auto' p='$5' ml='$3' mr='$10' h={200} {...allEventsLink}>
                              <YStack ai='center' py='$3' jc='center'>
                                <Heading size='$4'>All</Heading>
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
            ]
          : undefined}

        <div id='latest-posts-header' key='latest-posts-header' style={{ width: '100%', maxWidth: 800, paddingLeft: 18, paddingRight: 18 }}>
          <XStack ai='center' w='100%' overflow='hidden'>
            <Heading size='$5' my='$2' pr='$3' mr='auto'>Posts</Heading>
            {/* <XStack f={1}> */}
            <PageChooser {...postPagination} noAutoScroll width='auto' maxWidth='67%' />
            {/* </XStack> */}
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
            <PageChooser {...postPagination} pageTopId='latest-posts-header'
              entityName={{ singular: 'post', plural: 'posts' }} />
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
