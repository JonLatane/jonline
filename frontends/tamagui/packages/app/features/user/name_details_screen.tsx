import { Button, Heading, Text, Paragraph, YStack } from '@jonline/ui'
import { isWeb, Permission, ScrollView, TextArea, useWindowDimensions } from '@jonline/ui/src'
import { ChevronLeft } from '@tamagui/lucide-icons'
import { loadUsername, RootState, selectUserById, useCredentialDispatch, useTypedSelector } from 'app/store'
import React, { useState, useEffect } from 'react'
import { createParam } from 'solito'
import { useLink } from 'solito/link'
import { TamaguiMarkdown } from '../post/post_card'
import { TabsNavigation } from '../tabs/tabs_navigation'
import UserCard from './user_card'
import { Dimensions } from 'react-native';
import StickyBox from "react-sticky-box";


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
  const isCurrentUser = accountOrServer.account && accountOrServer.account?.user?.id == user?.id;
  const canEdit = isCurrentUser
    || accountOrServer.account?.user?.permissions?.includes(Permission.ADMIN);
  const [name, setName] = useState(user?.username);
  const [bio, setBio] = useState(user?.bio);
  useEffect(() => {
    if (user && !name) setName(user.username);
    if (user && !bio) setBio(user.bio);
  });

  const isSafari = /^((?!chrome|android).)*safari/i.test(navigator.userAgent);
  const [showScrollPreserver, setShowScrollPreserver] = useState(isSafari);
  useEffect(() => {
    if (username && !loadingUser && (!user || usersState.status == 'unloaded') && !userLoadFailed) {
      setLoadingUser(true);
      setTimeout(() => dispatch(loadUsername({ ...accountOrServer, username: username! })));
    } else if (loadingUser && (user || userLoadFailed)) {
      setLoadingUser(false);
    }
    if (user && showScrollPreserver) {
      setTimeout(() => setShowScrollPreserver(false), 1500);
    }
  });
  const windowHeight = useWindowDimensions().height;

  return (
    <TabsNavigation>
      <YStack f={1} jc="center" ai="center" space margin='$3' w='100%'>
        {user ? <>
          <ScrollView w='100%'>
            <YStack maw={800} w='100%' als='center'>
              <UserCard user={user} setUsername={canEdit ? setName : undefined} />
              <YStack als='center' w='100%' p='$3' space>
                {canEdit ?
                  <TextArea value={bio} onChangeText={t => setBio(t)}
                    placeholder='Your user bio' />
                  : <TamaguiMarkdown text={bio!} />}
                {/* {canEdit ?
                <TextArea value={bio} onChangeText={t => setBio(t)}
                  placeholder='Your user bio' />
                : <TamaguiMarkdown text={bio!} />}
              {canEdit ?
                <TextArea value={bio} onChangeText={t => setBio(t)}
                  placeholder='Your user bio' />
                : <TamaguiMarkdown text={bio!} />}
              {canEdit ?
                <TextArea value={bio} onChangeText={t => setBio(t)}
                  placeholder='Your user bio' />
                : <TamaguiMarkdown text={bio!} />}
              {canEdit ?
                <TextArea value={bio} onChangeText={t => setBio(t)}
                  placeholder='Your user bio' />
                : <TamaguiMarkdown text={bio!} />} */}
              </YStack>
              {isWeb && canEdit ? <YStack h={50} /> : undefined}
            </YStack>
          </ScrollView>
          {canEdit ?
            isWeb ? <StickyBox bottom offsetBottom={0} style={{ width: '100%' }}>
              <YStack w='100%' paddingVertical='$2' backgroundColor='$background' alignContent='center'>
                <Button backgroundColor={primaryColor} als='center'>Save Changes</Button>
              </YStack>
            </StickyBox>
              : <Button mt='$3' backgroundColor={primaryColor}>Save Changes</Button>
            : undefined}
        </>
          : userLoadFailed
            ? <YStack width='100%' maw={800} jc="center" ai="center">
              <Heading size='$5' mb='$3'>The profile for <Text fontFamily='$body' fontSize='$7'>{username}</Text> could not be loaded.</Heading>
              <Heading size='$3' ta='center'>They may either not exist, not be visible to you, or be hidden by moderators.</Heading>
            </YStack>
            : <Heading size='$3'>Loading{username ? ` ${username}` : ''}</Heading>}
      </YStack>
    </TabsNavigation>
  )
}
