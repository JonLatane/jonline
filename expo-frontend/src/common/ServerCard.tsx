import React from "react";
import { StyleSheet, Text, View } from "react-native";
import store, { useTypedDispatch } from "../store/store";
import { JonlineServer, selectServer } from "../store/modules/Servers";
import * as Colors from "../styles/Colors";
import * as Spacing from "../styles/Spacing";

interface Props {
  server: JonlineServer;
}

const Styles = StyleSheet.create({
  cardBackground: {
    width: "100%",
    borderWidth: 1,
    borderRadius: 8,
    backgroundColor: Colors.SECONDARY,
    borderColor: Colors.PRIMARY,
    ...Spacing.padding,
    ...Spacing.marginVertical,
  },
  selectedBackground: {
    backgroundColor: "#a9ff9e",
    borderColor: "#129e00",
  },
  // dislikedBackground: {
  //   backgroundColor: "#ff866e",
  //   borderColor: "#cf2200",
  // },
  factText: {
    color: "black",
    fontSize: 20,
  },
  borderlessButton: {
    padding: 0,
    background: 'none',
    border: 'none',
    outline: 'none',
  }
});

const ServerCard: React.FC<Props> = ({ server }) => {
  const dispatch = useTypedDispatch();
  let background = {};
  if (store.getState().servers.server.host == server.host) {
    background = Styles.selectedBackground;
  }

  return (
    <a style={Styles.borderlessButton} onClick={() => dispatch(selectServer(server))}>
      <View style={[Styles.cardBackground, background]}>
        <Text style={Styles.factText}>{server.host}</Text>
      </View>
    </a>
  );
};

export default ServerCard;
