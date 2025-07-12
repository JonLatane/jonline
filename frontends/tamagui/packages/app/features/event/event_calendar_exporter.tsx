import { FederatedEvent, federateId, useServerTheme } from "app/store";
import React, { useEffect, useState } from "react";

import { EventInstance } from "@jonline/api";
import { Button, Heading, Paragraph, Popover, Tooltip, YStack, useMedia } from "@jonline/ui";
import { ArrowRightFromLine, Calendar, ExternalLink } from "@tamagui/lucide-icons";
import { useAnonymousAuthToken, useCurrentAccountOrServer, useFederatedAccountOrServer } from "app/hooks";
import { CalendarEvent, google, ics, office365, outlook, yahoo } from "calendar-link";
import moment from "moment";
import { useLink } from "solito/link";
import { useGroupContext } from "app/contexts/group_context";
// import { set } from 'immer/dist/internal';
import { highlightedButtonBackground, themedButtonBackground } from "app/utils";
import { useSelector } from "react-redux";
import { selectRsvpData } from "./event_rsvp_manager";

type Props = {
  event: FederatedEvent,
  instance: EventInstance,
  tiny?: boolean;
};
export const EventCalendarExporter: React.FC<Props> = ({
  event,
  instance,
  tiny: inputTiny,
}) => {
  const mediaQuery = useMedia();
  const tiny = inputTiny === true || (inputTiny === undefined && !mediaQuery.gtXs);
  const accountOrServer = useFederatedAccountOrServer(event);
  // const server = accountOrServer.server;
  const isPrimaryServer = useCurrentAccountOrServer().server?.host === accountOrServer.server?.host;
  const serverTheme = useServerTheme(accountOrServer.server);
  const { navTextColor } = serverTheme;
  // const currentAndPinnedServers = useCurrentAndPinnedServers();
  const showServerInfo = !isPrimaryServer;
  const { selectedGroup } = useGroupContext();

  const detailsLinkId = showServerInfo
    ? federateId(instance.id, accountOrServer.server)
    : instance.id;
  const groupLinkId = selectedGroup ?
    (showServerInfo
      ? federateId(selectedGroup.shortname, accountOrServer.server)
      : selectedGroup.shortname)
    : undefined;
  const eventLinkPath = selectedGroup
    ? `/g/${groupLinkId}/e/${detailsLinkId}`
    : `/event/${detailsLinkId}`;

  const { anonymousAuthToken } = useAnonymousAuthToken(instance.id);

  const eventPath = eventLinkPath;
  const hasRsvpAssociated = anonymousAuthToken && (event?.info?.allowsAnonymousRsvps || instance?.info?.rsvpInfo?.allowsAnonymousRsvps);
  const eventLink = hasRsvpAssociated
    ? `http://${window.location.host}${eventPath}?anonymousAuthToken=${encodeURIComponent(anonymousAuthToken)}`
    : `http://${window.location.host}${eventPath}`;

  const rsvpData = useSelector(selectRsvpData(federateId(instance.id, accountOrServer.server)));
  const location = rsvpData?.hiddenLocation ?? instance.location;
  const eventDescription = event.post?.content ?? '';
  const calendarEvent: CalendarEvent = {
    title: event.post?.title ?? 'Title Data Missing',
    description: hasRsvpAssociated
      ? `${eventDescription}\n\nmanage your RSVP at:\n${eventLink}`
      : event.post?.link
        ? `${eventDescription}\n\nvia: ${eventLink}`
        : eventDescription,
    url: event.post?.link ?? eventLink,
    location: location?.uniformlyFormattedAddress,
    start: moment(instance.startsAt).toISOString(),
    end: moment(instance.endsAt).toISOString(),
    // duration: [3, "hour"],
  };

  const googleLink = useLink({ href: google(calendarEvent) });
  const outlookLink = useLink({ href: outlook(calendarEvent) });
  const office365Link = useLink({ href: office365(calendarEvent) });
  const yahooLink = useLink({ href: yahoo(calendarEvent) });
  const icsLink = useLink({ href: ics(calendarEvent) });
  const [open, setOpen] = useState(false);
  const [hasOpened, setHasOpened] = useState(false);
  useEffect(() => {
    if (open && !hasOpened) {
      setHasOpened(true);
    }
  }, [open, hasOpened]);

  return <Tooltip>
    <Tooltip.Trigger zi={100000}>
      <Popover size="$5" stayInFrame onOpenChange={setOpen} placement='bottom-end'>
        <Popover.Trigger asChild>
          <Button my='auto' h={tiny ? '$3' : 'auto'}
            icon={Calendar} iconAfter={ArrowRightFromLine}
            {...highlightedButtonBackground(serverTheme, 'nav')}
          >
            {tiny
              ? undefined
              : <YStack ai='center'>
                {hasRsvpAssociated
                  ? <>
                    <Paragraph color={navTextColor} lineHeight='$1' size='$3'>Export</Paragraph>
                    <Paragraph color={navTextColor} lineHeight='$1' size='$3'>Private Link</Paragraph>
                    <Paragraph color={navTextColor} lineHeight='$1' size='$3'>to Calendar...</Paragraph>
                  </>
                  : <>
                    <Paragraph color={navTextColor} lineHeight='$1' size='$3'>Export to</Paragraph>
                    <Paragraph color={navTextColor} lineHeight='$1' size='$3'>Calendar...</Paragraph>
                  </>}
              </YStack>}
          </Button>
        </Popover.Trigger>

        {hasOpened
          ? <Popover.Content
            borderWidth={1}
            zi={100001}
            borderColor="$borderColor"
            enterStyle={{ y: -10, opacity: 0 }}
            exitStyle={{ y: -10, opacity: 0 }}
            elevate
            animation={[
              'standard',
              {
                opacity: {
                  overshootClamping: true,
                },
              },
            ]}
          >
            <Popover.Arrow borderWidth={1} borderColor="$borderColor" />

            <YStack gap="$3" h='100%'>
              {/* {willAdaptEdit ?
          <Popover.Sheet.ScrollView f={1}> */}
              <Heading size='$1'>{hasRsvpAssociated ? 'Export Private Link' : 'Export'}</Heading>
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
          : undefined}
      </Popover >
    </Tooltip.Trigger>
    {tiny ? <Tooltip.Content zi={100001}>
      <Paragraph lineHeight='$1' size='$3'>Export to Calendar...</Paragraph>
    </Tooltip.Content> : undefined}
  </Tooltip>
};
