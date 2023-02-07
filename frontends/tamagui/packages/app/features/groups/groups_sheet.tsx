import { Button, Heading, Popover, useMedia } from '@jonline/ui';
import { Adapt, Anchor, GetGroupsRequest, Group, Input, Label, Paragraph, ScrollView, Sheet, TamaguiElement, Theme, XStack, YGroup, YStack } from '@jonline/ui/src';
import { Boxes, ChevronDown, Info, Search, X as XIcon } from '@tamagui/lucide-icons';
import { RootState, selectAllGroups, selectAllServers, updateGroups, useCredentialDispatch, useTypedSelector } from 'app/store';
import React, { useState } from 'react';
import ReactMarkdown from 'react-markdown';
import { FlatList, View } from 'react-native';
import { useLink } from 'solito/link';

export type GroupsSheetProps = {
  selectedGroup?: Group;
}

export function GroupsSheet({ selectedGroup }: GroupsSheetProps) {
  const [open, setOpen] = useState(false);
  const [infoOpen, setInfoOpen] = useState(false);
  const [position, setPosition] = useState(0);
  const [searchText, setSearchText] = useState('');
  let { dispatch, accountOrServer } = useCredentialDispatch();

  const app = useTypedSelector((state: RootState) => state.app);
  const serversState = useTypedSelector((state: RootState) => state.servers);
  const servers = useTypedSelector((state: RootState) => selectAllServers(state.servers));
  const server = useTypedSelector((state: RootState) => state.servers.server);
  const navColorInt = server?.serverConfiguration?.serverInfo?.colors?.navigation;
  const navColor = `#${(navColorInt)?.toString(16).slice(-6) || 'FFFFFF'}`;
  const searchInputRef = React.createRef() as React.MutableRefObject<HTMLElement | View>;

  const groups = useTypedSelector((state: RootState) => selectAllGroups(state.groups));
  const groupsState = useTypedSelector((state: RootState) => state.groups);
  if (groupsState.status == 'unloaded') {
    reloadGroups();
  }

  function reloadGroups() {
    if (!accountOrServer.server) return;

    setTimeout(() =>
      dispatch(updateGroups({ ...accountOrServer, ...GetGroupsRequest.create() })), 1);
  }

  const matchedGroups = groups.filter(g => g.name.toLowerCase().includes(searchText.toLowerCase()));

  const infoMarginLeft = -36;
  const infoPaddingRight = 40;
  return (

    <>
      <Button icon={selectedGroup ? undefined : Boxes} circular={!selectedGroup}
        paddingRight={selectedGroup ? infoPaddingRight : undefined}
        onPress={() => setOpen((x) => !x)}>
        {selectedGroup ? <Heading size="$4">{selectedGroup.name}</Heading> : undefined}
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
              size="$4"
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
              <FlatList data={matchedGroups}
                renderItem={({ item: group }) => {
                  return <GroupButton group={group} selected={group.id == selectedGroup?.id} setOpen={setOpen} />
                }}
              />
            </YStack>
          </Sheet.ScrollView>
        </Sheet.Frame>
      </Sheet>
      {
        selectedGroup ? <>
          <Theme inverse>
            <Button icon={Info} opacity={0.7} size="$2" circular marginVertical='auto' ml={infoMarginLeft} onPress={() => setInfoOpen((x) => !x)} />
          </Theme>
          <Sheet
            modal
            open={infoOpen}
            onOpenChange={setInfoOpen}
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
                  size="$4"
                  mb='$3'
                  circular
                  icon={ChevronDown}
                  onPress={() => setInfoOpen(false)} />
                <XStack f={1} />
              </XStack>

              <YStack space="$3" mb='$2' p='$4' maw={800} als='center' width='100%'>
                <Heading>{selectedGroup?.name}</Heading>
                <Heading size='$2'>{server?.host}/g/{selectedGroup?.shortname}</Heading>
              </YStack>

              <Sheet.ScrollView p="$4" space>
                <YStack maw={600} als='center' width='100%'>
                  <ReactMarkdown children={selectedGroup?.description ?? ''}
                    components={{
                      // li: ({ node, ordered, ...props }) => <li }} {...props} />,
                      p: ({ node, ...props }) => <Paragraph children={props.children} size='$1' />,
                      a: ({ node, ...props }) => <Anchor color={navColor} target='_blank' href={props.href} children={props.children} />,
                    }} />
                </YStack>
              </Sheet.ScrollView>
            </Sheet.Frame>
          </Sheet>
        </> : undefined
      }
    </>

  )
}


type GroupButtonProps = {
  group: Group;
  selected: boolean;
  setOpen: (open: boolean) => void;
}

function GroupButton({ group, selected, setOpen }: GroupButtonProps) {
  const link = useLink({ href: `/g/${group.shortname}` });
  const onPress = link.onPress;
  link.onPress = (e) => {
    setOpen(false);
    onPress?.(e);
  }

  const server = useTypedSelector((state: RootState) => state.servers.server);
  const navColorInt = server?.serverConfiguration?.serverInfo?.colors?.navigation;
  const navColor = `#${(navColorInt)?.toString(16).slice(-6) || 'FFFFFF'}`;
  return <Button
    // bordered={false}
    // href={`/g/${group.shortname}`}
    transparent={!selected}
    backgroundColor={selected ? navColor : undefined}
    // size="$8"
    // disabled={appSection == AppSection.HOME}
    {...link}
  >
    <Heading size="$4">{group.name}</Heading>
  </Button>;
}
