import { RootState, loadUser, selectUserById, useRootSelector, useServerTheme } from "app/store";
import React, { useEffect, useState } from "react";

import { Author, Permission, Post } from "@jonline/api";
import { Anchor, DateViewer, Heading, Image, Paragraph, Spinner, Text, XStack, YStack, useMedia } from "@jonline/ui";
import { PermissionIndicator } from "@jonline/ui";
import { useCurrentAccountOrServer, useAppDispatch, useCredentialDispatch, useProvidedDispatch, useCurrentServer } from "app/hooks";
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
  larger?: boolean;
  shrink?: boolean;
  textColor?: string;
  nameOnly?: boolean;
  avatarOnly?: boolean;
  dateOnly?: boolean;
}
export const AuthorInfo = ({
  post,
  author = post?.author,
  disableLink = false,
  detailsMargins = 0,
  larger = false,
  shrink = false,
  textColor: inputTextColor,
  nameOnly = false,
  avatarOnly = false,
  dateOnly = false,
}: AuthorInfoProps) => {
  const { dispatch, accountOrServer } = useProvidedDispatch();
  // const author = inputAuthor as Author;
  const server = accountOrServer.server;
  const authorIdPair = author ? federatedIDPair(author.userId, server) : undefined;
  const serverAuthorId = author?.userId;
  const federatedAuthorId = serverAuthorId ? federateId(serverAuthorId, server) : undefined;
  const authorName = author?.username;
  const federatedAuthorName = authorName ? federateId(authorName, server) : undefined;
  // const { server, primaryColor, navColor } = useServerTheme();

  const isCurrentUser = serverAuthorId === accountOrServer.account?.user?.id;
  // console.log('AuthorInfo', { isCurrentUser, authorId: authorIdPair, currentUser: accountOrServer.account?.user })
  const { primaryAnchorColor, navAnchorColor } = useServerTheme(accountOrServer.server);
  const textColor = inputTextColor ??
    (isCurrentUser
      ? primaryAnchorColor
      : undefined);
  const permissionBadgeColor = inputTextColor;

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
  // const ref = React.useRef() as React.MutableRefObject<HTMLElement | View>;

  // useEffect(() => {
  //   if (server && serverAuthorId && isVisible) {
  //     if (!loadingAuthor && !authorUser && !authorLoadFailed) {
  //       // console.log('BEGIN loading author', federatedAuthorId, serverAuthorId, accountOrServer.server?.host, author)
  //       dispatch(loadUser({ userId: serverAuthorId, ...accountOrServer })).then((action) => {
  //         // setLoadingAuthor(false);
  //         // console.log('FINISH loading author', action)
  //       });
  //       setLoadingAuthor(true);
  //     } else if (loadingAuthor && authorUser) {
  //       setLoadingAuthor(false);
  //     }
  //   }
  // }, [!!server, serverAuthorId, isVisible, authorLoadFailed, loadingAuthor, author, authorUser]);
  const avatarUrl = useMediaUrl(author?.avatar?.id ?? authorUser?.avatar?.id, accountOrServer);
  const avatarSize = mediaQuery.gtXs
    ? shrink ? 30 : 50
    : shrink ? 18 : 26;
  const avatarImage = <XStack p={0} w={avatarSize} h={avatarSize}>
    <Image
      width={avatarSize}
      height={avatarSize}
      borderRadius={avatarSize / 2}
      resizeMode="cover"
      als="flex-start"
      source={{ uri: avatarUrl, width: avatarSize, height: avatarSize }}
    />
  </XStack>;

  const permissionsIndicators = [
    author && hasAdminPermission(authorUser ?? author)
      ? <PermissionIndicator key='admin' permission={Permission.ADMIN} color={permissionBadgeColor} /> : undefined,
    author && hasPermission(authorUser ?? author, Permission.RUN_BOTS)
      ? <PermissionIndicator key='bot' permission={Permission.RUN_BOTS} color={permissionBadgeColor} /> : undefined
  ];
  
  const username = author?.username ?? authorName;
  const realName = authorUser?.realName;
  const renderAsLoading = false;//loadingAuthor || (!authorUser && !authorLoadFailed);
  return <XStack alignContent='flex-start'>
    <YStack w={detailsMargins} />
    {(!nameOnly && !dateOnly && avatarUrl && avatarUrl != '')
      ? <YStack marginVertical='auto'>
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
    {avatarOnly
      ? undefined
      : <YStack>
        {dateOnly
          ? undefined
          : <XStack ai='center'>
            {/* <Heading size="$1" mr='$1' marginVertical='auto'>by</Heading> */}

            {/* <Heading size={larger ? '$7' : "$1"} ml='$1' mr='$2'
              marginVertical='auto' color={textColor}> */}
            {author ?? authorName
              ? disableLink
                ? `${username}`
                : <Anchor flexDirection='row' {...authorLinkProps} color={textColor}>
                  <Paragraph size={larger ? '$7' : '$1'} color={textColor}>
                    {username}
                  </Paragraph>
                  {realName
                    ? <Paragraph size={larger ? '$7' : '$1'} color={textColor}>
                      {' ('}
                      {<Text fontWeight='bold' color={textColor}>{authorUser.realName}</Text>}
                      {')'}
                    </Paragraph>
                    : undefined}
                </Anchor>
              : 'anonymous'}
            <Spinner size='small' ml='$2' animation='standard' color={textColor}
              opacity={renderAsLoading ? 0.5 : 0} />
            {/* </Heading> */}
            {nameOnly ? permissionsIndicators : undefined}
          </XStack>}
        {nameOnly
          ? undefined
          : <XStack>
            <XStack mr='$2'>
              {post
                ? <DateViewer date={post.publishedAt || post.createdAt} updatedDate={post.updatedAt} />
                : undefined}
            </XStack>
            {dateOnly ? undefined : permissionsIndicators}
          </XStack>
        }
      </YStack>}
  </XStack>;
}
