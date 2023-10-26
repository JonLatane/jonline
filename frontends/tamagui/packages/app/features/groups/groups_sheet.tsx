import { GetGroupsRequest, Group, Permission, Post } from '@jonline/api';
import { Button, Heading, Input, Paragraph, Sheet, Theme, useMedia, XStack, YStack, Text, standardAnimation, Separator, ZStack, Dialog, ListItemText, YGroup, ListItem } from '@jonline/ui';
import { Boxes, Calendar, ChevronDown, Cloud, Delete, Edit, Eye, Info, MessageSquare, Moon, Save, Search, Star, Sun, Users, Users2, X as XIcon } from '@tamagui/lucide-icons';
import { RootState, isGroupLocked, joinLeaveGroup, selectAllGroups, serverID, updateGroups, useAccount, useAccountOrServer, useCredentialDispatch, useServerTheme, useTypedDispatch, useTypedSelector } from 'app/store';
import React, { createRef, useEffect, useState } from 'react';
import { FlatList, GestureResponderEvent, TextInput, View } from 'react-native';
import { useLink } from 'solito/link';
import { } from '../post/post_card';
import { TamaguiMarkdown } from '../post/tamagui_markdown';
import { passes, pending } from '../../utils/moderation_utils';
import { CreateGroupSheet } from './create_group_sheet';
import { GroupButton, GroupJoinLeaveButton } from './group_buttons';

export type GroupsSheetProps = {
  selectedGroup?: Group;
  // Forwarder to link to a group page. Defaults to /g/:shortname.
  // But, for instance, post pages can link to /g/:shortname/p/:id.
  groupPageForwarder?: (group: Group) => string;

  noGroupSelectedText?: string;
  onGroupSelected?: (group: Group) => void;

  disabled?: boolean;
  title?: string;
  itemTitle?: string;
  disableSelection?: boolean;
  hideInfoButtons?: boolean;
  topGroupIds?: string[];
  extraListItemChrome?: (group: Group) => JSX.Element | undefined;
  delayRenderingSheet?: boolean;
  hideAdditionalGroups?: boolean;
  hideLeaveButtons?: boolean;
  key?: string;
}

export function GroupsSheet({ key, selectedGroup, groupPageForwarder, noGroupSelectedText, onGroupSelected, disabled, title, itemTitle, disableSelection, hideInfoButtons, topGroupIds, extraListItemChrome, delayRenderingSheet, hideAdditionalGroups, hideLeaveButtons }: GroupsSheetProps) {
  const [open, setOpen] = useState(false);
  const [infoOpen, setInfoOpen] = useState(false);
  const [infoGroupId, setInfoGroupId] = useState<string | undefined>(undefined);
  const infoGroup = useTypedSelector((state: RootState) =>
    infoGroupId ? state.groups.entities[infoGroupId] : undefined);
  const [position, setPosition] = useState(0);
  const [searchText, setSearchText] = useState('');
  const { dispatch, accountOrServer } = useCredentialDispatch();
  const account = accountOrServer.account;
  const [hasRenderedSheet, setHasRenderedSheet] = useState(false);
  const [editing, setEditing] = useState(false);
  // function setEditing(value: boolean) {
  //   _setEditing(value);
  //   // onEditingChange?.(value);
  // }
  const [previewingEdits, setPreviewingEdits] = useState(false);
  const [savingEdits, setSavingEdits] = useState(false);

  // const app = useTypedSelector((state: RootState) => state.app);
  // const serversState = useTypedSelector((state: RootState) => state.servers);
  // const servers = useTypedSelector((state: RootState) => selectAllServers(state.servers));
  const { server, textColor, primaryColor, primaryTextColor, navColor, navTextColor, primaryAnchorColor, navAnchorColor } = useServerTheme();
  const searchInputRef = React.createRef<TextInput>();// = React.createRef() as React.MutableRefObject<HTMLElement | View>;

  const groupsState = useTypedSelector((state: RootState) => state.groups);
  const [loadingGroups, setLoadingGroups] = useState(false);
  useEffect(() => {
    if (!loadingGroups && groupsState.status == 'unloaded' && !extraListItemChrome) {
      setLoadingGroups(true);
      reloadGroups();
    } else if (loadingGroups && !['unloaded', 'loading'].includes(groupsState.status)) {
      setLoadingGroups(false);
    }
  });
  useEffect(() => {
    if (open && !hasRenderedSheet) {
      setHasRenderedSheet(true);
    }
  }, [open]);

  function reloadGroups() {
    if (!accountOrServer.server) return;

    setTimeout(() =>
      dispatch(updateGroups({ ...accountOrServer, ...GetGroupsRequest.create() })), 1);
  }

  const recentGroupIds = useTypedSelector((state: RootState) => server
    ? state.app.serverRecentGroups?.[serverID(server)] ?? []
    : []);
  // const renderedTopGroupIds = topGroupIds ?? recentGroupIds;


  const allGroups = useTypedSelector((state: RootState) => selectAllGroups(state.groups));


  const matchedGroups: Group[] = allGroups.filter(g =>
    g.name.toLowerCase().includes(searchText.toLowerCase()) ||
    g.description.toLowerCase().includes(searchText.toLowerCase()));

  const topGroups: Group[] = [
    ...(selectedGroup != undefined ? [selectedGroup] : []),
    ...(
      (topGroupIds ?? []).filter(id => id != selectedGroup?.id)
        .map(id => allGroups.find(g => g.id == id)).filter(g => g != undefined) as Group[]
    ).filter(g =>
      g.name.toLowerCase().includes(searchText.toLowerCase()) ||
      g.description.toLowerCase().includes(searchText.toLowerCase())),
  ];


  const recentGroups = recentGroupIds
    .map(id => allGroups.find(g => g.id === id))
    .filter(g => g != undefined && g.id !== selectedGroup?.id
      && !topGroups.some(tg => tg.id == g.id)
      && matchedGroups.some(mg => mg.id === g.id)) as Group[];

  const sortedGroups: Group[] = [
    ...matchedGroups
      .filter(g => g.id !== selectedGroup?.id &&
        (!(topGroupIds || []).includes(g.id)) &&
        (!(recentGroupIds || []).includes(g.id))),
  ];

  // console.log('topGroupIds', topGroupIds);
  // console.log('topGroups', topGroups);
  // console.log('sortedGroups', sortedGroups);

  const infoMarginLeft = -34;
  const infoPaddingRight = 39;

  useEffect(() => {
    if (!infoOpen && infoGroup) {
      setInfoGroupId(undefined);
    }
  }, [infoOpen]);

  function updateGroup() {
    setSavingEdits(true);
    // dispatch(updatePost({
    //   ...accountOrServer, ...post,
    //   content: editedContent,
    //   media: editedMedia,
    //   embedLink: editedEmbedLink,
    //   visibility: editedVisibility,
    // })).then(() => {
    //   setEditing(false);
    //   setSavingEdits(false);
    //   setPreviewingEdits(false);
    // });
    setTimeout(() => setSavingEdits(false), 3000);
  }
  function deleteGroup() {
    setDeleting(true);
    // dispatch(deleteGroup({ ...accountOrServer, ...post })).then(() => {
    //   setDeleted(true);
    //   setDeleting(false);
    // });
  }

  const infoRenderingGroup = infoGroup ?? selectedGroup;
  const canEditGroup = account?.user?.permissions?.includes(Permission.ADMIN)
    || infoRenderingGroup?.currentUserMembership?.permissions?.includes(Permission.ADMIN);
  const [editingGroup, setEditingGroup] = useState<boolean>(false);
  const [editedName, setEditedName] = useState<string>(infoRenderingGroup?.name ?? '');
  const [editedDescription, setEditedDescription] = useState<string>(infoRenderingGroup?.name ?? '');
  const [editedAvatar, setEditedAvatar] = useState(infoRenderingGroup?.avatar);
  const [deleted, setDeleted] = useState(false);
  const [deleting, setDeleting] = useState(false);
  useEffect(() => {
    if (infoRenderingGroup) {
      setEditingGroup(false);
      setEditedName(infoRenderingGroup.name);
      setEditedDescription(infoRenderingGroup.description ?? '');
      setEditedAvatar(infoRenderingGroup.avatar);
    }
  }, [infoRenderingGroup?.id, server ? serverID(server) : 'no server']);


  //TODO: Simplify/abstract this into its own component? But then, with this design, will there ever be a need
  // for a *third* "Join" button in this app?
  const joined = passes(infoRenderingGroup?.currentUserMembership?.userModeration)
    && passes(infoRenderingGroup?.currentUserMembership?.groupModeration);
  const membershipRequested = infoRenderingGroup?.currentUserMembership && !joined && passes(infoRenderingGroup?.currentUserMembership?.userModeration);
  const invited = infoRenderingGroup?.currentUserMembership && !joined && passes(infoRenderingGroup?.currentUserMembership?.groupModeration);

  return (

    <>
      <Button
        key={key ? `groups-sheet-button-${key}` : undefined}
        icon={selectedGroup ? undefined : Boxes} circular={!selectedGroup && !noGroupSelectedText}
        paddingRight={selectedGroup && !hideInfoButtons ? infoPaddingRight : undefined}
        paddingLeft={selectedGroup && !hideInfoButtons ? '$2' : undefined}
        disabled={disabled}
        my='auto'
        o={disabled ? 0.5 : 1}
        onPress={() => setOpen((x) => !x)}
        w={noGroupSelectedText ? '100%' : undefined}>
        {selectedGroup || noGroupSelectedText
          ? <Paragraph size="$1">
            {selectedGroup ? selectedGroup.name : noGroupSelectedText}
          </Paragraph>
          : undefined}
      </Button>
      {delayRenderingSheet && !hasRenderedSheet && !open
        ? undefined
        : <Sheet
          key={key ? `groups-sheet-${key}` : undefined}
          modal
          open={open}
          onOpenChange={setOpen}
          snapPoints={[87]}
          position={position}
          onPositionChange={setPosition}
          dismissOnSnapToBottom
        >
          <Sheet.Overlay />
          <Sheet.Frame>
            <Sheet.Handle />
            {/* <ZStack h={60}>
              <XStack space='$4' paddingHorizontal='$3' mb='$2'>
                <XStack f={1} />
                <CreateGroupSheet />
              </XStack> */}
            <XStack space='$4' paddingHorizontal='$3' mb='$2'>
              <XStack f={1} />
              <Button
                alignSelf='center'
                size="$3"
                mt='$1'
                // transform={[{translateY: 20}]}
                // mb='$3'
                // my='auto'
                circular
                icon={ChevronDown}
                onPress={() => setOpen(false)} />
              <XStack f={1} />
              {/* <CreateGroupSheet /> */}
            </XStack>

            {/* </ZStack> */}

            <YStack space="$3" mb='$2' maw={800} als='center' width='100%'>
              {title ? <Heading size={itemTitle ? '$2' : "$7"} paddingHorizontal='$3' mb={itemTitle ? -15 : '$3'}>{title}</Heading> : undefined}
              {itemTitle ? <Heading size="$7" paddingHorizontal='$3' whiteSpace='nowrap' overflow='hidden' textOverflow='ellipsis'>{itemTitle}</Heading> : undefined}

              <XStack space="$3" paddingHorizontal='$3'>
                <XStack marginVertical='auto' ml='$3' mr={-44}>
                  <Search />
                </XStack>
                <XStack w='100%' pr='$0'>
                  <Input size="$3" f={1} placeholder='Search for Groups' textContentType='name'
                    paddingHorizontal={40} ref={searchInputRef}
                    onChange={(e) => setSearchText(e.nativeEvent.text)} value={searchText} />
                  <Button icon={XIcon} ml={-44} mr='$3'
                    onPress={() => {
                      setSearchText('');
                      searchInputRef.current?.focus();
                    }}
                    size='$2' circular marginVertical='auto'
                    disabled={searchText == ''} opacity={searchText == '' ? 0.5 : 1} />
                </XStack>
                {/* </Input> */}
              </XStack>
            </YStack>

            <Sheet.ScrollView p="$4" space>
              <YStack maw={600} als='center' width='100%'>
                {topGroups.length > 0
                  ?
                  <>
                    <YStack>
                      {topGroups.map((group, index) => {
                        return <GroupButton
                          key={`groupButton-${group.id}`}
                          group={group}
                          groupPageForwarder={groupPageForwarder}
                          onGroupSelected={onGroupSelected}
                          selected={group.id == selectedGroup?.id}
                          onShowInfo={() => {
                            setInfoGroupId(group.id);
                            setInfoOpen(true);
                          }}
                          setOpen={setOpen}
                          disabled={disableSelection}
                          hideInfoButton={hideInfoButtons}
                          extraListItemChrome={extraListItemChrome}
                          hideLeaveButton={hideLeaveButtons}
                        />
                      })}
                    </YStack>
                  </>
                  : undefined}
                {recentGroups.length > 0
                  ? <>
                    <Heading size='$4' mt='$3' als='center'>Recent Groups</Heading>
                    <YStack>
                      {recentGroups.map((group, index) => {
                        return <GroupButton
                          key={`groupButton-${group.id}`}
                          group={group}
                          groupPageForwarder={groupPageForwarder}
                          onGroupSelected={onGroupSelected}
                          selected={group.id == selectedGroup?.id}
                          onShowInfo={() => {
                            setInfoGroupId(group.id);
                            setInfoOpen(true);
                          }}
                          setOpen={setOpen}
                          disabled={disableSelection}
                          hideInfoButton={hideInfoButtons}
                          extraListItemChrome={extraListItemChrome}
                          hideLeaveButton={hideLeaveButtons}
                        />
                      })}
                    </YStack>
                  </>
                  : undefined}
                {hideAdditionalGroups
                  ? undefined
                  : sortedGroups.length > 0
                    ? <>
                      {topGroups.length + recentGroups.length > 0 ? <Heading size='$4' mt='$3' als='center'>More Groups</Heading> : undefined}
                      <YStack>
                        {sortedGroups.map((group, index) => {
                          return <GroupButton
                            key={`groupButton-${group.id}`}
                            group={group}
                            groupPageForwarder={groupPageForwarder}
                            onGroupSelected={onGroupSelected}
                            selected={group.id == selectedGroup?.id}
                            onShowInfo={() => {
                              setInfoGroupId(group.id);
                              setInfoOpen(true);
                            }}
                            setOpen={setOpen}
                            disabled={disableSelection}
                            hideInfoButton={hideInfoButtons}
                            extraListItemChrome={extraListItemChrome}
                            hideLeaveButton={hideLeaveButtons}
                          />
                        })}
                      </YStack>
                    </>
                    : <Heading size='$3' als='center'>No Groups {searchText != '' ? `Matched "${searchText}"` : 'Found'}</Heading>}
              </YStack>
            </Sheet.ScrollView>
            <CreateGroupSheet />
          </Sheet.Frame>
        </Sheet>
      }
      {selectedGroup && !hideInfoButtons
        ? <>
          <Theme inverse>
            <Button icon={Info} opacity={0.7} size="$2" circular marginVertical='auto'
              ml={infoMarginLeft} onPress={() => setInfoOpen((x) => !x)} />
          </Theme>
        </>
        : undefined}
      {!hideInfoButtons ?
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

            <YStack space="$3" mb='$2' p='$4' maw={800} als='center' width='100%'>
              <XStack>
                <Heading my='auto' f={1}>{infoRenderingGroup?.name}</Heading>
                {infoRenderingGroup
                  ? <GroupJoinLeaveButton group={infoRenderingGroup} hideLeaveButton={hideLeaveButtons} />
                  : undefined}
              </XStack>
              <XStack>
                <Heading size='$2'>{server?.host}/g/{infoRenderingGroup?.shortname}</Heading>
                <XStack f={1} />
                <Heading size='$1' marginVertical='auto'>
                  {infoRenderingGroup?.memberCount} member{infoRenderingGroup?.memberCount == 1 ? '' : 's'}
                </Heading>
              </XStack>
              <XStack>
                {canEditGroup
                  ? editing
                    ? <>
                      <Button my='auto' size='$2' icon={Save} onPress={updateGroup} color={primaryAnchorColor} disabled={savingEdits} transparent>
                        Save
                      </Button>
                      <Button my='auto' size='$2' icon={XIcon} onPress={() => setEditing(false)} disabled={savingEdits} transparent>
                        Cancel
                      </Button>
                      {previewingEdits
                        ? <Button my='auto' size='$2' icon={Edit} onPress={() => setPreviewingEdits(false)} color={navAnchorColor} disabled={savingEdits} transparent>
                          Edit
                        </Button>
                        :
                        <Button my='auto' size='$2' icon={Eye} onPress={() => setPreviewingEdits(true)} color={navAnchorColor} disabled={savingEdits} transparent>
                          Preview
                        </Button>}
                    </>
                    : <>
                      <Button my='auto' size='$2' icon={Edit} onPress={() => setEditing(true)} disabled={deleting} transparent>
                        Edit
                      </Button>

                      <Dialog>
                        <Dialog.Trigger asChild>
                          <Button my='auto' size='$2' icon={Delete} disabled={deleting} transparent>
                            Delete
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
                              <Dialog.Title>Delete Group</Dialog.Title>
                              <Dialog.Description>
                                <YStack space='$3'>
                                  <Paragraph>
                                    Really delete the group "{infoRenderingGroup?.name ?? 'group'}"?
                                  </Paragraph>
                                  <Paragraph>
                                    The group will be deleted along with any group post/event associations.
                                    Posts/events themselves belong to the users who posted them, not {infoRenderingGroup?.name ?? 'this group'}.
                                  </Paragraph>
                                </YStack>
                              </Dialog.Description>

                              <XStack space="$3" jc="flex-end">
                                <Dialog.Close asChild>
                                  <Button>Cancel</Button>
                                </Dialog.Close>
                                {/* <Dialog.Action asChild> */}
                                <Theme inverse>
                                  <Button onPress={deleteGroup}>Delete</Button>
                                </Theme>
                                {/* </Dialog.Action> */}
                              </XStack>
                            </YStack>
                          </Dialog.Content>
                        </Dialog.Portal>
                      </Dialog>
                    </>
                  : undefined}
              </XStack>
            </YStack>

            <Sheet.ScrollView p="$4" space>
              <YStack maw={600} als='center' width='100%'>
                {/* <ReactMarkdown children={infoRenderingGroup?.description ?? ''}
                    components={{
                      // li: ({ node, ordered, ...props }) => <li }} {...props} />,
                      p: ({ node, ...props }) => <Paragraph children={props.children} size='$1' />,
                      a: ({ node, ...props }) => <Anchor color={navColor} target='_blank' href={props.href} children={props.children} />,
                    }} /> */}
                <TamaguiMarkdown text={infoRenderingGroup?.description ?? ''} />
              </YStack>
            </Sheet.ScrollView>
          </Sheet.Frame>
        </Sheet>
        : undefined}
    </>
  )
}

