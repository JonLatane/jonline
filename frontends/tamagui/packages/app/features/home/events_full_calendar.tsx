import daygridPlugin from "@fullcalendar/daygrid";
import interactionPlugin from "@fullcalendar/interaction";
import listPlugin from "@fullcalendar/list";
import multimonthPlugin from "@fullcalendar/multimonth";
import FullCalendar from "@fullcalendar/react";
import timegridPlugin from "@fullcalendar/timegrid";
import { momentLocalizer } from 'react-big-calendar';
import 'react-big-calendar/lib/css/react-big-calendar.css';


import { Button, Dialog, ScrollView, Text, YStack, needsScrollPreservers, reverseStandardAnimation, useDebounceValue, useMedia, useWindowDimensions } from '@jonline/ui';
import { FederatedEvent, JonlineServer, RootState, colorIntMeta, federateId, selectAllServers, setShowBigCalendar, useRootSelector, useServerTheme } from 'app/store';
import React, { useEffect, useState } from 'react';
// import { DynamicCreateButton } from '../evepont/create_event_sheet';
import { X as XIcon } from '@tamagui/lucide-icons';
import { useAppDispatch, useAppSelector, useLocalConfiguration, usePaginatedRendering } from 'app/hooks';
import moment from 'moment';
import { createParam } from 'solito';
import EventCard from '../event/event_card';
import { useTabsNavigationHeight } from '../navigation/tabs_navigation';
import { useHideNavigation } from "../navigation/use_hide_navigation";

const { useParam, useUpdateParams } = createParam<{ endsAfter: string, search: string }>()
export type EventsFullCalendarProps = {
  // selectedGroup?: FederatedGroup;
  events: FederatedEvent[];
  weeklyOnly?: boolean;
  // timeFilter: TimeFilter;
}
export const EventsFullCalendar: React.FC<EventsFullCalendarProps> = ({ events: allEvents, weeklyOnly }: EventsFullCalendarProps) => {
  const dispatch = useAppDispatch();
  const mediaQuery = useMedia();
  const { showBigCalendar: bigCalendar, showPinnedServers, shrinkPreviews } = useLocalConfiguration();

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

  // const timeFilter: TimeFilter = { endsAfter: endsAfter ? toProtoISOString(endsAfter) : undefined };
  // console.log('timeFilter', timeFilter);
  // useEffect(() => {
  //   const serverName = currentServer?.serverConfiguration?.serverInfo?.name || '...';
  //   const title = selectedGroup ? `${selectedGroup.name} | ${serverName}` : serverName;
  //   setDocumentTitle(`Events | ${title}`)
  // });

  // const { results: allEventsUnfiltered, loading: loadingEvents, reload: reloadEvents, hasMorePages, firstPageLoaded } =
  //   useEventPages(EventListingType.ALL_ACCESSIBLE_EVENTS, selectedGroup, { timeFilter });

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
  // const paginatedEvents = pagination.results;

  // useEffect(() => {
  //   if (firstPageLoaded) {
  //     dismissScrollPreserver(setShowScrollPreserver);
  //   }
  // }, [firstPageLoaded]);

  useEffect(pagination.reset, [queryEndsAfter, debouncedSearchText]);

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
  // const serializedTimeFilter = serializeTimeFilter(timeFilter);
  const minBigCalWidth = 150;
  const minBigCalHeight = 150;
  const maxWidth = 2000;
  const bigCalWidth = Math.min(maxWidth - 30, Math.max(minBigCalWidth, window.innerWidth - 30));
  const bigCalHeight = Math.min(
    weeklyOnly ? 350 : Number.MAX_SAFE_INTEGER,
    Math.max(minBigCalHeight, window.innerHeight - navigationHeight - 20)
  );
  const starredPostIds = useAppSelector(state => state.app.starredPostIds);

  return (//<>
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

            key={`calendar-rendering-${window.innerWidth
              }-${window.innerHeight
              }-${navigationHeight
              }-${hideNavigation
              }-${allEvents.length}`}
            selectable
            dateClick={({ date, view }) => {
              view.calendar.changeView('listDay', date);
            }}

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
  )
}

const localizer = momentLocalizer(moment);
