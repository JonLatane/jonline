import React from "react";
import { FlatList, StyleSheet, Text } from "react-native";
import * as Colors from "../styles/Colors";
import * as Spacing from "../styles/Spacing";
import FunFactCard from "../common/FunFactCard";
import { RootState, useTypedSelector } from "../store/store";
import { selectAllFacts } from "../store/modules/Facts";
import { selectAllServers } from "../store/modules/Servers";
import ServerCard from "../common/ServerCard";

const Styles = StyleSheet.create({
  trueBackground: {
    flex: 1,
    backgroundColor: Colors.DARK,
  },
  contentBackground: {
    ...Spacing.largePadding,
  },
  headerText: {
    color: Colors.PRIMARY,
    fontSize: 24,
    fontWeight: "bold",
  },
});

const AccountsScreen: React.FC = () => {
  const servers = useTypedSelector((state: RootState) => selectAllServers(state.servers));
  // debugger;
  return (
    <>
      <FlatList
        data={servers}
        keyExtractor={(server) => server.host}
        ListHeaderComponent={<Text style={Styles.headerText}>Servers</Text>}
        renderItem={({ item }) => {
          return <ServerCard server={item} />;
        }}
        style={Styles.trueBackground}
        contentContainerStyle={Styles.contentBackground}
      />
      <FlatList
        data={servers}
        keyExtractor={(server) => server.host}
        ListHeaderComponent={<Text style={Styles.headerText}>Accounts</Text>}
        renderItem={({ item }) => {
          return <ServerCard server={item} />;
        }}
        style={Styles.trueBackground}
        contentContainerStyle={Styles.contentBackground}
      />
    </>
  );
};

export default AccountsScreen;
