import { WebUserInterface } from "@jonline/api";
import { Button, ScrollView, Spinner, Theme, ToastViewport, XStack, YStack, useMedia, useWindowDimensions } from "@jonline/ui";
import { ChevronRight, Home as HomeIcon } from '@tamagui/lucide-icons';
import { GroupContextProvider } from 'app/contexts';
import { useAppDispatch, useServer } from "app/hooks";
import { FederatedEntity, FederatedGroup, RootState, colorMeta, federatedId, markGroupVisit, useRootSelector, useServerTheme } from "app/store";
import { useEffect } from "react";
import StickyBox from "react-sticky-box";
import { useLink } from "solito/link";
import { AccountsSheet } from "../accounts/accounts_sheet";
import { GroupsSheet } from "../groups/groups_sheet";
import { AppSection, AppSubsection, FeaturesNavigation, useInlineFeatureNavigation } from "./features_navigation";
import { PinnedServerSelector } from "./pinned_server_selector";
import { ServerNameAndLogo, splitOnFirstEmoji } from "./server_name_and_logo";
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
  topChrome?: React.ReactNode;
  bottomChrome?: React.ReactNode;
  loading?: boolean;
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
  primaryEntity,
  topChrome,
  bottomChrome,
  loading
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
  const navColorInt = primaryServer?.serverConfiguration?.serverInfo?.colors?.navigation;
  const navColor = `#${(navColorInt)?.toString(16).slice(-6) || '424242'}`;

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
  const hideNavigation = useHideNavigation();

  useEffect(() => {
    if (selectedGroup && currentServer && recentGroupIds[0] != federatedId(selectedGroup)) {
      dispatch(markGroupVisit({ group: selectedGroup, server: currentServer }));
    }
  }, [selectedGroup?.id]);

  const dimensions = useWindowDimensions();

  const measuredHomeButtonWidth = document.querySelector('#home-button')?.clientWidth ?? 0;
  const measuredHomeButtonHeight = document.querySelector('#home-button')?.clientHeight ?? 0;
  return <Theme inverse={invert} key={`tabs-${appSection}-${appSubsection}`}>
    <ToastViewport zi={1000000} multipleToasts left={0} right={0} bottom={11} />

    <GroupContextProvider value={selectedGroup}>

      <YStack jc="center" ac='center' ai="center"
        w='100%'
        backgroundColor={bgColor}
        minHeight={window.innerHeight} >
        <StickyBox style={{ zIndex: 10, width: '100%', pointerEvents: hideNavigation ? 'none' : undefined }} className='blur'>
          <YStack w='100%'>
            {hideNavigation ? undefined : <XStack id='nav-main'
              backgroundColor={primaryColor} opacity={hideNavigation ? 0 : 0.92} gap="$1" py='$1' pl='$1' w='100%'>
              {/* <XStack w={5} /> */}
              <YStack my='auto' maw={shrinkHomeButton ? '$6' : undefined}>
                <AccountsSheet size='$4' //onlyShowServer={onlyShowServer}
                  selectedGroup={selectedGroup} />
                <XStack position='absolute' zi={10000} animation='standard' o={loading ? 1 : 0}
                  pointerEvents="none"
                  ml={(measuredHomeButtonWidth - 30) / 2}
                  mt={(measuredHomeButtonHeight - 10) / 2}>
                  <Spinner size='large' color={primaryColor} scale={1.4} />
                </XStack>
                <XStack position='absolute' zi={10000} animation='standard' o={loading ? 1 : 0}
                  pointerEvents="none"
                  ml={(measuredHomeButtonWidth - 30) / 2}
                  mt={(measuredHomeButtonHeight - 10) / 2}>
                  <Spinner size='large' color={navColor} scale={-1.1} />
                </XStack>
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
                ? <XStack gap='$2' ml='$1' mr={showServerInfo ? 0 : -3} my='auto' id='main-groups-button'>
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
              <PinnedServerSelector show={withServerPinning && !selectedGroup} affectsNavigation transparent />
            </XStack>

            {topChrome}
          </YStack>
        </StickyBox>


        <StickyBox style={{ zIndex: 10, height: 0, pointerEvents: 'none' }}>
          <YStack gap="$1" animation='standard' opacity={loading && hideNavigation ? 0.92 : 0}>
            <Spinner size='large' color={navColor} scale={2}
              top={dimensions.height / 2 - 50}
            />
          </YStack>
        </StickyBox>

        <YStack f={1} w='100%' jc="center" ac='center' ai="center" //backgroundColor={bgColor}
          maw={window.innerWidth}
          overflow="hidden"
        >
          {children}
        </YStack>

        {bottomChrome
          ? <StickyBox bottom offsetBottom={0} className='blur' style={{ width: '100%', zIndex: 10 }}>
            {bottomChrome}
          </StickyBox>
          : undefined}
      </YStack>
    </GroupContextProvider>
  </Theme>;
}
