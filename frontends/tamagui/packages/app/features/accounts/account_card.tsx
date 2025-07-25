import { Permission } from "@jonline/api";
import { Anchor, Button, Card, Dialog, Heading, Image, Input, Paragraph, Text, Theme, Tooltip, XStack, YStack, ZStack, formatError, useMedia, useTheme } from "@jonline/ui";
import { AlertCircle, Bot, Check, ChevronDown, ChevronUp, Delete, Pin, Shield, User as UserIcon } from "@tamagui/lucide-icons";
import { Selector, colorMeta, useAppSelector, useCredentialDispatch, useCurrentAccountId, useLocalConfiguration, useMediaUrl } from "app/hooks";
import { useRequestResult } from "app/hooks/use_request_result";
import { JonlineAccount, RootState, accountID, actionSucceeded, getCredentialClient, login, moveAccountDown, moveAccountUp, pinAccount, removeAccount, selectAccount, selectServer, serverID, store, unpinAccount, useRootSelector, useServerTheme } from "app/store";
import { hasAdminPermission, hasPermission } from 'app/utils';
import React, { useCallback, useMemo, useState } from "react";
import { TextInput } from "react-native";
import { useLink } from "solito/link";
import { ServerNameAndLogo } from "../navigation/server_name_and_logo";
import { createSelector } from "@reduxjs/toolkit";

interface Props {
  account: JonlineAccount;
  totalAccounts: number;
  // onReauthenticate?: (account: JonlineAccount) => void;
  onProfileOpen?: () => void;
  onPress?: () => void;
  // selectedAccount?: JonlineAccount;
}


const selectAccountIds = (
): Selector<string[]> =>
  createSelector(
    [(state: RootState) => state.accounts.ids as string[]],
    (data) => data
  );


const selectPinned = (
  account: JonlineAccount
): Selector<boolean> =>
  createSelector(
    [(state: RootState) => state.accounts.pinnedServers.map(ps => ps.accountId).includes(accountID(account))],
    (data) => data
  );



const AccountCard: React.FC<Props> = ({ account, totalAccounts, onProfileOpen, onPress }) => {
  const { dispatch, accountOrServer: currentAccountOrServer } = useCredentialDispatch();
  const currentAccountId = useCurrentAccountId();
  // useAppSelector(state => state.accounts.pinnedServers.find(ps =>
  //   ps.serverId === state.servers.currentServerId)?.accountId);
  const selected = currentAccountId === accountID(account);
  // console.log('AccountCard selected', selected, 'currentAccountId', currentAccountId, 'accountID(account)', accountID(account));
  const pinned = useAppSelector(selectPinned(account));

  const currentServer = currentAccountOrServer.server;
  const isCurrentServer = currentServer &&
    serverID(currentServer) == serverID(account.server);

  const [showReauthenticate, setShowReauthenticate] = useState(false);
  // console.log('showReauthenticate', showReauthenticate);
  const [reauthenticationPassword, setReauthenticationPassword] = useState('');
  // const [reauthenticationSuccess, setReauthenticationSuccess] = useState<boolean | undefined>();
  //   useEffect(() => {
  //     if (reauthenticationSuccess) {
  //       setTimeout(() => {
  //         setReauthenticationSuccess(undefined);
  // \      }, 1500);

  //       setTimeout(() => setResult(undefined), 1000);
  //     }
  //   });

  const {
    caller: doReauthentication,
    error: reauthenticationError,
    loading: reauthenticating,
    result: reauthenticationResult
  } = useRequestResult(
    async (setResult, setError) => {
      const action = await store.dispatch(login({
        ...account.server,
        username: account.user.username,
        userId: account.user.id,
        password: reauthenticationPassword,
        skipSelection: !isCurrentServer || !!currentAccountId
      }));
      if (actionSucceeded(action)) {
        setResult(action.payload);
        setTimeout(() => setResult(undefined), 1000);
        setShowReauthenticate(false);
        setReauthenticationPassword('');
        // setReauthenticationSuccess(true);
      } else {
        setError(formatError('error' in action ? action.error : undefined));
      }
    });

  const reauthenticationValid = reauthenticationPassword.length >= 8;
  const enablePasswordInput = !reauthenticating && !reauthenticationResult;
  const enableReauthenticateButton = reauthenticationValid && !reauthenticating && !reauthenticationResult;
  // console.log('reauthenticationValid', reauthenticationValid, 'reauthenticating', reauthenticating, 'reauthenticationResult', reauthenticationResult);

  const profileLink = useLink({
    href: isCurrentServer
      ? `/${account.user.username}`
      : `/${account.user.username}@${account.server.host}`
  });
  const profileLinkProps = {
    ...profileLink,
    onPress: (e) => {
      // if (account.needsReauthentication) {
      e.stopPropagation();
      // }
      profileLink.onPress?.(e);
      onProfileOpen?.();
    }
  };

  // const navColor = `#${(navColorInt)?.toString(16).slice(-6) || '424242'}`;
  // const primaryColorMeta = colorMeta(navColor);
  // const navColorMeta = colorMeta(navColor);

  const { primaryColor, primaryTextColor, navColor, navTextColor, primaryAnchorColor, navAnchorColor } = useServerTheme(account.server);
  const theme = useTheme();

  const backgroundColor = theme.background.val;
  const { luma: themeBgLuma } = colorMeta(backgroundColor);
  const darkMode = themeBgLuma <= 0.5;
  // const primaryAnchorColor = !darkMode ? primaryColorMeta.darkColor : primaryColorMeta.lightColor;
  // const navAnchorColor = !darkMode ? navColorMeta.darkColor : navColorMeta.lightColor;

  const { allowServerSelection } = useLocalConfiguration();

  const doSelectAccount = useCallback(() => {
    requestAnimationFrame(() => {
      if (account.needsReauthentication) {
        // onReauthenticate(account);
        setShowReauthenticate(true);
        return;
      }

      if (!isCurrentServer) {
        if (pinned) {
          dispatch(unpinAccount(account));
        } else {
          dispatch(pinAccount(account));
        }
        return;
      }

      if (isCurrentServer || allowServerSelection) {
        if (currentServer?.host != account.server.host) {

          dispatch(selectServer(account.server));
        }
        dispatch(selectAccount(account));
      }
    });
  }, [account, isCurrentServer, pinned, allowServerSelection, currentServer?.host, dispatch]);

  const doLogout = useCallback(() => {
    requestAnimationFrame(() => dispatch(selectAccount(undefined)));
  }, [dispatch]);

  const moveUp = useCallback(() => {
    requestAnimationFrame(() => dispatch(moveAccountUp(accountID(account)!)));
  }, [account, dispatch]);

  const moveDown = useCallback(() => {
    requestAnimationFrame(() => dispatch(moveAccountDown(accountID(account)!)));
  }, [account, dispatch]);
  const accountIds = useAppSelector(selectAccountIds());
  const canMoveUp = accountIds.indexOf(accountID(account)!) > 0;
  const canMoveDown = accountIds.indexOf(accountID(account)!) < accountIds.length - 1;
  const avatarUrl = useMediaUrl(account.user.avatar?.id, { account, server: account.server });
  const mediaQuery = useMedia();

  const textColor = selected ? navTextColor : undefined;
  const passwordRef = React.useRef(undefined as never) as React.MutableRefObject<TextInput>;

  const primaryBackgroundRight = pinned && !selected;
  const serverLogo = isCurrentServer ? undefined
    : <>
      <YStack w={50} h={50} jc='center' ai='center' ac='center'>
        <ServerNameAndLogo server={account.server} shrinkToSquare />
      </YStack>
      <Heading mx='$2' size='$7' color={selected ? navTextColor : undefined}>/</Heading>
    </>
  const reauth = useCallback(() => {
    getCredentialClient({ account, server: account.server });
  }, [account]);
  const [deleting, setDeleting] = useState(false);
  return <>
    <Card theme="dark" size="$4" bordered
      animation='standard'
      // w={250}
      // h={50}
      w='100%'
      backgroundColor={selected ? navColor : undefined}
      scale={0.9}
      // hoverStyle={{ scale: 0.925 }}
      // pressStyle={{ scale: 0.985 }}
      onPress={onPress ?? doSelectAccount}
    >
      <Card.Header>
        <YStack gap='$2'>
          <XStack ai='center'>
            {serverLogo}
            {(avatarUrl && avatarUrl != '') ?
              <XStack
                ai='center'
                w={mediaQuery.gtXs || true ? 50 : 26}
                h={mediaQuery.gtXs || true ? 50 : 26}
                mr={mediaQuery.gtXs || true ? '$3' : '$2'}>
                <Image
                  // pos="absolute"
                  width={mediaQuery.gtXs || true ? 50 : 26}
                  // opacity={0.25}
                  height={mediaQuery.gtXs || true ? 50 : 26}
                  borderRadius={mediaQuery.gtXs || true ? 25 : 13}
                  resizeMode="cover"
                  // als="flex-start"
                  source={{ uri: avatarUrl, width: mediaQuery.gtXs || true ? 50 : 26, height: mediaQuery.gtXs || true ? 50 : 26 }}
                // blurRadius={1.5}
                // borderRadius={5}
                />
              </XStack>
              : undefined}
            <YStack f={1}>
              <XStack ai='center'>
                <Heading size="$1" color={textColor}>{account.server.host}/</Heading>
                {account.user.realName ?
                  <Heading size='$7' fontSize="$1">{account.user.username}</Heading>
                  : undefined}

              </XStack>
              <Heading size="$7" color={textColor} mr='auto'>{account.user.realName || account.user.username}</Heading>
            </YStack>


            {hasAdminPermission(account.user)
              ? <Shield color={selected ? navTextColor : textColor} mb='auto' /> : undefined}
            {hasPermission(account.user, Permission.RUN_BOTS)
              ? <Bot color={selected ? navTextColor : textColor} mb='auto' /> : undefined}
          </XStack>

          {reauthenticationResult || account.needsReauthentication
            ? showReauthenticate
              ? <XStack flexWrap="wrap" ai='center' gap='$3'>
                <Input placeholder="Password" secureTextEntry
                  ref={passwordRef}
                  value={reauthenticationPassword}
                  disabled={!enablePasswordInput}
                  o={enablePasswordInput ? 1 : 0.5}
                  textContentType="password"
                  onChange={(e) => {
                    setReauthenticationPassword(e.nativeEvent.text)
                  }}
                  onKeyPress={(e) => {
                    if (e.nativeEvent.key === 'Enter') {
                      doReauthentication();
                    }
                  }} />

                {reauthenticationError
                  ? <Paragraph size='$1'>{reauthenticationError}</Paragraph>
                  : undefined}
                <Button mt='$2' mr='auto' h='auto' py='$3'
                  disabled={!enableReauthenticateButton}
                  o={enableReauthenticateButton ? 1 : 0.5}
                  onPress={(e) => {
                    e.stopPropagation();
                    doReauthentication();
                  }}>
                  <Paragraph size='$1' color={primaryAnchorColor} alignSelf="center" my='auto'>
                    Reauthenticate
                  </Paragraph>
                </Button>
              </XStack>
              : <XStack ai='center'>
                <Button mt='$2' mr='auto' h='auto' py='$3' onPress={(e) => {
                  e.stopPropagation();
                  setShowReauthenticate(true);
                  setTimeout(() => passwordRef.current?.focus(), 100);
                }}>
                  <XStack gap='$2' ai='center'>
                    <ZStack w='$2' h='$2'>
                      <XStack animation='standard' o={reauthenticationResult ? 1 : 0}>
                        <Check color={navAnchorColor} />
                      </XStack>
                      <YStack animation='standard' o={reauthenticationResult ? 0 : 1}>
                        <AlertCircle color={navAnchorColor} />
                      </YStack>
                    </ZStack>
                    <ZStack w='$12' h='$2'>
                      <Paragraph o={reauthenticationResult ? 1 : 0}
                        size='$1' color={primaryAnchorColor} alignSelf="center" my='auto'>
                        Reauthenticated! 👏
                      </Paragraph>
                      <Paragraph o={reauthenticationResult ? 0 : 1}
                        size='$1' color={primaryAnchorColor} alignSelf="center" my='auto'>
                        Reauthentication required.
                      </Paragraph>
                    </ZStack>
                  </XStack>
                </Button>
                <Button onPress={() => reauth()}>
                  <Paragraph size='$1'>Quick Reauth</Paragraph>
                </Button>
              </XStack>
            : undefined}

        </YStack>
        <XStack>
          <YStack f={1}>
          </YStack>
        </XStack>
      </Card.Header>
      <Card.Footer p='$3'>
        <YStack width='100%'>
          <XStack width='100%'>
            <YStack>
              <Heading size="$1" color={textColor} alignSelf="center">Account ID</Heading>
              <Paragraph size='$1' color={textColor} alignSelf="center">{account.user.id}</Paragraph>
            </YStack>
            <YStack f={1} />
            <XStack backgroundColor={primaryBackgroundRight ? primaryColor : undefined} p='$2' br='$2'>
              {pinned && !selected ? <XStack o={0.5} ai='center' mr='$2'>

                <Tooltip>
                  <Tooltip.Trigger>
                    <Pin size='$3' color={primaryTextColor} />
                  </Tooltip.Trigger>
                  <Tooltip.Content>
                    <Paragraph>
                      Pinned: data from {account.server?.host} will come from {account.user.username}'s account.
                    </Paragraph>
                  </Tooltip.Content>
                </Tooltip>
              </XStack> : undefined}
              {selected && !onPress
                ? <Button onPress={(e) => { e.stopPropagation(); doLogout(); }} mr='$2'>Logout</Button>
                : undefined}
              {totalAccounts > 1 && (!selected || onPress || mediaQuery.gtXxxs)
                ? <XStack my='auto' gap='$2' mr='$2'>
                  <Button disabled={!canMoveUp} o={canMoveUp ? 1 : 0.5} size='$2' onPress={(e) => { e.stopPropagation(); moveUp(); }} icon={ChevronUp} circular />
                  <Button disabled={!canMoveDown} o={canMoveDown ? 1 : 0.5} size='$2' onPress={(e) => { e.stopPropagation(); moveDown(); }} icon={ChevronDown} circular />
                </XStack>
                : undefined}

              <Button circular {...profileLinkProps} icon={<UserIcon />} mr='$2' />
              <Button icon={<Delete />} circular
                onPress={(e) => {
                  console.log('delete account', account);
                  e.stopPropagation();
                  setDeleting(true);
                }}
                color="red" />
            </XStack>
          </XStack>
        </YStack>
      </Card.Footer>
      <Card.Background>
        <XStack h='100%'>
          <YStack h='100%' w={7}
            borderTopLeftRadius='$2' borderBottomLeftRadius='$2'
            backgroundColor={primaryColor} />
          <YStack h='100%' w={3}
            backgroundColor={navColor} />
          <YStack f={1} />
        </XStack>
      </Card.Background>
    </Card>

    <Dialog open={deleting} onOpenChange={setDeleting}>
      {/* <Dialog.Trigger asChild>
                
              </Dialog.Trigger> */}
      <Dialog.Portal zIndex={1000000000000011}>
        <Dialog.Overlay
          zIndex={1000000000000012}
          key="overlay"
          animation='standard'
          o={0.5}
          enterStyle={{ o: 0 }}
          exitStyle={{ o: 0 }}
        />
        <Dialog.Content
          zIndex={1000000000000013}
          bordered
          elevate
          key="content"
          animation={[
            'standard',
            {
              opacity: {
                overshootClamping: true,
              },
            },
          ]}
          m='$3'
          enterStyle={{ x: 0, y: -20, opacity: 0, scale: 0.9 }}
          exitStyle={{ x: 0, y: 10, opacity: 0, scale: 0.95 }}
          x={0}
          scale={1}
          opacity={1}
          y={0}
        >
          <YStack>
            <Dialog.Title>Remove Account</Dialog.Title>
            {/* <Dialog.Description> */}
            <YStack gap='$2' mt='$2' mb='$3'>
              <Paragraph>
                Really remove account <Text fontWeight='bold'>{account.user.username}@{account.server.host}</Text> from this device?
              </Paragraph>
              <Paragraph>
                The account will remain on {account.server.host}, but your data will be removed from this browser.
              </Paragraph>
              <Paragraph>
                To delete your account and data on {account.server.host}, open the User Settings on your <Anchor {...profileLinkProps}>profile page</Anchor>.
              </Paragraph>
            </YStack>
            {/* </Dialog.Description> */}

            <XStack gap="$3" jc="flex-end">
              <Dialog.Close asChild>
                <Button>Cancel</Button>
              </Dialog.Close>
              <Theme inverse>
                <Button onPress={() => dispatch(removeAccount(accountID(account)!))}>Remove</Button>
              </Theme>
            </XStack>
          </YStack>
        </Dialog.Content>
      </Dialog.Portal>
    </Dialog>
  </>
};

export default AccountCard;
