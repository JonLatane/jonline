import { GroupListingType, Permission } from '@jonline/api';
import { Button, Heading, Input, Paragraph, Sheet, Image, Theme, XStack, YStack, useTheme, useDebounceValue } from '@jonline/ui';
import { AtSign, Boxes, ChevronDown, ChevronLeft, Info, Search, X as XIcon } from '@tamagui/lucide-icons';
import { useAppSelector, useCredentialDispatch, useFederatedDispatch, useGroupPages, useLocalConfiguration, useMediaUrl, useServer } from 'app/hooks';
import { FederatedEntity, FederatedGroup, JonlineAccount, RootState, accountID, federatedId, getServerTheme, pinAccount, selectGroupById, serverID, unpinAccount, useRootSelector, useServerTheme, selectAllGroups, selectAllServers, optServerID, selectAccountById } from 'app/store';
import { hasPermission, themedButtonBackground } from 'app/utils';
import React, { useEffect, useState } from 'react';
import { TextInput } from 'react-native';
import { PinnedServerSelector } from '../navigation/pinned_server_selector';
import { CreateGroupSheet } from './create_group_sheet';
import { GroupButton } from './group_buttons';
import { GroupDetailsSheet } from './group_details_sheet';
import { ServerNameAndLogo } from '../navigation/server_name_and_logo';
import { SingleServerAccountsSheet } from '../accounts/single_server_accounts_sheet';
import FlipMove from 'react-flip-move';

export type GroupsSheetProps = {
  selectedGroup?: FederatedGroup;
  // Forwarder to link to a group page. Defaults to /g/:shortname.
  // But, for instance, post pages can link to /g/:shortname/p/:id.
  groupPageForwarder?: (groupIdentifier: string) => string;

  noGroupSelectedText?: string;
  onGroupSelected?: (group: FederatedGroup) => void;

  disabled?: boolean;
  title?: string;
  itemTitle?: string;
  disableSelection?: boolean;
  hideInfoButtons?: boolean;
  topGroupIds?: string[];
  extraListItemChrome?: (group: FederatedGroup) => JSX.Element | undefined;
  // delayRenderingSheet?: boolean; // Now it's always delayed. Remove this line.
  hideAdditionalGroups?: boolean;
  hideLeaveButtons?: boolean;
  groupNamePrefix?: string;
  primaryEntity?: FederatedEntity<any>;
  serverHostFilter?: string;
}
export function GroupsSheet({
  selectedGroup,
  groupPageForwarder,
  noGroupSelectedText,
  onGroupSelected,
  disabled,
  title,
  itemTitle,
  disableSelection,
  hideInfoButtons,
  topGroupIds,
  extraListItemChrome,
  // delayRenderingSheet,
  hideAdditionalGroups,
  hideLeaveButtons,
  groupNamePrefix,
  primaryEntity,
  serverHostFilter
}: GroupsSheetProps) {
  const [open, setOpen] = useState(false);
  const [infoOpen, setInfoOpen] = useState(false);
  const [infoGroupId, setInfoGroupId] = useState<string | undefined>(undefined);

  const [position, setPosition] = useState(0);
  const [searchText, setSearchText] = useState('');
  const { dispatch, accountOrServer } = useFederatedDispatch(selectedGroup);
  const { account: groupAccount, server: groupServer } = accountOrServer;
  const currentServer = useServer();

  const primaryEntityServer = useAppSelector(state => primaryEntity
    ? selectAllServers(state.servers).find(s => s.host === primaryEntity.serverHost)
    : undefined);
  const primaryEntityAccountId = useAppSelector(state => state.accounts.pinnedServers
    .find(a => a.serverId === optServerID(primaryEntityServer))?.accountId);
  const primaryEntityAccount = useAppSelector(state => primaryEntityAccountId
    ? selectAccountById(state.accounts, primaryEntityAccountId)
    : undefined);

  const account = primaryEntity ? primaryEntityAccount : groupAccount;
  const server = primaryEntityServer ?? groupServer;

  const showServerInfo = (primaryEntity && primaryEntity.serverHost !== currentServer?.host) ||
    (selectedGroup && selectedGroup.serverHost !== currentServer?.host);
  const circular = !selectedGroup && !noGroupSelectedText && !showServerInfo;

  const { primaryColor, primaryTextColor, navColor, navTextColor } = getServerTheme(server, useTheme());
  const searchInputRef = React.createRef<TextInput>();

  const groupsState = useRootSelector((state: RootState) => state.groups);

  const [hasOpened, setHasOpened] = useState(false);
  useEffect(() => {
    if (open && !hasOpened) {
      setHasOpened(true);
    }
  }, [open]);
  const openChanged = useDebounceValue(open, 3000);
  useEffect(() => {
    if (!openChanged) {
      setHasOpened(false);
    }
  }, [openChanged])

  const { groups: allGroups } = useGroupPages(GroupListingType.ALL_GROUPS, 0, { disableLoading: extraListItemChrome !== undefined });

  const recentGroupIds = useRootSelector((state: RootState) => state.app.recentGroups ?? []);

  const groupMatcher = (group: FederatedGroup) =>
    (
      group.name.toLowerCase().includes(searchText.toLowerCase()) ||
      group.description.toLowerCase().includes(searchText.toLowerCase())
    ) && (
      serverHostFilter == undefined || group.serverHost === serverHostFilter
    );
  const matchedGroups: FederatedGroup[] = allGroups.filter(groupMatcher);

  const topGroups: FederatedGroup[] = [
    ...(selectedGroup != undefined ? [selectedGroup] : []),
    ...(
      (topGroupIds ?? []).filter(id => id != selectedGroup?.id)
        .map(id => allGroups.find(g => g.id == id)).filter(g => g != undefined) as FederatedGroup[]
    ).filter(groupMatcher),
  ];

  const recentGroups = recentGroupIds
    .map(id => allGroups.find(g => g.id === id))
    .filter(g => g != undefined && g.id !== selectedGroup?.id
      && !topGroups.some(tg => tg.id == g.id)
      && matchedGroups.some(mg => mg.id === g.id)) as FederatedGroup[];

  const sortedGroups: FederatedGroup[] = [
    ...matchedGroups
      .filter(g => g.id !== selectedGroup?.id &&
        (!(topGroupIds || []).includes(g.id)) &&
        (!(recentGroupIds || []).includes(g.id))),
  ];

  const infoMarginLeft = showServerInfo ? -32 : -32;
  const infoPaddingRight = showServerInfo ? 28 : 36;
  const onPress = () => setOpen(true);

  const toggleAccountSelect = (a: JonlineAccount) => {
    if (accountID(a) === accountID(account)) {
      dispatch(unpinAccount(a));
    } else {
      dispatch(pinAccount(a));
    }
  };
  const avatarUrl = useMediaUrl(account?.user.avatar?.id, { account, server: account?.server });
  const avatarSize = 20;

  return (
    <>
      {<YStack>
        {showServerInfo
          ? <SingleServerAccountsSheet server={server}
            selectedAccount={account}
            onAccountSelected={toggleAccountSelect}
            button={(onPress) =>
              <Button onPress={onPress} animation='standard' h='auto' px='$2'
                borderBottomWidth={1} borderBottomLeftRadius={0} borderBottomRightRadius={0}
                o={account ? 1 : 0.5}
                {...themedButtonBackground(navColor, navTextColor)}>
                <XStack ai='center' w='100%' gap='$2'>

                  {(avatarUrl && avatarUrl != '') ?

                    <XStack w={avatarSize} h={avatarSize} ml={-3} mr={-3}>
                      <Image
                        pos="absolute"
                        width={avatarSize}
                        height={avatarSize}
                        borderRadius={avatarSize / 2}
                        resizeMode="cover"
                        als="flex-start"
                        source={{ uri: avatarUrl, width: avatarSize, height: avatarSize }}
                      />
                    </XStack>
                    : undefined}
                  <Paragraph f={1} size='$1' whiteSpace="nowrap" overflow="hidden" textOverflow="ellipse"
                    color={navTextColor} o={account ? 1 : 0.5}>
                    {account
                      ? account?.user.username
                      : 'anonymous'}
                  </Paragraph>
                  <AtSign size='$1' color={navTextColor} />
                </XStack>
              </Button>} /> : undefined}
        <Button
          // circular={circular}
          paddingRight={selectedGroup && !hideInfoButtons ? infoPaddingRight : undefined}
          paddingLeft={selectedGroup && !hideInfoButtons ? '$2' : undefined}
          disabled={disabled}
          my='auto'
          px={circular ? '$1' : undefined}
          h={circular ? undefined : 'auto'}
          mih='$3'
          o={disabled ? 0.5 : 1}
          onPress={onPress}
          {...themedButtonBackground(showServerInfo ? primaryColor : undefined, showServerInfo ? primaryTextColor : undefined)}
          borderTopLeftRadius={showServerInfo ? 0 : undefined} borderTopRightRadius={showServerInfo ? 0 : undefined}
          w={noGroupSelectedText ? '100%' : undefined}>
          {selectedGroup || noGroupSelectedText || showServerInfo
            ? <YStack>
              {showServerInfo
                ? <XStack o={selectedGroup ? 0.5 : 8} ml={-12}>
                  <ServerNameAndLogo server={primaryEntityServer ?? server}
                    textColor={showServerInfo ? primaryTextColor : undefined} />
                </XStack>
                : undefined}
              {selectedGroup && groupNamePrefix
                ? <Paragraph size="$1" lineHeight={14}
                  color={showServerInfo ? primaryTextColor : undefined}>
                  {groupNamePrefix}
                </Paragraph>
                : undefined}
              <Heading size="$7" lineHeight={14} fontSize='$3'
                color={showServerInfo ? primaryTextColor : undefined}>
                {selectedGroup ? selectedGroup.name : noGroupSelectedText}
              </Heading>

            </YStack>
            : <YStack ai='center'>
              <Boxes size='$1' />
              <Paragraph size='$1' o={0.5}>Groups</Paragraph>
            </YStack>}
        </Button>
      </YStack >}
      {hasOpened
        ? <Sheet
          modal
          open={open}
          onOpenChange={setOpen}
          snapPoints={[87]}
          position={position}
          onPositionChange={setPosition}
          dismissOnSnapToBottom
          zIndex={100000}
        >
          <Sheet.Overlay />
          <Sheet.Frame>
            <Sheet.Handle />
            {/* <XStack gap='$4' paddingHorizontal='$3' mb='$2'>
              <XStack f={1} />
              <Button
                alignSelf='center'
                size="$3"
                mt='$1'
                circular
                icon={ChevronDown}
                onPress={() => setOpen(false)} />
              <XStack f={1} />
            </XStack> */}

            <YStack gap="$3" mb='$2' maw={800} als='center' width='100%'>
              {title ? <Heading size={itemTitle ? '$2' : "$7"} paddingHorizontal='$3' mb={itemTitle ? -15 : '$3'}>{title}</Heading> : undefined}
              {itemTitle ? <Heading size="$7" paddingHorizontal='$3' whiteSpace='nowrap' overflow='hidden' textOverflow='ellipsis'>{itemTitle}</Heading> : undefined}

              <XStack gap="$3" paddingHorizontal='$3'>
                <XStack w='100%' pr='$0'>

                  <Button
                    // alignSelf='center'
                    // my='auto'
                    size="$2"
                    my='auto'
                    mr='$2'
                    circular
                    icon={ChevronLeft}
                    // mb='$2'
                    onPress={() => {
                      setOpen(false)
                    }}
                  />
                  <XStack my='auto' ml='$3' mr={-34}>
                    <Search />
                  </XStack>
                  <Input size="$3" f={1} placeholder='Search for Groups' textContentType='name'
                    paddingHorizontal={40} ref={searchInputRef}

                    onChange={(e) => setSearchText(e.nativeEvent.text)} value={searchText} >

                  </Input>
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

              {disableSelection ? undefined : <PinnedServerSelector show transparent simplified />}
            </YStack>
            <Sheet.ScrollView p="$4" space>
              <FlipMove style={{ maxWidth: 600, width: '100%', alignSelf: 'center' }}>
                {/* <YStack maw={600} als='center' width='100%'> */}
                {topGroups.length > 0
                  ? [
                    ...topGroups.map((group, index) => {
                      return <div key={`groupButton-${federatedId(group)}`}>
                        <GroupButton
                          group={group}
                          groupPageForwarder={groupPageForwarder}
                          onGroupSelected={onGroupSelected}
                          selected={group.id == selectedGroup?.id}
                          onShowInfo={() => {
                            setInfoGroupId(federatedId(group));
                            setInfoOpen(true);
                          }}
                          setOpen={setOpen}
                          disabled={disableSelection}
                          hideInfoButton={hideInfoButtons}
                          extraListItemChrome={extraListItemChrome}
                          hideLeaveButton={hideLeaveButtons}
                        />
                      </div>
                    })
                  ]
                  : undefined}
                {recentGroups.length > 0
                  ? [
                    <Heading size='$4' mt='$3' als='center'>Recent Groups</Heading>,
                    ...recentGroups.map((group, index) => {
                      return <div key={`groupButton-${federatedId(group)}`}>
                        <GroupButton
                          group={group}
                          groupPageForwarder={groupPageForwarder}
                          onGroupSelected={onGroupSelected}
                          selected={group.id == selectedGroup?.id}
                          onShowInfo={() => {
                            setInfoGroupId(federatedId(group));
                            setInfoOpen(true);
                          }}
                          setOpen={setOpen}
                          disabled={disableSelection}
                          hideInfoButton={hideInfoButtons}
                          extraListItemChrome={extraListItemChrome}
                          hideLeaveButton={hideLeaveButtons}
                        />
                      </div>
                    })
                  ]
                  : undefined}
                {hideAdditionalGroups
                  ? undefined
                  : sortedGroups.length > 0
                    ? [
                      topGroups.length + recentGroups.length > 0 ? <Heading size='$4' mt='$3' als='center'>More Groups</Heading> : undefined,
                      sortedGroups.map((group, index) => {
                        return <div key={`groupButton-${federatedId(group)}`}>
                          <GroupButton
                            group={group}
                            groupPageForwarder={groupPageForwarder}
                            onGroupSelected={onGroupSelected}
                            selected={group.id == selectedGroup?.id}
                            onShowInfo={() => {
                              setInfoGroupId(federatedId(group));
                              setInfoOpen(true);
                            }}
                            setOpen={setOpen}
                            disabled={disableSelection}
                            hideInfoButton={hideInfoButtons}
                            extraListItemChrome={extraListItemChrome}
                            hideLeaveButton={hideLeaveButtons}
                          />
                        </div>
                      })
                    ]
                    : <div key='noGroups' style={{ width: '100%', display: 'flex' }}>
                      <Heading size='$3' mx='auto' o={0.5}>
                        No Groups {searchText != '' ? `Matched "${searchText}"` : 'Found'}
                      </Heading>
                    </div>}
                {/* </YStack> */}
              </FlipMove>
            </Sheet.ScrollView>
            {hasPermission(account?.user, Permission.CREATE_GROUPS) &&
              (!serverHostFilter || serverHostFilter === server?.host)
              ? <CreateGroupSheet />
              : undefined}
          </Sheet.Frame>
        </Sheet>
        : undefined}
      {
        selectedGroup && !hideInfoButtons
          ? <>
            <Theme inverse>
              <XStack opacity={0.7} marginVertical='auto'>
                <Button icon={Info} size="$2" circular mt={showServerInfo ? '$4' : undefined}
                  ml={infoMarginLeft}
                  onPress={() => {
                    setInfoGroupId(federatedId(selectedGroup));
                    setInfoOpen((x) => !x)
                  }} />
              </XStack>
            </Theme>
          </>
          : undefined
      }
      {
        !hideInfoButtons ?
          <GroupDetailsSheet {...{ selectedGroup, infoGroupId, infoOpen, setInfoOpen }} />
          : undefined
      }
    </>
  )
}

