import React, { useState } from "react";
import {
  Button,
  Keyboard,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from "react-native";
import * as Colors from "../styles/Colors";
import * as Spacing from "../styles/Spacing";
import FunFactCard from "../common/FunFactCard";
import { useTypedDispatch, useTypedSelector } from "../store";
import { upsertFact, getNewFact } from "../store/modules/Facts";
import { useEffect } from "react";

const Styles = StyleSheet.create({
  background: {
    flex: 1,
    backgroundColor: Colors.DARK,
    ...Spacing.largePadding,
  },
  inputPromptContainer: {
    flex: 1,
  },
  enterANumberText: {
    color: Colors.PRIMARY,
    fontSize: 24,
    fontWeight: "bold",
  },
  inputContainer: {
    ...Spacing.marginVertical,
    ...Spacing.padding,
    backgroundColor: Colors.LIGHT,
    color: "black",
    fontSize: 18,
    borderRadius: 8,
  },
  feedbackContainer: {
    flexDirection: "row",
    width: "100%",
  },
  feedbackButton: {
    flex: 1,
    justifyContent: "center",
    alignItems: "center",
  },
  feebackButtonText: {
    fontSize: 30,
    fontWeight: "bold",
  },
});

const HomeScreen: React.FC = () => {
  // Store values
  const dispatch = useTypedDispatch();
  const pendingFact = useTypedSelector((state) => state.facts.pendingFact);
  const factError = useTypedSelector((state) => state.facts.error);

  // State variables
  const [num, setNum] = useState(6);

  // Respond to the factError changing
  useEffect(() => {
    if (factError) {
      alert(factError.message);
    }
  }, [factError]);

  return (
    <View style={Styles.background}>
      <View style={Styles.inputPromptContainer}>
        <Text style={Styles.enterANumberText}>Enter a number:</Text>
        <TextInput
          value={num >= 0 ? num.toString() : ""}
          onChangeText={(val) => {
            if (val.length) setNum(parseInt(val));
            else setNum(-1);
          }}
          style={Styles.inputContainer}
          keyboardType="number-pad"
        />
        <Button
          title="Submit"
          color={Colors.LIGHT}
          onPress={() => {
            Keyboard.dismiss();
            dispatch(getNewFact(num));
          }}
        />
        {pendingFact && <FunFactCard funFact={pendingFact} />}
      </View>
      <View style={Styles.feedbackContainer}>
        <TouchableOpacity
          style={Styles.feedbackButton}
          onPress={() => {
            if (!pendingFact) return;
            const newFact = {
              ...pendingFact,
              rating: 1 as 1,
            };
            dispatch(upsertFact(newFact));
            dispatch(getNewFact(num));
          }}
        >
          <Text style={[Styles.feebackButtonText, { color: Colors.PRIMARY }]}>
            LIKE
          </Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={Styles.feedbackButton}
          onPress={() => {
            if (!pendingFact) return;
            const newFact = {
              ...pendingFact,
              rating: -1 as -1,
            };
            dispatch(upsertFact(newFact));
            dispatch(getNewFact(num));
          }}
        >
          <Text style={[Styles.feebackButtonText, { color: Colors.SECONDARY }]}>
            DISLIKE
          </Text>
        </TouchableOpacity>
      </View>
    </View>
  );
};

export default HomeScreen;
