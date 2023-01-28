import { Button, useMedia, WebUserInterface, XStack, YStack, ZStack, ScrollView, Heading } from "@jonline/ui/src";
import { RootState, useTypedSelector } from "app/store/store";
import { useLink } from "solito/link";
import { AccountsSheet } from "../accounts/accounts_sheet";
import { Platform } from 'react-native'
import StickyBox from "react-sticky-box";
import { Home as HomeIcon } from '@tamagui/lucide-icons'


export type TabsNavigationProps = {
  children?: React.ReactNode;
};
export function TabsNavigation({ children }: TabsNavigationProps) {
  const media = useMedia()
  const server = useTypedSelector((state: RootState) => state.servers.server);
  const homeProps = useLink({
    href: server?.serverConfiguration?.serverInfo?.webUserInterface != WebUserInterface.REACT_TAMAGUI ? '/tamagui' : '/',
  })
  const serverName = server?.serverConfiguration?.serverInfo?.name || 'Jonline';
  let account = useTypedSelector((state: RootState) => state.accounts.account);
  let backgroundColorInt = server?.serverConfiguration?.serverInfo?.colors?.primary;
  let backgroundColor = `#${(backgroundColorInt)?.toString(16).slice(-6) || '424242'}`;
  let navColorInt = server?.serverConfiguration?.serverInfo?.colors?.navigation;
  let navColor = `#${(navColorInt)?.toString(16).slice(-6) || 'fff'}`;

  return Platform.select({
    web: <>
      <StickyBox style={{ zIndex: 10 }} className="blur">
        <YStack space="$1" backgroundColor={backgroundColor} opacity={0.87}>
          {/* <XStack h={5}></XStack> */}
          <XStack space="$1" marginVertical={5}>
            <XStack w={5} />
            <Button size="$5" iconAfter={HomeIcon}  {...homeProps}><Heading>{serverName}</Heading></Button>
            <XStack f={1} />
            <AccountsSheet circular={!media.gtSm} />
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