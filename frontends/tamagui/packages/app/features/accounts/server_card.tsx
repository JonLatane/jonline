import { Button, Card, Dialog, Heading, Theme, XStack, YStack } from "@jonline/ui";
import { Info, Lock, Trash, Unlock } from "@tamagui/lucide-icons";
import { store, JonlineServer, removeAccount, removeServer, RootState, selectAccount, selectAllAccounts, selectServer, serverID, useTypedDispatch, useTypedSelector, accountId } from "app/store";
import React from "react";
import { useLink } from "solito/link";
import { ServerNameAndLogo } from "../tabs/server_name_and_logo";

interface Props {
  server: JonlineServer;
  isPreview?: boolean;
}

const ServerCard: React.FC<Props> = ({ server, isPreview = false }) => {
  const dispatch = useTypedDispatch();
  const selected = store.getState().servers.server?.host == server.host;
  const accountsState = useTypedSelector((state: RootState) => state.accounts);
  const accounts = useTypedSelector((state: RootState) => selectAllAccounts(state.accounts))
    .filter(account => account.server.host == server.host);
  const infoLink = useLink({ href: `/server/${serverID(server)}` });
  const primaryColorInt = server.serverConfiguration?.serverInfo?.colors?.primary;
  const primaryColor = `#${(primaryColorInt)?.toString(16).slice(-6) || '424242'}`;

  function doSelectServer() {
    if (selected) {
      dispatch(selectAccount(undefined));
    } else if (accountsState.account && serverID(accountsState.account.server) != serverID(server)) {
      dispatch(selectAccount(undefined));
    }
    dispatch(selectServer(server));
  }

  function doRemoveServer() {
    accounts.forEach(account => {
      if (account.server.host == server.host) {
        dispatch(removeAccount(accountId(account)!));
      }
    });
    dispatch(removeServer(server));
  }

  return (
    <Theme inverse={selected}>
      <Card theme="dark" elevate size="$4" bordered
        animation='standard'
        scale={0.9}
        width={isPreview ? 260 : '100%'}
        hoverStyle={{ scale: 0.925 }}
        pressStyle={{ scale: 0.875 }}
        onPress={doSelectServer}>
        <Card.Header>
          <XStack>
            <YStack f={1}>
              {/* <Heading marginRight='auto' whiteSpace="nowrap" width='100%' overflow="hidden" textOverflow="ellipsis"
              opacity={server.serverConfiguration?.serverInfo?.name ? 1 : 0.5}>{server.serverConfiguration?.serverInfo?.name || 'Unnamed'}</Heading> */}
              {/* <XStack h={48}> */}
                <ServerNameAndLogo server={server} />
              {/* </XStack> */}
              <Heading size="$1" marginRight='auto'>{server.host}</Heading>
            </YStack>
            {isPreview ? <Button onPress={(e) => { e.stopPropagation(); infoLink.onPress(e); }} icon={<Info />} circular /> : undefined}
          </XStack>
        </Card.Header>
        <Card.Footer p='$3'>
          <XStack width='100%'>
            <YStack mt='$2' mr='$3'>
              {server.secure ? <Lock /> : <Unlock />}
            </YStack>
            <YStack f={10}>
              <Heading size="$1" mr='auto'>{accounts.length > 0 ? accounts.length : "No "} account{accounts.length == 1 ? '' : 's'}</Heading>
              {server.serviceVersion ? <Heading size="$1" mr='auto'>{server.serviceVersion?.version}</Heading> : undefined}
            </YStack>
            {isPreview
              ? <Dialog>
                <Dialog.Trigger asChild>
                  <Button onPress={(e) => { e.stopPropagation(); }} icon={<Trash />} color="red" circular />
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
                      <Dialog.Title>Remove Server</Dialog.Title>
                      <Dialog.Description>
                        {/* <Paragraph> */}
                        Really remove {server.host}{accounts.length == 1 ? ' and one account' : accounts.length > 1 ? ` and ${accounts.length} accounts` : ''}?
                        {/* </Paragraph> */}
                      </Dialog.Description>

                      <XStack space="$3" jc="flex-end">
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
              : undefined
            }
          </XStack>
        </Card.Footer>
        <Card.Background>
          <YStack h='100%' w={5} backgroundColor={primaryColor} />
        </Card.Background>
      </Card>
    </Theme>
  );
};

export default ServerCard;
