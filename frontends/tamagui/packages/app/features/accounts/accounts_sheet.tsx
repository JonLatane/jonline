import { Button, Heading, Input, Label, Sheet, SizeTokens, Switch, useMedia, XStack, YStack } from '@jonline/ui';
import { ChevronDown, ChevronLeft, Info, Menu, Plus, RefreshCw, User as UserIcon, X as XIcon } from '@tamagui/lucide-icons';
import { accountId, clearAccountAlerts, clearServerAlerts, createAccount, JonlineServer, loadingCredentialedData, login, resetCredentialedData, RootState, selectAllAccounts, selectAllServers, serverID, upsertServer, useServerTheme, useTypedDispatch, useTypedSelector } from 'app/store';
import React, { useState, useEffect } from 'react';
import { FlatList, Platform } from 'react-native';
import { useLink } from 'solito/link';
import { v4 as uuidv4 } from 'uuid';
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
  const media = useMedia();
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
  const browsingOnDiffers = browsingOn && (
    serversState.server && serversState.server.host != browsingOn ||
    onlyShowServer && onlyShowServer.host != browsingOn
  );
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
  const isLoadingCredentialedData = loadingCredentialedData();
  useEffect(() => {
    if (accountsLoading && !forceDisableAccountButtons) {
      setForceDisableAccountButtons(true);
    }
  });

  if (serversState.successMessage) {
    setTimeout(() => {
      setNewServerHost('');
      setNewServerSecure(true);
      dispatch(clearServerAlerts());
      setAddingServer(false);
    }, 1000);
  }
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
  if (!app.allowServerSelection && browsingServers) {
    setBrowsingServers(false);
  }
  const serversDiffer = onlyShowServer && serversState.server && serverID(onlyShowServer) != serverID(serversState.server);
  const currentServerInfoLink = serversState.server && useLink({ href: `/server/${serverID(serversState.server)}` });
  // bc react native may render multiple accounts sheets at a time
  const secureLabelUuid = uuidv4();
  const disableSecureSelection = serversLoading || (Platform.OS == 'web' && window.location.protocol == 'https');
  return (
    <>
      <Button
        size={size}
        icon={circular ? UserIcon : open ? XIcon : ChevronDown}
        circular={circular}
        color={serversDiffer || browsingOnDiffers ? warningAnchorColor : undefined}
        onPress={() => setOpen((x) => !x)}
      >
        {circular ? undefined : <YStack>
          {serversState.server ? <Heading transform={[{ translateY: serversState.server ? 2 : 0 }]} size='$1'>{serversState.server.host}/</Heading> : undefined}
          {accountsState.account ? <Heading transform={[{ translateY: -2 }]} size='$7' space='$0'>{accountsState.account.user.username}</Heading> : undefined}
        </YStack>}
      </Button>
      <Sheet
        modal
        open={open}
        onOpenChange={setOpen}
        // snapPoints={[80]}
        snapPoints={[87]}
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
              size="$6"
              circular
              icon={ChevronDown}
              onPress={() => setOpen(false)} />
            <XStack f={1} />
            <SettingsSheet size='$3' />

          </XStack>
          <Sheet.ScrollView p="$4" space>
            <YStack maxWidth={800} width='100%' alignSelf='center'>
              {onlyShowServer && serversDiffer ? undefined : <YStack space="$2">
                <XStack>
                  {app.allowServerSelection && (browsingServers || media.gtXs)
                    ? <Heading marginRight='$2'>Server{browsingServers ? 's' : ':'}</Heading>
                    : undefined}

                  <XStack f={1} />

                  {!browsingServers ?
                    <XStack animation="bouncy"
                      opacity={1}
                      scale={1}
                      y={0}
                      enterStyle={{
                        // scale: 1.5,
                        y: 50,
                        opacity: 0,
                      }}
                      exitStyle={{
                        // scale: 1.5,
                        // y: 50,
                        opacity: 0,
                      }}>
                      {currentServerInfoLink && !onlyShowServer
                        ? <Button size='$3' mr='$2' disabled icon={<Info />} circular opacity={0} />
                        : undefined}
                      <YStack maw={media.gtXs ? 350 : 250}>
                        <Heading whiteSpace="nowrap" maw={200} overflow='hidden' als='center'>{serversState.server?.serverConfiguration?.serverInfo?.name}</Heading>
                        <Heading size='$3' als='center' marginTop='$2'>
                          {serversState.server ? serversState.server.host : '<None>'}{serversDiffer ? ' is selected' : ''}
                        </Heading>
                      </YStack>
                      {currentServerInfoLink && !onlyShowServer
                        ? <Button size='$3' ml='$2' onPress={(e) => { e.stopPropagation(); currentServerInfoLink.onPress(e); }} icon={<Info />} circular />
                        : undefined}
                    </XStack>
                    : undefined}
                  <XStack f={1} />
                  {app.allowServerSelection ? <Button
                    size="$3"
                    icon={browsingServers ? ChevronLeft : Menu}
                    // circular
                    opacity={onlyShowServer != undefined ? 0.5 : 1}
                    disabled={onlyShowServer != undefined}
                    maw={100}
                    onPress={() => setBrowsingServers((x) => !x)}
                  >
                    {browsingServers ? 'Back' : 'Select'}
                  </Button> : undefined}
                  {browsingServers ? <Button
                    size="$3"
                    icon={Plus}
                    marginLeft='$2'
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
                    snapPoints={[82]} dismissOnSnapToBottom
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
                        <Heading size="$10" style={{ flex: 1 }}>Add Server</Heading>
                        <YStack>
                          <Input textContentType="URL" keyboardType='url' autoCorrect={false} autoCapitalize='none' placeholder="Server Hostname" disabled={serversLoading}
                            value={newServerHost}
                            onChange={(data) => setNewServerHost(data.nativeEvent.text)} />
                        </YStack>
                        {(newServerHostNotBlank && newServerExists && !serversState.successMessage) ? <Heading size="$2" color="red" alignSelf='center'>Server already exists</Heading> : undefined}
                        <XStack>
                          <YStack style={{ flex: 1, marginLeft: 'auto', marginRight: 'auto' }} opacity={disableSecureSelection ? 0.5 : 1}>
                            <Switch size="$1" style={{ marginLeft: 'auto', marginRight: 'auto' }} id={`newServerSecure-${secureLabelUuid}`} aria-label='Secure'
                              defaultChecked
                              onCheckedChange={(checked) => setNewServerSecure(checked)}
                              disabled={disableSecureSelection} >
                              <Switch.Thumb animation="quick" />
                            </Switch>

                            <Label style={{ flex: 1, alignContent: 'center', marginLeft: 'auto', marginRight: 'auto' }} htmlFor={`newServerSecure-${secureLabelUuid}`} >
                              <Heading size="$2">Secure</Heading>
                            </Label>
                          </YStack>
                          <Button style={{ flex: 2 }} backgroundColor={primaryColor} color={primaryTextColor} onClick={addServer} disabled={serversLoading || !newServerValid}>
                            Add Server
                          </Button>
                        </XStack>
                        {serversState.errorMessage ? <Heading size="$2" color="red" alignSelf='center'>{serversState.errorMessage}</Heading> : undefined}
                        {serversState.successMessage ? <Heading size="$2" color="green" alignSelf='center'>{serversState.successMessage}</Heading> : undefined}
                      </YStack>
                    </Sheet.Frame>
                  </Sheet>
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
                ? <XStack animation="bouncy"
                  opacity={1}
                  scale={1}
                  y={0}
                  enterStyle={{
                    // scale: 1.5,
                    y: -50,
                    opacity: 0,
                  }}
                  exitStyle={{
                    // scale: 1.5,
                    // y: 50,
                    opacity: 0,
                  }}>
                  <FlatList
                    horizontal={true}
                    data={servers}
                    keyExtractor={(server) => server.host}
                    renderItem={({ item: server }) => {
                      return <ServerCard server={server} key={`serverCard-${serverID(server)}`} isPreview />;
                    }}
                  // style={Styles.trueBackground}
                  // contentContainerStyle={Styles.contentBackground}
                  />
                </XStack> : undefined}
              {!browsingServers ? <YStack h="$2" /> : undefined}
              <YStack space="$2">
                <XStack>
                  <Heading style={{ flex: 1 }}>Accounts</Heading>

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
                    snapPoints={[82]} dismissOnSnapToBottom
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
                          setAddingAccount(false)
                        }}
                      />
                      <YStack space="$2" maw={600} w='100%' als='center'>
                        <Heading size="$10">Add Account</Heading>
                        <Heading size="$6">{primaryServer?.host}/</Heading><Input textContentType="username" autoCorrect={false} placeholder="Username" keyboardType='twitter'
                          disabled={disableAccountInputs} opacity={disableAccountInputs ? 0.5 : 1}
                          autoCapitalize='none'
                          value={newAccountUser}
                          onChange={(data) => { setNewAccountUser(data.nativeEvent.text) }} />

                        {loginMethod ? <XStack w='100%' animation="bouncy"
                          scale={1}
                          y={0}
                          enterStyle={{
                            y: -20,
                            opacity: 0,
                          }}
                          exitStyle={{
                            opacity: 0,
                          }}><Input secureTextEntry w='100%'
                            textContentType={loginMethod == LoginMethod.Login ? "password" : "newPassword"}
                            placeholder="Password"
                            disabled={disableAccountInputs} opacity={disableAccountInputs ? 0.5 : 1}

                            value={newAccountPass}
                            onChange={(data) => { setNewAccountPass(data.nativeEvent.text) }} /></XStack>
                          : undefined}

                        {loginMethod
                          ? <XStack>
                            <Button marginRight='$1' onClick={() => { setLoginMethod(undefined); setNewAccountPass(''); }} icon={ChevronLeft}
                              disabled={disableAccountInputs} opacity={disableAccountInputs ? 0.5 : 1}>
                              Back
                            </Button>
                            <Button flex={1} backgroundColor={primaryColor} color={primaryTextColor} onClick={() => {
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
                            <Button flex={2} marginRight='$1' onClick={() => setLoginMethod(LoginMethod.CreateAccount)}
                              disabled={disableLoginMethodButtons} opacity={disableLoginMethodButtons ? 0.5 : 1}>
                              Create Account
                            </Button>
                            <Button flex={1} backgroundColor={primaryColor} color={primaryTextColor} onClick={() => setLoginMethod(LoginMethod.Login)}
                              disabled={disableLoginMethodButtons} opacity={disableLoginMethodButtons ? 0.5 : 1}>
                              Login
                            </Button>
                          </XStack>}

                        {accountsState.errorMessage ? <Heading size="$2" color="red" alignSelf='center' ta='center'>{accountsState.errorMessage}</Heading> : undefined}
                        {accountsState.successMessage ? <Heading size="$2" color="green" alignSelf='center' ta='center'>{accountsState.successMessage}</Heading> : undefined}
                      </YStack>
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
