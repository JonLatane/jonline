import { AnimatePresence, Button, ButtonProps, Heading, Paragraph, ScrollView, Tooltip, XStack, YStack, ZStack, standardAnimation, useForceUpdate, useMedia, useTheme } from "@jonline/ui";
import { ChevronRight, CornerRightUp, HelpCircle, MoveUp, SeparatorHorizontal } from '@tamagui/lucide-icons';
import { DarkModeToggle, doesPlatformPreferDarkMode } from "app/components/dark_mode_toggle";
import { useComponentKey, useAccount, useAccountOrServer, useAppDispatch, useLocalConfiguration, useAppSelector, useServer } from "app/hooks";
import { JonlineServer, PinnedServer, colorMeta, getServerTheme, pinServer, selectAllServers, serverID, setShowHelp, setViewingRecommendedServers, useServerTheme } from "app/store";
import { themedButtonBackground } from "app/utils/themed_button_background";
import moment, { Moment } from "moment";
import { useEffect, useState } from "react";
import { GestureResponderEvent } from "react-native";
import { ServerNameAndLogo, splitOnFirstEmoji } from "./server_name_and_logo";
import RecommendedServer from "../accounts/recommended_server";


export type PinnedServerSelectorProps = {
  show?: boolean;
};
export function PinnedServerSelector({ show }: PinnedServerSelectorProps) {
  const dispatch = useAppDispatch();
  const pinnedServers = useAppSelector(state => state.accounts.pinnedServers);

  const currentServer = useServer();
  const allServers = useAppSelector(state => selectAllServers(state.servers));
  const availableServers = useAppSelector(state =>
    selectAllServers(state.servers)
      .filter(server => (!currentServer || serverID(server) != serverID(currentServer))
        // && !pinnedServers.some(s => s.serverId === serverID(server))
      ));
  const [showDataSources, setShowDataSources] = useState(true);
  const pinnedServerCount = availableServers
    .filter(server => pinnedServers.some(s => s.pinned && s.serverId === serverID(server)))
    .length;
  const totalServerCount = availableServers.length;
  const { viewingRecommendedServers, browsingServers } = useLocalConfiguration();


  const currentServerRecommendedHosts = currentServer?.serverConfiguration?.serverInfo?.recommendedServerHosts ?? [];
  const allRecommendableServerHosts = [...new Set([
    ...(currentServer ? currentServerRecommendedHosts : []),
    ...allServers.filter(s => s.host != currentServer?.host)
      .flatMap(s => s.serverConfiguration?.serverInfo?.recommendedServerHosts ?? [])
  ])];
  const recommendedServerHostsUnfiltered = browsingServers
    ? allRecommendableServerHosts
    : [...new Set(currentServer?.serverConfiguration?.serverInfo?.recommendedServerHosts ?? [])];
  const currentServerHosts = allServers.map(s => s.host);
  const recommendedServerHosts = recommendedServerHostsUnfiltered
    .filter(host => !currentServerHosts.includes(host));

  const shortServerName = splitOnFirstEmoji(currentServer?.serverConfiguration?.serverInfo?.name ?? '...')[0];
  return <YStack w='100%' h={show ? undefined : 0} backgroundColor='$backgroundHover'>
    <AnimatePresence>
      {show ? <>
        <Button key='pinned-server-toggle' py='$1' h='auto' onPress={() => setShowDataSources(!showDataSources)}>
          <XStack mr='auto'>
            <Paragraph my='auto' size='$1'>
              From {shortServerName} and {pinnedServerCount} of {totalServerCount} other {totalServerCount === 1 ? 'server' : 'servers'}
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

                {recommendedServerHosts.length > 0
                  ? <Button h='auto' py='$1' my='auto' size='$2' onPress={() => dispatch(setViewingRecommendedServers(!viewingRecommendedServers))}>
                    <XStack>
                      <YStack my='auto' ai='center'>
                        <Heading size='$1'>
                          Recommended
                        </Heading>
                        {recommendedServerHosts.length > 0
                          ? <Heading size='$1'>({recommendedServerHosts.length})</Heading>
                          : undefined}
                      </YStack>
                      <XStack my='auto' animation='quick' rotate={!viewingRecommendedServers ? '90deg' : '0deg'}>
                        <ChevronRight size='$1' />
                      </XStack>
                    </XStack>
                  </Button>
                  : undefined}

                {viewingRecommendedServers ?
                  recommendedServerHosts.map((host, index) => {
                    const precedingServer = index > 0 ? recommendedServerHosts[index - 1]! : undefined;
                    // console.log('ugh', host, index, 'preceding:', precedingServer, currentServerRecommendedHosts, currentServerRecommendedHosts.includes(host), precedingServer && currentServerRecommendedHosts.includes(precedingServer))
                    return <>
                      {precedingServer && !currentServerRecommendedHosts.includes(host) && currentServerRecommendedHosts.includes(precedingServer)
                        ? <XStack key='separator' my='auto'>
                          <Tooltip>
                            <Tooltip.Trigger>
                              <SeparatorHorizontal size='$5' />
                            </Tooltip.Trigger>
                            <Tooltip.Content>
                              <Paragraph size='$1'>Servers to the right are recommended by servers other than {currentServer?.serverConfiguration?.serverInfo?.name}.</Paragraph>
                            </Tooltip.Content>
                          </Tooltip>
                        </XStack>
                        : undefined}
                      <XStack my='auto' key={`recommended-server-${host}`}>
                        <RecommendedServer host={host} tiny />
                      </XStack>
                    </>;
                  })
                  : undefined}

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
