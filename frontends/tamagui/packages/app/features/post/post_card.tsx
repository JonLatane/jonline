import React from "react";
import { StyleSheet, Text, View } from "react-native";
import store, { RootState, useCredentialDispatch, useTypedDispatch, useTypedSelector } from "../../store/store";
import { JonlineServer, removeServer, selectServer } from "../../store/modules/servers";
import { AlertDialog, Button, Card, Heading, Paragraph, Post, Theme, XStack, YStack } from "@jonline/ui";
import { Lock, Trash, Unlock } from "@tamagui/lucide-icons";
import Accounts, { removeAccount, selectAccount, selectAllAccounts } from "app/store/modules/accounts";
import ReactMarkdown from 'react-markdown'

interface Props {
  post: Post;
}

const ServerCard: React.FC<Props> = ({ post }) => {
  const { dispatch, account_or_server } = useCredentialDispatch();
  // let selected = store.getState().servers.server?.host == server.host;
  // const accounts = useTypedSelector((state: RootState) => selectAllAccounts(state.accounts))
  // .filter(account => account.server.host == server.host);

  function doOpenPost() {
    // if (store.getState().accounts.account?.server.host != server.host) {
    //   dispatch(selectAccount(undefined));
    // }
    // dispatch(selectServer(server));
  }

  // function doRemoveServer() {
  //   accounts.forEach(account => {
  //     if (account.server.host == server.host) {
  //       dispatch(removeAccount(account.id));
  //     }
  //   });
  //   dispatch(removeServer(server.host));
  // }

  return (
    <Theme inverse={false}>
      <Card theme="dark" elevate size="$4" bordered
        animation="bouncy"
        scale={0.9}
        width={260}
        hoverStyle={{ scale: 0.925 }}
        pressStyle={{ scale: 0.875 }}
        onClick={doOpenPost}>
        <Card.Header>
          <XStack>
            <View style={{ flex: 1 }}>
              <Heading size="$7" style={{ marginRight: 'auto' }}>{post.title && post.title}</Heading>
            </View>
            {/* {server.secure ? <Lock /> : <Unlock />} */}
          </XStack>
        </Card.Header>
        <Card.Footer>
          <XStack width='100%'>
            <YStack style={{ flex: 10 }}>
            {/* <Heading size="$1" style={{marginRight: 'auto'}}>{accounts.length || "No"} account{ accounts.length == 1 ? '' : 's'}</Heading> */}
            {/* <Heading size="$1" style={{marginRight: 'auto'}}>{server.serviceVersion!.version}</Heading> */}
            {post.content && <Paragraph><ReactMarkdown>{post.content!}</ReactMarkdown></Paragraph>}
            </YStack>
            {/* <AlertDialog native>
              <AlertDialog.Trigger asChild>
                <Button icon={<Trash />} color="red" />
              </AlertDialog.Trigger>
              <AlertDialog.Portal>
                <AlertDialog.Overlay
                  key="overlay"
                  animation="quick"
                  o={0.5}
                  enterStyle={{ o: 0 }}
                  exitStyle={{ o: 0 }}
                />
                <AlertDialog.Content
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
                    <AlertDialog.Title>Remove Server</AlertDialog.Title>
                    <AlertDialog.Description>
                      <Paragraph>
                      Really remove {server.host}{accounts.length == 1 ? ' and one account' : accounts.length > 1 ? ` and ${accounts.length} accounts` : ''}?
                      </Paragraph>
                    </AlertDialog.Description>

                    <XStack space="$3" jc="flex-end">
                      <AlertDialog.Cancel asChild>
                        <Button>Cancel</Button>
                      </AlertDialog.Cancel>
                      <AlertDialog.Action asChild onClick={doRemoveServer}>
                        <Button theme="active">Remove</Button>
                      </AlertDialog.Action>
                    </XStack>
                  </YStack>
                </AlertDialog.Content>
              </AlertDialog.Portal>
            </AlertDialog> */}
          </XStack>
        </Card.Footer>
        {/* <Card.Background backgroundColor={selected ? '#424242' : undefined} /> */}
      </Card>
    </Theme>
  );
};

export default ServerCard;
