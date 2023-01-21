import React from "react";
import { StyleSheet, Text, View } from "react-native";
import store, { useTypedDispatch } from "../../store/store";
import { JonlineServer, selectServer } from "../../store/modules/Servers";
import { Card } from "@jonline/ui";
// import * as Colors from "../styles/Colors";
// import * as Spacing from "../styles/Spacing";

interface Props {
  server: JonlineServer;
}

const ServerCard: React.FC<Props> = ({ server }) => {
  const dispatch = useTypedDispatch();
  let selected = store.getState().servers.server?.host == server.host;

  return (
    <Card theme="dark" elevate size="$4" bordered

    animation="bouncy"
    w={250}
    h={50}
    scale={0.9}
    hoverStyle={{ scale: 0.925 }}
    pressStyle={{ scale: 0.875 }}
    onClick={() => dispatch(selectServer(server))}>
      <Card.Header><Text>{server.host}</Text></Card.Header>
      <Card.Background backgroundColor={selected ? '#424242' : undefined}/>
    </Card>
    // <a style={Styles.borderlessButton} onClick={() => dispatch(selectServer(server))}>
    // </a>
  );
};

export default ServerCard;
