import { RootState, loadUser, selectUserById, useRootSelector } from "app/store";
import React, { useEffect, useState } from "react";

import { Author, Permission, Post } from "@jonline/api";
import { Anchor, DateViewer, Heading, Image, XStack, YStack, useMedia } from "@jonline/ui";
import { PermissionIndicator } from "@jonline/ui/src/permission_indicator";
import { useAccountOrServer, useAppDispatch, useCredentialDispatch, useProvidedDispatch, useServer } from "app/hooks";
import { useMediaUrl } from "app/hooks/use_media_url";
import { federateId, federatedIDPair } from "app/store/federation";
import { hasAdminPermission, hasPermission } from "app/utils/permission_utils";
import { View } from "react-native";
import { useLink } from "solito/link";
import { useAccountOrServerContext } from "app/contexts";

export type AuthorInfoProps = {
  author?: Author;
  post?: Post;
  detailsMargins?: number;
  disableLink?: boolean;
  isVisible?: boolean;
}
export const AuthorInfo = ({ post, author: inputAuthor = post?.author, disableLink = false, detailsMargins = 0, isVisible = true }: AuthorInfoProps) => {
  const { dispatch, accountOrServer } = useProvidedDispatch();
  if ((!post && !inputAuthor)) {
    // throw new Error('AuthorInfo requires either a post or an author');
  }
  if (post && inputAuthor && post.author?.userId !== inputAuthor.userId) {
    // throw new Error('Post author and author props do not match');
  }
  const author = inputAuthor as Author;
  const server = useServer();
  const authorId = federatedIDPair(author.userId, server);
  const serverAuthorId = author?.userId;
  const federatedAuthorId = serverAuthorId && federateId(serverAuthorId, server);
  const authorName = author?.username;
  // const { server, primaryColor, navColor } = useServerTheme();
  const media = useMedia();
  const authorUser = useRootSelector((state: RootState) => federatedAuthorId ? selectUserById(state.users, federatedAuthorId) : undefined);
  // const authorAvatar = useRootSelector((state: RootState) => authorId ? state.users.avatars[authorId] : undefined);
  const authorLoadFailed = useRootSelector((state: RootState) => federatedAuthorId ? state.users.failedUserIds.includes(federatedAuthorId) : false);

  const [loadingAuthor, setLoadingAuthor] = useState(false);
  const authorLink = useLink({
    href: authorName
      ? `/${authorName}`
      : author
        ? `/${author.username}`
        : `/user/${serverAuthorId}`
  });
  const authorLinkProps = authorLink;
  if (authorLinkProps) {
    const authorOnPress = authorLinkProps.onPress;
    authorLinkProps.onPress = (event) => {
      event?.stopPropagation();
      authorOnPress?.(event);
    }
  }
  console.log
  const ref = React.useRef() as React.MutableRefObject<HTMLElement | View>;

  useEffect(() => {
    if (serverAuthorId && isVisible) {
      if (!loadingAuthor && !authorUser && !authorLoadFailed) {
        console.log('loading author')
        dispatch(loadUser({ userId: serverAuthorId, ...accountOrServer }));
        setLoadingAuthor(true);
      } else if (loadingAuthor && author) {
        setLoadingAuthor(false);
      }
    }
  }, [serverAuthorId, isVisible]);
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
          {post
            ? <DateViewer date={post.publishedAt || post.createdAt} updatedDate={post.updatedAt} />
            : undefined}
        </XStack>
        {author && hasAdminPermission(authorUser)
          ? <PermissionIndicator permission={Permission.ADMIN} /> : undefined}
        {author && hasPermission(authorUser, Permission.RUN_BOTS)
          ? <PermissionIndicator permission={Permission.RUN_BOTS} /> : undefined}
      </XStack>
    </YStack>
  </XStack>;
}
