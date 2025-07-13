import { EventListingType, TimeFilter } from '@jonline/api';
import { momentLocalizer } from 'react-big-calendar';
import 'react-big-calendar/lib/css/react-big-calendar.css';


import { AnimatePresence, Button, DateTimePicker, Heading, Input, Spinner, XStack, YStack, dismissScrollPreserver, needsScrollPreservers, standardAnimation, toProtoISOString, useDebounceValue, useMedia } from '@jonline/ui';
import { useServerTheme } from 'app/store';
import React, { useEffect, useMemo, useState } from 'react';
// import { DynamicCreateButton } from '../evepont/create_event_sheet';
import { CalendarArrowDown, Calendar as CalendarIcon, CalendarPlus, X as XIcon } from '@tamagui/lucide-icons';
import { SubnavButton } from 'app/components/subnav_button';
import { useAppSelector, useEventPages, useLocalConfiguration, usePaginatedRendering, usePinnedAccountsAndServers } from 'app/hooks';
import { useBigCalendar } from "app/hooks/configuration_hooks";
import { useUpcomingEventsFilter } from 'app/hooks/use_upcoming_events_filter';
import { setDocumentTitle, themedButtonBackground } from 'app/utils';
import moment from 'moment';
import { createParam } from 'solito';
import { useLink } from 'solito/link';
import { EventListingLarge } from '../event/event_listing_large';
import { AppSection } from '../navigation/features_navigation';
import { TabsNavigation } from '../navigation/tabs_navigation';
import { useParamState } from '../people/people_screen';
import { AutoAnimatedList } from '../post';
import { DynamicCreateButton } from './dynamic_create_button';
import { HomeScreenProps } from './home_screen';
import { EventCalendarExporter } from '../event/event_calendar_exporter';

const { useParam, useUpdateParams } = createParam<{ endsAfter: string, search: string }>()
export function EventsScreen() {
  return <BaseEventsScreen />;
}

export type EventDisplayMode = 'upcoming' | 'all' | 'filtered';
export const BaseEventsScreen: React.FC<HomeScreenProps> = ({ selectedGroup }: HomeScreenProps) => {
  const mediaQuery = useMedia();
  const { shrinkPreviews } = useLocalConfiguration();
  const { bigCalendar, setBigCalendar } = useBigCalendar();

  // const eventsState = useRootSelector((state: RootState) => state.events);

  const [showScrollPreserver, setShowScrollPreserver] = useState(needsScrollPreservers());

  const { server: currentServer, primaryColor, primaryAnchorColor, navColor, navTextColor, transparentBackgroundColor } = useServerTheme();
  // const dimensions = useWindowDimensions();
  const [queryEndsAfter, setQueryEndsAfter] = useParam('endsAfter');
  const [querySearchParam] = useParam('search');
  // const querySearch = querySearchParam ?? '';
  const updateParams = useUpdateParams();
  const [searchText, setSearchText] = useParamState(querySearchParam, '');
  const debouncedSearchText = useDebounceValue(
    searchText.trim().toLowerCase(),
    300
  );
  useEffect(() => {
    if (querySearchParam ?? '' !== debouncedSearchText)
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
  const displayMode: EventDisplayMode = queryEndsAfter === undefined
    ? 'upcoming'
    : moment(queryEndsAfter).unix() === 0 && querySearchParam === undefined
      ? 'all'
      : 'filtered';
  // console.log('displayMode', displayMode, moment(queryEndsAfter).unix())
  const setDisplayMode = (mode: EventDisplayMode) => {
    switch (mode) {
      case 'upcoming':
        updateParams({
          endsAfter: undefined,//upcomingEndsAfter,
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
        if (displayMode === 'upcoming') {
          updateParams({
            endsAfter: moment(upcomingEndsAfter).toISOString(false),
            search: ''
          });
        } else if (displayMode === 'all') {
          updateParams({
            endsAfter: moment(1000).toISOString(false),
            search: ''
          });
        } else {
          updateParams({
            search: searchText
          });
        }
        break;
    }
  };
  const timeFilter: TimeFilter = { endsAfter: endsAfter ? toProtoISOString(endsAfter) : undefined };
  // console.log('timeFilter', timeFilter);
  const documentTitle = (() => {
    const serverName = currentServer?.serverConfiguration?.serverInfo?.name || '...';
    const title = selectedGroup ? `${selectedGroup.name} | ${serverName}` : serverName;
    return `Events | ${title}`
  })()
  useEffect(() => {
    setDocumentTitle(documentTitle)
  }, [documentTitle, window.location.search]);

  const { results: allEventsUnfiltered, loading: loadingEvents, reload: reloadEvents, hasMorePages, firstPageLoaded } =
    useEventPages(EventListingType.ALL_ACCESSIBLE_EVENTS, selectedGroup, { timeFilter });

  const [pageLoadTime] = useState<string>(moment(Date.now()).toISOString(true));
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
  const pinnedAccountsAndServers = usePinnedAccountsAndServers()
  const selectedServers = useMemo(() => pinnedAccountsAndServers.map(s => s.server).filter(s => !!s), [pinnedAccountsAndServers]);


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
  // const calendarSubcriptionLink = useLink({ href: `https://${currentServer?.host}/calendar.ics` });
  const topChromePadding = mediaQuery.gtXs ? '$3' : '$2';
  const topChrome = <YStack w='100%' px={mediaQuery.gtXs ? '$2' : '$1'} key='filter-toolbar'>
    <XStack w='100%' ai='center'>
      <Button onPress={() => setBigCalendar(!bigCalendar)} px={topChromePadding}
        icon={CalendarIcon}
        transparent
        {...themedButtonBackground(
          bigCalendar ? navColor : undefined, bigCalendar ? navTextColor : undefined)} />

      {displayModeButton('upcoming', 'Upcoming')}
      {displayModeButton('all', 'All')}
      {displayModeButton('filtered', 'Filtered')}
      {/* <Button target='_blank' {...calendarSubcriptionLink} icon={CalendarArrowDown} transparent px={topChromePadding} /> */}
      <EventCalendarExporter tiny showSubscriptions={{ servers: selectedServers }} />

      <DynamicCreateButton showEvents
        button={(onPress) =>
          <Button onPress={onPress}
            px={topChromePadding}
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

  const eventListing = <EventListingLarge events={allEvents} />;

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
        px={mediaQuery.gtXxs ? '$3' : 0}
        maw={maxWidth}>
        <AutoAnimatedList style={{ width: '100%', /*display: 'flex', flexDirection: 'column', alignItems: 'center'*/ }}>
          {/* <EventListingLarge events={allEvents} /> */}
          {eventListing}
          {showScrollPreserver && !bigCalendar ? <div key='scroll-preserver' style={{ height: 100000 }} /> : undefined}
        </AutoAnimatedList>

      </YStack >
    </TabsNavigation >
  )
}

const localizer = momentLocalizer(moment);
