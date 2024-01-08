import { Button, Heading, Input, Paragraph, Sheet, standardAnimation, useMedia, XStack, YStack, ZStack } from '@jonline/ui';
import { ChevronDown, ChevronLeft, ExternalLink } from '@tamagui/lucide-icons';
import { TamaguiMarkdown } from 'app/components';
import { useAppDispatch, useServer } from 'app/hooks';
import { accountID, actionSucceeded, clearAccountAlerts, createAccount, getServerTheme, JonlineAccount, JonlineServer, login, RootState, selectAllAccounts, serverID, store, useRootSelector } from 'app/store';
import { themedButtonBackground } from 'app/utils';
import React, { useEffect, useState } from 'react';
import { TextInput } from 'react-native';
import { ServerNameAndLogo } from '../navigation/server_name_and_logo';
import AccountCard from './account_card';
import { useLink } from 'solito/link';

export type AddAccountSheetProps = {
  server?: JonlineServer;
  operation?: string;
  button?: (onPress: () => void) => JSX.Element;
  selectedAccount?: JonlineAccount;
  onAccountSelected?: (account: JonlineAccount) => void;
}

export enum LoginMethod {
  Login = 'login',
  CreateAccount = 'create_account',
}
export function AddAccountSheet({ server: specifiedServer, operation, button, onAccountSelected, selectedAccount }: AddAccountSheetProps) {
  const mediaQuery = useMedia();
  // const [open, setOpen] = useState(false);
  // const [browsingServers, setBrowsingServers] = useState(false);
  // const [addingServer, setAddingServer] = useState(false);
  const [open, setOpen] = useState(false);
  const [addingAccount, setAddingAccount] = useState(false);
  const [loginMethod, setLoginMethod] = useState<LoginMethod | undefined>(undefined);
  const [reauthenticating, setReauthenticating] = useState(false);
  const [position, setPosition] = useState(0);
  const [newAccountUser, setNewAccountUser] = useState('');
  const [newAccountPass, setNewAccountPass] = useState('');


  const passwordRef = React.useRef() as React.MutableRefObject<TextInput>;
  const dispatch = useAppDispatch();
  const app = useRootSelector((state: RootState) => state.app);
  const serversState = useRootSelector((state: RootState) => state.servers);

  const currentServer = useServer();
  const server = specifiedServer ?? currentServer;
  const isCurrentServer = server?.host == currentServer?.host;
  const serverLink = useLink({ href: server ? `http://${server.host}` : '' });

  const { primaryColor, primaryTextColor, navColor, navTextColor } = getServerTheme(server);
  const accountsState = useRootSelector((state: RootState) => state.accounts);
  const accounts = useRootSelector((state: RootState) => selectAllAccounts(state.accounts));
  // const primaryServer = onlyShowServer || serversState.server;
  // const accountsOnPrimaryServer = server ? accounts.filter(a => serverUrl(a.server) == serverUrl(server!)) : [];
  const accountsOnServer = server ? accounts.filter(a => serverID(a.server) == serverID(server!)) : [];

  function reauthenticateAccount(account: JonlineAccount) {
    setReauthenticating(true);
    setAddingAccount(true);
    setLoginMethod(LoginMethod.Login);
    setNewAccountUser(account.user.username);
    setOpen(true);
    setTimeout(() => passwordRef.current.focus(), 100);
  }
  async function onAccountAdded() {
    setAddingAccount(false);

    setNewAccountUser('');
    setNewAccountPass('');
    setForceDisableAccountButtons(false);
    setLoginMethod(undefined);
    setReauthenticating(false);

    setTimeout(() => {
      setOpen(false);
      dispatch(clearAccountAlerts());
    }, 600);

    const accountEntities = store.getState().accounts.entities;
    const account = store.getState().accounts.ids.map((id) => accountEntities[id])
      .find(a => a && a.user.username === newAccountUser && a.server.host === server?.host);

    if (account) {
      if (onAccountSelected) {
        onAccountSelected(account);
      }
    } else {
      console.warn("Account not found after adding it. This is a bug.");
    }
  }
  function loginToServer() {
    dispatch(clearAccountAlerts());
    dispatch(login({
      ...server!,
      username: newAccountUser,
      password: newAccountPass,
      skipSelection: onAccountSelected !== undefined,
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
      ...server!,
      username: newAccountUser,
      password: newAccountPass,
      skipSelection: onAccountSelected !== undefined,
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
  const disableAccountInputs = accountsLoading || forceDisableAccountButtons;
  const disableAccountButtons = accountsLoading || !newAccountValid || forceDisableAccountButtons;
  const disableLoginMethodButtons = newAccountUser == '';

  useEffect(() => {
    if (accountsLoading && !forceDisableAccountButtons) {
      setForceDisableAccountButtons(true);
    } else if (!accountsLoading && forceDisableAccountButtons) {
      setForceDisableAccountButtons(false);
    }
    if (!addingAccount && accountsOnServer.length == 0) {
      setAddingAccount(true);
    }
  }, [accountsLoading, forceDisableAccountButtons, addingAccount, accountsOnServer.length]);
  // if (accountsState.successMessage) {
  //   setTimeout(() => {
  //     // setOpen(false);
  //     setTimeout(() => {
  //       dispatch(clearAccountAlerts());
  //       // setNewAccountUser('');
  //       // setNewAccountPass('');
  //       // setForceDisableAccountButtons(false);
  //       // setLoginMethod(undefined);
  //       // setReauthenticating(false);
  //     }, 1000);
  //   }, 1500);
  // } else if (accountsState.errorMessage && forceDisableAccountButtons) {
  //   setForceDisableAccountButtons(false);
  // }
  // console.log('rerender')
  const onPress = () => setOpen((x) => !x);
  return (
    <>
      {button
        ? button(onPress)
        : <Button {...themedButtonBackground(primaryColor, primaryTextColor)}
          disabled={server === undefined}
          onPress={onPress}>
          <Heading size='$2' color={primaryTextColor}>
            Login/Sign Up
          </Heading>
          {operation ? <Heading size='$1' color={primaryTextColor}>
            to {operation}
          </Heading> : undefined}
        </Button>}
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
        <Sheet.Overlay />
        <Sheet.Frame>
          <Sheet.Handle />
          {/* <ZStack h='$6'> */}
          <XStack ai='center'
            pl={mediaQuery.gtXs ? '$2' : 0}
            pr={mediaQuery.gtXs ? '$4' : '$1'}>

            <XStack f={1} ai='center'>
              {isCurrentServer
                ? <ServerNameAndLogo server={server} />
                : <Button maxWidth='100%' h='auto' ml='$1' p='$1' transparent iconAfter={ExternalLink} target='_blank' {...serverLink}>
                  <XStack ai='center'>
                    <ServerNameAndLogo server={server} />
                  </XStack>
                </Button>
              }
            </XStack>
            <Button
              alignSelf='center'
              size="$6"
              circular
              icon={ChevronDown}
              onPress={() => {
                setOpen(false)
              }}
            />
            <XStack f={1} ai='center'>
              {isCurrentServer
                ? undefined
                : <>
                  <Paragraph ml='auto' size='$1' o={0.5}> via</Paragraph>
                  <XStack o={0.5}>
                    <ServerNameAndLogo server={currentServer} />
                  </XStack>
                </>}
            </XStack>
          </XStack>
          {/* </ZStack> */}
          {accountsOnServer.length > 0
            ? <XStack marginHorizontal='auto' marginVertical='$3'>
              {/* <Tooltip placement="bottom">
                <Tooltip.Trigger> */}
              <Button {...addingAccount ? {} : themedButtonBackground(navColor, navTextColor)}
                transparent={addingAccount}
                borderTopRightRadius={0} borderBottomRightRadius={0}
                onPress={() => {
                  setAddingAccount(false);
                  setReauthenticating(false);
                }}>
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
              <Button {...!addingAccount ? {} : themedButtonBackground(navColor, navTextColor)}
                transparent={!addingAccount}
                borderTopLeftRadius={0} borderBottomLeftRadius={0}
                // opacity={!chatUI || showScrollPreserver ? 0.5 : 1}
                onPress={() => setAddingAccount(true)}>
                <Heading size='$4' color={!addingAccount ? undefined : navTextColor}>{reauthenticating ? 'Reauthenticate' : 'Add Account'}</Heading>
              </Button>
              {/* </Tooltip.Trigger>
                <Tooltip.Content>
                  <Heading size='$2'>Go to newest.</Heading>
                </Tooltip.Content>
              </Tooltip> */}
            </XStack>
            : <Heading size='$9' ml='$5'>Add Account</Heading>}
          <Sheet.ScrollView>
            <YStack space="$2" maw={600} w='100%' pb='$2' als='center' paddingHorizontal="$5">
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
                        ref={passwordRef}
                        textContentType={loginMethod == LoginMethod.Login ? "password" : "newPassword"}
                        placeholder="Password"
                        editable={!disableAccountInputs} opacity={disableAccountInputs || newAccountPass.length === 0 ? 0.5 : 1}

                        value={newAccountPass}
                        onChange={(data) => { setNewAccountPass(data.nativeEvent.text) }} /></XStack>
                    : undefined}

                  {loginMethod === LoginMethod.CreateAccount
                    ? <>
                      <Heading size="$2" alignSelf='center' ta='center'>License</Heading>
                      <TamaguiMarkdown text={`
${server?.serverConfiguration?.serverInfo?.name ?? 'This server'} is powered by [Jonline](https://github.com/JonLatane/jonline), which is
released under the AGPL. As a user, using this server means you have a fundamental right to view the source code of this software and anything
using its data. If you suspect that the operator of this server is not using the official Jonline software, or doing anything proprietary/non-open
with your data, please contact the [Free Software Foundation](https://www.fsf.org/) to evaluate support options.
                          `} />
                      {(server?.serverConfiguration?.serverInfo?.privacyPolicy?.length ?? 0) > 0
                        ? <>
                          <Heading size="$2" alignSelf='center' ta='center'>Privacy Policy</Heading>
                          <TamaguiMarkdown text={server?.serverConfiguration?.serverInfo?.privacyPolicy} />
                        </> : undefined}
                      {(server?.serverConfiguration?.serverInfo?.mediaPolicy?.length ?? 0) > 0
                        ? <>
                          <Heading size="$2" alignSelf='center' ta='center'>Media Policy</Heading>
                          <TamaguiMarkdown text={server?.serverConfiguration?.serverInfo?.mediaPolicy} />
                        </> : undefined}
                    </>
                    : undefined}

                  {accountsState.errorMessage ? <Heading size="$2" color="red" alignSelf='center' ta='center'>{accountsState.errorMessage}</Heading> : undefined}
                  {accountsState.successMessage ? <Heading size="$2" color="green" alignSelf='center' ta='center'>{accountsState.successMessage}</Heading> : undefined}

                  {loginMethod
                    ? <XStack>
                      {reauthenticating ? undefined : <Button marginRight='$1' onPress={() => { setLoginMethod(undefined); setNewAccountPass(''); }} icon={ChevronLeft}
                        disabled={disableAccountInputs} opacity={disableAccountInputs ? 0.5 : 1}>
                        Back
                      </Button>}
                      <Button key='confirm-button' flex={1} {...themedButtonBackground(primaryColor, primaryTextColor)}
                        onPress={() => {
                          if (loginMethod == LoginMethod.Login) {
                            loginToServer();
                          } else {
                            createServerAccount();
                          }
                        }}
                        disabled={disableAccountButtons}
                        opacity={disableAccountButtons ? 0.5 : 1}
                      >
                        {loginMethod == LoginMethod.Login ? reauthenticating ? 'Reauthenticate' : 'Login' : 'Sign Up'}
                      </Button>
                    </XStack>
                    : <XStack space='$1'>
                      <Button flex={2} marginRight='$1' onPress={() => setLoginMethod(LoginMethod.CreateAccount)}
                        disabled={disableLoginMethodButtons} opacity={disableLoginMethodButtons ? 0.5 : 1}>
                        Sign Up
                      </Button>
                      <Button flex={1} {...themedButtonBackground(primaryColor, primaryTextColor)}
                        onPress={() => setLoginMethod(LoginMethod.Login)}
                        disabled={disableLoginMethodButtons} opacity={disableLoginMethodButtons ? 0.5 : 1}>
                        Login
                      </Button>
                    </XStack>}
                </YStack>
                : accountsOnServer.length > 0 ? <>
                  {/* <Heading size="$7" paddingVertical='$2'>Choose Account</Heading> */}
                  {accountsOnServer.map((account) =>
                    <YStack key={accountID(account)} mb='$2'>
                      <AccountCard account={account}
                        totalAccounts={accountsOnServer.length}
                        selectedAccount={selectedAccount}
                        onPress={onAccountSelected ? () => onAccountSelected(account) : undefined}
                        onReauthenticate={reauthenticateAccount} />
                    </YStack>)}
                </>
                  : undefined}
            </YStack>
          </Sheet.ScrollView>
        </Sheet.Frame>
      </Sheet>
    </>
  )
}
