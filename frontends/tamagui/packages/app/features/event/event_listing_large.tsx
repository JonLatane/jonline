import { Author, Event, Location, Permission } from '@jonline/api';
import * as webllm from "@mlc-ai/web-llm";
import 'react-big-calendar/lib/css/react-big-calendar.css';

import { Button, Heading, Input, Paragraph, Select, Spinner, TextArea, Tooltip, XStack, YStack, needsScrollPreservers, standardAnimation, useDebounceValue, useMedia, useToastController } from '@jonline/ui';
import { FederatedEvent, federateId, federatedId, useServerTheme } from 'app/store';
import React, { useEffect, useMemo, useState } from 'react';

import { useLocalConfiguration, usePaginatedRendering } from 'app/hooks';
import { useBigCalendar } from "app/hooks/configuration_hooks";
import FlipMove from 'lumen5-react-flip-move';
import EventCard from './event_card';
import { AppSection } from '../navigation/features_navigation';
import { TabsNavigation } from '../navigation/tabs_navigation';

import { EventsFullCalendar, useScreenWidthAndHeight } from "./events_full_calendar";

import { Calendar as CalendarIcon, Check, ChevronDown, ChevronRight, Key, Eye, EyeOff } from '@tamagui/lucide-icons';
import { hasPermission, highlightedButtonBackground, setDocumentTitle, themedButtonBackground } from 'app/utils';
import OpenAI from 'openai';
import { isSafari } from '@jonline/ui/src/global';
import { useCreationAccountOrServer } from '../../hooks/account_or_server/use_creation_account_or_server';
import { CreationServerSelector } from '../accounts/creation_server_selector';
import { PageChooser } from "../home/page_chooser";
import { TamaguiMarkdown } from '../post';

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
    ? <div key='bigcalendar-rendering' style={{ width: '100%',
      display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
      <EventsFullCalendar events={events}
        scrollToTime={events[0]?.instances[0]?.startsAt} />
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
            {/* </FlipMove> */}
            {/* </AnimatePresence> */}
          </XStack>
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

        events.length === 0
          ? <div key='no-events-found' style={{ width: '100%', margin: 'auto' }}>
            <YStack width='100%' maw={600} jc="center" ai="center" mx='auto'>
              <Heading size='$5' o={0.5} mb='$3'>No events found.</Heading>
              {/* <Heading size='$2' o={0.5} ta='center'>The events you're looking for may either not exist, not be visible to you, or be hidden by moderators.</Heading> */}
            </YStack>
          </div>
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
      ];
}
