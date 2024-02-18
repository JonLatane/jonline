import { EventListingType, TimeFilter } from '@jonline/api';
import { Calendar as BigCalendar, momentLocalizer } from 'react-big-calendar'
import 'react-big-calendar/lib/css/react-big-calendar.css';
import FullCalendar from "@fullcalendar/react";
import interactionPlugin from "@fullcalendar/interaction";
import daygridPlugin from "@fullcalendar/daygrid";
import timegridPlugin from "@fullcalendar/timegrid";
import multimonthPlugin from "@fullcalendar/multimonth";
import listPlugin from "@fullcalendar/list";


import { AnimatePresence, Text, Button, DateTimePicker, Heading, XStack, YStack, dismissScrollPreserver, needsScrollPreservers, standardAnimation, toProtoISOString, useMedia, useWindowDimensions } from '@jonline/ui';
import { JonlineServer, RootState, colorIntMeta, federateId, federatedId, parseFederatedId, selectAllServers, setShowBigCalendar, useRootSelector, useServerTheme } from 'app/store';
import React, { useEffect, useState } from 'react';
// import { DynamicCreateButton } from '../evepont/create_event_sheet';
import { SubnavButton } from 'app/components/subnav_button';
import { useAppDispatch, useAppSelector, useEventPages, useLocalConfiguration, usePaginatedRendering } from 'app/hooks';
import { setDocumentTitle, themedButtonBackground } from 'app/utils';
import moment from 'moment';
import FlipMove from 'react-flip-move';
import { createParam } from 'solito';
import EventCard from '../event/event_card';
import { AppSection } from '../navigation/features_navigation';
import { TabsNavigation } from '../navigation/tabs_navigation';
import { DynamicCreateButton } from './dynamic_create_button';
import { HomeScreenProps } from './home_screen';
import { PaginationIndicator, PaginationResetIndicator } from './pagination_indicator';
import { Calendar as CalendarIcon } from '@tamagui/lucide-icons';

const { useParam } = createParam<{ endsAfter: string }>()
export function EventsScreen() {
  return <BaseEventsScreen />;
}

export type EventDisplayMode = 'upcoming' | 'all' | 'filtered';
export const BaseEventsScreen: React.FC<HomeScreenProps> = ({ selectedGroup }: HomeScreenProps) => {
  const mediaQuery = useMedia();
  const eventsState = useRootSelector((state: RootState) => state.events);

  const [showScrollPreserver, setShowScrollPreserver] = useState(needsScrollPreservers());

  const { server: currentServer, primaryColor, primaryTextColor, navColor, navTextColor } = useServerTheme();
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


  const navigationHeight = document.getElementById('jonline-top-navigation')?.clientHeight ?? 0;
  const timeFilter: TimeFilter = { endsAfter: endsAfter ? toProtoISOString(endsAfter) : undefined };
  // console.log('timeFilter', timeFilter);
  useEffect(() => {
    const serverName = currentServer?.serverConfiguration?.serverInfo?.name || '...';
    const title = selectedGroup ? `${selectedGroup.name} | ${serverName}` : serverName;
    setDocumentTitle(`Events | ${title}`)
  });

  const { results: allEvents, loading: loadingEvents, reload: reloadEvents, hasMorePages, firstPageLoaded } =
    useEventPages(EventListingType.ALL_ACCESSIBLE_EVENTS, selectedGroup, { timeFilter });

  const renderInColumns = mediaQuery.gtXs;
  const numberOfColumns = mediaQuery.gtXxxl ? 6
    : mediaQuery.gtXl ? 5
      : mediaQuery.gtLg ? 4
        : mediaQuery.gtMd ? 3
          : 2;
  const pagination = usePaginatedRendering(allEvents, renderInColumns
    ? mediaQuery.gtXxxl ? 12
      : mediaQuery.gtXl ? 10
        : mediaQuery.gtLg ? 8 : 6
    : 7);

  const paginatedEvents = pagination.results;


  useEffect(() => {
    if (firstPageLoaded) {
      dismissScrollPreserver(setShowScrollPreserver);
    }
  }, [firstPageLoaded]);
  useEffect(pagination.reset, [queryEndsAfter]);

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
  // console.log('numberOfColumns', numberOfColumns, 'renderInColumns', renderInColumns);
  const eventCardWidth = renderInColumns
    ? (window.innerWidth - 50 - (20 * numberOfColumns)) / numberOfColumns
    : undefined;
  const maxWidth = 2000;
  // useEffect(() => { }, [pinnedServersHeight]);
  // const [bigCalendar, setBigCalendar] = useState(false);

  const dispatch = useAppDispatch();
  const { showBigCalendar: bigCalendar, showPinnedServers } = useLocalConfiguration();
  const setBigCalendar = (v: boolean) => dispatch(setShowBigCalendar(v));
  const serverColors = useAppSelector((state) => selectAllServers(state.servers).reduce(
    (result, server: JonlineServer) => {
      if (server.serverConfiguration?.serverInfo?.colors?.primary) {
        result[server.host] = colorIntMeta(server.serverConfiguration.serverInfo.colors.primary).color;

      }
      return result;
    }, {}
  ));

  const [_showPinnedServers, _setShowPinnedServers] = useState(showPinnedServers);
  useEffect(() => {
    _setShowPinnedServers(showPinnedServers);
  }, [showPinnedServers]);

  return (
    <TabsNavigation
      appSection={AppSection.EVENTS}
      selectedGroup={selectedGroup}
      groupPageForwarder={(groupIdentifier) => `/g/${groupIdentifier}/events`}
      withServerPinning
      showShrinkPreviews={!bigCalendar}
      loading={loadingEvents}
      topChrome={
        <YStack w='100%' px='$2' key='filter-toolbar'>
          <XStack w='100%' ai='center'>

            <Button onPress={() => setBigCalendar(!bigCalendar)}
              icon={CalendarIcon}
              {...themedButtonBackground(
                bigCalendar ? navColor : undefined, bigCalendar ? navTextColor : undefined)} />

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
              <XStack key='endsAfterFilter' w='100%' flexWrap='wrap' maw={800} px='$2' mx='auto' ai='center'
                animation='standard' {...standardAnimation}>
                <Heading size='$5' mb='$3' my='auto'>Ends After</Heading>
                <XStack ml='auto' my='auto'>
                  <DateTimePicker value={endsAfter} onChange={(v) => setQueryEndsAfter(v)} />
                </XStack>
              </XStack>
              : undefined}
          </AnimatePresence>
        </YStack>
      }
      bottomChrome={<DynamicCreateButton selectedGroup={selectedGroup} showEvents />}
    >
      <YStack f={1} w='100%' jc="center" ai="center" mt={bigCalendar ? 0 : '$3'} px='$3' maw={maxWidth}>
        <FlipMove>
          {bigCalendar ?
            // @ts-nocheck
            <YStack key='calendar-rendering' mx='$1'
              //  w='100%'

              width={window.innerWidth}
              height={window.innerHeight - navigationHeight - 85}
              px='$2'

              backgroundColor={'white'}
              borderRadius='$3'>

              <Text fontFamily='$body' color='black' width='100%'>
                <div
                  style={{
                    width: window.innerWidth - 10,
                    height: window.innerHeight - navigationHeight - 85
                    // height: '100%'
                  }} >
                  <FullCalendar
                    selectable
                    headerToolbar={{
                      start: 'prev', end: 'next',
                      center: 'title',       
                    }}
                    footerToolbar={{
                      start: 'today',
                      center: '',
                      end: 'dayGridMonth,timeGridWeek,timeGridDay,listWeek',
                    }}
                    plugins={[
                      daygridPlugin,
                      timegridPlugin,
                      multimonthPlugin,
                      listPlugin,
                      interactionPlugin
                    ]}
                    height='100%'
                    events={allEvents.map((event) => {
                      return {
                        id: federateId(event.instances[0]?.id ?? '', event.serverHost),
                        // id: event.instances[0]?.id ?? '',
                        // serverHost: event.serverHost,
                        title: event.post?.title,
                        color: serverColors[event.serverHost],
                        start: moment(event.instances[0]?.startsAt ?? 0).toDate(),
                        end: moment(event.instances[0]?.endsAt ?? 0).toDate()
                      }
                    })}
                    eventClick={(modelEvent) => {
                      const { id, serverHost } = parseFederatedId(modelEvent.event.id);
                      const isPrimaryServer = serverHost === currentServer?.host;
                      const detailsLinkId = !isPrimaryServer
                        ? federateId(id, serverHost)
                        : id;
                      const groupLinkId = selectedGroup ?
                        (selectedGroup?.serverHost !== currentServer?.host
                          ? federateId(selectedGroup.shortname, selectedGroup.serverHost)
                          : selectedGroup.shortname)
                        : undefined;
                      const href = selectedGroup
                        ? `/g/${groupLinkId}/e/${detailsLinkId}`
                        : `/event/${detailsLinkId}`;
                      window.location.pathname = href;
                    }}
                  />
                </div>
              </Text>
              {/* <Text fontFamily='$body' color='black' width='100%'>

                <BigCalendar localizer={localizer}
                  // events={[{title: 'test', start: new Date(), end: new Date()}]}
                  events={allEvents.map((event) => {
                    return {
                      title: event.post?.title,
                      color: 'red',
                      start: moment(event.instances[0]?.startsAt ?? 0).toDate(),
                      end: moment(event.instances[0]?.endsAt ?? 0).toDate()
                    }
                  })}
                  startAccessor="start"
                  endAccessor="end"
                  style={{ width: window.innerWidth, height: window.innerHeight - navigationHeight - 230}} />
              </Text> */}
            </YStack>
            // @ts-nocheck
            : renderInColumns ?
              <YStack gap='$2' key='multi-column-rendering'>
                <PaginationResetIndicator {...pagination} />
                <XStack mx='auto' gap='$2' flexWrap='wrap' jc='center'>
                  {/* <AnimatePresence> */}

                  <FlipMove style={{ display: 'flex', flexWrap: 'wrap' }}>

                    {firstPageLoaded || allEvents.length > 0
                      ? allEvents.length === 0
                        ? <div key='no-events-found' style={{ width: '100%', margin: 'auto' }}>
                          <YStack width='100%' maw={600} jc="center" ai="center" mx='auto'>
                            <Heading size='$5' mb='$3'>No events found.</Heading>
                            <Heading size='$3' ta='center'>The events you're looking for may either not exist, not be visible to you, or be hidden by moderators.</Heading>
                          </YStack>
                        </div>
                        : undefined
                      : undefined}
                    {paginatedEvents.map((event) => {
                      return <span key={federateId(event.instances[0]?.id ?? '', currentServer)}>
                        <XStack w={eventCardWidth}
                          mx='$1' px='$1'>
                          <EventCard event={event} isPreview />
                        </XStack>
                      </span>;
                    })}
                  </FlipMove>
                  {/* </AnimatePresence> */}
                </XStack>
                <PaginationIndicator {...pagination} />
              </YStack>
              : <YStack key='single-column-rendering' w='100%' ac='center' ai='center' jc='center' gap='$2'>

                <PaginationResetIndicator {...pagination} />
                <FlipMove>

                  {firstPageLoaded || allEvents.length > 0
                    ? allEvents.length === 0
                      ? <div key='no-events-found' style={{ width: '100%', margin: 'auto' }}>
                        <YStack width='100%' maw={600} jc="center" ai="center" mx='auto'>
                          <Heading size='$5' mb='$3'>No events found.</Heading>
                          <Heading size='$3' ta='center'>The events you're looking for may either not exist, not be visible to you, or be hidden by moderators.</Heading>
                        </YStack>
                      </div>
                      : undefined
                    : undefined}
                  {paginatedEvents.map((event) => {
                    return <div key={`event-preview-${federatedId(event)}-${event.instances[0]!.id}`}>
                      <XStack w='100%'>
                        <EventCard event={event} key={federateId(event.instances[0]?.id ?? '', currentServer)} isPreview />
                      </XStack>
                    </div>
                  })}
                </FlipMove>
                <PaginationIndicator {...pagination} />
              </YStack>}
        </FlipMove>

        {showScrollPreserver && !bigCalendar ? <YStack h={100000} /> : undefined}
      </YStack >
    </TabsNavigation >
  )
}

const localizer = momentLocalizer(moment);
