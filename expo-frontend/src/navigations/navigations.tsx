import * as React from "react";
import { NavigationContainer } from "@react-navigation/native";
import { BottomTabBar, createBottomTabNavigator } from "@react-navigation/bottom-tabs";
import HomeScreen from "../views/Home";
import HistoryScreen from "../views/History";
import AccountsScreen from "../views/AccountsScreen";
import { Animated } from "react-native";
import { createMaterialBottomTabNavigator } from "@react-navigation/material-bottom-tabs";
import MaterialCommunityIcons from "react-native-vector-icons/MaterialCommunityIcons";

const Tab = createMaterialBottomTabNavigator();

export default function Navigator() {
  return (
    <NavigationContainer>
      <Tab.Navigator
      // tabBarOptions={{}}
        // tabBarOptions={{
        //   style: { backgroundColor: "black" },
        //   keyboardHidesTabBar: true,
        //   labelStyle: { fontSize: 24, color: "white" },
        // }}
        // screenOptions={{
        //   "tabBarHideOnKeyboard": true,
        //   "tabBarLabelStyle": {
        //     "fontSize": 24,
        //     "color": "black"
        //   },
        //   "tabBarStyle": [
        //     {
        //       "display": "flex"
        //     },
        //     null
        //   ]
        // }}
      >
        <Tab.Screen name="accounts" component={AccountsScreen} options={
          {
            title: "Accounts & Servers",

            tabBarIcon: ({ color }) => <MaterialCommunityIcons name="account" color={color} size={26} />
          }} />
        <Tab.Screen name="Home" component={HomeScreen} options={{}} />
        <Tab.Screen name="History" component={HistoryScreen} options={{}} />
      </Tab.Navigator>
    </NavigationContainer>
  );
}
