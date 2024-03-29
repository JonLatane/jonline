import { Anchor, AnimatePresence, Button, ColorTokens, Dialog, Heading, Image, Input, Label, Paragraph, ScrollView, Sheet, SizeTokens, Switch, Theme, Tooltip, XStack, YStack, ZStack, reverseStandardAnimation, standardAnimation, standardHorizontalAnimation, useDebounce, useDebounceValue, useMedia } from '@jonline/ui';
import { AlertCircle, AlertTriangle, AtSign, ChevronDown, ChevronLeft, ChevronRight, ChevronUp, Info, LogIn, Plus, SeparatorHorizontal, SeparatorVertical, Server, User as UserIcon, X as XIcon } from '@tamagui/lucide-icons';
import { TamaguiMarkdown } from 'app/components';
import { DarkModeToggle } from 'app/components/dark_mode_toggle';
import { useAccount, useAppDispatch, useFederatedAccountOrServer, useLocalConfiguration } from 'app/hooks';
import { useMediaUrl } from 'app/hooks/use_media_url';
import { FederatedEntity, FederatedGroup, JonlineAccount, JonlineServer, RootState, accountID, actionSucceeded, clearAccountAlerts, clearServerAlerts, createAccount, login, selectAccount, selectAllAccounts, selectAllServers, selectServer, serverID, setBrowsingServers, setViewingRecommendedServers, store, upsertServer, useRootSelector, useServerTheme } from 'app/store';
import { themedButtonBackground } from 'app/utils';
import React, { useEffect, useState } from 'react';
import { Platform, TextInput } from 'react-native';
import { useLink } from 'solito/link';
import { v4 as uuidv4 } from 'uuid';
import { physicallyHostingServerId } from '../about/about_screen';
import { ServerNameAndLogo } from '../navigation/server_name_and_logo';
import { TutorialToggle } from '../navigation/tabs_tutorial';
import { SettingsSheet } from '../settings_sheet';
import AccountCard from './account_card';
import { LoginMethod } from './single_server_accounts_sheet';
import RecommendedServer from './recommended_server';
import ServerCard from './server_card';
import FlipMove from 'react-flip-move';

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
  const [addingAccount, setAddingAccount] = useState(false);
  const [position, setPosition] = useState(0);
  const [addingAccountPosition, setAddingAccountPosition] = useState(0);
  const [newServerHost, setNewServerHost] = useState('');
  const [newServerSecure, setNewServerSecure] = useState(true);
  const [newAccountUser, setNewAccountUser] = useState('');
  const [newAccountPass, setNewAccountPass] = useState('');
  const [loginMethod, setLoginMethod] = useState<LoginMethod | undefined>(undefined);

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
  const [addAccountServer, setAddAccountServer] = useState(currentServer);
  const { primaryColor: addAccountServerPrimaryColor, primaryTextColor: addAccountServerPrimaryTextColor } = useServerTheme(addAccountServer);
  useEffect(() => {
    if (addAccountServer) {
      document.getElementById('accounts-sheet-currently-adding-server')
        ?.scrollIntoView({ behavior: 'smooth', block: 'center' });
    }
  }, [addAccountServer]);
  const account = useAccount();
  const serversState = useRootSelector((state: RootState) => state.servers);
  const servers = useRootSelector((state: RootState) => selectAllServers(state.servers));
  const allowServerSelection = allowServerSelectionSetting || servers.length > 1;
  const serversLoading = serversState.status == 'loading';
  const newServerHostNotBlank = newServerHost != '';
  const newServerExists = servers.some(s => s.host == newServerHost);
  const newServerValid = newServerHostNotBlank && !newServerExists;
  const browsingOn = Platform.OS == 'web' ? window.location.hostname : undefined
  const effectiveServer = primaryAccountOrServer.server ?? currentServer;

  const usernameRef = React.useRef() as React.MutableRefObject<TextInput>;
  const passwordRef = React.useRef() as React.MutableRefObject<TextInput>;
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
  const [authError, setAuthError] = useState(undefined as string | undefined);

  async function onAccountAdded() {
    setAddingAccount(false);
    setOpen(false);

    setTimeout(() => {
      dispatch(clearAccountAlerts());

      // setTimeout(() => {
      setNewAccountUser('');
      setNewAccountPass('');
      setForceDisableAccountButtons(false);
      setLoginMethod(undefined);
      // }, 600);
    }, 2000);

    const accountEntities = store.getState().accounts.entities;
    const account = store.getState().accounts.ids.map((id) => accountEntities[id])
      .find(a => a && a.user.username === newAccountUser && a.server.host === currentServer?.host);

    if (account) {
      // if (onAccountSelected) {
      //   onAccountSelected(account);
      // }
    } else {
      console.warn("Account not found after adding it. This is a bug.");
    }
  }

  const skipSelection = addAccountServer?.host !== currentServer?.host;
  function loginToServer() {
    dispatch(clearAccountAlerts());
    dispatch(login({
      ...addAccountServer!,
      userId: undefined,
      username: newAccountUser,
      password: newAccountPass,
      skipSelection
    })).then(action => {
      if (actionSucceeded(action)) {
        onAccountAdded();
      } else {
        setForceDisableAccountButtons(false);
      }
    });
  }
  function createServerAccount() {
    dispatch(clearAccountAlerts());
    dispatch(createAccount({
      ...addAccountServer!,
      username: newAccountUser,
      password: newAccountPass,
      skipSelection
    })).then(action => {
      if (actionSucceeded(action)) {
        onAccountAdded();
      } else {
        setForceDisableAccountButtons(false);
      }
    });
  }

  const accountsLoading = accountsState.status == 'loading';
  const newAccountValid = newAccountUser.length > 0 && newAccountPass.length >= 8;
  const [forceDisableAccountButtons, setForceDisableAccountButtons] = useState(false);
  const disableLoginMethodButtons = newAccountUser == '';
  const disableAccountInputs = accountsLoading || forceDisableAccountButtons;
  const disableAccountButtons = accountsLoading || !newAccountValid || forceDisableAccountButtons;

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
      onPress={() => setOpen((x) => !x)}
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
        zIndex={100000}
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
                  <Server size='$1' />
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

                    <DarkModeToggle />

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
                  <XStack mb='$2' ai='center'>
                    <Heading size='$5' f={1}>
                      Accounts
                    </Heading>
                    <Button
                      size="$3"
                      icon={Plus}
                      disabled={currentServer === undefined && servers.length === 0}
                      {...themedButtonBackground(primaryColor, primaryTextColor)}
                      onPress={() => {
                        setAddingAccount(true);
                        setTimeout(() => usernameRef.current.focus(), 100);
                      }}
                    >
                      Login/Sign Up
                    </Button>
                    <Sheet
                      modal
                      open={addingAccount}
                      onOpenChange={setAddingAccount}
                      // snapPoints={[80]}
                      snapPoints={[81]} dismissOnSnapToBottom
                      position={addingAccountPosition}
                      onPositionChange={setAddingAccountPosition}
                    // dismissOnSnapToBottom
                    >
                      <Sheet.Overlay />
                      <Sheet.Frame padding="$5">
                        <Sheet.Handle />
                        {/* <Button
                          alignSelf='center'
                          size="$3"
                          circular
                          icon={ChevronDown}
                          onPress={() => {
                            setAddingAccount(false)
                          }}
                        /> */}
                        <XStack ai='center'
                          pl={mediaQuery.gtXs ? '$2' : 0}
                          pr={mediaQuery.gtXs ? '$4' : '$1'}>
                          <ScrollView horizontal f={1}>
                            <FlipMove style={{ display: 'flex', flexDirection: 'row', alignItems: 'center' }}>
                              {addAccountServer
                                ? <div id='accounts-sheet-currently-adding-server'
                                  key={`serverCard-${serverID(addAccountServer)}`}
                                  style={{ margin: 2 }}>
                                  <ServerNameAndLogo server={addAccountServer} />
                                </div>
                                : undefined}
                              {addAccountServer && servers.length > 1
                                ? <div key='separator' style={{ margin: 2 }}>
                                  <SeparatorVertical size='$1' />
                                </div>
                                : undefined}
                              {servers.filter(s => s.host != addAccountServer?.host)
                                .map((server, index) =>
                                  <div key={`serverCard-${serverID(server)}`} style={{ margin: 2 }}>
                                    <Button onPress={() => setAddAccountServer(server)}>
                                      <ServerNameAndLogo server={server} />
                                    </Button>
                                  </div>
                                )}
                            </FlipMove>
                          </ScrollView>
                          <AnimatePresence>
                            {addAccountServer?.host !== currentServer?.host
                              ? <XStack
                                animation='standard' {...standardHorizontalAnimation}
                                o={0.5}
                                ai='center' >
                                <Paragraph ml='auto' size='$1' > via</Paragraph>
                                <XStack>
                                  <ServerNameAndLogo server={currentServer} />
                                </XStack>
                              </XStack>
                              : undefined}
                          </AnimatePresence>
                        </XStack>
                        <Heading size="$9" mt='$3'>
                          {loginMethod === 'login' ? 'Login'
                            : loginMethod === 'create_account' ? 'Sign Up'
                              : 'Add Account'}
                        </Heading>
                        <Heading size="$4">{addAccountServer?.host}/</Heading>
                        <Sheet.ScrollView>
                          <YStack gap="$2"
                            maw={600} w='100%' als='center'
                            p='$2'
                            pt='$3'
                          >
                            {/* <Heading size="$10">Add Account</Heading> */}
                            <Input textContentType="username" autoCorrect={false} placeholder="Username" keyboardType='twitter'
                              editable={!disableAccountInputs} opacity={disableAccountInputs || newAccountUser.length === 0 ? 0.5 : 1}
                              autoCapitalize='none'
                              value={newAccountUser}
                              ref={usernameRef}
                              // autoFocus={!loginMethod}
                              onKeyPress={(e) => {
                                if (e.nativeEvent.key === 'Enter') {
                                  if (!loginMethod) {
                                    setLoginMethod(LoginMethod.Login);
                                    setTimeout(() => passwordRef.current.focus(), 100);
                                  } else {
                                    passwordRef.current.focus();
                                  }
                                }
                              }}
                              onChange={(data) => { setNewAccountUser(data.nativeEvent.text) }} />
                            {loginMethod
                              ? <XStack w='100%' animation="quick" {...standardAnimation}>
                                <Input secureTextEntry w='100%'
                                  ref={passwordRef}
                                  // autoFocus
                                  id='accounts-sheet-password-input'
                                  textContentType={//loginMethod === LoginMethod.Login
                                    // ?
                                    "newPassword"
                                    // : "password"
                                  }
                                  placeholder="Password"
                                  editable={!disableAccountInputs} opacity={disableAccountInputs || newAccountPass.length === 0 ? 0.5 : 1}
                                  onKeyPress={(e) => {
                                    if (e.nativeEvent.key === 'Enter') {
                                      if (loginMethod == LoginMethod.Login) {
                                        loginToServer();
                                      } else {
                                        createServerAccount();
                                      }
                                    }
                                  }}
                                  value={newAccountPass}
                                  onChange={(data) => { setNewAccountPass(data.nativeEvent.text) }} />
                              </XStack>
                              : undefined}
                            {loginMethod && newAccountPass.length < 8 ? <Heading size="$2" color="red" alignSelf='center' ta='center'>Password must be at least 8 characters.</Heading> : undefined}
                            {loginMethod === LoginMethod.CreateAccount
                              ? <>
                                <Heading size="$2" alignSelf='center' ta='center'>License</Heading>
                                <TamaguiMarkdown text={`
                ${addAccountServer?.serverConfiguration?.serverInfo?.name ?? 'This server'} is powered by [Jonline](https://github.com/JonLatane/jonline), which is
                released under the AGPL. As a user, you have a fundamental right to view the source code of this software. If you suspect that the
                operator of this server is not using the official Jonline software, you can contact the [Free Software Foundation](https://www.fsf.org/)
                to evaluate support options.
                            `} />
                                {(addAccountServer?.serverConfiguration?.serverInfo?.privacyPolicy?.length ?? 0) > 0
                                  ? <>
                                    <Heading size="$2" alignSelf='center' ta='center'>Privacy Policy</Heading>
                                    <TamaguiMarkdown text={addAccountServer?.serverConfiguration?.serverInfo?.privacyPolicy} />
                                  </> : undefined}
                                {(addAccountServer?.serverConfiguration?.serverInfo?.mediaPolicy?.length ?? 0) > 0
                                  ? <>
                                    <Heading size="$2" alignSelf='center' ta='center'>Media Policy</Heading>
                                    <TamaguiMarkdown text={addAccountServer?.serverConfiguration?.serverInfo?.mediaPolicy} />
                                  </> : undefined}
                              </>
                              : undefined}
                            {accountsState.errorMessage ? <Heading size="$2" color="red" alignSelf='center' ta='center'>{accountsState.errorMessage}</Heading> : undefined}
                            {accountsState.successMessage ? <Heading size="$2" color="green" alignSelf='center' ta='center'>{accountsState.successMessage}</Heading> : undefined}
                            {loginMethod
                              ? <XStack>
                                <Button marginRight='$1'
                                  onPress={() => { setLoginMethod(undefined); setNewAccountPass(''); }} icon={ChevronLeft}
                                  disabled={disableAccountInputs} opacity={disableAccountInputs ? 0.5 : 1}>
                                  Back
                                </Button>
                                <Button flex={1}
                                  {...themedButtonBackground(addAccountServerPrimaryColor, addAccountServerPrimaryTextColor)}
                                  // backgroundColor={primaryColor}
                                  //  hoverStyle={{ backgroundColor: primaryColor }}
                                  //  color={primaryTextColor}
                                  onPress={() => {
                                    if (loginMethod == LoginMethod.Login) {
                                      loginToServer();
                                    } else {
                                      createServerAccount();
                                    }
                                  }}
                                  disabled={disableAccountButtons} opacity={disableAccountButtons ? 0.5 : 1}>
                                  {loginMethod == LoginMethod.Login ? 'Login' : 'Sign Up'}
                                </Button>
                              </XStack>
                              : <XStack mt='$3'>
                                <Button flex={2}
                                  marginRight='$1'
                                  onPress={() => {
                                    setLoginMethod(LoginMethod.CreateAccount);
                                    setTimeout(() => passwordRef.current.focus(), 100);
                                  }}
                                  disabled={disableLoginMethodButtons} opacity={disableLoginMethodButtons ? 0.5 : 1}>
                                  Sign Up
                                </Button>
                                <Button flex={1}
                                  {...themedButtonBackground(addAccountServerPrimaryColor, addAccountServerPrimaryTextColor)}
                                  // backgroundColor={primaryColor} hoverStyle={{ backgroundColor: primaryColor }} color={primaryTextColor}
                                  onPress={() => {
                                    setLoginMethod(LoginMethod.Login);
                                    setTimeout(() => passwordRef.current.focus(), 100);
                                  }}
                                  disabled={disableLoginMethodButtons} opacity={disableLoginMethodButtons ? 0.5 : 1}>
                                  Login
                                </Button>
                              </XStack>}
                          </YStack>
                        </Sheet.ScrollView>
                      </Sheet.Frame>
                    </Sheet>
                  </XStack>
                </YStack>
              </div>

              {separateAccountsByServer
                ? [
                  accountsOnPrimaryServer.length === 0
                    ? <div key='no-accounts-on-server' style={{width: '100%', display: 'flex'}}>
                      <Heading size="$2" mx='auto' paddingVertical='$6' o={0.5}>No accounts added on {primaryServer?.host}.</Heading>
                    </div>
                    : undefined,
                  accountsOnPrimaryServer.map((account) =>
                    <div key={accountID(account)} style={{ marginBottom: 8 }}>
                      <AccountCard
                        account={account}
                        onProfileOpen={() => setOpen(false)}
                        totalAccounts={accountsOnPrimaryServer.length} />
                    </div>),
                  accountsElsewhere.length > 0
                    ? [
                      <div key='acounts-elsewhere' style={{width: '100%', display: 'flex'}}>
                        <Heading mr='$3' pr='$3' size='$3'>Accounts Elsewhere</Heading>
                      </div>,
                      accountsElsewhere.map((account) =>
                        <div key={accountID(account)} style={{ marginBottom: 8 }}>
                          <AccountCard key={accountID(account)}
                            account={account}
                            totalAccounts={accountsOnPrimaryServer.length} />
                        </div>)
                    ]
                    : undefined
                ]
                : [
                  displayedAccounts.length === 0
                    ? <Heading size="$2" alignSelf='center' paddingVertical='$6'>No accounts added.</Heading>
                    : undefined,
                  displayedAccounts.map((account) =>
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
