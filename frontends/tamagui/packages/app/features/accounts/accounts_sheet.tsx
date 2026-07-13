import { Button, ColorTokens, Heading, Image, Input, Label, Paragraph, ScrollView, Sheet, SizeTokens, Switch, Theme, Tooltip, XStack, YStack, ZStack, useDebounceValue, useMedia } from '@jonline/ui';
import { AlertCircle, AlertTriangle, ArrowDownUp, AtSign, ChevronLeft, ChevronRight, Info, Plus, Router, SeparatorHorizontal } from '@tamagui/lucide-icons';
import { DarkModeToggle } from 'app/components/dark_mode_toggle';
import { useAppDispatch, useCurrentAccount, useFederatedAccountOrServer, useLocalConfiguration, usePinnedAccountsAndServers } from 'app/hooks';
import { useMediaUrl } from 'app/hooks/use_media_url';
import { FederatedEntity, FederatedGroup, RootState, accountID, clearServerAlerts, selectAllAccounts, selectAllServers, serverID, setBrowsingServers, setHasOpenedAccounts, setSeparateAccountsByServer, setViewingRecommendedServers, upsertServer, useRootSelector, useServerTheme } from 'app/store';
import { themedButtonBackground } from 'app/utils';
import React, { useCallback, useEffect, useState } from 'react';
import { Platform } from 'react-native';
import { useLink } from 'solito/link';
import { v4 as uuidv4 } from 'uuid';
import { physicallyHostingServerId } from '../about/about_screen';
import { ServerNameAndLogo } from '../navigation/server_name_and_logo';
import { AutoAnimatedList } from '../post';
import { SettingsSheetButton } from '../settings/settings_sheet_button';
import AccountCard from './account_card';
import { AuthSheetButton } from './auth_sheet_button';
import RecommendedServer from './recommended_server';
import ServerCard from './server_card';
import { useAccountsSheetContext } from 'app/contexts/accounts_sheet_context';

export type AccountsSheetProps = {
  // Indicate to the AccountsSheet that we're
  // viewing server configuration for a server,
  // and should only show accounts for that server.
  // onlyShowServer?: JonlineServer;
  selectedGroup?: FederatedGroup;
  primaryEntity?: FederatedEntity<any>;
}
const doesPlatformPreferDarkMode = () =>
  window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches;

export function AccountsSheet({ selectedGroup, primaryEntity }: AccountsSheetProps) {
  const mediaQuery = useMedia();
  // const [open, setOpen] = useState(false);
  const [open, setOpen] = useAccountsSheetContext().open;
  const primaryAccountOrServer = useFederatedAccountOrServer(primaryEntity);
  const { allowServerSelection: allowServerSelectionSetting, hasOpenedAccounts, separateAccountsByServer, browsingServers, viewingRecommendedServers } = useLocalConfiguration();
  const [addingServer, setAddingServer] = useState(false);
  const [position, setPosition] = useState(0);
  const [newServerHost, setNewServerHost] = useState('');
  const [newServerSecure, setNewServerSecure] = useState(true);

  // const openDebounced300 = useDebounceValue(open, 300);
  // const openDebounced3000 = useDebounceValue(open, 3000);
  // useEffect(() => {
  //   if (openDebounced && !hasOpenedAccounts) {
  //     requestAnimationFrame(() => dispatch(setHasOpenedAccounts(true)));
  //   }
  // }, [openDebounced, hasOpenedAccounts]);

  useEffect(() => {
    if (!hasOpenedAccounts && open) {
      requestAnimationFrame(() => dispatch(setHasOpenedAccounts(true)));
    }
  }, [open]);



  // useEffect(() => {
  //   if (!openDebounced) {
  //     setHasOpened(false);
  //   }
  // }, [openDebounced])
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
  const addServer = useCallback(() => {
    console.log(`Connecting to server ${newServerHost}`)
    dispatch(clearServerAlerts());
    dispatch(upsertServer({
      host: newServerHost,
      secure: newServerSecure,
    }));
  }, [newServerHost, newServerSecure]);

  const accountsState = useRootSelector((state: RootState) => state.accounts);
  const accounts = useRootSelector((state: RootState) => selectAllAccounts(state.accounts));
  const primaryServer = primaryEntity?.serverHost || currentServer;
  const accountsOnPrimaryServer = primaryServer ? accounts.filter(a => serverID(a.server) == serverID(primaryServer!)) : [];
  const accountsElsewhere = accounts.filter(a => !accountsOnPrimaryServer.includes(a));
  const displayedAccounts = accounts;
  const successMessageDebounce = useDebounceValue(serversState.successMessage, 3000);
  useEffect(() => {
    if (successMessageDebounce) {
      clearServerAlerts();
    }
  }, [successMessageDebounce]);
  const errorMessageDebounce = useDebounceValue(serversState.errorMessage, 10000);
  useEffect(() => {
    if (errorMessageDebounce) {
      clearServerAlerts();
    }
  }, [errorMessageDebounce]);


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
  const alertTriangle = useCallback(({ color }: { color?: string | ColorTokens } = {}) => <Tooltip>
    <Tooltip.Trigger>
      <AlertTriangle color={color} />
    </Tooltip.Trigger>
    <Tooltip.Content>
      <Paragraph size='$1'>You are seeing data as though you were on {currentServer?.host}, although you're on {browsingOn}.</Paragraph>
    </Tooltip.Content>
  </Tooltip>, [currentServer, browsingOn]);

  const renderContent = true;//openDebounced300 || openDebounced3000;

  // const pinnedServers = usePinnedAccountsAndServers().map(aos =>
  //   `${aos.server ? serverID(aos.server) : null}-(${aos.account ? accountID(aos.account) : null})`)
  //   .sort().join(',');

  // useEffect(() => {
  //   if (open) {
  //     requestAnimationFrame(() => setOpen(false));
  //   }
  // }, [pinnedServers]);

  return <Sheet
    modal
    open={open}
    onOpenChange={setOpen}
    // snapPoints={[80]}
    snapPoints={[
      // 50, 
      91
    ]}
    // zIndex={500000}
    position={position}
    onPositionChange={setPosition}
    dismissOnSnapToBottom

  >
    <Sheet.Overlay />
    <Sheet.Frame >
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
        <AutoAnimatedList>
          <Heading size='$7' mr='$2' key='accounts'>Accounts</Heading>
          {browsingServers
            ? <Heading size='$1' key='and-servers' mt={-5} whiteSpace='nowrap'>& Servers</Heading>
            : undefined}
        </AutoAnimatedList>
        <XStack f={1} />
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
        <SettingsSheetButton size='$3' />
      </XStack>
      <Sheet.ScrollView px="$4" pb='$4' pt='$1' f={1} maw='100%'>
        <AutoAnimatedList style={{ maxWidth: 800, width: '100%', alignSelf: 'center' }} gap='$1'>
          {/* <YStack maxWidth={800} gap='$2' width='100%' alignSelf='center'> */}
          {renderContent ? <>
            {browsingServers
              ? //<div key='server-header'>
              <XStack key='server-header' ai='center' w='100%'>
                {browsingServers
                  ? <Heading size='$5' marginRight='$2'>Servers</Heading>
                  : undefined}

                {browsingServers
                  ? addingServer
                    ? <Button
                      size="$3"
                      icon={ChevronLeft}
                      marginLeft='auto'
                      // circular
                      onPress={() => setAddingServer((x) => !x)}
                    >
                      Done
                    </Button>
                    : <Button
                      size="$3"
                      icon={Plus}
                      marginLeft='auto'
                      // circular
                      onPress={() => setAddingServer((x) => !x)}
                    >
                      Add
                    </Button>
                  : undefined}
              </XStack>
              //</div>
              : //<div key='primary-server-logo'>
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
              //</div>
            }
            {addingServer
              ? //<div key='add-server'>
              <XStack key='add-server' gap="$2" mt='$2' w='100%' maxWidth={600} width='100%' ai='center' alignSelf='center'>
                {/* <Heading size="$10" f={1}>Add Server</Heading> */}
                {/* <YStack> */}
                <Input f={1} textContentType="URL" keyboardType='url' autoCorrect={false} autoCapitalize='none' placeholder="Server Hostname"
                  editable={!serversLoading}
                  opacity={serversLoading || newServerHost.length === 0 ? 0.5 : 1}
                  value={newServerHost}
                  onChange={(data) => setNewServerHost(data.nativeEvent.text)} />
                {/* </YStack> */}
                {/* <XStack> */}
                {disableSecureSelection || true
                  ? undefined
                  : <YStack mt='$1' mx='auto' opacity={disableSecureSelection ? 0.5 : 1}>
                    <Switch size="$1" style={{ marginLeft: 'auto', marginRight: 'auto' }} id={`newServerSecure-${secureLabelUuid}`} aria-label='Secure'
                      defaultChecked
                      onCheckedChange={(checked) => setNewServerSecure(checked)}
                      disabled={disableSecureSelection} >
                      <Switch.Thumb animation='standard' disabled={disableSecureSelection} />
                    </Switch>

                    <Label style={{ flex: 1, alignContent: 'center', marginLeft: 'auto', marginRight: 'auto' }} htmlFor={`newServerSecure-${secureLabelUuid}`} >
                      <Heading size="$2">Secure</Heading>
                    </Label>
                  </YStack>}
                <Button backgroundColor={primaryColor} color={primaryTextColor}
                  onPress={addServer} disabled={serversLoading || !newServerValid} opacity={serversLoading || !newServerValid ? 0.5 : 1}>
                  Add
                </Button>
                {/* </XStack> */}
                {/* {serversState.errorMessage ? <Heading size="$2" color="red" alignSelf='center'>{serversState.errorMessage}</Heading> : undefined}
                    {serversState.successMessage ? <Heading size="$2" color="green" alignSelf='center'>{serversState.successMessage}</Heading> : undefined} */}
              </XStack>
              // </div>
              : undefined}
            {(newServerHostNotBlank && newServerExists && !serversState.successMessage)
              ? <Heading size="$2" maw='100%' color="red" alignSelf='center'>Server already exists</Heading>
              : undefined}

            {addingServer && serversState.errorMessage
              ? <Heading size="$2" maw='100%' color="red" alignSelf='center'>{serversState.errorMessage}</Heading>
              : undefined}

            {addingServer && serversState.successMessage
              ? <Heading size="$2" maw='100%' color="green" alignSelf='center'>{serversState.successMessage}</Heading>
              : undefined}

            {servers.length === 0
              ? <div key='no-servers'>
                <Heading size="$2" maw='100%' alignSelf='center' paddingVertical='$6'>No servers added.</Heading>
              </div>
              : undefined}

            {/* <div key='servers'> */}
            <ScrollView key='servers' horizontal maw='100%'>
              <XStack gap='$3'>
                <AutoAnimatedList direction='horizontal' style={{ width: '100%' }}>
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
                </AutoAnimatedList>
              </XStack>
            </ScrollView>
            {/* </div> */}
            {recommendedServerHosts.length > 0
              ? <>
                {/* <div key='recommended-servers-link'> */}
                <Button key='recommended-servers-link' mt='$2' size='$2' mx='auto' onPress={() => dispatch(setViewingRecommendedServers(!viewingRecommendedServers))}>
                  <XStack>
                    <Heading size='$1'>{browsingServers ? 'All ' : ''}Recommended Servers{recommendedServerHosts.length > 0 ? ` (${recommendedServerHosts.length})` : ''}</Heading>
                    <XStack animation='standard' rotate={viewingRecommendedServers ? '90deg' : '0deg'}>
                      <ChevronRight size='$1' />
                    </XStack>
                  </XStack>
                </Button>
                {/* </div> */}
                {viewingRecommendedServers
                  ?
                  // <div key='recommended-servers'>
                  <XStack key='recommended-servers' mt='$2' mb='$2' w='100%'>
                    <ScrollView f={1} horizontal>
                      <AutoAnimatedList direction='horizontal' gap='$1'>
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
                      </AutoAnimatedList>
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
                  // </div>
                  : undefined}
              </>
              : undefined}
            {serversDiffer
              ? //<div key='servers-differ'>
              <XStack key='servers-differ' maw='100%'>
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
              //</div>
              : undefined}
            {browsingOnDiffers
              ? //<div key='browsing-on-differs' style={{ width: '100%', display: 'flex' }}>
              <XStack key='browsing-on-differs' maw='100%' mx='auto' gap='$2'>
                <XStack my='auto'>{alertTriangle()}</XStack>
                <Heading size='$3' my='auto' als='center' textAlign='center'>
                  Browsing via {browsingOn}
                </Heading>
              </XStack>
              //</div>
              : undefined}

            {/* <div key='accounts-header'> */}
            <YStack key='accounts-header' gap="$2" mt='$2' w='100%'>
              <XStack mb='$2' ai='center' gap='$2'>
                <Heading size='$5' f={1}>
                  Accounts
                </Heading>

                {accounts.length > 1
                  ? <Button onPress={() => dispatch(setSeparateAccountsByServer(!separateAccountsByServer))}
                    icon={ArrowDownUp}
                    transparent
                    circular
                    size='$2'
                    {...themedButtonBackground(
                      !separateAccountsByServer ? navColor : undefined, !separateAccountsByServer ? navTextColor : undefined)} />
                  : undefined}

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
            {separateAccountsByServer
              ? <>
                {accountsOnPrimaryServer.length === 0
                  ? <Heading key='no-accounts-on-server' w='100%' size="$2" mx='auto' paddingVertical='$6' o={0.5}>
                    No accounts added on {primaryServer?.host}.
                  </Heading>
                  : undefined}
                {...accountsOnPrimaryServer.map((account) =>
                  <XStack key={`account-${accountID(account)}`} w='100%'>
                    <AccountCard key={accountID(account)}
                      account={account}
                      onProfileOpen={() => setOpen(false)}
                      totalAccounts={accountsOnPrimaryServer.length} />
                  </XStack>
                )
                }
                {accountsElsewhere.length > 0
                  ? <>
                    <Heading key='acounts-elsewhere' maw='100%' mr='$3' pr='$3' size='$3' whiteSpace='nowrap'>Accounts Elsewhere</Heading>
                    {
                      ...accountsElsewhere.map((account) =>
                        <XStack key={`account-${accountID(account)}`} w='100%'>
                          <AccountCard key={accountID(account)}
                            account={account}
                            totalAccounts={accountsOnPrimaryServer.length} />
                        </XStack>
                      )
                    }
                  </>
                  : undefined}
              </>
              : <>
                {displayedAccounts.length === 0
                  ? <Heading key='no-accounts-added' maw='100%' size="$2" alignSelf='center' paddingVertical='$6'>No accounts added.</Heading>
                  : undefined}
                {...displayedAccounts.map((account) =>
                  <XStack key={`account-${accountID(account)}`} w='100%'>
                    <AccountCard key={`account-${accountID(account)}`}
                      account={account}
                      totalAccounts={displayedAccounts.length} />
                  </XStack>
                )}
              </>}
            {/* </AutoAnimatedList> */}
          </> : undefined}
        </AutoAnimatedList>
      </Sheet.ScrollView>
    </Sheet.Frame>
  </Sheet >;
}
