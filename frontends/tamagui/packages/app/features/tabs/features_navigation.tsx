import { Group } from "@jonline/api";
import { JonlineServer } from "app/store";
import { Button, Heading, Popover, ScrollView, XStack, YStack } from '@jonline/ui';
import { useAccount } from '../../store/store';

export enum AppSection {
  HOME = 'home',
  POSTS = 'posts',
  EVENTS = 'events',
  PEOPLE = 'people',
  GROUPS = 'groups',
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

export type FeaturesNavigationProps = {
  appSection?: AppSection;
  selectedGroup?: Group;
  // Forwarder to link to a group page. Defaults to /g/:shortname.
  // But, for instance, post pages can link to /g/:shortname/p/:id.
  groupPageForwarder?: (group: Group) => string;
};

export function FeaturesNavigation({ appSection = AppSection.HOME, selectedGroup, groupPageForwarder }: FeaturesNavigationProps) {
  const account = useAccount();
  return <>
    <XStack w={selectedGroup ? 11 : 3.5} />
    <Popover size="$5">
      <Popover.Trigger asChild>
        <Button transparent>
          <Heading size="$4">{sectionTitle(appSection)}</Heading>
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
              <Button
                // bordered={false}
                transparent
                size="$3"
                // disabled={appSection == section}
                onPress={() => { }}
              >
                <Heading size="$4">{sectionTitle(section)}</Heading>
              </Button>
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
          <XStack ac='center' jc='center'>

            <Popover.Close asChild>
              <Button
                // bordered={false}
                transparent
                size="$3"
                disabled={appSection == AppSection.PEOPLE}
                onPress={() => { }}
              >
                <Heading size="$4">{sectionTitle(AppSection.PEOPLE)}</Heading>
              </Button>
            </Popover.Close>
            {account ? <><Popover.Close asChild>
              <Button
                // bordered={false}
                transparent
                size="$3"
                disabled={appSection == AppSection.PEOPLE}
                onPress={() => { }}
              >
                <Heading size="$4">Follow Requests</Heading>
              </Button>
            </Popover.Close></> : undefined}
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