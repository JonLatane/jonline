import { Anchor, Button, H1, Input, Paragraph, Separator, Sheet, XStack, YStack, Text, Heading, Label, Switch } from '@jonline/ui'
import { ChevronDown, ChevronUp } from '@tamagui/lucide-icons'
import store, { RootState, useTypedDispatch, useTypedSelector } from 'app/store/store';
import React, { useState } from 'react'
import { useLink } from 'solito/link'
import { createServer, selectAllServers } from "../../store/modules/Servers";
import { selectAllAccounts } from "../../store/modules/Accounts";
import { FlatList, View } from 'react-native';
import ServerCard from './server_card';


export function AccountsSheet() {
  const [newServerHost, setNewServerHost] = useState('');
  const [newAccountUser, setNewAccountUser] = useState('');
  const [newAccountPass, setNewAccountPass] = useState('');

  const dispatch = useTypedDispatch();
  const serversState = useTypedSelector((state: RootState) => state.servers);
  const servers = useTypedSelector((state: RootState) => selectAllServers(state.servers));
  const newServer = React.createRef<any>();
  const newServerSecure = React.createRef<any>();
  const serversLoading = serversState.status == 'loading';
  const newServerValid = newServerHost != '';

  function addServer() {
    dispatch(createServer({
      host: newServer.current!.value,
      allowInsecure: newServerSecure.current!.ariaChecked == 'false',
    }));
  }

  const accountsState = useTypedSelector((state: RootState) => state.accounts);
  const accounts = useTypedSelector((state: RootState) => selectAllAccounts(state.accounts));
  const newAccountUserRef = React.createRef<any>();
  const newAccountPassRef = React.createRef<any>();
  function login() {
    // dispatch(createServer({
    //   host: newServer.current!.value,
    //   allowInsecure: newServerSecure.current!.ariaChecked == 'false',
    // }));
  }
  function createAccount() {
    // dispatch(createServer({
    //   host: newServer.current!.value,
    //   allowInsecure: newServerSecure.current!.ariaChecked == 'false',
    // }));
  }
  const accountsLoading = accountsState.status == 'loading';
  const newAccountValid = newAccountUser.length > 0 && newAccountPass.length >= 8;

  const [open, setOpen] = useState(false)
  const [position, setPosition] = useState(0)
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
        snapPoints={[90]} dismissOnSnapToBottom
        position={position}
        onPositionChange={setPosition}
        // dismissOnSnapToBottom
      >
        <Sheet.Overlay />
        <Sheet.Frame ai="center" jc="center">
          <Sheet.Handle />
          <Button
            size="$6"
            circular
            icon={ChevronDown}
            onPress={() => {
              setOpen(false)
            }}
          />
          <Sheet.ScrollView p="$4" space>
          <YStack>
            <Heading>Servers</Heading>
            <YStack>
              <Input ref={newServer} textContentType="URL" placeholder="Server Hostname" disabled={serversLoading}
                onChange={() => { setNewServerHost(newServer.current!.value) }} />
            </YStack>
              <XStack>
                    <YStack style={{marginLeft: 'auto', marginRight: 'auto'}}>
                      <Switch size="$1" style={{marginLeft: 'auto', marginRight: 'auto'}} ref={newServerSecure} id="newServerSecure" aria-label='Secure' defaultChecked disabled={serversLoading} />
                      
                      <Label style={{flex: 1, alignContent: 'center'}} htmlFor="newServerSecure" >
                        <Heading size="$2">Secure</Heading>
                      </Label>
                    </YStack>
                  <Button style={{flex: 1}} onClick={addServer} disabled={serversLoading || !newServerValid}>
                    Add
                  </Button>
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
          <YStack>
            <Heading>Accounts for {serversState.server?.host}</Heading>
            <YStack>
              <Input ref={newAccountUserRef} textContentType="URL" placeholder="Username" disabled={accountsLoading}
                onChange={() => { setNewAccountUser(newAccountUserRef.current!.value) }} />
                <Input ref={newAccountUserRef} textContentType="password" placeholder="Password" disabled={accountsLoading}
                  onChange={() => { setNewAccountPass(newAccountPassRef.current!.value) }} />
            </YStack>
              <XStack>
                  <Button style={{flex: 2}} onClick={createAccount} disabled={accountsLoading || !newAccountValid}>
                    Create Account
                  </Button>
                  <Button style={{flex: 1}} onClick={login} disabled={accountsLoading || !newAccountValid}>
                    Login
                  </Button>
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
          </Sheet.ScrollView>
        </Sheet.Frame>
      </Sheet>
    </>
  )
}
