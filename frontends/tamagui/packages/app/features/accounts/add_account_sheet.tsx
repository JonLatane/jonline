import { Button, Heading, Input, Label, Sheet, SizeTokens, Switch, useMedia, XStack, YStack } from '@jonline/ui';
import { ChevronDown, ChevronLeft, Info, Menu, Plus, RefreshCw, User as UserIcon, X as XIcon } from '@tamagui/lucide-icons';
import { clearAccountAlerts, clearServerAlerts, createAccount, JonlineServer, loadingCredentialedData, login, resetCredentialedData, RootState, selectAllAccounts, selectAllServers, serverUrl, upsertServer, useServerInfo, useTypedDispatch, useTypedSelector } from 'app/store';
import React, { useState, useEffect } from 'react';
import { FlatList, Platform } from 'react-native';
import { useLink } from 'solito/link';
import { v4 as uuidv4 } from 'uuid';
import { SettingsSheet } from '../settings_sheet';
import AccountCard from './account_card';
import ServerCard from './server_card';

export type AddAccountSheetProps = {
  // primaryServer?: JonlineServer;
}

export function AddAccountSheet({}: AddAccountSheetProps) {
  const media = useMedia();
  // const [open, setOpen] = useState(false);
  // const [browsingServers, setBrowsingServers] = useState(false);
  // const [addingServer, setAddingServer] = useState(false);
  const [addingAccount, setAddingAccount] = useState(false);
  const [position, setPosition] = useState(0);
  const [newAccountUser, setNewAccountUser] = useState('');
  const [newAccountPass, setNewAccountPass] = useState('');

  const dispatch = useTypedDispatch();
  const app = useTypedSelector((state: RootState) => state.app);
  const serversState = useTypedSelector((state: RootState) => state.servers);
  const servers = useTypedSelector((state: RootState) => selectAllServers(state.servers));
  const browsingOn = Platform.OS == 'web' ? window.location.hostname : undefined
  // const browsingOnDiffers = browsingOn && (
  //   serversState.server && serversState.server.host != browsingOn ||
  //   onlyShowServer && onlyShowServer.host != browsingOn
  // );
  // function addServer() {
  //   console.log(`Connecting to server ${newServerHost}`)
  //   dispatch(clearServerAlerts());
  //   dispatch(upsertServer({
  //     host: newServerHost,
  //     secure: newServerSecure,
  //   }));
  // }

  const { server, primaryColor, primaryTextColor, navColor, navTextColor } = useServerInfo();
  const accountsState = useTypedSelector((state: RootState) => state.accounts);
  const accounts = useTypedSelector((state: RootState) => selectAllAccounts(state.accounts));
  // const primaryServer = onlyShowServer || serversState.server;
  // const accountsOnPrimaryServer = server ? accounts.filter(a => serverUrl(a.server) == serverUrl(server!)) : [];
  function loginToServer() {
    dispatch(clearAccountAlerts());
    dispatch(login({
      ...server!,
      username: newAccountUser,
      password: newAccountPass,
    }));
  }
  function createServerAccount() {
    dispatch(clearAccountAlerts());
    dispatch(createAccount({
      ...server!,
      username: newAccountUser,
      password: newAccountPass,
    }));
  }

  const accountsLoading = accountsState.status == 'loading';
  const newAccountValid = newAccountUser.length > 0 && newAccountPass.length >= 8;
  const [forceDisableAccountButtons, setForceDisableAccountButtons] = useState(false);
  const disableAccountInputs = accountsLoading || forceDisableAccountButtons;
  const disableAccountButtons = accountsLoading || !newAccountValid || forceDisableAccountButtons;
  useEffect(() => {
    if (accountsLoading && !forceDisableAccountButtons) {
      setForceDisableAccountButtons(true);
    }
  });

  if (accountsState.successMessage) {
    setTimeout(() => {
      setAddingAccount(false);
      setTimeout(() => {
        dispatch(clearAccountAlerts());
        setNewAccountUser('');
        setNewAccountPass('');
        setForceDisableAccountButtons(false);
      }, 1000);
    }, 1500);
  } else if (accountsState.errorMessage && forceDisableAccountButtons) {
    setForceDisableAccountButtons(false);
  }
  return (
    <>
      <Button backgroundColor={primaryColor} color={primaryTextColor}
        disabled={serversState.server === undefined}
        onPress={() => setAddingAccount((x) => !x)}>
        Login or Create Account to Comment
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
            <Heading size="$6">{server?.host}/</Heading>
            <Input textContentType="username" autoCorrect={false} placeholder="Username" keyboardType='twitter'
              disabled={disableAccountInputs} opacity={disableAccountInputs ? 0.5 : 1}
              autoCapitalize='none'
              value={newAccountUser}
              onChange={(data) => { setNewAccountUser(data.nativeEvent.text) }} />
            <Input secureTextEntry textContentType="newPassword" placeholder="Password"
              disabled={disableAccountInputs} opacity={disableAccountInputs ? 0.5 : 1}
              value={newAccountPass}
              onChange={(data) => { setNewAccountPass(data.nativeEvent.text) }} />

            <XStack>
              <Button flex={2} marginRight='$1' onClick={createServerAccount} disabled={disableAccountButtons} opacity={disableAccountButtons ? 0.5 : 1}>
                Create Account
              </Button>
              <Button flex={1} theme='active' onClick={loginToServer} disabled={disableAccountButtons} opacity={disableAccountButtons ? 0.5 : 1}>
                Login
              </Button>
            </XStack>

            {accountsState.errorMessage ? <Heading size="$2" color="red" alignSelf='center'>{accountsState.errorMessage}</Heading> : undefined}
            {accountsState.successMessage ? <Heading size="$2" color="green" alignSelf='center'>{accountsState.successMessage}</Heading> : undefined}

          </YStack>
        </Sheet.Frame>
      </Sheet>
    </>
  )
}
