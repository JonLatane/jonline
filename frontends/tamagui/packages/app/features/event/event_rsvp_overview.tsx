import { accountOrServerId, getCredentialClient, useCredentialDispatch, useServerTheme } from "app/store";
import React, { useEffect, useState } from "react";

import { AttendanceStatus, Event, EventAttendance, EventInstance, Permission } from "@jonline/api";
import { Anchor, AnimatePresence, Button, Dialog, Heading, Input, Label, Paragraph, RadioGroup, Select, SizeTokens, standardAnimation, TextArea, Theme, useMedia, XStack, YStack, ZStack } from "@jonline/ui";
import { AlertTriangle, Check, ChevronDown, ChevronRight, Edit, Plus } from "@tamagui/lucide-icons";
import { hasPermission } from "app/utils/permission_utils";
import { createParam } from "solito";
import { TamaguiMarkdown } from "../post/tamagui_markdown";
import RsvpCard from "./rsvp_card";
import { passes, pending, rejected } from "app/utils/moderation_utils";

export interface EventRsvpOverviewProps {
  event: Event;
  instance: EventInstance;
  newRsvpMode: RsvpMode;
  setNewRsvpMode: (mode: RsvpMode) => void;
  attendances: EventAttendance[];
  loading?: boolean;
  onPress?: () => void;
  expanded?: boolean;
}

export type RsvpMode = 'anonymous' | 'user' | undefined;

// let newEventId = 0;
const { useParam } = createParam<{ anonymousAuthToken: string }>()

export const EventRsvpOverview: React.FC<EventRsvpOverviewProps> = ({
  event,
  instance,
  newRsvpMode,
  setNewRsvpMode,
  attendances,
  loading,
  onPress,
  expanded = false,
}) => {
  const mediaQuery = useMedia();
  const { server, primaryColor, primaryTextColor, primaryAnchorColor, navColor, navTextColor, navAnchorColor } = useServerTheme();

  let { dispatch, accountOrServer } = useCredentialDispatch();
  const { account } = accountOrServer;
  const isEventOwner = account && account?.user?.id === event?.post?.author?.userId;

  const [queryAnonAuthToken, setQueryAnonAuthToken] = useParam('anonymousAuthToken');
  const anonymousAuthToken = queryAnonAuthToken ?? '';

  const showRsvpSection = event?.info?.allowsRsvps &&
    (event?.info?.allowsAnonymousRsvps || hasPermission(accountOrServer?.account?.user, Permission.RSVP_TO_EVENTS));

  // const [newRsvpMode, setNewRsvpMode] = useState(undefined as RsvpMode);
  // const [attendances, setAttendances] = useState([] as EventAttendance[]);
  const currentRsvp = attendances.find(a => account !== undefined && a.userAttendee?.userId === account.user?.id);
  const currentAnonRsvp = attendances.find(a => a.anonymousAttendee && a.anonymousAttendee?.authToken === queryAnonAuthToken);

  const numberOfGuestsOptions = [...Array(52).keys()];

  // useEffect(() => {
  //   if (newRsvpMode === 'anonymous' && currentAnonRsvp) {
  //     setAnonymousRsvpName(currentAnonRsvp.anonymousAttendee?.name ?? '');
  //     setNumberOfGuests(currentAnonRsvp.numberOfGuests);
  //     setPublicNote(currentAnonRsvp.publicNote);
  //     setPrivateNote(currentAnonRsvp.privateNote);
  //     setRsvpStatus(currentAnonRsvp.status);
  //   } else if (newRsvpMode === 'user' && currentRsvp) {
  //     setNumberOfGuests(currentRsvp.numberOfGuests);
  //     setPublicNote(currentRsvp.publicNote);
  //     setPrivateNote(currentRsvp.privateNote);
  //     setRsvpStatus(currentRsvp.status);
  //   }
  // }, [newRsvpMode, currentAnonRsvp, currentRsvp]);

  const scrollToRsvps = () =>
    document.querySelectorAll('.event-rsvp-manager')
      .forEach(e => e.scrollIntoView({ block: 'center', behavior: 'smooth' }));

  useEffect(() => {
    if (queryAnonAuthToken && queryAnonAuthToken !== '') {
      setTimeout(() => {
        setNewRsvpMode('anonymous');
      },
        1000)
    }
  }, [queryAnonAuthToken]);

  useEffect(() => {
    if (newRsvpMode !== undefined) {
      scrollToRsvps();
    }
  }, [newRsvpMode]);

  const [rsvpStatus, setRsvpStatus] = useState(AttendanceStatus.INTERESTED);
  const [anonymousRsvpName, setAnonymousRsvpName] = useState('');
  const [publicNote, setPublicNote] = useState('');
  const [privateNote, setPrivateNote] = useState('');
  const [numberOfGuests, setNumberOfGuests] = useState(1);

  const canRsvp = (newRsvpMode === 'user' && account?.user) || anonymousRsvpName.length > 0;

  const upsertableAttendance = instance ? {
    eventInstanceId: instance.id,
    userAttendee: newRsvpMode === 'user'
      ? { userId: account?.user?.id }
      : undefined,
    anonymousAttendee: newRsvpMode === 'anonymous' ? {
      name: anonymousRsvpName,
      authToken: anonymousAuthToken
    } : undefined,
    status: rsvpStatus,
    numberOfGuests: numberOfGuests,
    privateNote,
    publicNote,
  } : undefined;


  if (!instance) {
    return <></>;
  }


  const nonPendingAttendances = attendances.filter(a => passes(a.moderation)).sort((a, b) => a.status - b.status);
  const [goingRsvpCount, goingAttendeeCount] = nonPendingAttendances
    .filter(a => a.status === AttendanceStatus.GOING)
    .reduce((acc, a) => [acc[0] + 1, acc[1] + a.numberOfGuests], [0, 0]);
  const [interestedRsvpCount, interestedAttendeeCount] = nonPendingAttendances
    .filter(a => [AttendanceStatus.INTERESTED, AttendanceStatus.REQUESTED].includes(a.status))
    .reduce((acc, a) => [acc[0] + 1, acc[1] + a.numberOfGuests], [0, 0]);


  const pendingAttendances = attendances.filter(a => pending(a.moderation)).sort((a, b) => a.status - b.status);
  const [pendingRsvpCount, pendingAttendeeCount] = pendingAttendances
    .reduce((acc, a) => [acc[0] + 1, acc[1] + a.numberOfGuests], [0, 0]);
  const hasPendingAttendances = pendingRsvpCount > 0 || pendingAttendeeCount > 0;

  const rejectedAttendances = attendances.filter(a => rejected(a.moderation)).sort((a, b) => a.status - b.status);
  const othersAttendances = nonPendingAttendances.filter(a => [currentRsvp, currentAnonRsvp].every(c => c?.id !== a.id));

  return <Button key='rsvp-card-toggle'
          h={hasPendingAttendances
            ? (mediaQuery.gtXxxxs ? '$10' : '$15')
            : (mediaQuery.gtXxxxs ? '$5' : '$10')}
          onPress={onPress} 
          disabled={attendances.length === 0} 
          o={attendances.length === 0 ? 0.5 : 1}>
          <XStack w='100%'>
            <YStack f={1}>
              {hasPendingAttendances
                ? <XStack w='100%' flexWrap="wrap">
                  <Paragraph size='$1' fontWeight='700'>{isEventOwner ? 'Pending Your Approval' : 'Pending Owner Approval'}</Paragraph>
                  {!loading
                    ? <Paragraph size='$1' ml='auto'>{pendingRsvpCount} {pendingRsvpCount === 1 ? 'RSVP' : 'RSVPs'} | {pendingAttendeeCount} {pendingAttendeeCount === 1 ? 'attendee' : 'attendees'}</Paragraph>
                    : <Paragraph size='$1' ml='auto'>...</Paragraph>}
                </XStack>
                : undefined}
              <XStack w='100%' flexWrap="wrap">
                <Paragraph size='$1' color={primaryAnchorColor}>Going</Paragraph>
                {!loading
                  ? <Paragraph size='$1' ml='auto'>{goingRsvpCount} {goingRsvpCount === 1 ? 'RSVP' : 'RSVPs'} | {goingAttendeeCount} {goingAttendeeCount === 1 ? 'attendee' : 'attendees'}</Paragraph>
                  : <Paragraph size='$1' ml='auto'>...</Paragraph>}
              </XStack>
              <XStack w='100%' flexWrap="wrap">
                <Paragraph size='$1' color={navAnchorColor}>Interested/Invited</Paragraph>
                {!loading
                  ? <Paragraph size='$1' ml='auto'>{interestedRsvpCount} {interestedRsvpCount === 1 ? 'RSVP' : 'RSVPs'} | {interestedAttendeeCount} {interestedAttendeeCount === 1 ? 'attendee' : 'attendees'}</Paragraph>
                  : <Paragraph size='$1' ml='auto'>...</Paragraph>}
              </XStack>
            </YStack>
            <XStack animation='quick' my='auto' ml='$2' rotate={expanded ? '90deg' : '0deg'}>
              <ChevronRight />
            </XStack>
          </XStack>
        </Button>;
};
