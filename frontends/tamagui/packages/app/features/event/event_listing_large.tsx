import 'react-big-calendar/lib/css/react-big-calendar.css';

import { Heading, XStack, YStack, needsScrollPreservers, standardAnimation, useMedia, useToastController } from '@jonline/ui';
import { FederatedEvent, federateId, federatedId, useServerTheme } from 'app/store';
import React, { useState } from 'react';

import { useLocalConfiguration, usePaginatedRendering } from 'app/hooks';
import { useBigCalendar } from "app/hooks/configuration_hooks";
import EventCard from './event_card';

import { EventsFullCalendar, useScreenWidthAndHeight } from "./events_full_calendar";

import { PageChooser } from "../home/page_chooser";

export type EventListingLargeProps = {
  events: FederatedEvent[];
}


export const EventListingLarge: React.FC<EventListingLargeProps> = ({ events }) => {
  const toast = useToastController();
  const mediaQuery = useMedia();
  const { shrinkPreviews } = useLocalConfiguration();
  const { bigCalendar, setBigCalendar } = useBigCalendar();

  // const eventsState = useRootSelector((state: RootState) => state.events);

  const [showScrollPreserver, setShowScrollPreserver] = useState(needsScrollPreservers());

  const serverTheme = useServerTheme();
  const { server: currentServer, primaryColor, primaryAnchorColor, navColor, navTextColor, transparentBackgroundColor } = serverTheme;//useServerTheme();

  // const { results: allEvents, loading: loadingEvents, reload: reloadEvents, hasMorePages, firstPageLoaded } =
  //   useEventPages(EventListingType.ALL_ACCESSIBLE_EVENTS);

  // const [pageLoadTime] = useState<string>(moment(Date.now()).toISOString(true));

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


  const eventCardWidth = renderInColumns
    ? (window.innerWidth - 50 - (20 * numberOfColumns)) / numberOfColumns
    : undefined;
  const maxWidth = 2000;


  // const oneLineFilterBar = mediaQuery.xShort && mediaQuery.gtXs;

  const { screenWidth, screenHeight } = useScreenWidthAndHeight();



  const pagination = usePaginatedRendering(
    events,
    pageSize
  );
  const paginatedEvents = pagination.results;


  return bigCalendar
    ? <div key='bigcalendar-rendering' style={{
      width: '100%',
      display: 'flex', flexDirection: 'column', alignItems: 'center'
    }}>
      <EventsFullCalendar events={events}
        scrollToTime={events[0]?.instances[0]?.startsAt} />
    </div>
    : renderInColumns
      ? [
        <PageChooser key='pages-top' id='pages-top' {...pagination} maxWidth='100%' />,
        <XStack key={`multi-column-rendering-page-${pagination.page}`} mx='auto' jc='center' flexWrap='wrap'>
          {/* <AnimatePresence> */}
          {events.length === 0
            ? <XStack key='no-events-found' style={{ width: '100%', margin: 'auto' }}
            // animation='standard' {...standardAnimation}
            >
              <YStack width='100%' maw={600} jc="center" ai="center" mx='auto'>
                <Heading size='$5' mb='$3' o={0.5}>No events found.</Heading>
              </YStack>
            </XStack>
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
        </XStack>,
        <PageChooser {...pagination} pageTopId='pages-top' key='pages-bottom' id='pages-bottom' showResultCounts maxWidth='100%'
          entityName={{ singular: 'event', plural: 'events' }} />
        ,
      ]
      : [
        <PageChooser id='pages-top' key='pages-top' {...pagination} maxWidth='100%' />,

        events.length === 0
          ? <YStack key='no-events-found' width='100%' maw={600} jc="center" ai="center" mx='auto'>
            <Heading size='$5' o={0.5} mb='$3'>No events found.</Heading>
            {/* <Heading size='$2' o={0.5} ta='center'>The events you're looking for may either not exist, not be visible to you, or be hidden by moderators.</Heading> */}
          </YStack>
          : undefined,

        paginatedEvents.map((event) => {
          return <XStack key={`event-preview-${federatedId(event)}-${event.instances[0]!.id}`} w='100%'>
            <EventCard event={event} key={federateId(event.instances[0]?.id ?? '', currentServer)} isPreview />
          </XStack>
        }),

        <PageChooser {...pagination} key='pages-bottom' pageTopId='pages-top' showResultCounts maxWidth='100%'
          entityName={{ singular: 'event', plural: 'events' }} />
      ];
}
