import { Group } from "@jonline/api";
import { JonlineServer } from "app/store";
import { Button, Heading, Popover, ScrollView, XStack, YStack } from '@jonline/ui';
import { useAccount, useLocalApp, useServerTheme } from 'app/store';
import { useLink } from "solito/link";
import { AlertTriangle } from "@tamagui/lucide-icons";
import { themedButtonBackground } from 'app/utils/themed_button_background';

export enum AppSection {
  HOME = 'home',
  POSTS = 'posts',
  POST = 'post',
  EVENTS = 'events',
  EVENT = 'event',
  PEOPLE = 'people',
  PROFILE = 'profile',
  GROUPS = 'groups',
  GROUP = 'group',
  MEDIA = 'media',
  INFO = 'info',
}

export enum AppSubsection {
  FOLLOW_REQUESTS = 'follow_requests',
}

export function sectionTitle(section: AppSection): string {
  switch (section) {
    case AppSection.HOME:
      return 'Latest';
    case AppSection.POSTS:
      return 'Posts';
    case AppSection.POST:
      return 'Post';
    case AppSection.EVENTS:
      return 'Events';
    case AppSection.EVENT:
      return 'Event';
    case AppSection.PEOPLE:
      return 'People';
    case AppSection.PROFILE:
      return 'Profile';
    case AppSection.GROUPS:
      return 'Groups';
    case AppSection.GROUP:
      return 'Group';
    case AppSection.MEDIA:
      return 'My Media';
    case AppSection.INFO:
      return 'Info';
    // default:
    //   return 'Latest';
  }
}
export function subsectionTitle(subsection?: AppSubsection): string | undefined {
  switch (subsection) {
    case AppSubsection.FOLLOW_REQUESTS:
      return 'Follow Requests';
    default:
      return undefined;
  }
}

export type FeaturesNavigationProps = {
  appSection?: AppSection;
  appSubsection?: AppSubsection;
  selectedGroup?: Group;
  // Forwarder to link to a group page. Defaults to /g/:shortname.
  // But, for instance, post pages can link to /g/:shortname/p/:id.
  groupPageForwarder?: (group: Group) => string;
};

export function FeaturesNavigation({ appSection = AppSection.HOME, appSubsection, selectedGroup, groupPageForwarder }: FeaturesNavigationProps) {
  const account = useAccount();
  const { primaryTextColor, navColor, navTextColor, textColor } = useServerTheme();

  const latestLink = useLink({
    href:
      selectedGroup == undefined ? '/' : `/g/${selectedGroup.shortname}`
  });
  const postsLink = useLink({
    href:
      selectedGroup == undefined ? '/posts' : `/g/${selectedGroup.shortname}/posts`
  });
  const eventsLink = useLink({
    href:
      selectedGroup == undefined ? '/events' : `/g/${selectedGroup.shortname}/events`
  });
  const peopleLink = useLink({ href: '/people' });
  const followRequestsLink = useLink({ href: '/people/follow_requests' });
  const myMediaLink = useLink({ href: '/media' });

  const isLatest = appSection == AppSection.HOME;
  const isPosts = appSection == AppSection.POSTS;
  const isEvents = appSection == AppSection.EVENTS;
  const isMedia = appSection == AppSection.MEDIA;
  const isPeople = appSection == AppSection.PEOPLE && appSubsection == undefined;
  const isFollowRequests = appSection == AppSection.PEOPLE && appSubsection == AppSubsection.FOLLOW_REQUESTS;

  function navButton(selected, link, name) {
    return <Popover.Close asChild>
      <Button
        // bordered={false}
        transparent
        size="$3"
        disabled={selected}
        o={selected ? 0.5 : 1}
        backgroundColor={selected ? navColor : undefined}
        {...link}
      >
        <Heading size="$4" color={selected ? navTextColor : textColor}>{name}</Heading>
      </Button>
    </Popover.Close>;
  }
  return <>
    <XStack w={selectedGroup ? 11 : 3.5} />
    <Popover size="$5">
      <Popover.Trigger asChild>
        <Button scale={0.95} ml={selectedGroup ? -4 : -3} {...themedButtonBackground(navColor)}>
          <Heading size="$4"
            // color={primaryTextColor}
            color={navTextColor}
          >{subsectionTitle(appSubsection) ?? sectionTitle(appSection)}</Heading>
        </Button>
      </Popover.Trigger>
      <Popover.Content
        bw={1}
        boc="$borderColor"
        enterStyle={{ x: 0, y: -10, o: 0 }}
        exitStyle={{ x: 0, y: -10, o: 0 }}
        x={0}
        y={0}
        o={1}
        animation={[
          'quick',
          {
            opacity: {
              overshootClamping: true,
            },
          },
        ]}
        elevate
      >
        <Popover.Arrow bw={1} boc="$borderColor" />

        <YStack space="$3">
          <XStack ac='center' jc='center' space='$2'>
            {navButton(isLatest, latestLink, sectionTitle(AppSection.HOME))}
            {navButton(isPosts, postsLink, sectionTitle(AppSection.POSTS))}
            {navButton(isEvents, eventsLink, sectionTitle(AppSection.EVENTS))}
          </XStack>
          <XStack ac='center' jc='center' space='$2'>
            {navButton(isPeople, peopleLink, 'People')}
            {account ? navButton(isFollowRequests, followRequestsLink, 'Follow Requests') : undefined}
          </XStack>
          {account ?
            <XStack ac='center' jc='center' space='$2'>
              {account ? navButton(isMedia, myMediaLink, 'My Media') : undefined}
            </XStack> : undefined}
        </YStack>
      </Popover.Content>
    </Popover>
  </>
}
