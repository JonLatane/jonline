import { Button, Heading, Image, Paragraph, ScrollView, Spinner, Tooltip, XStack, YStack, ZStack, standardAnimation, useMedia } from "@jonline/ui";
import { AtSign, CheckCircle, ChevronRight, Circle, Maximize2, Minimize2, PanelBottomClose, PanelTopClose, PanelTopOpen, SeparatorHorizontal, X as XIcon } from '@tamagui/lucide-icons';
import { useAppDispatch, useAppSelector, useCurrentAccount, useCurrentServer, useFederatedAccountOrServer, useLocalConfiguration, useMediaUrl } from "app/hooks";

import { FederatedPagesStatus, JonlineAccount, JonlineServer, PinnedServer, accountID, pinAccount, pinServer, selectAccountById, selectAllServers, serverID, setExcludeCurrentServer, setHideNavigation, setShowPinnedServers, setShrinkPreviews, setViewingRecommendedServers, unpinAccount, useServerTheme } from "app/store";
import { themedButtonBackground } from "app/utils/themed_button_background";
import FlipMove from 'react-flip-move';
import { AuthSheetButton } from "../accounts/auth_sheet_button";
import RecommendedServer, { useJonlineServerInfo } from "../accounts/recommended_server";
import { ServerNameAndLogo, splitOnFirstEmoji } from "./server_name_and_logo";
import { User } from "@jonline/api";


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
  const { alwaysShowHideButton, showPinnedServers, viewingRecommendedServers, browsingServers, shrinkPreviews, hideNavigation } = useLocalConfiguration();


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

  const disabled = false;//useHideNavigation();
  const excludeCurrentServer = useAppSelector(state => state.accounts.excludeCurrentServer);
  const configuringFederation = useAppSelector(state => state.servers.configuringFederation);
  const accountId = accountID(useCurrentAccount());
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
    : pinnedServerCount === 0
      ? `From ${shortServerName}`
      : excludeCurrentServer
        ? totalServerCount === pinnedServerCount
          ? `From ${pinnedServerCount} other ${pinnedServerCount === 1 ? 'server' : 'servers'}`
          : `From ${pinnedServerCount} of ${totalServerCount} other ${totalServerCount === 1 ? 'server' : 'servers'}`
        : totalServerCount === pinnedServerCount
          ? `From ${shortServerName} and ${pinnedServerCount} other ${pinnedServerCount === 1 ? 'server' : 'servers'}`
          : `From ${shortServerName} and ${pinnedServerCount} of ${totalServerCount} other ${totalServerCount === 1 ? 'server' : 'servers'}`;

  const { transparentBackgroundColor } = useServerTheme();
  const renderPinnedServers = showPinnedServers || simplified && !disabled;
  const childMargins = { paddingTop: 4, paddingBottom: 4 };
  return <YStack key='pinned-server-selector' id={affectsNavigation ? 'navigation-pinned-servers' : undefined}
    w='100%' h={show ? undefined : 0}
  // backgroundColor={transparentBackgroundColor}
  // o={transparent ? 1 : 1}
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

            {alwaysShowHideButton || hideNavigation || (mediaQuery.gtXs && mediaQuery.short)
              ? <Button key='hide-nav-button' py='$1' h='auto' transparent
                // animation='standard' {...reverseHorizontalAnimation}
                onPress={() => dispatch(setHideNavigation(!hideNavigation))}>
                <XStack position='absolute' animation='standard'
                  o={hideNavigation ? 1 : 0}
                  transform={[{ translateY: hideNavigation ? 0 : 10 }]}
                  scale={hideNavigation ? 1 : 2}>
                  <PanelTopOpen size='$1' />
                </XStack>
                <XStack position='absolute' animation='standard'
                  o={hideNavigation ? 0 : 1}
                  transform={[{ translateY: !hideNavigation ? 0 : 10 }]}
                  scale={hideNavigation ? 0.2 : 1}>
                  <PanelTopClose size='$1' />
                </XStack>
              </Button>
              : undefined}

            <Button key='pinned-server-toggle' py='$1'
              pl='$2' pr='$1'
              h='auto' transparent onPress={() => dispatch(setShowPinnedServers(!showPinnedServers))} f={1}>
              <XStack mr='auto' maw='100%' ai='center'>
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

            {/* <AnimatePresence> */}
            {showShrinkPreviews
              ? <Button key='shrink-previews-button' py='$1' h='auto' transparent
                // animation='standard' {...reverseHorizontalAnimation}
                onPress={() => dispatch(setShrinkPreviews(!shrinkPreviews))}>
                <XStack position='absolute' animation='standard' o={shrinkPreviews ? 1 : 0} scale={shrinkPreviews ? 1 : 2}>
                  <Maximize2 size='$1' />
                </XStack>
                <XStack position='absolute' animation='standard' o={shrinkPreviews ? 0 : 1} scale={shrinkPreviews ? 0.2 : 1}>
                  <Minimize2 size='$1' />
                </XStack>
              </Button>
              : undefined}
            {/* </AnimatePresence> */}
          </>
        }
      </XStack>
      <ScrollView key='pinned-server-scroller' w='100%' horizontal>
        <XStack mx='$3'
          ai='center' gap='$2' key='available-servers'>
          <FlipMove style={{ display: 'flex', alignItems: 'center' }}>
            {renderPinnedServers
              ? [
                availableServers.map(server => {
                  let pinnedServer = pinnedServers.find(s => s.serverId === serverID(server));
                  return <div key={`server-${server.host}`} style={{ display: 'flex', marginRight: 5, ...childMargins }}>
                    <PinnableServer {...{ server, pinnedServer, simplified: simplified }} />
                  </div>;
                }),
                recommendedServerHosts.length > 0
                  ? <div key='recommended-servers-button' style={{ display: 'flex', marginRight: -10, ...childMargins }}/*animation='standard' {...standardAnimation}*/>
                    <Button h='auto' py='$1' mr='$1' size='$2'
                      onPress={() => dispatch(setViewingRecommendedServers(!viewingRecommendedServers))}>
                      <XStack ai='center'>
                        <YStack my='auto' ai='center'>
                          <Heading size='$1'>
                            Recommended
                          </Heading>
                          <Heading size='$1'>
                            Servers{recommendedServerHosts.length ? ` (${recommendedServerHosts.length})` : undefined}
                          </Heading>
                        </YStack>
                        {/* <XStack my='auto' animation='quick' rotate={!viewingRecommendedServers ? '90deg' : '0deg'}>
                          <ChevronRight size='$1' />
                        </XStack> */}

                        <ZStack w='$1' h='$1'>
                          <XStack m='auto' animation='standard' o={viewingRecommendedServers ? 0 : 1} rotate={viewingRecommendedServers ? '-90deg' : '0deg'}>
                            <ChevronRight size='$1' />
                          </XStack>
                          <XStack m='auto' animation='standard' o={!viewingRecommendedServers ? 0 : 1} rotate={viewingRecommendedServers ? '-90deg' : '0deg'}>
                            <XIcon size='$1' />
                          </XStack>
                        </ZStack>
                      </XStack>
                    </Button>
                  </div>
                  : undefined,
                viewingRecommendedServers ?
                  // <XStack key='recommended-servers' animation='standard' {...standardHorizontalAnimation}>
                  recommendedServerHosts.map((host, index) => {
                    const precedingServer = index > 0 ? recommendedServerHosts[index - 1]! : undefined;
                    // console.log('ugh', host, index, 'preceding:', precedingServer, currentServerRecommendedHosts, currentServerRecommendedHosts.includes(host), precedingServer && currentServerRecommendedHosts.includes(precedingServer))
                    return [
                      precedingServer && !currentServerRecommendedHosts.includes(host) && currentServerRecommendedHosts.includes(precedingServer)
                        ? <div key='separator' style={{ display: 'flex', marginTop: 'auto', marginBottom: 'auto', ...childMargins }}>
                          <Tooltip>
                            <Tooltip.Trigger>
                              <SeparatorHorizontal size='$5' />
                            </Tooltip.Trigger>
                            <Tooltip.Content>
                              <Paragraph size='$1'>Servers to the right are recommended by servers other than {currentServer?.serverConfiguration?.serverInfo?.name}.</Paragraph>
                            </Tooltip.Content>
                          </Tooltip>
                        </div>
                        : undefined,
                      <div key={`server-${host}`} style={{ display: 'flex', marginTop: 'auto', marginBottom: 'auto', ...childMargins }}>
                        <RecommendedServer host={host} tiny />
                      </div>
                    ]
                  })
                  // </XStack>
                  : recommendedServerHosts.length > 0
                    ? <XStack key='recommendedServerHosts-spacer' w='$10' />
                    : undefined
              ]

              : undefined}
          </FlipMove>
        </XStack>
      </ScrollView>
      {/* </YStack>
        : undefined} */}

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
  const dispatch = useAppDispatch();
  const account = useAppSelector(state => pinnedServer?.accountId ? selectAccountById(state.accounts, pinnedServer.accountId) : undefined);
  const { primaryColor, primaryTextColor, primaryAnchorColor, navColor, navTextColor } = useServerTheme(server);
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
      : <AuthSheetButton server={server}
        // selectedAccount={pinnedAccount}
        // onAccountSelected={toggleAccountSelect}
        button={(onPress) =>
          <ShortAccountSelectorButton {...{ server, pinnedServer, onPress }} />} />
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


export type ShortAccountSelectorButtonProps = {
  server: JonlineServer;
  pinnedServer?: PinnedServer;
  onPress?: () => void;
};
export function ShortAccountSelectorButton({ server, pinnedServer, onPress }: ShortAccountSelectorButtonProps) {
  const pinned = !!pinnedServer?.pinned;
  const { navColor, navTextColor } = useServerTheme(server);
  const account = useAppSelector(state => pinnedServer?.accountId ? selectAccountById(state.accounts, pinnedServer.accountId) : undefined);
  // const avatarUrl = useMediaUrl(accountuser.avatar?.id, { account, server: account?.server });
  // const avatarSize = 20;
  // const pinnedAccount = useAppSelector(state => pinnedServer?.accountId ? selectAccountById(state.accounts, pinnedServer.accountId) : undefined);

  return <Button onPress={onPress} h='auto' py='$1' px='$2'
    borderBottomWidth={1} borderBottomLeftRadius={0} borderBottomRightRadius={0}
    o={pinned ? 1 : 0.5}
    disabled={!onPress}
    {...(pinned ? themedButtonBackground(navColor, navTextColor) : {})}>
    <AccountAvatarAndUsername account={account}
      textColor={pinned ? navTextColor : undefined} />
  </Button>;
}

export type AccountAvatarAndUsernameProps = {
  account?: JonlineAccount;
  user?: User;
  server?: JonlineServer;
  textColor?: string;
};
export function AccountAvatarAndUsername({
  account: specifiedAccount,
  server: specifiedServer,
  user: specifiedUser,
  textColor
}:
  AccountAvatarAndUsernameProps) {
  const user = specifiedUser ?? specifiedAccount?.user;
  const serverHost = specifiedServer?.host ?? specifiedAccount?.server?.host ??
    (user && 'serverHost' in user ? user.serverHost as string : undefined);

  const accountOrServer = useFederatedAccountOrServer(serverHost);
  const account = specifiedAccount ?? accountOrServer.account;

  const { server } = useJonlineServerInfo(serverHost ?? 'unknown');
  // const pinned = !!pinnedServer?.pinned;
  // const { primaryColor, primaryTextColor, primaryAnchorColor, navColor, navTextColor } = useServerTheme(server);
  // const account = useAppSelector(state => pinnedServer?.accountId ? selectAccountById(state.accounts, pinnedServer.accountId) : undefined);
  const avatarUrl = useMediaUrl(user?.avatar?.id, { account, server });
  const avatarSize = 20;

  return <XStack ai='center' w='100%' gap='$2'>

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
    <Paragraph f={1} size='$1' whiteSpace="nowrap" overflow="hidden" textOverflow="ellipse"
      color={textColor}
      o={user ? 1 : 0.5}>
      {user?.username ?? 'anonyous'}
    </Paragraph>
    <AtSign size='$1' color={textColor} />
  </XStack>;
}