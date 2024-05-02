import { EventListingType, TimeFilter } from '@jonline/api';
import { momentLocalizer } from 'react-big-calendar';
import 'react-big-calendar/lib/css/react-big-calendar.css';


import { AnimatePresence, Button, DateTimePicker, Heading, Input, Spinner, XStack, YStack, dismissScrollPreserver, needsScrollPreservers, reverseStandardAnimation, standardAnimation, toProtoISOString, useDebounceValue, useMedia, useWindowDimensions } from '@jonline/ui';
import { FederatedEvent, JonlineServer, RootState, colorIntMeta, federateId, federatedId, selectAllServers, serializeTimeFilter, useRootSelector, useServerTheme } from 'app/store';
import React, { useEffect, useMemo, useState } from 'react';
// import { DynamicCreateButton } from '../evepont/create_event_sheet';
import { Calendar as CalendarIcon, CalendarPlus, X as XIcon } from '@tamagui/lucide-icons';
import { SubnavButton } from 'app/components/subnav_button';
import { useAppDispatch, useAppSelector, useEventPages, useLocalConfiguration, usePaginatedRendering } from 'app/hooks';
import { useBigCalendar } from "app/hooks/configuration_hooks";
import { setDocumentTitle, themedButtonBackground } from 'app/utils';
import moment from 'moment';
import FlipMove from 'react-flip-move';
import { createParam } from 'solito';
import EventCard from '../event/event_card';
import { AppSection } from '../navigation/features_navigation';
import { TabsNavigation, useTabsNavigationHeight } from '../navigation/tabs_navigation';
import { useHideNavigation } from "../navigation/use_hide_navigation";
import { DynamicCreateButton } from './dynamic_create_button';
import { EventsFullCalendar } from "./events_full_calendar";
import { HomeScreenProps } from './home_screen';
import { PageChooser } from "./page_chooser";
import { useUpcomingEventsFilter } from 'app/hooks/use_upcoming_events_filter';

const { useParam, useUpdateParams } = createParam<{ endsAfter: string, search: string }>()
export function EventsScreen() {
  return <BaseEventsScreen />;
}

export type EventDisplayMode = 'upcoming' | 'all' | 'filtered';
export const BaseEventsScreen: React.FC<HomeScreenProps> = ({ selectedGroup }: HomeScreenProps) => {
  const dispatch = useAppDispatch();
  const mediaQuery = useMedia();
  const { showPinnedServers, shrinkPreviews } = useLocalConfiguration();
  const { bigCalendar, setBigCalendar } = useBigCalendar();

  const eventsState = useRootSelector((state: RootState) => state.events);

  const [showScrollPreserver, setShowScrollPreserver] = useState(needsScrollPreservers());

  const { server: currentServer, primaryColor, primaryAnchorColor, navColor, navTextColor, transparentBackgroundColor } = useServerTheme();
  const dimensions = useWindowDimensions();
  const [pageLoadTime] = useState<string>(moment(Date.now()).toISOString(true));
  // const [endsAfter, setEndsAfter] = useState<string>(pageLoadTime);
  const [queryEndsAfter, setQueryEndsAfter] = useParam('endsAfter');
  const [querySearch] = useParam('search');
  const updateParams = useUpdateParams();
  const [searchText, setSearchText] = useState(querySearch ?? '');
  const debouncedSearchText = useDebounceValue(
    searchText.trim().toLowerCase(),
    1000
  );
  useEffect(() => {
    updateParams({ search: debouncedSearchText }, { web: { replace: true } });
  }, [debouncedSearchText])
  // useEffect(() => {
  //   if (!queryEndsAfter) {
  //     setQueryEndsAfter(moment(pageLoadTime).toISOString(true));
  //   }
  // }, [endsAfter]);


  const upcomingTimeFilter: TimeFilter = useUpcomingEventsFilter();
  const upcomingEndsAfter = moment(upcomingTimeFilter.endsAfter).toISOString(false);


  const endsAfter = queryEndsAfter ?? upcomingEndsAfter;
  const displayMode: EventDisplayMode = queryEndsAfter === undefined || queryEndsAfter == upcomingEndsAfter
    ? 'upcoming'
    : moment(queryEndsAfter).unix() === 0 && querySearch === undefined
      ? 'all'
      : 'filtered';
  // console.log('displayMode', displayMode, moment(queryEndsAfter).unix())
  const setDisplayMode = (mode: EventDisplayMode) => {
    switch (mode) {
      case 'upcoming':
        updateParams({
          endsAfter: upcomingEndsAfter,
          search: undefined
        });
        break;
      case 'all':
        updateParams({
          endsAfter: moment(0).toISOString(false),
          search: undefined
        });
        break;
      case 'filtered':
        const search = searchText ?? '';
        if (displayMode === 'upcoming') {
          updateParams({
            endsAfter: moment(pageLoadTime).toISOString(false),
            search
          });
        } else if (displayMode === 'all') {
          updateParams({
            endsAfter: moment(1000).toISOString(false),
            search
          });
        } else {
          updateParams({
            search
          });
        }
        break;
    }
  };
  const timeFilter: TimeFilter = { endsAfter: endsAfter ? toProtoISOString(endsAfter) : undefined };
  // console.log('timeFilter', timeFilter);
  useEffect(() => {
    const serverName = currentServer?.serverConfiguration?.serverInfo?.name || '...';
    const title = selectedGroup ? `${selectedGroup.name} | ${serverName}` : serverName;
    setDocumentTitle(`Events | ${title}`)
  });

  const { results: allEventsUnfiltered, loading: loadingEvents, reload: reloadEvents, hasMorePages, firstPageLoaded } =
    useEventPages(EventListingType.ALL_ACCESSIBLE_EVENTS, selectedGroup, { timeFilter });

  const allEventsWithNonBigCalendarUpcomingFilter = displayMode === 'upcoming' && !bigCalendar
    ? allEventsUnfiltered.filter(e => moment(e.instances[0]?.endsAt).isAfter(pageLoadTime))
    : allEventsUnfiltered

  const allEvents = useMemo(
    () => allEventsWithNonBigCalendarUpcomingFilter?.filter((e) =>
      displayMode === 'filtered'
        ? !debouncedSearchText
        || e.post?.title?.toLowerCase().includes(debouncedSearchText)
        : true) ?? [],
    [
      //TODO there must be something better than length
      // to cheaply "hash" unfiltered events on. At the very least,
      // include pinned servers/accounts in the hash?
      allEventsUnfiltered.length,
      useAppSelector(state => state.accounts.pinnedServers),
      timeFilter.toString(),
      displayMode,
      debouncedSearchText,
    ]
  );

  const numberOfColumns = mediaQuery.gtXxxxl ? 6
    : mediaQuery.gtXxl ? 5
      : mediaQuery.gtLg ? 4
        : mediaQuery.gtMd ? 3
          : mediaQuery.gtXs ? 2 : 1;

  const renderInColumns = numberOfColumns > 1;

  const widthAdjustedPageSize = renderInColumns
    ? numberOfColumns * 2
    : 8;

  const pageSize = renderInColumns && shrinkPreviews
    ? mediaQuery.gtMdHeight
      ? Math.round(widthAdjustedPageSize * 2)
      : mediaQuery.gtShort
        ? Math.round(widthAdjustedPageSize * 1.5)
        : widthAdjustedPageSize
    : widthAdjustedPageSize;

  const pagination = usePaginatedRendering(
    allEvents,
    pageSize
  );
  const paginatedEvents = pagination.results;

  useEffect(() => {
    if (firstPageLoaded) {
      dismissScrollPreserver(setShowScrollPreserver);
    }
  }, [firstPageLoaded]);

  useEffect(pagination.reset, [queryEndsAfter, debouncedSearchText]);

  function displayModeButton(associatedDisplayMode: EventDisplayMode, title: string) {
    return <SubnavButton title={title}
      // icon={icon}
      selected={displayMode === associatedDisplayMode}
      select={() => {
        setDisplayMode(associatedDisplayMode);
        window.scrollTo({ top: 0, behavior: 'smooth' });
      }} />;
  }
  const eventCardWidth = renderInColumns
    ? (window.innerWidth - 50 - (20 * numberOfColumns)) / numberOfColumns
    : undefined;
  const maxWidth = 2000;

  const [modalInstanceId, setModalInstanceId] = useState<string | undefined>(undefined);
  const modalInstance = useAppSelector((state) => allEvents.find((e) => federateId(e.instances[0]?.id ?? '', e.serverHost) === modalInstanceId));
  // console.log('modalInstanceId', modalInstanceId, 'modalInstance', modalInstance);
  const setModalInstance = (e: FederatedEvent | undefined) => {
    setModalInstanceId(e ? federateId(e.instances[0]?.id ?? '', e.serverHost) : undefined);
  }
  const hideNavigation = useHideNavigation();

  const serverColors = useAppSelector((state) => selectAllServers(state.servers).reduce(
    (result, server: JonlineServer) => {
      if (server.serverConfiguration?.serverInfo?.colors?.primary) {
        result[server.host] = colorIntMeta(server.serverConfiguration.serverInfo.colors.primary).color;

      }
      return result;
    }, {}
  ));

  const navigationHeight = useTabsNavigationHeight();
  const serializedTimeFilter = serializeTimeFilter(timeFilter);
  const minBigCalWidth = 150;
  const minBigCalHeight = 150;
  const bigCalWidth = Math.min(maxWidth - 30, Math.max(minBigCalWidth, window.innerWidth - 30));
  const bigCalHeight = Math.max(minBigCalHeight, window.innerHeight - navigationHeight - 20);
  const starredPostIds = useAppSelector(state => state.app.starredPostIds);

  const oneLineFilterBar = mediaQuery.xShort && mediaQuery.gtXs;
  const filterBarFlex = oneLineFilterBar ? { f: 1 } : { w: '100%' };

  const searchFilterBar =
    <YStack {...filterBarFlex} px='$2' py='$2' key='search-toolbar'>
      <XStack w='100%' ai='center' gap='$2' mx='$2'>
        <Input placeholder='Search'
          f={1}
          value={searchText}
          onChange={(e) => setSearchText(e.nativeEvent.text)} />
        <XStack position='absolute' right={55}
          pointerEvents="none"
          animation='standard'
          o={searchText !== debouncedSearchText ? 1 : 0}
        >
          <Spinner />
        </XStack>
        <Button circular disabled={searchText.length === 0} o={searchText.length === 0 ? 0.5 : 1} icon={XIcon} size='$2' onPress={() => setSearchText('')} mr='$2' />
      </XStack>
    </YStack>;
  const endsAfterFilterBar =
    <XStack key='endsAfterFilter' pb={oneLineFilterBar ? undefined : '$2'}  {...filterBarFlex} flexWrap={oneLineFilterBar ? undefined : 'wrap'} maw={800} px='$2' mx='auto' ai='center'
      animation='standard' {...standardAnimation}>
      <Heading size='$3' mb='$3' my='auto'>Ends After</Heading>
      <XStack ml='auto' my='auto'>
        <DateTimePicker value={endsAfter} onChange={(v) => setQueryEndsAfter(v)} />
      </XStack>
    </XStack>;
  const filterBar = <>
    {searchFilterBar}
    {endsAfterFilterBar}
  </>;
  const responsiveFilterBar = oneLineFilterBar
    ? <XStack w='100%' ai='center'>
      {filterBar}
    </XStack>
    : filterBar;
  const topChrome = <YStack w='100%' px='$2' key='filter-toolbar'>
    <XStack w='100%' ai='center'>
      <Button onPress={() => setBigCalendar(!bigCalendar)}
        icon={CalendarIcon}
        transparent
        {...themedButtonBackground(
          bigCalendar ? navColor : undefined, bigCalendar ? navTextColor : undefined)} />

      {displayModeButton('upcoming', 'Upcoming')}
      {displayModeButton('all', 'All')}
      {displayModeButton('filtered', 'Filtered')}

      <DynamicCreateButton showEvents
        button={(onPress) =>
          <Button onPress={onPress}
            icon={CalendarPlus}
            transparent
            {...themedButtonBackground(undefined, primaryAnchorColor)} />} />
    </XStack>
    <AnimatePresence>
      {displayMode === 'filtered'
        ? responsiveFilterBar
        : undefined}
    </AnimatePresence>
  </YStack>;
  return (
    <TabsNavigation
      appSection={AppSection.EVENTS}
      selectedGroup={selectedGroup}
      groupPageForwarder={(groupIdentifier) => `/g/${groupIdentifier}/events`}
      groupPageReverse='/events'
      withServerPinning
      showShrinkPreviews={!bigCalendar}
      loading={loadingEvents}
      topChrome={topChrome}
    // bottomChrome={<DynamicCreateButton selectedGroup={selectedGroup} showEvents />}
    >
      <YStack f={1} w='100%' jc="center" ai="center"
        mt={bigCalendar ? mediaQuery.xShort ? '$15' : 0 : '$3'}
        mb={bigCalendar && mediaQuery.xShort ? '$15' : 0}
        // mb={bigCalendar && mediaQuery.xShort ? '$15' : 0}
        px='$3'
        maw={maxWidth}>
        <FlipMove style={{ width: '100%' }}>
          {bigCalendar
            ? <div key='bigcalendar-rendering'>
              <EventsFullCalendar events={allEvents} />
            </div>
            : renderInColumns
              ? [
                <div key='pages-top' id='pages-top'>
                  <PageChooser {...pagination} />
                </div>,
                <div key={`multi-column-rendering-page-${pagination.page}`}>
                  {/* <YStack gap='$2' width='100%' > */}
                  <XStack mx='auto' jc='center' flexWrap='wrap'>
                    {/* <AnimatePresence> */}
                    {firstPageLoaded || allEvents.length > 0
                      ? allEvents.length === 0
                        ? <XStack key='no-events-found' style={{ width: '100%', margin: 'auto' }}
                        // animation='standard' {...standardAnimation}
                        >
                          <YStack width='100%' maw={600} jc="center" ai="center" mx='auto'>
                            <Heading size='$5' mb='$3' o={0.5}>No events found.</Heading>
                          </YStack>
                        </XStack>
                        : undefined
                      : undefined}
                    {paginatedEvents.map((event) => {
                      return <XStack key={federateId(event.instances[0]?.id ?? '', currentServer)}
                        animation='standard' {...standardAnimation}
                      >
                        <XStack w={eventCardWidth}
                          mx='$1' px='$1'>
                          <EventCard event={event} isPreview />
                        </XStack>
                      </XStack>;
                    })}
                    {/* </FlipMove> */}
                    {/* </AnimatePresence> */}
                  </XStack>
                  {/* <PageChooser {...pagination} pageTopId='pages-top' /> */}
                  {/* <PaginationIndicator {...pagination} /> */}
                  {/* </YStack> */}
                </div>,
                <div key='pages-bottom' id='pages-bottom'>
                  <PageChooser {...pagination} pageTopId='pages-top' showResultCounts
                    entityName={{ singular: 'event', plural: 'events' }} />
                </div>,
              ]
              : [
                <div id='pages-top' key='pagest-top'>
                  <PageChooser {...pagination} />
                </div>,

                firstPageLoaded || allEvents.length > 0
                  ? allEvents.length === 0
                    ? <div key='no-events-found' style={{ width: '100%', margin: 'auto' }}>
                      <YStack width='100%' maw={600} jc="center" ai="center" mx='auto'>
                        <Heading size='$5' o={0.5} mb='$3'>No events found.</Heading>
                        {/* <Heading size='$2' o={0.5} ta='center'>The events you're looking for may either not exist, not be visible to you, or be hidden by moderators.</Heading> */}
                      </YStack>
                    </div>
                    : undefined
                  : undefined,

                paginatedEvents.map((event) => {
                  return <div key={`event-preview-${federatedId(event)}-${event.instances[0]!.id}`}>
                    <XStack w='100%'>
                      <EventCard event={event} key={federateId(event.instances[0]?.id ?? '', currentServer)} isPreview />
                    </XStack>
                  </div>
                }),

                <div key='pages-bottom' style={{ width: '100%', margin: 'auto' }}>
                  <PageChooser {...pagination} pageTopId='pages-top' showResultCounts
                    entityName={{ singular: 'event', plural: 'events' }} />
                </div>
              ]}
          {showScrollPreserver && !bigCalendar ? <div key='scroll-preserver' style={{ height: 100000 }} /> : undefined}
        </FlipMove>

      </YStack >
    </TabsNavigation >
  )
}

const localizer = momentLocalizer(moment);
