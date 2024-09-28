import { RootState, useRootSelector, useServerTheme } from "app/store";
import React, { useState } from "react";

import { Author, Permission, Post } from "@jonline/api";
import { Anchor, DateViewer, Image, Paragraph, PermissionIndicator, Spinner, Text, XStack, YStack, useMedia } from "@jonline/ui";
import { useProvidedDispatch } from "app/hooks";
import { useMediaUrl } from "app/hooks/use_media_url";
import { federateId, federatedIDPair } from "app/store/federation";
import { hasAdminPermission, hasPermission } from "app/utils/permission_utils";
import { useLink } from "solito/link";

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
  const avatarUrl = useMediaUrl(author?.avatar?.id, accountOrServer);
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
    author && hasAdminPermission(author)
      ? <PermissionIndicator key='admin' permission={Permission.ADMIN} color={permissionBadgeColor} /> : undefined,
    author && hasPermission(author, Permission.RUN_BOTS)
      ? <PermissionIndicator key='bot' permission={Permission.RUN_BOTS} color={permissionBadgeColor} /> : undefined
  ];

  const username = author?.username ?? authorName;
  const realName = author?.realName;

  const renderAsLoading = false;

  return <XStack alignContent='flex-start'>
    <YStack w={detailsMargins} />
    {(!nameOnly && !dateOnly && avatarUrl && avatarUrl != '')
      ? <YStack marginVertical='auto'>
        {disableLink
          ?
          { avatarImage }
          :
          <Anchor {...authorLinkProps}
            mr={mediaQuery.gtXs ? '$3' : '$2'}>
            {avatarImage}
          </Anchor>
        }
      </YStack>
      : undefined}
    {avatarOnly
      ? undefined
      : <YStack>
        {dateOnly
          ? undefined
          : <XStack ai='center'>
            {author ?? authorName
              ? disableLink
                ? username
                // ? <>
                //   <Paragraph size={larger ? '$7' : '$1'} color={textColor}>
                //     {username}
                //   </Paragraph>
                //   {realName
                //     ? <Paragraph size={larger ? '$7' : '$1'} color={textColor}>
                //       {' ('}
                //       {<Text fontWeight='bold' color={textColor}>{authorUser.realName}</Text>}
                //       {')'}
                //     </Paragraph>
                //     : undefined}
                // </>
                : <Anchor flexDirection='row' {...authorLinkProps} color={textColor}>
                  <Paragraph size={larger ? '$7' : '$1'} color={textColor}>
                    {username}
                  </Paragraph>
                  {realName
                    ? <Paragraph size={larger ? '$7' : '$1'} color={textColor}>
                      {' ('}
                      {<Text fontWeight='bold' color={textColor}>{realName}</Text>}
                      {')'}
                    </Paragraph>
                    : undefined}
                </Anchor>
              : 'anonymous'}
            <Spinner size='small' ml='$2' animation='standard' color={textColor}
              opacity={renderAsLoading ? 0.5 : 0} />
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
