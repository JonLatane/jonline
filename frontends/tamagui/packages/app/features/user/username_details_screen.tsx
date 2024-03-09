import { Moderation, Permission, PostContext, User, Visibility } from '@jonline/api';
import { AnimatePresence, Button, Dialog, Heading, Input, Paragraph, ScrollView, Spinner, Text, TextArea, Theme, Tooltip, XStack, YStack, ZStack, dismissScrollPreserver, isClient, isWeb, needsScrollPreservers, reverseHorizontalAnimation, standardHorizontalAnimation, useMedia, useToastController, useWindowDimensions } from '@jonline/ui';
import { AlertTriangle, CheckCircle, ChevronRight, Edit3 as Edit, Eye, SquareAsterisk, Trash, XCircle } from '@tamagui/lucide-icons';
import { PermissionsEditor, PermissionsEditorProps, TamaguiMarkdown, ToggleRow, VisibilityPicker } from 'app/components';
import { useAccount, useCredentialDispatch, useFederatedDispatch, usePaginatedRendering } from 'app/hooks';
import { FederatedEvent, FederatedPost, RootState, deleteUser, federatedId, getFederated, getServerTheme, loadUserEvents, loadUserPosts, loadUserReplies, loadUsername, resetPassword, selectUserById, serverID, updateUser, useRootSelector, useServerTheme } from 'app/store';
import { hasAdminPermission, pending, setDocumentTitle, themedButtonBackground } from 'app/utils';
import React, { useEffect, useState } from 'react';
import FlipMove from 'react-flip-move';
import { createParam } from 'solito';
import { useLink } from 'solito/link';
import { useAppSelector } from '../../hooks/store_hooks';
import { AppSection } from '../navigation/features_navigation';
import { TabsNavigation } from '../navigation/tabs_navigation';
import { PostCard } from '../post/post_card';
import { UserCard, useFullAvatarHeight } from './user_card';
import { EventCard } from '../event/event_card';
import { PaginationIndicator, PaginationResetIndicator } from '../home/pagination_indicator';

const { useParam } = createParam<{ username: string, serverHost?: string }>()

export function UsernameDetailsScreen() {
  const mediaQuery = useMedia();
  const [pathUsername] = useParam('username');
  const [inputUsername, inputServerHost] = (pathUsername ?? '').split('@');

  const { dispatch, accountOrServer } = useFederatedDispatch(inputServerHost);

  const { server, account } = accountOrServer;

  const linkProps = useLink({ href: '/' });

  const { primaryColor, primaryTextColor, primaryAnchorColor, navColor, navTextColor } = getServerTheme(server);
  const usernameIds = useAppSelector(state => getFederated(state.users.usernameIds, server));
  const userId: string | undefined = useRootSelector((state: RootState) =>
    inputUsername
      ? usernameIds[inputUsername]
      : undefined);
  const user = useRootSelector((state: RootState) => userId ? selectUserById(state.users, userId) : undefined);
  const usersState = useRootSelector((state: RootState) => state.users);
  const [loadingUser, setLoadingUser] = useState(false);
  const [showUserSettings, setShowUserSettings] = useState(false);
  const failedUsernames = getFederated(usersState.failedUsernames, server);
  // debugger;
  const userLoadFailed = failedUsernames.includes(inputUsername!);
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

  const permissionsModified = JSON.stringify(permissions) !== JSON.stringify(user?.permissions ?? []);
  const dirtyData = user !== undefined && (
    username != user?.username || bio != user?.bio || avatar?.id != user?.avatar?.id
    || defaultFollowModeration != user?.defaultFollowModeration || visibility != user?.visibility
    || permissionsModified
  );

  const [loadingUserPosts, setLoadingUserPosts] = useState(false);
  const userPostData: FederatedPost[] | undefined = useAppSelector((state) => {
    return userId
      ? state.users.idPosts[userId]
        ?.map(postId => state.posts.entities[postId]!)
      : undefined
  });
  const userPosts = userPostData ?? [];
  useEffect(() => {
    if (userId && !userPostData && !loadingUserPosts) {
      setLoadingUserPosts(true);
      dispatch(loadUserPosts({ ...accountOrServer, userId }))
        .then(() => setLoadingUserPosts(false));
    }
  }, [userId, userPostData, loadingUserPosts]);

  const [loadingUserReplies, setLoadingUserReplies] = useState(false);
  const userReplyData: FederatedPost[] | undefined = useRootSelector((state: RootState) => {
    return userId
      ? state.users.idReplies[userId]
        ?.map(postId => state.posts.entities[postId]!)
      : undefined
  });
  const userReplies = userReplyData ?? [];
  useEffect(() => {
    if (userId && !userReplyData && !loadingUserReplies) {
      setLoadingUserReplies(true);
      dispatch(loadUserReplies({ ...accountOrServer, userId }))
        .then(() => setLoadingUserReplies(false));
    }
  }, [userId, userReplyData, loadingUserReplies]);

  const [loadingEvents, setLoadingUserEvents] = useState(false);
  const userEventData: FederatedEvent[] | undefined = useRootSelector((state: RootState) => {
    return userId
      ? state.users.idEventInstances[userId]
        ?.map(instanceId => {
          const eventId = state.events.instanceEvents[instanceId];
          if (!eventId) return undefined;
          const event = state.events.entities[eventId];
          if (!event) return undefined;
          return { ...event, instances: event.instances.filter(i => i.id === instanceId.split('@')[0]) };
        })
        ?.filter(e => e !== undefined) as FederatedEvent[]
      : undefined
  });
  useEffect(() => {
    if (userId && !userEventData && !loadingEvents) {
      setLoadingUserEvents(true);
      dispatch(loadUserEvents({ ...accountOrServer, userId }))
        .then(() => setLoadingUserEvents(false));
    }
  }, [userId, userEventData, loadingEvents]);
  const allEvents = userEventData ?? [];
  const eventPagination = usePaginatedRendering(allEvents, 7);
  const paginatedEvents = eventPagination.results;

  const eventCardWidth = mediaQuery.gtSm ? 400 : 323;
  const noEventsWidth = Math.max(300, Math.min(1400, window.innerWidth) - 180);

  const [postContext, setPostContext] = useState(PostContext.POST);
  const [showScrollPreserver, setShowScrollPreserver] = useState(needsScrollPreservers());
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

  const [successSaving, setSuccessSaving] = useState(false);
  useEffect(() => {
    resetFormData();
  }, [userId, pathUsername, server ? serverID(server) : undefined]);
  useEffect(() => {
    if (editMode && !canEdit) setEditMode(false);
  }, [editMode, canEdit]);

  useEffect(() => {
    if (inputUsername && !!accountOrServer.server && !loadingUser && !user && !userLoadFailed) {
      setLoadingUser(true);
      dispatch(loadUsername({ ...accountOrServer, username: inputUsername! }))
        .then(() => setLoadingUser(false));
    }
  }, [inputUsername, loadingUser, user, userLoadFailed, !!accountOrServer.server]);
  // console.log('user', user, 'loadingUser', loadingUser, userLoadFailed, !!accountOrServer.server);
  useEffect(() => {
    if (user && userPostData && showScrollPreserver) {
      dismissScrollPreserver(setShowScrollPreserver);
    }
  }, [user, userPostData, showScrollPreserver])
  const windowHeight = useWindowDimensions().height;
  const [saving, setSaving] = useState(false);
  const toast = useToastController()

  const isBusiness = permissions.includes(Permission.BUSINESS);
  useEffect(() => {
    const serverName = server?.serverConfiguration?.serverInfo?.name || '...';
    const realName = (user?.realName?.length ?? 0) > 0 ? user?.realName : undefined;
    let title = realName ?? username ?? 'User';
    title += ` | ${isBusiness ? 'Business Profile' : 'Profile'} | ${serverName}`;
    setDocumentTitle(title)
  }, [user, username]);

  async function saveUser() {
    if (!canEdit && !user) return;

    const usernameChanged = username != user?.username;

    setSaving(true);
    dispatch(updateUser({
      ...accountOrServer,
      ...{ ...user!, username: username ?? '', bio: bio ?? '', avatar, defaultFollowModeration, visibility, permissions },
    })).then((result) => {
      const success = result.type == updateUser.fulfilled.type;
      if (success && usernameChanged) {
        window.location.replace(`/${username}`);
      }
      if (!success) {
        toast.show('Failed to save profile changes.', {
          message: usernameChanged ? 'The new username may be taken or invalid.' : undefined,
        })
      } else {
        toast.show('Profile saved.')
      }
      setSuccessSaving(success);
      setSaving(false);
      setTimeout(() => setSuccessSaving(false), 3000);
    });
  }
  const postsState = useRootSelector((state: RootState) => state.posts);
  const loading = loadingUser || loadingUserPosts || loadingEvents || loadingUserReplies;

  // const loading = usersState.status == 'loading' || usersState.status == 'unloaded'
  //   || postsState.status == 'loading' || postsState.status == 'unloaded';

  return (
    <TabsNavigation appSection={AppSection.PROFILE} primaryEntity={user}
      bottomChrome={canEdit
        ? <YStack w='100%' paddingVertical='$2' alignContent='center'>
          <XStack mx='auto' px='$3' w='100%' maw={800}>
            {/* <XStack f={1} /> */}
            <Tooltip placement="top-start">
              <Tooltip.Trigger>
                <Button icon={Eye} circular mr='$2' als='center'
                  {...themedButtonBackground(editMode ? undefined : navColor, editMode ? undefined : navTextColor)}
                  onPress={() => setEditMode(false)} />
              </Tooltip.Trigger>
              <Tooltip.Content>
                <Heading size='$2'>View {isCurrentUser ? 'your' : 'this'} profile</Heading>
              </Tooltip.Content>
            </Tooltip>
            <Tooltip placement="top-start">
              <Tooltip.Trigger>
                <Button icon={Edit} circular mr='$5' als='center'
                  {...themedButtonBackground(!editMode ? undefined : navColor, !editMode ? undefined : navTextColor)}
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

            <XStack f={1} />
            {/* <YStack animation='quick' o={dirtyData ? 1 : 0} p='$3'>
          <AlertTriangle color='yellow' />
        </YStack> */}
            <ZStack w={48} h={48}>
              <YStack animation='quick' o={successSaving ? 1 : 0} p='$3'>
                <CheckCircle color='green' />
              </YStack>
              <YStack animation='quick' o={dirtyData ? 1 : 0} p='$3'>
                <AlertTriangle color='yellow' />
              </YStack>
              <YStack animation='quick' o={saving ? 1 : 0} p='$3'>
                <Spinner size='small' />
              </YStack>
            </ZStack>
            <Button key={`save-color-${primaryColor}`} mr='$3'
              {...themedButtonBackground(primaryColor, primaryTextColor, saving ? 0.5 : 1)}
              // disabled={!dirtyData} opacity={dirtyData ? 1 : 0.5}
              als='center' onPress={saveUser}>
              <Heading size='$2' color={primaryTextColor}>Save</Heading>
            </Button>
            {/* <XStack f={1} /> */}
          </XStack>
        </YStack> : undefined}>
      <YStack f={1} jc="center" ai="center" gap margin='$3' w='100%'>
        {user ? <>
          {/* <ScrollView w='100%'> */}
          <YStack maw={1400} w='100%' als='center' p='$2' marginHorizontal='auto' ai='center'>
            <YStack maw={800} w='100%' als='center'>
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
                  <Heading size='$4' ta='center'>Permissions & Moderation</Heading>
                  <XStack animation='standard' rotate={showUserSettings ? '90deg' : '0deg'}>
                    <ChevronRight />
                  </XStack>
                </XStack>
              </Button>
              <UserVisibilityPermissions expanded={showUserSettings}
                {...{ user, defaultFollowModeration, setDefaultFollowModeration, visibility, setVisibility, permissionsEditorProps, editMode }} />
            </YStack>

            <Heading size='$4' ta='center' mt='$2'>Upcoming Events</Heading>

            <ScrollView horizontal w='100%'>
              <XStack w={eventCardWidth} gap='$2' mx='auto' pl={mediaQuery.gtMd ? '$5' : undefined} my='auto'>

                <FlipMove style={{ display: 'flex' }}>

                  {loadingEvents && allEvents.length == 0
                    ? <XStack key='spinner' mx={window.innerWidth / 2 - 50} my='auto'>
                      <Spinner size='large' color={navColor} />
                    </XStack>
                    : undefined}
                  {allEvents.length == 0 && !loadingEvents
                    ? <div style={{ width: noEventsWidth, marginTop: 'auto', marginBottom: 'auto' }} key='no-events-found'>
                      <YStack width='100%' maw={600} jc="center" ai="center" mx='auto' my='auto' px='$2' mt='$3'>
                        <Heading size='$5' ta='center' mb='$3'>No events found.</Heading>
                        <Heading size='$3' ta='center'>The events you're looking for may either not exist, not be visible to you, or be hidden by moderators.</Heading>
                      </YStack>
                    </div>
                    : undefined}


                  <div key='next-page' style={{ marginTop: 'auto', marginBottom: 'auto' }}>
                    <PaginationResetIndicator {...eventPagination} width={eventCardWidth * 0.5} height={eventCardWidth * 0.75} />
                  </div>
                  {paginatedEvents.map((event) =>
                    <span key={`event-preview-${federatedId(event)}-${event.instances[0]!.id}`}>
                      <XStack mx='$1' px='$1' pb='$5'>
                        <EventCard event={event} isPreview horizontal xs ignoreShrinkPreview />
                      </XStack>
                    </span>)}

                  <div key='next-page' style={{ marginTop: 'auto', marginBottom: 'auto' }}>
                    <PaginationIndicator {...eventPagination} width={eventCardWidth * 0.5} height={eventCardWidth * 0.75} />
                  </div>
                </FlipMove>
              </XStack>
            </ScrollView>

            <Heading size='$4' ta='center' my='$2'>Latest Activity</Heading>

            <XStack jc='center'>
              <Button borderTopRightRadius={0} borderBottomRightRadius={0}
                {...themedButtonBackground(postContext === PostContext.POST ? primaryColor : undefined, postContext === PostContext.POST ? primaryTextColor : undefined)}
                onPress={() => setPostContext(PostContext.POST)}>Posts</Button>
              <Button borderTopLeftRadius={0} borderBottomLeftRadius={0}
                {...themedButtonBackground(postContext === PostContext.REPLY ? primaryColor : undefined, postContext === PostContext.REPLY ? primaryTextColor : undefined)}
                onPress={() => setPostContext(PostContext.REPLY)}>Replies</Button>
            </XStack>

            <YStack maw={800} w='100%' als='center'>
              <YStack ai='center' w='100%'>
                <FlipMove style={{ width: '100%' }}>
                  {loading ? <div key='spinner'><Spinner color={primaryAnchorColor} /></div> :
                    postContext === PostContext.POST && userPosts.length === 0
                      ? <div key='no-posts' style={{ display: 'flex', width: '100%', marginTop: 50, marginBottom: 150 }}><Heading w='100%' size='$1' ta='center'o={0.5}>No posts yet</Heading></div>
                      : postContext === PostContext.REPLY && userPosts.length === 0
                        ? <div key='no-replies' style={{ display: 'flex', width: '100%', marginTop: 50, marginBottom: 150 }}><Heading w='100%' size='$1' ta='center' o={0.5}>No replies yet</Heading></div>
                        : undefined}
                  {postContext === PostContext.POST
                    ? userPosts.map((post) => {
                      return <div key={`userpost-${post.id}`} style={{ width: '100%' }}><PostCard post={post} isPreview forceExpandPreview /></div>;
                      // return <AsyncPostCard key={`userpost-${postId}`} postId={postId} />;
                    })
                    : postContext === PostContext.REPLY ? userReplies.map((post) => {
                      return <div key={`userpost-${post.id}`}><PostCard post={post} isPreview forceExpandPreview /></div>;
                      // return <AsyncPostCard key={`userpost-${postId}`} postId={postId} />;
                    })
                      : undefined}
                </FlipMove>
              </YStack>
              {showScrollPreserver ? <YStack h={100000} /> : undefined}
            </YStack>
            {isWeb && canEdit ? <YStack h={50} /> : undefined}
          </YStack>
          {/* </ScrollView> */}
        </>
          : userLoadFailed
            ? <YStack width='100%' maw={800} jc="center" ai="center">
              <Heading size='$5' mb='$3'>The profile for <Text fontFamily='$body' fontSize='$7'>{inputUsername}</Text> could not be loaded.</Heading>
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
  const mediaQuery = useMedia();
  const { primaryColor, primaryTextColor, navColor, navTextColor } = useServerTheme();
  const account = useAccount();
  const isCurrentUser = account && account?.user?.id == user.id;
  const isAdmin = hasAdminPermission(account?.user);
  const canEdit = isCurrentUser || isAdmin;
  const disableInputs = !editMode || !canEdit;

  function doDeleteUser() {
    dispatch(deleteUser({ ...user!, ...accountOrServer }))
      .then(() => window.location.replace('/'));
  }

  const [resetUserPassword, setResetUserPassword] = useState('');
  const [confirmUserPassword, setConfirmUserPassword] = useState('');
  const [showPasswordPlaintext, setShowPasswordPlaintext] = useState(false);
  const toast = useToastController();
  const resetPasswordValid = resetUserPassword.length >= 8 && resetUserPassword == confirmUserPassword;
  const confirmPasswordInvalid = resetUserPassword.length >= 8 && resetUserPassword !== confirmUserPassword;
  function doResetPassword() {
    dispatch(resetPassword({ userId: user.id, password: resetUserPassword, ...accountOrServer }))
      .then(() => toast.show('Password reset.'));
  }

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
        {mediaQuery.gtSm ? <Heading size='$3' marginVertical='auto' f={1} o={disableInputs ? 0.5 : 1}>
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
        <>

          <Dialog>
            <Dialog.Trigger asChild>
              <Button icon={<SquareAsterisk />} mb='$2'>
                Reset Password
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
                  <Dialog.Title>Reset Password</Dialog.Title>
                  <Dialog.Description>
                    <YStack gap='$2'>
                      <Paragraph size="$2">New Password:</Paragraph>
                      <XStack gap='$2'>
                        <Input f={1} textContentType='password' secureTextEntry={!showPasswordPlaintext} placeholder={`Updated password (min 8 characters)`}
                          value={resetUserPassword}
                          onChange={(data) => { setResetUserPassword(data.nativeEvent.text) }} />
                        <Button circular icon={showPasswordPlaintext ? SquareAsterisk : Eye}
                          onPress={() => setShowPasswordPlaintext(!showPasswordPlaintext)} />
                        {/* <Text fontFamily='$body'>weeks</Text> */}

                      </XStack>
                      <Paragraph size="$2">Confirm Password:</Paragraph>
                      <XStack>
                        <Input f={1} textContentType='password' secureTextEntry={!showPasswordPlaintext} placeholder={`Confirm password`}
                          value={confirmUserPassword}
                          onChange={(data) => { setConfirmUserPassword(data.nativeEvent.text) }} />

                        <ZStack w='$2' h='$2' my='auto' ml='$4' mr='$2' pr='$2'>
                          <XStack m='auto' animation='standard' pr='$1'
                            o={resetPasswordValid ? 1 : 0}>
                            <CheckCircle color={navColor} />
                          </XStack>
                          <XStack m='auto' animation='standard' pr='$1'
                            o={confirmPasswordInvalid ? 1 : 0}>
                            <XCircle />
                          </XStack>
                        </ZStack>
                        {/* <Text fontFamily='$body'>weeks</Text> */}
                      </XStack>
                    </YStack>
                  </Dialog.Description>

                  <XStack gap="$3" jc="flex-end">
                    <Dialog.Close asChild>
                      <Button>Cancel</Button>
                    </Dialog.Close>
                    {/* <Theme inverse> */}
                    <Dialog.Close asChild>

                      <Button onPress={doResetPassword}
                        {...themedButtonBackground(primaryColor, primaryTextColor)}
                        opacity={resetPasswordValid ? 1 : 0.5}
                        disabled={!resetPasswordValid}>Reset Password</Button>
                    </Dialog.Close>

                    {/* </Theme> */}
                  </XStack>
                </YStack>
              </Dialog.Content>
            </Dialog.Portal>
          </Dialog>
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

                  <XStack gap="$3" jc="flex-end">
                    <Dialog.Close asChild>
                      <Button>Cancel</Button>
                    </Dialog.Close>
                    <Theme inverse>
                      <Button onPress={doDeleteUser}>Delete</Button>
                    </Theme>
                  </XStack>
                </YStack>
              </Dialog.Content>
            </Dialog.Portal>
          </Dialog>
        </> : undefined}
    </YStack> : undefined}
  </AnimatePresence>;
}
