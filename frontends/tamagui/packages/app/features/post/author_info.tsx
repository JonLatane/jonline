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
  larger?: boolean;
}
export const AuthorInfo = ({ post, author = post?.author, disableLink = false, detailsMargins = 0, isVisible = true, larger = false }: AuthorInfoProps) => {
  const { dispatch, accountOrServer } = useProvidedDispatch();
  // const author = inputAuthor as Author;
  const server = accountOrServer.server;
  const authorId = author ? federatedIDPair(author.userId, server) : undefined;
  const serverAuthorId = author?.userId;
  const federatedAuthorId = serverAuthorId ? federateId(serverAuthorId, server) : undefined;
  const authorName = author?.username;
  const federatedAuthorName = authorName ? federateId(authorName, server) : undefined;
  // const { server, primaryColor, navColor } = useServerTheme();
  const mediaQuery = useMedia();
  const authorUser = useRootSelector((state: RootState) => federatedAuthorId ? 
    selectUserById(state.users, federatedAuthorId) : undefined);
  // const authorAvatar = useRootSelector((state: RootState) => authorId ? state.users.avatars[authorId] : undefined);
  const authorLoadFailed = useRootSelector((state: RootState) => federatedAuthorId ? state.users.failedUserIds.includes(federatedAuthorId) : false);

  const [loadingAuthor, setLoadingAuthor] = useState(false);
  const authorLink = useLink({
    href: `/${federatedAuthorName}`
  });
  const authorLinkProps = authorLink;
  if (authorLinkProps) {
    const authorOnPress = authorLinkProps.onPress;
    authorLinkProps.onPress = (event) => {
      event?.stopPropagation();
      authorOnPress?.(event);
    }
  }
  // console.log("RENDER loading author", federatedAuthorId, authorUser);
  const ref = React.useRef() as React.MutableRefObject<HTMLElement | View>;

  useEffect(() => {
    if (server && serverAuthorId && isVisible) {
      if (!loadingAuthor && !authorUser && !authorLoadFailed) {
        // console.log('BEGIN loading author', federatedAuthorId, serverAuthorId, accountOrServer.server?.host, author)
        dispatch(loadUser({ userId: serverAuthorId, ...accountOrServer })).then((action) => {
          // setLoadingAuthor(false);
          // console.log('FINISH loading author', action)
        });
        setLoadingAuthor(true);
      } else if (loadingAuthor && authorUser) {
        setLoadingAuthor(false);
      }
    }
  }, [!!server, serverAuthorId, isVisible, authorLoadFailed, loadingAuthor, author, authorUser]);
  const avatarUrl = useMediaUrl(author?.avatar?.id ?? authorUser?.avatar?.id, accountOrServer);
  const avatarImage = <XStack p={0} w={mediaQuery.gtXs ? 50 : 26} h={mediaQuery.gtXs ? 50 : 26}>
    <Image
      width={mediaQuery.gtXs ? 50 : 26}
      height={mediaQuery.gtXs ? 50 : 26}
      borderRadius={mediaQuery.gtXs ? 25 : 13}
      resizeMode="cover"
      als="flex-start"
      source={{ uri: avatarUrl, width: mediaQuery.gtXs ? 50 : 26, height: mediaQuery.gtXs ? 50 : 26 }}
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
            mr={mediaQuery.gtXs ? '$3' : '$2'}>
            {avatarImage}
          </Anchor>
          // </FadeInView>
        }
      </YStack>
      : undefined}
    <YStack>
      <XStack>
        {/* <Heading size="$1" mr='$1' marginVertical='auto'>by</Heading> */}

        <Heading size={larger ? '$7' : "$1"} ml='$1' mr='$2'
          marginVertical='auto'>
          {author ?? authorName
            ? disableLink
              ? `${author?.username ?? authorName}`
              : <Anchor size={larger ? '$7' : '$1'} {...authorLinkProps}>{author?.username ?? authorName}</Anchor>
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
