import { Group } from "@jonline/api";
import { JonlineServer } from "app/store";
import { Button, Heading, Popover, ScrollView, XStack, YStack } from '@jonline/ui';
import { useAccount, useServerTheme } from '../../store/store';
import { useLink } from "solito/link";

export enum AppSection {
  HOME = 'home',
  POSTS = 'posts',
  EVENTS = 'events',
  PEOPLE = 'people',
  GROUPS = 'groups',
}

export enum AppSubsection {
  FOLLOW_REQUESTS = 'follow_requests',
}

export function sectionTitle(section: AppSection) {
  switch (section) {
    case AppSection.HOME:
      return 'Latest';
    case AppSection.POSTS:
      return 'Posts';
    case AppSection.EVENTS:
      return 'Events';
    case AppSection.PEOPLE:
      return 'People';
    case AppSection.GROUPS:
      return 'Groups';
    default:
      return 'Latest';
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
  const { navColor, navTextColor, textColor } = useServerTheme();

  const latestLink = useLink({ href: '/' });
  const peopleLink = useLink({ href: '/people' });
  const followRequestsLink = useLink({ href: '/people/follow_requests' });

  const isLatest = appSection == AppSection.HOME;
  const isPeople = appSection == AppSection.PEOPLE && appSubsection == undefined;
  const isFollowRequests = appSection == AppSection.PEOPLE && appSubsection == AppSubsection.FOLLOW_REQUESTS;

  function navButton(selected, link, name) {
    return <Button
      // bordered={false}
      transparent
      size="$3"
      disabled={selected}
      backgroundColor={selected ? navColor : undefined}
      {...link}
    >
      <Heading size="$4" color={selected ? navTextColor : textColor}>{name}</Heading>
    </Button>;
  }
  return <>
    <XStack w={selectedGroup ? 11 : 3.5} />
    <Popover size="$5">
      <Popover.Trigger asChild>
        <Button transparent>
          <Heading size="$4">{subsectionTitle(appSubsection) ?? sectionTitle(appSection)}</Heading>
        </Button>
      </Popover.Trigger>

      {/* <Adapt when="sm" platform="web">
<Popover.Sheet modal dismissOnSnapToBottom>
<Popover.Sheet.Frame padding="$4">
<Adapt.Contents />
</Popover.Sheet.Frame>
<Popover.Sheet.Overlay />
</Popover.Sheet>
</Adapt> */}

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
          {/* <XStack space="$3">
<Label size="$3" htmlFor={'asdf'}>
Name
</Label>
<Input size="$3" id={'asdf'} />
</XStack> */}

          {[AppSection.HOME/*, AppSection.POSTS, AppSection.EVENTS*/].map((section) => <ScrollView w='100%'><XStack ac='center' jc='center'>
            <Popover.Close asChild>

              {navButton(isLatest, latestLink, sectionTitle(section))}
              {/* <Button
                // bordered={false}
                transparent
                size="$3"
                // disabled={appSection == section}
                onPress={() => { }}
              >
                <Heading size="$4">{sectionTitle(section)}</Heading>
              </Button> */}
            </Popover.Close>
            {account ? <>
              {/* <Popover.Close asChild>
              <Button
                // bordered={false}
                transparent
                size="$3"
                // disabled={appSection == section}
                onPress={() => { }}
              >
                <Heading size="$4">Following</Heading>
              </Button>
            </Popover.Close> */}
              {/* <Popover.Close asChild>
              <Button
                // bordered={false}
                transparent
                size="$3"
                // disabled={appSection == section}
                onPress={() => { }}
              >
                <Heading size="$4">Groups</Heading>
              </Button>
            </Popover.Close> */}
            </> : undefined}
          </XStack>
          </ScrollView>)
          }
          <XStack ac='center' jc='center' space='$2'>

            <Popover.Close asChild>
              {navButton(isPeople, peopleLink, 'People')}
              {/* <Button
                // bordered={false}
                transparent
                size="$3"
                disabled={isPeople}
                backgroundColor={isPeople ? navColor : undefined}
                {...peopleLink}
              >
                <Heading size="$4" color={isPeople ? navTextColor : textColor}>People</Heading>
              </Button> */}
            </Popover.Close>
            {account ? <>
              <Popover.Close asChild>
                {navButton(isFollowRequests, followRequestsLink, 'Follow Requests')}
                {/* <Button
                  // bordered={false}
                  transparent
                  size="$3"
                  disabled={isFollowRequests}
                  backgroundColor={isFollowRequests ? navColor : undefined}
                  {...followRequestsLink}
                >
                  <Heading size="$4" color={isFollowRequests ? navTextColor : textColor}>Follow Requests</Heading>
                </Button> */}
              </Popover.Close>
            </> : undefined}
          </XStack>
          {/* <XStack ac='center' jc='center'>

            <Popover.Close asChild>
              <Button
                // bordered={false}
                transparent
                size="$3"
                disabled={appSection == AppSection.GROUPS}
                onPress={() => { }}
              >
                <Heading size="$4">{sectionTitle(AppSection.GROUPS)}</Heading>
              </Button>
            </Popover.Close>
            {account ? <><Popover.Close asChild>
              <Button
                // bordered={false}
                transparent
                size="$3"
                disabled={appSection == AppSection.GROUPS}
                onPress={() => { }}
              >
                <Heading size="$4">Member Requests</Heading>
              </Button>
            </Popover.Close></> : undefined}
          </XStack> */}
        </YStack>
      </Popover.Content>
    </Popover>
  </>
}