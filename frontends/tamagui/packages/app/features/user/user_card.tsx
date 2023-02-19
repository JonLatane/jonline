import { Card, Heading, Image, Theme, useMedia, User, XStack, YStack } from "@jonline/ui";
import { Permission, Tooltip } from "@jonline/ui/src";
import { Bot, Camera, Shield } from "@tamagui/lucide-icons";
import { loadUser, RootState, useCredentialDispatch, useServerTheme, useTypedSelector } from "app/store";
import React, { useEffect } from "react";
import { FadeInView } from "../post/fade_in_view";
import { } from "../post/post_card";

interface Props {
  user: User;
  isPreview?: boolean;
  setUsername?: (username: string) => void;
  setAvatar?: (encodedBlob: string) => void;
}

const UserCard: React.FC<Props> = ({ user, isPreview = false, setUsername, setAvatar }) => {
  const { dispatch, accountOrServer } = useCredentialDispatch();
  const media = useMedia();

  const isCurrentUser = accountOrServer.account && accountOrServer.account?.user?.id == user.id;
  const { server, primaryColor, navColor } = useServerTheme();
  const avatar = useTypedSelector((state: RootState) => state.users.avatars[user.id]);
  const [loadingAvatar, setLoadingAvatar] = React.useState(false);

  useEffect(() => {
    if (!loadingAvatar) {
      if (avatar == undefined) {
        setLoadingAvatar(true);
        setTimeout(() => dispatch(loadUser({ id: user.id, ...accountOrServer })), 1);
      } else if (avatar != undefined) {
        setLoadingAvatar(false);
      }
    }
  });

  return (
    <Theme inverse={isCurrentUser}>
      <Card theme="dark" elevate size="$4" bordered
        animation="bouncy"
        scale={0.9}
        width={isPreview ? 260 : '100%'}
        // width={400}
        hoverStyle={{ scale: 0.925 }}
        pressStyle={{ scale: 0.875 }}>
        <Card.Header>
          <XStack>
            <YStack f={1}>
              <Heading size="$1" style={{ marginRight: 'auto' }}>{server?.host}/</Heading>

              {/* <Heading marginRight='auto' whiteSpace="nowrap" opacity={true ? 1 : 0.5}>{user.userConfiguration?.userInfo?.name || 'Unnamed'}</Heading> */}
              <Heading size="$7" marginRight='auto'>{user.username}</Heading>
            </YStack>

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
        <Card.Footer>
          <YStack mt='$2' mr='$3' w='100%'>
            <XStack>
              <Heading size='$1' f={1}>{user.followerCount} followers</Heading>
              <Heading size='$1' f={1} ta='right'>following {user.followingCount}</Heading>
            </XStack>
            <XStack>
              <Heading size='$1' f={1}>{user.groupCount} groups</Heading>
              <Heading size='$1' f={1} ta='right'>{user.postCount} posts/replies</Heading>
            </XStack>
            {(!isPreview && avatar && avatar != '') ?
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
                width={media.gtXs ? 400 : 300}
                height={media.gtXs ? 400 : 300}
                resizeMode="contain"
                als="center"
                src={avatar}
                borderRadius={10}
              // borderBottomRightRadius={5}
              /> : undefined}
            <XStack>
              <Heading size='$1'>{user.id}</Heading>
              <XStack f={1} />
              {isCurrentUser && setAvatar ? <Camera /> : undefined}
            </XStack>
          </YStack>
        </Card.Footer>
        <Card.Background>
          {/* <XStack>
            <YStack h='100%' w={5} backgroundColor={primaryColor} /> */}
          {(isPreview && avatar && avatar != '') ?
            <FadeInView>
              <Image
                pos="absolute"
                width={300}
                opacity={0.25}
                height={300}
                resizeMode="contain"
                als="flex-start"
                src={avatar}
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

export default UserCard;
