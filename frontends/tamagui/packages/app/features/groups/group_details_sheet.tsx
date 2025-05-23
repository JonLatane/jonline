import { Group, Moderation, Permission, Visibility } from '@jonline/api';
import { AnimatePresence, Button, Heading, Image, Input, Paragraph, Sheet, TextArea, XStack, YStack, standardAnimation, useToastController } from '@jonline/ui';
import { PayloadAction } from '@reduxjs/toolkit';
import { ChevronLeft, Cog, FileImage } from '@tamagui/lucide-icons';
import { EditingContextProvider, PermissionsEditor, PermissionsEditorProps, SaveButtonGroup, TamaguiMarkdown, ToggleRow, VisibilityPicker, useEditableState, useStatefulEditingContext } from 'app/components';
import { useGroupContext } from 'app/contexts';
import { useNavigationContext } from 'app/contexts/navigation_context';
import { useCurrentServer, useFederatedDispatch, useMediaUrl, usePinnedAccountsAndServers } from 'app/hooks';
import { RootState, actionFailed, deleteGroup, federatedId, updateGroup, useRootSelector, useServerTheme } from 'app/store';
import { passes, pending } from 'app/utils';
import React, { useState } from 'react';
import { createParam } from 'solito';
import { useLink } from 'solito/link';
import { SingleMediaChooser } from '../accounts/single_media_chooser';
import { AppSection } from '../navigation/features_navigation';
import { ServerNameAndLogo, splitOnFirstEmoji } from '../navigation/server_name_and_logo';
import { } from '../post/post_card';
import { groupVisibilityDescription } from './create_group_sheet';
import { GroupJoinLeaveButton } from './group_buttons';


export const groupUserPermissions = [
  Permission.VIEW_USERS,
  // Permission.PUBLISH_USERS_LOCALLY,
  // Permission.PUBLISH_USERS_GLOBALLY,
  // Permission.VIEW_GROUPS,
  // Permission.CREATE_GROUPS,
  // Permission.VIEW_MEDIA,
  // Permission.CREATE_MEDIA,
  // Permission.PUBLISH_MEDIA_LOCALLY,
  // Permission.PUBLISH_MEDIA_GLOBALLY,
  // Permission.PUBLISH_GROUPS_LOCALLY,
  // Permission.PUBLISH_GROUPS_GLOBALLY,
  // Permission.JOIN_GROUPS,
  Permission.VIEW_POSTS,
  Permission.CREATE_POSTS,
  // Permission.PUBLISH_POSTS_LOCALLY,
  // Permission.PUBLISH_POSTS_GLOBALLY,
  Permission.VIEW_EVENTS,
  Permission.CREATE_EVENTS,
  // Permission.PUBLISH_EVENTS_LOCALLY,
  // Permission.PUBLISH_EVENTS_GLOBALLY,
  Permission.ADMIN,
];

export type GroupDetailsSheetProps = {
  // selectedGroup?: FederatedGroup;
  // infoGroupId?: string;
  // infoOpen: boolean;
  // setInfoOpen: (infoOpen: boolean) => void;
  hideLeaveButtons?: boolean;
}

const { useParam, useUpdateParams } = createParam<{ shortname: string | undefined }>();
export function GroupDetailsSheet({ hideLeaveButtons }: GroupDetailsSheetProps) {
  const { infoGroupId, setInfoGroupId, selectedGroup } = useGroupContext();
  const infoGroup = useRootSelector((state: RootState) =>
    infoGroupId ? state.groups.entities[infoGroupId] : undefined);
  // debugger;
  const [position, setPosition] = useState(0);
  const { dispatch, accountOrServer } = useFederatedDispatch(infoGroup);
  const { account, server } = accountOrServer;
  // const server = accountOrServer.server;
  const currentServer = useCurrentServer();
  const isPrimaryServer = currentServer?.host === accountOrServer.server?.host;
  const currentAndPinnedServers = usePinnedAccountsAndServers();
  const showServerInfo = !isPrimaryServer || currentAndPinnedServers.length > 1;


  // const dispatch = useAppDispatch();
  const groupIdentifier = infoGroup
    ? isPrimaryServer ? infoGroup.shortname : `${infoGroup.shortname}@${infoGroup.serverHost}`
    : undefined;
  // const { groupPageForwarder, groupPageReverse } = useNavigationContext();
  const linkToGroup = useLink({
    href: `/g/${groupIdentifier}`
  });
  const linkToMembers = useLink({
    href: `/g/${groupIdentifier}/members`
  });

  const [queryShortname] = useParam('shortname');
  const updateParams = useUpdateParams();

  const infoRenderingGroup = infoGroup ?? selectedGroup;
  const canEditGroup = !!account?.user?.permissions?.includes(Permission.ADMIN)
    || !!infoRenderingGroup?.currentUserMembership?.permissions?.includes(Permission.ADMIN);
  const editingContext = useStatefulEditingContext(canEditGroup);
  const { editing, setEditing, previewingEdits, setPreviewingEdits, savingEdits, setSavingEdits, deleting, setDeleting } = editingContext;

  const { textColor, navColor, navTextColor, navAnchorColor } = useServerTheme(server);

  const homeLink = useLink({ href: '/' });

  async function doDeleteGroup() {
    dispatch(deleteGroup({ ...accountOrServer, ...(infoRenderingGroup!) })).then((action) => {
      setDeleted(true);
      setInfoGroupId(undefined);
      setDeleting(false);
      // actionFailed
      return action;
    }).then(() => {
      if (queryShortname !== undefined && queryShortname.length > 0 && queryShortname === infoRenderingGroup?.shortname) {
        window.location.replace('/');
      }
    });
  }

  const [name, editedName, setEditedName] = useEditableState<string>(infoRenderingGroup?.name ?? '', editingContext);
  const [description, editedDescription, setEditedDescription] = useEditableState<string>(infoRenderingGroup?.description ?? '', editingContext);
  const [avatar, editedAvatar, setEditedAvatar] = useEditableState(infoRenderingGroup?.avatar, editingContext);
  const [visibility, editedVisibility, setEditedVisibility] = useEditableState(infoRenderingGroup?.visibility ?? Visibility.VISIBILITY_UNKNOWN, editingContext);
  const [defaultMembershipModeration, editedDefaultMembershipModeration, setEditedDefaultMembershipModeration] = useEditableState(infoRenderingGroup?.defaultMembershipModeration ?? Moderation.MODERATION_UNKNOWN, editingContext);
  const [defaultPostModeration, editedDefaultPostModeration, setEditedDefaultPostModeration] = useEditableState(infoRenderingGroup?.defaultPostModeration ?? Moderation.MODERATION_UNKNOWN, editingContext);
  const [defaultEventModeration, editedDefaultEventModeration, setEditedDefaultEventModeration] = useEditableState(infoRenderingGroup?.defaultEventModeration ?? Moderation.MODERATION_UNKNOWN, editingContext);
  const [defaultMembershipPermissions, editedDefaultMembershipPermissions, setEditedDefaultMembershipPermissions] = useEditableState(infoRenderingGroup?.defaultMembershipPermissions ?? [], editingContext);
  const [nonMemberPermissions, editedNonMemberPermissions, setEditedNonMemberPermissions] = useEditableState(infoRenderingGroup?.nonMemberPermissions ?? [], editingContext);

  const updatedGroup: Group = {
    ...accountOrServer,
    ...(infoRenderingGroup!),
    name: editedName,
    description: editedDescription,
    avatar: editedAvatar,
    visibility,
    defaultMembershipModeration,
    defaultPostModeration,
    defaultEventModeration,
    defaultMembershipPermissions,
    nonMemberPermissions,
  };

  const toast = useToastController();
  function doUpdateGroup() {
    requestAnimationFrame(() => {
      dispatch(updateGroup(updatedGroup)).then((action: PayloadAction<Group, any, any>) => {
        setSavingEdits(false);
        setEditing(false);
        setPreviewingEdits(false);

        if (actionFailed(action)) {
          toast.show('Failed to update group.');
          console.error('Failed to update group', action);
          return action;
        }

        const updatedShortname = action.payload.shortname;

        // console.log('shortname', shortname, 'infoRenderingGroup?.shortname', infoRenderingGroup?.shortname);
        if (queryShortname !== undefined && queryShortname.length > 0 && updatedShortname.length > 0
          && queryShortname === infoRenderingGroup?.shortname && queryShortname !== updatedShortname) {
          console.log('replacing shortname')
          updateParams({ shortname: action.payload.shortname }, { web: { replace: true } });
        }
      });
    });
  }

  // useEffect(() => {
  //   if (infoGroup) {
  //     setEditing(false);
  //     setEditedName(infoGroup.name);
  //     setEditedDescription(infoGroup.description ?? '');
  //     setEditedAvatar(infoGroup.avatar);
  //   }
  // }, [infoGroupId, server ? serverID(server) : 'no server']);

  const [deleted, setDeleted] = useState(false);

  const [showMedia, _setShowMedia] = useState(false);
  const [showSettings, _setShowSettings] = useState(false);
  const disableInputs = !editing || previewingEdits || savingEdits || deleting;
  function setShowMedia(v: boolean) {
    _setShowMedia(v);
    if (v && showSettings) {
      _setShowSettings(false);
    }
  }
  function setShowSettings(v: boolean) {
    _setShowSettings(v);
    if (v && showMedia) {
      _setShowMedia(false);
    }
  }

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
  const isGroupAdmin = infoRenderingGroup?.currentUserMembership?.permissions?.includes(Permission.ADMIN);
  const membershipPermissionsEditorProps: PermissionsEditorProps = {
    selectablePermissions: groupUserPermissions,
    selectedPermissions: defaultMembershipPermissions,
    selectPermission: (p: Permission) => selectDefaultPermission(p, defaultMembershipPermissions, setEditedDefaultMembershipPermissions),
    deselectPermission: (p: Permission) => deselectDefaultPermission(p, defaultMembershipPermissions, setEditedDefaultMembershipPermissions),
    editMode: editing,
  };
  const nonMemberPermissionsEditorProps: PermissionsEditorProps = {
    selectablePermissions: groupUserPermissions.filter(p => ![Permission.ADMIN].includes(p)),
    selectedPermissions: nonMemberPermissions,
    selectPermission: (p: Permission) => selectDefaultPermission(p, nonMemberPermissions, setEditedNonMemberPermissions),
    deselectPermission: (p: Permission) => deselectDefaultPermission(p, nonMemberPermissions, setEditedNonMemberPermissions),
    editMode: editing,
  };


  //TODO: Simplify/abstract this into its own component? But then, with this design, will there ever be a need
  // for a *third* "Join" button in this app?
  const joined = passes(infoRenderingGroup?.currentUserMembership?.userModeration)
    && passes(infoRenderingGroup?.currentUserMembership?.groupModeration);
  const membershipRequested = infoRenderingGroup?.currentUserMembership && !joined && passes(infoRenderingGroup?.currentUserMembership?.userModeration);
  const invited = infoRenderingGroup?.currentUserMembership && !joined && passes(infoRenderingGroup?.currentUserMembership?.groupModeration);

  const avatarUrl = useMediaUrl(avatar?.id);
  const hasAvatarUrl = avatarUrl && avatarUrl != '';
  const fullAvatarHeight = 72;

  const [groupNameBeforeEmoji, groupNameEmoji, groupNameAfterEmoji] = splitOnFirstEmoji(name);
  const displayedGroupName = groupNameEmoji && !hasAvatarUrl
    ? groupNameBeforeEmoji + (
      groupNameAfterEmoji && groupNameAfterEmoji != ''
        ? ' | ' + groupNameAfterEmoji
        : '')
    : name;

  const { appSection } = useNavigationContext();
  const groupNameAndLogo = <XStack f={1}>
    {editing && !previewingEdits //&& infoRenderingGroup?.id != selectedGroup?.id
      ? <Input textContentType="name" f={1}
        my='auto'
        mr='$2'
        placeholder={`Group Name (required)`}
        disabled={savingEdits} opacity={savingEdits || editedName == '' ? 0.5 : 1}
        // autoCapitalize='words'
        value={editedName}
        onChange={(data) => { setEditedName(data.nativeEvent.text) }} />
      : <Heading my='auto' f={1}>{displayedGroupName}</Heading>}


    {editing && !previewingEdits
      ?
      <Button p='$0'
        ml='$2'
        my='auto'
        mr='$2'
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
            <FileImage />
          </XStack>}
      </Button>
      : hasAvatarUrl
        ? <Image
          // mb='$3'
          // ml='$2'
          mr='$2'
          my='auto'
          width={fullAvatarHeight}
          height={fullAvatarHeight}
          resizeMode="contain"
          als="center"
          source={{ uri: avatarUrl, height: fullAvatarHeight, width: fullAvatarHeight }}
          borderRadius={10} />
        : groupNameEmoji
          ? <Heading size='$10' my='auto' mx='$3' whiteSpace="nowrap">
            {groupNameEmoji}
          </Heading>
          : undefined}
  </XStack>;

  const alreadyOnGroupPage = !!infoGroup && !!selectedGroup && federatedId(infoGroup) === federatedId(selectedGroup) && appSection === AppSection.HOME;
  // console.log('GroupDetailsSheet', 'alreadyOnGroupPage', alreadyOnGroupPage, !!infoGroup, !!selectedGroup, infoGroup && federatedId(infoGroup), selectedGroup && federatedId(selectedGroup), appSection);
  return <EditingContextProvider value={editingContext}>
    <Sheet
      modal
      open={!!infoGroupId}
      onOpenChange={(v) => v ? undefined : setInfoGroupId(undefined)}
      snapPoints={[81]}
      position={position}
      onPositionChange={setPosition}
      dismissOnSnapToBottom
      zIndex={1000000}
    >
      <Sheet.Overlay />
      <Sheet.Frame>
        <Sheet.Handle />
        <XStack gap='$2' paddingHorizontal='$3' ai='center' w='100%'>

          <Button
            // alignSelf='center'
            size="$2"
            // mb='$3'
            circular
            icon={ChevronLeft}
            onPress={() => setInfoGroupId(undefined)} />
          {/* <XStack f={1} /> */}
          {showServerInfo
            ? <XStack my='auto' f={2} >
              <ServerNameAndLogo server={server} />
            </XStack>
            : undefined}
          {/* <Button
            disabled o={0}
            alignSelf='center'
            size="$3"
            mb='$3'
            circular
          // icon={ChevronDown}
          // onPress={() => setInfoOpen(false)} 
          /> */}

          <XStack f={1} />

          {showServerInfo && !isPrimaryServer
            ? <YStack my='auto' f={1} ai='flex-start' jc='flex-start' o={0.5}>
              <Paragraph pl='$2' size='$1'>on</Paragraph>
              <ServerNameAndLogo server={currentServer} />
            </YStack>
            : undefined}

          <Button size='$3' backgroundColor={showSettings ? navColor : undefined}
            hoverStyle={{ backgroundColor: showSettings ? navColor : undefined }}
            onPress={() => setShowSettings(!showSettings)} circular my='auto'>
            <Cog color={showSettings ? navTextColor : undefined} />
          </Button>
        </XStack>

        <YStack gap="$0" px='$4' maw={800} als='center' width='100%'>
          <XStack>

            {editing || alreadyOnGroupPage
              ? groupNameAndLogo
              : <Button px='$1' h='auto' transparent {...linkToGroup} f={1}>
                {groupNameAndLogo}
              </Button>}
            {infoRenderingGroup
              ? <GroupJoinLeaveButton group={infoRenderingGroup} hideLeaveButton={hideLeaveButtons} />
              : undefined}
          </XStack>
          <XStack ai='center'>
            {/* <Heading size='$2'>{server?.host}/g/{infoRenderingGroup?.shortname}</Heading> */}
            <XStack f={1} />
            <Button transparent {...linkToMembers}>
              <Heading size='$1'>
                {infoRenderingGroup?.memberCount} member{infoRenderingGroup?.memberCount == 1 ? '' : 's'}
              </Heading>
            </Button>
          </XStack>
        </YStack>
        <Sheet.ScrollView>
          <YStack gap="$0" px='$4' maw={800} als='center' width='100%'>
            {/* <AnimatePresence> */}
            <YStack mx='$3'>
              {editing && !previewingEdits && showMedia
                ? <SingleMediaChooser key='create-group-avatar-chooser'
                  disabled={!showMedia}
                  selectedMedia={avatar} setSelectedMedia={setEditedAvatar} />
                : undefined}
            </YStack>
            {/* </AnimatePresence> */}


            <AnimatePresence>
              {showSettings
                ? <YStack key='edit-group-settings'
                  animation='standard'
                  mt='$2'
                  p='$2'
                  backgroundColor='$backgroundHover'
                  borderColor='$color'
                  borderWidth={1}
                  borderRadius='$2'
                  // touch={showSettings}

                  {...standardAnimation}
                >
                  <XStack mx='auto'>
                    <VisibilityPicker
                      label='Group Visibility'
                      visibility={visibility}
                      disabled={disableInputs}
                      onChange={setEditedVisibility}
                      visibilityDescription={v => groupVisibilityDescription(v, server)} />
                  </XStack>
                  <ToggleRow name='Require Membership Moderation'
                    value={pending(defaultMembershipModeration)}
                    setter={(v) => setEditedDefaultMembershipModeration(v ? Moderation.PENDING : Moderation.UNMODERATED)}
                    disabled={disableInputs} />
                  <ToggleRow name='Require Post Moderation'
                    description='Hide all Posts shared to this Group until approved by a moderator.'
                    value={pending(defaultPostModeration)}
                    setter={(v) => setEditedDefaultPostModeration(v ? Moderation.PENDING : Moderation.UNMODERATED)}
                    disabled={disableInputs} />
                  <ToggleRow name='Require Event Moderation'
                    description='Hide all Events shared to this Group until approved by a moderator.'
                    value={pending(defaultEventModeration)}
                    setter={(v) => setEditedDefaultEventModeration(v ? Moderation.PENDING : Moderation.UNMODERATED)}
                    disabled={disableInputs} />

                  <PermissionsEditor label='Default Member Permissions'
                    {...membershipPermissionsEditorProps} />
                  <PermissionsEditor label='Non-Member Permissions'
                    {...nonMemberPermissionsEditorProps} />
                </YStack>
                : undefined}
            </AnimatePresence>
          </YStack>
          {editing && !previewingEdits
            ? <TextArea f={1} pt='$2' mx='$3' value={editedDescription}
              disabled={savingEdits} opacity={savingEdits || editedDescription == '' ? 0.5 : 1}
              h={(editedDescription?.length ?? 0) > 300 ? window.innerHeight - 100 : undefined}
              onChangeText={setEditedDescription}
              placeholder={`Description (optional). Markdown is supported.`} />
            : //<Sheet.ScrollView p="$4" space>
            <YStack maw={600} als='center' width='100%' px='$4'>
              <TamaguiMarkdown text={description} />
            </YStack>
            //</Sheet.ScrollView>
          }
        </Sheet.ScrollView>
        <SaveButtonGroup entityType='Group'
          entityName={infoRenderingGroup?.name}
          doUpdate={() => doUpdateGroup()}
          doDelete={() => doDeleteGroup()}
          deleteDialogText={
            <YStack gap='$3'>
              <Paragraph>
                Really delete the group "{infoRenderingGroup?.name ?? 'group'}"?
              </Paragraph>
              <Paragraph>
                The group will be deleted along with any group post/event associations.
                Posts/events themselves belong to the users who posted them, not {infoRenderingGroup?.name ?? 'this group'}.
              </Paragraph>
            </YStack>
          }
        // deleteInstructions={infoRenderingGroup?.id != selectedGroup?.id
        //   ? undefined
        //   : <Paragraph size='$1' ml='auto' my='auto'>
        //     To delete or edit group name, view this group's info from the <Anchor size='$1' color={navAnchorColor} {...homeLink}>home page</Anchor>.
        //   </Paragraph>
        // } 
        />
      </Sheet.Frame >
    </Sheet >
  </EditingContextProvider >;
}

