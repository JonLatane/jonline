import { createNativeStackNavigator } from '@react-navigation/native-stack'
import React from 'react'

import { Heading, Theme } from '@jonline/ui'
import { AboutScreen } from 'app/features/about/screen'
import { AccountsSheet } from 'app/features/accounts/accounts_sheet'
import { GroupDetailsScreen } from 'app/features/groups/details_screen'
import { PostDetailsScreen } from 'app/features/post/details_screen'
import { UsernameDetailsScreen } from 'app/features/user/username_details_screen'
import { RootState, useTypedSelector } from 'app/store'
import { HomeScreen } from '../../features/home/screen'
import { UserDetailsScreen } from '../../features/user/details_screen'
import { MainPeopleScreen, FollowRequestsScreen } from 'app/features/people/screen';

const Stack = createNativeStackNavigator<{
  home: undefined,
  about: undefined,
  userDetails: {
    id: string
  },
  usernameDetails: {
    username: string
  },
  accountDetails: {
    id: string
  },
  postDetails: {
    postId: string
  },
  groupDetails: {
    shortname: string
  },
  groupPostDetails: {
    shortname: string,
    postId: string
  },
  people: undefined,
  followRequests: undefined,
}>()

export function NativeNavigation() {
  let server = useTypedSelector((state: RootState) => state.servers.server);
  let account = useTypedSelector((state: RootState) => state.accounts.account);
  let backgroundColorInt = server?.serverConfiguration?.serverInfo?.colors?.primary;
  let backgroundColor = `#${(backgroundColorInt)?.toString(16).slice(-6) || '424242'}`;
  let navColorInt = server?.serverConfiguration?.serverInfo?.colors?.navigation;
  let navColor = `#${(navColorInt)?.toString(16).slice(-6) || 'fff'}`;
  let headerStyle = { backgroundColor, };
  // let accountsButton = <Button icon={UserIcon} onClick={()=>{}} size='$2' />;
  let accountsButton = <Theme name='dark'>
    <AccountsSheet size='$3' circular />
  </Theme>;

  let defaultOptions = {
    headerStyle,
    // headerLargeTitle: true,
    headerRight: () => accountsButton,
    headerTintColor: navColor,
    headerTitle: ({ children }) => <Heading>{children}</Heading>,

    // headerRightContainerStyle: { paddingRight: 25 },
  }
  return (
    <Stack.Navigator>
      <Stack.Screen
        name="home"
        component={HomeScreen}
        options={{
          title: 'Home',
          ...defaultOptions,
        }}
      />
      <Stack.Screen
        name="about"
        component={AboutScreen}
        options={{
          title: 'About',
          ...defaultOptions,
        }}
      />
      <Stack.Screen
        name="userDetails"
        component={UserDetailsScreen}
        options={{
          title: 'User Profile',
          ...defaultOptions,
        }}
      />
      <Stack.Screen
        name="usernameDetails"
        component={UsernameDetailsScreen}
        options={{
          title: 'User Profile',
          ...defaultOptions,
        }}
      />
      <Stack.Screen
        name="accountDetails"
        component={UserDetailsScreen}
        options={{
          title: 'Account Profile',
          ...defaultOptions,
        }}
      />
      <Stack.Screen
        name="postDetails"
        component={PostDetailsScreen}
        options={{
          title: 'Post Details',
          ...defaultOptions,
        }}
      />
      <Stack.Screen
        name="groupDetails"
        component={GroupDetailsScreen}
        options={{
          title: 'Group Details',
          ...defaultOptions,
        }}
      />
      <Stack.Screen
        name="groupPostDetails"
        component={PostDetailsScreen}
        options={{
          title: 'Group Post Details',
          ...defaultOptions,
        }}
      />
      <Stack.Screen
        name="people"
        component={MainPeopleScreen}
        options={{
          title: 'People',
          ...defaultOptions,
        }}
      />
      <Stack.Screen
        name="followRequests"
        component={FollowRequestsScreen}
        options={{
          title: 'Follow Requests',
          ...defaultOptions,
        }}
      />
    </Stack.Navigator>
  )
}
