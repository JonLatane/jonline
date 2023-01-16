import React from "react";
import { StyleSheet, Text, View } from "react-native";
import store from "../store/store";
import { JonlineServer } from "../store/modules/Servers";
import * as Colors from "../styles/Colors";
import * as Spacing from "../styles/Spacing";
import { JonlineAccount } from "../store/modules/Accounts";

interface Props {
  account: JonlineAccount;
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
});

const AccountCard: React.FC<Props> = ({ account }) => {
  let ratingBackground = {};
  if (store.getState().accounts.account.id == account.id) 
    ratingBackground = Styles.selectedBackground;
  // if (funFact.rating === 1) ratingBackground = Styles.likedBackground;
  // else if (funFact.rating === -1) ratingBackground = Styles.dislikedBackground;

  return (
    <View style={[Styles.cardBackground, ratingBackground]}>
      <Text style={Styles.factText}>{account.user.username}</Text>
    </View>
  );
};

export default AccountCard;
