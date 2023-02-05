import { Button, Heading, Popover, useMedia } from '@jonline/ui';
import { Adapt, GetGroupsRequest, Group, Input, Label, ScrollView, XStack, YGroup } from '@jonline/ui/src';
import { Boxes, Search, X as XIcon } from '@tamagui/lucide-icons';
import { RootState, selectAllGroups, selectAllServers, updateGroups, useCredentialDispatch, useTypedSelector } from 'app/store';
import React, { useState } from 'react';
import { FlatList } from 'react-native';

export type GroupsSheetProps = {
  group?: Group;
}

export function GroupsSheet({ group }: GroupsSheetProps) {
  const media = useMedia();
  const [open, setOpen] = useState(false);
  const [browsingServers, setBrowsingServers] = useState(false);
  const [addingServer, setAddingServer] = useState(false);
  const [addingAccount, setAddingAccount] = useState(false);
  const [position, setPosition] = useState(0);
  const [newServerHost, setNewServerHost] = useState('');
  const [newServerSecure, setNewServerSecure] = useState(true);
  const [newAccountUser, setNewAccountUser] = useState('');
  const [newAccountPass, setNewAccountPass] = useState('');
  const [searchText, setSearchText] = useState('');
  let { dispatch, accountOrServer } = useCredentialDispatch();

  const app = useTypedSelector((state: RootState) => state.app);
  const serversState = useTypedSelector((state: RootState) => state.servers);
  const servers = useTypedSelector((state: RootState) => selectAllServers(state.servers));
  const groups = useTypedSelector((state: RootState) => selectAllGroups(state.groups));
  const groupsState = useTypedSelector((state: RootState) => state.groups);
  if (groupsState.status == 'unloaded') {
    reloadGroups();
  } else if (groups.length > 0) {
    // setTimeout(() => setShowScrollPreserver(false), 1500);
  }

  function reloadGroups() {
    if (!accountOrServer.server) return;

    setTimeout(() =>
      dispatch(updateGroups({ ...accountOrServer, ...GetGroupsRequest.create() })), 1);
  }

  const matchedGroups = groups.filter(g => g.name.toLowerCase().includes(searchText.toLowerCase()));
  return (

    <Popover size="$5">
      <Popover.Trigger asChild>
        <Button icon={group ? undefined : Boxes} circular={!group}>
          {group ? group.name : undefined}
        </Button>
      </Popover.Trigger>

      <Adapt when="sm" platform="web">
        <Popover.Sheet modal dismissOnSnapToBottom>
          <Popover.Sheet.Frame padding="$4">
            <Adapt.Contents />
          </Popover.Sheet.Frame>
          <Popover.Sheet.Overlay />
        </Popover.Sheet>
      </Adapt>

      <Popover.Content
        bw={1}
        boc="$borderColor"
        enterStyle={{ x: 0, y: -10, o: 0 }}
        exitStyle={{ x: 0, y: -10, o: 0 }}
        x={0}
        y={0}
        o={1}
        animation={[
          'quick',
          {
            opacity: {
              overshootClamping: true,
            },
          },
        ]}
        elevate
      >
        <Popover.Arrow bw={1} boc="$borderColor" />

        <YGroup space="$3">
          <XStack space="$3">
            {/* <Label size="$3" htmlFor={'groupSearch'}>
              Name
            </Label> */}
            <XStack marginVertical='auto'>
              <Search />
            </XStack>
            <Input size="$3" id={'groupSearch'} f={1} placeholder='Search for Group' textContentType='name'
              onChange={(e) => setSearchText(e.nativeEvent.text)} value={searchText} />
            <Button icon={XIcon} onPress={() => setSearchText('')} size='$2' circular marginVertical='auto'
              disabled={searchText == ''} opacity={searchText == '' ? 0.5 : 1} />
            {/* </Input> */}
          </XStack>

          <ScrollView f={1}>
            <FlatList data={matchedGroups}
              renderItem={({ item: group }) =>
                <Popover.Close asChild>
                  <Button
                    // bordered={false}
                    transparent
                    size="$3"
                    // disabled={appSection == AppSection.HOME}
                    onPress={() => { }}
                  >
                    <Heading size="$4">{group.name}</Heading>
                  </Button>
                </Popover.Close>}

            />
          </ScrollView>
        </YGroup>
      </Popover.Content>
    </Popover>

  )
}
