import { FederatedEvent, FederatedUser, JonlineServer, federateId, selectServer, selectServerById, serverID, useRootSelector, useServerTheme } from "app/store";
import React, { useEffect, useState } from "react";

import { Author, EventInstance, Visibility } from "@jonline/api";
import { Anchor, Button, Heading, Paragraph, Popover, ScrollView, Tooltip, XStack, YStack, ZStack, useMedia, useToastController } from "@jonline/ui";
import { ArrowRightFromLine, Calendar, CalendarArrowDown, Copy, CopyCheck, ExternalLink, Link } from "@tamagui/lucide-icons";
import { useAnonymousAuthToken, useComponentKey, useCurrentAccountOrServer, useFederatedAccountOrServer } from "app/hooks";
import { CalendarEvent, google, ics, office365, outlook, yahoo } from "calendar-link";
import moment from "moment";
import { useLink } from "solito/link";
import { useGroupContext } from "app/contexts/group_context";
// import { set } from 'immer/dist/internal';
import { highlightedButtonBackground, themedButtonBackground } from "app/utils";
import { useSelector } from "react-redux";
import { selectRsvpData } from "./event_rsvp_manager";
import { ServerNameAndLogo, shortenServerName } from "../navigation/server_name_and_logo";
import { AuthorInfo } from "../post";

type Props = {
  event?: FederatedEvent,
  instance?: EventInstance,
  tiny?: boolean;
  showSubscriptions?: {
    user?: FederatedUser,
    servers?: JonlineServer[],
  }
};
export const EventCalendarExporter: React.FC<Props> = ({
  event,
  instance,
  tiny: inputTiny,
  showSubscriptions
}) => {
  const mediaQuery = useMedia();
  const tiny = inputTiny === true || (inputTiny === undefined && !mediaQuery.gtXs);
  const eventAccountOrServer = useFederatedAccountOrServer(event);
  const userSubscriptionAccountOrServerOrDefault = useFederatedAccountOrServer(showSubscriptions?.user);
  const userSubscriptionAccountOrServer = showSubscriptions?.user ? userSubscriptionAccountOrServerOrDefault : eventAccountOrServer;
  const accountOrServer = eventAccountOrServer ?? userSubscriptionAccountOrServer;
  // const server = accountOrServer.server;
  const isPrimaryServer = useCurrentAccountOrServer().server?.host === accountOrServer.server?.host;
  const serverTheme = useServerTheme(accountOrServer.server);
  const { navTextColor } = serverTheme;
  // const currentAndPinnedServers = useCurrentAndPinnedServers();
  const showServerInfo = !isPrimaryServer;
  const { selectedGroup } = useGroupContext();

  const [userSubscriptionAuthor, userSubscriptionHost]: [Author | undefined, string | undefined] = showSubscriptions?.user
    ? [
      Author.create({
        userId: showSubscriptions.user.id,
        avatar: showSubscriptions.user.avatar,
        username: showSubscriptions.user.username,
        realName: showSubscriptions.user.realName,
        permissions: showSubscriptions.user.permissions ?? [],
      }),
      showSubscriptions.user.serverHost
    ]
    : event?.post?.author && event?.post.visibility === Visibility.GLOBAL_PUBLIC
      ? [event?.post?.author, event?.serverHost]
      : [undefined, undefined];
  const [userSubscriptionUrl, userSubscriptionName] = userSubscriptionAuthor && userSubscriptionHost ? [`https://${userSubscriptionHost}/calendar.ics?user_id=${userSubscriptionAuthor.userId}`, userSubscriptionAuthor.realName || userSubscriptionAuthor.username] : [undefined];
  const subscriptionServers = showSubscriptions?.servers ?? [];
  const serverSubscriptionUrls = subscriptionServers.map(server => `https://${server.host}/calendar.ics`);

  const eventLinkId = showServerInfo
    ? federateId(instance?.id ?? '', accountOrServer.server)
    : instance?.id ?? '';
  const groupLinkId = selectedGroup ?
    (showServerInfo
      ? federateId(selectedGroup.shortname, accountOrServer.server)
      : selectedGroup.shortname)
    : undefined;
  const eventLinkPath = selectedGroup
    ? `/g/${groupLinkId}/e/${eventLinkId}`
    : `/event/${eventLinkId}`;

  const { anonymousAuthToken } = useAnonymousAuthToken(instance?.id ?? '');

  const eventPath = eventLinkPath;
  const hasRsvpAssociated = anonymousAuthToken && (event?.info?.allowsAnonymousRsvps || instance?.info?.rsvpInfo?.allowsAnonymousRsvps);
  const eventLink = hasRsvpAssociated
    ? `http://${window.location.host}${eventPath}?anonymousAuthToken=${encodeURIComponent(anonymousAuthToken)}`
    : `http://${window.location.host}${eventPath}`;

  const rsvpData = useSelector(selectRsvpData(federateId(instance?.id ?? '', accountOrServer.server)));
  const location = rsvpData?.hiddenLocation ?? instance?.location;
  const eventDescription = event?.post?.content ?? '';
  const calendarEvent: CalendarEvent = {
    title: event?.post?.title ?? 'Title Data Missing',
    description: hasRsvpAssociated
      ? `${eventDescription}\n\nmanage your RSVP at:\n${eventLink}`
      : event?.post?.link
        ? `${eventDescription}\n\nvia: ${eventLink}`
        : eventDescription,
    url: event?.post?.link ?? eventLink,
    location: location?.uniformlyFormattedAddress,
    start: moment(instance?.startsAt).toISOString(),
    end: moment(instance?.endsAt).toISOString(),
    // duration: [3, "hour"],
  };

  const googleLink = useLink({ href: google(calendarEvent) });
  const outlookLink = useLink({ href: outlook(calendarEvent) });
  const office365Link = useLink({ href: office365(calendarEvent) });
  const yahooLink = useLink({ href: yahoo(calendarEvent) });
  const icsLink = useLink({ href: ics(calendarEvent) });
  const [open, setOpen] = useState(false);
  const [hasOpened, setHasOpened] = useState(false);
  const [copiedUrls, setCopiedUrls] = useState<Set<string>>(new Set());
  const toast = useToastController();
  useEffect(() => {
    if (open && !hasOpened) {
      setHasOpened(true);
    }
  }, [open, hasOpened]);

  const copyToClipboard = async (url: string) => {
    try {
      await navigator.clipboard.writeText(url);
      setCopiedUrls(prev => new Set(prev).add(url));
      toast.show('Copied!');
      
      // Remove the copied state after 5 seconds
      setTimeout(() => {
        setCopiedUrls(prev => {
          const newSet = new Set(prev);
          newSet.delete(url);
          return newSet;
        });
      }, 5000);
    } catch (err) {
      console.error('Failed to copy: ', err);
      toast.show('Copy failed');
    }
  };

  const CopyButton = ({ url, isRightButton = false }: { url: string; isRightButton?: boolean }) => {
    const isCopied = copiedUrls.has(url);
    return (
      <Button 
        my='auto' 
        h='auto' 
        px='$2' 
        onPress={() => copyToClipboard(url)}
        borderTopLeftRadius={isRightButton ? 0 : undefined}
        borderBottomLeftRadius={isRightButton ? 0 : undefined}
        ml={isRightButton ? -1 : undefined} // Overlap border for connected look
      >
        <YStack ai='center' pos='relative'>
          <ZStack w='$2' h='$2'>
            <ZStack animation='standard' o={isCopied ? 0 : 1}>
              <Copy size='$1' />
            </ZStack>
            <ZStack animation='standard' o={isCopied ? 1 : 0}>
              <CopyCheck size='$1' />
            </ZStack>
          </ZStack>
          {isCopied && (
            <Paragraph 
              size='$1' 
              color='$color' 
              pos='absolute' 
              top={-15} 
              whiteSpace='nowrap'
              zi={1000}
            >
              Copied!
            </Paragraph>
          )}
        </YStack>
      </Button>
    );
  };
  const showSubscriptionsSection = (userSubscriptionAuthor && userSubscriptionHost) || subscriptionServers.length > 0;

  const subscriptionsSection = <>
    <Heading size='$4' lineHeight='$1'>Subscribe to Calendar</Heading>
    <Paragraph lineHeight='$1' size='$1'>(iCalendar/RFC 5545)</Paragraph>

    {userSubscriptionAuthor && userSubscriptionHost ?
      <>
        <Paragraph lineHeight='$1' size='$2'>Use this link to subscribe to all of {userSubscriptionName}'s calendar events (you may need to copy/paste the URL):</Paragraph>
        <XStack mx='auto'>
          <Anchor href={userSubscriptionUrl}>
            <Button iconAfter={Link} my='auto' h='auto' px='$2' pointerEvents="none"
              borderTopRightRadius={0}
              borderBottomRightRadius={0}>
              <YStack ai='center'>
                <XStack ai='center'>
                  <AuthorInfo larger author={userSubscriptionAuthor} disableLink />
                  <Heading size='$7' ml='$1'>@</Heading>
                </XStack>
                <ServerNameAndLogo server={userSubscriptionAccountOrServer.server} />
                <Paragraph lineHeight='$1' size='$1'>Calendar Subscription</Paragraph>
              </YStack>
            </Button>
          </Anchor>
          <CopyButton url={userSubscriptionUrl!} isRightButton />
        </XStack>
      </>
      : undefined}
    {subscriptionServers.length > 0 ?
      <>
        <Paragraph lineHeight='$1' size='$3'>
          {subscriptionServers.length === 1
            ? `Use this link to subscribe to public events from ${shortenServerName(subscriptionServers[0])} (you may need to copy/paste the URL):`
            : 'Use these links to subscribe to public events in that community (you may need to copy/paste the URL):'}</Paragraph>
        <XStack flexWrap='wrap' gap='$2' ai='center' jc='space-around' my='$2'>
          {subscriptionServers.map((server, index) => {
            const url = `https://${server.host}/calendar.ics`;
            return (
              <XStack key={index}>
                <Anchor href={url}>
                  <Button iconAfter={Link} my='auto' h='auto' px='$2' pointerEvents="none"
                    borderTopRightRadius={0}
                    borderBottomRightRadius={0}>
                    <YStack ai='center'>
                      <ServerNameAndLogo server={server} />
                      <Paragraph lineHeight='$1' size='$1'>Calendar Subscription</Paragraph>
                    </YStack>
                    {/* <YStack mr='auto'><Paragraph lineHeight='$1' size='$3'>{server.serverConfiguration?.serverInfo?.name}</Paragraph><Paragraph lineHeight='$1' size='$2'>ICS Link</Paragraph></YStack> */}
                  </Button>
                </Anchor>
                <CopyButton url={url} isRightButton />
              </XStack>
            );
          })}
        </XStack>
      </>
      : undefined}
  </>;
  const singleEventExportSection = <>
    <Heading size='$4'>{hasRsvpAssociated ? 'Export Event with Private RSVP Link' : showSubscriptionsSection ? 'Export Single Event ' : 'Export Event'}</Heading>
    <XStack flexWrap='wrap' gap='$2' ai='center' jc='space-around' my='$2'>

      <Button iconAfter={ExternalLink} my='auto' h='auto' px='$2' {...icsLink}><YStack mr='auto'><Paragraph lineHeight='$1' size='$3'>ICS (iCal/Apple)</Paragraph><Paragraph lineHeight='$1' size='$2'>Calendar</Paragraph></YStack></Button>
      <Button iconAfter={ExternalLink} my='auto' h='auto' px='$2' {...googleLink} target='_blank'><YStack mr='auto'><Paragraph lineHeight='$1' size='$4'>Google</Paragraph><Paragraph lineHeight='$1' size='$2'>Calendar</Paragraph></YStack></Button>
      <Button iconAfter={ExternalLink} my='auto' h='auto' px='$2' {...office365Link} target='_blank'><YStack mr='auto'><Paragraph lineHeight='$1' size='$4'>Office 365</Paragraph><Paragraph lineHeight='$1' size='$2'>Calendar</Paragraph></YStack></Button>
      <Button iconAfter={ExternalLink} my='auto' h='auto' px='$2' {...outlookLink} target='_blank'><YStack mr='auto'><Paragraph lineHeight='$1' size='$4'>Outlook</Paragraph><Paragraph lineHeight='$1' size='$2'>Calendar</Paragraph></YStack></Button>
      <Button iconAfter={ExternalLink} my='auto' h='auto' px='$2' {...yahooLink} target='_blank'><YStack mr='auto'><Paragraph lineHeight='$1' size='$4'>Yahoo</Paragraph><Paragraph lineHeight='$1' size='$2'>Calendar</Paragraph></YStack></Button>
    </XStack>

  </>;
  const componentKey = useComponentKey('EventCalendarExporter')
  const buttonTop = document.getElementById(componentKey)?.getBoundingClientRect().top ?? 100;
  return <Tooltip>
    <Tooltip.Trigger zi={100000}>
      <Popover size="$5" stayInFrame onOpenChange={setOpen} placement='bottom-end'>
        <Popover.Trigger asChild>
          <Button my='auto' id={componentKey}
            h={tiny
              ? !!event
                ? '$3'
                : undefined
              : 'auto'}
            iconAfter={CalendarArrowDown}
            {...(event
              ? highlightedButtonBackground(serverTheme, 'nav')
              : { transparent: true })
            }
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
          ?
          <Popover.Content
            borderWidth={1}
            mx='$2'
            px={0}
            py='$1'
            maw='400px'
            mah={Math.max(window.innerHeight - buttonTop - 100, 200)}

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

            <ScrollView>
              <YStack h='100%' px='$2'>
                {hasRsvpAssociated
                  ? <>
                    {event ? singleEventExportSection : undefined}
                    {showSubscriptionsSection ? subscriptionsSection : undefined}
                  </>
                  : <>
                    {showSubscriptionsSection ? subscriptionsSection : undefined}
                    {event ? singleEventExportSection : undefined}
                  </>}
              </YStack>
            </ScrollView>
          </Popover.Content>
          : undefined}
      </Popover >
    </Tooltip.Trigger>
    {tiny ? <Tooltip.Content zi={100001}>
      <Paragraph lineHeight='$1' size='$3'>{event ? "Export to Calendar..." : "Subscribe to Calendars..."}</Paragraph>
    </Tooltip.Content> : undefined}
  </Tooltip>
};
