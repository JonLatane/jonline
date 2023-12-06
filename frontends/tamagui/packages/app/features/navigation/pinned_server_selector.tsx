import { AnimatePresence, Button, ButtonProps, Heading, Paragraph, ScrollView, Tooltip, XStack, YStack, ZStack, standardAnimation, useForceUpdate, useMedia, useTheme } from "@jonline/ui";
import { ChevronRight, CornerRightUp, HelpCircle, MoveUp } from '@tamagui/lucide-icons';
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
  serverPinningEntity?: string;
};
export function PinnedServerSelector({ show, serverPinningEntity }: PinnedServerSelectorProps) {
  const pinnedServers = useAppSelector(state => state.accounts.pinnedServers);

  const currentServer = useServer();
  const availableServers = useAppSelector(state =>
    selectAllServers(state.servers)
      .filter(server => (!currentServer || serverID(server) != serverID(currentServer))
        // && !pinnedServers.some(s => s.serverId === serverID(server))
      ));
  const [showDataSources, setShowDataSources] = useState(false);
  const pinnedServerCount = availableServers
    .filter(server => pinnedServers.some(s => s.pinned && s.serverId === serverID(server)))
    .length;
  const totalServerCount = availableServers.length;
  return <YStack w='100%' h={show ? undefined : 0} backgroundColor='$backgroundHover'>
    <AnimatePresence>
      {show ? <>
        <Button key='pinned-server-toggle' py='$1' h='auto' onPress={() => setShowDataSources(!showDataSources)}>
          <XStack mr='auto'>
            <Paragraph my='auto' size='$1'>
              {serverPinningEntity ? `+ ${serverPinningEntity} from ` : ''}{pinnedServerCount} of {totalServerCount} other {totalServerCount === 1 ? 'server' : 'servers'}
            </Paragraph>
            <XStack my='auto' animation='standard' rotate={showDataSources ? '90deg' : '0deg'}>
              <ChevronRight size='$1' />
            </XStack>
          </XStack>
        </Button>
        {showDataSources
          ? <YStack w='100%' animation='standard' {...standardAnimation}>
            <ScrollView key='pinned-server-scroller' w='100%' horizontal>
              <XStack m='$3' ai='center' space='$2'>
                {availableServers.map(server => {
                  let pinnedServer = pinnedServers.find(s => s.serverId === serverID(server));
                  return <PinnableServer key={serverID(server)} {...{ server, pinnedServer }} />;
                })}
              </XStack>
            </ScrollView>
          </YStack>
          : undefined}
      </> : undefined}
    </AnimatePresence>
  </YStack >;
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
  // console.log("PinnableServer", server.serverConfiguration?.serverInfo?.name, pinned);
  return <Button onPress={onPress} animation='standard'
    o={pinned ? 1 : 0.5}
    {...(pinned ? themedButtonBackground(primaryColor, primaryTextColor) : {})}>
    <ServerNameAndLogo server={server} textColor={pinned ? primaryTextColor : undefined} />
  </Button>;
}
