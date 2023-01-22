import React from "react";
import { StyleSheet, Text, View } from "react-native";
import store, { useTypedDispatch } from "../../store/store";
import { JonlineServer, selectServer } from "../../store/modules/Servers";
import { Card, Heading, XStack } from "@jonline/ui";
import { Lock, Unlock } from "@tamagui/lucide-icons";

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
          <Heading size="$3" style={{flex: 1}}>{server.host}</Heading>
          {server.secure ? <Lock/> : <Unlock/>}
      {/* <Heading size="$3" style={{flex: 1}}>{server.serviceVersion!.version}</Heading> */}
        </XStack>
      </Card.Header>
      <Card.Footer>
        <XStack alignContent="flex-end">
          <Heading size="$1">{server.serviceVersion!.version}</Heading>
        </XStack>
      </Card.Footer>
      <Card.Background backgroundColor={selected ? '#424242' : undefined}/>
    </Card>
    // <a style={Styles.borderlessButton} onClick={() => dispatch(selectServer(server))}>
    // </a>
  );
};

export default ServerCard;
