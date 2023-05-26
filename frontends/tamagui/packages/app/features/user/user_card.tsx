import { Permission, User } from "@jonline/api";
import { Anchor, Button, Card, Heading, Image, Paragraph, Theme, Tooltip, useMedia, XStack, YStack } from '@jonline/ui';
import { Bot, Camera, Shield } from "@tamagui/lucide-icons";

import { useOnScreen } from 'app/hooks/use_on_screen';
import { loadUser, RootState, useCredentialDispatch, useServerTheme, useTypedSelector } from "app/store";
import { passes, pending } from "app/utils/moderation";
import React, { useEffect } from "react";
import { GestureResponderEvent, View } from 'react-native';
import { followUnfollowUser, isUserLocked, respondToFollowRequest } from '../../store/modules/users';
import { useLocalApp } from '../../store/store';
import { FadeInView } from "../post/fade_in_view";
import { } from "../post/post_card";
import { useLink } from 'solito/link';
import { useMediaUrl } from "app/hooks/use_media_url";
import { MediaChooser } from "../media/media_chooser";

interface Props {
  user: User;
  isPreview?: boolean;
  username?: string;
  setUsername?: (username: string) => void;
  avatarMediaId?: string;
  setAvatarMediaId?: (mediaId?: string) => void;
}

export function useFullAvatarHeight(): number {
  const media = useMedia();
  return media.gtXs ? 400 : 300;
}

export const UserCard: React.FC<Props> = ({ user, isPreview = false, setUsername, avatarMediaId: avatarMediaIdProp, setAvatarMediaId }) => {
  const { dispatch, accountOrServer } = useCredentialDispatch();
  const media = useMedia();
  const app = useLocalApp();
  const avatarMediaId = setAvatarMediaId ? avatarMediaIdProp : user.avatarMediaId;

  const isAdmin = accountOrServer?.account?.user?.permissions?.includes(Permission.ADMIN);
  const isCurrentUser = accountOrServer.account && accountOrServer.account?.user?.id == user.id;
  const { server, primaryColor, navColor, primaryTextColor, navTextColor, textColor } = useServerTheme();
  const [loadingAvatar, setLoadingAvatar] = React.useState(false);

  const following = passes(user.currentUserFollow?.targetUserModeration);
  const followRequested = user.currentUserFollow && !following;
  const followsCurrentUser = passes(user.targetCurrentUserFollow?.targetUserModeration);
  const followRequestReceived = user.targetCurrentUserFollow && !followsCurrentUser;
  const isLocked = useTypedSelector((state: RootState) => isUserLocked(state.users, user.id));
  const userLink = useLink({ href: `/${user.username}` });
  const fullAvatarHeight = useFullAvatarHeight();

  const requiresPermissionToFollow = pending(user.defaultFollowModeration);

  const onFollowPressed = (e: GestureResponderEvent) => {
    e.stopPropagation();
    dispatch(followUnfollowUser({ userId: user.id, follow: !(following || followRequested), ...accountOrServer }))
  };

  const doRespondToFollowRequest = (e: GestureResponderEvent, accept: boolean) => {
    e.stopPropagation();
    dispatch(respondToFollowRequest({ userId: user.id, accept, ...accountOrServer }))
  };
  const ref = React.useRef() as React.MutableRefObject<HTMLElement | View>;
  const onScreen = useOnScreen(ref, "-1px");
  const avatarUrl = useMediaUrl(avatarMediaId ?? user?.avatarMediaId);
  // debugger;

  return (
    <Theme inverse={isCurrentUser}>
      <Card theme="dark" elevate size="$4" bordered
        animation="bouncy"
        ref={ref}
        // scale={0.9}
        margin='$0'
        width={'100%'}
        scale={1}
        opacity={1}
        y={0}
      // enterStyle={{ y: -50, opacity: 0, }}
      // exitStyle={{ opacity: 0, }}
      // width={400}
      // hoverStyle={isPreview ? { scale: 0.97 } : {}}
      // pressStyle={isPreview ? { scale: 0.95 } : {}}
      // {...(isPreview ? userLink : {})}
      >
        <Card.Header>
          <XStack>
            <Anchor f={1} {...(isPreview ? userLink : {})}>
              <YStack f={1}>
                <Heading size="$1" mr='auto'>{server?.host}/</Heading>

                {/* <Heading marginRight='auto' whiteSpace="nowrap" opacity={true ? 1 : 0.5}>{user.userConfiguration?.userInfo?.name || 'Unnamed'}</Heading> */}
                <Heading size="$7" marginRight='auto'>{user.username}</Heading>
              </YStack>
            </Anchor>

            {app.showUserIds ? <XStack o={0.6}>
              <Heading size='$1'>{user.id}</Heading>
              {/* <XStack f={1} /> */}
            </XStack> : undefined}

            {user.permissions.includes(Permission.ADMIN)
              ? <Tooltip placement="bottom-end">
                <Tooltip.Trigger>
                  <Shield />
                </Tooltip.Trigger>
                <Tooltip.Content>
                  <Heading size='$2'>User is an admin.</Heading>
                </Tooltip.Content>
              </Tooltip> : undefined}
            {user.permissions.includes(Permission.RUN_BOTS)
              ? <Tooltip placement="bottom-end">
                <Tooltip.Trigger>
                  <Bot />
                </Tooltip.Trigger>
                <Tooltip.Content>
                  <Heading size='$2' ta='center' als='center'>User may be (or run) a bot.</Heading>
                  <Heading size='$1' ta='center' als='center'>Posts may be written by an algorithm rather than a human.</Heading>
                </Tooltip.Content>
              </Tooltip> : undefined}

            {/* {isPreview ? <Button onPress={(e) => { e.stopPropagation(); infoLink.onPress(e); }} icon={<Info />} circular /> : undefined} */}
          </XStack>
        </Card.Header>
        <Card.Footer p='$3'>
          <YStack mt='$2' mr='$3' w='100%'>
            {(!isPreview && avatarUrl && avatarUrl != '') ?
              <FadeInView>
                <Image
                  // pos="absolute"
                  // width={400}
                  // opacity={0.25}
                  // height={400}
                  // minWidth={300}
                  // minHeight={300}
                  // width='100%'
                  // height='100%'
                  mb='$3'
                  width={fullAvatarHeight}
                  height={fullAvatarHeight}
                  resizeMode="contain"
                  als="center"
                  source={{ uri: avatarUrl }}
                  // src={avatarUrl}
                  borderRadius={10}
                // borderBottomRightRadius={5}
                />
              </FadeInView> : undefined}
            {(isCurrentUser || isAdmin) && setAvatarMediaId
              ? <YStack mb='$2'>
                <MediaChooser
                  selectedMedia={avatarMediaId ? [avatarMediaId] : []}
                  onMediaSelected={media => { setAvatarMediaId?.(media.length == 0 ? undefined : media[0]) }} >
                  <XStack>
                    <Camera color={navTextColor} />
                    <Heading color={navTextColor} ml='$3' my='auto' size='$1'>Choose Avatar</Heading>
                  </XStack>
                </MediaChooser>
              </YStack>
              : undefined}
            {followsCurrentUser ? <Heading size='$1' ta='center'>{following ? 'Friends' : 'Follows You'}</Heading> : undefined}
            {followRequestReceived ? <>
              <Heading size='$1' ta='center'>Wants to follow you</Heading>
              <XStack ac='center' jc='center' mb='$2' space='$2'>
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
            </> : undefined}
            {/* {followRequestReceived && accountOrServer.account && accountOrServer.account.user.id != user.id
              ? <YStack h='$2' /> : undefined} */}
            {accountOrServer.account && accountOrServer.account.user.id != user.id ? <XStack ac='center' jc='center'>
              <Button backgroundColor={!following && !followRequested ? primaryColor : undefined}
                mb='$2'
                p='$3'
                disabled={isLocked} opacity={isLocked ? 0.5 : 1}
                onPress={onFollowPressed}>
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
            <XStack>
              <Heading size='$1' f={1}>{user.followerCount} followers</Heading>
              <Heading size='$1' f={1} ta='right'>following {user.followingCount}</Heading>
            </XStack>
            <XStack>
              <Heading size='$1' f={1}>{user.groupCount} groups</Heading>
              <Heading size='$1' f={1} ta='right'>{user.postCount} posts/replies</Heading>
            </XStack>
          </YStack>
        </Card.Footer>
        <Card.Background>
          {/* <XStack>
            <YStack h='100%' w={5} backgroundColor={primaryColor} /> */}
          {(isPreview && avatarUrl && avatarUrl != '') ?
            <FadeInView>
              <Image
                pos="absolute"
                width={media.gtSm ? 300 : 150}
                height={media.gtSm ? 300 : 150}
                opacity={0.25}
                resizeMode="contain"
                als="flex-start"
                source={{ uri: avatarUrl }}
                // src={avatarUrl}
                blurRadius={1.5}
                // borderRadius={5}
                borderBottomRightRadius={5}
              />
            </FadeInView> : undefined}
          {/* </XStack> */}
        </Card.Background>
      </Card>
    </Theme>
  );
};
