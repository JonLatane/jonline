import { Button, useMedia, WebUserInterface, XStack, YStack, ZStack, ScrollView, Heading } from "@jonline/ui/src";
import { RootState, useTypedSelector } from "app/store/store";
import { useLink } from "solito/link";
import { AccountsSheet } from "../accounts/accounts_sheet";
import { Platform } from 'react-native'
import StickyBox from "react-sticky-box";
import { Home as HomeIcon } from '@tamagui/lucide-icons'
import { JonlineServer } from "app/store/modules/servers";


export type TabsNavigationProps = {
  children?: React.ReactNode;
  onlyShowServer?: JonlineServer;
};
export function TabsNavigation({ children, onlyShowServer }: TabsNavigationProps) {
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
  const serverNameContainsEmoji = /\p{Emoji}/u.test(serverName);
  let account = useTypedSelector((state: RootState) => state.accounts.account);
  let backgroundColorInt = primaryServer?.serverConfiguration?.serverInfo?.colors?.primary;
  let backgroundColor = `#${(backgroundColorInt)?.toString(16).slice(-6) || '424242'}`;
  let navColorInt = primaryServer?.serverConfiguration?.serverInfo?.colors?.navigation;
  let navColor = `#${(navColorInt)?.toString(16).slice(-6) || 'fff'}`;
  let wrapTitle = serverName.length > 20;
  let maxWidth=media.gtXs ? 350 : 250;
  return Platform.select({
    web: <>
      <StickyBox style={{ zIndex: 10 }} className="blur">
        <YStack space="$1" backgroundColor={backgroundColor} opacity={0.87}>
          {/* <XStack h={5}></XStack> */}
          <XStack space="$1" marginVertical={5}>
            <XStack w={5} />
            <Button size="$4" maw={maxWidth} overflow='hidden' ac='flex-start'
              iconAfter={serverNameContainsEmoji ? undefined : HomeIcon}
              {...homeProps}>
                <XStack maw={maxWidth - (serverNameContainsEmoji ? 50 : 0)}>
                <Heading whiteSpace="nowrap">{serverName}</Heading>
                </XStack>
            </Button>
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