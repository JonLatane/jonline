import { FederatedEvent, federateId } from "app/store";
import React from "react";

import { EventInstance } from "@jonline/api";
import { Button, Paragraph, Popover, Tooltip, YStack, useMedia } from "@jonline/ui";
import { ArrowRightFromLine, Calendar, ExternalLink } from "@tamagui/lucide-icons";
import { useAccountOrServer, useFederatedAccountOrServer } from "app/hooks";
import { CalendarEvent, google, ics, office365, outlook, yahoo } from "calendar-link";
import moment from "moment";
import { useLink } from "solito/link";
import { useGroupContext } from "../../contexts/group_context";

type Props = {
  event: FederatedEvent,
  instance: EventInstance,
  tiny?: boolean;
  anonymousRsvpPath?: string;
};
export const EventCalendarLink: React.FC<Props> = ({
  event,
  instance,
  tiny: inputTiny = false,
  anonymousRsvpPath
}) => {
  const mediaQuery = useMedia();
  const tiny = inputTiny || !mediaQuery.gtXs;
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

  const eventPath = anonymousRsvpPath ?? eventLinkPath;
  const eventLink = `http://${window.location.host}${eventPath}`;

  const calendarEvent: CalendarEvent = {
    title: event.post?.title ?? 'Title Data Missing',
    description: anonymousRsvpPath
      ? `${event.post?.content ?? ''}\n\nmanage your RSVP at:\n${eventLink}`
      : `${event.post?.content ?? ''}\n\nvia: ${eventLink}`,
    url: eventLink,
    location: instance.location?.uniformlyFormattedAddress,
    start: moment(instance.startsAt).toISOString(),
    end: moment(instance.endsAt).toISOString(),
    // duration: [3, "hour"],
  };

  const googleLink = useLink({ href: google(calendarEvent) });
  const outlookLink = useLink({ href: outlook(calendarEvent) });
  const office365Link = useLink({ href: office365(calendarEvent) });
  const yahooLink = useLink({ href: yahoo(calendarEvent) });
  const icsLink = useLink({ href: ics(calendarEvent) });

  return <Tooltip>
    <Tooltip.Trigger>
      <Popover size="$5" allowFlip stayInFrame placement='left'>
        <Popover.Trigger asChild>
          {/* <Tooltip>
        <Tooltip.Trigger> */}

          <Button h={tiny ? '$3' : 'auto'} icon={Calendar} iconAfter={ArrowRightFromLine} >
            {tiny ? undefined : <YStack ai='center'>
              {anonymousRsvpPath
                ? <>
                  <Paragraph lineHeight='$1' size='$3'>Export</Paragraph>
                  <Paragraph lineHeight='$1' size='$3'>Private Link</Paragraph>
                  <Paragraph lineHeight='$1' size='$3'>to Calendar...</Paragraph>
                </>
                : <>
                  <Paragraph lineHeight='$1' size='$3'>Export to</Paragraph>
                  <Paragraph lineHeight='$1' size='$3'>Calendar...</Paragraph>
                </>}
            </YStack>}
          </Button>
          {/* </Tooltip.Trigger>
        {tiny ? <Tooltip.Content>
          <Paragraph lineHeight='$1' size='$3'>Export to Calendar...</Paragraph>
        </Tooltip.Content> : undefined}
      </Tooltip> */}
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
            <Button iconAfter={ExternalLink} my='auto' h='auto' px='$2' {...yahooLink} target='_blank'><YStack mr='auto'><Paragraph lineHeight='$1' size='$4'>Yahoo</Paragraph><Paragraph lineHeight='$1' size='$2'>Calendar</Paragraph></YStack></Button>

            {/* </Popover.Sheet.ScrollView>
          : <ScrollView h='$20'>
            <Button my='auto' h='auto' px='$2' {...osmLink} target='_blank'><YStack><Paragraph mx='auto' lineHeight='$1' size='$1'>OpenStreet</Paragraph><Paragraph mx='auto' lineHeight='$1' size='$1'>Map</Paragraph></YStack></Button>
            <Button my='auto' h='auto' px='$2' {...appleMapsLink} target='_blank'><YStack><Paragraph mx='auto' lineHeight='$1' size='$2'>Apple</Paragraph><Paragraph mx='auto' lineHeight='$1' size='$1'>Maps</Paragraph></YStack></Button>
            <Button my='auto' h='auto' px='$2' {...googleMapsLink} target='_blank'><YStack><Paragraph mx='auto' lineHeight='$1' size='$2'>Google</Paragraph><Paragraph mx='auto' lineHeight='$1' size='$1'>Maps</Paragraph></YStack></Button>
          </ScrollView>} */}
          </YStack>
        </Popover.Content>
      </Popover >
    </Tooltip.Trigger>
    {tiny ? <Tooltip.Content>
      <Paragraph lineHeight='$1' size='$3'>Export to Calendar...</Paragraph>
    </Tooltip.Content> : undefined}
  </Tooltip>
};
