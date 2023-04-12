import { Event, EventListingType } from '@jonline/api';
import { dismissScrollPreserver, Heading, isClient, needsScrollPreservers, Spinner, useWindowDimensions, YStack } from '@jonline/ui';
import { getEventsPage, loadEventsPage, RootState, useCredentialDispatch, useServerTheme, useTypedSelector } from 'app/store';
import React, { useEffect, useState } from 'react';
import { FlatList } from 'react-native';
import StickyBox from "react-sticky-box";
// import { StickyCreateButton } from '../evepont/create_event_sheet';
import EventCard from '../event/event_card';
import PostCard from '../post/post_card';
import { TabsNavigation } from '../tabs/tabs_navigation';
import { AppSection } from '../tabs/features_navigation';

export function EventsScreen() {
  const serversState = useTypedSelector((state: RootState) => state.servers);
  const eventsState = useTypedSelector((state: RootState) => state.events);
  const app = useTypedSelector((state: RootState) => state.app);

  const events: Event[] = useTypedSelector((state: RootState) =>
    getEventsPage(state.events, EventListingType.PUBLIC_EVENTS, 0));
  // const events = useTypedSelector((state: RootState) => selectAllEvents(state.events));
  // const events: Event[] = [];
  const [showScrollPreserver, setShowScrollPreserver] = useState(needsScrollPreservers());
  let { dispatch, accountOrServer } = useCredentialDispatch();
  const { server, primaryColor, navColor, navTextColor } = useServerTheme();
  // let primaryColorInt = serversState.server?.serverConfiguration?.serverInfo?.colors?.primary;
  // let primaryColor = `#${(primaryColorInt)?.toString(16).slice(-6) || '424242'}`;
  // let navColorInt = serversState.server?.serverConfiguration?.serverInfo?.colors?.navigation;
  // let navColor = `#${(navColorInt)?.toString(16).slice(-6) || 'fff'}`;
  const dimensions = useWindowDimensions();

  const [loadingEvents, setLoadingEvents] = useState(false);
  useEffect(() => {
    if (eventsState.loadStatus == 'unloaded' && !loadingEvents) {
      if (!accountOrServer.server) return;

      console.log("Loading events...");
      setLoadingEvents(true);
      reloadEvents();
    } else if (eventsState.loadStatus == 'loaded' && loadingEvents) {
      setLoadingEvents(false);
      dismissScrollPreserver(setShowScrollPreserver);
    }
    document.title = server?.serverConfiguration?.serverInfo?.name || 'Jonline';
  });

  function reloadEvents() {
    // setTimeout(() => 
    dispatch(loadEventsPage({ ...accountOrServer }))
    // , 1);
  }

  function onHomePressed() {
    if (isClient && window.scrollY > 0) {
      window.scrollTo({ top: 0, behavior: 'smooth' });
    } else {
      reloadEvents();
    }
  }

  return (
    <TabsNavigation customHomeAction={onHomePressed} appSection={AppSection.EVENTS}>
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
            keyExtractor={(event) => event.id}
            renderItem={({ item: event }) => {
              return <EventCard event={event} isPreview />;
              // return <PostCard post={event.post!} isPreview />;
            }} />}
      </YStack>
      {/* <StickyCreateButton /> */}
    </TabsNavigation>
  )
}
