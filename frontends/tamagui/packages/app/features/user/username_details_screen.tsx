import { Moderation, Permission, User, Visibility } from '@jonline/api';
import { AnimatePresence, Button, Dialog, Heading, ScrollView, Text, TextArea, Theme, Tooltip, XStack, YStack, dismissScrollPreserver, isClient, isWeb, needsScrollPreservers, reverseHorizontalAnimation, standardHorizontalAnimation, useMedia, useWindowDimensions } from '@jonline/ui';
import { AlertTriangle, CheckCircle, ChevronRight, Edit, Eye, Trash } from '@tamagui/lucide-icons';
import { RootState, clearUserAlerts, deleteUser, loadUserPosts, loadUsername, selectUserById, updateUser, useAccount, useCredentialDispatch, useServerTheme, useTypedSelector, userSaved } from 'app/store';
import { pending } from 'app/utils/moderation_utils';
import React, { useEffect, useState } from 'react';
import StickyBox from "react-sticky-box";
import { createParam } from 'solito';
import { useLink } from 'solito/link';
import { AsyncPostCard } from '../post/async_post_card';
import { TamaguiMarkdown } from '../post/tamagui_markdown';
import { VisibilityPicker } from '../post/visibility_picker';
import { ToggleRow } from '../settings_sheet';
import { AppSection } from '../tabs/features_navigation';
import { TabsNavigation } from '../tabs/tabs_navigation';
import { PermissionsEditor, PermissionsEditorProps } from './permissions_editor';
import { UserCard, useFullAvatarHeight } from './user_card';
import { hasAdminPermission } from 'app/utils/permission_utils';

const { useParam } = createParam<{ username: string }>()

export function UsernameDetailsScreen() {
  const [inputUsername] = useParam('username');
  const linkProps = useLink({ href: '/' });

  const { server, primaryColor, primaryTextColor, navColor, navTextColor } = useServerTheme();
  const paramUserId: string | undefined = useTypedSelector((state: RootState) => inputUsername ? state.users.usernameIds[inputUsername] : undefined);
  const [userId, setUserId] = useState(paramUserId);
  const user = useTypedSelector((state: RootState) => userId ? selectUserById(state.users, userId) : undefined);
  const { dispatch, accountOrServer } = useCredentialDispatch();
  const usersState = useTypedSelector((state: RootState) => state.users);
  const [loadingUser, setLoadingUser] = useState(false);
  const [showUserSettings, setShowUserSettings] = useState(false);
  const userLoadFailed = usersState.failedUsernames.includes(inputUsername!);
  const isCurrentUser = accountOrServer.account && accountOrServer.account?.user?.id == user?.id;
  const isAdmin = hasAdminPermission(accountOrServer.account?.user);
  const canEdit = isCurrentUser || isAdmin;
  const [username, setUsername] = useState(user?.username);
  const [bio, setBio] = useState(user?.bio);
  const [avatar, setAvatar] = useState(user?.avatar);
  const [editMode, setEditMode] = useState(false);
  const [defaultFollowModeration, setDefaultFollowModeration] = useState(user?.defaultFollowModeration ?? Moderation.MODERATION_UNKNOWN);
  const [visibility, setVisibility] = useState(Visibility.GLOBAL_PUBLIC);
  const [permissions, setPermissions] = useState(user?.permissions ?? []);
  function selectPermission(permission: Permission) {
    if (permissions.includes(permission)) {
      setPermissions(permissions.filter(p => p != permission));
    } else {
      setPermissions([...permissions, permission]);
    }
  }
  function deselectPermission(permission: Permission) {
    setPermissions(permissions.filter(p => p != permission));
  }

  const permissionsEditorProps: PermissionsEditorProps = {
    selectedPermissions: permissions,
    selectPermission,
    deselectPermission,
    editMode
  };

  const successSaving = useTypedSelector((state: RootState) => state.users.successMessage == userSaved);
  const permissionsModified = JSON.stringify(permissions) !== JSON.stringify(user?.permissions ?? []);
  const dirtyData = username != user?.username || bio != user?.bio || avatar?.id != user?.avatar?.id
    || defaultFollowModeration != user?.defaultFollowModeration || visibility != user?.visibility
    || permissionsModified;

  const userPosts = useTypedSelector((state: RootState) => {
    return userId ? (state.users.idPosts ?? {})[userId] : undefined
  });
  const [loadingUserPosts, setLoadingUserPosts] = useState(false);
  const [loadingUserEvents, setLoadingUserEvents] = useState(false);
  const fullAvatarHeight = useFullAvatarHeight();
  function resetFormData() {
    if (!user) {
      setUsername(undefined);
      setBio(undefined);
      setAvatar(undefined);
      setDefaultFollowModeration(Moderation.MODERATION_UNKNOWN);
      setVisibility(Visibility.VISIBILITY_UNKNOWN);
      setPermissions([]);
      return;
    };

    setUsername(user.username);
    setBio(user.bio);
    setAvatar(user.avatar);
    setDefaultFollowModeration(user.defaultFollowModeration);
    setVisibility(user.visibility);
    setPermissions(user.permissions);
  }

  useEffect(() => {
    if (paramUserId != userId) {
      setUserId(paramUserId);
      resetFormData();
    }
  }, [paramUserId, userId]);
  useEffect(() => {
    if (user && !username) {
      setUserId(paramUserId);
      resetFormData();
    }
  }, [user, username]);
  useEffect(() => {
    if (dirtyData && successSaving) {
      dispatch(clearUserAlerts!());
    }
  }, [dirtyData, successSaving]);
  useEffect(() => {
    if (editMode && !canEdit) setEditMode(false);
  }, [editMode, canEdit]);
  useEffect(() => {
    if (userId && !userPosts && !loadingUserPosts) {
      setLoadingUserPosts(true);
      reloadPosts();
    } else if (userPosts) {
      setLoadingUserPosts(false);
      dismissScrollPreserver(setShowScrollPreserver);
    }
  }, [userId, userPosts, loadingUserPosts]);

  function reloadPosts() {
    if (!accountOrServer.server) return;

    setTimeout(() =>
      dispatch(loadUserPosts({ ...accountOrServer, userId: userId! })), 1);
  }

  const [showScrollPreserver, setShowScrollPreserver] = useState(needsScrollPreservers());
  useEffect(() => {
    // debugger;
    if (inputUsername && !loadingUser && (!user || usersState.status == 'unloaded') && !userLoadFailed) {
      setLoadingUser(true);
      setTimeout(() => dispatch(loadUsername({ ...accountOrServer, username: inputUsername! })));
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
      ...{ ...user!, bio: bio ?? '', avatar, defaultFollowModeration, visibility, permissions },
    })), 1);
  }
  const postsState = useTypedSelector((state: RootState) => state.posts);
  const loading = usersState.status == 'loading' || usersState.status == 'unloaded'
    || postsState.status == 'loading' || postsState.status == 'unloaded';

  return (
    <TabsNavigation appSection={AppSection.PROFILE}>
      <YStack f={1} jc="center" ai="center" space margin='$3' w='100%'>
        {user ? <>
          <ScrollView w='100%'>
            <YStack maw={800} w='100%' als='center' p='$2' marginHorizontal='auto'>
              <UserCard
                editable editingDisabled={!editMode}
                user={user}
                username={username}
                setUsername={setUsername}
                avatar={avatar}
                setAvatar={setAvatar} />
              <YStack als='center' w='100%' paddingHorizontal='$2' paddingVertical='$3' space>
                {editMode ?
                  <TextArea key='bio-edit' animation='quick' {...standardHorizontalAnimation}
                    value={bio} onChangeText={t => setBio(t)}
                    // size='$5'
                    h='$14'
                    placeholder={`Edit ${isCurrentUser ? 'your' : `${username}'s`} user bio. Markdown is supported.`}
                  />
                  : <YStack key='bio-markdown' animation='quick' {...reverseHorizontalAnimation}>
                    <TamaguiMarkdown text={bio!} />
                  </YStack>}
              </YStack>
              <Button mt={-15} onPress={() => setShowUserSettings(!showUserSettings)} transparent>
                <XStack ac='center' jc='center'>
                  <Heading size='$4' ta='center'>User Settings</Heading>
                  <XStack animation='standard' rotate={showUserSettings ? '90deg' : '0deg'}>
                    <ChevronRight />
                  </XStack>
                </XStack>
              </Button>
              <UserVisibilityPermissions expanded={showUserSettings}
                {...{ user, defaultFollowModeration, setDefaultFollowModeration, visibility, setVisibility, permissionsEditorProps, editMode }} />

              {(userPosts || []).length > 0 ?
                <>
                  <Heading size='$4' ta='center' mt='$2'>Latest Activity</Heading>
                  <>
                    <YStack>
                      {userPosts?.map((postId) => {
                        return <AsyncPostCard key={`userpost-${postId}`} postId={postId} />;
                      })}
                      {showScrollPreserver ? <YStack h={100000} /> : undefined}
                    </YStack>
                    {/* <FlatList data={userPosts} style={{ width: '100%' }}
                      // onRefresh={reloadPosts}
                      // refreshing={postsState.status == 'loading'}
                      // Allow easy restoring of scroll position
                      ListFooterComponent={showScrollPreserver ? <YStack h={100000} /> : undefined}
                      keyExtractor={(postId) => postId}
                      renderItem={({ item: postId }) => {
                        return <AsyncPostCard key={`userpost-${postId}`} postId={postId} />;
                      }} /> */}
                  </>
                </>
                : loading ? undefined : <Heading size='$1' ta='center'>No posts yet</Heading>}

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
                      <Button icon={Edit} circular mr='$5' als='center'
                        backgroundColor={!editMode ? undefined : navColor} color={!editMode ? undefined : navTextColor}
                        onPress={() => {
                          setEditMode(true);
                          // setShowPermissionsAndVisibility(true);
                          const maxScrollPosition = 270 + (avatar ? fullAvatarHeight : 0);
                          if (window.scrollY > maxScrollPosition) {
                            isClient && window.scrollTo({ top: maxScrollPosition, behavior: 'smooth' });
                          }
                        }} />
                    </Tooltip.Trigger>
                    <Tooltip.Content>
                      <Heading size='$2'>Edit {isCurrentUser ? 'your' : 'this'} profile</Heading>
                    </Tooltip.Content>
                  </Tooltip>
                  <YStack animation='quick' o={dirtyData ? 1 : 0} p='$3'>
                    <AlertTriangle color='yellow' />
                  </YStack>
                  <Button backgroundColor={primaryColor} disabled={!dirtyData} opacity={dirtyData ? 1 : 0.5} als='center' onPress={saveUser}>
                    <Heading size='$2' color={primaryTextColor}>Save</Heading>
                  </Button>
                  <YStack animation='quick' o={successSaving ? 1 : 0} p='$3'>
                    <CheckCircle color='green' />
                  </YStack>
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

interface UserVisibilityPermissionsProps {
  user: User,
  defaultFollowModeration: Moderation,
  setDefaultFollowModeration: (v: Moderation) => void,
  visibility: Visibility,
  setVisibility: (v: Visibility) => void,
  expanded?: boolean;
  editMode: boolean;
  permissionsEditorProps: PermissionsEditorProps;
}

const UserVisibilityPermissions: React.FC<UserVisibilityPermissionsProps> = ({ user, defaultFollowModeration, setDefaultFollowModeration, visibility, setVisibility, editMode, expanded = true, permissionsEditorProps }) => {
  const { dispatch, accountOrServer } = useCredentialDispatch();
  const { server } = accountOrServer;
  const media = useMedia();
  const account = useAccount();
  const isCurrentUser = account && account?.user?.id == user.id;
  const isAdmin = hasAdminPermission(account?.user);
  const canEdit = isCurrentUser || isAdmin;
  const disableInputs = !editMode || !canEdit;
  return <AnimatePresence>
    {expanded ? <YStack animation='standard' key='user-visibility-permissions'
      p='$3'
      ac='center'
      jc='center'
      opacity={1}
      scale={1}
      y={0}
      enterStyle={{
        y: -50,
        opacity: 0,
      }}
      exitStyle={{
        opacity: 0,
      }}>
      <XStack ac='center' jc='center' mb='$2'>
        {media.gtSm ? <Heading size='$3' marginVertical='auto' f={1} o={disableInputs ? 0.5 : 1}>
          Visibility
        </Heading> : undefined}
        <VisibilityPicker label={`${isCurrentUser ? 'Profile' : 'User'} Visibility`}
          visibility={visibility} onChange={setVisibility}
          disabled={disableInputs}
          visibilityDescription={(v) => {
            switch (v) {
              case Visibility.PRIVATE:
                return `Only ${isCurrentUser ? 'you' : 'they'} can see ${isCurrentUser ? 'your' : 'their'} profile.`;
              case Visibility.LIMITED:
                return `Only followers can see ${isCurrentUser ? 'your' : 'their'} profile.`;
              case Visibility.SERVER_PUBLIC:
                return `Anyone on this server can see ${isCurrentUser ? 'your' : 'their'} profile.`;
              case Visibility.GLOBAL_PUBLIC:
                return `Anyone on the internet can see ${isCurrentUser ? 'your' : 'their'} profile.`;
              default:
                return 'Unknown';
            }
          }} />
      </XStack>
      <ToggleRow name={`Require${editMode && isCurrentUser ? '' : 's'} Permission to Follow`}
        value={pending(defaultFollowModeration)}
        setter={(v) => setDefaultFollowModeration(v ? Moderation.PENDING : Moderation.UNMODERATED)}
        disabled={disableInputs} />
      <XStack h='$1' />
      <PermissionsEditor {...permissionsEditorProps} />
      {isCurrentUser || isAdmin ?
        <Dialog>
          <Dialog.Trigger asChild>
            <Button icon={<Trash />} color="red" mb='$3'>
              Delete Account
            </Button>
          </Dialog.Trigger>
          <Dialog.Portal zi={1000011}>
            <Dialog.Overlay
              key="overlay"
              animation="quick"
              o={0.5}
              enterStyle={{ o: 0 }}
              exitStyle={{ o: 0 }}
            />
            <Dialog.Content
              bordered
              elevate
              key="content"
              animation={[
                'quick',
                {
                  opacity: {
                    overshootClamping: true,
                  },
                },
              ]}
              m='$3'
              enterStyle={{ x: 0, y: -20, opacity: 0, scale: 0.9 }}
              exitStyle={{ x: 0, y: 10, opacity: 0, scale: 0.95 }}
              x={0}
              scale={1}
              opacity={1}
              y={0}
            >
              <YStack space>
                <Dialog.Title>Delete Account</Dialog.Title>
                <Dialog.Description>
                  Really delete account {user.username} on {server!.host}? Media may take up to 24 hours to be deleted.
                </Dialog.Description>

                <XStack space="$3" jc="flex-end">
                  <Dialog.Close asChild>
                    <Button>Cancel</Button>
                  </Dialog.Close>
                  {/* <Dialog.Action asChild> */}
                  <Theme inverse>
                    <Button onPress={() => dispatch(deleteUser({ ...user, ...accountOrServer }))}>Delete</Button>
                  </Theme>
                  {/* </Dialog.Action> */}
                </XStack>
              </YStack>
            </Dialog.Content>
          </Dialog.Portal>
        </Dialog> : undefined}
    </YStack> : undefined}
  </AnimatePresence>;
}
