import { FederatedEvent, federateId, getServerTheme } from "app/store";
import React from "react";

import { EventInstance, Group } from "@jonline/api";
import { Button, Heading, Paragraph, Popover, XStack, YStack, useTheme } from "@jonline/ui";
import { ArrowRightFromLine, Calendar, ExternalLink } from "@tamagui/lucide-icons";
import { useAccountOrServer, useFederatedAccountOrServer, useServer } from "app/hooks";
import { themedButtonBackground } from "app/utils/themed_button_background";
import { CalendarEvent, google, ics, office365, outlook, yahoo } from "calendar-link";
import moment from "moment";
import { useLink } from "solito/link";
import { useGroupContext } from "../../contexts/group_context";

export const EventCalendarLink: React.FC<{ event: FederatedEvent, instance: EventInstance }> = ({
  event,
  instance,
}) => {

  const accountOrServer = useFederatedAccountOrServer(event);
  // const server = accountOrServer.server;
  const isPrimaryServer = useAccountOrServer().server?.host === accountOrServer.server?.host;
  // const currentAndPinnedServers = useCurrentAndPinnedServers();
  const showServerInfo = !isPrimaryServer;
  const primaryInstanceIdString = instance.id;
  const groupContext = useGroupContext();

  const detailsLinkId = showServerInfo
    ? federateId(primaryInstanceIdString, accountOrServer.server)
    : primaryInstanceIdString;
  const groupLinkId = groupContext ?
    (showServerInfo
      ? federateId(groupContext.shortname, accountOrServer.server)
      : groupContext.shortname)
    : undefined;
  const eventLinkPath = groupContext
    ? `/g/${groupLinkId}/e/${detailsLinkId}`
    : `/event/${detailsLinkId}`;
  const eventLink = `http://${window.location.host}${eventLinkPath}`;


  const calendarEvent: CalendarEvent = {
    title: event.post?.title ?? 'Title Data Missing',
    description: `via ${eventLink}:\n${event.post?.content ?? ''}`,
    url: eventLink,
    location: instance.location?.uniformlyFormattedAddress,
    start: moment(instance.startsAt).toISOString(),
    end: moment(instance.endsAt).toISOString(),
    duration: [3, "hour"],
  };

  // Then fetch the link
  // google(calendarEvent); // https://calendar.google.com/calendar/render...
  // outlook(calendarEvent); // https://outlook.live.com/owa/...
  // office365(calendarEvent); // https://outlook.office.com/owa/...
  // yahoo(calendarEvent); // https://calendar.yahoo.com/?v=60&title=...
  // ics(calendarEvent); // standard ICS file based on https://icalendar.org

  const googleLink = useLink({ href: google(calendarEvent) });
  const outlookLink = useLink({ href: outlook(calendarEvent) });
  const office365Link = useLink({ href: office365(calendarEvent) });
  const yahooLink = useLink({ href: yahoo(calendarEvent) });
  const icsLink = useLink({ href: ics(calendarEvent) });

  return <Popover size="$5" allowFlip placement='left'>
    <Popover.Trigger asChild>
      <Button h='auto' icon={Calendar} iconAfter={ArrowRightFromLine} >
        <YStack ai='center'>
          <Paragraph lineHeight='$1' size='$3'>Export to</Paragraph>
          <Paragraph lineHeight='$1' size='$3'>Calendar...</Paragraph>
        </YStack>
      </Button>
    </Popover.Trigger>

    <Popover.Content
      borderWidth={1}
      borderColor="$borderColor"
      enterStyle={{ y: -10, opacity: 0 }}
      exitStyle={{ y: -10, opacity: 0 }}
      elevate
      animation={[
        'quick',
        {
          opacity: {
            overshootClamping: true,
          },
        },
      ]}
    >
      <Popover.Arrow borderWidth={1} borderColor="$borderColor" />

      <YStack space="$3" h='100%'>
        {/* {willAdaptEdit ?
          <Popover.Sheet.ScrollView f={1}> */}
        <Button iconAfter={ExternalLink} my='auto' h='auto' px='$2' {...icsLink}><YStack mr='auto'><Paragraph lineHeight='$1' size='$3'>ICS (iCal/Apple)</Paragraph><Paragraph lineHeight='$1' size='$2'>Calendar</Paragraph></YStack></Button>
        <Button iconAfter={ExternalLink} my='auto' h='auto' px='$2' {...googleLink} target='_blank'><YStack mr='auto'><Paragraph lineHeight='$1' size='$4'>Google</Paragraph><Paragraph lineHeight='$1' size='$2'>Calendar</Paragraph></YStack></Button>
        <Button iconAfter={ExternalLink} my='auto' h='auto' px='$2' {...office365Link} target='_blank'><YStack mr='auto'><Paragraph lineHeight='$1' size='$4'>Office 365</Paragraph><Paragraph lineHeight='$1' size='$2'>Calendar</Paragraph></YStack></Button>
        <Button iconAfter={ExternalLink} my='auto' h='auto' px='$2' {...outlookLink} target='_blank'><YStack mr='auto'><Paragraph lineHeight='$1' size='$4'>Outlook</Paragraph><Paragraph lineHeight='$1' size='$2'>Calendar</Paragraph></YStack></Button>

        {/* </Popover.Sheet.ScrollView>
          : <ScrollView h='$20'>
            <Button my='auto' h='auto' px='$2' {...osmLink} target='_blank'><YStack><Paragraph mx='auto' lineHeight='$1' size='$1'>OpenStreet</Paragraph><Paragraph mx='auto' lineHeight='$1' size='$1'>Map</Paragraph></YStack></Button>
            <Button my='auto' h='auto' px='$2' {...appleMapsLink} target='_blank'><YStack><Paragraph mx='auto' lineHeight='$1' size='$2'>Apple</Paragraph><Paragraph mx='auto' lineHeight='$1' size='$1'>Maps</Paragraph></YStack></Button>
            <Button my='auto' h='auto' px='$2' {...googleMapsLink} target='_blank'><YStack><Paragraph mx='auto' lineHeight='$1' size='$2'>Google</Paragraph><Paragraph mx='auto' lineHeight='$1' size='$1'>Maps</Paragraph></YStack></Button>
          </ScrollView>} */}
      </YStack>
    </Popover.Content>
  </Popover >
};