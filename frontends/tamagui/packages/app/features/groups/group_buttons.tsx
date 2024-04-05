import { Group } from '@jonline/api';
import { Button, Heading, Image, Paragraph, Separator, Text, XStack, YStack, standardAnimation, useMedia } from '@jonline/ui';
import { Info, Users2 } from '@tamagui/lucide-icons';
import { useCurrentAccountOrServer, useAppDispatch, usePinnedAccountsAndServers, useFederatedDispatch, useMediaUrl } from 'app/hooks';
import { FederatedGroup, RootState, federatedId, getServerTheme, isGroupLocked, joinLeaveGroup, useRootSelector, useServerTheme } from 'app/store';
import { passes, pending, themedButtonBackground } from 'app/utils';
import React from 'react';
import { useLink } from 'solito/link';
import { ServerNameAndLogo, splitOnFirstEmoji } from '../navigation/server_name_and_logo';

export type GroupButtonProps = {
  group: FederatedGroup;
  selected: boolean;
  setOpen: (open: boolean) => void;
  onShowInfo: () => void;
  // Forwarder to link to a group page. Defaults to /g/:shortname.
  // But, for instance, post pages can link to /g/:shortname/p/:id.
  groupPageForwarder?: (groupIdentifier: string) => string;
  onGroupSelected?: (group: Group) => void;
  disabled?: boolean;
  hideInfoButton?: boolean;
  extraListItemChrome?: (group: Group) => JSX.Element | undefined;

  hideLeaveButton?: boolean;
}

export function GroupButton({ group, selected, setOpen, groupPageForwarder, onShowInfo, onGroupSelected, disabled, hideInfoButton, extraListItemChrome, hideLeaveButton }: GroupButtonProps) {
  const { dispatch, accountOrServer } = useFederatedDispatch(group);
  const mediaQuery = useMedia();
  const { account } = accountOrServer;
  const server = accountOrServer.server;
  const isPrimaryServer = useCurrentAccountOrServer().server?.host === accountOrServer.server?.host;
  const currentAndPinnedServers = usePinnedAccountsAndServers();
  const showServerInfo = !isPrimaryServer || currentAndPinnedServers.length > 1;
  // const dispatch = useAppDispatch();
  const groupIdentifier = isPrimaryServer ? group.shortname : `${group.shortname}@${group.serverHost}`;
  const link = onGroupSelected ? { onPress: () => onGroupSelected(group) } :
    useLink({ href: groupPageForwarder ? groupPageForwarder(groupIdentifier) : `/g/${groupIdentifier}` });
  const media = useMedia();
  const onPress = link.onPress;
  link.onPress = (e) => {
    setOpen(false);
    onPress?.(e);
  }
  const { textColor, primaryColor, primaryTextColor, navColor, navTextColor } = getServerTheme(server);

  const avatarUrl = useMediaUrl(group.avatar?.id);
  const hasAvatarUrl = avatarUrl && avatarUrl != '';
  const [groupNameBeforeEmoji, groupNameEmoji, groupNameAfterEmoji] = splitOnFirstEmoji(group.name);
  const displayedGroupName = groupNameEmoji && !hasAvatarUrl
    ? groupNameBeforeEmoji + (
      groupNameAfterEmoji && groupNameAfterEmoji != ''
        ? ' | ' + groupNameAfterEmoji
        : '')
    : group.name;
  const fullAvatarHeight = 48;

  return <XStack w='100%'>
    <YStack f={1} borderRadius='$5' borderWidth={1} borderColor={primaryColor} mb='$2'
      backgroundColor={selected ? navColor : undefined}
    >
      <XStack>
        <Button
          f={1}
          h='auto'
          px='$2'
          // bordered={false}
          // href={`/g/${group.shortname}`}
          transparent={!selected}

          // transparent={}

          // backgroundColor={selected ? navColor : undefined}
          {...themedButtonBackground(selected ? navColor : undefined, undefined, (disabled && !extraListItemChrome) ? 0.5 : 1)}
          // size="$8"
          // disabled={appSection == AppSection.HOME}
          disabled={disabled}
          pt='$2'
          {...link}
        >
          <YStack w='100%'>
            <XStack w='100%' ai='center'>
              <YStack w='100%' f={1} my='auto'>

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
                    {displayedGroupName}
                  </Paragraph>
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

              <YStack>
                {showServerInfo
                  ? <ServerNameAndLogo textColor={selected ? navTextColor : undefined} server={server} fallbackToHomeIcon />
                  : undefined}
                <XStack ml='auto'>
                  {hasAvatarUrl
                    ? <Image
                      // mb='$3'
                      // ml='$2'
                      mx='$2'
                      // mr={-10}
                      my='auto'
                      width={fullAvatarHeight}
                      height={fullAvatarHeight}
                      resizeMode="contain"
                      als="center"
                      source={{ uri: avatarUrl, height: fullAvatarHeight, width: fullAvatarHeight }}
                      borderRadius={10} />
                    : groupNameEmoji
                      ? <Heading size='$10' my='auto' mx='$2' whiteSpace="nowrap">
                        {groupNameEmoji}
                      </Heading>
                      : undefined}
                  {/* {showServerInfo && (hasAvatarUrl || groupNameEmoji)
            ? <Heading size='$7' id='server-icon-separator' mr='$2'>@</Heading>
            : undefined} */}
                  {/* {showServerInfo
            ? <XStack my='auto' w={'$4'} h={'$4'} jc='center'>
              <ServerNameAndLogo server={server} shrinkToSquare />
            </XStack>
            : undefined} */}
                  <XStack o={0.6} my='auto'>
                    <XStack my='auto'>
                      <Users2 size='$1' color={selected ? navTextColor : undefined} />
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
              </YStack>
            </XStack>
          </YStack>
        </Button>
      </XStack>
      <XStack flexWrap='wrap' w='100%'>
        <GroupJoinLeaveButton group={group} hideLeaveButton={hideLeaveButton} />
        {extraListItemChrome?.(group)}
      </XStack>
      {/* {accountOrServer.account || extraListItemChrome
      ? <Separator mt='$1' />
      : undefined} */}
    </YStack>
    {hideInfoButton ? undefined :
      <Button
        size='$2'
        my='auto'
        ml='$2'
        // mr='$2'
        circular
        icon={Info} onPress={() => onShowInfo()} />}
  </XStack>;
}

export type GroupJoinLeaveButtonProps = {
  group: FederatedGroup;
  hideLeaveButton?: boolean;
}

export function GroupJoinLeaveButton({ group, hideLeaveButton }: GroupJoinLeaveButtonProps) {
  const { dispatch, accountOrServer } = useFederatedDispatch(group);
  const { account } = accountOrServer;
  const server = accountOrServer.server;
  const { textColor, primaryColor, primaryTextColor, navColor, navTextColor } = getServerTheme(server);

  const joined = passes(group.currentUserMembership?.userModeration)
    && passes(group.currentUserMembership?.groupModeration);
  const membershipRequested = group.currentUserMembership && !joined && passes(group.currentUserMembership?.userModeration);
  const invited = group.currentUserMembership && !joined && passes(group.currentUserMembership?.groupModeration)
  const requiresPermissionToJoin = pending(group.defaultMembershipModeration);
  const isLocked = useRootSelector((state: RootState) => isGroupLocked(state.groups, federatedId(group)));

  const onJoinPressed = () => {
    // e.stopPropagation();
    const join = !(joined || membershipRequested || invited);
    dispatch(joinLeaveGroup({ groupId: group.id, join, ...accountOrServer }));
  };

  return account && (!hideLeaveButton || !joined)
    ? <XStack key='join-button' ac='center' jc='center' mx='auto' my='auto' >
      <Button mt='$2' backgroundColor={!joined && !membershipRequested ? primaryColor : undefined}
        // {...standardAnimation} animation='quick'
        mb='$2'
        p='$3'
        disabled={isLocked} opacity={isLocked ? 0.5 : 1}
        onPress={onJoinPressed}>
        <YStack jc='center' ac='center'>
          <Heading jc='center' ta='center' size='$2' color={!joined && !membershipRequested ? primaryTextColor : undefined}>
            {!joined && !membershipRequested ? requiresPermissionToJoin ? 'Join Request' : 'Join'
              : joined ? 'Leave' : 'Cancel Request'}
          </Heading>
          {requiresPermissionToJoin && joined ? <Paragraph size='$1'>
            Permission required to re-join
          </Paragraph>
            : undefined}
        </YStack>
      </Button>
    </XStack> : <></>;
}

