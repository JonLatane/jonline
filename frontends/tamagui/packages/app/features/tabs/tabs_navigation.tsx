import { Group, WebUserInterface } from "@jonline/api";
import { Button, Heading, Popover, ScrollView, Theme, useMedia, XStack, YStack } from "@jonline/ui";
import { useTheme } from "@react-navigation/native";
import { Home as HomeIcon } from '@tamagui/lucide-icons';
import { JonlineServer, RootState, useServerTheme, useTypedSelector } from "app/store";
import { Platform } from 'react-native';
import StickyBox from "react-sticky-box";
import { useLink } from "solito/link";
import { AccountsSheet } from "../accounts/accounts_sheet";
import { GroupsSheet } from "../groups/groups_sheet";
import { AppSection, AppSubsection, FeaturesNavigation, sectionTitle } from "./features_navigation";

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
};

export function TabsNavigation({ children, onlyShowServer, appSection = AppSection.HOME, appSubsection, selectedGroup, customHomeAction }: TabsNavigationProps) {
  const media = useMedia()
  const server = useTypedSelector((state: RootState) => state.servers.server);
  const primaryServer = onlyShowServer || server;
  const webUI = server?.serverConfiguration?.serverInfo?.webUserInterface;
  const homeProps = customHomeAction ? { onPress: customHomeAction } : useLink({
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

  // const app = useLocalApp();
  const theme = useTheme();
  // const targetTheme = app.darkModeAuto ? undefined : app.darkMode ? 'dark' : 'light';
  const { darkMode: systemDark } = useServerTheme();
  const invert = !app.darkModeAuto ? (systemDark != app.darkMode) ? true : false : false;
  const dark = app.darkModeAuto ? systemDark : app.darkMode;
  const bgColor = dark ? '$gray1Dark' : '$gray2Light';
  const shrinkHomeButton = selectedGroup || appSubsection == AppSubsection.FOLLOW_REQUESTS;
  // console.log(`app.darkModeAuto=${app.darkModeAuto}, systemDark=${systemDark}, app.darkMode=${app.darkMode}, invert=${invert}, dark=${dark}, bgColor=${bgColor}`);
  return <Theme inverse={invert} key={`tabs-${appSection}-${appSubsection}`}>
    {Platform.select({
      web: <>
        <StickyBox style={{ zIndex: 10 }} className="blur">
          <YStack space="$1" backgroundColor={backgroundColor} opacity={0.92}>
            {/* <XStack h={5}></XStack> */}
            <XStack space="$1" marginVertical={5}>
              <XStack w={5} />
              {shrinkHomeButton
                ? <Button size="$4" maw={maxWidth} overflow='hidden' ac='flex-start'
                  iconAfter={serverNameEmoji ? undefined : HomeIcon}
                  {...homeProps}>
                  <XStack maw={maxWidth - (serverNameEmoji ? 50 : 0)}>
                    <Heading whiteSpace="nowrap">{serverNameEmoji ?? ''}</Heading>
                  </XStack>
                </Button>
                : <Button size="$4" maw={maxWidth} overflow='hidden' ac='flex-start'
                  iconAfter={serverNameEmoji ? undefined : HomeIcon}
                  {...homeProps}>
                  <XStack maw={maxWidth - (serverNameEmoji ? 50 : 0)}>
                    <Heading whiteSpace="nowrap">{serverName}</Heading>
                  </XStack>
                </Button>}
              <ScrollView horizontal>
                <XStack w={1} />
                <GroupsSheet selectedGroup={selectedGroup} />
                {app.showBetaNavigation ? <FeaturesNavigation {...{appSection, appSubsection, selectedGroup}} /> : undefined}
              </ScrollView>
              <XStack f={1} />
              <AccountsSheet size='$4' circular={!media.gtSm} onlyShowServer={onlyShowServer} />
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
  </Theme>;
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