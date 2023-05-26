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
}

export function GroupsSheet({ selectedGroup }: GroupsSheetProps) {
  const [open, setOpen] = useState(false);
  const [infoOpen, setInfoOpen] = useState(false);
  const [position, setPosition] = useState(0);
  const [searchText, setSearchText] = useState('');
  let { dispatch, accountOrServer } = useCredentialDispatch();

  // const app = useTypedSelector((state: RootState) => state.app);
  // const serversState = useTypedSelector((state: RootState) => state.servers);
  // const servers = useTypedSelector((state: RootState) => selectAllServers(state.servers));
  const { server, primaryColor, navColor, navTextColor } = useServerTheme();
  const searchInputRef = React.createRef() as React.MutableRefObject<HTMLElement | View>;

  const groups = useTypedSelector((state: RootState) => selectAllGroups(state.groups));
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

  const matchedGroups = groups.filter(g => g.name.toLowerCase().includes(searchText.toLowerCase()));

  const infoMarginLeft = -34;
  const infoPaddingRight = 39;
  return (

    <>
      <Button icon={selectedGroup ? undefined : Boxes} circular={!selectedGroup}
        paddingRight={selectedGroup ? infoPaddingRight : undefined}
        paddingLeft={selectedGroup ? '$2' : undefined}
        onPress={() => setOpen((x) => !x)}>
        {selectedGroup ? <Paragraph size="$1">{selectedGroup.name}</Paragraph> : undefined}
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
              {matchedGroups.length > 0
                ? 
                <>
                <YStack>
                  {matchedGroups.map((group, index) => {
                    return <GroupButton key={`groupButton-${group.id}`} group={group} selected={group.id == selectedGroup?.id} setOpen={setOpen} />
                  })}
                </YStack>
                {/* <FlatList data={matchedGroups}
                  renderItem={({ item: group }) => {
                    return <GroupButton key={`groupButton-${group.id}`} group={group} selected={group.id == selectedGroup?.id} setOpen={setOpen} />
                  }}
                /> */}
                </>
                : <Heading size='$3' als='center'>No Groups {searchText != '' ? `Matched "${searchText}"` : 'Found'}</Heading>}
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
                <XStack>
                  <Heading size='$2'>{server?.host}/g/{selectedGroup?.shortname}</Heading>
                  <XStack f={1} />
                  <Heading size='$1' marginVertical='auto'>
                    {selectedGroup?.memberCount} member{selectedGroup?.memberCount == 1 ? '' : 's'}
                  </Heading>
                </XStack>
              </YStack>

              <Sheet.ScrollView p="$4" space>
                <YStack maw={600} als='center' width='100%'>
                  {/* <ReactMarkdown children={selectedGroup?.description ?? ''}
                    components={{
                      // li: ({ node, ordered, ...props }) => <li }} {...props} />,
                      p: ({ node, ...props }) => <Paragraph children={props.children} size='$1' />,
                      a: ({ node, ...props }) => <Anchor color={navColor} target='_blank' href={props.href} children={props.children} />,
                    }} /> */}
                  <TamaguiMarkdown text={selectedGroup?.description ?? ''} />
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
  // Forwarder to link to a group page. Defaults to /g/:shortname.
  // But, for instance, post pages can link to /g/:shortname/p/:id.
  groupPageForwarder?: (group: Group) => string;
}

function GroupButton({ group, selected, setOpen, groupPageForwarder }: GroupButtonProps) {
  const link = useLink({ href: groupPageForwarder ? groupPageForwarder(group) : `/g/${group.shortname}` });
  const media = useMedia();
  const onPress = link.onPress;
  link.onPress = (e) => {
    setOpen(false);
    onPress?.(e);
  }
  const { server, primaryColor, navColor, navTextColor } = useServerTheme();
  return <Button
    // bordered={false}
    // href={`/g/${group.shortname}`}
    transparent={!selected}
    backgroundColor={selected ? navColor : undefined}
    // size="$8"
    // disabled={appSection == AppSection.HOME}
    {...link}
  >
    <XStack w='100%'>
      <XStack w={media.gtXs ? 70 : 0} />
      <Paragraph size="$5" color={selected ? navTextColor : undefined} whiteSpace='nowrap' overflow='hidden' marginVertical='auto' f={1} ta='center'>
        {group.name}
      </Paragraph>
      <XStack w={70}>
        <YStack marginVertical='auto' mr='$2'><Users size="$1" color={selected ? navTextColor : undefined} /></YStack>
        <Heading size="$3" color={selected ? navTextColor : undefined} marginVertical='auto' f={1} ta='right'>
          {group.memberCount}
        </Heading>
      </XStack>
    </XStack>
  </Button>;
}
