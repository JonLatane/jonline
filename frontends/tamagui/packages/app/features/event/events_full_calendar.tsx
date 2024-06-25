import daygridPlugin from "@fullcalendar/daygrid";
import interactionPlugin from "@fullcalendar/interaction";
import listPlugin from "@fullcalendar/list";
import multimonthPlugin from "@fullcalendar/multimonth";
import FullCalendar from "@fullcalendar/react";
import timegridPlugin from "@fullcalendar/timegrid";
import { Calendar as BigCalendar, momentLocalizer } from 'react-big-calendar';
import 'react-big-calendar/lib/css/react-big-calendar.css';
// import { , momentLocalizer } from "react-big-calendar";
import { DayPilotCalendar } from "@daypilot/daypilot-lite-react";


import { AnimatePresence, Button, Dialog, Heading, ScrollView, Text, XStack, YStack, needsScrollPreservers, reverseStandardAnimation, standardAnimation, useDebounceValue, useMedia, useWindowDimensions } from '@jonline/ui';
import { FederatedEvent, JonlineServer, RootState, colorIntMeta, colorMeta, federateId, federatedId, parseFederatedId, selectAllServers, setShowBigCalendar, useServerTheme } from 'app/store';
import React, { useCallback, useEffect, useMemo, useState } from 'react';
// import { DynamicCreateButton } from '../evepont/create_event_sheet';
import { ChevronLeft, ChevronRight, X as XIcon } from '@tamagui/lucide-icons';
import { Selector, useAppDispatch, useAppSelector, useLocalConfiguration, usePaginatedRendering } from 'app/hooks';
import moment from 'moment';
import { createParam } from 'solito';
import EventCard from './event_card';
import { useTabsNavigationHeight } from '../navigation/tabs_navigation';
import { useHideNavigation } from "../navigation/use_hide_navigation";
import { createSelector } from "@reduxjs/toolkit";

export function useScreenWidthAndHeight() {
  const minBigCalWidth = 150;
  const minBigCalHeight = 150;
  const maxWidth = 2000;

  const navigationHeight = useTabsNavigationHeight();
  const screenWidth = Math.min(maxWidth - 30, Math.max(minBigCalWidth, window.innerWidth - 30));

  const screenHeight =
    Math.max(minBigCalHeight, window.innerHeight - navigationHeight - 20);

  return { screenWidth, screenHeight };
}
const { useParam, useUpdateParams } = createParam<{ endsAfter: string, search: string }>()
export type EventsFullCalendarProps = {
  // selectedGroup?: FederatedGroup;
  events: FederatedEvent[];
  weeklyOnly?: boolean;
  dayOnly?: boolean;
  width?: string | number;
  scrollToTime?: string;
  disableSelection?: boolean;
  // timeFilter: TimeFilter;
}

const selectServerColors = (
): Selector<{}> =>
  createSelector(
    [(state: RootState) => selectAllServers(state.servers).reduce(
      (result, server: JonlineServer) => {
        if (server.serverConfiguration?.serverInfo?.colors?.primary) {
          result[server.host] = colorIntMeta(server.serverConfiguration.serverInfo.colors.primary).color;
  
        }
        return result;
      }, {}
    )],
    (data) => data
  );

export const EventsFullCalendar: React.FC<EventsFullCalendarProps> = ({
  events: allEvents,
  weeklyOnly,
  width,
  scrollToTime: scrollToTimeParam,
  disableSelection
}: EventsFullCalendarProps) => {
  const dispatch = useAppDispatch();
  const mediaQuery = useMedia();
  const { showBigCalendar: bigCalendar, showPinnedServers, shrinkPreviews } = useLocalConfiguration();

  // const eventsState = useAppSelector((state: RootState) => state.events);

  const [showScrollPreserver, setShowScrollPreserver] = useState(needsScrollPreservers());

  const { server: currentServer, primaryColor, primaryAnchorColor, navColor, navLightColor, navTextColor, transparentBackgroundColor } = useServerTheme();
  const dimensions = useWindowDimensions();
  const [pageLoadTime] = useState<string>(moment(Date.now()).toISOString(true));
  // const [endsAfter, setEndsAfter] = useState<string>(pageLoadTime);
  const [queryEndsAfter, setQueryEndsAfter] = useParam('endsAfter');
  const [querySearchParam] = useParam('search');
  const querySearch = querySearchParam ?? '';
  const updateParams = useUpdateParams();
  const [searchText, setSearchText] = useState(querySearch);
  const debouncedSearchText = useDebounceValue(
    searchText.trim().toLowerCase(),
    1000
  );
  const hasNewEvent = allEvents.some(e => !e.id);
  useEffect(() => {
    if (querySearch !== debouncedSearchText) {
      updateParams({ search: debouncedSearchText }, { web: { replace: true } });
    }
  }, [debouncedSearchText])
  const endsAfter = queryEndsAfter ?? moment(pageLoadTime).toISOString(true);
  // useEffect(() => {
  //   if (!queryEndsAfter) {
  //     setQueryEndsAfter(moment(pageLoadTime).toISOString(true));
  //   }
  // }, [endsAfter]);

  // const timeFilter: TimeFilter = { endsAfter: endsAfter ? toProtoISOString(endsAfter) : undefined };
  // console.log('timeFilter', timeFilter);
  // useEffect(() => {
  //   const serverName = currentServer?.serverConfiguration?.serverInfo?.name || '...';
  //   const title = selectedGroup ? `${selectedGroup.name} | ${serverName}` : serverName;
  //   setDocumentTitle(`Events | ${title}`)
  // });

  // const { results: allEventsUnfiltered, loading: loadingEvents, reload: reloadEvents, hasMorePages, firstPageLoaded } =
  //   useEventPages(EventListingType.ALL_ACCESSIBLE_EVENTS, selectedGroup, { timeFilter });

  // const numberOfColumns = mediaQuery.gtXxxxl ? 6
  //   : mediaQuery.gtXxl ? 5
  //     : mediaQuery.gtLg ? 4
  //       : mediaQuery.gtMd ? 3
  //         : mediaQuery.gtXs ? 2 : 1;

  // const renderInColumns = numberOfColumns > 1;

  // const widthAdjustedPageSize = renderInColumns
  //   ? numberOfColumns * 2
  //   : 8;

  // const pageSize = renderInColumns && shrinkPreviews
  //   ? mediaQuery.gtMdHeight
  //     ? Math.round(widthAdjustedPageSize * 2)
  //     : mediaQuery.gtShort
  //       ? Math.round(widthAdjustedPageSize * 1.5)
  //       : widthAdjustedPageSize
  // : widthAdjustedPageSize;

  // const pagination = usePaginatedRendering(
  //   allEvents,
  //   pageSize
  // );
  // const paginatedEvents = pagination.results;

  // useEffect(() => {
  //   if (firstPageLoaded) {
  //     dismissScrollPreserver(setShowScrollPreserver);
  //   }
  // }, [firstPageLoaded]);

  // useEffect(pagination.reset, [queryEndsAfter, debouncedSearchText]);

  // const setBigCalendar = (v: boolean) => dispatch(setShowBigCalendar(v));
  const [modalInstanceId, setModalInstanceId] = useState<string | undefined>(undefined);
  // console.log('EventsFullCalendar', { modalInstanceId })
  const modalInstance = useMemo(
    () => allEvents.find((e) => federateId(e.instances[0]?.id ?? '', e.serverHost) === modalInstanceId),
    [modalInstanceId, allEvents]
  );
  // console.log('modalInstanceId', modalInstanceId, 'modalInstance', modalInstance);
  const hideNavigation = useHideNavigation();

  const serverColors = useAppSelector(selectServerColors());

  const navigationHeight = useTabsNavigationHeight();
  // const serializedTimeFilter = serializeTimeFilter(timeFilter);
  const minBigCalWidth = 150;
  const minBigCalHeight = 150;
  const maxWidth = 2000;

  const { screenWidth: bigCalWidth, screenHeight: borderedScreenHeight } = useScreenWidthAndHeight();
  const bigCalHeight = Math.min(
    weeklyOnly ? 350 : Number.MAX_SAFE_INTEGER,
    borderedScreenHeight
  );
  const starredPostIds = useAppSelector(state => state.app.starredPostIds);

  const startTimes = allEvents.map((event) => {
    const instance = event.instances[0];
    const startsAt = moment(instance?.startsAt ?? 0);
    const startsAtTime = startsAt.format('HH:mm:ss');
    return startsAtTime;
  });
  const modeStartTime = mode(startTimes);
  const earliestDate = moment.min(
    allEvents.map((event) => moment(event.instances[0]?.startsAt ?? 0).startOf('day'))
  );
  const latestDate = moment.max(
    allEvents.map((event) => moment(event.instances[0]?.endsAt ?? 0).endOf('day'))
  );
  const scrollToTime = (scrollToTimeParam
    ? moment(scrollToTimeParam)
    : //modalInstance
    //  ? moment(modalInstance?.instances[0]?.startsAt)
    //  : 
    moment()
  ).subtract(30, 'minutes');
  const { calendarImplementation } = useLocalConfiguration();
  // const [calendarImplementation]: 'fullcalendar' | 'big-calendar' = 'big-calendar';
  const convertedEvents = allEvents.map((event) => {
    const starred = starredPostIds.includes(
      federateId(event.instances[0]?.post?.id ?? 'invalid', event.serverHost)
    );
    return {
      id: federateId(event.instances[0]?.id ?? '', event.serverHost),
      title: starred ? `⭐️ ${event.post?.title}` : event.post?.title,
      color: serverColors[event.serverHost],
      style: {
        backgroundColor: serverColors[event.serverHost],
        color: colorMeta(serverColors[event.serverHost]).textColor,
        // borderRadius: 10,
        // borderColor: 'blue',
      },
      start: moment(event.instances[0]?.startsAt ?? 0).toDate(),
      end: moment(event.instances[0]?.endsAt ?? 0).toDate()
    }
  });
  const renderingKey = `calendar-rendering-${window.innerWidth
    }-${window.innerHeight
    }-${navigationHeight
    }-${hideNavigation
    }-${allEvents.length
    }-${scrollToTime}`;

  const isEmpty = allEvents.length === 0;

  const sortedEvents = useMemo(
    () => allEvents.sort((a, b) => moment(a.instances[0]?.startsAt ?? 0).unix() - moment(b.instances[0]?.startsAt ?? 0).unix()),
    [allEvents.map(e => federateId(e.instances[0]?.id ?? '', e.serverHost))]
  );
  const findNeighborEvent = useCallback((offset: number) => {
    if (modalInstance) {
      const index = sortedEvents.findIndex((e) => e.instances[0]?.id === modalInstance.instances[0]?.id && e.serverHost === modalInstance.serverHost);
      return sortedEvents[index + offset];
    }
  }, [
    modalInstance ? federateId(modalInstance.instances[0]?.id ?? '', modalInstance.serverHost) : undefined,
    sortedEvents.map(e => federateId(e.instances[0]?.id ?? '', e.serverHost))
  ]);
  const nextEvent = useMemo(() => findNeighborEvent(1), [findNeighborEvent]);
  const prevEvent = useMemo(() => findNeighborEvent(-1), [findNeighborEvent]);


  // <div key={modalInstance?.id} onKeyDown={modalInstance
  //   ? (e) => {
  //     if (e.key === 'ArrowRight' && nextEvent) {
  //       setModalInstanceId(federateId(nextEvent.instances[0]!.id, nextEvent.serverHost));
  //     } else if (e.key === 'ArrowLeft' && prevEvent) {
  //       setModalInstanceId(federateId(prevEvent.instances[0]!.id, prevEvent.serverHost));
  //     }
  //   }
  //   : undefined} />
  // const nextEventId = nextEvent ? federateId(nextEvent.instances[0]!.id, nextEvent.serverHost) : undefined;
  // const prevEventId = prevEvent ? federateId(prevEvent.instances[0]!.id, prevEvent.serverHost) : undefined;
  // useEffect(() => {
  //   const handleKeyDown = (e: KeyboardEvent) => {
  //     if (e.key === 'ArrowRight' && nextEvent) {
  //       console.log('right');
  //       setModalInstanceId(nextEventId);
  //     } else if (e.key === 'ArrowLeft' && prevEvent) {
  //       console.log('left');
  //       setModalInstanceId(prevEventId);
  //     }

  //   };
  //   document.addEventListener('keydown', handleKeyDown, true);

  //   return () => {
  //     document.removeEventListener('keydown', handleKeyDown);
  //   };

  // }, [nextEventId, prevEventId]);
  return (<>

    <YStack zi={1}
      // onKeyPress={undefined}
      // key={`calendar-rendering-${serializedTimeFilter}`} 
      mx='$1'
      animation='standard' {...reverseStandardAnimation}
      //  w='100%'

      width={width ?? bigCalWidth}
      height={bigCalHeight}
      // p='$2'

      backgroundColor='whitesmoke'
      borderRadius='$3'>

      {isEmpty
        ? <YStack zi={2} position='absolute' top={100} left='50%'
          transform='translate(-50%, 0)'
        >
          <Heading color='black' size='$12' ta='center'>No Events.</Heading>
        </YStack>
        : undefined}
      <Text fontFamily='$body' color='black' width='100%'
        pointerEvents={isEmpty ? 'none' : undefined}
        opacity={isEmpty ? 0.4 : 1}>
        <div
          style={{
            display: 'block',
            width: width ?? bigCalWidth,//- 10,
            height: bigCalHeight,// - 10,
            // height: '100%'
          }} >

          {calendarImplementation === 'fullcalendar' //|| calendarImplementation === undefined
            ? <FullCalendar

              key={renderingKey}
              selectable
              dateClick={({ date, view }) => {
                view.calendar.changeView('listDay', date);
              }}
              // scrollTime={modeStartTime}
              scrollTime={scrollToTime.format('HH:mm:ss')}
              {...weeklyOnly
                ? {
                  headerToolbar: {
                    start: 'prev,next',
                    center: 'title',
                    end: mediaQuery.gtXs ? 'today' : undefined
                    // end: 'dayGridMonth,timeGridWeek,timeGridDay, listMonth',
                  },
                }
                : mediaQuery.xShort && mediaQuery.gtXs
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
              plugins={weeklyOnly ?
                [
                  // daygridPlugin,
                  timegridPlugin,
                  // multimonthPlugin,
                  // listPlugin,
                  // interactionPlugin
                ] : [
                  daygridPlugin,
                  timegridPlugin,
                  multimonthPlugin,
                  listPlugin,
                  interactionPlugin
                ]}
              // width='100%'
              height='100%'
              events={convertedEvents}
              eventClick={disableSelection ? undefined : (modelEvent) => {
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

            : calendarImplementation === 'big-calendar' || calendarImplementation === undefined
              ? <YStack w='100%' h='100%'>
                <BigCalendar
                  // key={renderingKey}
                  // key={`calendar-rendering-${scrollToTime}`}
                  localizer={localizer}

                  // defaultDate={new Date()}
                  defaultView={weeklyOnly ? 'week' : undefined}
                  views={weeklyOnly ? ['week'] : undefined}//mediaQuery.gtSm ? undefined : ['month', 'week', 'agenda']}
                  formats={{
                    // timeGutterFormat: weeklyOnly ? ' ' : undefined,//'h'
                    timeGutterFormat: mediaQuery.gtXxs ? 'ha' : ' '

                  }}

                  events={allEvents.map((event) => {
                    const starred = starredPostIds.includes(
                      federateId(event.instances[0]?.post?.id ?? 'invalid', event.serverHost)
                    );
                    return {
                      id: federateId(event.instances[0]?.id ?? '', event.serverHost),
                      serverHost: event.serverHost,
                      title: starred ? `⭐️ ${event.post?.title}` : event.post?.title,
                      selected: true,
                      start: moment(event.instances[0]?.startsAt ?? 0).toDate(),
                      end: moment(event.instances[0]?.endsAt ?? 0).toDate()
                    }
                  })}
                  scrollToTime={scrollToTime.toDate()}
                  defaultDate={scrollToTime.toDate()}
                  eventPropGetter={(event) => {
                    // console.log('BigCalendar EventPropGetter', event);
                    const serverEventId = parseFederatedId(event.id).id;
                    return {
                      style: {
                        backgroundColor: hasNewEvent && serverEventId
                          ? `${serverColors[event.serverHost]}33`
                          : serverColors[event.serverHost],
                        // opacity: hasNewEvent && !event.id ? 0.5 : 1,
                        color: colorMeta(serverColors[event.serverHost]).textColor,
                        fontSize: mediaQuery.gtXxs ? undefined : '11px'
                      }
                    }
                  }}
                  onSelectEvent={disableSelection ? undefined : (modelEvent) => {
                    setModalInstanceId(modelEvent.id);
                  }}
                  dayPropGetter={(date) => {
                    return {
                      style: {
                        // borderColor: 'black',
                        backgroundColor: moment(date).isBefore(earliestDate)
                          || moment(date).isAfter(latestDate)
                          ? '#F0F0F0'
                          : moment(date).startOf('day').unix() === moment().startOf('day').unix()
                            ? `${navLightColor}44`
                            : '#FFFFFF'
                      }
                    }

                  }}
                  style={{ width: '100%', height: '100%' }}
                />
              </YStack>
              : calendarImplementation === 'daypilot'
                ? <YStack h='100%' overflow="hidden">
                  <DayPilotCalendar
                    viewType={"Week"}
                    // startDate={"2024-09-07"}
                    timeRangeSelectedHandling={"Disabled"}
                    events={allEvents.map((event) => {
                      const starred = starredPostIds.includes(
                        federateId(event.instances[0]?.post?.id ?? 'invalid', event.serverHost)
                      );
                      return {
                        id: federateId(event.instances[0]?.id ?? '', event.serverHost),
                        text: starred ? `⭐️ ${event.post?.title}` : event.post?.title,
                        barColor: serverColors[event.serverHost],
                        start: moment(event.instances[0]?.startsAt ?? 0).utc(false).toDate(),
                        end: moment(event.instances[0]?.endsAt ?? 0).utc(false).toDate()
                      }
                    })}
                    onEventClick={disableSelection ? undefined : (args: any) => {
                      console.log('DayPilotCalendar onEvent Click', args);
                      // debugger;
                      setModalInstanceId(args?.e?.data?.id);
                    }}
                    // height='100%'
                    // heightSpec='Parent100Pct'

                    style={{ width: '100%', height: '100%', overflow: 'hidden' }}
                  // onEventClick={onEventClick}
                  // controlRef={setCalendar}
                  />
                </YStack>
                : undefined}

        </div>
      </Text>
    </YStack>
    <Dialog modal open={!!modalInstance} onOpenChange={(o) => o ? null : setModalInstanceId(undefined)}>

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
          // animateOnly={['transform', 'opacity']}
          animation='standard'
          // maw={bigCalWidth}
          w={Math.min(800, bigCalWidth)}
          mah={borderedScreenHeight}
          enterStyle={{ x: 0, y: -20, opacity: 0, scale: 0.9 }}
          exitStyle={{ x: 0, y: 10, opacity: 0, scale: 0.95 }}
          gap="$4"
        >
          {/* <Unspaced> */}
          <YStack gap='$2' h='100%'>
            <XStack w='100%'>
              <Button
                ml='$3' size='$2'
                circular
                icon={ChevronLeft}
                disabled={!prevEvent}
                o={prevEvent ? 1 : 0.5}
                onPress={() => setModalInstanceId(federateId(prevEvent!.instances[0]!.id, prevEvent!.serverHost))}
              />
              <Button
                ml='$3' size='$2'
                circular
                icon={ChevronRight}
                disabled={!nextEvent}
                o={nextEvent ? 1 : 0.5}
                onPress={() => setModalInstanceId(federateId(nextEvent!.instances[0]!.id, nextEvent!.serverHost))}
              />
              <Dialog.Close asChild>
                <Button
                  ml='auto' mr='$3' size='$2'
                  circular
                  icon={XIcon}
                />
              </Dialog.Close>
            </XStack>
            {/* <YStack w='100%' my='auto' f={1}> */}
            <ScrollView f={1}>
              {modalInstance
                ? <EventCard key={modalInstance?.id} event={modalInstance!} isPreview ignoreShrinkPreview />
                : undefined}
            </ScrollView>
            {/* </YStack> */}
          </YStack>
        </Dialog.Content>
      </Dialog.Portal>
    </Dialog>
  </>
  )
}

const localizer = momentLocalizer(moment);

function mode(arr: string[]): string | undefined {
  const numMapping = {};
  let greatestFreq = 0;
  let mode: string | undefined;
  arr.forEach(function findMode(v) {
    numMapping[v] = (numMapping[v] || 0) + 1;

    if (greatestFreq < numMapping[v]) {
      greatestFreq = numMapping[v];
      mode = v;
    }
  });
  return mode;
}
