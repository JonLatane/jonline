import { Event, EventInstance, EventListingType, Group, Location, Permission, Post } from '@jonline/api';
import { Heading, Paragraph, Text, XStack } from '@jonline/ui';
import { FederatedGroup, createEvent, createGroupPost, federatedEntity, loadEventsPage, loadGroupEventsPage } from 'app/store';
import React, { useEffect, useState } from 'react';
// import AccountCard from './account_card';
// import ServerCard from './server_card';
import { useCredentialDispatch } from 'app/hooks';
import moment from 'moment';
import { BaseCreatePostSheet } from '../post/base_create_post_sheet';
import EventCard from './event_card';
import { LocationControl } from './location_control';

export const defaultEventInstance: () => EventInstance = () => EventInstance.create({ id: '', startsAt: moment().toISOString(), endsAt: moment().add(1, 'hour').toISOString() });

export type CreateEventSheetProps = {
  selectedGroup?: FederatedGroup;
};

export const supportDateInput = (m: moment.Moment) => m.local().format('YYYY-MM-DDTHH:mm');
export const toProtoISOString = (localDateTimeInput: string) =>
  moment(localDateTimeInput).toISOString(true);

export function CreateEventSheet({ selectedGroup }: CreateEventSheetProps) {
  const { dispatch, accountOrServer } = useCredentialDispatch();
  const [startsAt, setStartsAt] = useState('');
  const [endsAt, setEndsAt] = useState('');
  const [duration, _setDuration] = useState(0);

  const canPublishLocally = accountOrServer.account?.user?.permissions?.includes(Permission.PUBLISH_EVENTS_LOCALLY);
  const canPublishGlobally = accountOrServer.account?.user?.permissions?.includes(Permission.PUBLISH_EVENTS_GLOBALLY);

  useEffect(() => {
    if (startsAt && endsAt) {
      const start = moment(startsAt);
      const end = moment(endsAt);
      _setDuration(end.diff(start, 'minutes'));
    }
  }, [endsAt]);
  useEffect(() => {
    if (startsAt && duration) {
      const start = moment(startsAt);
      const end = start.add(duration, 'minutes');
      setEndsAt(supportDateInput(end));
    }
  }, [startsAt]);


  const [location, setLocation] = useState(Location.create({}));

  const endDateInvalid = !moment(endsAt).isAfter(moment(startsAt));
  const invalid = endDateInvalid;

  function previewEvent(post: Post) {
    const event = Event.create({
      post: post,
      instances: [
        EventInstance.create({
          location,
          startsAt: toProtoISOString(startsAt),
          endsAt: toProtoISOString(endsAt)
        }),
      ],
    });
    return federatedEntity(event, accountOrServer.server);
  };

  function doCreate(
    post: Post,
    group: Group | undefined,
    resetPost: () => void,
    onComplete: () => void
  ) {
    function doReset() {
      resetPost();
      setStartsAt('');
      setEndsAt('');
    }

    dispatch(createEvent({ ...previewEvent(post), ...accountOrServer })).then((action) => {
      if (action.type == createEvent.fulfilled.type) {
        dispatch(loadEventsPage({ ...accountOrServer, listingType: EventListingType.ALL_ACCESSIBLE_EVENTS, page: 0 }));
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
      } else {
        onComplete();
      }
    });
  }

  return <BaseCreatePostSheet
    entityName='Event'
    {...{ canPublishGlobally, canPublishLocally, selectedGroup, doCreate, invalid }}
    preview={(post, group) => {
      console.log('previewEvent', previewEvent(post));
      return <EventCard event={previewEvent(post)} hideEditControls />;
    }}
    feedPreview={(post, group) => <EventCard event={previewEvent(post)} isPreview hideEditControls />}

    onFreshOpen={() => {
      setStartsAt(supportDateInput(moment()));
      setEndsAt(supportDateInput(moment().add(1, 'hour')));
    }}
    additionalFields={(post, group) => <>
      <XStack mx='$2'>
        <Heading size='$2' f={1} marginVertical='auto'>Start Time</Heading>
        <Text fontSize='$2' fontFamily='$body'>
          <input type='datetime-local' min={supportDateInput(moment(0))} value={startsAt} onChange={(v) => setStartsAt(v.target.value)} style={{ padding: 10 }} />
        </Text>
      </XStack>
      <XStack mx='$2'>
        <Heading size='$2' f={1} marginVertical='auto'>End Time</Heading>
        <Text fontSize='$2' fontFamily='$body'>
          <input type='datetime-local' value={endsAt} min={startsAt} onChange={(v) => setEndsAt(v.target.value)} style={{ padding: 10 }} />
        </Text>
      </XStack>

      {endDateInvalid ? <Paragraph size='$2' mx='$2'>Must be after Start Time</Paragraph> : undefined}

      <LocationControl key='location-control' location={location} setLocation={setLocation} />
    </>}
  />;
}
