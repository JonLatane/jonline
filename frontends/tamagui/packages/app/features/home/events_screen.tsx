import { EventListingType, TimeFilter } from '@jonline/api';
import { AnimatePresence, Heading, Spinner, Text, XStack, YStack, dismissScrollPreserver, needsScrollPreservers, standardAnimation, useMedia, useWindowDimensions } from '@jonline/ui';
import { RootState, federateId, useRootSelector, useServerTheme } from 'app/store';
import React, { useEffect, useState } from 'react';
import StickyBox from "react-sticky-box";
// import { StickyCreateButton } from '../evepont/create_event_sheet';
import { SubnavButton } from 'app/components/subnav_button';
import { NavigationContextConsumer } from 'app/contexts';
import { useEventPages, usePaginatedRendering } from 'app/hooks';
import { setDocumentTitle } from 'app/utils';
import moment from 'moment';
import { createParam } from 'solito';
import { standardHorizontalAnimation } from '../../../ui/src/animations';
import { supportDateInput, toProtoISOString } from '../event/create_event_sheet';
import EventCard from '../event/event_card';
import { AppSection } from '../navigation/features_navigation';
import { TabsNavigation } from '../navigation/tabs_navigation';
import { HomeScreenProps } from './home_screen';
import { PaginationIndicator } from './pagination_indicator';
import { StickyCreateButton } from './sticky_create_button';

const { useParam } = createParam<{ endsAfter: string }>()
export function EventsScreen() {
  return <BaseEventsScreen />;
}

export type EventDisplayMode = 'upcoming' | 'all' | 'filtered';
export const BaseEventsScreen: React.FC<HomeScreenProps> = ({ selectedGroup }: HomeScreenProps) => {
  const mediaQuery = useMedia();
  const eventsState = useRootSelector((state: RootState) => state.events);

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

  const { results: allEvents, loading: loadingEvents, reload: reloadEvents, hasMorePages, firstPageLoaded } =
    useEventPages(EventListingType.ALL_ACCESSIBLE_EVENTS, selectedGroup);

  const pagination = usePaginatedRendering(allEvents, 7);
  const paginatedEvents = pagination.results;


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
          // console.log('setting ends after to undefined');
          setQueryEndsAfter(undefined);
        }
        break;
      case 'all':
        if (queryEndsAfter != moment(0).toISOString(true)) {
          // console.log('setting ends after to 0');
          setQueryEndsAfter(moment(0).toISOString(true));
        }
        break;
      case 'filtered':
        if (queryEndsAfter === undefined) {
          // console.log('setting ends after to page load time');
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
  const renderInColumns = mediaQuery.gtXs;
  const eventCardWidth = renderInColumns
    // ? mediaQuery.gtXl
    //   ? (window.innerWidth - 40) / 5
    ? mediaQuery.gtLg
      ? (window.innerWidth - 80) / 4
      : mediaQuery.gtMd
        ? (window.innerWidth - 60) / 3
        : (window.innerWidth - 40) / 2
    //310
    : undefined;
  const maxWidth = 2000;
  // useEffect(() => { }, [pinnedServersHeight]);

  return (
    <TabsNavigation
      appSection={AppSection.EVENTS}
      selectedGroup={selectedGroup}
      groupPageForwarder={(groupIdentifier) => `/g/${groupIdentifier}/events`}
      withServerPinning
    >
      <NavigationContextConsumer>
        {(navContext) => <StickyBox key='filters' offsetTop={56 + (navContext?.pinnedServersHeight ?? 0)} className='blur' style={{ width: '100%', zIndex: 10 }}>
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
        </StickyBox>}
      </NavigationContextConsumer>
      {loadingEvents ? <StickyBox style={{ zIndex: 10, height: 0 }}>
        <YStack space="$1" opacity={0.92}>
          <Spinner size='large' color={navColor} scale={2}
            top={dimensions.height / 2 - 50}
          />
        </YStack>
      </StickyBox> : undefined}
      <YStack f={1} w='100%' jc="center" ai="center" p="$0" paddingHorizontal='$3' mt='$3' px='$3' maw={maxWidth} space>

        {firstPageLoaded
          ? allEvents.length == 0
            ? <YStack width='100%' maw={600} jc="center" ai="center">
              <Heading size='$5' mb='$3'>No events found.</Heading>
              <Heading size='$3' ta='center'>The events you're looking for may either not exist, not be visible to you, or be hidden by moderators.</Heading>
            </YStack>
            : renderInColumns ?
              <YStack space='$2'>
                <XStack mx='auto' space='$2' flexWrap='wrap'>
                  <AnimatePresence>
                    {paginatedEvents.map((event) => {
                      return <XStack w={eventCardWidth} key={federateId(event.instances[0]?.id ?? '', server)}
                        animation='standard' {...standardHorizontalAnimation} mx='$1'>
                        <EventCard event={event} isPreview horizontal />
                      </XStack>;
                    })}
                  </AnimatePresence>
                </XStack>
                <PaginationIndicator {...pagination} />
              </YStack>
              : <YStack w='100%' ac='center' ai='center' jc='center' space='$2'>
                {paginatedEvents.map((event) => {
                  return <XStack animation='standard' {...standardAnimation}>
                    <EventCard event={event} key={federateId(event.instances[0]?.id ?? '', server)} isPreview />
                  </XStack>
                })}
                <PaginationIndicator {...pagination} />
              </YStack>
          : undefined}
        {showScrollPreserver ? <YStack h={100000} /> : undefined}
      </YStack>
      <StickyCreateButton selectedGroup={selectedGroup} showEvents />
      {/* <StickyCreateButton /> */}
    </TabsNavigation>
  )
}
