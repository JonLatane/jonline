import React from "react";
import { StyleSheet, Text, View } from "react-native";
import store, { useTypedDispatch } from "../../store/store";
import { JonlineServer, removeServer, selectServer } from "../../store/modules/Servers";
import { AlertDialog, Button, Card, Heading, XStack, YStack } from "@jonline/ui";
import { Lock, Trash, Unlock } from "@tamagui/lucide-icons";

interface Props {
  server: JonlineServer;
}

const ServerCard: React.FC<Props> = ({ server }) => {
  const dispatch = useTypedDispatch();
  let selected = store.getState().servers.server?.host == server.host;

  return (
    <Card theme="dark" elevate size="$4" bordered

      animation="bouncy"
      // w={250}
      // h={50}
      scale={0.9}
      hoverStyle={{ scale: 0.925 }}
      pressStyle={{ scale: 0.875 }}
      onClick={() => dispatch(selectServer(server))}>
      <Card.Header>
        <XStack>
          <Heading size="$3" style={{ flex: 1 }}>{server.host}</Heading>
          {server.secure ? <Lock /> : <Unlock />}
          {/* <Heading size="$3" style={{flex: 1}}>{server.serviceVersion!.version}</Heading> */}
        </XStack>
      </Card.Header>
      <Card.Footer>
        <XStack width='100%'>
          <Heading size="$1" style={{ flex: 10 }}>{server.serviceVersion!.version}</Heading>
          <AlertDialog native>
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
                    Are you sure you want to remove this server?
                  </AlertDialog.Description>

                  <XStack space="$3" jc="flex-end">
                    <AlertDialog.Cancel asChild>
                      <Button>Cancel</Button>
                    </AlertDialog.Cancel>
                    <AlertDialog.Action asChild>
                      <Button theme="active" onClick={() => dispatch(removeServer(server.host))}>Remove</Button>
                    </AlertDialog.Action>
                  </XStack>
                </YStack>
              </AlertDialog.Content>
            </AlertDialog.Portal>
          </AlertDialog>
        </XStack>
      </Card.Footer>
      <Card.Background backgroundColor={selected ? '#424242' : undefined} />
    </Card>
  );
};

export default ServerCard;
