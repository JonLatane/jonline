import { Button, Heading, Text, Paragraph, YStack } from '@jonline/ui'
import { isWeb, Permission, ScrollView, TextArea, Tooltip, useWindowDimensions, XStack } from '@jonline/ui/src'
import { ChevronLeft, Edit, Eye } from '@tamagui/lucide-icons'
import { loadUsername, RootState, selectUserById, updateUser, useCredentialDispatch, useServerTheme, useTypedSelector } from 'app/store'
import React, { useState, useEffect } from 'react'
import { createParam } from 'solito'
import { useLink } from 'solito/link'
import { TabsNavigation } from '../tabs/tabs_navigation'
import UserCard from './user_card'
import { Dimensions } from 'react-native';
import StickyBox from "react-sticky-box";
import { dismissScrollPreserver, needsScrollPreservers } from '@jonline/ui/src/global'
import { TamaguiMarkdown } from '../post/tamagui_markdown'


const { useParam } = createParam<{ username: string }>()

export function UsernameDetailsScreen() {
  const [username] = useParam('username')
  const linkProps = useLink({ href: '/' })

  const { server, primaryColor, primaryTextColor, navColor, navTextColor } = useServerTheme();
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
  const avatar = useTypedSelector((state: RootState) => userId ? state.users.avatars[userId] : undefined);
  const [updatedAvatar, setUpdatedAvatar] = useState(avatar);
  const [editMode, setEditMode] = useState(false);

  useEffect(() => {
    if (user && !name) setName(user.username);
    if (user && !bio) setBio(user.bio);
    if (avatar && !updatedAvatar) setUpdatedAvatar(avatar);
    if (editMode && !canEdit) setEditMode(false);
  });

  const [showScrollPreserver, setShowScrollPreserver] = useState(needsScrollPreservers());
  useEffect(() => {
    if (username && !loadingUser && (!user || usersState.status == 'unloaded') && !userLoadFailed) {
      setLoadingUser(true);
      setTimeout(() => dispatch(loadUsername({ ...accountOrServer, username: username! })));
    } else if (loadingUser && (user || userLoadFailed)) {
      setLoadingUser(false);
    }
    if (user && showScrollPreserver) {
      dismissScrollPreserver(setShowScrollPreserver);
    }
  });
  const windowHeight = useWindowDimensions().height;
  function saveUser() {
    if (!canEdit && !user) return;

    setTimeout(() => dispatch(updateUser({
      ...accountOrServer,
      user: { ...user!, bio: bio ?? '' },
      avatar: avatar,
    })));
  }

  return (
    <TabsNavigation>
      <YStack f={1} jc="center" ai="center" space margin='$3' w='100%'>
        {user ? <>
          <ScrollView w='100%'>
            <YStack maw={800} w='100%' als='center' marginHorizontal='auto'>
              <UserCard user={user} setUsername={editMode ? setName : undefined} setAvatar={editMode ? setUpdatedAvatar : undefined} />
              <YStack als='center' w='100%' p='$3' space>
                {editMode ?
                  <TextArea value={bio} onChangeText={t => setBio(t)}
                    placeholder={`Edit ${isCurrentUser ? 'your' : `${name}'s`} user bio. Markdown is supported.`} />
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
            isWeb ? <StickyBox bottom offsetBottom={0} className='blur' style={{ width: '100%' }}>
              <YStack w='100%' opacity={.92} paddingVertical='$2' backgroundColor='$background' alignContent='center'>
                <XStack alignItems='center'>
                  <XStack f={1} />
                  <Tooltip placement="top-start">
                    <Tooltip.Trigger>
                      <Button backgroundColor={editMode ? undefined : navColor} color={editMode ? undefined : navTextColor} als='center' onPress={() => setEditMode(false)} icon={Eye} circular mr='$2' />
                    </Tooltip.Trigger>
                    <Tooltip.Content>
                      <Heading size='$2'>View {isCurrentUser ? 'your' : 'this'} profile</Heading>
                    </Tooltip.Content>
                  </Tooltip>
                  <Tooltip placement="top-start">
                    <Tooltip.Trigger>
                      <Button backgroundColor={!editMode ? undefined : navColor} color={!editMode ? undefined : navTextColor} als='center' onPress={() => setEditMode(true)} icon={Edit} circular mr='$5' />
                    </Tooltip.Trigger>
                    <Tooltip.Content>
                      <Heading size='$2'>Edit {isCurrentUser ? 'your' : 'this'} profile</Heading>
                    </Tooltip.Content>
                  </Tooltip>
                  <Button backgroundColor={primaryColor} als='center' onPress={saveUser}>
                    <Heading size='$2' color={primaryTextColor}>Save</Heading>
                  </Button>
                  <XStack f={1} />
                </XStack>
              </YStack>
            </StickyBox>
              : <Button mt='$3' backgroundColor={primaryColor} onPress={saveUser}>Save Changes</Button>
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
