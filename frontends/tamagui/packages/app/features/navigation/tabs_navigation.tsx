import { Group, WebUserInterface } from "@jonline/api";
import { Button, ScrollView, Theme, ToastViewport, XStack, YStack, useMedia } from "@jonline/ui";
import { Home as HomeIcon } from '@tamagui/lucide-icons';
import { GroupContextProvider, NavigationContextProvider, NavigationContextType, useNavigationContext, useOrCreateNavigationContext } from 'app/contexts';
import { useAppDispatch, useLocalConfiguration, useServer } from "app/hooks";
import { FederatedGroup, JonlineServer, RootState, markGroupVisit, serverID, useRootSelector, useServerTheme } from "app/store";
import { useEffect, useState } from "react";
import StickyBox from "react-sticky-box";
import { useLink } from "solito/link";
import { AccountsSheet } from "../accounts/accounts_sheet";
import { GroupsSheet } from "../groups/groups_sheet";
import { AppSection, AppSubsection, FeaturesNavigation, useInlineFeatureNavigation } from "./features_navigation";
import { PinnedServerSelector } from "./pinned_server_selector";
import { ServerNameAndLogo, splitOnFirstEmoji } from "./server_name_and_logo";
import { TabsTutorial } from "./tabs_tutorial";

export type TabsNavigationProps = {
  children?: React.ReactNode;
  onlyShowServer?: JonlineServer;
  appSection?: AppSection;
  appSubsection?: AppSubsection;
  selectedGroup?: FederatedGroup;
  customHomeAction?: () => void;
  // Forwarder to link to a group page. Defaults to /g/:shortname.
  // But, for instance, post pages can link to /g/:shortname/p/:id.
  groupPageForwarder?: (groupIdentifier: string) => string;
  groupPageExiter?: () => void;
  withServerPinning?: boolean;
};

export const tabNavBaseHeight = 64;

export function TabsNavigation({
  children,
  onlyShowServer,
  appSection = AppSection.HOME,
  appSubsection,
  selectedGroup,
  customHomeAction,
  groupPageForwarder,
  groupPageExiter,
  withServerPinning,
}: TabsNavigationProps) {
  const mediaQuery = useMedia()
  const server = useServer();// useRootSelector((state: RootState) => state.servers.server);
  const primaryServer = onlyShowServer || server;
  const webUI = server?.serverConfiguration?.serverInfo?.webUserInterface;
  const homeProps = customHomeAction ? { onPress: customHomeAction } : useLink({
    href:
      selectedGroup && appSection == AppSection.POSTS ? `/posts` :
        selectedGroup && appSection == AppSection.EVENTS ? `/events` :
          selectedGroup && appSection == AppSection.MEMBERS ? `/people` :
            webUI == WebUserInterface.FLUTTER_WEB
              ? '/tamagui'
              : '/'
  });
  const dispatch = useAppDispatch();
  const serverName = primaryServer?.serverConfiguration?.serverInfo?.name || '...';
  const app = useRootSelector((state: RootState) => state.app);
  const [_serverNameBeforeEmoji, serverNameEmoji, _serverNameAfterEmoji] = splitOnFirstEmoji(serverName, true)
  const backgroundColorInt = primaryServer?.serverConfiguration?.serverInfo?.colors?.primary;
  const backgroundColor = `#${(backgroundColorInt)?.toString(16).slice(-6) || '424242'}FF`;

  const navigationContext: NavigationContextType = useOrCreateNavigationContext();

  const logo = primaryServer?.serverConfiguration?.serverInfo?.logo;

  const { darkMode: systemDark } = useServerTheme();
  const invert = !app.darkModeAuto ? (systemDark != app.darkMode) ? true : false : false;
  const dark = app.darkModeAuto ? systemDark : app.darkMode;
  const bgColor = dark ? '$gray1Dark' : '$gray2Light';
  const shrinkHomeButton = false;/*!mediaQuery.gtMd && (
    selectedGroup != undefined ||
    appSubsection == AppSubsection.FOLLOW_REQUESTS ||
    (app.inlineFeatureNavigation === true && !mediaQuery.gtSm)
  );*/
  const canUseLogo = logo?.wideMediaId != undefined || logo?.squareMediaId != undefined;
  const showHomeIcon = serverNameEmoji == undefined && !canUseLogo && shrinkHomeButton;
  const recentGroupIds = useRootSelector((state: RootState) => server
    ? state.app.serverRecentGroups?.[serverID(server)] ?? []
    : []);
  const { inlineNavigation: inlineFeatureNavigation } = useInlineFeatureNavigation();
  const scrollGroupsSheet = !inlineFeatureNavigation
    || !mediaQuery.gtXs;

  useEffect(() => {
    if (selectedGroup && server && recentGroupIds[0] != selectedGroup.id) {
      dispatch(markGroupVisit({ group: selectedGroup, server }));
    }
  }, [selectedGroup?.id]);

  const useSquareLogo = canUseLogo && logo?.squareMediaId != undefined;
  const useWideLogo = canUseLogo && logo?.wideMediaId != undefined && !shrinkHomeButton;
  const hasEmoji = serverNameEmoji && serverNameEmoji !== '';

  const circularAccountsSheet = !mediaQuery.gtSm;

  return <Theme inverse={invert} key={`tabs-${appSection}-${appSubsection}`}>
    <ToastViewport zi={1000000} multipleToasts left={0} right={0} bottom={11} />

    <NavigationContextProvider value={navigationContext}>
      <GroupContextProvider value={selectedGroup}>

        <YStack w='100%' backgroundColor='$backgroundFocus' jc="center" ac='center' ai="center" minHeight={window.innerHeight}>
          <StickyBox style={{ zIndex: 10, width: '100%' }} className='blur'>
            <YStack backgroundColor={backgroundColor} opacity={0.92} w='100%'>
              <XStack space="$1" my='$1' pl='$1' w='100%'>
                {/* <XStack w={5} /> */}
                <YStack>
                  <AccountsSheet size='$4' circular={circularAccountsSheet} onlyShowServer={onlyShowServer} />
                  <Button //size="$4"
                    id="home-button"
                    py={0}
                    px={
                      shrinkHomeButton && !useWideLogo && !useSquareLogo ? '$3' :
                        !shrinkHomeButton && !useWideLogo && !useSquareLogo && !hasEmoji ? '$2' : 0}
                    height='auto'
                    borderTopLeftRadius={0} borderTopRightRadius={0}
                    width={shrinkHomeButton && useSquareLogo ? 48 : undefined}

                    overflow='hidden'
                    icon={showHomeIcon ? <HomeIcon size='$1' /> : undefined}

                    {...homeProps}
                  >
                    <ServerNameAndLogo shrinkToSquare={shrinkHomeButton}
                      fallbackToHomeIcon
                      server={primaryServer} />
                  </Button>
                </YStack>
                {!scrollGroupsSheet
                  ? <XStack space='$2' ml='$1' my='auto' id='main-groups-button'>
                    <GroupsSheet key='main' selectedGroup={selectedGroup}
                      groupPageForwarder={groupPageForwarder} />
                  </XStack>
                  : undefined}
                <ScrollView horizontal>
                  {!scrollGroupsSheet
                    ? <>
                      <XStack w={2} />
                    </>
                    : <>
                      <XStack w={1} />
                      <XStack className='main-groups-button'>
                        <GroupsSheet key='main' selectedGroup={selectedGroup} groupPageForwarder={groupPageForwarder} />
                      </XStack>
                      <XStack w={3} />
                    </>
                  }
                  <FeaturesNavigation {...{ appSection, appSubsection, selectedGroup }} />
                </ScrollView>
                <XStack f={1} />
                {/* <AccountsSheet size='$4' circular={circularAccountsSheet} onlyShowServer={onlyShowServer} /> */}
                <XStack w={5} />
              </XStack>

              <YStack w='100%' backgroundColor='$background'>
                <TabsTutorial />
              </YStack>

              <XStack w='100%' id='nav-pinned-server-selector'>
                <PinnedServerSelector show={withServerPinning && !selectedGroup} affectsNavigation />
              </XStack>
            </YStack>
          </StickyBox>

          <YStack f={1} w='100%' jc="center" ac='center' ai="center" backgroundColor={bgColor}>
            {children}
          </YStack>
        </YStack>
      </GroupContextProvider>
    </NavigationContextProvider>
  </Theme>;
}
