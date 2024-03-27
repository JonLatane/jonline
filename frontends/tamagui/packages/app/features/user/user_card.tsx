import { Permission } from "@jonline/api";
import { Anchor, AnimatePresence, Button, Card, DateViewer, Heading, Image, Input, Paragraph, Theme, Tooltip, XStack, YStack, ZStack, useMedia, useTheme } from '@jonline/ui';
import { Bot, Building2, Shield } from "@tamagui/lucide-icons";

import { standardAnimation } from "@jonline/ui";
import { useAccountOrServer, useAppDispatch, useCurrentAndPinnedServers, useFederatedAccountOrServer, useLocalConfiguration } from 'app/hooks';
import { useMediaUrl } from "app/hooks/use_media_url";
import { FederatedUser, RootState, followUnfollowUser, getServerTheme, isUserLocked, respondToFollowRequest, useRootSelector } from "app/store";
import { passes, pending } from "app/utils/moderation_utils";
import { hasAdminPermission, hasPermission } from "app/utils/permission_utils";
import React from "react";
import { GestureResponderEvent } from 'react-native';
import { useLink } from 'solito/link';
import { SingleMediaChooser } from '../accounts/single_media_chooser';
import { MediaRef } from "../media/media_chooser";
import { ServerNameAndLogo } from "../navigation/server_name_and_logo";
import { postBackgroundSize } from "../post/post_card";

interface Props {
  user: FederatedUser;
  isPreview?: boolean;
  username?: string;
  setUsername?: (username: string) => void;
  avatar?: MediaRef;
  setAvatar?: (avatar?: MediaRef) => void;
  editable?: boolean;
  editingDisabled?: boolean;
}

export function useFullAvatarHeight(): number {
  const media = useMedia();
  return media.gtXs ? 400 : 300;
}

export const UserCard: React.FC<Props> = ({ user, isPreview = false, username: inputUsername, setUsername, avatar: inputAvatar, setAvatar, editable, editingDisabled }) => {
  // return <></>;
  // const { dispatch, accountOrServer } = useCredentialDispatch();
  const mediaQuery = useMedia();
  const dispatch = useAppDispatch();
  const accountOrServer = useFederatedAccountOrServer(user);
  const isPrimaryServer = useAccountOrServer().server?.host === user.serverHost;
  const currentAndPinnedServers = useCurrentAndPinnedServers();
  const showServerInfo = !isPrimaryServer || (isPreview && currentAndPinnedServers.length > 1);
  const { account, server } = accountOrServer;
  const media = useMedia();
  const { showUserIds } = useLocalConfiguration();
  const { imagePostBackgrounds, fancyPostBackgrounds, shrinkPreviews } = useLocalConfiguration();

  const [username, avatar] = editable ? [inputUsername, inputAvatar]
    : [user.username, user.avatar];

  const isAdmin = hasAdminPermission(account?.user);
  const isCurrentUser = account && account?.user?.id == user.id;
  const theme = useTheme();
  const { primaryColor, navColor, primaryTextColor, navTextColor, textColor } = getServerTheme(server, theme);

  const following = passes(user.currentUserFollow?.targetUserModeration);
  const followRequested = user.currentUserFollow && !following;
  const followsCurrentUser = passes(user.targetCurrentUserFollow?.targetUserModeration);
  const followRequestReceived = user.targetCurrentUserFollow && !followsCurrentUser;
  const isLocked = useRootSelector((state: RootState) => isUserLocked(state.users, user.id));
  const userLink = useLink({ href: isPrimaryServer ? `/${user.username}` : `/${user.username}@${user.serverHost}` });
  const fullAvatarHeight = useFullAvatarHeight();

  const requiresPermissionToFollow = pending(user.defaultFollowModeration);

  const onFollowPressed = (e: GestureResponderEvent) => {
    e.stopPropagation();
    const follow = !(following || followRequested);
    dispatch(followUnfollowUser({ userId: user.id, follow, ...accountOrServer }))
  };

  const doRespondToFollowRequest = (e: GestureResponderEvent, accept: boolean) => {
    e.stopPropagation();
    dispatch(respondToFollowRequest({ userId: user.id, accept, ...accountOrServer }))
  };
  const avatarUrl = useMediaUrl(avatar?.id, accountOrServer);
  const hasAvatarUrl = avatarUrl && avatarUrl != '';
  const canEditAvatar = (isCurrentUser || isAdmin) && editable && setAvatar && !editingDisabled;

  const usernameRegion = <XStack f={1} w='100%'>
    {hasAvatarUrl ? <Image
      width={50}
      height={50}
      mr='$2' my='auto'
      borderRadius={25}
      resizeMode="cover"
      als="flex-start"
      source={{ uri: avatarUrl, height: 50, width: 50 }}
    /> : <XStack></XStack>}
    <YStack f={1}>
      <XStack ai='center'>
        <Heading size="$1" >{server?.host}/</Heading>
        {showUserIds ? <Paragraph size='$1' ml='auto' mr='$2' o={0.6}>{user.id}</Paragraph> : undefined}
      </XStack>
      {/* <Heading marginRight='auto' whiteSpace="nowrap" opacity={true ? 1 : 0.5}>{user.userConfiguration?.userInfo?.name || 'Unnamed'}</Heading> */}
      {editable && !editingDisabled && setUsername
        ? <Input textContentType="name" f={1}
          my='auto'
          mr='$2'
          placeholder={`Username (required)`}
          disabled={editingDisabled} opacity={editingDisabled || username == '' ? 0.5 : 1}
          // autoCapitalize='words'
          value={username}
          onChange={(data) => { setUsername(data.nativeEvent.text) }} />
        :
        <Heading size="$7" marginRight='auto' w='100%'>{username}</Heading>}
    </YStack>
    {/* {showServerInfo
      ?  */}
    <XStack my='auto' w={mediaQuery.gtXxxs ? undefined : '$4'} h={mediaQuery.gtXxxs ? undefined : '$4'} animation='standard'
      o={showServerInfo ? 1 : 0} >
      <ServerNameAndLogo server={server} shrinkToSquare={!mediaQuery.gtXxxs} />
    </XStack>
    {/* : undefined} */}
  </XStack>;



  const mainImage = <YStack w='100%'>
    {(!isPreview && hasAvatarUrl)
      ? <Image
        mb='$3'
        width={fullAvatarHeight}
        height={fullAvatarHeight}
        resizeMode="contain"
        als="center"
        source={{ uri: avatarUrl, height: fullAvatarHeight, width: fullAvatarHeight }}
        borderRadius={10} />
      : undefined}
    {canEditAvatar
      ? <SingleMediaChooser selectedMedia={avatar} setSelectedMedia={setAvatar} />
      : undefined}
  </YStack>;
  const followHandler = <YStack w='100%'>
    <AnimatePresence>
      {followsCurrentUser
        ? <Heading key='follow-request-heading' animation='quick' {...standardAnimation}
          size='$1' ta='center'>
          {following ? 'Friends' : 'Follows You'}
        </Heading>
        : undefined}
      {followRequestReceived ?
        <YStack key='follow-request-heading' animation='quick' {...standardAnimation}
          gap='$2'>
          <Heading size='$1' ta='center'>Wants to follow you</Heading>
          <XStack ac='center' jc='center' mb='$2' gap='$2'>
            <Button onPress={(e) => doRespondToFollowRequest(e, true)} backgroundColor={primaryColor}
              disabled={isLocked} opacity={isLocked ? 0.5 : 1}>
              <Heading size='$2' color={primaryTextColor}>
                Accept
              </Heading>
            </Button>
            <Button onPress={(e) => doRespondToFollowRequest(e, false)}
              disabled={isLocked} opacity={isLocked ? 0.5 : 1} >
              <Heading size='$2' color={textColor}>
                Reject
              </Heading>
            </Button>
          </XStack>
        </YStack> : undefined}

      {accountOrServer.account && accountOrServer.account.user.id != user.id ? <XStack key='follow-button' ac='center' jc='center'>
        <Button
          backgroundColor={!following && !followRequested ? primaryColor : undefined}
          // animation='standard'
          {...standardAnimation}
          mb='$2'
          p='$3'
          disabled={isLocked} opacity={isLocked ? 0.5 : 1}
          onPress={onFollowPressed}
        >
          <YStack jc='center' ac='center'>
            <Heading jc='center' ta='center' size='$2' color={!following && !followRequested ? primaryTextColor : textColor}>
              {!following && !followRequested ? requiresPermissionToFollow ? 'Follow Request' : 'Follow'
                : following ? 'Unfollow' : 'Cancel Request'}
            </Heading>
            {requiresPermissionToFollow && following ? <Paragraph size='$1'>
              Permission required to re-follow
            </Paragraph> : undefined}
          </YStack>
        </Button>
      </XStack> : undefined}
    </AnimatePresence>
  </YStack>

  const footerContent = <YStack mt='$2' mr='$3' w='100%'>
    <XStack>
      <Heading size='$1' f={1}>{user.followerCount} {user.followerCount === 1 ? 'follower' : 'followers'}</Heading>
      <Heading size='$1' f={1} ta='right'>following {user.followingCount}</Heading>
    </XStack>
    <XStack>
      <Heading size='$1' f={1}>{user.groupCount} {user.groupCount === 1 ? 'group' : 'groups'}</Heading>
      <Heading size='$1' f={1} ta='right'>{user.postCount} {user.postCount === 1 ? 'post/reply' : 'posts/replies'}</Heading>
    </XStack>
    <YStack jc='flex-end' ai='flex-end' ac='flex-end'>
      <Paragraph size='$1' o={0.5}>Account Created</Paragraph>
      <DateViewer date={user.createdAt} updatedDate={user.updatedAt} />
      {/* {showUserIds ? <XStack o={0.6}>
        <Paragraph size='$1' mt='$1' mr='$1'>{user.id}</Paragraph>
      </XStack> : undefined} */}
    </YStack>
  </YStack>;

  const backgroundSize = postBackgroundSize(media);
  return (
    <Theme /*inverse={isCurrentUser ?? false}*/>
      <Card theme="dark" size="$4" bordered
        animation='standard' {...standardAnimation}
        // scale={0.9}
        borderColor={showServerInfo ? primaryColor : undefined}
        pl='$2'
        margin='$0'
        width={'100%'}
        scale={1}
        opacity={1}
        y={0}
      >
        <Card.Header>
          <XStack w='100%' gap='$1' ai='center'>
            {isPreview
              ? <Anchor w='100%' f={1} textDecorationLine='none' {...(isPreview ? userLink : {})}>
                {usernameRegion}
              </Anchor>
              : usernameRegion}

            {hasAdminPermission(user)
              ? <Tooltip placement="bottom-end">
                <Tooltip.Trigger>
                  <Shield />
                </Tooltip.Trigger>
                <Tooltip.Content>
                  <Heading size='$2'>User is an admin.</Heading>
                </Tooltip.Content>
              </Tooltip> : undefined}
            {hasPermission(user, Permission.BUSINESS)
              ? <Tooltip placement="bottom-end">
                <Tooltip.Trigger>
                  <Building2 />
                </Tooltip.Trigger>
                <Tooltip.Content>
                  <Heading size='$2' ta='center' als='center'>Business Account</Heading>
                  {/* <Heading size='$1' ta='center' als='center'>Posts may be written by an algorithm rather than a human.</Heading> */}
                </Tooltip.Content>
              </Tooltip> : undefined}
            {hasPermission(user, Permission.RUN_BOTS)
              ? <Tooltip placement="bottom-end">
                <Tooltip.Trigger>
                  <Bot />
                </Tooltip.Trigger>
                <Tooltip.Content>
                  <Heading size='$2' ta='center' als='center'>User may be (or run) a bot.</Heading>
                  <Heading size='$1' ta='center' als='center'>Posts may be written by an algorithm rather than a human.</Heading>
                </Tooltip.Content>
              </Tooltip> : undefined}
          </XStack>
        </Card.Header>
        <Card.Footer p='$3'>
          <YStack mt='$2' mr='$3' w='100%'>
            {isPreview
              ? <Anchor w='100%' f={1} textDecorationLine='none' {...(isPreview ? userLink : {})}>
                {mainImage}
              </Anchor>
              : mainImage}
            {followHandler}
            <AnimatePresence>
              {isPreview
                ? shrinkPreviews ? undefined
                  : <Anchor w='100%' f={1} animation='standard' {...standardAnimation} textDecorationLine='none' {...(isPreview ? userLink : {})}>
                    {footerContent}
                  </Anchor>
                : footerContent}
            </AnimatePresence>
          </YStack>
        </Card.Footer>
        {imagePostBackgrounds
          ? <Card.Background>
            <ZStack w='100%' h='100%'>
              {(isPreview && hasAvatarUrl) ?
                <Image
                  mr={0}
                  o={0.10}
                  width={backgroundSize}
                  height={backgroundSize}
                  opacity={fancyPostBackgrounds ? 0.11 : 0.04}
                  resizeMode="cover"
                  als="center"
                  source={{ uri: avatarUrl, height: backgroundSize, width: backgroundSize }}
                  blurRadius={fancyPostBackgrounds ? 1.5 : undefined}
                  borderBottomRightRadius={5}
                />
                : undefined}

              <XStack h='100%'>
                <YStack h='100%' w={8}
                  borderTopLeftRadius={20} borderBottomLeftRadius={20}
                  backgroundColor={primaryColor} />
                <YStack h='100%' w={3}
                  backgroundColor={navColor} />
              </XStack>
            </ZStack>
          </Card.Background>
          : undefined}
      </Card>
    </Theme>
  );
};
