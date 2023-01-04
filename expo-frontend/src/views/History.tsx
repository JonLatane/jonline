import React from "react";
import { FlatList, StyleSheet, Text } from "react-native";
import * as Colors from "../styles/Colors";
import * as Spacing from "../styles/Spacing";
import FunFactCard from "../common/FunFactCard";
import { useTypedSelector } from "../store";
import { selectAllFacts } from "../store/modules/Facts";

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

const HistoryScreen: React.FC = () => {
  const funFacts = useTypedSelector((state) => selectAllFacts(state.facts));

  return (
    <FlatList
      data={funFacts}
      keyExtractor={(funFact) => funFact.fact}
      ListHeaderComponent={<Text style={Styles.headerText}>History</Text>}
      renderItem={({ item }) => {
        return <FunFactCard funFact={item} />;
      }}
      style={Styles.trueBackground}
      contentContainerStyle={Styles.contentBackground}
    />
  );
};

export default HistoryScreen;
