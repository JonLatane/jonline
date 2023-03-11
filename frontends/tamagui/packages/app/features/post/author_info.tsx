import { loadUser, RootState, selectUserById, useCredentialDispatch, useServerTheme, useTypedSelector } from "app/store";
import React, { useEffect, useState } from "react";

import { Permission, Post } from "@jonline/api";
import { Anchor, Heading, Image, Tooltip, useMedia, XStack, YStack } from "@jonline/ui";
import { Bot, Shield } from "@tamagui/lucide-icons";
import moment from "moment";
import { useLink } from "solito/link";
import { FadeInView } from "./fade_in_view";

export type AuthorInfoProps = {
  post: Post;
  detailsMargins?: number;
  isPreview?: boolean;
}
export const AuthorInfo = ({ post, isPreview, detailsMargins = 0 }: AuthorInfoProps) => {
  const authorId = post.author?.userId;
  const authorName = post.author?.username;
  const { dispatch, accountOrServer } = useCredentialDispatch();
  const { server, primaryColor, navColor } = useServerTheme();
  const media = useMedia();
  const author = useTypedSelector((state: RootState) => authorId ? selectUserById(state.users, authorId) : undefined);
  const authorAvatar = useTypedSelector((state: RootState) => authorId ? state.users.avatars[authorId] : undefined);
  const authorLoadFailed = useTypedSelector((state: RootState) => authorId ? state.users.failedUserIds.includes(authorId) : false);

  const [loadingAuthor, setLoadingAuthor] = useState(false);
  const authorLink = useLink({
    href: authorName
      ? `/${authorName}`
      : `/user/${authorId}`
  });
  const authorLinkProps = author ? authorLink : undefined;
  if (authorLinkProps) {
    const authorOnPress = authorLinkProps.onPress;
    authorLinkProps.onPress = (event) => {
      event?.stopPropagation();
      authorOnPress?.(event);
    }
  }
  useEffect(() => {
    if (authorId) {
      if (!loadingAuthor && (!author || authorAvatar == undefined) && !authorLoadFailed) {
        setLoadingAuthor(true);
        setTimeout(() => dispatch(loadUser({ id: authorId, ...accountOrServer })), 1);
      } else if (loadingAuthor && author) {
        setLoadingAuthor(false);
      }
    }
  });
  return <XStack f={1} ml={media.gtXs ? 0 : -7} alignContent='flex-start'>
    {(authorAvatar && authorAvatar != '') ?
      <YStack marginVertical='auto'>
        {isPreview
          ? <FadeInView>
            <XStack w={media.gtXs ? 50 : 26} h={media.gtXs ? 50 : 26}
              mr={media.gtXs ? '$3' : '$2'}>
              <Image
                pos="absolute"
                width={media.gtXs ? 50 : 26}
                // opacity={0.25}
                height={media.gtXs ? 50 : 26}
                borderRadius={media.gtXs ? 25 : 13}
                resizeMode="contain"
                als="flex-start"
                src={authorAvatar}
              // blurRadius={1.5}
              // borderRadius={5}
              />
            </XStack>
          </FadeInView>
          :
          <FadeInView>
            <Anchor {...authorLinkProps}
              mr={media.gtXs ? '$3' : '$2'}>
              <XStack w={media.gtXs ? 50 : 26} h={media.gtXs ? 50 : 26}>
                <Image
                  pos="absolute"
                  width={media.gtXs ? 50 : 26}
                  // opacity={0.25}
                  height={media.gtXs ? 50 : 26}
                  borderRadius={media.gtXs ? 25 : 13}
                  resizeMode="contain"
                  als="flex-start"
                  src={authorAvatar}
                // blurRadius={1.5}
                // borderRadius={5}
                />
              </XStack>
            </Anchor>
          </FadeInView>}
      </YStack>
      : undefined}
    <YStack marginLeft={detailsMargins}>
      <XStack>
        {/* <Heading size="$1" mr='$1' marginVertical='auto'>by</Heading> */}

        <Heading size="$1" ml='$1' mr='$2'
          marginVertical='auto'>
          {author
            ? isPreview
              ? `${author?.username}`
              : <Anchor size='$1' {...authorLinkProps}>{author?.username}</Anchor>
            : 'anonymous'}
        </Heading>
      </XStack>
      <XStack>
        <Tooltip placement="bottom-start">
          <Tooltip.Trigger>
            <Heading size="$1" marginVertical='auto' mr='$2'>
              {moment.utc(post.createdAt).local().startOf('seconds').fromNow()}
            </Heading>
          </Tooltip.Trigger>
          <Tooltip.Content>
            <Heading size='$2'>{moment.utc(post.createdAt).local().format("ddd, MMM Do YYYY, h:mm:ss a")}</Heading>
          </Tooltip.Content>
        </Tooltip>
        {author && author.permissions.includes(Permission.ADMIN)
          ? <Tooltip placement="bottom">
            <Tooltip.Trigger>
              <Shield />
            </Tooltip.Trigger>
            <Tooltip.Content>
              <Heading size='$2'>User is an admin.</Heading>
            </Tooltip.Content>
          </Tooltip> : undefined}
        {author && author.permissions.includes(Permission.RUN_BOTS)
          ? <Tooltip placement="bottom">
            <Tooltip.Trigger>
              <Bot />
            </Tooltip.Trigger>
            <Tooltip.Content>
              <Heading size='$2' ta='center' als='center'>User may be (or run) a bot.</Heading>
              <Heading size='$1' ta='center' als='center'>Posts may be written by an algorithm rather than a human.</Heading>
            </Tooltip.Content>
          </Tooltip> : undefined}
      </XStack>
    </YStack>
  </XStack>;
}
