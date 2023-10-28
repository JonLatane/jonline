import { Anchor, Button, Heading, Image, Input, Label, ScrollView, Sheet, SizeTokens, Switch, XStack, YStack, reverseStandardAnimation, standardAnimation, useMedia } from '@jonline/ui';
import { ChevronDown, ChevronLeft, Info, LogIn, Menu, Plus, RefreshCw, Server, User as UserIcon, X as XIcon } from '@tamagui/lucide-icons';
import { useMediaUrl } from 'app/hooks/use_media_url';
import { JonlineServer, RootState, accountId, clearAccountAlerts, clearServerAlerts, createAccount, login, resetCredentialedData, selectAllAccounts, selectAllServers, serverID, upsertServer, useLoadingCredentialedData, useServerTheme, useTypedDispatch, useTypedSelector } from 'app/store';
import React, { useEffect, useState } from 'react';
import { Platform } from 'react-native';
import { useLink } from 'solito/link';
import { v4 as uuidv4 } from 'uuid';
import { physicallyHostingServerId } from '../about/about_screen';
import { TamaguiMarkdown } from '../post/tamagui_markdown';
import { SettingsSheet } from '../settings_sheet';
import AccountCard from './account_card';
import { LoginMethod } from './add_account_sheet';
import ServerCard from './server_card';

export type AccountsSheetProps = {
  size?: SizeTokens;
  circular?: boolean;
  onlyShowServer?: JonlineServer;
}

export function AccountsSheet({ size = '$5', circular = false, onlyShowServer }: AccountsSheetProps) {
  const mediaQuery = useMedia();
  const [open, setOpen] = useState(false);
  const [browsingServers, setBrowsingServers] = useState(false);
  const [addingServer, setAddingServer] = useState(false);
  const [addingAccount, setAddingAccount] = useState(false);
  const [position, setPosition] = useState(0);
  const [newServerHost, setNewServerHost] = useState('');
  const [newServerSecure, setNewServerSecure] = useState(true);
  const [newAccountUser, setNewAccountUser] = useState('');
  const [newAccountPass, setNewAccountPass] = useState('');
  const [loginMethod, setLoginMethod] = useState<LoginMethod | undefined>(undefined);

  const dispatch = useTypedDispatch();
  const app = useTypedSelector((state: RootState) => state.app);
  const { server, primaryColor, primaryTextColor, navColor, navTextColor, warningAnchorColor } = useServerTheme();
  const serversState = useTypedSelector((state: RootState) => state.servers);
  const servers = useTypedSelector((state: RootState) => selectAllServers(state.servers));
  const serversLoading = serversState.status == 'loading';
  const newServerHostNotBlank = newServerHost != '';
  const newServerExists = servers.some(s => s.host == newServerHost);
  const newServerValid = newServerHostNotBlank && !newServerExists;
  const browsingOn = Platform.OS == 'web' ? window.location.hostname : undefined
  const effectiveServer = onlyShowServer ?? server;
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

  const accountsState = useTypedSelector((state: RootState) => state.accounts);
  const accounts = useTypedSelector((state: RootState) => selectAllAccounts(state.accounts));
  const primaryServer = onlyShowServer || serversState.server;
  const accountsOnPrimaryServer = primaryServer ? accounts.filter(a => serverID(a.server) == serverID(primaryServer!)) : [];
  const accountsElsewhere = accounts.filter(a => !accountsOnPrimaryServer.includes(a));
  function loginToServer() {
    dispatch(clearAccountAlerts());
    dispatch(login({
      ...primaryServer!,
      username: newAccountUser,
      password: newAccountPass,
    }));
  }
  function createServerAccount() {
    dispatch(clearAccountAlerts());
    dispatch(createAccount({
      ...primaryServer!,
      username: newAccountUser,
      password: newAccountPass,
    }));
  }

  const accountsLoading = accountsState.status == 'loading';
  const newAccountValid = newAccountUser.length > 0 && newAccountPass.length >= 8;
  const [forceDisableAccountButtons, setForceDisableAccountButtons] = useState(false);
  const disableLoginMethodButtons = newAccountUser == '';
  const disableAccountInputs = accountsLoading || forceDisableAccountButtons;
  const disableAccountButtons = accountsLoading || !newAccountValid || forceDisableAccountButtons;
  const isLoadingCredentialedData = useLoadingCredentialedData();
  useEffect(() => {
    if (accountsLoading && !forceDisableAccountButtons) {
      setForceDisableAccountButtons(true);
    }
  });

  useEffect(() => {
    if (serversState.successMessage) {
      setTimeout(() => {
        setNewServerHost('');
        setNewServerSecure(true);
        dispatch(clearServerAlerts());
        setAddingServer(false);
      }, 1000);
    }
  }, [serversState.successMessage]);

  useEffect(() => {
    if (accountsState.successMessage) {
      setTimeout(() => {
        setAddingAccount(false);
        setTimeout(() => {
          dispatch(clearAccountAlerts());
          setNewAccountUser('');
          setNewAccountPass('');
          setForceDisableAccountButtons(false);
          setLoginMethod(undefined);
        }, 1000);
      }, 1500);
    } else if (accountsState.errorMessage && forceDisableAccountButtons) {
      setForceDisableAccountButtons(false);
    }
  }, [accountsState.successMessage, accountsState.errorMessage, forceDisableAccountButtons]);

  useEffect(() => {
    if (!app.allowServerSelection && browsingServers) {
      setBrowsingServers(false);
    }
  }, [app.allowServerSelection, browsingServers]);
  const serversDiffer = onlyShowServer && serversState.server && serverID(onlyShowServer) != serverID(serversState.server);
  const serverId = serversState.server ? serverID(serversState.server) : undefined;
  // debugger;
  const currentServerInfoLink = useLink({
    href: serverId === physicallyHostingServerId() ? '/about' : `/server/${serverId!}`
  });
  // bc react native may render multiple accounts sheets at a time
  const secureLabelUuid = uuidv4();
  const secureRequired = Platform.OS == 'web' && window.location.protocol == 'https';
  const disableSecureSelection = serversLoading || secureRequired;

  const account = accountsState.account;
  const avatarUrl = useMediaUrl(account?.user.avatar?.id, { account, server: account?.server });

  const userIcon = account ? UserIcon : LogIn;
  return (
    <>
      {circular && avatarUrl && avatarUrl != ''
        ? <Anchor
          my='auto'
          mr={-10}
          ml='$1'
          onPress={() => setOpen((x) => !x)}>
          <XStack w={48} h={48}
            ml={-5}
            mr={mediaQuery.gtXs || true ? '$3' : '$2'}>
            <Image
              pos="absolute"
              width={48}
              // opacity={0.25}
              height={48}
              borderRadius={24}
              // mr={-5}
              resizeMode="cover"
              als="flex-start"
              source={{ uri: avatarUrl, width: 48, height: 48 }}
            // blurRadius={1.5}
            // borderRadius={5}
            />
          </XStack>
        </Anchor>
        : <Button
          my='auto'
          size={size}
          icon={
            circular ? userIcon : open ? XIcon : avatarUrl && avatarUrl != '' ? undefined : ChevronDown
          }
          circular={circular}
          color={serversDiffer || browsingOnDiffers ? warningAnchorColor : undefined}
          onPress={() => setOpen((x) => !x)}

        >
          {circular ? undefined :
            <>
              {(avatarUrl && avatarUrl != '') ?

                <XStack w={26} h={26}
                  ml={-5}
                  mr={mediaQuery.gtXs || true ? '$3' : '$2'}>
                  <Image
                    pos="absolute"
                    width={26}
                    // opacity={0.25}
                    height={26}
                    borderRadius={13}
                    resizeMode="cover"
                    als="flex-start"
                    source={{ uri: avatarUrl, width: 26, height: 26 }}
                  // blurRadius={1.5}
                  // borderRadius={5}
                  />
                </XStack>
                : undefined}
              <YStack>
                {serversState.server ? <Heading transform={[{ translateY: serversState.server ? 2 : 0 }]} size='$1'>{serversState.server.host}/</Heading> : undefined}
                {accountsState.account ? <Heading transform={[{ translateY: -2 }]} size='$7' space='$0'>{accountsState.account.user.username}</Heading> : undefined}
              </YStack>
            </>
          }
        </Button>
      }
      <Sheet
        modal
        open={open}
        onOpenChange={setOpen}
        // snapPoints={[80]}
        snapPoints={[92]}
        position={position}
        onPositionChange={setPosition}
        dismissOnSnapToBottom
      >
        <Sheet.Overlay />
        <Sheet.Frame>
          <Sheet.Handle />
          <XStack space='$4' paddingHorizontal='$3'>

            <Button size='$3' icon={RefreshCw} circular
              // disabled={isLoadingCredentialedData} opacity={isLoadingCredentialedData ? 0.5 : 1}
              onPress={resetCredentialedData} />
            <XStack f={1} />
            <Button
              alignSelf='center'
              size="$5"
              circular
              icon={ChevronDown}
              onPress={() => setOpen(false)} />
            <XStack f={1} />
            <SettingsSheet size='$3' />

          </XStack>
          <Sheet.ScrollView p="$4" space>
            <YStack maxWidth={800} width='100%' alignSelf='center'>
              <XStack>
                {app.allowServerSelection && (browsingServers || mediaQuery.gtXs)
                  ? <Heading marginRight='$2'>Server{browsingServers ? 's' : ':'}</Heading>
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
                    <YStack space="$2" maxWidth={600} width='100%' alignSelf='center'>
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
                {app.allowServerSelection
                  ? <Button
                    size="$3"
                    ml={browsingServers ? '$2' : 'auto'}
                    icon={browsingServers ? ChevronLeft : Server}
                    // circular
                    opacity={onlyShowServer != undefined ? 0.5 : 1}
                    disabled={onlyShowServer != undefined}
                    // maw={100}
                    onPress={() => setBrowsingServers((x) => !x)} >
                    {browsingServers ? 'Back' : `More Servers (${servers.length})`}
                  </Button>
                  : undefined}
              </XStack>
              {onlyShowServer && serversDiffer ? undefined : <YStack space="$2">
                <XStack>

                  <XStack f={1} />

                  {!browsingServers ?
                    <XStack animation="quick" mt={app.allowServerSelection ? '$3' : undefined} {...reverseStandardAnimation}>
                      {/* {currentServerInfoLink && !onlyShowServer
                        ? <Button size='$3' mr='$2' disabled icon={<Info />} circular opacity={0} />
                        : undefined} */}
                      <YStack
                        w='100%'
                        maw={mediaQuery.gtXs ? 350 : 250}
                        f={1}>
                        <Heading
                          // whiteSpace="nowrap" 
                          w='100%'
                          // maw={200}
                          // overflow='hidden'
                          ta='center'
                          als='center'>{serversState.server?.serverConfiguration?.serverInfo?.name}</Heading>
                        <Heading size='$3' als='center' textAlign='center' marginTop='$2'>
                          {serversState.server ? serversState.server.host : '<None>'}{serversDiffer ? ' is selected' : ''}
                        </Heading>
                      </YStack>
                      {currentServerInfoLink && !onlyShowServer
                        ? <Button size='$3' my='auto' ml='$2' onPress={(e) => { e.stopPropagation(); currentServerInfoLink.onPress(e); }} icon={<Info />} circular />
                        : undefined}
                    </XStack>
                    : undefined}
                  <XStack f={1} />
                </XStack>
              </YStack>}
              {serversDiffer
                ? <>
                  <Heading color={warningAnchorColor} whiteSpace='nowrap' maw={200} overflow='hidden' als='center'>{primaryServer?.serverConfiguration?.serverInfo?.name}</Heading>
                  <Heading color={warningAnchorColor} size='$3' als='center' marginTop='$2' textAlign='center'>
                    Viewing server configuration for {onlyShowServer.host}
                  </Heading>
                </>
                : onlyShowServer
                  ? <Heading size='$3' marginTop='$2' color={warningAnchorColor} textAlign='center'>
                    Viewing server configuration
                  </Heading>
                  : undefined}
              {browsingOnDiffers
                ? <><Heading color={warningAnchorColor} size='$3' als='center' marginTop='$2' textAlign='center'>
                  Browsing via {browsingOn}
                </Heading>
                </>
                : browsingServers && Platform.OS == 'web'
                  ? <Heading size='$3' marginTop='$2'>&nbsp;</Heading>
                  : undefined}

              {servers.length === 0 ? <Heading size="$2" alignSelf='center' paddingVertical='$6'>No servers added.</Heading> : undefined}

              {browsingServers
                ? <XStack animation="quick" mb='$2' {...standardAnimation}>
                  <>
                    <ScrollView horizontal>
                      <XStack space='$3'>
                        {servers.map((server, index) => {
                          return <ServerCard server={server} key={`serverCard-${serverID(server)}`} isPreview />;
                        })}
                      </XStack>
                    </ScrollView>
                    {/* <FlatList
                    horizontal={true}
                    data={servers}
                    keyExtractor={(server) => server.host}
                    renderItem={({ item: server }) => {
                      return <ServerCard server={server} key={`serverCard-${serverID(server)}`} isPreview />;
                    }}
                  // style={Styles.trueBackground}
                  // contentContainerStyle={Styles.contentBackground}
                  /> */}
                  </>
                </XStack> : undefined}
              {!browsingServers ? <YStack h="$2" /> : undefined}
              <YStack space="$2">
                <XStack>
                  <Heading f={1}>Accounts</Heading>

                  <Button
                    size="$3"
                    icon={Plus}
                    disabled={serversState.server === undefined}
                    onPress={() => setAddingAccount((x) => !x)}
                  >
                    Login/Create
                  </Button>
                  <Sheet
                    modal
                    open={addingAccount}
                    onOpenChange={setAddingAccount}
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
                        size="$3"
                        circular
                        icon={ChevronDown}
                        onPress={() => {
                          setAddingAccount(false)
                        }}
                      />
                      <Heading size="$9">Add Account</Heading>
                      <Heading size="$4">{primaryServer?.host}/</Heading>
                      <Sheet.ScrollView>
                        <YStack space="$2" pb='$2' maw={600} w='100%' als='center'>
                          {/* <Heading size="$10">Add Account</Heading> */}
                          <Input textContentType="username" autoCorrect={false} placeholder="Username" keyboardType='twitter'
                            editable={!disableAccountInputs} opacity={disableAccountInputs || newAccountUser.length === 0 ? 0.5 : 1}
                            autoCapitalize='none'
                            value={newAccountUser}
                            onChange={(data) => { setNewAccountUser(data.nativeEvent.text) }} />

                          {loginMethod
                            ? <XStack w='100%' animation="quick" {...standardAnimation}>
                              <Input secureTextEntry w='100%'
                                textContentType={loginMethod == LoginMethod.Login ? "password" : "newPassword"}
                                placeholder="Password"
                                editable={!disableAccountInputs} opacity={disableAccountInputs || newAccountPass.length === 0 ? 0.5 : 1}

                                value={newAccountPass}
                                onChange={(data) => { setNewAccountPass(data.nativeEvent.text) }} />
                            </XStack>
                            : undefined}

                          {loginMethod && newAccountPass.length < 8 ? <Heading size="$2" color="red" alignSelf='center' ta='center'>Password must be at least 8 characters.</Heading> : undefined}

                          {loginMethod === LoginMethod.CreateAccount && (server?.serverConfiguration?.serverInfo?.privacyPolicy?.length ?? 0) > 0
                            ? <>
                              <Heading size="$2" alignSelf='center' ta='center'>Privacy Policy</Heading>
                              <TamaguiMarkdown text={server?.serverConfiguration?.serverInfo?.privacyPolicy} />
                            </> : undefined}

                          {accountsState.errorMessage ? <Heading size="$2" color="red" alignSelf='center' ta='center'>{accountsState.errorMessage}</Heading> : undefined}
                          {accountsState.successMessage ? <Heading size="$2" color="green" alignSelf='center' ta='center'>{accountsState.successMessage}</Heading> : undefined}

                          {loginMethod
                            ? <XStack>
                              <Button marginRight='$1' onPress={() => { setLoginMethod(undefined); setNewAccountPass(''); }} icon={ChevronLeft}
                                disabled={disableAccountInputs} opacity={disableAccountInputs ? 0.5 : 1}>
                                Back
                              </Button>
                              <Button flex={1} backgroundColor={primaryColor} color={primaryTextColor} onPress={() => {
                                if (loginMethod == LoginMethod.Login) {
                                  loginToServer();
                                } else {
                                  createServerAccount();
                                }
                              }} disabled={disableAccountButtons} opacity={disableAccountButtons ? 0.5 : 1}>
                                {loginMethod == LoginMethod.Login ? 'Login' : 'Create Account'}
                              </Button>
                            </XStack>
                            : <XStack>
                              <Button flex={2} marginRight='$1' onPress={() => setLoginMethod(LoginMethod.CreateAccount)}
                                disabled={disableLoginMethodButtons} opacity={disableLoginMethodButtons ? 0.5 : 1}>
                                Create Account
                              </Button>
                              <Button flex={1} backgroundColor={primaryColor} color={primaryTextColor} onPress={() => setLoginMethod(LoginMethod.Login)}
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


              {app.separateAccountsByServer
                ? <>
                  {accountsOnPrimaryServer.length === 0 ? <Heading size="$2" alignSelf='center' paddingVertical='$6'>No accounts added on {primaryServer?.host}.</Heading> : undefined}
                  {accountsOnPrimaryServer.map((account) => <AccountCard account={account} key={accountId(account)} />)}
                  {accountsElsewhere.length > 0 && !onlyShowServer
                    ? <>
                      <Heading>Accounts Elsewhere</Heading>
                      {accountsElsewhere.map((account) => <AccountCard account={account} key={accountId(account)} />)}
                    </>
                    : undefined
                  }
                </>
                : <>
                  {accounts.length === 0 ? <Heading size="$2" alignSelf='center' paddingVertical='$6'>No accounts added.</Heading> : undefined}
                  {accounts.map((account) => <AccountCard account={account} key={accountId(account)} />)}
                </>}

              {/* <FlatList
                data={accounts}
                keyExtractor={(account) => accountId(account)}
                renderItem={({ item }) => {
                  return <AccountCard account={item} />;
                }}
              // style={Styles.trueBackground}
              // contentContainerStyle={Styles.contentBackground}
              /> */}
            </YStack>
          </Sheet.ScrollView>
        </Sheet.Frame>
      </Sheet>
    </>
  )
}
