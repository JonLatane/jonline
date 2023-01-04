import * as React from "react";
import { NavigationContainer } from "@react-navigation/native";
import { createBottomTabNavigator } from "@react-navigation/bottom-tabs";
import HomeScreen from "../views/Home";
import HistoryScreen from "../views/History";

const Tab = createBottomTabNavigator();

export default function Navigator() {
  return (
    <NavigationContainer>
      <Tab.Navigator
        // tabBarOptions={{
        //   style: { backgroundColor: "black" },
        //   keyboardHidesTabBar: true,
        //   labelStyle: { fontSize: 24, color: "white" },
        // }}
        screenOptions={{
          "tabBarHideOnKeyboard": true,
          "tabBarLabelStyle": {
            "fontSize": 24,
            "color": "white"
          },
          "tabBarStyle": [
            {
              "display": "flex"
            },
            null
          ]
        }}
      >
        <Tab.Screen name="Home" component={HomeScreen} />
        <Tab.Screen name="History" component={HistoryScreen} />
      </Tab.Navigator>
    </NavigationContainer>
  );
}
