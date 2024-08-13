import { Event, EventInstance, EventListingType, Group, Location, Permission, Post, TimeFilter } from '@jonline/api';
import { Button, DateTimePicker, Heading, Paragraph, XStack, YStack, getThemes, supportDateInput, toProtoISOString, useTheme } from '@jonline/ui';
import { FederatedGroup, createEvent, createGroupPost, federatedEntity, useServerTheme, loadEventsPage, loadGroupEventsPage, resetEvents } from 'app/store';
import React, { useCallback, useEffect, useState } from 'react';
// import {Calendar as CalendarIcon} from '@tamagui/lucide-icons';

import { useCreationDispatch, useCreationServer, useCredentialDispatch, useEventPageParam, useEventPages, useLocalConfiguration } from 'app/hooks';
import moment from 'moment';
import { BaseCreatePostSheet } from '../post/base_create_post_sheet';
import EventCard from './event_card';
import { LocationControl } from './location_control';
import { Calendar as CalendarIcon } from '@tamagui/lucide-icons';
import { useBigCalendar } from 'app/hooks/configuration_hooks';
import { themedButtonBackground } from 'app/utils';
import { EventsFullCalendar } from './events_full_calendar';

export const defaultEventInstance: () => EventInstance = () => EventInstance.create({ id: '', startsAt: moment().toISOString(), endsAt: moment().add(1, 'hour').toISOString() });

export type CreateEventSheetProps = {
  selectedGroup?: FederatedGroup;
  button?: (onPress: () => void) => JSX.Element;
};

export function CreateEventSheet({ selectedGroup, button }: CreateEventSheetProps) {
  const { dispatch, accountOrServer } = useCreationDispatch();
  const [startsAt, _setStartsAt] = useState('');
  const [endsAt, _setEndsAt] = useState('');
  const [duration, _setDuration] = useState(0);

  const canPublishLocally = accountOrServer.account?.user?.permissions?.includes(Permission.PUBLISH_EVENTS_LOCALLY);
  const canPublishGlobally = accountOrServer.account?.user?.permissions?.includes(Permission.PUBLISH_EVENTS_GLOBALLY);

  const setStartsAt = useCallback((v: string) => {
    _setStartsAt(v);
    if (v && duration) {
      const start = moment(v);
      const end = start.add(duration, 'minutes');
      _setEndsAt(supportDateInput(end));
    }
  }, [duration]);
  const setEndsAt = useCallback((v: string) => {
    _setEndsAt(v);
    if (startsAt) {
      const start = moment(startsAt);
      const end = moment(v);
      _setDuration(end.diff(start, 'minutes'));
    }
  }, [startsAt]);
  // useEffect(() => {
  //   if (startsAt && endsAt) {
  //     const start = moment(startsAt);
  //     const end = moment(endsAt);
  //     _setDuration(end.diff(start, 'minutes'));
  //   }
  // }, [endsAt]);
  // useEffect(() => {
  //   if (startsAt && duration) {
  //     const start = moment(startsAt);
  //     const end = start.add(duration, 'minutes');
  //     setEndsAt(supportDateInput(end));
  //   }
  // }, [startsAt]);


  const [location, setLocation] = useState(Location.create({}));

  const endDateInvalid = !moment(endsAt).isAfter(moment(startsAt));
  const invalid = endDateInvalid;

  const previewEvent = useCallback((post: Post) => {
    const event = Event.create({
      post: post,
      instances: [
        EventInstance.create({
          location,
          startsAt: toProtoISOString(startsAt),
          endsAt: toProtoISOString(endsAt),
          post: Post.create({
            visibility: post.visibility,
            shareable: post.shareable,
          })
        }),
      ],
    });
    return federatedEntity(event, accountOrServer.server);
  }, [location, startsAt, endsAt, accountOrServer.server]);

  const doCreate = useCallback((
    post: Post,
    group: Group | undefined,
    resetPost: () => void,
    onComplete: () => void,
    onErrored: (error: any) => void,
  ) => {
    function doReset() {
      resetPost();
      setStartsAt('');
      setEndsAt('');
    }

    // const event = previewEvent(post);
    dispatch(createEvent({ ...previewEvent(post), ...accountOrServer })).then((action) => {
      if (action.type == createEvent.fulfilled.type) {
        // dispatch(loadEventsPage({ ...accountOrServer, listingType: EventListingType.ALL_ACCESSIBLE_EVENTS, page: 0 }));

        const post = action.payload as Post;
        if (group) {
          dispatch(createGroupPost({ groupId: group.id, postId: (post).id, ...accountOrServer }))
            .then(() => {
              loadGroupEventsPage({ ...accountOrServer, groupId: group.id, page: 0 })
              doReset();
            });
        } else {
          doReset();
        }
        onComplete();
      } else {
        if ('error' in action) {
          onErrored(action.error);
        } else {
          onErrored('Error creating Event');
        }
      }
    });
  }, [previewEvent, accountOrServer]);
  const { bigCalendar, setBigCalendar } = useBigCalendar();
  const { creationServer } = useCreationServer();
  const { navColor, navTextColor } = useServerTheme(creationServer);
  // const timeFilter: TimeFilter = { endsAfter: endsAfter ? toProtoISOString(endsAfter) : undefined };
  const [pageLoadTime] = useState<string>(moment(Date.now()).toISOString(true));
  const endsAfter = moment(pageLoadTime).subtract(1, "week").toISOString(true);
  const timeFilter: TimeFilter = { endsAfter: endsAfter ? toProtoISOString(endsAfter) : undefined };

  const { results: eventResults, loading: loadingEvents, reload: reloadEvents, firstPageLoaded: eventsLoaded } =
    useEventPages(EventListingType.ALL_ACCESSIBLE_EVENTS, selectedGroup, { timeFilter });

  const { eventPagesOnHome } = useLocalConfiguration();
  const allEvents = bigCalendar
    ? eventResults
    : eventResults.filter(e => moment(e.instances[0]?.endsAt).isAfter(pageLoadTime))

  const preview = useCallback((post: Post, group: Group | undefined) => {
    return <EventCard event={previewEvent(post)} hideEditControls />;
  }, [previewEvent]);
  const feedPreview = useCallback((post: Post, group: Group | undefined) => {
    const event = previewEvent(post);
    return <YStack>
      <Button
        onPress={() => setBigCalendar(!bigCalendar)} mb='$2'
        icon={CalendarIcon}
        transparent
        {...themedButtonBackground(
          bigCalendar ? navColor : undefined, bigCalendar ? navTextColor : undefined)}
      // animation='standard'
      // zi={100000}
      // disabled={!showEvents || allEvents.length === 0}
      // o={showEvents && allEvents.length > 0 ? 1 : 0}
      />
      {bigCalendar
        ? <EventsFullCalendar events={[event, ...allEvents]}
          scrollToTime={event.instances[0]?.startsAt} weeklyOnly width='100%' />
        : <EventCard event={event} isPreview hideEditControls />}
      {/* <EventCard event={previewEvent(post)} isPreview hideEditControls /> */}
    </YStack>
  }, [previewEvent, bigCalendar, navColor, allEvents]);

  const additionalFields = useCallback((post: Post, group: Group | undefined) => {
    return <>
      <XStack mx='$2'>
        <Heading size='$2' f={1} marginVertical='auto'>Start Time</Heading>
        <XStack ml='auto' my='auto'>
          <DateTimePicker value={startsAt} onChange={(v) => setStartsAt(v)} />
        </XStack>
      </XStack>
      <XStack mx='$2'>
        <Heading size='$2' f={1} marginVertical='auto'>End Time</Heading>
        <XStack ml='auto' my='auto'>
          <DateTimePicker value={endsAt} onChange={(v) => setEndsAt(v)} />
        </XStack>
      </XStack>

      {endDateInvalid ? <Paragraph size='$2' mx='$2'>Must be after Start Time</Paragraph> : undefined}

      <LocationControl key='location-control' location={location} setLocation={setLocation} />
    </>;
  }, [startsAt, endsAt, location]);

  const onFreshOpen = useCallback(() => {
    setStartsAt(supportDateInput(moment()));
    setEndsAt(supportDateInput(moment().add(1, 'hour')));
  }, []);

  return <BaseCreatePostSheet
    entityName='Event'
    requiredPermissions={[Permission.CREATE_EVENTS]}
    {...{
      canPublishGlobally, canPublishLocally, selectedGroup, doCreate, invalid, button,
      preview, feedPreview, onFreshOpen, additionalFields
    }}
  />;
}
