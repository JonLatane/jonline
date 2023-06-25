import { Button, Heading, Input, Label, Sheet, SizeTokens, standardAnimation, Switch, Tooltip, useMedia, XStack, YStack } from '@jonline/ui';
import { ChevronDown, ChevronLeft, Info, Menu, Plus, RefreshCw, User as UserIcon, X as XIcon } from '@tamagui/lucide-icons';
import { accountId, clearAccountAlerts, clearServerAlerts, createAccount, JonlineServer, useLoadingCredentialedData, login, resetCredentialedData, RootState, selectAllAccounts, selectAllServers, serverID, upsertServer, useServerTheme, useTypedDispatch, useTypedSelector } from 'app/store';
import React, { useState, useEffect } from 'react';
import { FlatList, Platform } from 'react-native';
import { useLink } from 'solito/link';
import { v4 as uuidv4 } from 'uuid';
import { SettingsSheet } from '../settings_sheet';
import AccountCard from './account_card';
import ServerCard from './server_card';

export type AddAccountSheetProps = {
  // primaryServer?: JonlineServer;
  operation: string;
}

export enum LoginMethod {
  Login = 'login',
  CreateAccount = 'create_account',
}
export function AddAccountSheet({ operation }: AddAccountSheetProps) {
  const media = useMedia();
  // const [open, setOpen] = useState(false);
  // const [browsingServers, setBrowsingServers] = useState(false);
  // const [addingServer, setAddingServer] = useState(false);
  const [open, setOpen] = useState(false);
  const [addingAccount, setAddingAccount] = useState(false);
  const [loginMethod, setLoginMethod] = useState<LoginMethod | undefined>(undefined);
  const [position, setPosition] = useState(0);
  const [newAccountUser, setNewAccountUser] = useState('');
  const [newAccountPass, setNewAccountPass] = useState('');

  const dispatch = useTypedDispatch();
  const app = useTypedSelector((state: RootState) => state.app);
  const serversState = useTypedSelector((state: RootState) => state.servers);

  const { server, primaryColor, primaryTextColor, navColor, navTextColor } = useServerTheme();
  const accountsState = useTypedSelector((state: RootState) => state.accounts);
  const accounts = useTypedSelector((state: RootState) => selectAllAccounts(state.accounts));
  // const primaryServer = onlyShowServer || serversState.server;
  // const accountsOnPrimaryServer = server ? accounts.filter(a => serverUrl(a.server) == serverUrl(server!)) : [];
  const accountsOnServer = server ? accounts.filter(a => serverID(a.server) == serverID(server!)) : [];

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
  const disableLoginMethodButtons = newAccountUser == '';

  useEffect(() => {
    if (accountsLoading && !forceDisableAccountButtons) {
      setForceDisableAccountButtons(true);
    }
    if (!addingAccount && accountsOnServer.length == 0) {
      setAddingAccount(true);
    }
  });
  if (accountsState.successMessage) {
    setTimeout(() => {
      setOpen(false);
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
  return (
    <>
      <Button backgroundColor={primaryColor} color={primaryTextColor}
        disabled={serversState.server === undefined}
        onPress={() => setOpen((x) => !x)}>
        <Heading size='$2' color={primaryTextColor}>
          Login/Create Account
        </Heading>
        <Heading size='$1' color={primaryTextColor}>
          to {operation}
        </Heading>
      </Button>
      <Sheet
        modal
        open={open}
        onOpenChange={setOpen}
        // snapPoints={[80]}
        snapPoints={[81]} dismissOnSnapToBottom
        position={position}
        onPositionChange={setPosition}
      // dismissOnSnapToBottom
      >
        <Sheet.Overlay  />
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
          {accountsOnServer.length > 0
            ? <XStack marginHorizontal='auto' marginVertical='$3'>
              {/* <Tooltip placement="bottom">
                <Tooltip.Trigger> */}
              <Button backgroundColor={addingAccount ? undefined : navColor}
                transparent={addingAccount}
                borderTopRightRadius={0} borderBottomRightRadius={0}
                onPress={() => setAddingAccount(false)}>
                <Heading size='$4' color={addingAccount ? undefined : navTextColor}>Choose Account</Heading>
              </Button>
              {/* </Tooltip.Trigger>
                <Tooltip.Content>
                  <Heading size='$2'>Newest on bottom.</Heading>
                  <Heading size='$1'>Sorted by time.</Heading>
                </Tooltip.Content>
              </Tooltip>
              <Tooltip placement="bottom-end">
                <Tooltip.Trigger> */}
              <Button backgroundColor={!addingAccount ? undefined : navColor}
                transparent={!addingAccount}
                borderTopLeftRadius={0} borderBottomLeftRadius={0}
                // opacity={!chatUI || showScrollPreserver ? 0.5 : 1}
                onPress={() => setAddingAccount(true)}>
                <Heading size='$4' color={!addingAccount ? undefined : navTextColor}>Add Account</Heading>
              </Button>
              {/* </Tooltip.Trigger>
                <Tooltip.Content>
                  <Heading size='$2'>Go to newest.</Heading>
                </Tooltip.Content>
              </Tooltip> */}
            </XStack>
            : <Heading size='$10' ml='$5'>Add Account</Heading>}
          <Sheet.ScrollView>
            <YStack space="$2" maw={600} w='100%' als='center' paddingHorizontal="$5">
              {addingAccount
                ? <YStack space="$2" w='100%'>
                  <Heading size="$6">{server?.host}/</Heading>
                  <Input textContentType="username" autoCorrect={false} placeholder="Username" keyboardType='twitter'
                    editable={!disableAccountInputs} opacity={disableAccountInputs || newAccountUser.length === 0 ? 0.5 : 1}
                    autoCapitalize='none'
                    value={newAccountUser}
                    onChange={(data) => { setNewAccountUser(data.nativeEvent.text) }} />
                  {loginMethod
                    ? <XStack w='100%' animation="quick"  {...standardAnimation}>
                      <Input secureTextEntry w='100%'
                        textContentType={loginMethod == LoginMethod.Login ? "password" : "newPassword"}
                        placeholder="Password"
                        editable={!disableAccountInputs} opacity={disableAccountInputs || newAccountPass.length === 0 ? 0.5 : 1}

                        value={newAccountPass}
                        onChange={(data) => { setNewAccountPass(data.nativeEvent.text) }} /></XStack>
                    : undefined}

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

                  {accountsState.errorMessage ? <Heading size="$2" color="red" alignSelf='center' ta='center'>{accountsState.errorMessage}</Heading> : undefined}
                  {accountsState.successMessage ? <Heading size="$2" color="green" alignSelf='center' ta='center'>{accountsState.successMessage}</Heading> : undefined}
                </YStack>
                : accountsOnServer.length > 0 ? <>
                  {/* <Heading size="$7" paddingVertical='$2'>Choose Account</Heading> */}
                  {accountsOnServer.map((account) => <AccountCard account={account} key={accountId(account)} />)}
                </>
                  : undefined}
            </YStack>
          </Sheet.ScrollView>
        </Sheet.Frame>
      </Sheet>
    </>
  )
}
