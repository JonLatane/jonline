import { GetGroupsRequest, Group } from '@jonline/api';
import { Button, Heading, Input, Paragraph, Sheet, Theme, XStack, YStack } from '@jonline/ui';
import { Boxes, ChevronDown, Info, Search, X as XIcon } from '@tamagui/lucide-icons';
import { RootState, loadGroupsPage, selectAllGroups, serverID, useCredentialDispatch, useServerTheme, useTypedSelector } from 'app/store';
import React, { useEffect, useState } from 'react';
import { TextInput } from 'react-native';
import { CreateGroupSheet } from './create_group_sheet';
import { GroupButton } from './group_buttons';
import { GroupDetailsSheet } from './group_details_sheet';

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

  const [position, setPosition] = useState(0);
  const [searchText, setSearchText] = useState('');
  const { dispatch, accountOrServer } = useCredentialDispatch();
  const { server } = accountOrServer;
  const [hasRenderedSheet, setHasRenderedSheet] = useState(false);


  const { navAnchorColor } = useServerTheme();
  const searchInputRef = React.createRef<TextInput>();

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
      dispatch(loadGroupsPage({ ...accountOrServer, ...GetGroupsRequest.create() })), 1);
  }

  const recentGroupIds = useTypedSelector((state: RootState) => server
    ? state.app.serverRecentGroups?.[serverID(server)] ?? []
    : []);

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

  const infoMarginLeft = -34;
  const infoPaddingRight = 39;

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
            <XStack space='$4' paddingHorizontal='$3' mb='$2'>
              <XStack f={1} />
              <Button
                alignSelf='center'
                size="$3"
                mt='$1'
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
        <GroupDetailsSheet {...{ selectedGroup, infoGroupId, infoOpen, setInfoOpen }} />
        : undefined}
    </>
  )
}

