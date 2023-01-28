import React from "react";
import { StyleSheet, Text, View } from "react-native";
import store, { RootState, useTypedDispatch, useTypedSelector } from "../../store/store";
import { JonlineServer, removeServer, selectServer, serverUrl } from "../../store/modules/servers";
import { Dialog, Button, Card, Heading, Paragraph, Theme, XStack, YStack } from "@jonline/ui";
import { Lock, Trash, Unlock } from "@tamagui/lucide-icons";
import Accounts, { removeAccount, selectAccount, selectAllAccounts } from "app/store/modules/accounts";

interface Props {
  server: JonlineServer;
}

const ServerCard: React.FC<Props> = ({ server }) => {
  const dispatch = useTypedDispatch();
  let selected = store.getState().servers.server?.host == server.host;
  const accountsState = useTypedSelector((state: RootState) => state.accounts);
  const accounts = useTypedSelector((state: RootState) => selectAllAccounts(state.accounts))
    .filter(account => account.server.host == server.host);

  function doSelectServer() {
    if (selected) {
      dispatch(selectAccount(undefined));
    } else if (accountsState.account && serverUrl(accountsState.account.server) != serverUrl(server)) {
      dispatch(selectAccount(undefined));
    }
    dispatch(selectServer(server));
  }

  function doRemoveServer() {
    accounts.forEach(account => {
      if (account.server.host == server.host) {
        dispatch(removeAccount(account.id));
      }
    });
    dispatch(removeServer(server));
  }

  return (
    <Theme inverse={selected}>
      <Card theme="dark" elevate size="$4" bordered
        animation="bouncy"
        scale={0.9}
        width={260}
        hoverStyle={{ scale: 0.925 }}
        pressStyle={{ scale: 0.875 }}
        onClick={doSelectServer}>
        <Card.Header>
          <XStack>
            <View style={{ flex: 1 }}>
              <Heading size="$5" style={{ marginRight: 'auto' }}>{server.host}</Heading>
            </View>
            {server.secure ? <Lock /> : <Unlock />}
          </XStack>
        </Card.Header>
        <Card.Footer>
          <XStack width='100%'>
            <YStack style={{ flex: 10 }}>
              <Heading size="$1" style={{ marginRight: 'auto' }}>{accounts.length ? '' : "No "}account{accounts.length == 1 ? '' : 's'}</Heading>
              {server.serviceVersion ? <Heading size="$1" style={{ marginRight: 'auto' }}>{server.serviceVersion?.version}</Heading> : undefined}
            </YStack>
            <Dialog>
              <Dialog.Trigger asChild>
                <Button onClick={(e) => { e.stopPropagation(); }} icon={<Trash />} color="red" />
              </Dialog.Trigger>
              <Dialog.Portal>
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
                      <Button theme="active" onClick={doRemoveServer}>Remove</Button>
                      {/* </Dialog.Action> */}
                    </XStack>
                  </YStack>
                </Dialog.Content>
              </Dialog.Portal>
            </Dialog>
          </XStack>
        </Card.Footer>
        {/* <Card.Background backgroundColor={selected ? '#424242' : undefined} /> */}
      </Card>
    </Theme>
  );
};

export default ServerCard;
