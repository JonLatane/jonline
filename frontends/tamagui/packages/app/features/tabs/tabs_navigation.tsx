import { Button, ScrollView, useMedia, WebUserInterface, XStack, YStack } from "@jonline/ui/src";
import { RootState, useTypedSelector } from "app/store/store";
import { useLink } from "solito/link";
import { AccountsSheet } from "../accounts/accounts_sheet";

export type TabsNavigationProps = {
  children?: React.ReactNode;
};
export function TabsNavigation({children}: TabsNavigationProps) {
  // const { tabs, activeTab, setActiveTab } = useTabs();
  const media = useMedia()
  const server = useTypedSelector((state: RootState) => state.servers.server);
  const homeProps = useLink({
    href: server?.serverConfiguration?.serverInfo?.webUserInterface != WebUserInterface.REACT_TAMAGUI ? '/tamagui' : '/',
  })
  return (
    <YStack f={1}>
    <XStack space="$2">
        <Button flex={1} size="$5" {...homeProps}>Home</Button>
        <AccountsSheet />
    </XStack>

    <YStack f={1} jc="center" ai="center" space>
      {children}
    </YStack>
    </YStack>
  );
}