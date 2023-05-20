import { loadUser, RootState, selectUserById, useCredentialDispatch, useServerTheme, useTypedSelector } from "app/store";
import React, { useEffect, useState } from "react";

import { Permission, Post } from "@jonline/api";
import { Anchor, DateViewer, Heading, Image, useMedia, XStack, YStack } from "@jonline/ui";
import { PermissionIndicator } from "@jonline/ui/src/permission_indicator";
import { useLink } from "solito/link";
import { FadeInView } from "./fade_in_view";
import { useMediaUrl } from "app/hooks/use_media_url";

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
  // const authorAvatar = useTypedSelector((state: RootState) => authorId ? state.users.avatars[authorId] : undefined);
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
      if (!loadingAuthor && !author && !authorLoadFailed) {
        setLoadingAuthor(true);
        setTimeout(() => dispatch(loadUser({ id: authorId, ...accountOrServer })), 1);
      } else if (loadingAuthor && author) {
        setLoadingAuthor(false);
      }
    }
  });
  const avatarUrl = useMediaUrl(author?.avatarMediaId);
  // debugger;

  return <XStack f={1} ml={media.gtXs ? 0 : -7} alignContent='flex-start'>
    {(avatarUrl && avatarUrl != '') ?
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
                source={{ uri: avatarUrl }}
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
                  source={{ uri: avatarUrl }}
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
        <DateViewer date={post.createdAt} />
        {author && author.permissions.includes(Permission.ADMIN)
          ? <PermissionIndicator permission={Permission.ADMIN} /> : undefined}
        {author && author.permissions.includes(Permission.RUN_BOTS)
          ? <PermissionIndicator permission={Permission.RUN_BOTS} /> : undefined}
      </XStack>
    </YStack>
  </XStack>;
}
