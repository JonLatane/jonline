import { AnimatePresence, Button, Heading, Image, Paragraph, ScrollView, Spinner, Tooltip, XStack, YStack, reverseStandardAnimation, standardAnimation, standardHorizontalAnimation, useMedia, useTheme } from "@jonline/ui";
import { AtSign, CheckCircle, ChevronRight, Circle, Maximize2, Minimize2, SeparatorHorizontal } from '@tamagui/lucide-icons';
import { useAccount, useAppDispatch, useAppSelector, useLocalConfiguration, useMediaUrl } from "app/hooks";

import { FederatedPagesStatus, JonlineAccount, JonlineServer, PinnedServer, accountID, getServerTheme, pinAccount, pinServer, selectAccountById, selectAllServers, serverID, setExcludeCurrentServer, setShowPinnedServers, setShrinkPreviews, setViewingRecommendedServers, unpinAccount, useServerTheme } from "app/store";
import { themedButtonBackground } from "app/utils/themed_button_background";
import { AddAccountSheet } from "../accounts/add_account_sheet";
import RecommendedServer from "../accounts/recommended_server";
import { ServerNameAndLogo, splitOnFirstEmoji } from "./server_name_and_logo";
import { useHideNavigation } from "./use_hide_navigation";
import FlipMove from 'react-flip-move';
import { ex } from "@fullcalendar/core/internal-common";


export type PinnedServerSelectorProps = {
  show?: boolean;
  transparent?: boolean;
  affectsNavigation?: boolean;
  pagesStatuses?: FederatedPagesStatus[];
  simplified?: boolean;
  showShrinkPreviews?: boolean;
};
export function PinnedServerSelector({
  show,
  transparent,
  affectsNavigation,
  pagesStatuses,
  simplified,
  showShrinkPreviews
}: PinnedServerSelectorProps) {
  const mediaQuery = useMedia();
  const dispatch = useAppDispatch();
  const pinnedServers = useAppSelector(state => state.accounts.pinnedServers);
  const { server: currentServer, primaryColor, primaryTextColor, primaryAnchorColor, navColor, navTextColor } = useServerTheme();

  const allServers = useAppSelector(state => selectAllServers(state.servers));
  const availableServers = useAppSelector(state =>
    selectAllServers(state.servers)
      .filter(server => simplified || !currentServer || server.host !== currentServer.host));

  const pinnedServerCount = availableServers
    .filter(server => pinnedServers.some(s => s.pinned && s.serverId === serverID(server)))
    .length;
  const totalServerCount = availableServers.length;
  const { showPinnedServers, viewingRecommendedServers, browsingServers, shrinkPreviews } = useLocalConfiguration();


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

  const shortServerName = currentServer?.serverConfiguration?.serverInfo?.shortName
    ||
    // Note the split *without* support for pipes (so | will be included)
    splitOnFirstEmoji(
      currentServer?.serverConfiguration?.serverInfo?.name ?? '...'
    )[0].replace(/\s*\|\s*/, ' ');

  const disabled = useHideNavigation();

  const excludeCurrentServer = useAppSelector(state => state.accounts.excludeCurrentServer);
  const configuringFederation = useAppSelector(state => state.servers.configuringFederation);
  const accountId = accountID(useAccount());
  function toggleExcludeCurrentServer() {
    const updatedValue = !excludeCurrentServer;
    dispatch(setExcludeCurrentServer(updatedValue));
    if (updatedValue && !pinnedServers.some(s => s.pinned && s.serverId !== serverID(currentServer!))) {
      dispatch(setShowPinnedServers(true));
    }
    dispatch(pinServer({ serverId: serverID(currentServer!), pinned: !updatedValue, accountId }));
  };

  const description = excludeCurrentServer && pinnedServerCount === 0
    ? 'No servers are selected'
    : excludeCurrentServer
      ? totalServerCount === pinnedServerCount
        ? `From ${pinnedServerCount} other ${pinnedServerCount === 1 ? 'server' : 'servers'}`
        : `From ${pinnedServerCount} of ${totalServerCount} other ${totalServerCount === 1 ? 'server' : 'servers'}`
      : totalServerCount === pinnedServerCount
        ? `From ${shortServerName} and ${pinnedServerCount} other ${pinnedServerCount === 1 ? 'server' : 'servers'}`
        : `From ${shortServerName} and ${pinnedServerCount} of ${totalServerCount} other ${totalServerCount === 1 ? 'server' : 'servers'}`;

  return <YStack key='pinned-server-selector' id={affectsNavigation ? 'navigation-pinned-servers' : undefined}
    w='100%' h={show ? undefined : 0}
    backgroundColor={transparent ? '$backgroundHover' : '$backgroundHover'}
    o={transparent ? 0.5 : 1}
  >
    {/* <AnimatePresence> */}
    {configuringFederation ?
      <XStack mx='$2' my='$1' gap='$2' ai='center' animation='standard' {...standardAnimation}>
        <Spinner size='small' color={primaryAnchorColor} />
        <Paragraph size='$1'>Configuring servers...</Paragraph>
      </XStack>
      : undefined}
    {/* </AnimatePresence> */}
    {/* <AnimatePresence> */}
    {show && !disabled ? <>
      <XStack key='pinned-server-toggle-row'>
        {simplified
          ? undefined
          : <>
            <Button key='pinned-server-toggle' py='$1'
              pl='$2' pr='$1'
              h='auto' transparent onPress={() => dispatch(setShowPinnedServers(!showPinnedServers))} f={1}>
              <XStack mr='auto' maw='100%'>
                <Paragraph my='auto' size='$1' whiteSpace="nowrap" overflow="hidden" textOverflow="ellipsis">
                  {description}
                </Paragraph>
                <XStack my='auto' animation='standard' rotate={showPinnedServers ? '90deg' : '0deg'}>
                  <ChevronRight size='$1' />
                </XStack>
              </XStack>
            </Button>
            <Button key='exclude-current-server-toggle' py='$1' h='auto' transparent
              onPress={toggleExcludeCurrentServer}>
              <XStack ml='auto' gap='$2'>
                {excludeCurrentServer ? <CheckCircle size='$1' /> : <Circle size='$1' />}
                <Paragraph my='auto' size='$1'>
                  Exclude{excludeCurrentServer || mediaQuery.gtSm ? ` ${shortServerName}` : ''}
                </Paragraph>
              </XStack>
            </Button>

            <AnimatePresence>
              {showShrinkPreviews
                ? <Button key='shrink-previews-button' py='$1' h='auto' transparent
                  animation='standard' {...reverseStandardAnimation}
                  onPress={() => dispatch(setShrinkPreviews(!shrinkPreviews))}>
                  <XStack position='absolute' animation='standard' o={shrinkPreviews ? 1 : 0} scale={shrinkPreviews ? 1 : 2}>
                    <Maximize2 size='$1' />
                  </XStack>
                  <XStack position='absolute' animation='standard' o={shrinkPreviews ? 0 : 1} scale={shrinkPreviews ? 0.2 : 1}>
                    <Minimize2 size='$1' />
                  </XStack>
                </Button>
                : undefined}
            </AnimatePresence>
          </>
        }
      </XStack>
      {showPinnedServers || simplified && !disabled
        ? <YStack w='100%' key='pinned-server-scroller-container' animation='standard' {...standardAnimation}>
          <ScrollView key='pinned-server-scroller' w='100%' horizontal>
            <XStack mx='$3' my='$1' py='$1' ai='center' gap='$2' key='available-servers'>
              <FlipMove style={{ display: 'flex', alignItems: 'center' }}>
                {availableServers.map(server => {
                  let pinnedServer = pinnedServers.find(s => s.serverId === serverID(server));
                  return <XStack key={`server-${server.host}`} //animation='standard' {...standardHorizontalAnimation}
                    mr='$2'>
                    <PinnableServer {...{ server, pinnedServer, simplified: simplified }} />
                  </XStack>;
                })}

                {recommendedServerHosts.length > 0
                  ? <XStack key='recommended-servers-button' /*animation='standard' {...standardAnimation}*/>
                    <Button h='auto' py='$1' mr='$2' size='$2'
                      onPress={() => dispatch(setViewingRecommendedServers(!viewingRecommendedServers))}>
                      <XStack>
                        <YStack my='auto' ai='center'>
                          <Heading size='$1'>
                            Recommended
                          </Heading>
                          <Heading size='$1'>
                            Servers{recommendedServerHosts.length ? ` (${recommendedServerHosts.length})` : undefined}
                          </Heading>
                        </YStack>
                        <XStack my='auto' animation='quick' rotate={!viewingRecommendedServers ? '90deg' : '0deg'}>
                          <ChevronRight size='$1' />
                        </XStack>
                      </XStack>
                    </Button>
                  </XStack>
                  : undefined}

                {viewingRecommendedServers ?
                  // <XStack key='recommended-servers' animation='standard' {...standardHorizontalAnimation}>
                  <>
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
                        <XStack my='auto' key={`server-${host}`}>
                          <RecommendedServer host={host} tiny />
                        </XStack>
                      </>;
                    })}
                  </>
                  // </XStack>
                  : recommendedServerHosts.length > 0
                    ? <XStack key='recommendedServerHosts-spacer' w='$10' />
                    : undefined}
              </FlipMove>
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
  const loadingPosts = useAppSelector(state => state.posts.pagesStatus.values[server.host] === 'loading');
  const loadingEvents = useAppSelector(state => state.events.pagesStatus.values[server.host] === 'loading');
  const loadingUsers = useAppSelector(state => state.users.pagesStatus.values[server.host] === 'loading');
  return <YStack maw={170}>
    <XStack zi={1000000} pointerEvents="none" mx='auto'>
      <XStack position='absolute' animation='standard' o={loadingUsers ? 1 : 0}
        pointerEvents="none" ml={-20} mt={12}>
        <Spinner size='large' color={navColor} scaleX={-1.7} scaleY={1.7} />
      </XStack>
      <XStack position='absolute' animation='standard' o={loadingPosts ? 1 : 0}
        pointerEvents="none" ml={-20} mt={12}>
        <Spinner size='large' color={primaryColor} scale={1.4} />
      </XStack>
      <XStack position='absolute' animation='standard' o={loadingEvents ? 1 : 0}
        pointerEvents="none" ml={-20} mt={12}>
        <Spinner size='large' color={navColor} scaleX={1.1} scaleY={-1.1} />
      </XStack>
    </XStack>
    {simplified
      ? undefined
      : <AddAccountSheet server={server}
        selectedAccount={pinnedAccount}
        onAccountSelected={toggleAccountSelect}
        button={(onPress) =>
          <Button onPress={onPress} h='auto' px='$2'
            borderBottomWidth={1} borderBottomLeftRadius={0} borderBottomRightRadius={0}
            o={pinned ? 1 : 0.5}
            {...(pinned ? themedButtonBackground(navColor, navTextColor) : {})}>
            <XStack ai='center' w='100%' gap='$2'>

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
    <Button onPress={onPress} h='auto'
      px='$1'
      borderTopLeftRadius={simplified ? undefined : 0} borderTopRightRadius={simplified ? undefined : 0}
      o={pinned ? 1 : 0.5}
      {...(pinned ? themedButtonBackground(primaryColor, primaryTextColor) : {})}>
      <ServerNameAndLogo server={server} textColor={pinned ? primaryTextColor : undefined} />
    </Button>
  </YStack>;
}
