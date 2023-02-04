import { Button, Heading, Input, Label, Sheet, SizeTokens, Switch, useMedia, XStack, YStack } from '@jonline/ui';
import { ChevronDown, ChevronLeft, Info, Menu, Plus, User as UserIcon, X as XIcon } from '@tamagui/lucide-icons';
import { clearAccountAlerts, clearServerAlerts, createAccount, JonlineServer, login, RootState, selectAllAccounts, selectAllServers, serverUrl, upsertServer, useTypedDispatch, useTypedSelector } from 'app/store';
import React, { useState } from 'react';
import { FlatList, Platform } from 'react-native';
import { useLink } from 'solito/link';
import { v4 as uuidv4 } from 'uuid';
import { SettingsSheet } from '../settings_sheet';
import AccountCard from '../accounts/account_card';
import ServerCard from '../accounts/server_card';

export type GroupsSheetProps = {
  size?: SizeTokens;
  circular?: boolean;
  onlyShowServer?: JonlineServer;
}

export function GroupsSheet({ size = '$5', circular = false, onlyShowServer }: GroupsSheetProps) {
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

  const dispatch = useTypedDispatch();
  const app = useTypedSelector((state: RootState) => state.app);
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
  const accountsOnPrimaryServer = primaryServer ? accounts.filter(a => serverUrl(a.server) == serverUrl(primaryServer!)) : [];
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
      setNewAccountUser('');
      setNewAccountPass('');
      dispatch(clearAccountAlerts());
      setAddingAccount(false);
    }, 1000);
  }
  if (!app.allowServerSelection && browsingServers) {
    setBrowsingServers(false);
  }
  const serversDiffer = onlyShowServer && serversState.server && serverUrl(onlyShowServer) != serverUrl(serversState.server);
  const currentServerInfoLink = serversState.server && useLink({ href: `/server/${serverUrl(serversState.server)}` });
  // bc react native may render multiple accounts sheets at a time
  const secureLabelUuid = uuidv4();
  return (
    <>
      <Button
        size={size}
        icon={circular ? UserIcon : open ? XIcon : ChevronDown}
        circular={circular}
        color={serversDiffer || browsingOnDiffers ? 'yellow' : undefined}
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
          {/* <ZStack>
            <XStack alignContent='flex-end' space='$2' p='$4'>
              <SettingsSheet />
            </XStack>

          <Button
            alignSelf='center'
            size="$6"
            circular
            icon={ChevronDown}
            onPress={() => {
              setOpen(false)
            }}/>
          </ZStack> */}
          <XStack space='$4'>
            <XStack w={2} />
            <Button circular disabled size='$3' backgroundColor='$backgroundTransparent' />
            {/* <XStack w={15} /> */}
            <XStack f={1} />
            <Button
              alignSelf='center'
              size="$6"
              circular
              icon={ChevronDown}
              onPress={() => {
                setOpen(false)
              }} />
            <XStack f={1} />
            <SettingsSheet />
            <XStack w={2} />
          </XStack>
          <Sheet.ScrollView p="$4" space>
            <YStack maxWidth={800} width='100%' alignSelf='center'>
              {onlyShowServer && serversDiffer ? undefined : <YStack space="$2">
                <XStack>
                  {app.allowServerSelection && (browsingServers || media.gtXs)
                    ? <Heading marginRight='$2'>Server{browsingServers ? 's' : ':'}</Heading>
                    : undefined}

                  <XStack f={1} />
                  {!browsingServers
                    ? <YStack maw={media.gtXs ? 350 : 250}>
                      <Heading whiteSpace="nowrap" maw={200} overflow='hidden' als='center'>{serversState.server?.serverConfiguration?.serverInfo?.name}</Heading>
                      <Heading size='$3' als='center' marginTop='$2'>
                        {serversState.server ? serversState.server.host : '<None>'}{serversDiffer ? ' is selected' : ''}
                      </Heading>
                    </YStack>
                    : undefined}
                  {!browsingServers && currentServerInfoLink && !onlyShowServer
                    ? <Button size='$3' ml='$2' onPress={(e) => { e.stopPropagation(); currentServerInfoLink.onPress(e); }} icon={<Info />} circular />
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
                          <YStack style={{ flex: 1, marginLeft: 'auto', marginRight: 'auto' }}>
                            <Switch size="$1" style={{ marginLeft: 'auto', marginRight: 'auto' }} id={`newServerSecure-${secureLabelUuid}`} aria-label='Secure'
                              defaultChecked
                              onCheckedChange={(checked) => setNewServerSecure(checked)}
                              disabled={serversLoading || (Platform.OS == 'web' && window.location.protocol == 'https')} />

                            <Label style={{ flex: 1, alignContent: 'center', marginLeft: 'auto', marginRight: 'auto' }} htmlFor={`newServerSecure-${secureLabelUuid}`} >
                              <Heading size="$2">Secure</Heading>
                            </Label>
                          </YStack>
                          <Button style={{ flex: 2 }} onClick={addServer} disabled={serversLoading || !newServerValid}>
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
                  <Heading color='yellow' whiteSpace='nowrap' maw={200} overflow='hidden' als='center'>{primaryServer?.serverConfiguration?.serverInfo?.name}</Heading>
                  <Heading color='yellow' size='$3' als='center' marginTop='$2' textAlign='center'>
                    Viewing server configuration for {onlyShowServer.host}
                  </Heading>
                </>
                : onlyShowServer
                  ? <Heading size='$3' marginTop='$2' color='yellow' textAlign='center'>
                    Viewing server configuration
                  </Heading>
                  : undefined}
              {browsingOnDiffers
                ? <><Heading color='yellow' size='$3' als='center' marginTop='$2' textAlign='center'>
                  Browsing via {browsingOn}
                </Heading>
                </>
                : browsingServers && Platform.OS == 'web'
                  ? <Heading size='$3' marginTop='$2'>&nbsp;</Heading>
                  : undefined}

              {servers.length === 0 ? <Heading size="$2" alignSelf='center' paddingVertical='$6'>No servers added.</Heading> : undefined}

              {browsingServers ? <FlatList
                horizontal={true}
                data={servers}
                keyExtractor={(server) => server.host}
                renderItem={({ item: server }) => {
                  return <ServerCard server={server} isPreview />;
                }}
              // style={Styles.trueBackground}
              // contentContainerStyle={Styles.contentBackground}
              /> : undefined}
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
                      <YStack space="$2">
                        <Heading size="$10">Add Account</Heading>
                        <Heading size="$6">{primaryServer?.host}/</Heading>
                        <Input textContentType="username" autoCorrect={false} placeholder="Username" keyboardType='twitter' autoCapitalize='none' disabled={accountsLoading}
                          value={newAccountUser}
                          onChange={(data) => { setNewAccountUser(data.nativeEvent.text) }} />
                        <Input secureTextEntry textContentType="newPassword" placeholder="Password" disabled={accountsLoading}
                          value={newAccountPass}
                          onChange={(data) => { setNewAccountPass(data.nativeEvent.text) }} />

                        <XStack>
                          <Button flex={2} marginRight='$1' onClick={createServerAccount} disabled={accountsLoading || !newAccountValid}>
                            Create Account
                          </Button>
                          <Button flex={1} onClick={loginToServer} disabled={accountsLoading || !newAccountValid}>
                            Login
                          </Button>
                        </XStack>

                        {accountsState.errorMessage ? <Heading size="$2" color="red" alignSelf='center'>{accountsState.errorMessage}</Heading> : undefined}
                        {accountsState.successMessage ? <Heading size="$2" color="green" alignSelf='center'>{accountsState.successMessage}</Heading> : undefined}

                      </YStack>
                    </Sheet.Frame>
                  </Sheet>
                </XStack>
              </YStack>


              {app.separateAccountsByServer
                ? <>
                  {accountsOnPrimaryServer.length === 0 ? <Heading size="$2" alignSelf='center' paddingVertical='$6'>No accounts added on {primaryServer?.host}.</Heading> : undefined}
                  {accountsOnPrimaryServer.map((account) => <AccountCard account={account} key={account.id} />)}
                  {accountsElsewhere.length > 0 && !onlyShowServer
                    ? <>
                      <Heading>Accounts Elsewhere</Heading>
                      {accountsElsewhere.map((account) => <AccountCard account={account} key={account.id} />)}
                    </>
                    : undefined
                  }
                </>
                : <>
                  {accounts.length === 0 ? <Heading size="$2" alignSelf='center' paddingVertical='$6'>No accounts added.</Heading> : undefined}
                  {accounts.map((account) => <AccountCard account={account} key={account.id} />)}
                </>}

              {/* <FlatList
                data={accounts}
                keyExtractor={(account) => account.id}
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
