import { Group } from '@jonline/api';
import { Button, Text, Image, Heading, Paragraph, Separator, XStack, YStack, useMedia } from '@jonline/ui';
import { RootState, isGroupLocked, joinLeaveGroup, useAccountOrServer, useServerTheme, useTypedDispatch, useTypedSelector } from 'app/store';
import React from 'react';
import { useLink } from 'solito/link';
import { passes, pending } from '../../utils/moderation_utils';
import { } from '../post/post_card';
import { Info, Users2 } from '@tamagui/lucide-icons';
import { useMediaUrl } from 'app/hooks';

export type GroupButtonProps = {
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

export function GroupButton({ group, selected, setOpen, groupPageForwarder, onShowInfo, onGroupSelected, disabled, hideInfoButton, extraListItemChrome, hideLeaveButton }: GroupButtonProps) {
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

  const avatarUrl = useMediaUrl(group.avatar?.id);
  const hasAvatarUrl = avatarUrl && avatarUrl != '';
  const fullAvatarHeight = 48;

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
        <XStack w='100%'>
          <YStack w='100%' f={1} marginVertical='auto'>
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
                  <Users2 size='$1'color={selected ? navTextColor : undefined} />
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
          {hasAvatarUrl
            ? <Image
              // mb='$3'
              // ml='$2'
              ml='$2'
              mr={-10}
              my='auto'
              width={fullAvatarHeight}
              height={fullAvatarHeight}
              resizeMode="contain"
              als="center"
              source={{ uri: avatarUrl, height: fullAvatarHeight, width: fullAvatarHeight }}
              borderRadius={10} />
            : undefined}
        </XStack>
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
      <GroupJoinLeaveButton group={group} hideLeaveButton={hideLeaveButton} />
      {/* {accountOrServer.account && (!hideLeaveButton || !joined)
        ? <XStack key='join-button' ac='center' jc='center' mx='auto' my='auto' >
          <Button mt='$2' backgroundColor={!joined && !membershipRequested ? primaryColor : undefined}
            // {...standardAnimation} animation='quick'
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
        </XStack> : undefined} */}
      {extraListItemChrome?.(group)}
    </XStack>
    {accountOrServer.account || extraListItemChrome
      ? <Separator mt='$1' />
      : undefined}
  </YStack>;
}

export type GroupJoinLeaveButtonProps = {
  group: Group;
  hideLeaveButton?: boolean;
}

export function GroupJoinLeaveButton({ group, hideLeaveButton }: GroupJoinLeaveButtonProps) {
  const accountOrServer = useAccountOrServer();
  const { account } = accountOrServer;
  const dispatch = useTypedDispatch();

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

  return account && (!hideLeaveButton || !joined)
    ? <XStack key='join-button' ac='center' jc='center' mx='auto' my='auto' >
      <Button mt='$2' backgroundColor={!joined && !membershipRequested ? primaryColor : undefined}
        // {...standardAnimation} animation='quick'
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
    </XStack> : <></>;
}
