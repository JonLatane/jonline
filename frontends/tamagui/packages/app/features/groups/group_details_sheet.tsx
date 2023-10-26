import { Empty, GetGroupsRequest, Group, Permission, Post } from '@jonline/api';
import { Button, Heading, Input, Image, Paragraph, Sheet, Theme, useMedia, XStack, YStack, Text, standardAnimation, Separator, ZStack, Dialog, ListItemText, YGroup, ListItem, TextArea, Anchor, AnimatePresence } from '@jonline/ui';
import { Boxes, Calendar, ChevronDown, Cloud, Delete, Edit, Eye, FileImage, Info, MessageSquare, Moon, Save, Search, Star, Sun, Users, Users2, X as XIcon } from '@tamagui/lucide-icons';
import { RootState, isGroupLocked, deleteGroup, updateGroup, joinLeaveGroup, selectAllGroups, serverID, loadGroupsPage, useAccount, useAccountOrServer, useCredentialDispatch, useServerTheme, useTypedDispatch, useTypedSelector, DeleteGroup, actionFailed } from 'app/store';
import React, { createRef, useEffect, useState } from 'react';
import { FlatList, GestureResponderEvent, TextInput, View } from 'react-native';
import { useLink } from 'solito/link';
import { } from '../post/post_card';
import { TamaguiMarkdown } from '../post/tamagui_markdown';
import { passes, pending } from '../../utils/moderation_utils';
import { CreateGroupSheet } from './create_group_sheet';
import { GroupButton, GroupJoinLeaveButton } from './group_buttons';
import { SingleMediaChooser } from '../accounts/single_media_chooser';
import { useMediaUrl } from 'app/hooks';
import { EditingContextProvider, SaveButtonGroup, useEditableState, useStatefulEditingContext } from '../../components/save_button_group';
import { PayloadAction } from '@reduxjs/toolkit';

export type GroupDetailsSheetProps = {
  selectedGroup?: Group;
  infoGroupId?: string;
  infoOpen: boolean;
  setInfoOpen: (infoOpen: boolean) => void;
  hideLeaveButtons?: boolean;
}

export function GroupDetailsSheet({ infoGroupId, selectedGroup, infoOpen, setInfoOpen, hideLeaveButtons }: GroupDetailsSheetProps) {
  const infoGroup = useTypedSelector((state: RootState) =>
    infoGroupId ? state.groups.entities[infoGroupId] : undefined);
  const [position, setPosition] = useState(0);
  const { dispatch, accountOrServer } = useCredentialDispatch();
  const { account, server } = accountOrServer;

  const infoRenderingGroup = infoGroup ?? selectedGroup;
  const canEditGroup = !!account?.user?.permissions?.includes(Permission.ADMIN)
    || !!infoRenderingGroup?.currentUserMembership?.permissions?.includes(Permission.ADMIN);
  const editingContext = useStatefulEditingContext(canEditGroup);
  const { editing, setEditing, previewingEdits, setPreviewingEdits, savingEdits, setSavingEdits, deleting, setDeleting } = editingContext;

  const { navAnchorColor } = useServerTheme();

  // const groupsState = useTypedSelector((state: RootState) => state.groups);
  // const [loadingGroups, setLoadingGroups] = useState(false);
  const homeLink = useLink({ href: '/' });
  // useEffect(() => {
  //   if (!loadingGroups && groupsState.status == 'unloaded' && !extraListItemChrome) {
  //     setLoadingGroups(true);
  //     reloadGroups();
  //   } else if (loadingGroups && !['unloaded', 'loading'].includes(groupsState.status)) {
  //     setLoadingGroups(false);
  //   }
  // });

  // function reloadGroups() {
  //   if (!accountOrServer.server) return;

  //   setTimeout(() =>
  //     dispatch(loadGroupsPage({ ...accountOrServer, ...GetGroupsRequest.create() })), 1);
  // }

  function doUpdateGroup() {
    dispatch(updateGroup({
      ...accountOrServer,
      ...(infoRenderingGroup!),
      name: editedName,
      description: editedDescription,
      avatar: editedAvatar,
      // This will force the server to derive a new shortname based on the edited name.
      // Maybe eventually it's worth exposing explicit shortname editing in the UI.
      shortname: ''
    })).then(() => {
      setSavingEdits(false);
      setEditing(false);
      setPreviewingEdits(false);
    });
  }
  async function doDeleteGroup() {
    // setDeleting(true);
    dispatch(deleteGroup({ ...accountOrServer, ...(infoRenderingGroup!) })).then((result) => {
      setDeleted(true);
      setInfoOpen(false);
      setDeleting(false);
      actionFailed
      return result;
    });
  }

  const [name, editedName, setEditedName] = useEditableState<string>(infoRenderingGroup?.name ?? '', editingContext);
  const [description, editedDescription, setEditedDescription] = useEditableState<string>(infoRenderingGroup?.description ?? '', editingContext);
  const [avatar, editedAvatar, setEditedAvatar] = useEditableState(infoRenderingGroup?.avatar, editingContext);
  const [visibility, editedVisibility, setEditedVisibility] = useEditableState(infoRenderingGroup?.visibility, editingContext);
  const [defaultMembershipModeration, editedDefaultMembershipModeration, setEditedDefaultMembershipModeration] = useEditableState(infoRenderingGroup?.defaultMembershipModeration, editingContext);
  const [defaultPostModeration, editedDefaultPostModeration, setEditedDefaultPostModeration] = useEditableState(infoRenderingGroup?.defaultPostModeration, editingContext);
  const [defaultEventModeration, editedDefaultEventModeration, setEditedDefaultEventModeration] = useEditableState(infoRenderingGroup?.defaultEventModeration, editingContext);

  const [deleted, setDeleted] = useState(false);

  const [showMedia, setShowMedia] = useState(false);
  const [showSettings, setShowSettings] = useState(false);

  useEffect(() => {
    if (infoGroup) {
      setEditing(false);
      setEditedName(infoGroup.name);
      setEditedDescription(infoGroup.description ?? '');
      setEditedAvatar(infoGroup.avatar);
    }
  }, [infoGroupId, server ? serverID(server) : 'no server']);


  //TODO: Simplify/abstract this into its own component? But then, with this design, will there ever be a need
  // for a *third* "Join" button in this app?
  const joined = passes(infoRenderingGroup?.currentUserMembership?.userModeration)
    && passes(infoRenderingGroup?.currentUserMembership?.groupModeration);
  const membershipRequested = infoRenderingGroup?.currentUserMembership && !joined && passes(infoRenderingGroup?.currentUserMembership?.userModeration);
  const invited = infoRenderingGroup?.currentUserMembership && !joined && passes(infoRenderingGroup?.currentUserMembership?.groupModeration);

  const avatarUrl = useMediaUrl(avatar?.id);
  const hasAvatarUrl = avatarUrl && avatarUrl != '';
  const fullAvatarHeight = 72;

  return <EditingContextProvider value={editingContext}>
    <Sheet
      modal
      open={infoOpen}
      onOpenChange={setInfoOpen}
      snapPoints={[81]}
      position={position}
      onPositionChange={setPosition}
      dismissOnSnapToBottom
    >
      <Sheet.Overlay />
      <Sheet.Frame>
        <Sheet.Handle />
        <XStack space='$4' paddingHorizontal='$3'>
          <XStack f={1} />
          <Button
            alignSelf='center'
            size="$4"
            mb='$3'
            circular
            icon={ChevronDown}
            onPress={() => setInfoOpen(false)} />
          <XStack f={1} />
        </XStack>

        <YStack space="$3" p='$4' maw={800} als='center' width='100%'>
          <XStack>
            {editing && !previewingEdits
              ? <Input textContentType="name" f={1}
                my='auto'
                mr='$2'
                placeholder={`Group Name (required)`}
                disabled={savingEdits} opacity={savingEdits || editedName == '' ? 0.5 : 1}
                autoCapitalize='words'
                value={editedName}
                onChange={(data) => { setEditedName(data.nativeEvent.text) }} />
              : <Heading my='auto' f={1}>{name}</Heading>}


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
                : undefined}
            {infoRenderingGroup
              ? <GroupJoinLeaveButton group={infoRenderingGroup} hideLeaveButton={hideLeaveButtons} />
              : undefined}
          </XStack>

          <AnimatePresence>
            <YStack mx='$3'>
              {editing && !previewingEdits && showMedia
                ? <SingleMediaChooser key='create-group-avatar-chooser'
                  disabled={!showMedia}
                  selectedMedia={avatar} setSelectedMedia={setEditedAvatar} />
                : undefined}
            </YStack>
          </AnimatePresence>

          <XStack>
            <Heading size='$2'>{server?.host}/g/{infoRenderingGroup?.shortname}</Heading>
            <XStack f={1} />
            <Heading size='$1' marginVertical='auto'>
              {infoRenderingGroup?.memberCount} member{infoRenderingGroup?.memberCount == 1 ? '' : 's'}
            </Heading>
          </XStack>
        </YStack>
        {editing && !previewingEdits
          ? <TextArea f={1} pt='$2' mx='$3' value={editedDescription}
            disabled={savingEdits} opacity={savingEdits || editedDescription == '' ? 0.5 : 1}
            h={(editedDescription?.length ?? 0) > 300 ? window.innerHeight - 100 : undefined}
            onChangeText={setEditedDescription}
            placeholder={`Description (optional). Markdown is supported.`} />
          : <Sheet.ScrollView p="$4" space>
            <YStack maw={600} als='center' width='100%'>
              <TamaguiMarkdown text={description} />
            </YStack>
          </Sheet.ScrollView>
        }
        <SaveButtonGroup entityType='Group'
          entityName={infoRenderingGroup?.name}
          doUpdate={() => doUpdateGroup()}
          doDelete={() => doDeleteGroup()}
          deleteDialogText={
            <YStack space='$3'>
              <Paragraph>
                Really delete the group "{infoRenderingGroup?.name ?? 'group'}"?
              </Paragraph>
              <Paragraph>
                The group will be deleted along with any group post/event associations.
                Posts/events themselves belong to the users who posted them, not {infoRenderingGroup?.name ?? 'this group'}.
              </Paragraph>
            </YStack>
          }
          deleteInstructions={infoRenderingGroup != selectedGroup
            ? undefined
            : <Paragraph size='$1' ml='auto' my='auto'>
              To delete, view this group's info from the <Anchor size='$1' color={navAnchorColor} {...homeLink}>home page</Anchor>.
            </Paragraph>
          } />
      </Sheet.Frame >
    </Sheet >
  </EditingContextProvider >;
}

