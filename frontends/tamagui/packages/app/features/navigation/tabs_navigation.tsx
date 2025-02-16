import { AnimatePresence, Button, Paragraph, ScrollView, Spinner, Theme, ToastViewport, XStack, YStack, standardHorizontalAnimation, useMedia, useWindowDimensions } from "@jonline/ui";
import { ChevronLeft, ChevronRight, Home as HomeIcon, PanelTopClose, PanelTopOpen } from '@tamagui/lucide-icons';
import { GroupContextProvider, MediaContextProvider, useNewMediaContext } from 'app/contexts';
import { AuthSheetContextProvider, useNewAuthSheetContext } from "app/contexts/auth_sheet_context";
import { NavigationContextProvider } from "app/contexts/navigation_context";
import { useAppDispatch, useAppSelector, useCreationServer, useCurrentServer, useLocalConfiguration } from "app/hooks";
import { FederatedEntity, FederatedGroup, RootState, colorMeta, federatedId, markGroupVisit, selectAllServers, setForceHideAccountSheetGuide, setHideNavigation, store, useRootSelector, useServerTheme } from "app/store";
import FlipMove from "lumen5-react-flip-move";
import React, { useEffect, useState } from "react";
import { useLink } from "solito/link";
import useDetectKeyboardOpen from "use-detect-keyboard-open";
import { AccountsSheet } from "../accounts/accounts_sheet";
import { AuthSheet } from "../accounts/auth_sheet";
import { GroupDetailsSheet } from "../groups/group_details_sheet";
import { GroupsSheet, GroupsSheetButton } from "../groups/groups_sheet";
import { MediaSheet } from "../media/media_sheet";
import { AppSection, AppSubsection, FeaturesNavigation, useInlineFeatureNavigation } from "./features_navigation";
import { PinnedServerSelector } from "./pinned_server_selector";
import { ServerNameAndLogo, splitOnFirstEmoji } from "./server_name_and_logo";
import { StarredPosts } from "./starred_posts";
import { useHideNavigation } from "./use_hide_navigation";
import { webPushSupport } from 'app/features/web_push/web_push';

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
  groupPageReverse?: string;
  withServerPinning?: boolean;
  primaryEntity?: FederatedEntity<any>;
  topChrome?: React.ReactNode;
  bottomChrome?: React.ReactNode;
  loading?: boolean;
  showShrinkPreviews?: boolean;
  minimal?: boolean;
};

// export const tabNavBaseHeight = 64;

export const useTabsNavigationHeight = () => {
  const topNavHeight = document.getElementById('jonline-top-navigation')?.clientHeight ?? 0;
  const bottomNavHeight = document.getElementById('jonline-bottom-navigation')?.clientHeight ?? 0;
  // const [topNavHeight, setTopNavHeight] = useState(document.getElementById('jonline-top-navigation')?.clientHeight ?? 0);
  // const [bottomNavHeight, setBottomNavHeight] = useState(document.getElementById('jonline-bottom-navigation')?.clientHeight ?? 0);
  // const [notified, setNotified] = useState(false);
  // useEffect(() => {
  //   if (notified) {
  //     setTopNavHeight(document.getElementById('jonline-top-navigation')?.clientHeight ?? 0);
  //     setBottomNavHeight(document.getElementById('jonline-bottom-navigation')?.clientHeight ?? 0);
  //   }
  // }, [notified]);
  // const tabNavChangeNotifier = useCallback(() => setNotified(true), [])
  const { showPinnedServers } = useLocalConfiguration();
  const [_showPinnedServers, _setShowPinnedServers] = useState(showPinnedServers);
  useEffect(() => {
    _setShowPinnedServers(showPinnedServers);
  }, [showPinnedServers]);

  function remeasure() {
    _setShowPinnedServers(showPinnedServers);
  }

  return { topNavHeight, bottomNavHeight, remeasure };
}

export function TabsNavigation({
  children,
  // onlyShowServer,
  appSection = AppSection.HOME,
  appSubsection,
  selectedGroup,
  customHomeAction,
  groupPageForwarder,
  groupPageReverse,
  withServerPinning,
  primaryEntity,
  topChrome,
  bottomChrome,
  loading,
  showShrinkPreviews,
  minimal
}: TabsNavigationProps) {
  const mediaQuery = useMedia()
  const mediaContext = useNewMediaContext();
  const authSheetContext = useNewAuthSheetContext();

  const { hasOpenedAccounts } = useLocalConfiguration();
  const { configuringFederation } = useAppSelector(state => state.servers);
  const [showAccountSheetGuide, setShowAccountSheetGuide] = useState(false);
  const dispatch = useAppDispatch();
  const forceHideAccountSheetGuide = useAppSelector(state => state.temporaryConfig.forceHideAccountSheetGuide);

  useEffect(() => {
    if (!loading && !configuringFederation &&
      !hasOpenedAccounts && !showAccountSheetGuide && !forceHideAccountSheetGuide) {
      setTimeout(() => {
        if (store.getState().config.hasOpenedAccounts) return;

        setShowAccountSheetGuide(true);
      }
        , 3000);
    }
  }, [hasOpenedAccounts, configuringFederation, loading]);
  useEffect(() => {
    if (hasOpenedAccounts && showAccountSheetGuide) {
      setShowAccountSheetGuide(false);
    }
  }, [hasOpenedAccounts]);
  const currentServer = useCurrentServer();
  const primaryServer = //onlyShowServer || 
    currentServer;
  const webUI = currentServer?.serverConfiguration?.serverInfo?.webUserInterface;
  const homeProps = customHomeAction ? { onPress: customHomeAction } : useLink({
    href:
      // selectedGroup && appSection == AppSection.POSTS ? `/posts` :
      //   selectedGroup && appSection == AppSection.EVENTS ? `/events` :
      //     selectedGroup && appSection == AppSection.MEMBERS ? `/people` :
      //       webUI == WebUserInterface.FLUTTER_WEB
      //         ? '/tamagui'
      //         : 
      '/'
  });

  const serverName = primaryServer?.serverConfiguration?.serverInfo?.name || '...';
  const app = useRootSelector((state: RootState) => state.config);
  const [_serverNameBeforeEmoji, serverNameEmoji, _serverNameAfterEmoji] = splitOnFirstEmoji(serverName, true)
  const backgroundColorInt = primaryServer?.serverConfiguration?.serverInfo?.colors?.primary;
  const primaryColor = `#${(backgroundColorInt)?.toString(16).slice(-6) || '424242'}`;
  // console.log('primaryColor', primaryColor);
  const primaryTextColor = colorMeta(primaryColor).textColor;
  const navColorInt = primaryServer?.serverConfiguration?.serverInfo?.colors?.navigation;
  const navColor = `#${(navColorInt)?.toString(16).slice(-6) || '424242'}`;

  const [sharingPostId, setSharingPostId] = useState<string | undefined>(undefined);
  const [infoGroupId, setInfoGroupId] = useState<string | undefined>(undefined);
  const groupContext = { selectedGroup, sharingPostId, setSharingPostId, infoGroupId, setInfoGroupId };

  const logo = primaryServer?.serverConfiguration?.serverInfo?.logo;


  const { backgroundColor, barelyTransparentBackgroundColor, transparentBackgroundColor, darkMode: systemDark, inverse } = useServerTheme(currentServer);

  // console.log('TabsNavigation darkMode', systemDark, 'inverse', inverse, 'transparentBackgroundColor', transparentBackgroundColor);

  const dark = app.darkModeAuto ? systemDark : app.darkMode;
  const bgColor = dark ? '$gray1Dark' : '$gray2Light';
  const canUseLogo = logo?.wideMediaId != undefined || logo?.squareMediaId != undefined;
  const showHomeIcon = serverNameEmoji == undefined && !canUseLogo;
  const recentGroupIds = useRootSelector((state: RootState) => state.config.recentGroups ?? []);
  const { inlineNavigation: inlineFeatureNavigation } = useInlineFeatureNavigation();
  const scrollGroupsSheet = !inlineFeatureNavigation
    || !mediaQuery.gtXs;

  const useSquareLogo = canUseLogo && logo?.squareMediaId != undefined;

  const showServerInfo = (primaryEntity && primaryEntity.serverHost !== currentServer?.host) ||
    (selectedGroup && selectedGroup.serverHost !== currentServer?.host);
  const shrinkHomeButton = !!selectedGroup || showServerInfo;
  const { alwaysShowHideButton } = useLocalConfiguration();
  const hideNavigation = useHideNavigation();

  useEffect(() => {
    if (selectedGroup && currentServer && recentGroupIds[0] != federatedId(selectedGroup)) {
      dispatch(markGroupVisit({ group: selectedGroup }));
    }
  }, [selectedGroup?.id]);

  const { creationServer, setCreationServer } = useCreationServer();
  const primaryEntityServer = useAppSelector(state =>
    primaryEntity
      ? selectAllServers(state.servers).find(s => s.host === primaryEntity?.serverHost)
      : undefined
  );
  useEffect(() => {
    if (primaryEntityServer && creationServer?.host !== primaryEntityServer?.host) {
      dispatch(setCreationServer(primaryEntityServer));
    }
  }, [primaryEntity?.serverHost]);

  const dimensions = useWindowDimensions();

  const measuredHomeButtonWidth = document.querySelector('#home-button')?.clientWidth ?? 0;
  const measuredHomeButtonHeight = document.querySelector('#home-button')?.clientHeight ?? 0;

  const [groupsSheetOpen, setGroupsSheetOpen] = useState(false);
  const [mediaSheetOpen, setMediaSheetOpen] = useState(false);

  const excludeCurrentServer = useAppSelector(state => state.accounts.excludeCurrentServer);
  const isKeyboardOpen = useDetectKeyboardOpen();
  const { topNavHeight, bottomNavHeight } = useTabsNavigationHeight();

  const showSpinners = loading || configuringFederation;

  return <Theme inverse={inverse}// key={`tabs-${appSection}-${appSubsection}`}
  >
    <ToastViewport zi={1000000} multipleToasts left={0} right={0} bottom={11} />

    <AuthSheetContextProvider value={authSheetContext}>
      <MediaContextProvider value={mediaContext}>
        <GroupContextProvider value={groupContext}>
          <NavigationContextProvider value={{ appSection, appSubsection, groupPageForwarder, groupPageReverse, primaryEntity }}>
            <YStack jc="center" ac='center' ai="center"
              className={isKeyboardOpen ? 'keyboard-open' : undefined}
              w='100%'
              backgroundColor={bgColor}
              minHeight={window.innerHeight} >
              <div style={{
                position: 'fixed',
                top: 0,
                left: 0,
                right: 0,
                zIndex: 10,
                // backgroundColor: transparentBackgroundColor
              }}>

                <YStack w='100%' className='blur' id='jonline-top-navigation'>
                  {hideNavigation ? undefined : <XStack id='nav-main' ai='center'
                    pointerEvents={hideNavigation ? 'none' : undefined}
                    backgroundColor={primaryColor} opacity={hideNavigation ? 0 : 0.92} gap="$1" py='$1' pl='$1' w='100%'>
                    {/* <XStack w={5} /> */}
                    <YStack my='auto' maw={shrinkHomeButton ? '$6' : undefined} >
                      <AccountsSheet size='$4' //onlyShowServer={onlyShowServer}
                        selectedGroup={selectedGroup} />
                      <XStack position='absolute' zi={10000} animation='standard' o={showSpinners ? 1 : 0}
                        pointerEvents="none"
                        ml={(measuredHomeButtonWidth - 30) / 2}
                        mt={(measuredHomeButtonHeight - 10) / 2}>
                        <Spinner size='large' color={primaryColor} scale={1.4} />
                      </XStack>
                      <XStack position='absolute' zi={10000} animation='standard' o={showSpinners ? 1 : 0}
                        pointerEvents="none"
                        ml={(measuredHomeButtonWidth - 30) / 2}
                        mt={(measuredHomeButtonHeight - 10) / 2}>
                        <Spinner size='large' color={navColor} scaleX={1.1} scaleY={-1.1} />
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
                          // o={excludeCurrentServer ? 0.5 : 1}
                          my={shrinkHomeButton ? 'auto' : undefined}
                          h={shrinkHomeButton ? '$3' : undefined}
                          w={shrinkHomeButton ? '100%' : undefined}
                          ac={shrinkHomeButton ? 'center' : undefined}
                          jc={shrinkHomeButton ? 'center' : undefined}
                        >
                          <ServerNameAndLogo
                            shrinkToSquare={shrinkHomeButton}
                            fallbackToHomeIcon
                            strikethrough={excludeCurrentServer}
                            server={primaryServer} />
                        </YStack>
                      </Button>
                    </YStack>
                    <AnimatePresence>
                      {showAccountSheetGuide
                        ? <YStack animation='standard' {...standardHorizontalAnimation} mr='$2' zi={9998}>
                          <XStack>
                            <XStack mt='$1' pt='$1' key='chevron'>
                              <ChevronLeft color={primaryTextColor} size='$1' />
                            </XStack>
                            <YStack>
                              <Paragraph color={primaryTextColor} size='$1'>Accounts, Servers,</Paragraph>
                              <Paragraph color={primaryTextColor} size='$1'>and Settings</Paragraph>
                            </YStack>
                          </XStack>
                          <Button size='$1'
                            onPress={() => {
                              dispatch(setForceHideAccountSheetGuide(true));
                              setShowAccountSheetGuide(false);
                              // dispatch(setHasOpenedAccounts(true));
                            }}>Got it!</Button>
                          {/* <XStack>
                            <ChevronLeft color={primaryTextColor} size='$1' />
                            <Paragraph color={primaryTextColor} size='$1'>Home/Latest</Paragraph>
                          </XStack> */}
                        </YStack>
                        : undefined}
                    </AnimatePresence>
                    {showServerInfo
                      ? <XStack my='auto' ml={-7} mr={-9}><ChevronRight color={primaryTextColor} /></XStack>
                      : undefined}
                    <AuthSheet />
                    {minimal ? undefined : <>
                      <GroupsSheet key='main' isPrimaryNavigation
                        open={groupsSheetOpen}
                        setOpen={setGroupsSheetOpen}
                      // selectedGroup={selectedGroup}
                      // primaryEntity={primaryEntity}
                      />

                      <GroupDetailsSheet />

                      <MediaSheet />


                      {!scrollGroupsSheet
                        ? <XStack gap='$2' ml='$1' mr={showServerInfo ? 0 : -3} my='auto' id='main-groups-button'>
                          <GroupsSheetButton key='main' isPrimaryNavigation
                            selectedGroup={selectedGroup}
                            open={groupsSheetOpen}
                            setOpen={setGroupsSheetOpen} />

                        </XStack>
                        : undefined}
                      <ScrollView horizontal>
                        <XStack ai='center'>
                          {!scrollGroupsSheet
                            ? undefined
                            : <XStack ml='$1' my='auto' key='main-groups-button' className='main-groups-button'>
                              <GroupsSheetButton key='main' isPrimaryNavigation
                                selectedGroup={selectedGroup}
                                open={groupsSheetOpen}
                                setOpen={setGroupsSheetOpen} />
                            </XStack>
                          }
                          <FeaturesNavigation {...{ appSection, appSubsection, selectedGroup }} />
                        </XStack>
                      </ScrollView>
                      <XStack f={1} />
                      {!withServerPinning &&
                        (alwaysShowHideButton || hideNavigation || (mediaQuery.gtXs && mediaQuery.short))
                        ? <Button key='hide-nav-button' py='$1' px='$2' h='$3' transparent
                          // animation='standard' {...reverseHorizontalAnimation}
                          onPress={() => dispatch(setHideNavigation(!hideNavigation))}>
                          <XStack position='absolute' animation='standard'
                            key='open-icon'
                            o={hideNavigation ? 1 : 0}
                            transform={[{ translateY: hideNavigation ? 0 : 10 }]}
                          // scale={hideNavigation ? 1 : 2}
                          >
                            <PanelTopOpen size='$1' color={primaryTextColor} />
                          </XStack>
                          <XStack position='absolute' animation='standard'
                            key='close-icon'
                            o={hideNavigation ? 0 : 1}
                            transform={[{ translateY: !hideNavigation ? 0 : -50 }]}
                          // scale={hideNavigation ? 0.2 : 1}
                          >
                            <PanelTopClose size='$1' color={primaryTextColor} />
                          </XStack>
                        </Button>
                        : undefined}

                      <StarredPosts />
                    </>}
                    {/* <AccountsSheet size='$4' circular={circularAccountsSheet} onlyShowServer={onlyShowServer} /> */}
                    <XStack w={5} />
                  </XStack>}

                  {/* <YStack w='100%' backgroundColor='$background'>
                <TabsTutorial />
              </YStack> */}

                  <XStack w='100%' id='nav-pinned-server-selector'
                    backgroundColor={transparentBackgroundColor}
                  // pointerEvents={hideNavigation ? 'none' : undefined}
                  >
                    <PinnedServerSelector
                      // show
                      show={(withServerPinning && !selectedGroup) || hideNavigation}
                      showShrinkPreviews={showShrinkPreviews}
                      affectsNavigation
                      withServerPinning={withServerPinning}
                      transparent />
                  </XStack>

                  <XStack w='100%' backgroundColor={transparentBackgroundColor}>
                    {topChrome}
                  </XStack>
                </YStack>
                {/* </StickyBox> */}
              </div>

              <XStack zi={1000} style={{ pointerEvents: 'none', position: 'fixed' }}
                animation='standard' o={showSpinners && hideNavigation ? 1 : 0}
                top={dimensions.height / 2 - 50}>
                <XStack position='absolute' key='primary-spinner'
                  transform={[{ translateX: -17 }]}>
                  <Spinner size='large' color={primaryColor} scale={2.4} />
                </XStack>
                <XStack position='absolute' key='other-spinner'
                  transform={[{ translateX: -17 }]}>
                  <Spinner size='large' color={navColor} scaleX={1.8} scaleY={-1.8} />
                </XStack>
              </XStack>

              <FlipMove /*typeName={null}*/ style={{ display: 'flex', flexDirection: 'flex-column', width: '100%', minHeight: '50vh' }}>
                <div key={`navigation-padding-${topNavHeight}`} style={{ height: topNavHeight }} />

                <div key='children' style={{ width: '100%', flex: 1 }} >
                  <YStack f={1} w='100%' jc="center" ac='center' ai="center"
                    //backgroundColor={bgColor}
                    maw={window.innerWidth}
                    mt={topNavHeight}
                    mb={bottomNavHeight}
                    overflow="hidden"
                  >
                    {children}
                  </YStack>
                </div>
                <div key={`navigation-padding-bottom-${bottomNavHeight}`}
                  style={{ height: bottomNavHeight }} />
              </FlipMove>

              {bottomChrome
                ?
                <div id='jonline-bottom-navigation' className='blur bottomChrome' style={{
                  position: 'fixed',
                  bottom: 0,
                  left: 0,
                  right: 0,
                  zIndex: 10,
                  backgroundColor: barelyTransparentBackgroundColor
                }}>
                  {bottomChrome}
                </div>
                : undefined}
            </YStack>
          </NavigationContextProvider>
        </GroupContextProvider>
      </MediaContextProvider>
    </AuthSheetContextProvider>
  </Theme>

  {/* <XStack position='absolute' bottom={5} right={5} zi={9999}>
      <Button icon={Fullscreen} onPress={() => requestFullscreen()} />
    </XStack> */}
  ;
}
