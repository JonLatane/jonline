import { Event, EventInstance, EventListingType, Group, Post, Visibility } from '@jonline/api';
import { Button, Heading, Input, Paragraph, Sheet, Text, TextArea, XStack, YStack, useMedia } from '@jonline/ui';
import { ChevronDown, Settings } from '@tamagui/lucide-icons';
import { RootState, clearPostAlerts, createEvent, createGroupPost, loadEventsPage, loadGroupEventsPage, selectAllAccounts, selectAllServers, serverID, useCredentialDispatch, useServerTheme, useTypedSelector } from 'app/store';
import React, { useEffect, useState } from 'react';
import { Platform, View } from 'react-native';
// import AccountCard from './account_card';
// import ServerCard from './server_card';
import moment from 'moment';
import { VisibilityPicker } from '../post/visibility_picker';
import EventCard from './event_card';
import { BaseCreatePostSheet } from '../post/base_create_post_sheet';

export const defaultEventInstance: () => EventInstance = () => EventInstance.create({ id: '', startsAt: moment().toISOString(), endsAt: moment().add(1, 'hour').toISOString() });

export type CreateEventSheetProps = {
  selectedGroup?: Group;
};

export const supportDateInput = (m: moment.Moment) => m.format('YYYY-MM-DDTHH:mm');
export const toProtoISOString = (localDateTimeInput: string) =>
  moment(localDateTimeInput).toISOString(true);

export function CreateEventSheet({ selectedGroup }: CreateEventSheetProps) {
  const { dispatch, accountOrServer } = useCredentialDispatch();
  const [startTime, setStartTime] = useState('');
  const [endTime, setEndTime] = useState('');

  const endDateInvalid = !moment(endTime).isAfter(moment(startTime));
  const invalid = endDateInvalid;

  function previewEvent(post: Post) {
    return Event.create({
      post: post,
      instances: [
        EventInstance.create({
          startsAt: toProtoISOString(startTime),
          endsAt: toProtoISOString(endTime)
        }),
      ],
    });
  }

  function doCreate(
    post: Post,
    group: Group | undefined,
    resetPost: () => void,
    onComplete: () => void
  ) {
    function doReset() {
      resetPost();
      setStartTime('');
      setEndTime('');
    }

    dispatch(createEvent({ ...previewEvent(post), ...accountOrServer })).then((action) => {
      if (action.type == createEvent.fulfilled.type) {
        dispatch(loadEventsPage({ ...accountOrServer, listingType: EventListingType.PUBLIC_EVENTS, page: 0 }));
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
    selectedGroup={selectedGroup}
    doCreate={doCreate}
    preview={(post, group) => {
      console.log('previewEvent', previewEvent(post));
      return <EventCard event={previewEvent(post)} hideEditControls />;
    }}
    feedPreview={(post, group) => <EventCard event={previewEvent(post)} isPreview hideEditControls />}
    invalid={invalid}
    onFreshOpen={() => {
      setStartTime(supportDateInput(moment()));
      setEndTime(supportDateInput(moment().add(1, 'hour')));
    }}
    additionalFields={(post, group) => <>
      <XStack mx='$2'>
        <Heading size='$2' f={1} marginVertical='auto'>Start Time</Heading>
        <Text fontSize='$2' fontFamily='$body'>
          <input type='datetime-local' value={startTime} onChange={(v) => setStartTime(v.target.value)} style={{ padding: 10 }} />
        </Text>
      </XStack>
      <XStack mx='$2'>
        <Heading size='$2' f={1} marginVertical='auto'>End Time</Heading>
        <Text fontSize='$2' fontFamily='$body'>
          <input type='datetime-local' value={endTime} min={startTime} onChange={(v) => setEndTime(v.target.value)} style={{ padding: 10 }} />
        </Text>
      </XStack>
      {endDateInvalid ? <Paragraph size='$2' mx='$2'>Must be after Start Time</Paragraph> : undefined}

    </>}
  />;
}
