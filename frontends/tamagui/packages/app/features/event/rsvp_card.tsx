import { useServerTheme } from "app/store";
import React from "react";

import { AttendanceStatus, Event, EventAttendance, EventInstance, Post } from "@jonline/api";
import { Button, Card, Heading, Paragraph, useMedia, XStack, YStack } from "@jonline/ui";
import { Edit } from "@tamagui/lucide-icons";
import { AuthorInfo } from "../post/author_info";
import { TamaguiMarkdown } from "../post/tamagui_markdown";

interface Props {
  event: Event;
  instance: EventInstance;
  attendance: EventAttendance;
  onEdit?: () => void;
}


export const RsvpCard: React.FC<Props> = ({
  event,
  instance,
  attendance,
  onEdit,
}) => {
  const mediaQuery = useMedia();
  const post = event.post!;

  const { server, textColor, primaryColor, navAnchorColor: navColor, backgroundColor: themeBgColor, primaryAnchorColor, navAnchorColor } = useServerTheme();

  const { anonymousAttendee, userAttendee, publicNote, privateNote, status, numberOfGuests } = attendance;

  return <Card theme="dark" elevate size="$4" bordered
    key={`attendance-card-${attendance.id}`}
    margin='$0'
    // marginBottom='$3'
    // marginTop='$3'
    // f={isPreview ? undefined : 1}
    // ref={ref!}
    scale={1}
    opacity={1}
    y={0}
  >
    {post.link || post.title
      ? <Card.Header>
        <XStack>
          <YStack f={1}>
            {anonymousAttendee
              ? <>
                <Paragraph size='$1'>Anonymous Attendee</Paragraph>
                <Heading size='$7'>{anonymousAttendee.name}</Heading>
              </>
              : <>
                <AuthorInfo post={Post.create({ author: attendance.userAttendee! })} />
              </>}
            <XStack space='$2'>
              <Paragraph size='$2' my='auto'
                color={attendance.status == AttendanceStatus.GOING ? primaryAnchorColor :
                  attendance.status == AttendanceStatus.INTERESTED || attendance.status == AttendanceStatus.REQUESTED ? navAnchorColor : undefined}>
                {attendanceStatusString(attendance.status)}
              </Paragraph>
              {attendance.numberOfGuests > 1 ?
                <Paragraph size='$1' my='auto'>
                  {attendance.numberOfGuests} attendee{attendance.numberOfGuests > 1 ? 's' : ''}
                </Paragraph> : undefined}

            </XStack>
          </YStack>
          {onEdit
          ? <Button ml='auto' circular transparent icon={Edit} onClick={onEdit}/ >
        : undefined}
        </XStack>
      </Card.Header>
      : undefined}
    <Card.Footer p='$3' pr={mediaQuery.gtXs ? '$3' : '$1'} >
      <YStack>
        <TamaguiMarkdown text={publicNote} />
        {privateNote && privateNote.length > 0
          ? <>
            <Heading size='$1'>Private Note</Heading>
            <TamaguiMarkdown text={privateNote} />
          </>
          : undefined}
      </YStack>
    </Card.Footer>
  </Card>;
};

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
