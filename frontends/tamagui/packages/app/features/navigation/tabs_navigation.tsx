import { Group, WebUserInterface } from "@jonline/api";
import { Button, ScrollView, Theme, ToastViewport, XStack, YStack, useMedia } from "@jonline/ui";
import { Home as HomeIcon } from '@tamagui/lucide-icons';
import { useAppDispatch, useLocalConfiguration } from "app/hooks";
import { JonlineServer, RootState, markGroupVisit, serverID, useRootSelector, useServerTheme } from "app/store";
import { useEffect } from "react";
import StickyBox from "react-sticky-box";
import { useLink } from "solito/link";
import { AccountsSheet } from "../accounts/accounts_sheet";
import { GroupContextProvider } from "../groups/group_context";
import { GroupsSheet } from "../groups/groups_sheet";
import { AppSection, AppSubsection, FeaturesNavigation, useInlineFeatureNavigation } from "./features_navigation";
import { ServerNameAndLogo, splitOnFirstEmoji } from "./server_name_and_logo";
import { TabsTutorial } from "./tabs_tutorial";
import { PinnedServerSelector } from "./pinned_server_selector";

export type TabsNavigationProps = {
  children?: React.ReactNode;
  onlyShowServer?: JonlineServer;
  appSection?: AppSection;
  appSubsection?: AppSubsection;
  selectedGroup?: Group;
  customHomeAction?: () => void;
  // Forwarder to link to a group page. Defaults to /g/:shortname.
  // But, for instance, post pages can link to /g/:shortname/p/:id.
  groupPageForwarder?: (group: Group) => string;
  groupPageExiter?: () => void;
  withServerPinning?: boolean;
};

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
  const server = useRootSelector((state: RootState) => state.servers.server);
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

  const logo = primaryServer?.serverConfiguration?.serverInfo?.logo;

  const { darkMode: systemDark } = useServerTheme();
  const invert = !app.darkModeAuto ? (systemDark != app.darkMode) ? true : false : false;
  const dark = app.darkModeAuto ? systemDark : app.darkMode;
  const bgColor = dark ? '$gray1Dark' : '$gray2Light';
  const shrinkHomeButton = !mediaQuery.gtMd && (
    selectedGroup != undefined ||
    appSubsection == AppSubsection.FOLLOW_REQUESTS ||
    (app.inlineFeatureNavigation === true && !mediaQuery.gtSm)
  );
  const canUseLogo = logo?.wideMediaId != undefined || logo?.squareMediaId != undefined;
  const showHomeIcon = serverNameEmoji == undefined && !canUseLogo && shrinkHomeButton;
  const renderHomeButtonChildren = !shrinkHomeButton || serverNameEmoji || canUseLogo;
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

  const { showPinnedServers } = useLocalConfiguration();

  return <Theme inverse={invert} key={`tabs-${appSection}-${appSubsection}`}>
    <ToastViewport zi={1000000} multipleToasts left={0} right={0} bottom={11} />

    <GroupContextProvider value={selectedGroup}>

      <YStack backgroundColor='$backgroundFocus' jc="center" ac='center' ai="center" minHeight={window.innerHeight}>
        <StickyBox style={{ zIndex: 10, width: '100%' }} className="blur">
          <YStack space="$1" backgroundColor={backgroundColor} opacity={0.92}>
            <XStack space="$1" marginVertical={5}>
              <XStack w={5} />
              <Button //size="$4"
                className="home-button"
                py={0}
                px={
                  shrinkHomeButton && !useWideLogo && !useSquareLogo ? '$3' :
                    !shrinkHomeButton && !useWideLogo && !useSquareLogo && !hasEmoji ? '$2' : 0}
                height={48}
                width={shrinkHomeButton && useSquareLogo ? 48 : undefined}

                overflow='hidden'
                icon={showHomeIcon ? <HomeIcon size='$1' /> : undefined}
                {...homeProps}
              >
                {renderHomeButtonChildren
                  ? <ServerNameAndLogo shrinkToSquare={shrinkHomeButton}
                    fallbackToHomeIcon
                    server={primaryServer} />
                  : undefined}
              </Button>
              {!scrollGroupsSheet
                ? <XStack space='$2' ml='$1' my='auto' className='main-groups-button'>
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
              <AccountsSheet size='$4' circular={circularAccountsSheet} onlyShowServer={onlyShowServer} />
              <XStack w={5} />
            </XStack>


            <PinnedServerSelector show={showPinnedServers && withServerPinning} />
          </YStack>
        </StickyBox>
        <TabsTutorial />
        <YStack f={1} w='100%' jc="center" ac='center' ai="center" backgroundColor={bgColor}>
          {children}
        </YStack>
      </YStack>
    </GroupContextProvider>
  </Theme>;
}
