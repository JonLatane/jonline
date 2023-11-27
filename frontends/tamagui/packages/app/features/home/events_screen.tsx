import { EventListingType, TimeFilter } from '@jonline/api';
import { AnimatePresence, Button, Heading, Spinner, Text, XStack, YStack, dismissScrollPreserver, needsScrollPreservers, standardAnimation, useWindowDimensions } from '@jonline/ui';
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
import { createParam } from 'solito';
import { SubnavButton } from 'app/components/subnav_button';
import { setDocumentTitle } from 'app/utils/set_title';

const { useParam } = createParam<{ endsAfter: string }>()
export function EventsScreen() {
  return <BaseEventsScreen />;
}

export type EventDisplayMode = 'upcoming' | 'all' | 'filtered';
export const BaseEventsScreen: React.FC<HomeScreenProps> = ({ selectedGroup }: HomeScreenProps) => {
  const eventsState = useTypedSelector((state: RootState) => state.events);

  const [showScrollPreserver, setShowScrollPreserver] = useState(needsScrollPreservers());

  const { server, primaryColor, navColor, navTextColor } = useServerTheme();
  const dimensions = useWindowDimensions();
  const [pageLoadTime] = useState<string>(moment(Date.now()).toISOString(true));
  // const [endsAfter, setEndsAfter] = useState<string>(pageLoadTime);
  const [queryEndsAfter, setQueryEndsAfter] = useParam('endsAfter');
  const endsAfter = queryEndsAfter ?? moment(pageLoadTime).toISOString(true);
  // useEffect(() => {
  //   if (!queryEndsAfter) {
  //     setQueryEndsAfter(moment(pageLoadTime).toISOString(true));
  //   }
  // }, [endsAfter]);


  const timeFilter: TimeFilter = { endsAfter: endsAfter ? toProtoISOString(endsAfter) : undefined };
  // console.log('timeFilter', timeFilter);
  useEffect(() => {
    const serverName = server?.serverConfiguration?.serverInfo?.name || '...';
    const title = selectedGroup ? `${selectedGroup.name} | ${serverName}` : serverName;
    setDocumentTitle(`Events | ${title}`)
  });

  const [currentPage, setCurrentPage] = useState(0);
  const { events, loadingEvents, reloadEvents, hasMorePages, firstPageLoaded } = selectedGroup
    ? useGroupEventPages(selectedGroup.id, currentPage, { filter: timeFilter })
    : useEventPages(EventListingType.ALL_ACCESSIBLE_EVENTS, currentPage, { filter: timeFilter });

  useEffect(() => {
    if (firstPageLoaded) {
      dismissScrollPreserver(setShowScrollPreserver);
    }
  }, [firstPageLoaded]);


  const [displayMode, setDisplayMode] = useState('upcoming' as EventDisplayMode);
  useEffect(() => {
    switch (displayMode) {
      case 'upcoming':
        if (queryEndsAfter != undefined) {
          console.log('setting ends after to undefined');
          setQueryEndsAfter(undefined);
        }
        break;
      case 'all':
        if (queryEndsAfter != moment(0).toISOString(true)) {
          console.log('setting ends after to 0');
          setQueryEndsAfter(moment(0).toISOString(true));
        }
        break;
      case 'filtered':
        if (queryEndsAfter === undefined) {
          console.log('setting ends after to page load time');
          setQueryEndsAfter(moment(pageLoadTime).toISOString(true));
        }
        break;
    }

  }, [displayMode, queryEndsAfter]);

  function displayModeButton(associatedDisplayMode: EventDisplayMode, title: string) {
    return <SubnavButton title={title}
      // icon={icon}
      selected={displayMode === associatedDisplayMode}
      select={() => {
        setDisplayMode(associatedDisplayMode);
        window.scrollTo({ top: 0, behavior: 'smooth' });
      }} />;
  }
  return (
    <TabsNavigation
      appSection={AppSection.EVENTS}
      selectedGroup={selectedGroup}
      groupPageForwarder={(group) => `/g/${group.shortname}/events`}
    >
      <StickyBox key='filters' offsetTop={56} className='blur' style={{ width: '100%', zIndex: 10 }}>
        <YStack w='100%' px='$2' key='filter-toolbar'>

          <XStack w='100%'>
            {displayModeButton('upcoming', 'Upcoming')}
            {displayModeButton('all', 'All')}
            {displayModeButton('filtered', 'Filtered')}
          </XStack>
          {/* <Button size='$1' onPress={() => setShowMedia(!showMedia)}>
            <XStack animation='quick' rotate={showMedia ? '90deg' : '0deg'}>
              <ChevronRight size='$1' />
            </XStack>
            <Heading size='$1' f={1}>Media {media.length > 0 ? `(${media.length})` : undefined}</Heading>
          </Button> */}
          <AnimatePresence>
            {displayMode === 'filtered' ?
              <XStack key='endsAfterFilter' w='100%' flexWrap='wrap' maw={800} px='$2' mx='auto' animation='standard' {...standardAnimation}>
                <Heading size='$5' mb='$3' my='auto'>Ends After</Heading>
                <Text ml='auto' my='auto' fontSize='$2' fontFamily='$body'>
                  <input type='datetime-local' min={supportDateInput(moment(0))} value={supportDateInput(moment(endsAfter))} onChange={(v) => setQueryEndsAfter(moment(v.target.value).toISOString(true))} style={{ padding: 10 }} />
                </Text>
              </XStack>
              : undefined}
          </AnimatePresence>
        </YStack>
      </StickyBox>
      {eventsState.loadStatus == 'loading' ? <StickyBox style={{ zIndex: 10, height: 0 }}>
        <YStack space="$1" opacity={0.92}>
          <Spinner size='large' color={navColor} scale={2}
            top={dimensions.height / 2 - 50}
          />
        </YStack>
      </StickyBox> : undefined}
      <YStack f={1} w='100%' jc="center" ai="center" p="$0" paddingHorizontal='$3' mt='$3' maw={800} space>

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
              </YStack>
            </>
          : undefined}
        {showScrollPreserver ? <YStack h={100000} /> : undefined}
      </YStack>
      <StickyCreateButton selectedGroup={selectedGroup} showEvents />
      {/* <StickyCreateButton /> */}
    </TabsNavigation>
  )
}
