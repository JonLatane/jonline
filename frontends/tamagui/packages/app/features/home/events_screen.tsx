import daygridPlugin from "@fullcalendar/daygrid";
import interactionPlugin from "@fullcalendar/interaction";
import listPlugin from "@fullcalendar/list";
import multimonthPlugin from "@fullcalendar/multimonth";
import FullCalendar from "@fullcalendar/react";
import timegridPlugin from "@fullcalendar/timegrid";
import { EventListingType, TimeFilter } from '@jonline/api';
import { momentLocalizer } from 'react-big-calendar';
import 'react-big-calendar/lib/css/react-big-calendar.css';


import { Adapt, AnimatePresence, Button, DateTimePicker, Dialog, Heading, Input, ScrollView, Sheet, Spinner, Text, XStack, YStack, dismissScrollPreserver, needsScrollPreservers, reverseStandardAnimation, standardAnimation, toProtoISOString, useMedia, useWindowDimensions } from '@jonline/ui';
import { FederatedEvent, JonlineServer, RootState, colorIntMeta, federateId, federatedId, selectAllServers, serializeTimeFilter, setShowBigCalendar, useRootSelector, useServerTheme } from 'app/store';
import React, { useEffect, useState } from 'react';
// import { DynamicCreateButton } from '../evepont/create_event_sheet';
import { Calendar as CalendarIcon, X as XIcon } from '@tamagui/lucide-icons';
import { SubnavButton } from 'app/components/subnav_button';
import { useAppDispatch, useAppSelector, useEventPages, useLocalConfiguration, usePaginatedRendering } from 'app/hooks';
import { setDocumentTitle, themedButtonBackground } from 'app/utils';
import moment from 'moment';
import FlipMove from 'react-flip-move';
import { createParam } from 'solito';
import EventCard from '../event/event_card';
import { AppSection } from '../navigation/features_navigation';
import { TabsNavigation, useTabsNavigationHeight } from '../navigation/tabs_navigation';
import { DynamicCreateButton } from './dynamic_create_button';
import { HomeScreenProps } from './home_screen';
import { PaginationIndicator, PaginationResetIndicator } from './pagination_indicator';

const { useParam, useUpdateParams } = createParam<{ endsAfter: string, search: string }>()
export function EventsScreen() {
  return <BaseEventsScreen />;
}

export type EventDisplayMode = 'upcoming' | 'all' | 'filtered';
export const BaseEventsScreen: React.FC<HomeScreenProps> = ({ selectedGroup }: HomeScreenProps) => {
  const mediaQuery = useMedia();
  const eventsState = useRootSelector((state: RootState) => state.events);

  const [showScrollPreserver, setShowScrollPreserver] = useState(needsScrollPreservers());

  const { server: currentServer, primaryColor, navColor, navTextColor, transparentBackgroundColor } = useServerTheme();
  const dimensions = useWindowDimensions();
  const [pageLoadTime] = useState<string>(moment(Date.now()).toISOString(true));
  // const [endsAfter, setEndsAfter] = useState<string>(pageLoadTime);
  const [queryEndsAfter, setQueryEndsAfter] = useParam('endsAfter');
  const [querySearch] = useParam('search');
  const updateParams = useUpdateParams();
  const [searchText, _setSearchText] = useState(querySearch ?? '');
  function setSearchText(text: string) {
    _setSearchText(text);
    updateParams({ search: text }, { web: { replace: true } });
  };
  const endsAfter = queryEndsAfter ?? moment(pageLoadTime).toISOString(true);
  // useEffect(() => {
  //   if (!queryEndsAfter) {
  //     setQueryEndsAfter(moment(pageLoadTime).toISOString(true));
  //   }
  // }, [endsAfter]);


  const displayMode = queryEndsAfter === undefined
    ? 'upcoming' as EventDisplayMode
    : moment(queryEndsAfter).unix() === 0
      ? 'all' as EventDisplayMode
      : 'filtered' as EventDisplayMode;
  const setDisplayMode = (mode: EventDisplayMode) => {
    switch (mode) {
      case 'upcoming':
        updateParams({
          endsAfter: undefined,
          search: undefined
        });
        break;
      case 'all':
        updateParams({
          endsAfter: moment(0).toISOString(true),
          search: undefined
        });
        break;
      case 'filtered':
        const search = searchText;
        if (displayMode === 'upcoming') {
          updateParams({
            endsAfter: moment(pageLoadTime).toISOString(true),
            search
          });
        } else if (displayMode === 'all') {
          updateParams({
            endsAfter: moment(pageLoadTime).toISOString(true),
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

  const allEvents = allEventsUnfiltered?.filter((e) =>
    displayMode === 'filtered'
      ? !searchText?.trim()
      || e.post?.title?.toLowerCase().includes(searchText.toLowerCase())
      : true) ?? [];

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
  const [modalInstanceId, setModalInstanceId] = useState<string | undefined>(undefined);
  const modalInstance = useAppSelector((state) => allEvents.find((e) => federateId(e.instances[0]?.id ?? '', e.serverHost) === modalInstanceId));
  // console.log('modalInstanceId', modalInstanceId, 'modalInstance', modalInstance);
  const setModalInstance = (e: FederatedEvent | undefined) => {
    setModalInstanceId(e ? federateId(e.instances[0]?.id ?? '', e.serverHost) : undefined);
  }

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
  const bigCalWidth = Math.max(minBigCalWidth, window.innerWidth - 40);
  const bigCalHeight = Math.max(minBigCalHeight, window.innerHeight - navigationHeight - 85);
  const starredPostIds = useAppSelector(state => state.app.starredPostIds);
  // const [bigCalWidth, setBigCalWidth] = useState(Math.max(minBigCalWidth, window.innerWidth));
  // const [bigCalHeight, setBigCalHeight] = useState(Math.max(minBigCalHeight, window.innerHeight - navigationHeight - 85));
  // useEffect(() => (window.innerWidth > minBigCalHeight)
  //   ? setBigCalWidth(window.innerWidth)
  //   : undefined, [bigCalWidth, window.innerWidth]);
  // useEffect(() => (window.innerHeight - navigationHeight - 85 > minBigCalHeight)
  //   ? setBigCalHeight(window.innerHeight - navigationHeight - 85)
  //   : undefined, [bigCalHeight, window.innerHeight, navigationHeight]);

  return (
    <TabsNavigation
      appSection={AppSection.EVENTS}
      selectedGroup={selectedGroup}
      groupPageForwarder={(groupIdentifier) => `/g/${groupIdentifier}/events`}
      withServerPinning
      showShrinkPreviews={!bigCalendar}
      loading={loadingEvents}
      topChrome={
        <YStack w='100%' px='$2' key='filter-toolbar'
        // backgroundColor={transparentBackgroundColor}
        >
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
              <>
                <YStack w='100%' px='$2' py='$2' key='search-toolbar'>
                  <XStack w='100%' ai='center' gap='$2' mx='$2'>
                    <Input placeholder='Search'
                      f={1}
                      value={searchText}
                      onChange={(e) => setSearchText(e.nativeEvent.text)} />
                    <Button circular disabled={searchText.length === 0} o={searchText.length === 0 ? 0.5 : 1} icon={XIcon} size='$2' onPress={() => setSearchText('')} mr='$2' />
                  </XStack>
                </YStack>
                <XStack key='endsAfterFilter' w='100%' flexWrap='wrap' maw={800} px='$2' mx='auto' ai='center'
                  animation='standard' {...standardAnimation}>
                  <Heading size='$5' mb='$3' my='auto'>Ends After</Heading>
                  <XStack ml='auto' my='auto'>
                    <DateTimePicker value={endsAfter} onChange={(v) => setQueryEndsAfter(v)} />
                  </XStack>
                </XStack>
              </>
              : undefined}
          </AnimatePresence>
        </YStack>
      }
      bottomChrome={<DynamicCreateButton selectedGroup={selectedGroup} showEvents />}
    >
      <YStack f={1} w='100%' jc="center" ai="center" mt={bigCalendar ? 0 : '$3'} px='$3' maw={maxWidth}>
        {/* <AnimatePresence>
         
        </AnimatePresence> */}
        <FlipMove style={{ width: '100%' }}>
          {bigCalendar
            ? allEvents.length === 0 ?
              loadingEvents || !firstPageLoaded
                ? <YStack key='bigcalendar-loading' width='100%' maw={600} jc="center" ai="center" mx='auto'>
                  <Spinner color={primaryColor} />
                  {/* <Heading size='$5' mb='$3'>Loading...</Heading> */}
                  <Heading size='$5' o={0.5} ta='center'>Loading events...</Heading>
                </YStack>
                : <YStack key='bigcalendar-no-events' width='100%' maw={600} jc="center" ai="center" mx='auto'>
                  <Heading size='$5' o={0.5} mb='$3'>No events found.</Heading>
                  <Heading size='$3' o={0.5} ta='center'>The events you're looking for may either not exist, not be visible to you, or be hidden by moderators.</Heading>
                </YStack>
              : <YStack
                key='calendar-rendering'
                // key={`calendar-rendering-${serializedTimeFilter}`} 
                mx='$1'
                animation='standard' {...reverseStandardAnimation}
                //  w='100%'

                width={bigCalWidth}
                height={bigCalHeight}
                p='$2'

                backgroundColor='whitesmoke'
                borderRadius='$3'>

                <Text fontFamily='$body' color='black' width='100%'>
                  <div
                    style={{
                      display: 'block',
                      width: bigCalWidth - 10,
                      height: bigCalHeight - 10,
                      // height: '100%'
                    }} >
                    <FullCalendar
                      key={`calendar-rendering-${serializedTimeFilter}-${window.innerWidth}-${window.innerHeight}-${navigationHeight}-${allEvents.length}`}
                      selectable
                      dateClick={({ date, view }) => {
                        view.calendar.changeView('listDay', date);
                      }}

                      headerToolbar={{
                        start: 'prev', end: 'next',
                        center: 'title',
                      }}
                      footerToolbar={{
                        start: 'today',
                        center: 'dayGridMonth,timeGridWeek,timeGridDay',
                        end: 'listMonth',
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
                        const starred = starredPostIds.includes(
                          federateId(event.instances[0]?.post?.id ?? 'invalid', event.serverHost)
                        );
                        return {
                          id: federateId(event.instances[0]?.id ?? '', event.serverHost),
                          // id: event.instances[0]?.id ?? '',
                          // serverHost: event.serverHost,
                          title: starred ? `⭐️ ${event.post?.title}` : event.post?.title,
                          color: serverColors[event.serverHost],
                          start: moment(event.instances[0]?.startsAt ?? 0).toDate(),
                          end: moment(event.instances[0]?.endsAt ?? 0).toDate()
                        }
                      })}
                      eventClick={(modelEvent) => {
                        setModalInstanceId(modelEvent.event.id);
                        // const { id: instanceId, serverHost } = parseFederatedId(modelEvent.event.id);
                        // const isPrimaryServer = serverHost === currentServer?.host;
                        // const detailsLinkId = !isPrimaryServer
                        //   ? federateId(instanceId, serverHost)
                        //   : instanceId;
                        // setModalInstanceId(detailsLinkId);
                        // const groupLinkId = selectedGroup ?
                        //   (selectedGroup?.serverHost !== currentServer?.host
                        //     ? federateId(selectedGroup.shortname, selectedGroup.serverHost)
                        //     : selectedGroup.shortname)
                        //   : undefined;
                        // const href = selectedGroup
                        //   ? `/g/${groupLinkId}/e/${detailsLinkId}`
                        //   : `/event/${detailsLinkId}`;
                        // window.location.pathname = href;
                      }}
                    />
                  </div>
                </Text>
                <Dialog
                  key={`modal-${modalInstanceId}`}
                  modal open={!!modalInstance}
                  onOpenChange={(o) => o ? null : setModalInstance(undefined)}>
                  {/* <Dialog.Trigger asChild>
                    <Button>Show Dialog</Button>
                  </Dialog.Trigger> */}

                  <Adapt when="sm" platform="touch">
                    <Sheet animation="medium" zIndex={200000} modal dismissOnSnapToBottom>
                      <Sheet.Frame padding="$4" gap="$4">
                        <Sheet.ScrollView>
                          {modalInstance
                            ? <EventCard event={modalInstance!} isPreview />
                            : undefined}
                        </Sheet.ScrollView>
                        {/* <Adapt.Contents /> */}
                      </Sheet.Frame>
                      <Sheet.Overlay
                        animation="lazy"
                        enterStyle={{ opacity: 0 }}
                        exitStyle={{ opacity: 0 }}
                      />
                    </Sheet>
                  </Adapt>

                  <Dialog.Portal>
                    <Dialog.Overlay
                      key="overlay"
                      animation="slow"
                      opacity={0.5}
                      enterStyle={{ opacity: 0 }}
                      exitStyle={{ opacity: 0 }}
                    />

                    <Dialog.Content
                      bordered
                      elevate
                      key="content"
                      animateOnly={['transform', 'opacity']}
                      animation='standard'
                      maw={bigCalWidth}
                      enterStyle={{ x: 0, y: -20, opacity: 0, scale: 0.9 }}
                      exitStyle={{ x: 0, y: 10, opacity: 0, scale: 0.95 }}
                      gap="$4"
                    >
                      {/* <Unspaced> */}
                      <YStack gap='$2'>
                        <Dialog.Close asChild>
                          <Button
                            ml='auto' mr='$3' size='$1'
                            circular
                            icon={XIcon}
                          />
                        </Dialog.Close>
                        <ScrollView f={1} >
                          {modalInstance
                            ? <EventCard event={modalInstance!} isPreview ignoreShrinkPreview />
                            : undefined}
                        </ScrollView>
                      </YStack>
                    </Dialog.Content>
                  </Dialog.Portal>
                </Dialog>

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
            : renderInColumns
              ? <YStack gap='$2' width='100%' key='multi-column-rendering'>
                <PaginationResetIndicator {...pagination} />
                <XStack mx='auto' jc='center' flexWrap='wrap'>
                  <AnimatePresence>

                    {/* <FlipMove style={{ display: 'flex', flexWrap: 'wrap' }}> */}

                    {firstPageLoaded || allEvents.length > 0
                      ? allEvents.length === 0
                        ? <XStack key='no-events-found' style={{ width: '100%', margin: 'auto' }} animation='standard' {...standardAnimation}>
                          <YStack width='100%' maw={600} jc="center" ai="center" mx='auto'>
                            <Heading size='$5' mb='$3'>No events found.</Heading>
                            <Heading size='$3' ta='center'>The events you're looking for may either not exist, not be visible to you, or be hidden by moderators.</Heading>
                          </YStack>
                        </XStack>
                        : undefined
                      : undefined}
                    {paginatedEvents.map((event) => {
                      return <XStack key={federateId(event.instances[0]?.id ?? '', currentServer)} animation='standard' {...standardAnimation}>
                        <XStack w={eventCardWidth}
                          mx='$1' px='$1'>
                          <EventCard event={event} isPreview />
                        </XStack>
                      </XStack>;
                    })}
                    {/* </FlipMove> */}
                  </AnimatePresence>
                </XStack>
                <PaginationIndicator {...pagination} />
              </YStack>
              : <>

                <div key='reset' style={{ width: '100%', margin: 'auto' }}>
                  <PaginationResetIndicator {...pagination} />
                </div>

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
                <div key='pagedown' style={{ width: '100%', margin: 'auto' }}>
                  <PaginationIndicator {...pagination} />
                </div>
              </>}
        </FlipMove>

        {showScrollPreserver && !bigCalendar ? <YStack h={100000} /> : undefined}
      </YStack >
    </TabsNavigation >
  )
}

const localizer = momentLocalizer(moment);
