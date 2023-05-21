import { Event, EventListingType } from '@jonline/api';
import { dismissScrollPreserver, Heading, isClient, needsScrollPreservers, Spinner, useWindowDimensions, YStack } from '@jonline/ui';
import { getEventPages, getEventsPage, loadEventsPage, RootState, useCredentialDispatch, useServerTheme, useTypedSelector } from 'app/store';
import React, { useEffect, useState } from 'react';
import { FlatList } from 'react-native';
import StickyBox from "react-sticky-box";
// import { StickyCreateButton } from '../evepont/create_event_sheet';
import EventCard from '../event/event_card';
import PostCard from '../post/post_card';
import { TabsNavigation } from '../tabs/tabs_navigation';
import { AppSection } from '../tabs/features_navigation';

export function EventsScreen() {
  const eventsState = useTypedSelector((state: RootState) => state.events);

  const [showScrollPreserver, setShowScrollPreserver] = useState(needsScrollPreservers());
  const { server, primaryColor, navColor, navTextColor } = useServerTheme();
  const dimensions = useWindowDimensions();

  useEffect(() => {
    document.title = server?.serverConfiguration?.serverInfo?.name || 'Jonline';
  });

  const [currentPage, setCurrentPage] = useState(0);
  const { events, loadingEvents, reloadEvents } = useEventPages(
    EventListingType.PUBLIC_EVENTS,
    currentPage,
    () => dismissScrollPreserver(setShowScrollPreserver)
  );

  return (
    <TabsNavigation appSection={AppSection.EVENTS}>
      {eventsState.loadStatus == 'loading' ? <StickyBox style={{ zIndex: 10, height: 0 }}>
        <YStack space="$1" opacity={0.92}>
          <Spinner size='large' color={navColor} scale={2}
            top={dimensions.height / 2 - 50}
          />
        </YStack>
      </StickyBox> : undefined}
      <YStack f={1} w='100%' jc="center" ai="center" p="$0" paddingHorizontal='$3' mt='$3' maw={800} space>
        {events.length == 0
          ? eventsState.loadStatus != 'loading' && eventsState.loadStatus != 'unloaded'
            ? <YStack width='100%' maw={600} jc="center" ai="center">
              <Heading size='$5' mb='$3'>No events found.</Heading>
              <Heading size='$3' ta='center'>The events you're looking for may either not exist, not be visible to you, or be hidden by moderators.</Heading>
            </YStack>
            : undefined
          : <FlatList data={events}
            // onRefresh={reloadEvents}
            // refreshing={eventsState.status == 'loading'}
            // Allow easy restoring of scroll position
            ListFooterComponent={showScrollPreserver ? <YStack h={100000} /> : undefined}
            keyExtractor={(event) => `${event.id}-${event.instances[0]?.id}`}
            renderItem={({ item: event, index }) => {
              const isLast = index == events.length - 1;
              return <EventCard event={event} isPreview
              onOnScreen={isLast ? () => {
                console.log(`Loading page ${currentPage + 1}...`);
                setCurrentPage(currentPage + 1);
              }: undefined} />;
              // return <PostCard post={event.post!} isPreview />;
            }} />}
      </YStack>
      {/* <StickyCreateButton /> */}
    </TabsNavigation>
  )
}

export function useEventPages(listingType: EventListingType, throughPage: number, onLoaded?: () => void) {
  const { dispatch, accountOrServer } = useCredentialDispatch();
  const eventsState = useTypedSelector((state: RootState) => state.events);
  const [loadingEvents, setLoadingEvents] = useState(false);

  const events: Event[] = useTypedSelector((state: RootState) => getEventPages(state.events, EventListingType.PUBLIC_EVENTS, throughPage));

  useEffect(() => {
    if (eventsState.loadStatus == 'unloaded' && !loadingEvents) {
      if (!accountOrServer.server) return;

      console.log("Loading events...");
      setLoadingEvents(true);
      reloadEvents();
    } else if (eventsState.loadStatus == 'loaded' && loadingEvents) {
      setLoadingEvents(false);
      onLoaded?.();
    }
  });

  function reloadEvents() {
    dispatch(loadEventsPage({ ...accountOrServer, listingType }))
  }

  return { events, loadingEvents, reloadEvents };
}
