import { Group, User, UserListingType } from "@jonline/api";
import { Button, Heading, Popover, Tooltip, XStack, YStack, useMedia } from '@jonline/ui';
import { Calendar, Clapperboard, Menu, MessageSquare, SeparatorVertical, Users2 } from "@tamagui/lucide-icons";
import { useCurrentAccountOrServer, useCredentialDispatch, useLocalConfiguration, useCurrentServer, usePinnedAccountsAndServers } from "app/hooks";
import { FederatedGroup, RootState, federateId, getFederated, getUsersPage, loadUsersPage, useRootSelector, useServerTheme } from 'app/store';
import { themedButtonBackground } from 'app/utils';
import { useCallback, useEffect, useState } from "react";
import { useLink } from "solito/link";
import { useUsersPage } from '../../hooks/pagination/user_pagination_hooks';
import FlipMove from "lumen5-react-flip-move";
import { useMediaContext } from "app/contexts";

export enum AppSection {
  NONE = 'none',
  HOME = 'home',
  POSTS = 'posts',
  // POST = 'post',
  EVENTS = 'events',
  // EVENT = 'event',
  PEOPLE = 'people',
  MEMBERS = 'members',
  MEMBER = 'member',
  PROFILE = 'profile',
  GROUPS = 'groups',
  GROUP = 'group',
  MEDIA = 'media',
  INFO = 'info',
}

const MENU_SECTIONS = [
  AppSection.HOME,
  AppSection.POSTS,
  // AppSection.POST,
  AppSection.EVENTS,
  // AppSection.EVENT,
  AppSection.PEOPLE,
  AppSection.MEMBERS,
  AppSection.MEMBER,
  AppSection.MEDIA,
];

export function menuIcon(section: AppSection, color?: string) {
  switch (section) {
    // case AppSection.HOME:
    //   return <Circle color={color} />;
    case AppSection.POSTS:
      return <MessageSquare color={color} />;
    case AppSection.EVENTS:
      return <Calendar color={color} />;
    case AppSection.PEOPLE:
    case AppSection.MEMBERS:
      return <Users2 color={color} />;
    case AppSection.MEDIA:
      return <Clapperboard color={color} />;
    default:
      return undefined;
  }
}

export enum AppSubsection {
  FOLLOW_REQUESTS = 'follow_requests',
  MEMBER_REQUESTS = 'follow_requests',
}

export function sectionTitle(section: AppSection): string {
  switch (section) {
    case AppSection.NONE:
      return 'No AppSection';
    case AppSection.HOME:
      return 'Latest';
    case AppSection.POSTS:
      return 'Posts';
    // case AppSection.POST:
    //   return 'Post';
    case AppSection.EVENTS:
      return 'Events';
    // case AppSection.EVENT:
    //   return 'Event';
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
    case AppSection.MEMBERS:
      return 'Members';
    case AppSection.MEMBER:
      return 'Member';
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

export function useInlineFeatureNavigation() {
  const mediaQuery = useMedia();
  const { inlineFeatureNavigation, shrinkFeatureNavigation } = useLocalConfiguration();

  return {
    shrinkNavigation: shrinkFeatureNavigation || shrinkFeatureNavigation === undefined && !mediaQuery.gtSm,
    inlineNavigation: inlineFeatureNavigation || inlineFeatureNavigation === undefined && mediaQuery.gtXxxs
  };
}

export type FeaturesNavigationProps = {
  appSection?: AppSection;
  appSubsection?: AppSubsection;
  selectedGroup?: FederatedGroup;
  disabled?: boolean;
};

export function FeaturesNavigation({ appSection = AppSection.HOME, appSubsection, selectedGroup, disabled }: FeaturesNavigationProps) {
  // const { account, server } = useCurrentAccountOrServer();
  const server = useCurrentServer();
  const hasAccount = usePinnedAccountsAndServers({ includeUnpinned: true }).filter(aos => !!aos.account?.user?.id).length > 0;
  const mediaQuery = useMedia();
  const { /*textColor, */primaryTextColor, navColor, navTextColor } = useServerTheme();

  const groupIdentifier = selectedGroup
    ? (selectedGroup?.serverHost === server?.host
      ? selectedGroup.shortname
      : federateId(selectedGroup.shortname, selectedGroup.serverHost))
    : undefined;

  const latestLink = useLink({
    href:
      selectedGroup === undefined ? '/' : `/g/${groupIdentifier}`
  });
  const postsLink = useLink({
    href:
      selectedGroup === undefined ? '/posts' : `/g/${groupIdentifier}/posts`
  });
  const eventsLink = useLink({
    href:
      selectedGroup === undefined ? '/events' : `/g/${groupIdentifier}/events`
  });
  const peopleLink = useLink({
    href:
      selectedGroup === undefined ? '/people' : `/g/${groupIdentifier}/members`
  });
  const followRequestsLink = useLink({ href: '/people/follow_requests' });

  const myMediaLink = {
    onPress: () => {
      if (popoverOpen) setPopoverOpen(false);
      setMediaSheetOpen(true);
    }
  };

  const isLatest = appSection == AppSection.HOME;
  const isPosts = appSection == AppSection.POSTS;
  const isEvents = appSection == AppSection.EVENTS;
  const isMedia = appSection == AppSection.MEDIA;

  const isPeople = appSection == AppSection.PEOPLE && appSubsection == undefined;
  const isFollowRequests = appSection == AppSection.PEOPLE && appSubsection == AppSubsection.FOLLOW_REQUESTS;

  const isMembers = appSection == AppSection.MEMBERS && appSubsection == undefined;
  const isMemberRequests = appSection == AppSection.MEMBERS && appSubsection == AppSubsection.MEMBER_REQUESTS;

  const { inlineNavigation, shrinkNavigation } = useInlineFeatureNavigation();

  const reorderInlineNavigation = !mediaQuery.gtMd && hasAccount;// && !menuItems.includes(appSection));
  const inlineNavSeparators = inlineNavigation && hasAccount /*&& mediaQuery.gtMd*/;

  // const { results: followRequests } = useUsersPage(UserListingType.FOLLOW_REQUESTS, 0);
  // useRootSelector((state: RootState) =>
  //   getUsersPage(state.users, UserListingType.FOLLOW_REQUESTS, 0));
  const { results: followRequests } = useUsersPage(UserListingType.FOLLOW_REQUESTS, 0);
  const followRequestCount = followRequests?.length ?? 0;
  // const followPageStatus = useRootSelector((state: RootState) => getFederated(state.users.pagesStatus, server));

  // const { dispatch, accountOrServer } = useCredentialDispatch();
  // const [loadingUsers, setLoadingUsers] = useState(false);
  // useEffect(() => {
  //   if (loadingUsers == undefined && !loadingUsers) {
  //     if (!accountOrServer.server) return;

  //     console.log("Loading users...");
  //     setLoadingUsers(true);
  //     dispatch(loadUsersPage({ listingType: UserListingType.FOLLOW_REQUESTS, ...accountOrServer }));
  //   } else if (followPageStatus == 'loaded' && loadingUsers) {
  //     setLoadingUsers(false);
  //     // dismissScrollPreserver(setShowScrollPreserver);
  //   }
  // });


  const showFollowRequests = hasAccount && (
    (!inlineNavigation || (!reorderInlineNavigation && appSubsection == AppSubsection.FOLLOW_REQUESTS))
    || followRequestCount > 0
    || isPeople
  );
  const triggerButton = useCallback((forPopup?: boolean) => {
    const icon = inlineNavigation && appSubsection
      ? undefined
      : (menuIcon(appSection, navTextColor)
        ?? (inlineNavigation
          ? undefined
          : <Menu color={navTextColor} />));
    const triggerButtonLink =
      forPopup ? undefined
        : appSection === AppSection.EVENTS && !location.toString().includes('/events')
          ? eventsLink
          : appSection === AppSection.POSTS && !location.toString().includes('/posts')
            ? postsLink
            : appSection === AppSection.PEOPLE && !location.toString().includes('/people')
              ? peopleLink
              : undefined;
    return <div key={`nav-${appSection}-${appSubsection}`}>
      <Button scale={0.95} ml={selectedGroup ? -4 : -3} my='auto'
        // disabled={inlineNavigation}
        {...(triggerButtonLink ?? {})}
        onPress={triggerButtonLink?.onPress
          ?? (inlineNavigation
            ? () => window.scrollTo({ top: 0, behavior: 'smooth' })
            : undefined)}
        // icon={inlineNavigation ? undefined : <Menu color={navTextColor} />}
        {...themedButtonBackground(navColor)}>
        <XStack gap='$2'>
          {icon}
          <Heading f={1} size="$4" color={navTextColor} textDecorationLine='none'>
            {subsectionTitle(appSubsection) ?? sectionTitle(appSection)}
          </Heading>
        </XStack>
      </Button>
    </div>;
  }, [appSection, appSubsection, inlineNavigation, navTextColor, selectedGroup]);

  const navButton = useCallback((selected: boolean, link: object, section: AppSection, subsection?: AppSubsection, count?: number) => {
    const baseName = (
      subsection
        ? subsectionTitle(subsection)
        : undefined
    ) ?? sectionTitle(section);
    const name = count && count > 0
      ? `${baseName} (${count})`
      : baseName;
    const textColor = selected
      ? navTextColor
      : inlineNavigation
        ? primaryTextColor
        : undefined;
    const icon = !subsection
      ? menuIcon(section, textColor)
      : undefined;

    const triggerButtonLink =
      // forPopup ? undefined  
      section === AppSection.EVENTS && !location.toString().includes('/events')
        ? eventsLink
        : section === AppSection.POSTS && !location.toString().includes('/posts')
          ? postsLink
          : section === AppSection.PEOPLE && !location.toString().includes('/people')
            ? peopleLink
            : undefined;
    const isDisabled = (selected && !triggerButtonLink) || disabled;
    return selected && inlineNavigation ?
      !reorderInlineNavigation
        ? triggerButton()
        : undefined
      : <div key={`nav-${section}-${subsection}`}>
        <Popover.Close asChild>
          <Tooltip>
            <Tooltip.Trigger>
              <Button
                // bordered={false}
                transparent

                my='auto'
                size="$3"
                disabled={isDisabled}
                o={isDisabled ? 0.5 : 1}
                backgroundColor={selected ? navColor : undefined}
                hoverStyle={{ backgroundColor: '$colorTransparent' }}
                {...triggerButtonLink ?? link}
              >
                <XStack gap='$2'>
                  {icon}
                  {!inlineNavigation || !shrinkNavigation || !icon
                    ? <Heading size="$4" color={textColor}>
                      {name}
                    </Heading>
                    : undefined}
                </XStack>
              </Button>
            </Tooltip.Trigger>
            {inlineNavigation && shrinkNavigation
              ? <Tooltip.Content>
                <Heading size='$2'>{name}</Heading>
              </Tooltip.Content>
              : undefined
            }
          </Tooltip>
        </Popover.Close>
      </div>;
  }, [appSection, appSubsection, inlineNavigation, navTextColor, selectedGroup, reorderInlineNavigation, shrinkNavigation]);

  const [latest, posts, events] = [
    navButton(isLatest, latestLink, AppSection.HOME),
    navButton(isPosts, postsLink, AppSection.POSTS),
    navButton(isEvents, eventsLink, AppSection.EVENTS),
  ];

  const postsEventsRow = selectedGroup ?
    inlineNavigation && reorderInlineNavigation && (appSection == AppSection.EVENTS)
      ? [latest, events, posts]
      : [latest, posts, events]
    : inlineNavigation && reorderInlineNavigation
      ? (appSection == AppSection.EVENTS)
        ? [events, posts]
        : [posts, events]
      //  appSection === AppSection.HOME//(appSection == AppSection.POSTS || appSection == AppSection.MEDIA || appSection == AppSection.INFO || appSection == AppSection.GROUP || appSection == AppSection.PEOPLE)
      //   ? [posts, events]
      //   : [latest, posts, events]
      : [
        appSection === AppSection.HOME && inlineNavigation
          ? latest : undefined,
        posts,
        events
      ];

  const peopleRow = [
    selectedGroup
      ? navButton(isMembers, peopleLink, AppSection.MEMBERS)
      : navButton(isPeople, peopleLink, AppSection.PEOPLE),
    showFollowRequests ? navButton(isFollowRequests, followRequestsLink,
      AppSection.PEOPLE, AppSubsection.FOLLOW_REQUESTS, followRequestCount
    ) : undefined,
  ];
  const isPeopleRow = isPeople || isFollowRequests;

  const { setMediaSheetOpen } = useMediaContext();
  const myDataRow = [
    hasAccount ? navButton(isMedia, myMediaLink, AppSection.MEDIA) : undefined
  ];

  const inlineSeparator = (index: number | string) => inlineNavSeparators
    ? <div key={`separator-${index}`}>
      <XStack my='auto'>
        <SeparatorVertical color={primaryTextColor} size='$1' />
      </XStack>
    </div>
    : undefined;

  const [popoverOpen, setPopoverOpen] = useState(false);



  // console.log('inlineNavigation', inlineNavigation, 'reorderInlineNavigation', reorderInlineNavigation, menuItems.includes(appSection));
  return inlineNavigation
    ? <>
      <XStack key='feature-nav-spacer' w={selectedGroup ? 11 : 3.5} />
      <FlipMove key='feature-navigation'
        style={{ display: 'flex', flexDirection: 'row', alignItems: 'center' }}>
        {!reorderInlineNavigation && MENU_SECTIONS.includes(appSection)
          ? undefined
          : triggerButton()}
        {/* <div key='spacer'>
        </div> */}
        {/* <XStack w={selectedGroup ? 11 : 3.5} /> */}
        {/* <XStack gap='$2' ml='$1' my='auto'> */}
        {isPeopleRow && reorderInlineNavigation ? peopleRow : postsEventsRow}
        {inlineSeparator(1)}
        {isPeopleRow && reorderInlineNavigation ? postsEventsRow : peopleRow}
        {isMedia && reorderInlineNavigation ? undefined : inlineSeparator(2)}
        {myDataRow}
        {/* </XStack> */}

      </FlipMove>
    </>
    : <>
      <XStack w={selectedGroup ? 11 : 3.5} />
      <Popover size="$5" open={popoverOpen} onOpenChange={setPopoverOpen}>
        <Popover.Trigger asChild>
          {triggerButton(true)}
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

          <YStack gap="$3">
            <XStack ac='center' jc='center' gap='$2'>
              {postsEventsRow}
            </XStack>
            <XStack ac='center' jc='center' gap='$2'>
              {peopleRow}
            </XStack>
            <XStack ac='center' jc='center' gap='$2'>
              {myDataRow}
            </XStack>
          </YStack>
        </Popover.Content>
      </Popover>
    </>;
}
