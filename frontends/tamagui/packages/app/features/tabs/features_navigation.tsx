import { Group } from "@jonline/api";
import { JonlineServer } from "app/store";
import { Button, Heading, Popover, ScrollView, XStack, YStack } from '@jonline/ui';
import { useAccount, useLocalApp, useServerTheme } from '../../store/store';
import { useLink } from "solito/link";
import { AlertTriangle } from "@tamagui/lucide-icons";

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
      return 'Media';
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
  const app = useLocalApp();
  const { navColor, navTextColor, textColor } = useServerTheme();

  const latestLink = useLink({ href: '/' });
  const postsLink = useLink({ href: '/posts' });
  const eventsLink = useLink({ href: '/events' });
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
        <Button transparent>
          <Heading size="$4">{subsectionTitle(appSubsection) ?? sectionTitle(appSection)}</Heading>
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
            {app.showBetaNavigation || isPosts || isEvents ? <>
              {/* {!app.showBetaNavigation ? <YStack marginVertical='auto' mr='$2'><AlertTriangle size='$1' /></YStack> : undefined} */}
              {navButton(isPosts, postsLink, sectionTitle(AppSection.POSTS))}
              <YStack mr='$2' />
              {navButton(isEvents, eventsLink, sectionTitle(AppSection.EVENTS))}
            </> : undefined}
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
