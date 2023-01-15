import React from "react";
import { StatusBar, StyleSheet, View } from "react-native";
import { Provider } from "react-redux";
import store, { persistor } from "./src/store/store";
import Navigator from "./src/navigations/navigations";
import { PersistGate } from 'redux-persist/integration/react'

// import 'localstorage-polyfill';

const Styles = StyleSheet.create({
  statusBarContainer: {
    width: "100%",
    height: 20,
    backgroundColor: "black",
  },
});

export default function App() {
  return (
    <Provider store={store}>
      <PersistGate loading={null} persistor={persistor}>
        <View style={Styles.statusBarContainer}>
          <StatusBar barStyle="light-content" />
        </View>
        <Navigator />
      </PersistGate>
    </Provider>
  );
}


// import { StatusBar } from 'expo-status-bar';
// import { StyleSheet, Text, View } from 'react-native';
// import { Provider } from 'react-redux';
// import { PersistGate } from 'redux-persist/integration/react';

// export default function App() {
//   return (
//     <Provider>
//         <PersistGate>
//             <View style={styles.container}>
//                 <Navigator />
//             </View>
//         </PersistGate>
//     </Provider>
//     // <View style={styles.container}>
//     //   <Text>Open up App.js to start working on your app!</Text>
//     //   <StatusBar style="auto" />
//     // </View>
//   );
// }

// const styles = StyleSheet.create({
//   container: {
//     flex: 1,
//     backgroundColor: '#fff',
//     alignItems: 'center',
//     justifyContent: 'center',
//   },
// });
