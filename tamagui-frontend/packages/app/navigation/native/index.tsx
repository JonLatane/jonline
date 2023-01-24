import React from 'react'
import { createNativeStackNavigator } from '@react-navigation/native-stack'

import { HomeScreen } from '../../features/home/screen'
import { UserDetailsScreen } from '../../features/user/details_screen'
import { PostDetailsScreen } from 'app/features/post/details_screen'

const Stack = createNativeStackNavigator<{
  home: undefined,
  userDetails: {
    id: string
  },
  accountDetails: {
    id: string
  },
  postDetails: {
    id: string
  }
}>()

export function NativeNavigation() {
  return (
    <Stack.Navigator>
      <Stack.Screen
        name="home"
        component={HomeScreen}
        options={{
          title: 'Home',
        }}
      />
      <Stack.Screen
        name="userDetails"
        component={UserDetailsScreen}
        options={{
          title: 'User Profile',
        }}
      />
      <Stack.Screen
        name="accountDetails"
        component={UserDetailsScreen}
        options={{
          title: 'Account Profile',
        }}
      />
      <Stack.Screen
        name="postDetails"
        component={PostDetailsScreen}
        options={{
          title: 'Post Details',
        }}
      />
    </Stack.Navigator>
  )
}
