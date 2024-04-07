import daygridPlugin from "@fullcalendar/daygrid";
import interactionPlugin from "@fullcalendar/interaction";
import listPlugin from "@fullcalendar/list";
import multimonthPlugin from "@fullcalendar/multimonth";
import FullCalendar from "@fullcalendar/react";
import timegridPlugin from "@fullcalendar/timegrid";
import { EventListingType, TimeFilter } from '@jonline/api';
import { momentLocalizer } from 'react-big-calendar';
import 'react-big-calendar/lib/css/react-big-calendar.css';


import { Adapt, AnimatePresence, Button, DateTimePicker, Dialog, Heading, Input, ScrollView, Sheet, Spinner, Text, XStack, YStack, dismissScrollPreserver, needsScrollPreservers, reverseStandardAnimation, standardAnimation, toProtoISOString, useDebounceValue, useMedia, useWindowDimensions } from '@jonline/ui';
import { FederatedEvent, JonlineServer, RootState, colorIntMeta, federateId, federatedId, selectAllServers, serializeTimeFilter, setShowBigCalendar, useRootSelector, useServerTheme } from 'app/store';
import React, { useEffect, useMemo, useState } from 'react';
// import { DynamicCreateButton } from '../evepont/create_event_sheet';
import { Calendar as CalendarIcon, CalendarPlus, X as XIcon } from '@tamagui/lucide-icons';
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
import { serverHost } from '../../store/federation';
import { useHideNavigation } from "../navigation/use_hide_navigation";
import { PageChooser } from "./page_chooser";

const { useParam, useUpdateParams } = createParam<{ endsAfter: string, search: string }>()
export function EventsScreen() {
  return <BaseEventsScreen />;
}

export type EventDisplayMode = 'upcoming' | 'all' | 'filtered';
export const BaseEventsScreen: React.FC<HomeScreenProps> = ({ selectedGroup }: HomeScreenProps) => {
  const mediaQuery = useMedia();
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
  const endsAfter = queryEndsAfter ?? moment(pageLoadTime).toISOString(true);
  // useEffect(() => {
  //   if (!queryEndsAfter) {
  //     setQueryEndsAfter(moment(pageLoadTime).toISOString(true));
  //   }
  // }, [endsAfter]);


  const displayMode: EventDisplayMode = queryEndsAfter === undefined
    ? 'upcoming'
    : moment(queryEndsAfter).unix() === 0 && querySearch === undefined
      ? 'all'
      : 'filtered';
  console.log('displayMode', displayMode, moment(queryEndsAfter).unix())
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

  const allEvents = useMemo(
    () => allEventsUnfiltered?.filter((e) =>
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

  const pageSize = renderInColumns
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

  const dispatch = useAppDispatch();
  const { showBigCalendar: bigCalendar, showPinnedServers } = useLocalConfiguration();
  const setBigCalendar = (v: boolean) => dispatch(setShowBigCalendar(v));
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
              transparent
              {...themedButtonBackground(
                bigCalendar ? navColor : undefined, bigCalendar ? navTextColor : undefined)} />

            {displayModeButton('upcoming', 'Upcoming')}
            {displayModeButton('all', 'All')}
            {displayModeButton('filtered', 'Filtered')}

            <DynamicCreateButton selectedGroup={selectedGroup} showEvents
              button={(onPress) =>
                <Button onPress={onPress}
                  icon={CalendarPlus}
                  transparent
                  {...themedButtonBackground(undefined, primaryAnchorColor)} />} />
          </XStack>
          <AnimatePresence>
            {displayMode === 'filtered' ?
              <>
                <YStack w='100%' px='$2' py='$2' key='search-toolbar'>
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
    // bottomChrome={<DynamicCreateButton selectedGroup={selectedGroup} showEvents />}
    >
      <YStack f={1} w='100%' jc="center" ai="center" mt={bigCalendar ? 0 : '$3'}
        px='$3'
        maw={maxWidth}>
        <FlipMove style={{ width: '100%' }}>
          {bigCalendar
            ? <div key='bigcalendar-rendering'>
              <YStack
                // key={`calendar-rendering-${serializedTimeFilter}`} 
                mx='$1'
                animation='standard' {...reverseStandardAnimation}
                //  w='100%'

                width={bigCalWidth}
                height={bigCalHeight}
                // p='$2'

                backgroundColor='whitesmoke'
                borderRadius='$3'>

                <Text fontFamily='$body' color='black' width='100%'>
                  <div
                    style={{
                      display: 'block',
                      width: bigCalWidth,//- 10,
                      height: bigCalHeight,// - 10,
                      // height: '100%'
                    }} >
                    <FullCalendar

                      key={`calendar-rendering-${serializedTimeFilter
                        }-${window.innerWidth
                        }-${window.innerHeight
                        }-${navigationHeight
                        }-${hideNavigation
                        }-${allEvents.length}`}
                      selectable
                      dateClick={({ date, view }) => {
                        view.calendar.changeView('listDay', date);
                      }}

                      {...mediaQuery.xShort && mediaQuery.gtXs
                        ? {
                          headerToolbar: {
                            start: 'prev,next, today',
                            center: 'title',
                            end: 'dayGridMonth,timeGridWeek,timeGridDay, listMonth',
                          },
                          // footerToolbar: {
                          //   start: 'today',
                          //   center: 'dayGridMonth,timeGridWeek,timeGridDay',
                          //   end: 'listMonth',
                          // }
                        } : {
                          headerToolbar: {
                            start: 'prev', end: 'next',
                            center: 'title',
                          },
                          footerToolbar: {
                            start: 'today',
                            center: 'dayGridMonth,timeGridWeek,timeGridDay',
                            end: 'listMonth',
                          }
                        }}
                      plugins={[
                        daygridPlugin,
                        timegridPlugin,
                        multimonthPlugin,
                        listPlugin,
                        interactionPlugin
                      ]}
                      // width='100%'
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

                  {/* <Adapt when="sm" platform="touch">
                    <Sheet animation="medium" zIndex={200000} modal dismissOnSnapToBottom>
                      <Sheet.Frame padding="$4" gap="$4">
                        <Sheet.ScrollView>
                          {modalInstance
                            ? <EventCard event={modalInstance!} isPreview />
                            : undefined}
                        </Sheet.ScrollView>
                      </Sheet.Frame>
                      <Sheet.Overlay
                        animation="lazy"
                        enterStyle={{ opacity: 0 }}
                        exitStyle={{ opacity: 0 }}
                      />
                    </Sheet>
                  </Adapt> */}

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
                      mah={bigCalHeight}
                      enterStyle={{ x: 0, y: -20, opacity: 0, scale: 0.9 }}
                      exitStyle={{ x: 0, y: 10, opacity: 0, scale: 0.95 }}
                      gap="$4"
                    >
                      {/* <Unspaced> */}
                      <YStack gap='$2' h='100%'>
                        <Dialog.Close asChild>
                          <Button
                            ml='auto' mr='$3' size='$1'
                            circular
                            icon={XIcon}
                          />
                        </Dialog.Close>
                        <ScrollView f={1}>
                          {modalInstance
                            ? <EventCard event={modalInstance!} isPreview ignoreShrinkPreview />
                            : undefined}
                        </ScrollView>
                      </YStack>
                    </Dialog.Content>
                  </Dialog.Portal>
                </Dialog>
              </YStack>
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
                <div key='pages-bottom' id='pages-top'>
                  <PageChooser {...pagination} />
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

                <div key='pagedown' style={{ width: '100%', margin: 'auto' }}>
                  <PageChooser {...pagination} pageTopId='pages-top' />
                </div>
              ]}
          {showScrollPreserver && !bigCalendar ? <div key='scroll-preserver' style={{ height: 100000 }} /> : undefined}
        </FlipMove>

      </YStack >
    </TabsNavigation >
  )
}

const localizer = momentLocalizer(moment);
