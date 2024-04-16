import { Button, ColorTokens, Heading, Image, Input, Label, Paragraph, ScrollView, Sheet, SizeTokens, Switch, Theme, Tooltip, XStack, YStack, ZStack, useDebounceValue, useMedia } from '@jonline/ui';
import { AlertCircle, Cpu, Router, AlertTriangle, ArrowDownUp, AtSign, ChevronDown, ChevronLeft, ChevronRight, Info, Plus, SeparatorHorizontal, Server } from '@tamagui/lucide-icons';
import { DarkModeToggle } from 'app/components/dark_mode_toggle';
import { useAppDispatch, useCurrentAccount, useFederatedAccountOrServer, useLocalConfiguration } from 'app/hooks';
import { useMediaUrl } from 'app/hooks/use_media_url';
import { FederatedEntity, FederatedGroup, RootState, accountID, clearServerAlerts, selectAllAccounts, selectAllServers, serverID, setBrowsingServers, setSeparateAccountsByServer, setViewingRecommendedServers, upsertServer, useRootSelector, useServerTheme } from 'app/store';
import { themedButtonBackground } from 'app/utils';
import React, { useEffect, useState } from 'react';
import FlipMove from 'react-flip-move';
import { Platform } from 'react-native';
import { useLink } from 'solito/link';
import { v4 as uuidv4 } from 'uuid';
import { physicallyHostingServerId } from '../about/about_screen';
import { ServerNameAndLogo } from '../navigation/server_name_and_logo';
import { SettingsSheet } from '../settings_sheet';
import AccountCard from './account_card';
import { AuthSheet } from './auth_sheet';
import RecommendedServer from './recommended_server';
import ServerCard from './server_card';
import { AuthSheetButton } from './auth_sheet_button';

export type AccountsSheetProps = {
  size?: SizeTokens;
  // Indicate to the AccountsSheet that we're
  // viewing server configuration for a server,
  // and should only show accounts for that server.
  // onlyShowServer?: JonlineServer;
  selectedGroup?: FederatedGroup;
  primaryEntity?: FederatedEntity<any>;
}
const doesPlatformPreferDarkMode = () =>
  window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches;

export function AccountsSheet({ size = '$5', selectedGroup, primaryEntity }: AccountsSheetProps) {
  const mediaQuery = useMedia();
  const [open, setOpen] = useState(false);
  const primaryAccountOrServer = useFederatedAccountOrServer(primaryEntity);
  const { allowServerSelection: allowServerSelectionSetting, separateAccountsByServer, browsingServers, viewingRecommendedServers } = useLocalConfiguration();
  const [addingServer, setAddingServer] = useState(false);
  const [position, setPosition] = useState(0);
  const [newServerHost, setNewServerHost] = useState('');
  const [newServerSecure, setNewServerSecure] = useState(true);

  const [hasOpened, setHasOpened] = useState(open);
  useEffect(() => {
    if (open && !hasOpened) {
      setHasOpened(true);
    }
  }, [hasOpened, open]);
  const openChanged = useDebounceValue(open, 3000);
  useEffect(() => {
    if (!openChanged) {
      setHasOpened(false);
    }
  }, [openChanged])
  const dispatch = useAppDispatch();
  const { server: currentServer, textColor, backgroundColor, primaryColor, primaryTextColor, navColor, navTextColor, warningAnchorColor } = useServerTheme();

  const account = useCurrentAccount();
  const serversState = useRootSelector((state: RootState) => state.servers);
  const servers = useRootSelector((state: RootState) => selectAllServers(state.servers));
  const allowServerSelection = allowServerSelectionSetting || servers.length > 1;
  const serversLoading = serversState.status == 'loading';
  const newServerHostNotBlank = newServerHost != '';
  const newServerExists = servers.some(s => s.host == newServerHost);
  const newServerValid = newServerHostNotBlank && !newServerExists;
  const browsingOn = Platform.OS == 'web' ? window.location.hostname : undefined
  const effectiveServer = primaryAccountOrServer.server ?? currentServer;

  const browsingOnDiffers = Platform.OS == 'web' &&
    effectiveServer?.host != browsingOn;
  //   serversState.server && serversState.server.host != browsingOn ||
  //   onlyShowServer && onlyShowServer.host != browsingOn
  // );
  function addServer() {
    console.log(`Connecting to server ${newServerHost}`)
    dispatch(clearServerAlerts());
    dispatch(upsertServer({
      host: newServerHost,
      secure: newServerSecure,
    }));
  }

  const accountsState = useRootSelector((state: RootState) => state.accounts);
  const accounts = useRootSelector((state: RootState) => selectAllAccounts(state.accounts));
  const primaryServer = primaryEntity?.serverHost || currentServer;
  const accountsOnPrimaryServer = primaryServer ? accounts.filter(a => serverID(a.server) == serverID(primaryServer!)) : [];
  const accountsElsewhere = accounts.filter(a => !accountsOnPrimaryServer.includes(a));
  const displayedAccounts = accounts;


  const currentServerHosts = servers.map(s => s.host);

  const currentServerRecommendedHosts = currentServer?.serverConfiguration?.serverInfo?.recommendedServerHosts ?? [];
  const allRecommendableServerHosts = [...new Set([
    ...(currentServer ? currentServerRecommendedHosts : []),
    ...servers.filter(s => s.host != currentServer?.host)
      .flatMap(s => s.serverConfiguration?.serverInfo?.recommendedServerHosts ?? [])
  ])];
  const recommendedServerHostsUnfiltered = browsingServers
    ? allRecommendableServerHosts
    : [...new Set(currentServer?.serverConfiguration?.serverInfo?.recommendedServerHosts ?? [])];
  const recommendedServerHosts = recommendedServerHostsUnfiltered
    .filter(host => !currentServerHosts.includes(host));

  const accountsLoading = accountsState.status == 'loading';
  const [forceDisableAccountButtons, setForceDisableAccountButtons] = useState(false);

  useEffect(() => {
    if (accountsLoading && !forceDisableAccountButtons) {
      setForceDisableAccountButtons(true);
    } else if (!accountsLoading && forceDisableAccountButtons) {
      setForceDisableAccountButtons(false);
    }
  }, [accountsLoading, forceDisableAccountButtons]);

  // useEffect(() => {
  //   if (!allowServerSelection && browsingServers) {
  //     dispatch(setBrowsingServers(false));
  //   }
  // }, [allowServerSelection, browsingServers]);
  const serversDiffer = primaryEntity && currentServer && primaryEntity.serverHost != currentServer.host;
  const serverId = currentServer ? serverID(currentServer) : undefined;
  // debugger;
  const currentServerInfoLink = useLink({
    href: serverId === physicallyHostingServerId() ? '/about' : `/server/${serverId!}`
  });
  // bc react native may render multiple accounts sheets at a time
  const secureLabelUuid = uuidv4();
  const secureRequired = Platform.OS == 'web' && window.location.protocol == 'https';
  const disableSecureSelection = serversLoading || secureRequired;

  const avatarUrl = useMediaUrl(account?.user.avatar?.id, { account, server: account?.server });

  // const userIcon = serversDiffer || browsingOnDiffers
  //   ? AlertTriangle :
  //   account ? UserIcon : LogIn;

  // const currentServer = currentServer;
  const avatarSize = 22;
  const alertTriangle = ({ color }: { color?: string | ColorTokens } = {}) => <Tooltip>
    <Tooltip.Trigger>
      <AlertTriangle color={color} />
    </Tooltip.Trigger>
    <Tooltip.Content>
      <Paragraph size='$1'>You are seeing data as though you were on {currentServer?.host}, although you're on {browsingOn}.</Paragraph>
    </Tooltip.Content>
  </Tooltip>;
  return <>
    <Button
      my='auto'
      size={size}
      {...themedButtonBackground(navColor, navTextColor)}
      // backgroundColor={navColor}
      h='auto'
      icon={serversDiffer || browsingOnDiffers
        ? alertTriangle({ color: navTextColor })
        : accounts.some(a => a.needsReauthentication)
          ? <AlertCircle color={navTextColor} />
          : undefined}
      borderBottomLeftRadius={0} borderBottomRightRadius={0}
      px='$2'
      py='$1'
      onPress={() => setOpen(true)}
    >
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
      <YStack f={1}>
        <Paragraph size='$1' color={navTextColor} o={account ? 1 : 0.5}
          whiteSpace='nowrap' overflow='hidden' textOverflow='ellipses'>
          {account?.user?.username ?? 'anonymous'}
        </Paragraph>
      </YStack>
      {selectedGroup ? undefined :
        <AtSign size='$1' color={navTextColor} />
      }

      {/* </XStack> */}
    </Button>
    {hasOpened
      ? <Sheet
        modal
        open={open}
        onOpenChange={setOpen}
        // snapPoints={[80]}
        snapPoints={[
          // 50, 
          91
        ]}
        zIndex={500000}
        position={position}
        onPositionChange={setPosition}
        dismissOnSnapToBottom

      >
        <Sheet.Overlay />
        <Sheet.Frame>
          <Sheet.Handle />
          {/* } */}
          <XStack gap='$4'
            h='$5' // paddingHorizontal='$3'
            mx='$3'
            mb='$2'
            ai='center'>
            <Button
              alignSelf='center'
              size="$3"
              circular
              icon={ChevronLeft}
              onPress={() => setOpen(false)} />
            <FlipMove style={{ flex: 1, display: 'flex', flexDirection: 'column' }}>
              <div key='accounts'>
                <Heading size='$7' mr='$2'>Accounts</Heading>
              </div>
              {browsingServers
                ? <div key='and-servers'>
                  <Heading size='$1'>& Servers</Heading>
                </div>
                : undefined}
            </FlipMove>
            {/* <XStack pointerEvents='none' o={0}><TutorialToggle onPress={() => setOpen(false)} /></XStack> */}
            {/* <XStack f={1} />
            <XStack f={1} /> */}
            <Button size='$3' circular p={0}
              onPress={() => dispatch(setBrowsingServers(!browsingServers))}
              animation='standard'
            // opacity={allowServerSelection || servers.length > 1 ? 1 : 0}
            // disabled={!(allowServerSelection || servers.length > 1)} 
            >
              <ZStack w='$2' h='$2'>
                <XStack m='auto' animation='standard' o={!browsingServers ? 0 : 1} rotate={browsingServers ? '-90deg' : '0deg'}>
                  <ChevronLeft size='$1' />
                </XStack>
                <XStack m='auto' animation='standard' o={browsingServers ? 0 : 1} rotate={browsingServers ? '-90deg' : '0deg'}>
                  <Router size='$1' />
                </XStack>
                <Theme inverse>
                  <XStack m='auto' animation='standard' px='$1' borderRadius='$3'
                    transform={[{ translateX: 15 }, { translateY: 10 }]}
                    backgroundColor={textColor}>
                    <Paragraph size='$1' color={backgroundColor} mx='$1' fontWeight='bold'>{servers.length}</Paragraph>
                  </XStack>
                </Theme>
              </ZStack>
            </Button>

            <DarkModeToggle />
            <SettingsSheet size='$3' />
          </XStack>
          <Sheet.ScrollView px="$4" pb='$4' pt='$1' f={1}>
            <FlipMove style={{ maxWidth: 800, width: '100%', alignSelf: 'center' }}>
              {/* <YStack maxWidth={800} gap width='100%' alignSelf='center'> */}
              {browsingServers
                ? <div key='server-header'>
                  <XStack ai='center'>
                    {browsingServers
                      ? <Heading size='$5' marginRight='$2'>Servers</Heading>
                      : undefined}

                    {browsingServers ? <Button
                      size="$3"
                      icon={Plus}
                      marginLeft='auto'
                      // circular
                      onPress={() => setAddingServer((x) => !x)}
                    >
                      Add
                    </Button> : undefined}
                    <Sheet
                      modal
                      open={addingServer}
                      onOpenChange={setAddingServer}
                      // snapPoints={[80]}
                      snapPoints={[81]} dismissOnSnapToBottom
                      position={position}
                      onPositionChange={setPosition}
                    // dismissOnSnapToBottom
                    >
                      <Sheet.Overlay />
                      <Sheet.Frame padding="$5">
                        <Sheet.Handle />
                        <Button
                          alignSelf='center'
                          size="$6"
                          circular
                          icon={ChevronDown}
                          onPress={() => {
                            setAddingServer(false)
                          }}
                        />
                        <YStack gap="$2" maxWidth={600} width='100%' alignSelf='center'>
                          <Heading size="$10" f={1}>Add Server</Heading>
                          <YStack>
                            <Input textContentType="URL" keyboardType='url' autoCorrect={false} autoCapitalize='none' placeholder="Server Hostname"
                              editable={!serversLoading}
                              opacity={serversLoading || newServerHost.length === 0 ? 0.5 : 1}
                              value={newServerHost}
                              onChange={(data) => setNewServerHost(data.nativeEvent.text)} />
                          </YStack>
                          {(newServerHostNotBlank && newServerExists && !serversState.successMessage) ? <Heading size="$2" color="red" alignSelf='center'>Server already exists</Heading> : undefined}
                          <XStack>
                            <YStack f={1} mx='auto' opacity={disableSecureSelection ? 0.5 : 1}>
                              <Switch size="$1" style={{ marginLeft: 'auto', marginRight: 'auto' }} id={`newServerSecure-${secureLabelUuid}`} aria-label='Secure'
                                defaultChecked
                                onCheckedChange={(checked) => setNewServerSecure(checked)}
                                disabled={disableSecureSelection} >
                                <Switch.Thumb animation="quick" disabled={disableSecureSelection} />
                              </Switch>

                              <Label style={{ flex: 1, alignContent: 'center', marginLeft: 'auto', marginRight: 'auto' }} htmlFor={`newServerSecure-${secureLabelUuid}`} >
                                <Heading size="$2">Secure</Heading>
                              </Label>
                            </YStack>
                            <Button f={2} backgroundColor={primaryColor} color={primaryTextColor}
                              onPress={addServer} disabled={serversLoading || !newServerValid} opacity={serversLoading || !newServerValid ? 0.5 : 1}>
                              Add Server
                            </Button>
                          </XStack>
                          {serversState.errorMessage ? <Heading size="$2" color="red" alignSelf='center'>{serversState.errorMessage}</Heading> : undefined}
                          {serversState.successMessage ? <Heading size="$2" color="green" alignSelf='center'>{serversState.successMessage}</Heading> : undefined}
                        </YStack>
                      </Sheet.Frame>
                    </Sheet>
                  </XStack>
                </div>
                : undefined}

              {!browsingServers ?
                <div key='primary-server-logo'>
                  <XStack w='100%' mx='auto'
                    ai='center'
                    mt={allowServerSelection ? '$3' : undefined}>
                    <XStack f={1} />
                    <YStack
                      ai='center'
                      // w='100%'
                      pl='$1'
                      pr='$2'>
                      <ServerNameAndLogo enlargeSmallText />

                      <Heading size='$3' als='center' ta='center'>
                        {currentServer ? currentServer.host : '<None>'}{serversDiffer ? ' is selected' : ''}
                      </Heading>

                    </YStack>
                    {currentServerInfoLink
                      ? <Button size='$3' my='auto' ml='$2' onPress={(e) => { e.stopPropagation(); currentServerInfoLink.onPress(e); }} icon={<Info />} circular />
                      : undefined}
                    <XStack f={1} />


                  </XStack>
                </div>
                : undefined}

              {servers.length === 0
                ?
                <div key='no-servers'>
                  <Heading size="$2" alignSelf='center' paddingVertical='$6'>No servers added.</Heading>
                </div>
                : undefined}

              <div key='servers'>
                <ScrollView horizontal>
                  <XStack gap='$3'>
                    <FlipMove style={{ display: 'flex' }}>
                      {browsingServers
                        ? servers.map((server, index) => {
                          return <span key={`serverCard-${serverID(server)}`} style={{ margin: 2 }}>
                            <ServerCard
                              // linkToServerInfo={onlyShowServer !== undefined}
                              server={server}
                              isPreview />
                          </span>;
                        })
                        : undefined}
                    </FlipMove>
                  </XStack>
                </ScrollView>
              </div>

              {recommendedServerHosts.length > 0
                ? [
                  <div key='recommended-servers-link'>
                    <Button mt='$2' size='$2' mx='auto' onPress={() => dispatch(setViewingRecommendedServers(!viewingRecommendedServers))}>
                      <XStack>
                        <Heading size='$1'>{browsingServers ? 'All ' : ''}Recommended Servers{recommendedServerHosts.length > 0 ? ` (${recommendedServerHosts.length})` : ''}</Heading>
                        <XStack animation='quick' rotate={viewingRecommendedServers ? '90deg' : '0deg'}>
                          <ChevronRight size='$1' />
                        </XStack>
                      </XStack>
                    </Button>
                  </div>,
                  viewingRecommendedServers
                    ?
                    <div key='recommended-servers'>
                      <XStack mt='$2' mb='$2' w='100%'>
                        <ScrollView f={1} horizontal>
                          <FlipMove style={{
                            display: 'flex',
                            flexDirection: 'row',
                            alignItems: 'center',
                            // justifyContent: 'center',
                            // width: '100%',
                            // overflow: 'auto',
                            // whiteSpace: 'nowrap',
                            // overflowX: 'scroll',
                            // overflowY: 'hidden',
                            // scrollbarWidth: 'none',
                            // msOverflowStyle: 'none',
                            // '&::-webkit-scrollbar': { display: 'none' }

                          }}>
                            {recommendedServerHosts.map((host, index) => {
                              const precedingServer = index > 0 ? recommendedServerHosts[index - 1]! : undefined;
                              // console.log('ugh', host, index, 'preceding:', precedingServer, currentServerRecommendedHosts, currentServerRecommendedHosts.includes(host), precedingServer && currentServerRecommendedHosts.includes(precedingServer))
                              return <div key={`server-${host}`}>
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
                              </div>;
                            })}
                          </FlipMove>
                        </ScrollView>

                        {allRecommendableServerHosts.length > recommendedServerHosts.length
                          ? <Button ml='auto' my='auto' onPress={() => dispatch(setBrowsingServers(true))}>
                            <YStack ai='center'>
                              <Paragraph size='$2' lineHeight={15} fontWeight='700'>{allRecommendableServerHosts.length - recommendedServerHosts.length}</Paragraph>
                              <Paragraph size='$1' lineHeight={15}>more</Paragraph>
                            </YStack>
                          </Button>
                          : undefined}
                      </XStack>
                    </div>
                    : undefined
                ]
                : undefined}

              {serversDiffer
                ? <div key='servers-differ'>
                  <XStack>
                    <XStack my='auto'>{alertTriangle()}</XStack>
                    <YStack my='auto' f={1}>
                      {/* <Heading whiteSpace='nowrap' maw={200} overflow='hidden' als='center'>
                          {primaryServer?.serverConfiguration?.serverInfo?.name}
                        </Heading> */}
                      <Heading size='$3' als='center' marginTop='$2' textAlign='center'>
                        Viewing/interacting with data on {primaryEntity.host}
                      </Heading>
                    </YStack>
                  </XStack>
                </div>
                : undefined}
              {browsingOnDiffers
                ? <div key='browsing-on-differs' style={{ width: '100%', display: 'flex' }}>
                  <XStack mx='auto' gap='$2'>
                    <XStack my='auto'>{alertTriangle()}</XStack>
                    <Heading size='$3' my='auto' als='center' textAlign='center'>
                      Browsing via {browsingOn}
                    </Heading>
                  </XStack>
                </div>
                : undefined}

              <div key='accounts-header'>
                <YStack gap="$2" mt='$2'>
                  <XStack mb='$2' ai='center' gap='$2'>
                    <Heading size='$5' f={1}>
                      Accounts
                    </Heading>


                    <Button onPress={() => dispatch(setSeparateAccountsByServer(!separateAccountsByServer))}
                      icon={ArrowDownUp}
                      transparent
                      circular
                      size='$2'
                      {...themedButtonBackground(
                        !separateAccountsByServer ? navColor : undefined, !separateAccountsByServer ? navTextColor : undefined)} />


                    <AuthSheetButton
                      server={currentServer}
                      button={onPress =>
                        <Button
                          size="$3"
                          icon={Plus}
                          disabled={currentServer === undefined && servers.length === 0}
                          {...themedButtonBackground(primaryColor, primaryTextColor)}
                          onPress={onPress}
                        >
                          Login/Sign Up
                        </Button>}
                    />
                  </XStack>
                </YStack>
              </div>

              {separateAccountsByServer
                ? [
                  accountsOnPrimaryServer.length === 0
                    ? <div key='no-accounts-on-server' style={{ width: '100%', display: 'flex' }}>
                      <Heading size="$2" mx='auto' paddingVertical='$6' o={0.5}>No accounts added on {primaryServer?.host}.</Heading>
                    </div>
                    : undefined,
                  ...accountsOnPrimaryServer.map((account) =>
                    <div key={accountID(account)} style={{ marginBottom: 8 }}>
                      <AccountCard
                        account={account}
                        onProfileOpen={() => setOpen(false)}
                        totalAccounts={accountsOnPrimaryServer.length} />
                    </div>),
                  ...accountsElsewhere.length > 0
                    ? [
                      <div key='acounts-elsewhere' style={{ width: '100%', display: 'flex' }}>
                        <Heading mr='$3' pr='$3' size='$3'>Accounts Elsewhere</Heading>
                      </div>,
                      ...accountsElsewhere.map((account) =>
                        <div key={accountID(account)} style={{ marginBottom: 8 }}>
                          <AccountCard key={accountID(account)}
                            account={account}
                            totalAccounts={accountsOnPrimaryServer.length} />
                        </div>)
                    ]
                    : []
                ]
                : [
                  displayedAccounts.length === 0
                    ? <Heading size="$2" alignSelf='center' paddingVertical='$6'>No accounts added.</Heading>
                    : undefined,
                  ...displayedAccounts.map((account) =>
                    <div key={accountID(account)} style={{ marginBottom: 8 }}>
                      <AccountCard key={accountID(account)}
                        account={account}
                        totalAccounts={displayedAccounts.length} />
                    </div>)
                ]}
            </FlipMove>
          </Sheet.ScrollView>
        </Sheet.Frame>
      </Sheet>
      : undefined}
  </>;
}
