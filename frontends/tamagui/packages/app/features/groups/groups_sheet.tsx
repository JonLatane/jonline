import { GetGroupsRequest, Group } from '@jonline/api';
import { Button, Heading, Input, Paragraph, Sheet, Theme, useMedia, XStack, YStack, Text, standardAnimation, Separator } from '@jonline/ui';
import { Boxes, Calendar, ChevronDown, Info, MessageSquare, Search, Users, Users2, X as XIcon } from '@tamagui/lucide-icons';
import { RootState, isGroupLocked, joinLeaveGroup, selectAllGroups, serverID, updateGroups, useAccount, useAccountOrServer, useCredentialDispatch, useServerTheme, useTypedDispatch, useTypedSelector } from 'app/store';
import React, { createRef, useEffect, useState } from 'react';
import { FlatList, GestureResponderEvent, TextInput, View } from 'react-native';
import { useLink } from 'solito/link';
import { } from '../post/post_card';
import { TamaguiMarkdown } from '../post/tamagui_markdown';
import { passes, pending } from '../../utils/moderation_utils';

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
}

export function GroupsSheet({ selectedGroup, groupPageForwarder, noGroupSelectedText, onGroupSelected, disabled, title, itemTitle, disableSelection, hideInfoButtons, topGroupIds, extraListItemChrome, delayRenderingSheet, hideAdditionalGroups, hideLeaveButtons }: GroupsSheetProps) {
  const [open, setOpen] = useState(false);
  const [infoOpen, setInfoOpen] = useState(false);
  const [infoGroup, setInfoGroup] = useState<Group | undefined>(undefined);
  const [position, setPosition] = useState(0);
  const [searchText, setSearchText] = useState('');
  const { dispatch, accountOrServer } = useCredentialDispatch();
  const [hasRenderedSheet, setHasRenderedSheet] = useState(false);

  // const app = useTypedSelector((state: RootState) => state.app);
  // const serversState = useTypedSelector((state: RootState) => state.servers);
  // const servers = useTypedSelector((state: RootState) => selectAllServers(state.servers));
  const { server, textColor, primaryColor, primaryTextColor, navColor, navTextColor } = useServerTheme();
  const searchInputRef= React.createRef<TextInput>();// = React.createRef() as React.MutableRefObject<HTMLElement | View>;

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
  const renderedTopGroupIds = topGroupIds ?? recentGroupIds;
  // console.log('renderedTopGroupIds', renderedTopGroupIds);

  const allGroups = useTypedSelector((state: RootState) => selectAllGroups(state.groups));
  const matchedGroups: Group[] = allGroups.filter(g =>
    g.name.toLowerCase().includes(searchText.toLowerCase()) ||
    g.description.toLowerCase().includes(searchText.toLowerCase()));
  const topGroups: Group[] = [
    ...(selectedGroup != undefined ? [selectedGroup] : []),
    ...(
      renderedTopGroupIds.filter(id => id != selectedGroup?.id)
        .map(id => allGroups.find(g => g.id == id)).filter(g => g != undefined) as Group[]
    ).filter(g =>
      g.name.toLowerCase().includes(searchText.toLowerCase()) ||
      g.description.toLowerCase().includes(searchText.toLowerCase())),
  ];
  const sortedGroups: Group[] = [
    ...matchedGroups.filter(g => g.id !== selectedGroup?.id && topGroupIds?.includes(g.id) !== true)
  ];

  const infoMarginLeft = -34;
  const infoPaddingRight = 39;

  useEffect(() => {
    if (!infoOpen && infoGroup) {
      setInfoGroup(undefined);
    }
  }, [infoOpen]);

  const infoRenderingGroup = infoGroup ?? selectedGroup;


  //TODO: Simplify/abstract this into its own component? But then, with this design, will there ever be a need
  // for a *third* "Join" button in this app?
  const joined = passes(infoRenderingGroup?.currentUserMembership?.userModeration)
    && passes(infoRenderingGroup?.currentUserMembership?.groupModeration);
  const membershipRequested = infoRenderingGroup?.currentUserMembership && !joined && passes(infoRenderingGroup?.currentUserMembership?.userModeration);
  const invited = infoRenderingGroup?.currentUserMembership && !joined && passes(infoRenderingGroup?.currentUserMembership?.groupModeration)
  const requiresPermissionToJoin = pending(infoRenderingGroup?.defaultMembershipModeration);
  const isLocked = useTypedSelector((state: RootState) => !infoRenderingGroup || isGroupLocked(state.groups, infoRenderingGroup.id));

  const onJoinPressed = () => {
    if (!infoRenderingGroup) {
      console.warn("onJoinPressed with no infoRenderingGroup");
      return;
    }
    // e.stopPropagation();
    const join = !(joined || membershipRequested || invited);
    dispatch(joinLeaveGroup({ groupId: infoRenderingGroup.id, join, ...accountOrServer }));
  };

  return (

    <>
      <Button icon={selectedGroup ? undefined : Boxes} circular={!selectedGroup && !noGroupSelectedText}
        paddingRight={selectedGroup && !hideInfoButtons ? infoPaddingRight : undefined}
        paddingLeft={selectedGroup && !hideInfoButtons ? '$2' : undefined}
        disabled={disabled}
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
            <XStack space='$4' paddingHorizontal='$3'>
              <XStack f={1} />
              <Button
                alignSelf='center'
                size="$3"
                mb='$3'
                circular
                icon={ChevronDown}
                onPress={() => setOpen(false)} />
              <XStack f={1} />
            </XStack>

            <YStack space="$3" mb='$2' maw={800} als='center' width='100%'>
              {title ? <Heading size={itemTitle ? '$2' : "$7"} paddingHorizontal='$3' mb={itemTitle ? -15 : '$3'}>{title}</Heading> : undefined}
              {itemTitle ? <Heading size="$7" paddingHorizontal='$3' whiteSpace='nowrap' overflow='hidden' textOverflow='ellipsis'>{itemTitle}</Heading> : undefined}

              <XStack space="$3" paddingHorizontal='$3'>
                <XStack marginVertical='auto' ml='$3' mr={-44}>
                  <Search />
                </XStack>
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
                            setInfoGroup(group);
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
                      {topGroups.length > 0 ? <Heading size='$4' mt='$3' als='center'>More Groups</Heading> : undefined}
                      <YStack>
                        {sortedGroups.map((group, index) => {
                          return <GroupButton
                            key={`groupButton-${group.id}`}
                            group={group}
                            groupPageForwarder={groupPageForwarder}
                            onGroupSelected={onGroupSelected}
                            selected={group.id == selectedGroup?.id}
                            onShowInfo={() => {
                              setInfoGroup(group);
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
                    : <Heading size='$3' als='center'>No Groups {searchText != '' ? `Matched "${searchText}"` : 'Found'}</Heading>
                }
              </YStack>
            </Sheet.ScrollView>
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
                {accountOrServer.account
                  ? <XStack key='join-button' ac='center' jc='center' mx='auto' my='auto' >
                    <Button mt='$2' backgroundColor={!joined && !membershipRequested ? primaryColor : undefined}
                      animation='quick' {...standardAnimation}
                      mb='$2'
                      p='$3'
                      disabled={isLocked} opacity={isLocked ? 0.5 : 1}
                      onPress={onJoinPressed}>
                      <YStack jc='center' ac='center'>
                        <Heading jc='center' ta='center' size='$2' color={!joined && !membershipRequested ? primaryTextColor : textColor}>
                          {!joined && !membershipRequested ? requiresPermissionToJoin ? 'Join Request' : 'Join'
                            : joined ? 'Leave' : 'Cancel Request'}
                        </Heading>
                        {requiresPermissionToJoin && joined ? <Paragraph size='$1'>
                          Permission required to re-join
                        </Paragraph>
                          : undefined}
                      </YStack>
                    </Button>
                  </XStack> : undefined}
              </XStack>
              <XStack>
                <Heading size='$2'>{server?.host}/g/{infoRenderingGroup?.shortname}</Heading>
                <XStack f={1} />
                <Heading size='$1' marginVertical='auto'>
                  {infoRenderingGroup?.memberCount} member{infoRenderingGroup?.memberCount == 1 ? '' : 's'}
                </Heading>
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


type GroupButtonProps = {
  group: Group;
  selected: boolean;
  setOpen: (open: boolean) => void;
  onShowInfo: () => void;
  // Forwarder to link to a group page. Defaults to /g/:shortname.
  // But, for instance, post pages can link to /g/:shortname/p/:id.
  groupPageForwarder?: (group: Group) => string;
  onGroupSelected?: (group: Group) => void;
  disabled?: boolean;
  hideInfoButton?: boolean;
  extraListItemChrome?: (group: Group) => JSX.Element | undefined;

  hideLeaveButton?: boolean;
}

function GroupButton({ group, selected, setOpen, groupPageForwarder, onShowInfo, onGroupSelected, disabled, hideInfoButton, extraListItemChrome, hideLeaveButton }: GroupButtonProps) {
  const accountOrServer = useAccountOrServer();
  const { account } = accountOrServer;
  const dispatch = useTypedDispatch();
  const link = onGroupSelected ? { onPress: () => onGroupSelected(group) } :
    useLink({ href: groupPageForwarder ? groupPageForwarder(group) : `/g/${group.shortname}` });
  const media = useMedia();
  const onPress = link.onPress;
  link.onPress = (e) => {
    setOpen(false);
    onPress?.(e);
  }
  const { server, textColor, primaryColor, primaryTextColor, navColor, navTextColor } = useServerTheme();

  const joined = passes(group.currentUserMembership?.userModeration)
    && passes(group.currentUserMembership?.groupModeration);
  const membershipRequested = group.currentUserMembership && !joined && passes(group.currentUserMembership?.userModeration);
  const invited = group.currentUserMembership && !joined && passes(group.currentUserMembership?.groupModeration)
  const requiresPermissionToJoin = pending(group.defaultMembershipModeration);
  const isLocked = useTypedSelector((state: RootState) => isGroupLocked(state.groups, group.id));

  const onJoinPressed = () => {
    // e.stopPropagation();
    const join = !(joined || membershipRequested || invited);
    dispatch(joinLeaveGroup({ groupId: group.id, join, ...accountOrServer }));
  };

  return <YStack>
    <XStack>
      <Button
        f={1}
        h={75}
        // bordered={false}
        // href={`/g/${group.shortname}`}
        transparent={!selected}
        backgroundColor={selected ? navColor : undefined}
        // size="$8"
        // disabled={appSection == AppSection.HOME}
        disabled={disabled}
        {...link}
      >
        <YStack w='100%' marginVertical='auto'>
          <XStack>
            <Paragraph f={1}
              my='auto'
              size="$5"
              color={selected ? navTextColor : undefined}
              whiteSpace='nowrap'
              overflow='hidden'
              numberOfLines={1}
              ta='left'
            >
              {group.name}
            </Paragraph>
            <XStack o={0.6} my='auto'>
              <XStack my='auto'>
                <Users2 size='$1' />
              </XStack>
              <Text mx='$1' my='auto' fontFamily='$body' fontSize='$1'
                color={selected ? navTextColor : undefined}
                whiteSpace='nowrap'
                overflow='hidden'
                numberOfLines={1}
                ta='left'>
                {group.memberCount}
              </Text>


              {/* <MessageSquare /> {group.postCount}
              <Calendar /> {group.eventCount} */}
            </XStack>
          </XStack>
          <Paragraph
            size="$2"
            color={selected ? navTextColor : undefined}
            whiteSpace='nowrap'
            overflow='hidden'
            numberOfLines={1}
            ta='left'
            o={0.8}
          >
            {group.description}
          </Paragraph>
        </YStack>
      </Button>
      {hideInfoButton ? undefined :
        <Button
          size='$2'
          my='auto'
          ml='$2'
          circular
          icon={Info} onPress={() => onShowInfo()} />}
    </XStack>
    <XStack flexWrap='wrap' w='100%'>
      {accountOrServer.account && (!hideLeaveButton || !joined)
        ? <XStack key='join-button' ac='center' jc='center' mx='auto' my='auto' >
          <Button mt='$2' backgroundColor={!joined && !membershipRequested ? primaryColor : undefined}
            animation='quick' {...standardAnimation}
            mb='$2'
            p='$3'
            disabled={isLocked} opacity={isLocked ? 0.5 : 1}
            onPress={onJoinPressed}>
            <YStack jc='center' ac='center'>
              <Heading jc='center' ta='center' size='$2' color={!joined && !membershipRequested ? primaryTextColor : textColor}>
                {!joined && !membershipRequested ? requiresPermissionToJoin ? 'Join Request' : 'Join'
                  : joined ? 'Leave' : 'Cancel Request'}
              </Heading>
              {requiresPermissionToJoin && joined ? <Paragraph size='$1'>
                Permission required to re-join
              </Paragraph>
                : undefined}
            </YStack>
          </Button>
        </XStack> : undefined}
      {extraListItemChrome?.(group)}
    </XStack>
    {accountOrServer.account || extraListItemChrome
      ? <Separator mt='$1' />
      : undefined}
  </YStack>;
}
