import { Button, Card, Dialog, Heading, Theme, XStack, YStack, standardHorizontalAnimation, Paragraph } from '@jonline/ui';
import { AlertCircle, ChevronLeft, ChevronRight, ExternalLink, Info, Lock, Trash, Unlock } from "@tamagui/lucide-icons";
import { colorMeta, useCurrentAccountOrServer, useAppDispatch, useAppSelector, useLocalConfiguration } from "app/hooks";
import { JonlineServer, RootState, accountID, moveServerDown, moveServerUp, removeAccount, removeServer, selectAccount, selectAllAccounts, selectServer, serverID, useRootSelector, selectAccountById } from 'app/store';
import React, { useState } from "react";
import { useLink } from "solito/link";
import { ServerNameAndLogo } from "../navigation/server_name_and_logo";

interface Props {
  server: JonlineServer;
  isPreview?: boolean;
  linkToServerInfo?: boolean;
  disableHeightLimit?: boolean;
  disableFooter?: boolean;
  disablePress?: boolean;
}

const ServerCard: React.FC<Props> = ({ server, isPreview = false, linkToServerInfo = false, disableHeightLimit, disableFooter = false, disablePress = false }) => {
  const dispatch = useAppDispatch();
  const { account: currentAccount, server: currentServer } = useCurrentAccountOrServer();
  const selected = currentServer?.host == server.host;
  const serversState = useRootSelector((state: RootState) => state.servers);
  const accountsState = useRootSelector((state: RootState) => state.accounts);
  const accounts = useRootSelector((state: RootState) => selectAllAccounts(state.accounts))
    .filter(account => account.server.host == server.host);
  const infoLink = useLink({ href: `/server/${serverID(server)}` });
  const primaryColorInt = server.serverConfiguration?.serverInfo?.colors?.primary;
  const primaryColor = `#${(primaryColorInt)?.toString(16).slice(-6) || '424242'}`;
  const primaryColorMeta = colorMeta(primaryColor);

  function moveUp() {
    requestAnimationFrame(() => dispatch(moveServerUp(serverID(server)!)));
  }
  function moveDown() {
    requestAnimationFrame(() => dispatch(moveServerDown(serverID(server)!)));
  }
  const canMoveUp = serversState.ids.indexOf(serverID(server)!) > 0;
  const canMoveDown = serversState.ids.indexOf(serverID(server)!) < serversState.ids.length - 1;
  const pinnedAccountId = useAppSelector(state =>
    state.accounts.pinnedServers.find(ps => ps.serverId == serverID(server))?.accountId);
  const pinnedAccount = useAppSelector(state => pinnedAccountId
    ? selectAccountById(state.accounts, pinnedAccountId)
    : undefined);
  function doSelectServer() {
    // if (selected) {
    //   dispatch(selectAccount(undefined));
    // } else if (currentAccount && serverID(currentAccount.server) != serverID(server)) {
    //   dispatch(selectAccount(undefined));
    // }
    if (linkToServerInfo) {
      infoLink.onPress();
    }
    dispatch(selectServer(server));
    // if (pinnedAccount) {
    //   dispatch(selectAccount(pinnedAccount));
    // }
  }

  function doRemoveServer() {
    accounts.forEach(account => {
      if (account.server.host == server.host) {
        dispatch(removeAccount(accountID(account)!));
      }
    });
    dispatch(removeServer(server));
  }

  const externalLink = useLink({ href: `${server.secure ? 'https' : 'http'}://${server.host}` });
  const browserHost = window.location.host.split(':')[0];
  const serverIsExternal = server.host != browserHost;
  const textColor = selected ? primaryColorMeta.textColor : undefined;

  const { allowServerSelection } = useLocalConfiguration();
  const pressParams = allowServerSelection || server.host === window?.location?.host ? {
    // pressStyle: { scale: 0.95 },
    onPress: disablePress ? undefined : doSelectServer
  } : {}

  const [deleting, setDeleting] = useState(false);
  return <>
    <Card theme="dark" size="$4" bordered
      animation='standard'
      // {...standardHorizontalAnimation}
      scale={0.9}
      backgroundColor={selected ? primaryColor : undefined}
      width={isPreview ? 280 : '100%'}
      {...pressParams}>
      <Card.Header>
        <XStack w='100%'>
          <YStack f={1} overflow="hidden">
            <YStack maxHeight={disableHeightLimit ? undefined : 128} overflow="hidden">
              {/* <Heading marginRight='auto' whiteSpace="nowrap" width='100%' overflow="hidden" textOverflow="ellipsis"
              opacity={server.serverConfiguration?.serverInfo?.name ? 1 : 0.5}>{server.serverConfiguration?.serverInfo?.name || 'Unnamed'}</Heading> */}
              {/* <XStack h={48}> */}
              <ServerNameAndLogo server={server} disableWidthLimits textColor={textColor} />
              {/* </XStack> */}
            </YStack>
            <Heading size="$1" marginRight='auto' color={textColor}>
              {server.host}
            </Heading>
          </YStack>
          {/* <Button icon={<Info />} circular
                onPress={(e) => { e.stopPropagation(); infoLink.onPress(e); }} /> */}
          <YStack ac='flex-end' gap='$2' ml='$1'>
            <XStack jc='flex-end'>
              {serverIsExternal ?
                <Button mx='$1' size='$3' icon={<ExternalLink />} circular
                  {...externalLink} target='_blank'
                  onPress={(e) => { e.stopPropagation(); }} />
                : undefined}
              {isPreview && !linkToServerInfo
                ? <Button ml='$1' size='$3' icon={<Info />} circular {...infoLink}
                  onPress={(e) => { e.stopPropagation(); }} />
                : undefined}
            </XStack>
            {isPreview && serversState.ids.length > 1
              ?
              <XStack jc='flex-end' gap='$2'>
                <Button disabled={!canMoveUp} o={canMoveUp ? 1 : 0.5} size='$2' onPress={(e) => { e.stopPropagation(); moveUp(); }} icon={ChevronLeft} circular />
                <Button disabled={!canMoveDown} o={canMoveDown ? 1 : 0.5} size='$2' onPress={(e) => { e.stopPropagation(); moveDown(); }} icon={ChevronRight} circular />
              </XStack>
              : undefined}
          </YStack>
        </XStack>
      </Card.Header>
      {disableFooter
        ? undefined
        : <Card.Footer p='$3'>
          <YStack w='100%'>
            {server.lastConnectionFailed
              ? <XStack ai='center' gap='$2'>
                <AlertCircle color={textColor} />
                <Paragraph size="$1" color={textColor} opacity={0.5}>
                  Last connection failed.
                </Paragraph>
              </XStack>
              : undefined}
            <XStack width='100%'>
              <YStack mt='$2' mr='$3'>
                {server.secure ? <Lock color={textColor} /> : <Unlock color={textColor} />}
              </YStack>
              <YStack f={10}>
                <Heading size="$1" mr='auto' color={textColor}>
                  {accounts.length > 0
                    ? accounts.length
                    : "No "} account{accounts.length == 1 ? '' : 's'}
                </Heading>
                {server.serviceVersion
                  ? <Heading size="$1" mr='auto' color={textColor}>
                    {server.serviceVersion?.version}
                  </Heading>
                  : undefined}
              </YStack>
              {isPreview && serverIsExternal && serversState.ids.length > 1
                ? <Button onPress={(e) => {
                  e.stopPropagation();
                  setDeleting(true);
                }} icon={<Trash />} color="red" circular />

                : undefined
              }
            </XStack>
          </YStack>
        </Card.Footer>
      }
      {
        !selected
          ? <Card.Background>
            <YStack h='100%' w={5}
              borderTopLeftRadius={20} borderBottomLeftRadius={20}
              backgroundColor={primaryColor} />
          </Card.Background>
          : undefined
      }
    </Card >
    < Dialog open={deleting} onOpenChange={setDeleting}>
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
          <YStack space>
            <Dialog.Title>Remove Server</Dialog.Title>
            <Dialog.Description>
              {/* <Paragraph> */}
              Really remove {server.host}{accounts.length == 1 ? ' and one account' : accounts.length > 1 ? ` and ${accounts.length} accounts` : ''}?
              {/* </Paragraph> */}
            </Dialog.Description>

            <XStack gap="$3" jc="flex-end">
              <Dialog.Close asChild>
                <Button>Cancel</Button>
              </Dialog.Close>
              {/* <Dialog.Action asChild onClick={doRemoveServer}> */}
              <Theme inverse>
                <Button onPress={doRemoveServer}>Remove</Button>
              </Theme>
              {/* </Dialog.Action> */}
            </XStack>
          </YStack>
        </Dialog.Content>
      </Dialog.Portal>
    </Dialog>
  </>;
};

export default ServerCard;
