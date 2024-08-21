import { Moderation, Permission, PostContext, TimeFilter, Visibility } from '@jonline/api';
import { AnimatePresence, Button, Dialog, Heading, Input, Paragraph, ScrollView, Spinner, Text, TextArea, Theme, Tooltip, XStack, YStack, ZStack, dismissScrollPreserver, isClient, needsScrollPreservers, reverseHorizontalAnimation, standardHorizontalAnimation, toProtoISOString, useMedia, useToastController, useWindowDimensions } from '@jonline/ui';
import { AlertTriangle, Calendar as CalendarIcon, CheckCircle, ChevronRight, Edit3 as Edit, Eye, SquareAsterisk, Trash, XCircle } from '@tamagui/lucide-icons';
import { PermissionsEditor, PermissionsEditorProps, TamaguiMarkdown, ToggleRow, VisibilityPicker } from 'app/components';
import { useEventPageParam, useFederatedDispatch, usePaginatedRendering } from 'app/hooks';
import { useBigCalendar, useShowEvents } from 'app/hooks/configuration_hooks';
import { FederatedEvent, FederatedPost, FederatedUser, RootState, actionSucceeded, deleteUser, federatedId, getFederated, loadUserEvents, loadUserPosts, loadUserReplies, loadUsername, resetPassword, selectUserById, serverID, updateUser, useRootSelector, useServerTheme } from 'app/store';
import { hasAdminPermission, pending, setDocumentTitle, themedButtonBackground } from 'app/utils';
import moment from 'moment';
import React, { useCallback, useEffect, useState } from 'react';
import FlipMove from 'lumen5-react-flip-move';
import { createParam } from 'solito';
import { useLink } from 'solito/link';
import { useAppSelector } from '../../hooks/store_hooks';
import { EventCard } from '../event/event_card';
import { useGroupFromPath } from '../groups/group_home_screen';
import { DynamicCreateButton } from '../home/dynamic_create_button';
import { EventsFullCalendar } from '../event/events_full_calendar';
import { PageChooser } from '../home/page_chooser';
import { AppSection } from '../navigation/features_navigation';
import { TabsNavigation } from '../navigation/tabs_navigation';
import { PostCard } from '../post/post_card';
import { FederatedProfiles } from './federated_profiles';
import { EditableUserDetails, UserCard, useFullAvatarHeight } from './user_card';
import { AccountOrServerContextProvider } from 'app/contexts';

const { useParam } = createParam<{ username: string, serverHost?: string, shortname: string | undefined }>()
const { useParam: useShortnameParam } = createParam<{ shortname: string | undefined }>();

export function UsernameDetailsScreen() {
  const mediaQuery = useMedia();
  const { group, pathShortname } = useGroupFromPath();

  const [pathUsername] = useParam('username');
  const [inputUsername, inputServerHost] = (pathUsername ?? '').split('@');

  const { dispatch, accountOrServer } = useFederatedDispatch(inputServerHost);

  const { server, account } = accountOrServer;

  const linkProps = useLink({ href: '/' });
  const { bigCalendar, setBigCalendar } = useBigCalendar();
  const { showEvents, setShowEvents } = useShowEvents();

  const { primaryColor, primaryTextColor, primaryAnchorColor, navColor, navTextColor } = useServerTheme(server);
  const usernameIds = useAppSelector(state => getFederated(state.users.usernameIds, server));
  const userId: string | undefined = useRootSelector((state: RootState) =>
    inputUsername
      ? usernameIds[inputUsername]
      : undefined);
  const user = useRootSelector((state: RootState) => userId ? selectUserById(state.users, userId) : undefined);
  const usersState = useRootSelector((state: RootState) => state.users);
  const [loadingUser, setLoadingUser] = useState(false);
  const [loadedUser, setLoadedUser] = useState(false);
  const [showUserSettings, setShowUserSettings] = useState(false);
  const failedUsernames = getFederated(usersState.failedUsernames, server);
  // debugger;
  const userLoadFailed = failedUsernames.includes(inputUsername!);
  const isCurrentUser = accountOrServer.account && accountOrServer.account?.user?.id == user?.id;
  const isAdmin = hasAdminPermission(accountOrServer.account?.user);
  const canEdit = isCurrentUser || isAdmin;
  const [username, setUsername] = useState(user?.username);
  const [realName, setRealName] = useState(user?.realName);
  const [bio, setBio] = useState(user?.bio);
  const [avatar, setAvatar] = useState(user?.avatar);
  const [editMode, setEditMode] = useState(false);
  const editableUserDetails: EditableUserDetails = {
    editable: canEdit,
    editingDisabled: !editMode,

    username,
    setUsername,
    realName,
    setRealName,
    avatar,
    setAvatar,
  }
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
    username != user?.username || realName != user?.realName || bio != user?.bio || avatar?.id != user?.avatar?.id
    || defaultFollowModeration != user?.defaultFollowModeration || visibility != user?.visibility
    || permissionsModified
  );

  const [loadingUserPosts, setLoadingUserPosts] = useState(false);
  const userPostData: FederatedPost[] | undefined = useAppSelector((state) => {
    return userId
      ? state.users.idPosts[userId]
        ?.map(postId => state.posts.entities[postId])
        ?.filter(p => p !== undefined) as FederatedPost[]
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

  const [postContext, setPostContext] = useState(PostContext.POST);
  const allPosts = postContext === PostContext.POST ? userPosts : userReplies;
  const hasPosts = userPosts.length > 0 || userReplies.length > 0;
  const postPagination = usePaginatedRendering(allPosts, 7, {
    // itemIdResolver: (oldLastPost) => `post-${federatedId(oldLastPost)}`
  });
  useEffect(() => {
    postPagination.setPage(0);
  }, [postContext, user?.id]);
  const paginatedPosts = postPagination.results;

  const [loadingEvents, setLoadingEvents] = useState(false);
  const userEventIds = useAppSelector(state => userId ? state.users.idEventInstances[userId] : undefined);
  const userEventData: FederatedEvent[] | undefined = useAppSelector(state => {
    return userEventIds?.map(instanceId => {
      const eventId = state.events.instanceEvents[instanceId];
      if (!eventId) return undefined;
      const event = state.events.entities[eventId];
      if (!event) return undefined;
      return { ...event, instances: event.instances.filter(i => i.id === instanceId.split('@')[0]) };
    })
      ?.filter(e => e !== undefined) as FederatedEvent[] | undefined
  });
  // console.log("UsernameDetailsScreen userEventIds.length", userEventIds?.length, "userEventData.length", userEventData?.length);

  const [pageLoadTime] = useState<string>(moment(Date.now()).toISOString(true));
  const endsAfter = moment(pageLoadTime).subtract(1, "week").toISOString(true);
  const timeFilter: TimeFilter = { endsAfter: endsAfter ? toProtoISOString(endsAfter) : undefined };

  useEffect(() => {
    if (userId && !userEventData && !loadingEvents) {
      setLoadingEvents(true);
      dispatch(loadUserEvents({ ...accountOrServer, timeFilter, userId }))
        .then(() => setLoadingEvents(false));
    }
  }, [userId, userEventData, loadingEvents]);
  // console.log(userEventData);
  const eventResults = userEventData ?? [];
  const allEvents = bigCalendar
    ? eventResults
    : eventResults.filter(e => moment(e.instances[0]!.endsAt).isAfter(pageLoadTime));
  const eventPagination = usePaginatedRendering(allEvents, 7, {
    pageParamHook: useEventPageParam,
  });
  const paginatedEvents = eventPagination.results;


  const eventCardWidth = mediaQuery.gtSm ? 400 : 323;
  const noEventsWidth = Math.max(300, Math.min(1400, window.innerWidth) - 180);

  const [showScrollPreserver, setShowScrollPreserver] = useState(needsScrollPreservers());
  const fullAvatarHeight = useFullAvatarHeight();
  const resetFormData = useCallback(() => {
    if (!user) {
      setUsername(undefined);
      setRealName(undefined);
      setBio(undefined);
      setAvatar(undefined);
      setDefaultFollowModeration(Moderation.MODERATION_UNKNOWN);
      setVisibility(Visibility.VISIBILITY_UNKNOWN);
      setPermissions([]);
      return;
    };

    setUsername(user.username);
    setRealName(user.realName);
    setBio(user.bio);
    setAvatar(user.avatar);
    setDefaultFollowModeration(user.defaultFollowModeration);
    setVisibility(user.visibility);
    setPermissions(user.permissions);
  }, [user ? federatedId(user) : undefined]);

  const [successSaving, setSuccessSaving] = useState(false);
  useEffect(() => {
    resetFormData();
  }, [userId, pathUsername, server ? serverID(server) : undefined]);
  useEffect(() => {
    if (editMode && !canEdit) setEditMode(false);
  }, [editMode, canEdit]);

  useEffect(() => {
    if (inputUsername && !!accountOrServer.server && !loadingUser && !user?.hasAdvancedData && !loadedUser && !userLoadFailed) {
      setLoadingUser(true);
      dispatch(loadUsername({ ...accountOrServer, username: inputUsername! }))
        .then(() => {
          setLoadingUser(false);
          setLoadedUser(true);
        });
    }
  }, [inputUsername, loadingUser, user, userLoadFailed, !!accountOrServer.server]);
  useEffect(() => {
    setLoadedUser(false);
  }, [accountOrServer.server, accountOrServer.account?.user?.id, inputUsername]);
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
  });//, [user, username]);

  async function saveUser() {
    if (!canEdit && !user) return;

    const usernameChanged = username != user?.username;

    setSaving(true);
    dispatch(updateUser({
      ...accountOrServer,
      // ...{
      ...user!,
      username: username ?? '',
      realName: realName ?? '',
      bio: bio ?? '',
      avatar,
      defaultFollowModeration,
      visibility,
      permissions
      // },
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
    <TabsNavigation appSection={group ? AppSection.MEMBERS : AppSection.PEOPLE} primaryEntity={user}
      selectedGroup={group}
      groupPageForwarder={(groupIdentifier) => `/g/${groupIdentifier}/m/${pathUsername}`}
      groupPageReverse={`/${pathUsername}`}
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
            {/* <YStack animation='standard' o={dirtyData ? 1 : 0} p='$3'>
          <AlertTriangle color='yellow' />
        </YStack> */}
            <ZStack w={48} h={48}>
              <YStack animation='standard' o={successSaving ? 1 : 0} p='$3'>
                <CheckCircle color='green' />
              </YStack>
              <YStack animation='standard' o={dirtyData ? 1 : 0} p='$3'>
                <AlertTriangle color='yellow' />
              </YStack>
              <YStack animation='standard' o={saving ? 1 : 0} p='$3'>
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
      <YStack f={1} jc="center" ai="center" gap margin='$3' w='100%' px='$3'>
        {user ? <>
          {/* <ScrollView w='100%'> */}
          <FlipMove style={{
            width: '100%',
            display: 'flex',
            flexDirection: 'column',
            alignSelf: 'center',
            maxWidth: 1400,
            alignItems: 'center'
          }}>
            {/* <YStack maw={1400} w='100%' als='center' p='$2' marginHorizontal='auto' ai='center'> */}
            <div key='user-card' style={{ maxWidth: 800, width: '100%', display: 'flex', flexDirection: 'column', alignSelf: 'center', marginBottom: 10 }}>
              <UserCard user={user} {...editableUserDetails} />
              {/* editable editingDisabled={!editMode}
                user={user}
                username={username}
                setUsername={setUsername}
                avatar={avatar}
                setAvatar={setAvatar} /> */}
            </div>

            {user.hasAdvancedData
              ? <div key='federated-profiles' style={{}}>
                <FederatedProfiles user={user} />
              </div>
              : undefined}

            <div key='user-bio' style={{ maxWidth: 800, width: '100%', display: 'flex', flexDirection: 'column', alignSelf: 'center' }}>
              <AccountOrServerContextProvider value={accountOrServer}>
                <YStack als='center' w='100%' paddingHorizontal='$2' gap>
                  {editMode ?
                    <TextArea key='bio-edit' animation='standard' {...standardHorizontalAnimation}
                      value={bio} onChangeText={t => setBio(t)}
                      // size='$5'
                      h='$14'
                      placeholder={`Edit ${isCurrentUser ? 'your' : `${username}'s`} user bio. Markdown is supported.`}
                    />
                    : <YStack key='bio-markdown' animation='standard' {...reverseHorizontalAnimation}>
                      <TamaguiMarkdown text={bio!} />
                    </YStack>}
                </YStack>
              </AccountOrServerContextProvider>
            </div>

            {!editMode
              ? allEvents.length > 0 ? [
                <div key='upcoming-events-header' style={{ width: '100%' }}>
                  <XStack w='100%' ai='center'>

                    <Button mr='$2' my='$2' onPress={() => setShowEvents(!showEvents)}>
                      <YStack ai='center'>
                        <Heading size='$1' lh='$1'>Upcoming</Heading>
                        <Heading size='$3' lh='$1'>Events</Heading>
                      </YStack>
                      <XStack animation='standard' rotate={showEvents ? '90deg' : '0deg'}>
                        <ChevronRight />
                      </XStack>
                    </Button>

                    <Button onPress={() => setBigCalendar(!bigCalendar)}
                      icon={CalendarIcon}
                      transparent
                      {...themedButtonBackground(
                        bigCalendar ? navColor : undefined, bigCalendar ? navTextColor : undefined)}
                      animation='standard'
                      disabled={!showEvents || allEvents.length === 0}
                      o={!showEvents || allEvents.length === 0
                        ? 0 : 1}
                    />
                    {isCurrentUser
                      ? <>
                        <XStack f={1} mr='auto' />
                        <DynamicCreateButton showPosts showEvents hideIfUnusable />
                      </>
                      : undefined}

                    {/* <Heading size='$4' ta='center' >Upcoming Events</Heading> */}
                  </XStack>
                </div>,
                showEvents
                  ? bigCalendar && allEvents.length > 0
                    ? [
                      <div key='full-calendar'>
                        <EventsFullCalendar key='full-calendar' events={allEvents} weeklyOnly />
                      </div>
                    ]
                    : [
                      <div key='upcoming-events-pagination'
                        style={{ width: 'auto', maxWidth: '100%', marginLeft: 'auto', marginRight: 'auto', paddingLeft: 8, paddingRight: 8 }}
                      >
                        <PageChooser {...eventPagination} width='auto' />
                      </div>,

                      <div key='upcoming-events' style={{ width: '100%' }}>
                        <ScrollView horizontal w='100%'>
                          <XStack w={eventCardWidth} gap='$2' mx='auto' pl={mediaQuery.gtMd ? '$5' : undefined} my='auto'>

                            <FlipMove style={{ display: 'flex' }}>

                              {loadingEvents && allEvents.length == 0
                                ? <XStack key='spinner' mx={window.innerWidth / 2 - 50} my='auto'>
                                  <Spinner size='large' color={navColor} />
                                </XStack>
                                : undefined}
                              {allEvents.length == 0 && !loadingEvents
                                ? <div style={{ margin: 'auto', width: window.innerWidth - 12 }} key='no-events-found'>
                                  <YStack jc="center" ai="center" mx='auto' my='auto' px='$2'>
                                    <Heading size='$1' ta='center' o={0.5}>No events yet</Heading>
                                    {/* <Heading size='$3' ta='center'>The events you're looking for may either not exist, not be visible to you, or be hidden by moderators.</Heading> */}
                                  </YStack>
                                </div>
                                : undefined}

                              {paginatedEvents.map((event) =>
                                <span key={`event-preview-${federatedId(event)}-${event.instances[0]!.id}`}>
                                  <XStack mx='$1' px='$1' pb='$5'>
                                    <EventCard event={event} isPreview horizontal xs ignoreShrinkPreview />
                                  </XStack>
                                </span>)}

                            </FlipMove>
                          </XStack>
                        </ScrollView>
                      </div>]
                  : undefined
              ] : isCurrentUser && allEvents.length === 0
                ? <div key='dynamic-create-buttons-no-events-yet' style={{ width: '100%' }}>
                  <XStack w='100%' ai='center'>
                    <XStack f={1} />
                    <DynamicCreateButton showPosts showEvents hideIfUnusable />
                  </XStack>
                </div>
                : undefined
              : undefined}

            {loading ? <div key='spinner'><Spinner color={primaryAnchorColor} /></div> : undefined}

            {!editMode && hasPosts
              ? <div key='latest-activity' style={{ width: '100%', display: 'flex', flexDirection: 'column', maxWidth: 800, alignSelf: 'center' }}>
                <Heading size='$4' ta='center' my='$2' mx='auto'>Latest Activity</Heading>

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

                      <div key='posts-pagination'
                        style={{ width: 'auto', maxWidth: '100%', marginTop: 10, marginLeft: 'auto', marginRight: 'auto', paddingLeft: 8, paddingRight: 8 }}
                      >
                        <PageChooser {...postPagination} noAutoScroll width='auto' />
                      </div>
                      {loading ? undefined :
                        postContext === PostContext.POST && userPosts.length === 0
                          ? <div key='no-posts' style={{ display: 'flex', width: '100%', marginTop: 50, marginBottom: 150 }}><Heading w='100%' size='$1' ta='center' o={0.5}>No posts yet</Heading></div>
                          : postContext === PostContext.REPLY && userReplies.length === 0
                            ? <div key='no-replies' style={{ display: 'flex', width: '100%', marginTop: 50, marginBottom: 150 }}><Heading w='100%' size='$1' ta='center' o={0.5}>No replies yet</Heading></div>
                            : undefined}
                      {paginatedPosts.map((post) =>
                        <div key={`userpost-${post.id}`} style={{ width: '100%' }}>
                          <PostCard post={post} isPreview forceExpandPreview />
                        </div>
                      )}
                    </FlipMove>
                  </YStack>
                  {showScrollPreserver ? <YStack h={100000} /> : undefined}
                </YStack>
              </div>
              : <div key='no-activity-spacer' style={{ height: 20 }} />}


            <div key='visibility-permissions-toggle' style={{ width: '100%', maxWidth: 800, alignSelf: 'center' }}>
              <Button mx='auto' onPress={() => setShowUserSettings(!showUserSettings)} transparent>
                <XStack ac='center' jc='center' ai='center' maw='100%'>
                  <Heading size='$4' ta='center' f={1}>
                    {isAdmin || isCurrentUser
                      ? 'Settings, Permissions & Moderation'
                      : 'Permissions & Moderation'}
                  </Heading>
                  <XStack animation='standard' rotate={showUserSettings ? '90deg' : '0deg'}>
                    <ChevronRight />
                  </XStack>
                </XStack>
              </Button>
            </div>
            {showUserSettings
              ? <div key='visibility-permissions' style={{ width: '100%', maxWidth: 800, alignSelf: 'center' }}>

                <UserVisibilityPermissions expanded={showUserSettings}
                  {...{ user, defaultFollowModeration, setDefaultFollowModeration, visibility, setVisibility, permissionsEditorProps, editMode }} />
              </div>
              : undefined}

            <div key='spacer' style={{ height: showUserSettings ? 50 : 200 }} />
            {/* {isWeb && canEdit ?
              <div key='latest-activity' style={{ height: 50 }} />
              : undefined} */}
            {/* </YStack> */}

          </FlipMove>
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
  user: FederatedUser,
  defaultFollowModeration: Moderation,
  setDefaultFollowModeration: (v: Moderation) => void,
  visibility: Visibility,
  setVisibility: (v: Visibility) => void,
  expanded?: boolean;
  editMode: boolean;
  permissionsEditorProps: PermissionsEditorProps;
}

const UserVisibilityPermissions: React.FC<UserVisibilityPermissionsProps> = ({ user, defaultFollowModeration, setDefaultFollowModeration, visibility, setVisibility, editMode, expanded = true, permissionsEditorProps }) => {
  const { dispatch, accountOrServer } = useFederatedDispatch(user);
  const { server } = accountOrServer;
  const mediaQuery = useMedia();
  const { primaryColor, primaryTextColor, navColor, navTextColor } = useServerTheme();
  const { account } = accountOrServer;
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
      .then((result) => {
        if (actionSucceeded(result)) {
          toast.show('Password reset.');
        } else {
          toast.show('Failed to reset password.');
        }
      });
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
                return `Only ${isCurrentUser ? 'you' : 'they'} can see ${isCurrentUser ? 'your' : 'this'} profile.`;
              case Visibility.LIMITED:
                return `Only followers can see ${isCurrentUser ? 'your' : 'this'} profile.`;
              case Visibility.SERVER_PUBLIC:
                return `Anyone on this server can see ${isCurrentUser ? 'your' : 'this'} profile.`;
              case Visibility.GLOBAL_PUBLIC:
                return `Anyone on the internet can see ${isCurrentUser ? 'your' : 'this'} profile.`;
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
                animation='standard'
                o={0.5}
                enterStyle={{ o: 0 }}
                exitStyle={{ o: 0 }}
              />
              <Dialog.Content
                bordered
                elevate
                key="content"
                animation={[
                  'standard',
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
                animation='standard'
                o={0.5}
                enterStyle={{ o: 0 }}
                exitStyle={{ o: 0 }}
              />
              <Dialog.Content
                bordered
                elevate
                key="content"
                animation={[
                  'standard',
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
          {/* <ResetPasswordDialog user={user} /> */}
        </> : undefined}
    </YStack> : undefined}
  </AnimatePresence>;
}
