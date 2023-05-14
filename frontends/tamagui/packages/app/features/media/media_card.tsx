import { colorMeta, loadUser, RootState, selectUserById, useCredentialDispatch, useServerTheme, useTypedSelector } from "app/store";
import React, { useEffect, useState } from "react";
import { View } from "react-native";

import { Media } from "@jonline/api";
import { Card, Heading, Theme, useMedia, useTheme, XStack, YStack } from "@jonline/ui";
import { useOnScreen } from "app/hooks/use_on_screen";
import { TamaguiMarkdown } from "../post/tamagui_markdown";

interface Props {
  media: Media;
}

export const MediaCard: React.FC<Props> = ({ media }) => {
  const { dispatch, accountOrServer } = useCredentialDispatch();
  const [loadingPreview, setLoadingPreview] = React.useState(false);
  const mediaQuery = useMedia();

  const theme = useTheme();
  const textColor: string = theme.color.val;
  // const themeBgColor = theme.background.val;
  const { server, primaryColor, navAnchorColor: navColor, backgroundColor: themeBgColor } = useServerTheme();
  const { luma: themeBgLuma } = colorMeta(themeBgColor);
  const postsStatus = useTypedSelector((state: RootState) => state.posts.status);
  // const postsBaseStatus = useTypedSelector((state: RootState) => state.posts.baseStatus);
  // const preview: string | undefined = useTypedSelector((state: RootState) => state.posts.previews[post.id]);
  const ref = React.useRef() as React.MutableRefObject<HTMLElement | View>;
  // Call the hook passing in ref and root margin
  // In this case it would only be considered onScreen if more ...
  // ... than 300px of element is visible.
  const onScreen = useOnScreen(ref, "-1px");
  // useEffect(() => {
  //   if (!preview && !loadingPreview && onScreen && post.previewImageExists != false) {
  //     post.content
  //     setLoadingPreview(true);
  //     setTimeout(() => dispatch(loadPostPreview({ ...post, ...accountOrServer })), 1);
  //   }
  // });

  // const authorId = post.author?.userId;
  // const authorName = post.author?.username;
  // const instances = media.instances;
  // const instance = instances[0];
  // const startsAtHeader = instances.length == 1 ? instance?.startsAt : undefined;
  // const endsAtHeader = instances.length == 1 ? instance?.endsAt : undefined;

  // const postLink = {};
  // useLink({
  //   href: groupContext
  //     ? `/g/${groupContext.shortname}/p/${post.id}`
  //     : `/post/${post.id}`,
  // });
  // const authorLink = useLink({
  //   href: authorName
  //     ? `/${authorName}`
  //     : `/user/${authorId}`
  // });

  // const maxContentHeight = isPreview ? horizontal ? 100 : 300 : undefined;
  // const postLinkProps = isPreview ? postLink : undefined;
  // const authorLinkProps = post.author ? authorLink : undefined;
  // const contentLengthShadowThreshold = horizontal ? 180 : 700;
  // const showDetailsShadow = isPreview && post.content && post.content.length > contentLengthShadowThreshold;
  // const detailsMargins = showDetailsShadow ? 20 : 0;
  // const footerProps = isPreview ? {
  // ml: -detailsMargins,
  //   mr: -detailsMargins,
  // } : {};
  // const contentProps = isPreview ? {
  // ml: detailsMargins,
  // mr: 2 * detailsMargins,
  // } : {};
  // const detailsProps = isPreview ? showDetailsShadow ? {
  //   ml: -detailsMargins,
  //   mr: -2 * detailsMargins,
  //   pr: 1 * detailsMargins,
  //   mb: -detailsMargins,
  //   pb: detailsMargins,
  //   shadowOpacity: 0.3,
  //   shadowOffset: { width: -5, height: -5 },
  //   shadowRadius: 10
  // } : {
  // mr: -20,
  // } : {
  // mr: -2 * detailsMargins,
  // };

  // const author = useTypedSelector((state: RootState) => authorId ? selectUserById(state.users, authorId) : undefined);
  // const authorAvatar = useTypedSelector((state: RootState) => authorId ? state.users.avatars[authorId] : undefined);
  // const authorLoadFailed = useTypedSelector((state: RootState) => authorId ? state.users.failedUserIds.includes(authorId) : false);

  // const [loadingAuthor, setLoadingAuthor] = useState(false);
  // useEffect(() => {
  //   if (authorId) {
  //     if (!loadingAuthor && (!author || authorAvatar == undefined) && !authorLoadFailed) {
  //       setLoadingAuthor(true);
  //       setTimeout(() => dispatch(loadUser({ id: authorId, ...accountOrServer })), 1);
  //     } else if (loadingAuthor && author) {
  //       setLoadingAuthor(false);
  //     }
  //   }
  // });

  return (
    <Theme inverse={false}>
      <Card theme="dark" elevate size="$4" bordered
        margin='$0'
        marginBottom='$3'
        marginTop='$3'
        padding='$0'
        // f={isPreview ? undefined : 1}
        animation="bouncy"
        // pressStyle={preview || post.replyToPostId ? { scale: 0.990 } : {}}
        ref={ref!}
      // {...postLinkProps}

      >
        <Card.Header>
          <YStack>
            <XStack>
              <View style={{ flex: 1 }}>

                <Heading size="$7" marginRight='auto'>{media.name}</Heading>

              </View>
            </XStack>
          </YStack>
        </Card.Header>
        <Card.Footer>

          {/* {...postLinkProps}> */}
          <YStack zi={1000} width='100%'>
            <YStack>
              <TamaguiMarkdown text={media.description} />
            </YStack>
          </YStack>
        </Card.Footer>
      </Card>
    </Theme>
  );
};
