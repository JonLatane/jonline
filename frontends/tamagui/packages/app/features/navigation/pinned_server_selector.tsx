import { AnimatePresence, Button, ButtonProps, Heading, Paragraph, ScrollView, Tooltip, XStack, YStack, ZStack, standardAnimation, useForceUpdate, useMedia, useTheme } from "@jonline/ui";
import { CornerRightUp, HelpCircle, MoveUp } from '@tamagui/lucide-icons';
import { DarkModeToggle, doesPlatformPreferDarkMode } from "app/components/dark_mode_toggle";
import { useComponentKey, useAccount, useAccountOrServer, useAppDispatch, useLocalConfiguration, useAppSelector, useServer } from "app/hooks";
import { JonlineServer, PinnedServer, colorMeta, getServerTheme, pinServer, selectAllServers, serverID, setShowHelp, useServerTheme } from "app/store";
import { themedButtonBackground } from "app/utils/themed_button_background";
import moment, { Moment } from "moment";
import { useEffect, useState } from "react";
import { GestureResponderEvent } from "react-native";
import { ServerNameAndLogo } from "./server_name_and_logo";


export type PinnedServerSelectorProps = {
  show?: boolean;
};
export function PinnedServerSelector({ show }: PinnedServerSelectorProps) {
  const mediaQuery = useMedia();
  const config = useLocalConfiguration();
  const pinnedServers = useAppSelector(state => state.accounts.pinnedServers);
  // debugger;
  const dispatch = useAppDispatch();
  const focueUpdate = useForceUpdate();
  const account = useAccount();
  const [hidingStarted, setHidingStarted] = useState(undefined as Moment | undefined);
  const currentServer = useServer();
  const availableServers = useAppSelector(state =>
    selectAllServers(state.servers)
      .filter(server => (!currentServer || serverID(server) != serverID(currentServer))
        // && !pinnedServers.some(s => s.serverId === serverID(server))
      ));
  return <YStack w='100%' h={show ? undefined : 0}>
    <AnimatePresence>
      {show
        ? <ScrollView key='pinned-server-scroller' horizontal w='100%' animation='standard' {...standardAnimation}>
          <XStack m='$3' ai='center' space='$2'>
            {availableServers.map(server => {
              let pinnedServer = pinnedServers.find(s => s.serverId === serverID(server));
              return <PinnableServer {...{ server, pinnedServer }} />;
            })}
          </XStack>
        </ScrollView>
        : undefined}
    </AnimatePresence>
  </YStack>;
}



export type PinnableServerProps = {
  server: JonlineServer;
  pinnedServer?: PinnedServer;
};
export function PinnableServer({ server, pinnedServer }: PinnableServerProps) {
  const pinned = !!pinnedServer?.pinned;
  const theme = useTheme();
  const dispatch = useAppDispatch();
  const { primaryColor, primaryTextColor, primaryAnchorColor, navColor, navTextColor } = getServerTheme(server, theme);
  const onPress = () => {
    const updatedValue: PinnedServer = pinnedServer
      ? { ...pinnedServer, pinned: !pinnedServer.pinned }
      : { serverId: serverID(server), pinned: true, accountId: undefined };
    dispatch(pinServer(updatedValue));
  }
  console.log("PinnableServer", server.serverConfiguration?.serverInfo?.name, pinned);
  return <Button onPress={onPress} animation='standard'
    {...(pinned ? themedButtonBackground(primaryColor, primaryTextColor) : {})}>
    <ServerNameAndLogo server={server} textColor={pinned ? primaryTextColor : undefined} />
  </Button>;
}
