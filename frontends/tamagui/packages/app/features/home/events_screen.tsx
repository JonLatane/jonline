import { EventListingType, TimeFilter } from '@jonline/api';
import { Heading, Spinner, Text, XStack, YStack, dismissScrollPreserver, needsScrollPreservers, useWindowDimensions } from '@jonline/ui';
import { RootState, useServerTheme, useTypedSelector } from 'app/store';
import React, { useEffect, useState } from 'react';
import StickyBox from "react-sticky-box";
// import { StickyCreateButton } from '../evepont/create_event_sheet';
import { useEventPages, useGroupEventPages } from 'app/hooks';
import moment from 'moment';
import { supportDateInput, toProtoISOString } from '../event/create_event_sheet';
import EventCard from '../event/event_card';
import { AppSection } from '../tabs/features_navigation';
import { TabsNavigation } from '../tabs/tabs_navigation';
import { HomeScreenProps } from './home_screen';
import { PaginationIndicator } from './pagination_indicator';
import { StickyCreateButton } from './sticky_create_button';

export function EventsScreen() {
  return <BaseEventsScreen />;
}

export const BaseEventsScreen: React.FC<HomeScreenProps> = ({ selectedGroup }: HomeScreenProps) => {
  const eventsState = useTypedSelector((state: RootState) => state.events);

  const [showScrollPreserver, setShowScrollPreserver] = useState(needsScrollPreservers());
  const { server, primaryColor, navColor, navTextColor } = useServerTheme();
  const dimensions = useWindowDimensions();
  const [pageLoadTime, _setPageLoadTime] = useState<string>(supportDateInput(moment(Date.now())));
  const [endsAfter, setEndsAfter] = useState<string>(pageLoadTime);

  const timeFilter: TimeFilter = { endsAfter: endsAfter ? toProtoISOString(endsAfter) : undefined };
  console.log('timeFilter', timeFilter);
  useEffect(() => {
    const serverName = server?.serverConfiguration?.serverInfo?.name || 'Jonline';
    const title = selectedGroup ? `${selectedGroup.name} | ${serverName}` : serverName;
    document.title = `Events | ${title}`;
  });

  const [currentPage, setCurrentPage] = useState(0);
  const { events, loadingEvents, reloadEvents, hasMorePages, firstPageLoaded } = selectedGroup
    ? useGroupEventPages(selectedGroup.id, currentPage, { filter: timeFilter })
    : useEventPages(EventListingType.PUBLIC_EVENTS, currentPage, { filter: timeFilter });

  useEffect(() => {
    if (firstPageLoaded) {
      dismissScrollPreserver(setShowScrollPreserver);
    }
  }, [firstPageLoaded]);

  return (
    <TabsNavigation
      appSection={AppSection.EVENTS}
      selectedGroup={selectedGroup}
      groupPageForwarder={(group) => `/g/${group.shortname}/events`}
    >
      {eventsState.loadStatus == 'loading' ? <StickyBox style={{ zIndex: 10, height: 0 }}>
        <YStack space="$1" opacity={0.92}>
          <Spinner size='large' color={navColor} scale={2}
            top={dimensions.height / 2 - 50}
          />
        </YStack>
      </StickyBox> : undefined}
      <YStack f={1} w='100%' jc="center" ai="center" p="$0" paddingHorizontal='$3' mt='$3' maw={800} space>
        <XStack w='100%' px='$2' flexWrap='wrap'>
          <Heading size='$5' mb='$3' my='auto'>Ends After</Heading>
          <Text ml='auto' my='auto' fontSize='$2' fontFamily='$body'>
            <input type='datetime-local' value={endsAfter} onChange={(v) => setEndsAfter(v.target.value)} style={{ padding: 10 }} />
          </Text>
        </XStack>
        {firstPageLoaded
          ? events.length == 0
            ? <YStack width='100%' maw={600} jc="center" ai="center">
              <Heading size='$5' mb='$3'>No events found.</Heading>
              <Heading size='$3' ta='center'>The events you're looking for may either not exist, not be visible to you, or be hidden by moderators.</Heading>
            </YStack>
            : <>
              <YStack>
                {events.map((event) => {
                  return <EventCard event={event} isPreview />;
                })}
                <PaginationIndicator
                  page={currentPage}
                  loadingPage={loadingEvents || eventsState.loadStatus == 'loading'}
                  hasNextPage={hasMorePages}
                  loadNextPage={() => setCurrentPage(currentPage + 1)} />
                {showScrollPreserver ? <YStack h={100000} /> : undefined}
              </YStack>
            </>
          : undefined}
      </YStack>
      <StickyCreateButton selectedGroup={selectedGroup} showEvents />
      {/* <StickyCreateButton /> */}
    </TabsNavigation>
  )
}
