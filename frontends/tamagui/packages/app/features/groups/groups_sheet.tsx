import { GetGroupsRequest, Group } from '@jonline/api';
import { Button, Heading, Input, Paragraph, Sheet, Theme, useMedia, XStack, YStack } from '@jonline/ui';
import { Boxes, ChevronDown, Info, Search, Users, X as XIcon } from '@tamagui/lucide-icons';
import { RootState, selectAllGroups, updateGroups, useCredentialDispatch, useServerTheme, useTypedSelector } from 'app/store';
import React, { useEffect, useState } from 'react';
import { FlatList, View } from 'react-native';
import { useLink } from 'solito/link';
import { } from '../post/post_card';
import { TamaguiMarkdown } from '../post/tamagui_markdown';

export type GroupsSheetProps = {
  selectedGroup?: Group;
  // Forwarder to link to a group page. Defaults to /g/:shortname.
  // But, for instance, post pages can link to /g/:shortname/p/:id.
  groupPageForwarder?: (group: Group) => string;

  noGroupSelectedText?: string;
  onGroupSelected?: (group: Group) => void;

  title?: string;
  disableSelection?: boolean;
  hideInfoButtons?: boolean;
  topGroupIds?: string[];
  extraListComponents?: (group: Group) => JSX.Element | undefined;
}

export function GroupsSheet({ selectedGroup, groupPageForwarder, noGroupSelectedText, onGroupSelected, title, disableSelection, hideInfoButtons, topGroupIds, extraListComponents }: GroupsSheetProps) {
  const [open, setOpen] = useState(false);
  const [infoOpen, setInfoOpen] = useState(false);
  const [infoGroup, setInfoGroup] = useState<Group | undefined>(undefined);
  const [position, setPosition] = useState(0);
  const [searchText, setSearchText] = useState('');
  const { dispatch, accountOrServer } = useCredentialDispatch();

  // const app = useTypedSelector((state: RootState) => state.app);
  // const serversState = useTypedSelector((state: RootState) => state.servers);
  // const servers = useTypedSelector((state: RootState) => selectAllServers(state.servers));
  const { server, primaryColor, navColor, navTextColor } = useServerTheme();
  const searchInputRef = React.createRef() as React.MutableRefObject<HTMLElement | View>;

  const groupsState = useTypedSelector((state: RootState) => state.groups);
  const [loadingGroups, setLoadingGroups] = useState(false);
  useEffect(() => {
    if (!loadingGroups && groupsState.status == 'unloaded') {
      setLoadingGroups(true);
      reloadGroups();
    } else if (loadingGroups && !['unloaded', 'loading'].includes(groupsState.status)) {
      setLoadingGroups(false);
    }
  });

  function reloadGroups() {
    if (!accountOrServer.server) return;

    setTimeout(() =>
      dispatch(updateGroups({ ...accountOrServer, ...GetGroupsRequest.create() })), 1);
  }

  const allGroups = useTypedSelector((state: RootState) => selectAllGroups(state.groups));
  const matchedGroups: Group[] = allGroups.filter(g =>
    g.name.toLowerCase().includes(searchText.toLowerCase()) ||
    g.description.toLowerCase().includes(searchText.toLowerCase()));
  const topGroups: Group[] = [
    ...(selectedGroup != undefined ? [selectedGroup] : []),
    ...((topGroupIds ?? []).filter(id => id != selectedGroup?.id)
      .map(id => allGroups.find(g => g.id == id)).filter(g => g != undefined) as Group[]),
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

  return (

    <>
      <Button icon={selectedGroup ? undefined : Boxes} circular={!selectedGroup && !noGroupSelectedText}
        paddingRight={selectedGroup && !hideInfoButtons ? infoPaddingRight : undefined}
        paddingLeft={selectedGroup && !hideInfoButtons ? '$2' : undefined}
        onPress={() => setOpen((x) => !x)}
        w={noGroupSelectedText ? '100%' : undefined}>
        {selectedGroup || noGroupSelectedText
          ? <Paragraph size="$1">
            {selectedGroup ? selectedGroup.name : noGroupSelectedText}
          </Paragraph>
          : undefined}
      </Button>
      <Sheet
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
            <XStack space="$3" paddingHorizontal='$3'>
              <XStack marginVertical='auto' ml='$3' mr={-44}>
                <Search />
              </XStack>
              <Input size="$3" id={'groupSearch'} f={1} placeholder='Search for Groups' textContentType='name'
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
                      />
                    })}
                  </YStack>
                </>
                : undefined}
              {sortedGroups.length > 0
                ?
                <>
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
                        extraListComponents={extraListComponents}
                      />
                    })}
                  </YStack>
                </>
                : <Heading size='$3' als='center'>No Groups {searchText != '' ? `Matched "${searchText}"` : 'Found'}</Heading>}
            </YStack>
          </Sheet.ScrollView>
        </Sheet.Frame>
      </Sheet>
      {selectedGroup && !hideInfoButtons
        ? <Theme inverse>
          <Button icon={Info} opacity={0.7} size="$2" circular marginVertical='auto'
            ml={infoMarginLeft} onPress={() => setInfoOpen((x) => !x)} />
        </Theme>
        : undefined}
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
            <Heading>{infoRenderingGroup?.name}</Heading>
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
  extraListComponents?: (group: Group) => JSX.Element | undefined;
}

function GroupButton({ group, selected, setOpen, groupPageForwarder, onShowInfo, onGroupSelected, disabled, hideInfoButton }: GroupButtonProps) {
  const link = onGroupSelected ? { onPress: () => onGroupSelected(group) } :
    useLink({ href: groupPageForwarder ? groupPageForwarder(group) : `/g/${group.shortname}` });
  const media = useMedia();
  const onPress = link.onPress;
  link.onPress = (e) => {
    setOpen(false);
    onPress?.(e);
  }
  const { server, primaryColor, navColor, navTextColor } = useServerTheme();
  return <XStack>
    {/* <Button
      size='$2'
      my='auto'
      mr='$2'
      circular
      o={0}
      pointerEvents='none'
      icon={Info} onPress={() => { }} /> */}
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
        <Paragraph
          size="$5"
          color={selected ? navTextColor : undefined}
          whiteSpace='nowrap'
          overflow='hidden'
          numberOfLines={1}
          ta='left'
        >
          {group.name}
        </Paragraph>
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
  </XStack>;
}
