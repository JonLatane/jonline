import { Anchor, Button, H1, Input, Paragraph, Separator, Sheet, XStack, YStack, Text, Heading, Label, Switch, SizeTokens, ZStack } from '@jonline/ui'
import { ChevronDown, ChevronUp, Plus, X as XIcon, User as UserIcon, ChevronLeft, Menu } from '@tamagui/lucide-icons'
import store, { RootState, useTypedDispatch, useTypedSelector } from 'app/store/store';
import React, { useState } from 'react'
import { useLink } from 'solito/link'
import { clearAlerts as clearServerAlerts, upsertServer, selectAllServers } from "../../store/modules/servers";
import { clearAlerts as clearAccountAlerts, createAccount, login, selectAllAccounts } from "../../store/modules/accounts";
import { FlatList, View } from 'react-native';
import ServerCard from './server_card';
import AccountCard from './account_card';
import { SettingsSheet } from '../settings_sheet';
import {v4 as uuidv4} from 'uuid';

export type AccountSheetProps = {
  size?: SizeTokens;
  showIcon?: boolean;
  circular?: boolean;
}

export function AccountsSheet({ size = '$5', circular = false }: AccountSheetProps) {
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
  const serversState = useTypedSelector((state: RootState) => state.servers);
  const servers = useTypedSelector((state: RootState) => selectAllServers(state.servers));
  const serversLoading = serversState.status == 'loading';
  const newServerHostNotBlank = newServerHost != '';
  const newServerExists = servers.some(s => s.host == newServerHost);
  const newServerValid = newServerHostNotBlank && !newServerExists;

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
  function loginToServer() {
    dispatch(clearAccountAlerts());
    dispatch(login({
      ...serversState.server!,
      username: newAccountUser,
      password: newAccountPass,
    }));
  }
  function createServerAccount() {
    dispatch(clearAccountAlerts());
    dispatch(createAccount({
      ...serversState.server!,
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
  // bc react native may render multiple accounts sheets at a time
  const secureLabelUuid = uuidv4();
  return (
    <>
      <Button
        size={size}
        icon={circular ? UserIcon : open ? XIcon : ChevronDown}
        circular={circular}
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
              <YStack space="$2">
                <XStack>
                  <Heading marginRight='$2'>Server{browsingServers ? 's' : ':'}</Heading>

                  <XStack f={1} />
                  {!browsingServers 
                    ? <Heading size='$3' marginTop='$2'>{serversState.server ? serversState.server.host : '<None>'}</Heading> 
                    : undefined}
                  <XStack f={1} />
                  <Button
                    size="$3"
                    icon={browsingServers ? ChevronLeft : Menu}
                    // circular
                    onPress={() => setBrowsingServers((x) => !x)}
                  >
                    {browsingServers ? 'Back' : 'Select'}
                  </Button>
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
                              onCheckedChange={(checked) => setNewServerSecure(checked)} disabled={serversLoading} />

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
              </YStack>

              {servers.length === 0 ? <Heading size="$2" alignSelf='center' paddingVertical='$6'>No servers added.</Heading> : undefined}

              {browsingServers ? <FlatList
                horizontal={true}
                data={servers}
                keyExtractor={(server) => server.host}
                renderItem={({ item: server }) => {
                  return <ServerCard server={server} />;
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
                        <Heading size="$6">{serversState.server?.host}/</Heading>
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

              {accounts.length === 0 ? <Heading size="$2" alignSelf='center' paddingVertical='$6'>No accounts added.</Heading> : undefined}

              {accounts.map((account) => <AccountCard account={account} key={account.id} />)}
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
