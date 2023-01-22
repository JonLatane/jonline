import { Anchor, Button, H1, Input, Paragraph, Separator, Sheet, XStack, YStack, Text, Heading, Label, Switch } from '@jonline/ui'
import { ChevronDown, ChevronUp, Plus } from '@tamagui/lucide-icons'
import store, { RootState, useTypedDispatch, useTypedSelector } from 'app/store/store';
import React, { useState } from 'react'
import { useLink } from 'solito/link'
import { clearAlerts as clearServerAlerts, createServer, selectAllServers } from "../../store/modules/Servers";
import { clearAlerts as clearAccountAlerts, createAccount, login, selectAllAccounts } from "../../store/modules/Accounts";
import { FlatList, View } from 'react-native';
import ServerCard from './server_card';
import AccountCard from './account_card';

export function AccountsSheet() {
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
    dispatch(createServer({
      host: newServerHost,
      secure: newServerSecure,
    }));
  }

  const accountsState = useTypedSelector((state: RootState) => state.accounts);
  const accounts = useTypedSelector((state: RootState) => selectAllAccounts(state.accounts));
  function loginToServer() {
    dispatch(login({
      ...serversState.server!,
      username: newAccountUser,
      password: newAccountPass,
    }));
  }
  function createServerAccount() {
    dispatch(createAccount({
      ...serversState.server!,
      username: newAccountUser,
      password: newAccountPass,
    }));
  }
  const accountsLoading = accountsState.status == 'loading';
  const newAccountValid = newAccountUser.length > 0 && newAccountPass.length >= 8;

  const [open, setOpen] = useState(false)
  const [addingServer, setAddingServer] = useState(false)
  const [addingAccount, setAddingAccount] = useState(false)
  const [position, setPosition] = useState(0)

  if (serversState.successMessage) {
    setAddingServer(false);
    setNewServerHost('');
    setNewServerSecure(true);
    dispatch(clearServerAlerts())
  }
  if (accountsState.successMessage) {
    setAddingAccount(false);
    setNewAccountUser('');
    setNewAccountPass('');
    dispatch(clearAccountAlerts())
  }
  return (
    <>
      <Button
        size="$6"
        icon={open ? ChevronDown : ChevronUp}
        // circular
        onPress={() => setOpen((x) => !x)}
      >
        Accounts
      </Button>
      <Sheet
        modal
        open={open}
        onOpenChange={setOpen}
        // snapPoints={[80]}
        snapPoints={[90]}
        position={position}
        onPositionChange={setPosition}
        dismissOnSnapToBottom
      >
        <Sheet.Overlay />
        <Sheet.Frame>
          <Sheet.Handle />
          <Button
            alignSelf='center'
            size="$6"
            circular
            icon={ChevronDown}
            onPress={() => {
              setOpen(false)
            }}
          />
          <Sheet.ScrollView p="$4" space>
            <YStack maxWidth='800px' width='100%' alignSelf='center'>
              <YStack space="$2">
                <XStack>
                  <Heading style={{ flex: 1 }}>Servers</Heading>

                  <Button
                    size="$3"
                    icon={Plus}
                    // circular
                    onPress={() => setAddingServer((x) => !x)}
                  >
                    Add
                  </Button>
                  <Sheet
                    modal
                    open={addingServer}
                    onOpenChange={setAddingServer}
                    // snapPoints={[80]}
                    snapPoints={[90]} dismissOnSnapToBottom
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
                      <YStack space="$2" maxWidth='600px' width='100%' alignSelf='center'>
                        <Heading size="$10" style={{ flex: 1 }}>Add Server</Heading>
                        <YStack>
                          <Input textContentType="URL" keyboardType='url' autoCorrect={false} autoCapitalize='none' placeholder="Server Hostname" disabled={serversLoading}
                            onChange={(data) => setNewServerHost(data.nativeEvent.text)} />
                        </YStack>
                        {newServerHostNotBlank && newServerExists && <Heading size="$2" color="red" alignSelf='center'>Server already exists</Heading>}
                        <XStack>
                          <YStack style={{ flex: 1, marginLeft: 'auto', marginRight: 'auto' }}>
                            <Switch size="$1" style={{ marginLeft: 'auto', marginRight: 'auto' }} id="newServerSecure" aria-label='Secure'
                              defaultChecked
                              onCheckedChange={(checked) => setNewServerSecure(checked)} disabled={serversLoading} />

                            <Label style={{ flex: 1, alignContent: 'center', marginLeft: 'auto', marginRight: 'auto' }} htmlFor="newServerSecure" >
                              <Heading size="$2">Secure</Heading>
                            </Label>
                          </YStack>
                          <Button style={{ flex: 2 }} onClick={addServer} disabled={serversLoading || !newServerValid}>
                            Add Server
                          </Button>
                        </XStack>
                        {serversState.errorMessage && <Heading size="$2" color="red" alignSelf='center'>{serversState.errorMessage}</Heading>}
                        {serversState.successMessage && <Heading size="$2" color="green" alignSelf='center'>{serversState.successMessage}</Heading>}
                      </YStack>
                    </Sheet.Frame>
                  </Sheet>
                </XStack>
              </YStack>

              <FlatList
                data={servers}
                keyExtractor={(server) => server.host}
                renderItem={({ item }) => {
                  return <ServerCard server={item} />;
                }}
              // style={Styles.trueBackground}
              // contentContainerStyle={Styles.contentBackground}
              />
              <YStack space="$2">
                <XStack>
                  <Heading style={{ flex: 1 }}>Accounts</Heading>

                  <Button
                    size="$3"
                    icon={Plus}
                    // circular
                    onPress={() => setAddingAccount((x) => !x)}
                  >
                    Add
                  </Button>
                  <Sheet
                    modal
                    open={addingAccount}
                    onOpenChange={setAddingAccount}
                    // snapPoints={[80]}
                    snapPoints={[90]} dismissOnSnapToBottom
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
                      <Heading size="$10">Add Account for {serversState.server?.host}</Heading>
                      <YStack space="$2">
                        <Input textContentType="username" autoCorrect={false} placeholder="Username" keyboardType='twitter' autoCapitalize='none' disabled={accountsLoading}
                          onChange={(data) => { setNewAccountUser(data.nativeEvent.text) }} />
                        <Input secureTextEntry textContentType="newPassword" placeholder="Password" disabled={accountsLoading}
                          onChange={(data) => { setNewAccountPass(data.nativeEvent.text) }} />

                        <XStack>
                          <Button style={{ flex: 2 }} onClick={createServerAccount} disabled={accountsLoading || !newAccountValid}>
                            Create Account
                          </Button>
                          <Button style={{ flex: 1 }} onClick={loginToServer} disabled={accountsLoading || !newAccountValid}>
                            Login
                          </Button>
                        </XStack>
                      </YStack>
                    </Sheet.Frame>
                  </Sheet>
                </XStack>
              </YStack>
              <FlatList
                data={accounts}
                keyExtractor={(account) => account.id}
                renderItem={({ item }) => {
                  return <AccountCard account={item} />;
                }}
              // style={Styles.trueBackground}
              // contentContainerStyle={Styles.contentBackground}
              />
            </YStack>
          </Sheet.ScrollView>
        </Sheet.Frame>
      </Sheet>
    </>
  )
}
