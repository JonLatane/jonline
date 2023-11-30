import { loadUser, RootState, selectUserById, useCredentialDispatch, useServerTheme, useRootSelector } from "app/store";
import React, { useEffect, useState } from "react";

import { Permission, Post } from "@jonline/api";
import { Anchor, Avatar, DateViewer, Heading, Image, useMedia, XStack, YStack } from "@jonline/ui";
import { PermissionIndicator } from "@jonline/ui/src/permission_indicator";
import { useMediaUrl } from "app/hooks/use_media_url";
import { View } from "react-native";
import { useLink } from "solito/link";
import { hasAdminPermission, hasPermission } from "app/utils/permission_utils";

export type AuthorInfoProps = {
  post: Post;
  detailsMargins?: number;
  disableLink?: boolean;
  isVisible?: boolean;
}
export const AuthorInfo = ({ post, disableLink = false, detailsMargins = 0, isVisible = true }: AuthorInfoProps) => {
  const authorId = post.author?.userId;
  const authorName = post.author?.username;
  const { dispatch, accountOrServer } = useCredentialDispatch();
  const { server, primaryColor, navColor } = useServerTheme();
  const media = useMedia();
  const author = useRootSelector((state: RootState) => authorId ? selectUserById(state.users, authorId) : undefined);
  // const authorAvatar = useRootSelector((state: RootState) => authorId ? state.users.avatars[authorId] : undefined);
  const authorLoadFailed = useRootSelector((state: RootState) => authorId ? state.users.failedUserIds.includes(authorId) : false);

  const [loadingAuthor, setLoadingAuthor] = useState(false);
  const authorLink = useLink({
    href: authorName
      ? `/${authorName}`
      : author
        ? `/${author.username}`
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
  const ref = React.useRef() as React.MutableRefObject<HTMLElement | View>;

  useEffect(() => {
    if (authorId && isVisible) {
      if (!loadingAuthor && !author && !authorLoadFailed) {
        dispatch(loadUser({ id: authorId, ...accountOrServer }));
        setLoadingAuthor(true);
      } else if (loadingAuthor && author) {
        setLoadingAuthor(false);
      }
    }
  }, [authorId, isVisible]);
  const avatarUrl = useMediaUrl(author?.avatar?.id);
  const avatarImage = <XStack p={0} w={media.gtXs ? 50 : 26} h={media.gtXs ? 50 : 26}>
    <Image
      width={media.gtXs ? 50 : 26}
      height={media.gtXs ? 50 : 26}
      borderRadius={media.gtXs ? 25 : 13}
      resizeMode="cover"
      als="flex-start"
      source={{ uri: avatarUrl, width: media.gtXs ? 50 : 26, height: media.gtXs ? 50 : 26 }}
    />
  </XStack>;

  return <XStack ref={ref} f={1} /*ml={media.gtXs ? 0 : -7}*/ alignContent='flex-start'>
    <YStack w={detailsMargins} />
    {(avatarUrl && avatarUrl != '') ?
      <YStack marginVertical='auto'>
        {disableLink
          ?
          // <FadeInView>
          { avatarImage }
          // </FadeInView>
          :
          // <FadeInView>
          <Anchor {...authorLinkProps}
            mr={media.gtXs ? '$3' : '$2'}>
            {avatarImage}
          </Anchor>
          // </FadeInView>
        }
      </YStack>
      : undefined}
    <YStack>
      <XStack>
        {/* <Heading size="$1" mr='$1' marginVertical='auto'>by</Heading> */}

        <Heading size="$1" ml='$1' mr='$2'
          marginVertical='auto'>
          {author ?? authorName
            ? disableLink
              ? `${author?.username ?? authorName}`
              : <Anchor size='$1' {...authorLinkProps}>{author?.username ?? authorName}</Anchor>
            : 'anonymous'}
        </Heading>
      </XStack>
      <XStack>
        <XStack mr='$2'>
          <DateViewer date={post.createdAt} updatedDate={post.updatedAt} />
        </XStack>
        {author && hasAdminPermission(author)
          ? <PermissionIndicator permission={Permission.ADMIN} /> : undefined}
        {author && hasPermission(author, Permission.RUN_BOTS)
          ? <PermissionIndicator permission={Permission.RUN_BOTS} /> : undefined}
      </XStack>
    </YStack>
  </XStack>;
}
