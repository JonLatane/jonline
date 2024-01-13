import { AnimatePresence, Button, Heading, Image, Paragraph, ScrollView, Tooltip, XStack, YStack, standardAnimation, standardHorizontalAnimation, useTheme } from "@jonline/ui";
import { AtSign, CheckCircle, ChevronRight, Circle, SeparatorHorizontal } from '@tamagui/lucide-icons';
import { useAppDispatch, useAppSelector, useLocalConfiguration, useMediaUrl, useServer } from "app/hooks";

import { useNavigationContext } from "app/contexts";
import { FederatedPagesStatus, JonlineAccount, JonlineServer, PinnedServer, getServerTheme, pinAccount, pinServer, selectAccountById, selectAllServers, serverID, setShowPinnedServers, setViewingRecommendedServers, unpinAccount } from "app/store";
import { themedButtonBackground } from "app/utils/themed_button_background";
import { useEffect } from "react";
import { accountID, setExcludeCurrentServer } from 'app/store';
import { AddAccountSheet } from "../accounts/add_account_sheet";
import RecommendedServer from "../accounts/recommended_server";
import { ServerNameAndLogo, splitOnFirstEmoji } from "./server_name_and_logo";


export type PinnedServerSelectorProps = {
  show?: boolean;
  transparent?: boolean;
  affectsNavigation?: boolean;
  pagesStatuses?: FederatedPagesStatus[];
  simplified?: boolean;
};
export function PinnedServerSelector({ show, transparent, affectsNavigation, pagesStatuses, simplified }: PinnedServerSelectorProps) {
  const dispatch = useAppDispatch();
  const pinnedServers = useAppSelector(state => state.accounts.pinnedServers);

  const currentServer = useServer();
  const allServers = useAppSelector(state => selectAllServers(state.servers));
  const availableServers = useAppSelector(state =>
    selectAllServers(state.servers)
      .filter(server => (!currentServer || serverID(server) != serverID(currentServer))
        // && !pinnedServers.some(s => s.serverId === serverID(server))
      ));
  // const [showDataSources, setShowDataSources] = useState(true);
  const pinnedServerCount = availableServers
    .filter(server => pinnedServers.some(s => s.pinned && s.serverId === serverID(server)))
    .length;
  const totalServerCount = availableServers.length;
  const { showPinnedServers, viewingRecommendedServers, browsingServers } = useLocalConfiguration();


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
  const navigationContext = useNavigationContext();
  useEffect(() => {
    if (navigationContext && affectsNavigation) {
      const pinnedServersHeight = document.querySelector('#navigation-pinned-servers')?.clientHeight ?? 0;
      navigationContext.setPinnedServersHeight(pinnedServersHeight);
    }
  },
    [
      allServers.map(serverID).toString(),
      pinnedServers.map(p => p.serverId).toString(),
      currentServer ? serverID(currentServer) : undefined,
      viewingRecommendedServers,
      browsingServers,
      showPinnedServers
    ]
  );
  const excludeCurrentServer = useAppSelector(state => state.accounts.excludeCurrentServer);
  return <YStack key='pinned-server-selector' id={affectsNavigation ? 'navigation-pinned-servers' : undefined}
    w='100%' h={show ? undefined : 0}
    backgroundColor={transparent ? undefined : '$backgroundHover'}
  >
    {/* <AnimatePresence> */}
    {show ? <>
      {simplified
        ? undefined
        : <XStack key='pinned-server-toggle-row'>
          <Button key='pinned-server-toggle' py='$1' h='auto' borderRadius={0} onPress={() => dispatch(setShowPinnedServers(!showPinnedServers))} f={1}>
            <XStack mr='auto'>
              <Paragraph my='auto' size='$1'>
                From {excludeCurrentServer ? '' : `${shortServerName} and `}{pinnedServerCount} of {totalServerCount} other {totalServerCount === 1 ? 'server' : 'servers'}
              </Paragraph>
              <XStack my='auto' animation='standard' rotate={showPinnedServers ? '90deg' : '0deg'}>
                <ChevronRight size='$1' />
              </XStack>
            </XStack>
          </Button>
          <Button key='exclude-current-server-toggle' py='$1' h='auto' borderRadius={0}
            onPress={() => dispatch(setExcludeCurrentServer(!excludeCurrentServer))}>
            <XStack ml='auto' space='$2'>
              {excludeCurrentServer ? <CheckCircle size='$1' /> : <Circle size='$1' />}
              <Paragraph my='auto' size='$1'>
                Exclude{excludeCurrentServer? ` ${shortServerName}` : ''}
              </Paragraph>
            </XStack>
          </Button>
        </XStack>}
      {showPinnedServers
        ? <YStack w='100%' key='pinned-server-scroller-container' animation='standard' {...standardAnimation}>
          <ScrollView key='pinned-server-scroller' w='100%' horizontal>
            <XStack m='$3' ai='center' space='$2' key='available-servers'>
              <AnimatePresence>
                {availableServers.map(server => {
                  let pinnedServer = pinnedServers.find(s => s.serverId === serverID(server));
                  return <XStack key={serverID(server)} animation='standard' {...standardHorizontalAnimation} mr='$2'>
                    <PinnableServer {...{ server, pinnedServer, simplified: simplified }} />
                  </XStack>;
                })}

                {recommendedServerHosts.length > 0
                  ? <XStack key='recommended-servers-button' animation='standard' {...standardAnimation}>
                    <Button h='auto' py='$1' mr='$2' size='$2'
                      onPress={() => dispatch(setViewingRecommendedServers(!viewingRecommendedServers))}>
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
                  </XStack>
                  : undefined}

                {viewingRecommendedServers ?
                  <XStack key='recommended-servers' animation='standard' {...standardHorizontalAnimation}>
                    {recommendedServerHosts.map((host, index) => {
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
                    })}
                  </XStack>
                  : recommendedServerHosts.length > 0
                    ? <XStack key='recommendedServerHosts-spacer' w='$10' />
                    : undefined}
              </AnimatePresence>
            </XStack>
          </ScrollView>
        </YStack>
        : undefined}
    </> : undefined}
    {/* </AnimatePresence> */}
  </YStack >;
}



export type PinnableServerProps = {
  server: JonlineServer;
  pinnedServer?: PinnedServer;
  simplified?: boolean;
};
export function PinnableServer({ server, pinnedServer, simplified }: PinnableServerProps) {
  const pinned = !!pinnedServer?.pinned;
  const theme = useTheme();
  const dispatch = useAppDispatch();
  const account = useAppSelector(state => pinnedServer?.accountId ? selectAccountById(state.accounts, pinnedServer.accountId) : undefined);
  const { primaryColor, primaryTextColor, primaryAnchorColor, navColor, navTextColor } = getServerTheme(server, theme);
  const onPress = () => {
    const updatedValue: PinnedServer = pinnedServer
      ? { ...pinnedServer, pinned: !pinnedServer.pinned }
      : { serverId: serverID(server), pinned: true, accountId: undefined };
    dispatch(pinServer(updatedValue));
  }

  const pinnedAccount = useAppSelector(state => pinnedServer?.accountId ? selectAccountById(state.accounts, pinnedServer.accountId) : undefined);
  const toggleAccountSelect = (account: JonlineAccount) => {
    if (accountID(account) === accountID(pinnedAccount)) {
      dispatch(unpinAccount(account));
    } else {
      dispatch(pinAccount(account));
    }
  };
  const avatarUrl = useMediaUrl(account?.user.avatar?.id, { account, server: account?.server });
  const avatarSize = 20;

  return <YStack maw={170}>
    {simplified
      ? undefined
      : <AddAccountSheet server={server}
        selectedAccount={pinnedAccount}
        onAccountSelected={toggleAccountSelect}
        button={(onPress) =>
          <Button onPress={onPress} animation='standard' h='auto' px='$2'
            borderBottomWidth={1} borderBottomLeftRadius={0} borderBottomRightRadius={0}
            o={pinned ? 1 : 0.5}
            {...(pinned ? themedButtonBackground(navColor, navTextColor) : {})}>
            <XStack ai='center' w='100%' space='$2'>

              {(avatarUrl && avatarUrl != '') ?

                <XStack w={avatarSize} h={avatarSize} ml={-3} mr={-3}>
                  <Image
                    pos="absolute"
                    width={avatarSize}
                    height={avatarSize}
                    borderRadius={avatarSize / 2}
                    resizeMode="cover"
                    als="flex-start"
                    source={{ uri: avatarUrl, width: avatarSize, height: avatarSize }}
                  />
                </XStack>
                : undefined}
              <Paragraph f={1} size='$1' whiteSpace="nowrap" overflow="hidden" textOverflow="ellipse" color={pinned ? navTextColor : undefined} o={pinnedAccount ? 1 : 0.5}>
                {pinnedAccount
                  ? pinnedAccount?.user.username
                  : 'anonymous'}
              </Paragraph>
              <AtSign size='$1' color={pinned ? navTextColor : undefined} />
            </XStack>
          </Button>} />
    }
    <Button onPress={onPress} animation='standard' h='auto'
      borderTopLeftRadius={simplified ? undefined : 0} borderTopRightRadius={simplified ? undefined : 0}
      o={pinned ? 1 : 0.5}
      {...(pinned ? themedButtonBackground(primaryColor, primaryTextColor) : {})}>
      <ServerNameAndLogo server={server} textColor={pinned ? primaryTextColor : undefined} />
    </Button>
  </YStack>;
}
