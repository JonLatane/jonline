import { Button, Heading, Popover, ScrollView, useMedia, WebUserInterface, XStack, YGroup, YStack } from "@jonline/ui/src";
import { Group } from "@jonline/ui/types";
import { Home as HomeIcon } from '@tamagui/lucide-icons';
import { JonlineServer, RootState, useTypedSelector } from "app/store";
import { Platform } from 'react-native';
import StickyBox from "react-sticky-box";
import { useLink } from "solito/link";
import { AccountsSheet } from "../accounts/accounts_sheet";
import { GroupsSheet } from "../groups/groups_sheet";


export enum AppSection {
  HOME = 'home',
  POSTS = 'posts',
  EVENTS = 'events',
}

export function sectionTitle(section: AppSection) {
  switch (section) {
    case AppSection.HOME:
      return 'Latest';
    case AppSection.POSTS:
      return 'Posts';
    case AppSection.EVENTS:
      return 'Events';
    default:
      return 'Latest';
  }
}

export type TabsNavigationProps = {
  children?: React.ReactNode;
  onlyShowServer?: JonlineServer;
  appSection?: AppSection;
  group?: Group;
};

export function TabsNavigation({ children, onlyShowServer, appSection = AppSection.HOME }: TabsNavigationProps) {
  const media = useMedia()
  const server = useTypedSelector((state: RootState) => state.servers.server);
  const primaryServer = onlyShowServer || server;
  const webUI = server?.serverConfiguration?.serverInfo?.webUserInterface;
  const homeProps = useLink({
    href: webUI == WebUserInterface.REACT_TAMAGUI || webUI == WebUserInterface.HANDLEBARS_TEMPLATES
      ? '/'
      : '/tamagui'
  });
  const serverName = primaryServer?.serverConfiguration?.serverInfo?.name || 'Jonline';
  const app = useTypedSelector((state: RootState) => state.app);
  const serverNameEmoji = serverName.match(/\p{Emoji}/u)?.at(0);
  const account = useTypedSelector((state: RootState) => state.accounts.account);
  const backgroundColorInt = primaryServer?.serverConfiguration?.serverInfo?.colors?.primary;
  const backgroundColor = `#${(backgroundColorInt)?.toString(16).slice(-6) || '424242'}A6`;
  const navColorInt = primaryServer?.serverConfiguration?.serverInfo?.colors?.navigation;
  const navColor = `#${(navColorInt)?.toString(16).slice(-6) || 'fff'}`;
  const wrapTitle = serverName.length > 20;
  const maxWidth = media.gtXs ? 350 : 250;
  return Platform.select({
    web: <>
      <StickyBox style={{ zIndex: 10 }} className="blur">
        <YStack space="$1" backgroundColor={backgroundColor} opacity={0.92}>
          {/* <XStack h={5}></XStack> */}
          <XStack space="$1" marginVertical={5}>
            <XStack w={5} />
            <Button size="$4" maw={maxWidth} overflow='hidden' ac='flex-start'
              iconAfter={serverNameEmoji ? undefined : HomeIcon}
              {...homeProps}>
              <XStack maw={maxWidth - (serverNameEmoji ? 50 : 0)}>
                <Heading whiteSpace="nowrap">{serverName}</Heading>
              </XStack>
            </Button>
            {app.showBetaNavigation ? <>
            <ScrollView horizontal>
              <XStack w={1}/>
              <GroupsSheet />
              <XStack w={3.5}/>
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

                  <YGroup space="$3">
                    {/* <XStack space="$3">
            <Label size="$3" htmlFor={'asdf'}>
              Name
            </Label>
            <Input size="$3" id={'asdf'} />
          </XStack> */}

                    {[AppSection.HOME, AppSection.POSTS, AppSection.EVENTS].map((section) =>
                      <Popover.Close asChild>
                        <Button
                          // bordered={false}
                          transparent
                          size="$3"
                          disabled={appSection == section}
                          onPress={() => { }}
                        >
                          <Heading size="$4">{sectionTitle(section)}</Heading>
                        </Button>
                      </Popover.Close>)
                    }
                  </YGroup>
                </Popover.Content>
              </Popover>
            </ScrollView>
            </> : undefined}
            <XStack f={1} />

            <AccountsSheet size='$4' circular={!media.gtSm} onlyShowServer={onlyShowServer} />
            <XStack w={5} />
          </XStack>
          {/* <XStack h={5}></XStack> */}
        </YStack>
      </StickyBox>
      <YStack f={1} jc="center" ai="center">
        {children}
      </YStack>
    </>,
    default:
      <YStack f={1} jc="center" ai="center">
        <ScrollView f={1}>
          <YStack f={1} jc="center" ai="center">
            {children}
          </YStack>
        </ScrollView>
      </YStack>
  });
}
function hexToRgb(hex) {
  var c;
  if (/^#([A-Fa-f0-9]{3}){1,2}$/.test(hex)) {
    c = hex.substring(1).split('');
    if (c.length == 3) {
      c = [c[0], c[0], c[1], c[1], c[2], c[2]];
    }
    c = '0x' + c.join('');
    return [(c >> 16) & 255, (c >> 8) & 255, c & 255];
  }
  throw new Error('Bad Hex');
}