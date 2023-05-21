import { Moderation, Permission, User, Visibility, permissionToJSON } from '@jonline/api';
import { Adapt, Button, dismissScrollPreserver, Heading, isClient, isWeb, needsScrollPreservers, Paragraph, ScrollView, Select, Sheet, Text, TextArea, Tooltip, useMedia, useWindowDimensions, XStack, YStack } from '@jonline/ui';
import { LinearGradient } from "@tamagui/linear-gradient";
import { AlertTriangle, Check, CheckCircle, ChevronRight, ChevronUp, Edit, Eye, Plus } from '@tamagui/lucide-icons';
import { clearUserAlerts, loadUsername, loadUserPosts, RootState, selectUserById, updateUser, useCredentialDispatch, userSaved, useServerTheme, useTypedSelector } from 'app/store';
import { pending } from 'app/utils/moderation';
import React, { useEffect, useState } from 'react';
import { FlatList } from 'react-native';
import StickyBox from "react-sticky-box";
import { createParam } from 'solito';
import { useLink } from 'solito/link';
import { useAccount } from '../../store/store';
import { AsyncPostCard } from '../post/async_post_card';
import { TamaguiMarkdown } from '../post/tamagui_markdown';
import { VisibilityPicker } from '../post/visibility_picker';
import { ToggleRow } from '../settings_sheet';
import { TabsNavigation } from '../tabs/tabs_navigation';
import  { UserCard, useFullAvatarHeight } from './user_card';
import {useMediaUrl} from '../../hooks/use_media_url';
import { AppSection } from '../tabs/features_navigation';


const { useParam } = createParam<{ username: string }>()

export function UsernameDetailsScreen() {
  const [username] = useParam('username');
  const linkProps = useLink({ href: '/' });

  const { server, primaryColor, primaryTextColor, navColor, navTextColor } = useServerTheme();
  const paramUserId: string | undefined = useTypedSelector((state: RootState) => username ? state.users.usernameIds[username] : undefined);
  const [userId, setUserId] = useState(paramUserId);
  const user = useTypedSelector((state: RootState) => userId ? selectUserById(state.users, userId) : undefined);
  const { dispatch, accountOrServer } = useCredentialDispatch();
  const usersState = useTypedSelector((state: RootState) => state.users);
  const [loadingUser, setLoadingUser] = useState(false);
  const [showPermissionsAndVisibility, setShowPermissionsAndVisibility] = useState(false);
  const userLoadFailed = usersState.failedUsernames.includes(username!);
  const isCurrentUser = accountOrServer.account && accountOrServer.account?.user?.id == user?.id;
  const isAdmin = accountOrServer.account?.user?.permissions?.includes(Permission.ADMIN);
  const canEdit = isCurrentUser || isAdmin;
  const [name, setName] = useState(user?.username);
  const [bio, setBio] = useState(user?.bio);
  const [avatarMediaId, setAvatarMediaId] = useState(user?.avatarMediaId);
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
  const dirtyData = name != user?.username || bio != user?.bio || avatarMediaId != user?.avatarMediaId
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
      setName(undefined);
      setBio(undefined);
      setAvatarMediaId(undefined);
      setDefaultFollowModeration(Moderation.MODERATION_UNKNOWN);
      setVisibility(Visibility.VISIBILITY_UNKNOWN);
      setPermissions([]);
      return;
    };

    setBio(user.bio);
    setAvatarMediaId(user.avatarMediaId);
    setDefaultFollowModeration(user.defaultFollowModeration);
    setVisibility(user.visibility);
    setName(user.username);
    setPermissions(user.permissions);
  }

  useEffect(() => {
    if (paramUserId != userId) {
      setUserId(paramUserId);
      resetFormData();
    }
    if (user && !name) {
      setUserId(paramUserId);
      resetFormData();
    }
    if (dirtyData && successSaving) {
      dispatch(clearUserAlerts!());
    }
    if (editMode && !canEdit) setEditMode(false);
    if (userId && !userPosts && !loadingUserPosts) {
      setLoadingUserPosts(true);
      reloadPosts();
    } else if (userPosts) {
      setLoadingUserPosts(false);
      dismissScrollPreserver(setShowScrollPreserver);
    }
  });

  function reloadPosts() {
    if (!accountOrServer.server) return;

    setTimeout(() =>
      dispatch(loadUserPosts({ ...accountOrServer, userId: userId! })), 1);
  }

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
      ...{ ...user!, bio: bio ?? '', avatarMediaId, defaultFollowModeration, visibility, permissions },
    })));
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
              <UserCard user={user} setUsername={editMode ? setName : undefined} avatarMediaId={avatarMediaId} setAvatarMediaId={editMode ? setAvatarMediaId : undefined} />
              <YStack als='center' w='100%' paddingHorizontal='$2' paddingVertical='$3' space>
                {editMode ?
                  <TextArea value={bio} onChangeText={t => setBio(t)}
                    // size='$5'
                    h='$14'
                    placeholder={`Edit ${isCurrentUser ? 'your' : `${name}'s`} user bio. Markdown is supported.`}
                    o={1}
                    scale={1}
                    y={0}
                    enterStyle={{ y: -50, o: 0, }}
                    exitStyle={{ o: 0, }} />
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
              <Button mt={-15} onPress={() => setShowPermissionsAndVisibility(!showPermissionsAndVisibility)} transparent>
                <XStack ac='center' jc='center'>
                  <Heading size='$4' ta='center'>Visibility & Permissions</Heading>
                  <XStack animation='bouncy' rotate={showPermissionsAndVisibility ? '90deg' : '0deg'}>
                    <ChevronRight />
                  </XStack>
                </XStack>
              </Button>
              <UserVisibilityPermissions expanded={showPermissionsAndVisibility}
                {...{ user, defaultFollowModeration, setDefaultFollowModeration, visibility, setVisibility, permissionsEditorProps, editMode }} />

              {(userPosts || []).length > 0 ?
                <>
                  <Heading size='$4' ta='center' mt='$2'>Latest Activity</Heading>
                  <FlatList data={userPosts} style={{ width: '100%' }}
                    // onRefresh={reloadPosts}
                    // refreshing={postsState.status == 'loading'}
                    // Allow easy restoring of scroll position
                    ListFooterComponent={showScrollPreserver ? <YStack h={100000} /> : undefined}
                    keyExtractor={(postId) => postId}
                    renderItem={({ item: postId }) => {
                      return <AsyncPostCard key={`userpost-${postId}`} postId={postId} />;
                    }} />
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
                          const maxScrollPosition = 270 + (avatarMediaId ? fullAvatarHeight : 0);
                          if (window.scrollY > maxScrollPosition) {
                            isClient && window.scrollTo({ top: maxScrollPosition, behavior: 'smooth' });
                          }
                        }} />
                    </Tooltip.Trigger>
                    <Tooltip.Content>
                      <Heading size='$2'>Edit {isCurrentUser ? 'your' : 'this'} profile</Heading>
                    </Tooltip.Content>
                  </Tooltip>
                  {dirtyData ? <YStack animation="bouncy"
                    p='$3'
                    opacity={1}
                    scale={1}
                    y={0}
                    enterStyle={{ y: -50, opacity: 0, }}
                    exitStyle={{ opacity: 0, }}>
                    <AlertTriangle color='yellow' />
                  </YStack> : <YStack animation="bouncy"
                    p='$3'
                    opacity={0}>
                    <AlertTriangle color='yellow' />
                  </YStack>}
                  <Button backgroundColor={primaryColor} disabled={!dirtyData} opacity={dirtyData ? 1 : 0.5} als='center' onPress={saveUser}>
                    <Heading size='$2' color={primaryTextColor}>Save</Heading>
                  </Button>
                  {successSaving ? <YStack animation="bouncy"
                    p='$3'
                    opacity={1}
                    scale={1}
                    y={0}
                    enterStyle={{ y: -50, opacity: 0, }}
                    exitStyle={{ opacity: 0, }}>
                    <CheckCircle color='green' />
                  </YStack> : <YStack animation="bouncy"
                    p='$3'
                    opacity={0}>
                    <CheckCircle color='green' />
                  </YStack>}
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
  const media = useMedia();
  const account = useAccount();
  const isCurrentUser = account && account?.user?.id == user.id;
  const isAdmin = account?.user?.permissions?.includes(Permission.ADMIN);
  const canEdit = isCurrentUser || isAdmin;
  const disableInputs = !editMode || !canEdit;
  return expanded ? <YStack animation="bouncy"
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
  </YStack> : <></>;
}

export type PermissionsEditorProps = {
  id?: string;
  label?: string;
  selectablePermissions?: Permission[];
  selectedPermissions: Permission[];
  selectPermission: (p: Permission) => void;
  deselectPermission: (p: Permission) => void;
  editMode: boolean;
}

function toTitleCase(str: string) {
  return str.replace(
    /\w\S*/g,
    function(txt: string) {
      return txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase();
    }
  );
}

function permissionName(p: Permission): string {
  return toTitleCase(permissionToJSON(p).replace(/_/g, ' '));
}

function permissionDescription(p: Permission): string | undefined {
  switch (p) {
    case Permission.ADMIN:
      return 'Grants access to server configuration and all other permissions, such as moderation, creation, and publishing of media, posts, and events.';
  }
  return undefined;
}

export const PermissionsEditor: React.FC<PermissionsEditorProps> = ({ id, label, selectablePermissions, selectedPermissions, selectPermission, deselectPermission, editMode }) => {
  const disabled = !editMode;
  const allPermissions = selectablePermissions ??
    Object.keys(Permission)
      .filter(k => typeof Permission[k as any] === "number")
      .map(k => Permission[k as any]! as unknown as Permission)
      .filter(p => p != Permission.PERMISSION_UNKNOWN && p != Permission.UNRECOGNIZED);
  const addablePermissions = allPermissions.filter(p => !selectedPermissions.includes(p));
  return <YStack w='100%'>
    <Heading size='$3' marginVertical='auto' o={editMode ? 1 : 0.5}>
      {label ?? 'Permissions'}
    </Heading>
    <XStack w='100%' space='$2' flexWrap='wrap'>
      {selectedPermissions.map((p: Permission) =>
        <Button disabled={!editMode} onPress={() => deselectPermission(p)} mb='$2'>
          <XStack>
            <Paragraph size='$2'>{permissionName(p)}</Paragraph>
          </XStack>
        </Button>)
      }
      {editMode ? <Select key={`permissions-${JSON.stringify(selectedPermissions)}`} onValueChange={(p) => selectPermission(parseInt(p) as Permission)}
        value={undefined}>
        <Select.Trigger height='$2' f={1} maw={350} opacity={disabled ? 0.5 : 1} iconAfter={Plus} {...{ disabled }}>
          <Select.Value placeholder="Add a Permission..." />
        </Select.Trigger>

        <Adapt when="xs" platform="touch">
          <Sheet modal dismissOnSnapToBottom>
            <Sheet.Frame>
              <Sheet.ScrollView>
                <Adapt.Contents />
              </Sheet.ScrollView>
            </Sheet.Frame>
            <Sheet.Overlay />
          </Sheet>
        </Adapt>

        <Select.Content zIndex={200000}>
          <Select.ScrollUpButton ai="center" jc="center" pos="relative" w="100%" h="$3">
            <YStack zi={10}>
              <ChevronUp size={20} />
            </YStack>
            <LinearGradient
              start={[0, 0]}
              end={[0, 1]}
              fullscreen
              colors={['$background', '$backgroundTransparent']}
              br="$4"
            />
          </Select.ScrollUpButton>

          <Select.Viewport minWidth={200}>
            <Select.Group space="$0">
              <Select.Label>{'Available Permissions'}</Select.Label>
              {addablePermissions.map((item, i) => {
                const description = permissionDescription?.(item);
                return (
                  <Select.Item index={i} key={`${item}`} value={item.toString()}>
                    <Select.ItemText>
                      <YStack>
                        <Heading size='$2'>{permissionName(item)}</Heading>
                        <Paragraph size='$1'>{permissionDescription(item)}</Paragraph>
                      </YStack>
                    </Select.ItemText>
                    <Select.ItemIndicator ml="auto">
                      <Check size={16} />
                    </Select.ItemIndicator>
                  </Select.Item>
                )
              })}
            </Select.Group>
          </Select.Viewport>

          <Select.ScrollDownButton ai="center" jc="center" pos="relative" w="100%" h="$3">
            <YStack zi={10}>
              <Plus size={20} />
            </YStack>
            <LinearGradient
              start={[0, 0]}
              end={[0, 1]}
              fullscreen
              colors={['$backgroundTransparent', '$background']}
              br="$4"
            />
          </Select.ScrollDownButton>
        </Select.Content>
      </Select> : undefined}

    </XStack>
  </YStack>;
};