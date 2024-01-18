import { Group, WebUserInterface } from "@jonline/api";
import { Button, ScrollView, Theme, ToastViewport, XStack, YStack, useMedia } from "@jonline/ui";
import { ChevronRight, Home as HomeIcon } from '@tamagui/lucide-icons';
import { GroupContextProvider, NavigationContextProvider, NavigationContextType, useNavigationContext, useOrCreateNavigationContext } from 'app/contexts';
import { useAppDispatch, useLocalConfiguration, useServer } from "app/hooks";
import { Federated, FederatedEntity, FederatedGroup, JonlineServer, RootState, colorMeta, federatedId, markGroupVisit, serverID, useRootSelector, useServerTheme } from "app/store";
import { useEffect, useState } from "react";
import StickyBox from "react-sticky-box";
import { useLink } from "solito/link";
import { AccountsSheet } from "../accounts/accounts_sheet";
import { GroupsSheet } from "../groups/groups_sheet";
import { AppSection, AppSubsection, FeaturesNavigation, useInlineFeatureNavigation } from "./features_navigation";
import { PinnedServerSelector } from "./pinned_server_selector";
import { ServerNameAndLogo, splitOnFirstEmoji } from "./server_name_and_logo";
import { TabsTutorial } from "./tabs_tutorial";
import useDetectScroll, { Axis, Direction } from '@smakss/react-scroll-direction'
import { useHideNavigation } from "./use_hide_navigation";

export type TabsNavigationProps = {
  children?: React.ReactNode;
  // onlyShowServer?: JonlineServer;
  appSection?: AppSection;
  appSubsection?: AppSubsection;
  selectedGroup?: FederatedGroup;
  customHomeAction?: () => void;
  // Forwarder to link to a group page. Defaults to /g/:shortname.
  // But, for instance, post pages can link to /g/:shortname/p/:id.
  groupPageForwarder?: (groupIdentifier: string) => string;
  groupPageExiter?: () => void;
  withServerPinning?: boolean;
  primaryEntity?: FederatedEntity<any>;
};

// export const tabNavBaseHeight = 64;

export function TabsNavigation({
  children,
  // onlyShowServer,
  appSection = AppSection.HOME,
  appSubsection,
  selectedGroup,
  customHomeAction,
  groupPageForwarder,
  groupPageExiter,
  withServerPinning,
  primaryEntity
}: TabsNavigationProps) {
  const mediaQuery = useMedia()
  const currentServer = useServer();
  const primaryServer = //onlyShowServer || 
    currentServer;
  const webUI = currentServer?.serverConfiguration?.serverInfo?.webUserInterface;
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
  const primaryColor = `#${(backgroundColorInt)?.toString(16).slice(-6) || '424242'}`;
  // console.log('primaryColor', primaryColor);
  const primaryTextColor = colorMeta(primaryColor).textColor;

  const navigationContext: NavigationContextType = useOrCreateNavigationContext();

  const logo = primaryServer?.serverConfiguration?.serverInfo?.logo;

  const { darkMode: systemDark } = useServerTheme();
  const invert = !app.darkModeAuto ? (systemDark != app.darkMode) ? true : false : false;
  const dark = app.darkModeAuto ? systemDark : app.darkMode;
  const bgColor = dark ? '$gray1Dark' : '$gray2Light';
  const canUseLogo = logo?.wideMediaId != undefined || logo?.squareMediaId != undefined;
  const showHomeIcon = serverNameEmoji == undefined && !canUseLogo;
  const recentGroupIds = useRootSelector((state: RootState) => state.app.recentGroups ?? []);
  const { inlineNavigation: inlineFeatureNavigation } = useInlineFeatureNavigation();
  const scrollGroupsSheet = !inlineFeatureNavigation
    || !mediaQuery.gtXs;

  const useSquareLogo = canUseLogo && logo?.squareMediaId != undefined;

  const showServerInfo = (primaryEntity && primaryEntity.serverHost !== currentServer?.host) ||
    (selectedGroup && selectedGroup.serverHost !== currentServer?.host);
  const shrinkHomeButton = !!selectedGroup || showServerInfo;
  const disabled = useHideNavigation();

  useEffect(() => {
    if (selectedGroup && currentServer && recentGroupIds[0] != federatedId(selectedGroup)) {
      dispatch(markGroupVisit({ group: selectedGroup, server: currentServer }));
    }
  }, [selectedGroup?.id]);
  useEffect(() => {
    if (navigationContext) {
      const navigationHeight = document.querySelector('#nav-main')?.clientHeight ?? 0;
      navigationContext.setNavigationHeight(navigationHeight);
    }
  },
    [
      primaryEntity?.serverHost,
      primaryServer,
      currentServer,
      disabled,
    ]
  );
  return <Theme inverse={invert} key={`tabs-${appSection}-${appSubsection}`}>
    <ToastViewport zi={1000000} multipleToasts left={0} right={0} bottom={11} />

    <NavigationContextProvider value={navigationContext}>
      <GroupContextProvider value={selectedGroup}>

        <YStack jc="center" ac='center' ai="center"
          w='100%'
          minHeight={window.innerHeight}
        >
          <StickyBox style={{ zIndex: 10, width: '100%', pointerEvents: disabled ? 'none' : undefined }} className='blur'>
            <YStack backgroundColor={primaryColor} opacity={disabled ? 0 : 0.92} w='100%'>
              {disabled ? undefined:<XStack id='nav-main' space="$1" my='$1' pl='$1' w='100%'>
                {/* <XStack w={5} /> */}
                <YStack my='auto' maw={shrinkHomeButton ? '$6' : undefined}>
                  <AccountsSheet size='$4' //onlyShowServer={onlyShowServer}
                    selectedGroup={selectedGroup} />
                  <Button //size="$4"
                    id="home-button"
                    py={0}
                    px={0}
                    // px={
                    //   shrinkHomeButton && !useWideLogo && !useSquareLogo ? '$3' :
                    //     !shrinkHomeButton && !useWideLogo && !useSquareLogo && !hasEmoji ? '$2' : 0}
                    height='auto'
                    borderTopLeftRadius={0} borderTopRightRadius={0}
                    // width={shrinkHomeButton && useSquareLogo ? 48 : undefined}

                    overflow='hidden'
                    icon={showHomeIcon ? <HomeIcon size='$1' /> : undefined}

                    {...homeProps}
                  >
                    <YStack
                      my={shrinkHomeButton ? 'auto' : undefined}
                      h={shrinkHomeButton ? '$3' : undefined}
                      w={shrinkHomeButton ? '100%' : undefined}
                      ac={shrinkHomeButton ? 'center' : undefined}
                      jc={shrinkHomeButton ? 'center' : undefined}
                    >
                      <ServerNameAndLogo
                        shrinkToSquare={shrinkHomeButton}
                        fallbackToHomeIcon
                        server={primaryServer} />
                    </YStack>
                  </Button>
                </YStack>
                {showServerInfo
                  ? <XStack my='auto' ml={-7} mr={-9}><ChevronRight color={primaryTextColor} /></XStack>
                  : undefined}
                {!scrollGroupsSheet
                  ? <XStack space='$2' ml='$1' mr={showServerInfo ? 0 : -3} my='auto' id='main-groups-button'>
                    <GroupsSheet key='main'
                      selectedGroup={selectedGroup}
                      groupPageForwarder={groupPageForwarder}
                      primaryEntity={primaryEntity} />

                  </XStack>
                  : undefined}
                <ScrollView horizontal>
                  {!scrollGroupsSheet
                    ? <></>
                    : <>
                      {/* <XStack w={1} /> */}
                      <XStack ml='$1' my='auto' className='main-groups-button'>
                        <GroupsSheet key='main'
                          selectedGroup={selectedGroup}
                          groupPageForwarder={groupPageForwarder}
                          primaryEntity={primaryEntity} />
                      </XStack>
                      {/* <XStack w={0} /> */}
                    </>
                  }
                  <FeaturesNavigation {...{ appSection, appSubsection, selectedGroup }} />
                </ScrollView>
                <XStack f={1} />
                {/* <AccountsSheet size='$4' circular={circularAccountsSheet} onlyShowServer={onlyShowServer} /> */}
                <XStack w={5} />
              </XStack>}

              {/* <YStack w='100%' backgroundColor='$background'>
                <TabsTutorial />
              </YStack> */}

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
