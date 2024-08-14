import { Group, MediaReference, Moderation, Permission, Visibility } from '@jonline/api';
import { Button, Heading, Image, Input, Paragraph, Sheet, TextArea, Tooltip, XStack, YStack, standardAnimation, useDebounceValue, useMedia } from '@jonline/ui';
import { ChevronLeft, Cog, FileImage } from '@tamagui/lucide-icons';
import { PermissionsEditor, PermissionsEditorProps, ToggleRow, VisibilityPicker } from 'app/components';
import { useCreationDispatch, useMediaUrl } from 'app/hooks';
import { JonlineServer, RootState, actionFailed, createGroup, selectAllAccounts, serverID, useRootSelector, useServerTheme } from 'app/store';
import { hasPermission, pending, themedButtonBackground } from 'app/utils';
import FlipMove from 'lumen5-react-flip-move';
import React, { useEffect, useState } from 'react';
import { TextInput } from 'react-native';
import { CreationServerSelector } from '../accounts/creation_server_selector';
import { SingleMediaChooser } from '../accounts/single_media_chooser';
import { groupUserPermissions } from './group_details_sheet';

export type CreateGroupSheetProps = {
  // selectedGroup?: Group;
  onFreshOpen?: () => void;
  // invalid?: boolean;
}

export const groupVisibilityDescription = (
  v: Visibility,
  server: JonlineServer | undefined,
) => {
  switch (v) {
    case Visibility.PRIVATE:
      return 'Only you can see this group.';
    case Visibility.LIMITED:
      return 'Only members and invited people can see this group.';
    case Visibility.SERVER_PUBLIC:
      return `Anyone on ${server?.serverConfiguration?.serverInfo?.name ?? 'this server'} can see this group.`;
    case Visibility.GLOBAL_PUBLIC:
      return 'Anyone on the internet can see this group.';
    default:
      return 'Unknown';
  }
}

export enum RenderType { Edit, FullPreview, ShortPreview }
const edit = (r: RenderType) => r == RenderType.Edit;
const fullPreview = (r: RenderType) => r == RenderType.FullPreview;
const shortPreview = (r: RenderType) => r == RenderType.ShortPreview;

export function CreateGroupSheet({ }: CreateGroupSheetProps) {
  const mediaQuery = useMedia();
  const { dispatch, accountOrServer } = useCreationDispatch();
  const account = accountOrServer.account!;
  const [open, setOpen] = useState(false);
  const [position, setPosition] = useState(0);

  const [renderType, setRenderType] = useState(RenderType.Edit);
  const [showSettings, _setShowSettings] = useState(true);
  const [showMedia, _setShowMedia] = useState(false);
  const [showMediaContainer, setShowMediaContainer] = useState(false);
  const [hasOpened, setHasOpened] = useState(open);
  useEffect(() => {
    if (open && !hasOpened) {
      setHasOpened(true);
    }
  }, [hasOpened, open]);
  const openChanged = useDebounceValue(open, 3000);
  useEffect(() => {
    if (!openChanged) {
      setHasOpened(false);
    }
  }, [openChanged]);

  function setShowSettings(value: boolean) {
    _setShowSettings(value);
    if (value && showMedia) {
      _setShowMedia(false);
    }
  }
  function setShowMedia(value: boolean) {
    const oldValue = showMedia;
    _setShowMedia(value);
    if (value) {
      if (!oldValue && !showMediaContainer) {
        setShowMediaContainer(true);
      }
      if (showSettings) {
        _setShowSettings(false);
      }
    } else if (oldValue) {
      setTimeout(() => setShowMediaContainer(false), 500);
    }
  }

  // Form fields
  const [visibility, setVisibility] = useState(Visibility.SERVER_PUBLIC);
  const [name, setName] = useState('');
  const [description, setDescription] = useState('');
  const [avatar, setAvatar] = useState<MediaReference | undefined>(undefined);
  const [defaultMembershipModeration, setDefaultMembershipModeration] = useState(Moderation.UNMODERATED);
  const [defaultPostModeration, setDefaultPostModeration] = useState(Moderation.UNMODERATED);
  const [defaultEventModeration, setDefaultEventModeration] = useState(Moderation.UNMODERATED);
  const [defaultMembershipPermissions, setDefaultMembershipPermissions] = useState([Permission.VIEW_POSTS, Permission.VIEW_EVENTS]);
  const [nonMemberPermissions, setNonMemberPermissions] = useState([Permission.VIEW_POSTS, Permission.VIEW_EVENTS]);
  const fullAvatarHeight = 72;

  function resetGroup() {
    setOpen(false);
    setName('');
    setDescription('');
    setAvatar(undefined);
    setVisibility(Visibility.LIMITED);
    setDefaultPostModeration(Moderation.UNMODERATED);
    setDefaultEventModeration(Moderation.UNMODERATED);
    setDefaultMembershipModeration(Moderation.UNMODERATED);
    setDefaultMembershipPermissions([Permission.VIEW_POSTS, Permission.VIEW_EVENTS]);
    setNonMemberPermissions([Permission.VIEW_POSTS, Permission.VIEW_EVENTS]);

    setRenderType(RenderType.Edit);
    window.scrollTo({ top: 0, behavior: 'smooth' });
    // dispatch(clearGroupAlerts!());
    setPosting(false);
  }

  const [error, setError] = useState(undefined as string | undefined);


  function selectDefaultPermission(permission: Permission, permissionSet: Permission[], setPermissionSet: (permissions: Permission[]) => void) {
    if (permissionSet.includes(permission)) {
      setPermissionSet(permissionSet.filter(p => p != permission));
    } else {
      setPermissionSet([...permissionSet, permission]);
    }
  }
  function deselectDefaultPermission(permission: Permission, permissionSet: Permission[], setPermissionSet: (permissions: Permission[]) => void) {
    setPermissionSet(permissionSet.filter(p => p != permission));
  }

  const membershipPermissionsEditorProps: PermissionsEditorProps = {
    selectablePermissions: groupUserPermissions,
    selectedPermissions: defaultMembershipPermissions,
    selectPermission: (p: Permission) => selectDefaultPermission(p, defaultMembershipPermissions, setDefaultMembershipPermissions),
    deselectPermission: (p: Permission) => deselectDefaultPermission(p, defaultMembershipPermissions, setDefaultMembershipPermissions),
    editMode: true,
  };
  const nonMemberPermissionsEditorProps: PermissionsEditorProps = {
    selectablePermissions: groupUserPermissions.filter(p => ![Permission.ADMIN].includes(p)),
    selectedPermissions: nonMemberPermissions,
    selectPermission: (p: Permission) => selectDefaultPermission(p, nonMemberPermissions, setNonMemberPermissions),
    deselectPermission: (p: Permission) => deselectDefaultPermission(p, nonMemberPermissions, setNonMemberPermissions),
    editMode: true,
  };

  function doCreate() {
    setIsCreating(true);
    const group = Group.create({
      name,
      description,
      visibility,
      avatar,
      defaultMembershipModeration,
      defaultPostModeration,
      defaultEventModeration,
      defaultMembershipPermissions,
      nonMemberPermissions,
    });
    setError(undefined);
    dispatch(createGroup({ ...group, ...accountOrServer }))
      .then((action) => {
        setIsCreating(false);
        if (actionFailed(action)) {
          setError('Error creating group.');
        } else {
          resetGroup();
          setOpen(false);
        }
      }).finally(() => setIsCreating(false))
  }

  const textAreaRef = React.createRef<TextInput>();

  const [posting, setPosting] = useState(false);
  const serversState = useRootSelector((state: RootState) => state.servers);

  const { server, primaryColor, primaryTextColor, navColor, navAnchorColor, navTextColor, textColor } = useServerTheme(accountOrServer.server);
  const accountsState = useRootSelector((state: RootState) => state.accounts);
  const accounts = useRootSelector((state: RootState) => selectAllAccounts(state.accounts));
  // const primaryServer = onlyShowServer || serversState.server;
  // const accountsOnPrimaryServer = server ? accounts.filter(a => serverUrl(a.server) == serverUrl(server!)) : [];
  const accountsOnServer = server ? accounts.filter(a => serverID(a.server) == serverID(server!)) : [];

  const postsState = useRootSelector((state: RootState) => state.posts);
  const accountsLoading = accountsState.status == 'loading';
  const valid = name.length > 0;

  const showEditor = edit(renderType);
  const showFullPreview = fullPreview(renderType);
  const showShortPreview = shortPreview(renderType);

  useEffect(() => {
    if (open) {
      setHasOpened(true);
    }
  }, [open]);

  const [isCreating, setIsCreating] = useState(false);
  const disableInputs = isCreating;
  const disableCreate = disableInputs || !valid || !hasPermission(account?.user, Permission.CREATE_GROUPS);
  const createDisabledReason = !valid
    ? 'Group name is required.'
    : !hasPermission(account?.user, Permission.CREATE_GROUPS)
      ? 'You do not have permission to create groups with this account.'
      : disableInputs
        ? 'Creating group...'
        : undefined;

  // return <></>;
  const avatarUrl = useMediaUrl(avatar?.id);
  const hasAvatarUrl = avatarUrl && avatarUrl != '';

  return (
    <>
      <Button backgroundColor={primaryColor}
        o={0.95}
        hoverStyle={{ backgroundColor: primaryColor, opacity: 1 }}
        color={primaryTextColor}
        // f={1}
        my='auto'
        disabled={server === undefined}
        onPress={() => setOpen(!open)}>
        <Heading size='$2' color={primaryTextColor}>Create Group</Heading>
      </Button>
      {true && (open || hasOpened)
        ? <Sheet
          modal
          open={open}
          onOpenChange={setOpen}
          // snapPoints={[80]}
          snapPoints={[83]} dismissOnSnapToBottom
          position={position}
          onPositionChange={setPosition}
        // dismissOnSnapToBottom
        >
          <Sheet.Overlay />
          <Sheet.Frame>
            <YStack h='100%'>
              <Sheet.Handle />
              <XStack als='center' ai='center' w='100%' px='$5' mb='$2' maw={800}>
                <Button
                  alignSelf='center'
                  size="$3"
                  circular
                  icon={ChevronLeft}
                  mr='$2'
                  onPress={() => {
                    setOpen(false)
                  }}
                />
                <Heading marginVertical='auto' f={1} size='$7'>New Group</Heading>
                <Button backgroundColor={showSettings ? navColor : undefined}
                  hoverStyle={{ backgroundColor: showSettings ? navColor : undefined }}
                  onPress={() => setShowSettings(!showSettings)} circular mr='$2'>
                  <Cog color={showSettings ? navTextColor : textColor} />
                </Button>

                <Tooltip>
                  <Tooltip.Trigger>
                    <Button backgroundColor={primaryColor} disabled={disableCreate} opacity={disableCreate ? 0.5 : 1}
                      onPress={() => doCreate()}>
                      <Heading size='$1' color={primaryTextColor}>Create</Heading>
                    </Button>
                  </Tooltip.Trigger>
                  <Tooltip.Content>
                    <Paragraph size='$2'>
                      {createDisabledReason}
                    </Paragraph>
                  </Tooltip.Content>
                </Tooltip>
              </XStack>
              <CreationServerSelector requiredPermissions={[Permission.CREATE_GROUPS]} />

              <Sheet.ScrollView>
                {error ? <Heading size="$2" color="red" alignSelf='center' ta='center'>{error}</Heading> : undefined}
                {/* {postsState.createPostStatus == "errored" && postsState.errorMessage ?
                <Heading size='$1' color='red' p='$2' ac='center' jc='center' ta='center'>{postsState.errorMessage}</Heading> : undefined} */}

                <XStack f={1} mb='$4' gap="$2" maw={600} w='100%' als='center' paddingHorizontal="$5">
                  <FlipMove style={{ width: '100%' }}>
                    {/* <YStack gap="$2" w='100%'> */}
                    <div key='name-media' style={{ width: '100%', marginBottom: 8 }}>
                      <XStack>
                        <Input f={1}
                          my='auto'
                          textContentType="name" placeholder={`Group Name (required)`}
                          borderColor={name == '' ? navAnchorColor : undefined}
                          placeholderTextColor={navAnchorColor}
                          disabled={disableInputs} opacity={disableInputs || name == '' ? 0.5 : 1}
                          // onFocus={() => setShowSettings(false)}
                          // autoCapitalize='words'
                          value={name}
                          onChange={(data) => { setName(data.nativeEvent.text) }} />
                        <Button p='$0'
                          ml='$2'
                          {...themedButtonBackground(showMedia ? navColor : undefined, showMedia ? navTextColor : undefined,)}
                          onPress={() => setShowMedia(!showMedia)}
                          height={hasAvatarUrl ? fullAvatarHeight : undefined}
                        >
                          {hasAvatarUrl
                            ? <Image
                              // mb='$3'
                              // ml='$2'
                              my='auto'
                              width={fullAvatarHeight}
                              height={fullAvatarHeight}
                              resizeMode="contain"
                              als="center"
                              source={{ uri: avatarUrl, height: fullAvatarHeight, width: fullAvatarHeight }}
                              borderRadius={10} />
                            : <XStack px='$2'>
                              <FileImage color={showMedia ? navTextColor : undefined} />
                            </XStack>}
                        </Button>
                      </XStack>
                    </div>
                    {showSettings
                      ? <div key='create-group-settings' style={{ width: '100%', marginBottom: 8 }}>
                        <YStack key='create-group-settings'
                          animation='standard'
                          p='$2'
                          backgroundColor='$backgroundHover'
                          borderRadius='$5'
                          // touch={showSettings}
                          {...standardAnimation}
                        >
                          <XStack mx='auto'>
                            <VisibilityPicker
                              label='Group Visibility'
                              visibility={visibility}
                              disabled={disableInputs}
                              onChange={setVisibility}
                              visibilityDescription={v => groupVisibilityDescription(v, server)} />
                          </XStack>
                          <ToggleRow name='Require Membership Moderation'
                            value={pending(defaultMembershipModeration)}
                            setter={(v) => setDefaultMembershipModeration(v ? Moderation.PENDING : Moderation.UNMODERATED)}
                            disabled={disableInputs} />
                          <ToggleRow name='Require Post Moderation'
                            description='Hide all Posts shared to this Group until approved by a moderator.'
                            value={pending(defaultPostModeration)}
                            setter={(v) => setDefaultPostModeration(v ? Moderation.PENDING : Moderation.UNMODERATED)}
                            disabled={disableInputs} />
                          <ToggleRow name='Require Event Moderation'
                            description='Hide all Events shared to this Group until approved by a moderator.'
                            value={pending(defaultEventModeration)}
                            setter={(v) => setDefaultEventModeration(v ? Moderation.PENDING : Moderation.UNMODERATED)}
                            disabled={disableInputs} />
                          <PermissionsEditor label='Default Member Permissions'
                            {...membershipPermissionsEditorProps} />
                          <PermissionsEditor label='Non-Member Permissions'
                            {...nonMemberPermissionsEditorProps} />
                        </YStack>
                      </div>
                      : undefined}
                    {showMedia
                      ? <div key='single-media-chooser' style={{ width: '100%', marginBottom: 8 }}>
                        <SingleMediaChooser key='create-group-avatar-chooser'
                          disabled={!showMedia}
                          selectedMedia={avatar} setSelectedMedia={setAvatar} />
                      </div>
                      : undefined}

                    <div key='description' style={{ width: '100%', marginBottom: 8 }}>
                      <TextArea f={1} pt='$2' value={description} ref={textAreaRef}
                        w='100%'
                        disabled={posting} opacity={posting || description == '' ? 0.5 : 1}
                        onChangeText={t => setDescription(t)}
                        placeholder={`Group description (optional). Markdown is supported.`} />
                    </div>
                    {/* {accountsState.errorMessage ? <Heading size="$2" color="red" alignSelf='center' ta='center'>{accountsState.errorMessage}</Heading> : undefined}
                    {accountsState.successMessage ? <Heading size="$2" color="green" alignSelf='center' ta='center'>{accountsState.successMessage}</Heading> : undefined} */}
                    {/* </YStack> */}
                  </FlipMove>
                </XStack>
              </Sheet.ScrollView>
            </YStack>
          </Sheet.Frame>
        </Sheet>
        : undefined}
    </>
  )
}
