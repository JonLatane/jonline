import { getCredentialClient, useAccountOrServer, useCredentialDispatch, useServerTheme } from "app/store";
import React, { useState } from "react";

import { AttendanceStatus, Event, EventAttendance, EventInstance, Moderation, Post } from "@jonline/api";
import { Button, Card, Heading, Paragraph, useMedia, XStack, YStack } from "@jonline/ui";
import { Edit } from "@tamagui/lucide-icons";
import { AuthorInfo } from "../post/author_info";
import { TamaguiMarkdown } from "../post/tamagui_markdown";
import { ModerationPicker } from "app/components/moderation_picker";
import { passes } from "app/utils/moderation_utils";
import { standardAnimation } from '../../../ui/src/animations';

interface Props {
  event: Event;
  instance: EventInstance;
  attendance: EventAttendance;
  onPressEdit?: () => void;
  onModerated?: (attendance: EventAttendance) => void;
}

export const RsvpCard: React.FC<Props> = ({
  event,
  instance,
  attendance,
  onPressEdit,
  onModerated,
}) => {
  const mediaQuery = useMedia();
  const { dispatch, accountOrServer } = useCredentialDispatch();
  const { account } = accountOrServer;
  const isEventOwner = account && account?.user?.id === event?.post?.author?.userId;
  // const post = event.post!;

  const { server, textColor, primaryColor, navAnchorColor: navColor, backgroundColor: themeBgColor, primaryAnchorColor, navAnchorColor } = useServerTheme();

  const { anonymousAttendee, userAttendee, publicNote, privateNote, status, numberOfGuests } = attendance;

  const [upserting, setUpserting] = useState(false);
  async function applyModeration(moderation: Moderation) {
    setUpserting(true);

    const client = await getCredentialClient(accountOrServer);
    client.upsertEventAttendance({ ...attendance, moderation }, client.credential)
      .then(onModerated)
      .finally(() => setUpserting(false));
  }

  return <Card elevate size="$4" bordered
    animation='standard'
    {...standardAnimation}
    key={`attendance-card-${attendance.id}`}
    margin='$0'
    mx="$1"
    scale={1}
    // opacity={1}
    y={0}
    mb='$2'
  >
    <Card.Header pb={0}>
      <XStack>
        <YStack f={1}>
          {anonymousAttendee
            ? <>
              <Paragraph size='$1'>Anonymous</Paragraph>
              <Heading size='$7'>{anonymousAttendee.name}</Heading>
            </>
            : <>
              <AuthorInfo post={Post.create({ author: attendance.userAttendee! })} />
            </>}
        </YStack>
        <YStack my='auto'>
          <Paragraph size='$2' mx='auto'
            color={attendance.status == AttendanceStatus.GOING ? primaryAnchorColor :
              attendance.status == AttendanceStatus.INTERESTED || attendance.status == AttendanceStatus.REQUESTED ? navAnchorColor : undefined}>
            {attendanceStatusString(attendance.status)}
          </Paragraph>
          {/* {attendance.numberOfGuests > 1 ? */}
          <Paragraph size='$1' mx='auto'>
            {attendance.numberOfGuests} attendee{attendance.numberOfGuests > 1 ? 's' : ''}
          </Paragraph>
          {/* : undefined} */}
        </YStack>
        {onPressEdit
          ? <Button circular transparent icon={Edit} onClick={onPressEdit} />
          : undefined}
      </XStack>
    </Card.Header>
    <Card.Footer p='$3' pr={mediaQuery.gtXs ? '$3' : '$1'} pt={0}>
      <YStack w='100%'>
        <TamaguiMarkdown text={publicNote} />
        {privateNote && privateNote.length > 0
          ? <>
            <Heading size='$1'>Private Note</Heading>
            <TamaguiMarkdown text={privateNote} />
          </>
          : undefined}
        <XStack ml='auto'>
          {/* <XStack f={1} /> */}
          {isEventOwner ?
            <ModerationPicker moderation={attendance.moderation}
              moderationDescription={attendanceModerationDescription}
              disabled={upserting}
              onChange={applyModeration} />
            : !passes(attendance.moderation)
              ? <Paragraph size='$1' ml='auto'>{attendanceModerationDescription(attendance.moderation)}</Paragraph>
              : undefined}
        </XStack>
      </YStack>
    </Card.Footer>
  </Card>;
};



export function attendanceModerationDescription(v: Moderation) {
  switch (v) {
    case Moderation.UNMODERATED: return 'Visible to anyone who can view this event.';
    case Moderation.REJECTED: return 'Rejected by the event owner. Visible only to attendee and owner.';
    case Moderation.APPROVED: return 'Visible to anyone who can view the event.';
    case Moderation.PENDING: return 'Awaiting approval by the event owner. Visible only to attendee and owner.';
  }
}

const attendanceStatusString = (status: AttendanceStatus) => {
  switch (status) {
    case AttendanceStatus.GOING:
      return 'Going';
    case AttendanceStatus.INTERESTED:
      return 'Interested';
    case AttendanceStatus.REQUESTED:
      return 'Requested';
    case AttendanceStatus.NOT_GOING:
      return 'Not Going';
    default:
      return 'Unknown';
  }
}

export default RsvpCard;
