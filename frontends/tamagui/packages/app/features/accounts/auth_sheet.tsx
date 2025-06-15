import { Button, Heading, Input, Sheet, standardAnimation, useMedia, XStack, YStack } from '@jonline/ui';
import { ChevronLeft } from '@tamagui/lucide-icons';
import { AutoAnimatedList, TamaguiMarkdown } from 'app/components';
import { useAuthSheetContext } from 'app/contexts/auth_sheet_context';
import { useAppDispatch, useCreationServer, useCurrentServer, usePinnedAccountsAndServers } from 'app/hooks';
import { accountID, actionSucceeded, clearAccountAlerts, createAccount, login, RootState, selectAllAccounts, serverID, store, useRootSelector, useServerTheme } from 'app/store';
import { themedButtonBackground } from 'app/utils';
import React, { useCallback, useEffect, useState } from 'react';
import { TextInput } from 'react-native';
import { useRouter } from 'solito/router';
import { ServerNameAndLogo } from '../navigation/server_name_and_logo';
import AccountCard from './account_card';
import { CreationServerSelector } from './creation_server_selector';

export type AuthSheetProps = {
  // server?: JonlineServer;
  // onAccountSelected?: (account: JonlineAccount) => void;
}

export enum LoginMethod {
  Login = 'login',
  CreateAccount = 'create_account',
}
export function AuthSheet({ }: AuthSheetProps) {
  const mediaQuery = useMedia();
  const dispatch = useAppDispatch();
  // const [open, setOpen] = useState(false);
  // const [browsingServers, setBrowsingServers] = useState(false);
  // const [addingServer, setAddingServer] = useState(false);
  // const [open, setOpen] = useState(false);
  const { open: [open, setOpen] } = useAuthSheetContext();

  const { creationServer: creationServer, setCreationServer: setCreationServer } = useCreationServer();
  // useEffect(() => {
  //   if (open && taggedServer && (
  //     !creationServer
  //     || serverID(taggedServer) != serverID(creationServer)
  //   )) {
  //     setCreationServer(taggedServer);
  //   }
  // }
  //   , [open, taggedServer]);
  const [addingAccount, setAddingAccount] = useState(false);
  const [loginMethod, setLoginMethod] = useState<LoginMethod | undefined>(undefined);
  const [reauthenticating, setReauthenticating] = useState(false);
  const [position, setPosition] = useState(0);
  const [newAccountUser, setNewAccountUser] = useState('');
  const [newAccountPass, setNewAccountPass] = useState('');

  const specifiedServer = creationServer;


  const usernameRef = React.useRef(undefined as never) as React.MutableRefObject<TextInput>;
  const passwordRef = React.useRef(undefined as never) as React.MutableRefObject<TextInput>;

  const currentServer = useCurrentServer();
  const server = specifiedServer ?? currentServer;

  const { primaryColor, primaryTextColor, navColor, navTextColor } = useServerTheme(server);
  const accountsState = useRootSelector((state: RootState) => state.accounts);
  const accounts = useRootSelector((state: RootState) => selectAllAccounts(state.accounts));
  // const primaryServer = onlyShowServer || serversState.server;
  // const accountsOnPrimaryServer = server ? accounts.filter(a => serverUrl(a.server) == serverUrl(server!)) : [];
  const accountsOnServer = server ? accounts.filter(a => serverID(a.server) == serverID(server!)) : [];

  async function onAccountAdded() {
    // setOpen(false);

    setAddingAccount(false);

    // setTimeout(() => {
    setNewAccountUser('');
    setNewAccountPass('');
    setForceDisableAccountButtons(false);
    setLoginMethod(undefined);
    setReauthenticating(false);
    // setTimeout(() => setOpen(false), 600);
    // }, 600);
    setTimeout(() => {
      setOpen(false);
    }, 700);
    setTimeout(() => {
      dispatch(clearAccountAlerts());
    }, 2000);

    const accountEntities = store.getState().accounts.entities;
    const account = store.getState().accounts.ids.map((id) => accountEntities[id])
      .find(a => a && a.user.username === newAccountUser && a.server.host === server?.host);

    if (account) {
      // if (onAccountSelected) {
      //   onAccountSelected(account);
      // }
    } else {
      console.warn("Account not found after adding it. This is a bug.");
    }
  }
  // const skipAccountSelection = onAccountSelected !== undefined || currentServer?.host !== server?.host;
  const loginToServer = useCallback(() => {
    dispatch(clearAccountAlerts());
    const loginRequest = {
      ...server!,
      userId: undefined,
      username: newAccountUser,
      password: newAccountPass,
      skipSelection: false,//skipAccountSelection,
    };
    // debugger;
    dispatch(login(loginRequest)).then(action => {
      if (actionSucceeded(action)) {
        onAccountAdded();
      } else {
        setForceDisableAccountButtons(false);
      }
    });
  }, [server, newAccountUser, newAccountPass]);
  const { push } = useRouter();
  const createServerAccount = useCallback(() => {
    dispatch(clearAccountAlerts());
    dispatch(createAccount({
      ...server!,
      username: newAccountUser,
      password: newAccountPass,
      skipSelection: false,//skipAccountSelection,
    })).then(action => {
      if (actionSucceeded(action)) {
        onAccountAdded();
        const isCurrentServer = server?.host === currentServer?.host;
        const profileUrl = isCurrentServer ? `/${newAccountUser}` : `/${newAccountUser}@${server?.host}`;
        requestAnimationFrame(() => push(profileUrl));
      } else {
        setForceDisableAccountButtons(false);
      }
    });
  }, [server, newAccountUser, newAccountPass]);

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
    if (!addingAccount && accountsOnServer.length == 0 && !accountsLoading) {
      setAddingAccount(true);
    }
  }, [accountsLoading, forceDisableAccountButtons, addingAccount, accountsOnServer.length]);

  useEffect(() => {
    if (open) {
      if (addingAccount && accountsOnServer.length > 0) {
        setAddingAccount(false);
      } else if (!addingAccount && accountsOnServer.length == 0) {
        setAddingAccount(true);
      }
    }
  }, [open]);

  const alreadyHasAccounts = accountsOnServer.length > 0;


  const pinnedServers = usePinnedAccountsAndServers()
    .map(aos =>
      `${aos.server ? serverID(aos.server) : null}-(${aos.account ? accountID(aos.account) : null})`)
    .sort().join(',');

  useEffect(() => {
    if (open) {
      requestAnimationFrame(() => setOpen(false));
    }
  }, [pinnedServers]);
  return (
    <>
      <Sheet
        modal
        open={open}
        onOpenChange={setOpen}
        // snapPoints={[80]}
        snapPoints={[81]} dismissOnSnapToBottom
        position={position}
        zIndex={600000}
        onPositionChange={setPosition}
      // dismissOnSnapToBottom
      >
        <Sheet.Overlay />
        <Sheet.Frame>
          <Sheet.Handle />
          {/* <ZStack h='$6'> */}
          <XStack
            // gap='$2'
            h='$5' // paddingHorizontal='$3'
            // mx='$3'
            px='$3'
            // w='100%'
            mb='$2'
            ai='center'
          >
            <Button
              alignSelf='center'
              size="$3"
              circular
              icon={ChevronLeft}
              onPress={() => setOpen(false)} />
            <XStack h='100%' f={1}>
              <AutoAnimatedList style={{ height: '100%', width: '100%', }}>
                {alreadyHasAccounts
                  ? <XStack key='accounts' ml='$3'>
                    <Button h='auto' mih='$3'
                      {...addingAccount ? {} : themedButtonBackground(navColor, navTextColor)}
                      transparent={addingAccount}
                      borderTopRightRadius={0} borderBottomRightRadius={0}
                      onPress={() => {
                        setAddingAccount(false);
                        setReauthenticating(false);
                      }}>
                      {mediaQuery.gtXs
                        ? <Heading whiteSpace='nowrap' size='$4' color={addingAccount ? undefined : navTextColor}>Choose Account</Heading>
                        : <YStack ai='center'>
                          <Heading whiteSpace='nowrap' size='$3' color={addingAccount ? undefined : navTextColor}>Choose</Heading>
                          <Heading whiteSpace='nowrap' size='$1' color={addingAccount ? undefined : navTextColor}>Account</Heading>
                        </YStack>}
                    </Button>
                    <Button h='auto' mih='$3'
                      {...!addingAccount ? {} : themedButtonBackground(navColor, navTextColor)}
                      transparent={!addingAccount}
                      borderTopLeftRadius={0} borderBottomLeftRadius={0}
                      // opacity={!chatUI || showScrollPreserver ? 0.5 : 1}
                      onPress={() => {
                        setAddingAccount(true);
                        setTimeout(() => usernameRef.current.focus(), 100);
                      }}>
                      {mediaQuery.gtXs
                        ?
                        <Heading size='$4' whiteSpace='nowrap' color={!addingAccount ? undefined : navTextColor}>{reauthenticating ? 'Reauthenticate' : 'Add Account'}</Heading>
                        : <YStack ai='center'>
                          <Heading size='$3' whiteSpace='nowrap' color={!addingAccount ? undefined : navTextColor}>Add</Heading>
                          <Heading size='$1' whiteSpace='nowrap' color={!addingAccount ? undefined : navTextColor}>Account</Heading>
                        </YStack>}
                    </Button>
                  </XStack>
                  :
                  <Heading key='add-account' size="$5" whiteSpace='nowrap' alignSelf='center' my='auto' ml='$3' >Add Account</Heading>
                }
              </AutoAnimatedList>
            </XStack>
            {/* {mediaQuery.gtXs || true
              ? <Button
                alignSelf='center'
                size="$3"
                circular
                pointerEvents='none'
                o={0.0}
              // icon={ChevronLeft}
              // onPress={() => setOpen(false)} 
              />
              : undefined} */}

            {/* <Heading size="$5" alignSelf='center'>{alreadyHasAccounts ? 'Accounts' : 'Add Account'}</Heading> */}
          </XStack>
          <CreationServerSelector />
          {/* {newFunction(mediaQuery, setOpen, creationServer, isCurrentServer, server, serverLink, servers, dispatch, setCreationServer, currentServer)} */}

          <Sheet.ScrollView width='100%'>
            <AutoAnimatedList style={{
              maxWidth: 600,
              width: '100%',
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'center',
              paddingLeft: 15,
              paddingRight: 15,
              marginLeft: 'auto',
              marginRight: 'auto',
            }}>

              {/* <YStack gap="$2" maw={600} w='100%' pb='$2' als='center' paddingHorizontal="$5"> */}
              {/* <div key={`server-logo-${server?.host}`} style={{
                marginTop: 10,
                marginBottom: 3,
                width: '100%',
                display: 'flex'
              }}> */}
              <XStack mx='auto' key={`server-logo-${server?.host}`}>
                <ServerNameAndLogo server={server} enlargeSmallText />
              </XStack>
              {/* </div> */}
              {addingAccount
                ? <YStack key='add-account-panel' gap="$2" w='100%' pb='$3'>
                  <Heading size="$6">{server?.host}/</Heading>
                  <Input textContentType="username" autoCorrect={false} placeholder="Username" keyboardType='twitter'
                    editable={!disableAccountInputs} opacity={disableAccountInputs || newAccountUser.length === 0 ? 0.5 : 1}
                    autoCapitalize='none'
                    value={newAccountUser}
                    ref={usernameRef}
                    onKeyPress={(e) => {
                      if (e.nativeEvent.key === 'Enter') {// || e.nativeEvent.keyCode === 13) {
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
                    ? <XStack w='100%' animation='standard'  {...standardAnimation}>
                      <Input secureTextEntry w='100%'
                        ref={passwordRef}
                        textContentType={loginMethod === LoginMethod.Login ? "password" : "newPassword"}
                        placeholder="Password"
                        editable={!disableAccountInputs} opacity={disableAccountInputs || newAccountPass.length === 0 ? 0.5 : 1}
                        onKeyPress={(e) => {
                          if (e.nativeEvent.key === 'Enter') {// || e.nativeEvent.keyCode === 13) {
                            if (loginMethod == LoginMethod.Login) {
                              loginToServer();
                            } else {
                              createServerAccount();
                            }
                          }
                        }}
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
                    : <XStack gap='$1'>
                      <Button flex={2} marginRight='$1'
                        onPress={() => {
                          setLoginMethod(LoginMethod.CreateAccount);
                          setTimeout(() => passwordRef.current.focus(), 100);
                        }}
                        disabled={disableLoginMethodButtons} opacity={disableLoginMethodButtons ? 0.5 : 1}>
                        Sign Up
                      </Button>
                      <Button flex={1} {...themedButtonBackground(primaryColor, primaryTextColor)}
                        onPress={() => {
                          setLoginMethod(LoginMethod.Login);
                          setTimeout(() => passwordRef.current.focus(), 100);
                        }}
                        disabled={disableLoginMethodButtons} opacity={disableLoginMethodButtons ? 0.5 : 1}>
                        Login
                      </Button>
                    </XStack>}
                </YStack>
                : accountsOnServer.length > 0
                  ? accountsOnServer.map((account) =>
                    <XStack key={accountID(account)} w='100%'>
                      <AccountCard account={account}
                        totalAccounts={accountsOnServer.length}
                      // onPress={
                      //   onAccountSelected 
                      //   ? () => onAccountSelected(account) : 
                      //   undefined}
                      />
                    </XStack>)
                  : undefined}
              {/* </YStack> */}
            </AutoAnimatedList>
          </Sheet.ScrollView>
        </Sheet.Frame>
      </Sheet>
    </>
  )
}
