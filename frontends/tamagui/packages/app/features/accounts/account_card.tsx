import React from "react";
import { StyleSheet, View } from "react-native";
import store, { useTypedDispatch } from "../../store/store";
import { JonlineServer, selectServer } from "../../store/modules/servers";
import { JonlineAccount, removeAccount, selectAccount } from "../../store/modules/accounts";
import { Card, Heading, XStack, YStack, Text, Paragraph, Dialog, Button, Theme } from "@jonline/ui";
import { Lock, Shield, ShieldCheck, ShieldClose, Trash, Unlock } from "@tamagui/lucide-icons";
import { Permission } from "@jonline/ui/src";

interface Props {
  account: JonlineAccount;
}

const AccountCard: React.FC<Props> = ({ account }) => {
  const dispatch = useTypedDispatch();
  let selected = store.getState().accounts.account?.id == account.id;

  function doSelectAccount() {
    if (store.getState().servers.server?.host != account.server.host) {
      dispatch(selectServer(account.server));
    }
    dispatch(selectAccount(account));
  }
  return (
    <Theme inverse={selected}>
      <Card theme="dark" elevate size="$4" bordered

        animation="bouncy"
        // w={250}
        // h={50}
        scale={0.9}
        hoverStyle={{ scale: 0.925 }}
        pressStyle={{ scale: 0.875 }}
        onClick={doSelectAccount}>
        <Card.Header>
          <XStack>
            <YStack style={{ flex: 1 }}>
              <Heading size="$1" style={{ marginRight: 'auto' }}>{account.server.host}/</Heading>
              <Heading size="$7" style={{ marginRight: 'auto' }}>{account.user.username}</Heading>
            </YStack>
            {/* {account.server.secure ? <Lock/> : <Unlock/>} */}
            {account.user.permissions.includes(Permission.ADMIN) && <Shield />}
          </XStack>
        </Card.Header>
        <Card.Footer>
          <XStack width='100%'>
            <YStack>
              <Heading size="$1" alignSelf="center">Account ID</Heading>
              <Paragraph size='$1' alignSelf="center">{account.user.id}</Paragraph>
            </YStack>
            <View style={{ flex: 1 }} />

            <Dialog>
              <Dialog.Trigger asChild>
                <Button icon={<Trash />} color="red" />
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
                    <Dialog.Title>Remove Account</Dialog.Title>
                    <Dialog.Description>
                      Really remove account {account.user.username} on {account.server.host}?
                    </Dialog.Description>

                    <XStack space="$3" jc="flex-end">
                      <Dialog.Close asChild>
                        <Button>Cancel</Button>
                      </Dialog.Close>
                      {/* <Dialog.Action asChild> */}
                        <Button theme="active" onClick={() => dispatch(removeAccount(account.id))}>Remove</Button>
                      {/* </Dialog.Action> */}
                    </XStack>
                  </YStack>
                </Dialog.Content>
              </Dialog.Portal>
            </Dialog>
          </XStack>
        </Card.Footer>
      </Card>
    </Theme>
    // <a style={Styles.borderlessButton} onClick={() => dispatch(selectServer(server))}>
    // </a>
  );
};

export default AccountCard;
