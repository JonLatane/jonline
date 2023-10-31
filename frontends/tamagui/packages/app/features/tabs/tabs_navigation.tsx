import { Group, Media, User, UserListingType, WebUserInterface } from "@jonline/api";
import { Button, Heading, isSafari, Paragraph, Popover, ScrollView, Theme, useMedia, XStack, YStack } from "@jonline/ui";
import { useTheme } from "@react-navigation/native";
import { Home as HomeIcon } from '@tamagui/lucide-icons';
import { JonlineServer, RootState, getUsersPage, loadUsersPage, markGroupVisit, useAccountOrServer, useServerTheme, useTypedDispatch, useTypedSelector } from "app/store";
import { Platform, TranslateXTransform } from 'react-native';
import StickyBox from "react-sticky-box";
import { useLink } from "solito/link";
import { AccountsSheet } from "../accounts/accounts_sheet";
import { GroupsSheet } from "../groups/groups_sheet";
import { AppSection, AppSubsection, FeaturesNavigation, sectionTitle, useInlineFeatureNavigation } from "./features_navigation";
import { GroupContextProvider } from "../groups/group_context";
import { MediaRenderer } from "../media/media_renderer";
import { useEffect, useState } from "react";
import { serverID } from '../../store';
import { ServerNameAndLogo } from "./server_name_and_logo";

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
};

export function TabsNavigation({ children, onlyShowServer, appSection = AppSection.HOME, appSubsection, selectedGroup, customHomeAction, groupPageForwarder, groupPageExiter }: TabsNavigationProps) {
  const mediaQuery = useMedia()
  const server = useTypedSelector((state: RootState) => state.servers.server);
  const primaryServer = onlyShowServer || server;
  const webUI = server?.serverConfiguration?.serverInfo?.webUserInterface;
  const homeProps = customHomeAction ? { onPress: customHomeAction } : useLink({
    href:
      selectedGroup && appSection == AppSection.POSTS ? `/posts` :
        selectedGroup && appSection == AppSection.EVENTS ? `/events` :
          webUI == WebUserInterface.FLUTTER_WEB
            ? '/tamagui'
            : '/'
  });
  const dispatch = useTypedDispatch();
  const serverName = primaryServer?.serverConfiguration?.serverInfo?.name || 'Jonline';
  const app = useTypedSelector((state: RootState) => state.app);
  const serverNameEmoji = serverName.match(/\p{Emoji}/u)?.at(0);
  // debugger;
  // debugger;
  const [serverNameBeforeEmoji, serverNameAfterEmoji] = serverName
    .split(serverNameEmoji ?? '|', 2)
    .map(x => x.replace(/[^\x20-\x7E]/g, '').trim())
    ;
  const veryShortServername = serverNameBeforeEmoji!.length < 10;
  const shortServername = serverNameBeforeEmoji!.length < 12;
  const largeServername = (!serverNameAfterEmoji || serverNameAfterEmoji === '') && veryShortServername;
  // const serverNameWithoutEmoji = serverNameEmoji
  //   ? serverName.split(serverNameEmoji, 1) //serverName.replace(serverNameEmoji, '')
  //   : serverName;
  const account = useTypedSelector((state: RootState) => state.accounts.account);
  const backgroundColorInt = primaryServer?.serverConfiguration?.serverInfo?.colors?.primary;
  const backgroundColor = `#${(backgroundColorInt)?.toString(16).slice(-6) || '424242'}A6`;
  const navColorInt = primaryServer?.serverConfiguration?.serverInfo?.colors?.navigation;
  const navColor = `#${(navColorInt)?.toString(16).slice(-6) || 'fff'}`;
  const wrapTitle = serverName.length > 20;
  // const maxWidth = mediaQuery.gtXs
  //   ? 270
  //   : 200;

  const logo = primaryServer?.serverConfiguration?.serverInfo?.logo;

  // const app = useLocalApp();
  // const theme = useTheme();
  // const targetTheme = app.darkModeAuto ? undefined : app.darkMode ? 'dark' : 'light';
  const { darkMode: systemDark } = useServerTheme();
  const invert = !app.darkModeAuto ? (systemDark != app.darkMode) ? true : false : false;
  const dark = app.darkModeAuto ? systemDark : app.darkMode;
  const bgColor = dark ? '$gray1Dark' : '$gray2Light';
  const shrinkHomeButton = !mediaQuery.gtMd && (selectedGroup != undefined ||
    appSubsection == AppSubsection.FOLLOW_REQUESTS);
  // console.log(`app.darkModeAuto=${app.darkModeAuto}, systemDark=${systemDark}, app.darkMode=${app.darkMode}, invert=${invert}, dark=${dark}, bgColor=${bgColor}`);
  const canUseLogo = logo?.wideMediaId != undefined || logo?.squareMediaId != undefined;
  //(!shrinkHomeButton && logo?.wideMediaId != undefined) ||
  //(shrinkHomeButton && logo?.squareMediaId != undefined);
  const showHomeIcon = serverNameEmoji == undefined && !canUseLogo && shrinkHomeButton;
  // console.log('showHomeIcon', showHomeIcon, serverNameEmoji, canUseLogo, logo?.wideMediaId, logo?.squareMediaId, shrinkHomeButton)
  const renderButtonChildren = !shrinkHomeButton || serverNameEmoji || canUseLogo;
  // console.log('showHomeIcon', showHomeIcon, serverNameEmoji, canUseLogo, logo?.wideMediaId, logo?.squareMediaId, maxWidth, renderButtonChildren);
  // debugger;
  const recentGroupIds = useTypedSelector((state: RootState) => server
    ? state.app.serverRecentGroups?.[serverID(server)] ?? []
    : []);
  const inlineFeatureNavigation = useInlineFeatureNavigation();
  const scrollGroupsSheet = !inlineFeatureNavigation
    || !mediaQuery.gtXs;

  useEffect(() => {
    if (selectedGroup && server && recentGroupIds[0] != selectedGroup.id) {
      dispatch(markGroupVisit({ group: selectedGroup, server }));
    }
  }, [selectedGroup?.id]);
  // console.log(`serverNameEmoji="${serverNameEmoji}", serverNameBeforeEmoji="${serverNameBeforeEmoji}", serverNameAfterEmoji="${serverNameAfterEmoji}"`)
  const useSquareLogo = canUseLogo && logo?.squareMediaId != undefined;
  const useWideLogo = canUseLogo && logo?.wideMediaId != undefined && !shrinkHomeButton;
  const useEmoji = serverNameEmoji && serverNameEmoji !== '';
  // const maxWidthAfterServerName = maxWidth ? maxWidth - (serverNameEmoji ? 50 : 0) : undefined;

  return <Theme inverse={invert} key={`tabs-${appSection}-${appSubsection}`}>
    <GroupContextProvider value={selectedGroup}>
      {Platform.select({
        web: <>
          <StickyBox style={{ zIndex: 10 }} className="blur">
            <YStack space="$1" backgroundColor={backgroundColor} opacity={0.92}>
              {/* <XStack h={5}></XStack> */}
              <XStack space="$1" marginVertical={5}>
                <XStack w={5} />
                <Button //size="$4"
                  py={0}
                  px={
                    shrinkHomeButton && !useWideLogo && !useSquareLogo ? '$3' :
                      !shrinkHomeButton && !useWideLogo && !useSquareLogo && !useEmoji ? '$2' : 0}
                  height={48}
                  width={shrinkHomeButton && useSquareLogo ? 48 : undefined}
                  // maw={maxWidth}
                  overflow='hidden' //ac='flex-start'
                  // iconAfter={showHomeIcon && !shrinkHomeButton ? HomeIcon : undefined}
                  icon={showHomeIcon /*&& shrinkHomeButton*/ ? <HomeIcon size='$1' /> : undefined}
                  {...homeProps}
                >
                  {renderButtonChildren
                    ? <ServerNameAndLogo shrink={shrinkHomeButton}
                      fallbackToHomeIcon
                      server={primaryServer} />
                    // ? shrinkHomeButton
                    //   ? useSquareLogo
                    //     ? <XStack h='100%'
                    //       scale={1.1}
                    //       transform={[
                    //         { translateY: 1.5 },
                    //         { translateX: isSafari() ? 8.0 : 2.0 }]
                    //       } >
                    //       <MediaRenderer server={server} forceImage media={Media.create({ id: logo?.squareMediaId })} failQuietly />
                    //     </XStack>
                    //     : <XStack h={'100%'} maw={maxWidthAfterServerName}>
                    //       <Heading my='auto' whiteSpace="nowrap">{serverNameEmoji ?? ''}</Heading>
                    //       {/* <Paragraph size='$1' lineHeight='$1' my='auto'>{serverNameWithoutEmoji}</Paragraph> */}
                    //     </XStack>
                    //   : <XStack h={'100%'} w='100%' space='$5' maw={maxWidthAfterServerName}>
                    //     {useWideLogo
                    //       ? <XStack h='100%' scale={1.05} transform={[{ translateY: 1.0 }, { translateX: 2.0 }]}>
                    //         <MediaRenderer server={server} forceImage media={Media.create({ id: logo?.wideMediaId })} failQuietly />
                    //       </XStack>
                    //       : <>
                    //         {useSquareLogo
                    //           ? <XStack w={'$3'} h={'$3'} ml='$2' mr='$1' my='auto'>
                    //             <MediaRenderer server={server} forceImage media={Media.create({ id: logo?.squareMediaId })} failQuietly />
                    //           </XStack>
                    //           : serverNameEmoji && serverNameEmoji != ''
                    //             ? <Heading size={undefined}
                    //               my='auto' ml='$2' mr='$2' whiteSpace="nowrap">{serverNameEmoji}</Heading>
                    //             : undefined}
                    //         <YStack f={1} my='auto' mr='$2' space={'$0'}>
                    //           {largeServername
                    //             ? <Heading my='auto' whiteSpace="nowrap" overflow="hidden" textOverflow="ellipsis">{serverNameBeforeEmoji}</Heading>
                    //             : <Paragraph size={'$1'}
                    //               fontWeight='700' lineHeight={12} >{serverNameBeforeEmoji}{useSquareLogo && serverNameEmoji && serverNameEmoji != '' ? ` ${serverNameEmoji}` : undefined}</Paragraph>}
                    //           {!largeServername && serverNameAfterEmoji && serverNameAfterEmoji !== '' && (mediaQuery.gtXs || shortServername)
                    //             ? <Paragraph
                    //               size={'$1'
                    //               }
                    //               lineHeight={12}
                    //             >
                    //               {serverNameAfterEmoji}
                    //             </Paragraph>
                    //             : undefined}
                    //         </YStack>
                    //       </>}
                    //   </XStack>
                    : undefined}
                </Button>
                {!scrollGroupsSheet
                  ? <XStack space='$2' ml='$1' my='auto'>
                    <GroupsSheet key='main' selectedGroup={selectedGroup} groupPageForwarder={groupPageForwarder} />
                  </XStack>
                  : undefined}
                <ScrollView horizontal>
                  {!scrollGroupsSheet
                    ? <>
                      <XStack w={2} />
                    </>
                    : <>
                      <XStack w={1} />
                      <GroupsSheet key='main' selectedGroup={selectedGroup} groupPageForwarder={groupPageForwarder} />
                      <XStack w={3} />
                    </>
                  }
                  <FeaturesNavigation {...{ appSection, appSubsection, selectedGroup }} />
                </ScrollView>
                <XStack f={1} />
                <AccountsSheet size='$4' circular={!mediaQuery.gtSm} onlyShowServer={onlyShowServer} />
                <XStack w={5} />
              </XStack>
              {/* <XStack h={5}></XStack> */}
            </YStack>
          </StickyBox>
          <YStack f={1} jc="center" ai="center" backgroundColor={bgColor}>
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
      })}
    </GroupContextProvider>
  </Theme>;
}
