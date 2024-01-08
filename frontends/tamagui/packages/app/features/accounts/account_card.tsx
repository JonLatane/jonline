import { Permission } from "@jonline/api";
import { Button, Card, Dialog, Heading, Image, Paragraph, Theme, XStack, YStack, useMedia, useTheme } from "@jonline/ui";
import { AlertCircle, Bot, ChevronDown, ChevronUp, Delete, Shield, User as UserIcon } from "@tamagui/lucide-icons";
import { colorMeta, useAppSelector, useCredentialDispatch, useMediaUrl } from "app/hooks";
import { JonlineAccount, accountID, getServerTheme, moveAccountDown, moveAccountUp, removeAccount, selectAccount, selectServer, serverID, store, useRootSelector } from "app/store";
import { hasAdminPermission, hasPermission } from 'app/utils';
import React from "react";
import { useLink } from "solito/link";
import { ServerNameAndLogo } from "../navigation/server_name_and_logo";

interface Props {
  account: JonlineAccount;
  totalAccounts: number;
  onReauthenticate?: (account: JonlineAccount) => void;
  onProfileOpen?: () => void;
  onPress?: () => void;
  selectedAccount?: JonlineAccount;
}

const AccountCard: React.FC<Props> = ({ account, totalAccounts, onReauthenticate, onProfileOpen, onPress, selectedAccount }) => {
  const { dispatch, accountOrServer: currentAccountOrServer } = useCredentialDispatch();
  const currentAccountId = useAppSelector(state => state.accounts.currentAccountId);
  const selectedAccountId = selectedAccount ? accountID(selectedAccount) : currentAccountId;
  const selected = selectedAccountId == accountID(account);

  const currentServer = currentAccountOrServer.server;
  const isCurrentServer = currentServer &&
    serverID(currentServer) == serverID(account.server);
  // const primaryColorInt = account.server.serverConfiguration?.serverInfo?.colors?.primary;
  // const navColorInt = account.server.serverConfiguration?.serverInfo?.colors?.navigation;
  // const primaryColor = `#${(primaryColorInt)?.toString(16).slice(-6) || '424242'}`;

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

  const theme = useTheme();
  const { primaryColor, navColor, primaryAnchorColor, navTextColor, navAnchorColor } = getServerTheme(account.server, theme);

  const backgroundColor = theme.background.val;
  const { luma: themeBgLuma } = colorMeta(backgroundColor);
  const darkMode = themeBgLuma <= 0.5;
  // const primaryAnchorColor = !darkMode ? primaryColorMeta.darkColor : primaryColorMeta.lightColor;
  // const navAnchorColor = !darkMode ? navColorMeta.darkColor : navColorMeta.lightColor;


  function doSelectAccount() {
    if (account.needsReauthentication && onReauthenticate) {
      onReauthenticate(account);
      return;
    }
    if (currentServer?.host != account.server.host) {
      dispatch(selectServer(account.server));
    }
    dispatch(selectAccount(account));
  }

  function doLogout() {
    dispatch(selectAccount(undefined));
  }
  function moveUp() {
    dispatch(moveAccountUp(accountID(account)!));
  }
  function moveDown() {
    dispatch(moveAccountDown(accountID(account)!));
  }
  const accountIds = useRootSelector(state => state.accounts.ids);
  const canMoveUp = accountIds.indexOf(accountID(account)!) > 0;
  const canMoveDown = accountIds.indexOf(accountID(account)!) < accountIds.length - 1;
  const avatarUrl = useMediaUrl(account.user.avatar?.id, { account, server: account.server });
  const mediaQuery = useMedia();

  const textColor = selected ? navTextColor : undefined;

  const authenticationRequired = <XStack space='$2'>
    <YStack my='auto'><AlertCircle color={navAnchorColor} /></YStack>
    <Paragraph size='$1' color={primaryAnchorColor} alignSelf="center" my='auto'>Reauthentication required.</Paragraph>
  </XStack>;

  return (
    // <Theme inverse={selected}>
    <Card theme="dark" elevate size="$4" bordered
      animation='standard'
      // w={250}
      // h={50}
      backgroundColor={selected ? navColor : undefined}
      scale={0.9}
      // hoverStyle={{ scale: 0.925 }}
      pressStyle={{ scale: 0.925 }}
      onPress={onPress ?? doSelectAccount}
    >
      <Card.Header>
        <XStack>
          {isCurrentServer ? undefined
            : <>
              <YStack w={50} h={50} my='auto' jc='center' ai='center' ac='center'>
                <ServerNameAndLogo server={account.server} shrinkToSquare />
              </YStack>
              <Heading my='auto' mx='$2' size='$7' color={selected ? navTextColor : undefined}>/</Heading>
            </>}
          {(avatarUrl && avatarUrl != '') ?

            <XStack w={mediaQuery.gtXs || true ? 50 : 26} h={mediaQuery.gtXs || true ? 50 : 26}
              mr={mediaQuery.gtXs || true ? '$3' : '$2'}>
              <Image
                pos="absolute"
                width={mediaQuery.gtXs || true ? 50 : 26}
                // opacity={0.25}
                height={mediaQuery.gtXs || true ? 50 : 26}
                borderRadius={mediaQuery.gtXs || true ? 25 : 13}
                resizeMode="cover"
                als="flex-start"
                source={{ uri: avatarUrl, width: mediaQuery.gtXs || true ? 50 : 26, height: mediaQuery.gtXs || true ? 50 : 26 }}
              // blurRadius={1.5}
              // borderRadius={5}
              />
            </XStack>
            : undefined}
          <YStack f={1}>
            <Heading size="$1" color={textColor} mr='auto'>{account.server.host}/</Heading>
            <Heading size="$7" color={textColor} mr='auto'>{account.user.username}</Heading>
            {account.needsReauthentication
              // ? authenticationRequired
              ? (onReauthenticate
                ? <Button mt='$2' mr='auto' h='auto' py='$3' onPress={(e) => { e.stopPropagation(); onReauthenticate(account); }}>
                  {authenticationRequired}
                </Button>
                : <XStack mt='$2' borderColor={textColor} borderWidth='$1' mr='auto' p='$2' borderRadius='$2'>
                  {authenticationRequired}
                </XStack>)
              : undefined}
          </YStack>
          {/* {account.server.secure ? <Lock/> : <Unlock/>} */}
          {hasAdminPermission(account.user) ? <Shield color={textColor} /> : undefined}
          {hasPermission(account.user, Permission.RUN_BOTS) ? <Bot color={textColor} /> : undefined}

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
            {selected && !onPress
              ? <Button onPress={(e) => { e.stopPropagation(); doLogout(); }} mr='$2'>Logout</Button>
              : undefined}
            {totalAccounts > 1 && (!selected || onPress || mediaQuery.gtXxxs)
              ? <XStack my='auto' space='$2' mr='$2'>
                <Button disabled={!canMoveUp} o={canMoveUp ? 1 : 0.5} size='$2' onPress={(e) => { e.stopPropagation(); moveUp(); }} icon={ChevronUp} circular />
                <Button disabled={!canMoveDown} o={canMoveDown ? 1 : 0.5} size='$2' onPress={(e) => { e.stopPropagation(); moveDown(); }} icon={ChevronDown} circular />
              </XStack>
              : undefined}

            <Button circular {...profileLinkProps} icon={<UserIcon />} mr='$2' />
            <Dialog>
              <Dialog.Trigger asChild>
                <Button icon={<Delete />} circular onPress={(e) => { e.stopPropagation(); }} color="red" />
              </Dialog.Trigger>
              <Dialog.Portal zi={1000011}>
                <Dialog.Overlay
                  key="overlay"
                  animation="quick"
                  o={0.5}
                  enterStyle={{ o: 0 }}
                  exitStyle={{ o: 0 }}
                />
                <Dialog.Content
                  bordered
                  elevate
                  key="content"
                  animation={[
                    'quick',
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
                  <YStack space>
                    <Dialog.Title>Remove Account</Dialog.Title>
                    <Dialog.Description>
                      Really remove account {account.user.username} on {account.server.host}?
                      The account will remain on {account.server.host}, but you will have to login
                      in this browser again.
                    </Dialog.Description>

                    <XStack space="$3" jc="flex-end">
                      <Dialog.Close asChild>
                        <Button>Cancel</Button>
                      </Dialog.Close>
                      {/* <Dialog.Action asChild> */}
                      <Theme inverse>
                        <Button onPress={() => dispatch(removeAccount(accountID(account)!))}>Remove</Button>
                      </Theme>
                      {/* </Dialog.Action> */}
                    </XStack>
                  </YStack>
                </Dialog.Content>
              </Dialog.Portal>
            </Dialog>
          </XStack>
        </YStack>
      </Card.Footer>
      {/* {!selected
        ?  */}
      <Card.Background>
        <XStack h='100%'>
          <YStack h='100%' w={5}
            borderTopLeftRadius={20} borderBottomLeftRadius={20}
            backgroundColor={primaryColor} />
          <YStack h='100%' w={5}
            backgroundColor={navColor} />
        </XStack>
      </Card.Background>
      {/* : undefined} */}
    </Card>
  );
};

export default AccountCard;
