import { Button, Heading, Text, Paragraph, YStack } from '@jonline/ui'
import { ChevronLeft } from '@tamagui/lucide-icons'
import { loadUsername, RootState, selectUserById, useCredentialDispatch, useTypedSelector } from 'app/store'
import React, { useState, useEffect } from 'react'
import { createParam } from 'solito'
import { useLink } from 'solito/link'
import { TabsNavigation } from '../tabs/tabs_navigation'
import UserCard from './user_card'

const { useParam } = createParam<{ username: string }>()

export function UsernameDetailsScreen() {
  const [username] = useParam('username')
  const linkProps = useLink({ href: '/' })

  const server = useTypedSelector((state: RootState) => state.servers.server);
  const primaryColorInt = server?.serverConfiguration?.serverInfo?.colors?.primary;
  const primaryColor = `#${(primaryColorInt)?.toString(16).slice(-6) || '424242'}`;
  const navColorInt = server?.serverConfiguration?.serverInfo?.colors?.navigation;
  const navColor = `#${(navColorInt)?.toString(16).slice(-6) || 'FFFFFF'}`;
  const userId = useTypedSelector((state: RootState) => username ? state.users.usernameIds[username] : undefined);
  const user = useTypedSelector((state: RootState) =>
    userId ? selectUserById(state.users, userId) : undefined);
  const { dispatch, accountOrServer } = useCredentialDispatch();
  const usersState = useTypedSelector((state: RootState) => state.users);
  const [loadingUser, setLoadingUser] = useState(false);
  const userLoadFailed = usersState.failedUsernames.includes(username!);
  // debugger;

  const isSafari = /^((?!chrome|android).)*safari/i.test(navigator.userAgent);
  const [showScrollPreserver, setShowScrollPreserver] = useState(isSafari);
  useEffect(() => {
    // debugger;
    if (username && (!user || usersState.status == 'unloaded') && !userLoadFailed && !loadingUser) {
      setLoadingUser(true);
      // useEffect(() => {
      console.log('loadUsername', username!)
      setTimeout(() =>
        dispatch(loadUsername({ ...accountOrServer, username: username! })));
      // });
    } else if (loadingUser && (user || userLoadFailed)) {
      setLoadingUser(false);
    }
    if (user && showScrollPreserver) {
      setTimeout(() => setShowScrollPreserver(false), 1500);
    }
  });
  return (
    <TabsNavigation>
      <YStack f={1} jc="center" ai="center" space margin='$3' maw={800} w='100%'>
        {user ? <>
          <UserCard user={user} />
        </>
          : userLoadFailed
            ? <>
              <Heading size='$5' mb='$3'>The profile for <Text fontFamily='$body' fontSize='$7'>{username}</Text> could not be loaded.</Heading>
              <Heading size='$3' ta='center'>They may either not exist, not be visible to you, or be hidden by moderators.</Heading>
            </>
            : <Heading size='$3'>Loading{username ? ` ${username}` : ''}</Heading>}
      </YStack>
    </TabsNavigation>
  )
}
