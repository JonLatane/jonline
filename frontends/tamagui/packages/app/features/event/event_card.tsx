import { colorMeta, loadPostPreview, loadPostReplies, loadUser, RootState, selectUserById, useCredentialDispatch, useServerTheme, useTypedSelector } from "app/store";
import React, { useEffect, useState } from "react";
import { GestureResponderEvent, Platform, View } from "react-native";

import { Group, Event } from "@jonline/api";
import { Anchor, Button, Card, Heading, Image, Theme, useMedia, useTheme, XStack, YStack } from "@jonline/ui";
import { ChevronRight } from "@tamagui/lucide-icons";
import { useOnScreen } from "app/hooks/use_on_screen";
import { useLink } from "solito/link";
import { AuthorInfo } from "../post/author_info";
import { FadeInView } from "../post/fade_in_view";
import { TamaguiMarkdown } from "../post/tamagui_markdown";
import moment from "moment";

interface Props {
  event: Event;
  isPreview?: boolean;
  groupContext?: Group;
}

export const EventCard: React.FC<Props> = ({ event, isPreview, groupContext }) => {
  const { dispatch, accountOrServer } = useCredentialDispatch();
  const [loadingPreview, setLoadingPreview] = React.useState(false);
  const media = useMedia();
  const post = event.post!;

  const theme = useTheme();
  const textColor: string = theme.color.val;
  const themeBgColor = theme.background.val;
  const { luma: themeBgLuma } = colorMeta(themeBgColor);
  const { server, primaryColor, navAnchorColor: navColor } = useServerTheme();
  const postsStatus = useTypedSelector((state: RootState) => state.posts.status);
  // const postsBaseStatus = useTypedSelector((state: RootState) => state.posts.baseStatus);
  const preview: string | undefined = useTypedSelector((state: RootState) => state.posts.previews[post.id]);
  const ref = React.useRef() as React.MutableRefObject<HTMLElement | View>;
  // Call the hook passing in ref and root margin
  // In this case it would only be considered onScreen if more ...
  // ... than 300px of element is visible.
  const onScreen = useOnScreen(ref, "-1px");
  useEffect(() => {
    if (!preview && !loadingPreview && onScreen && post.previewImageExists != false) {
      post.content
      setLoadingPreview(true);
      setTimeout(() => dispatch(loadPostPreview({ ...post, ...accountOrServer })), 1);
    }
  });

  const authorId = post.author?.userId;
  const authorName = post.author?.username;
  const instances = event.instances;
  const instance = instances[0];
  const startsAtHeader = instances.length == 1 ? instance?.startsAt : undefined;
  const endsAtHeader = instances.length == 1 ? instance?.endsAt : undefined;

  const postLink = {};
  // useLink({
  //   href: groupContext
  //     ? `/g/${groupContext.shortname}/p/${post.id}`
  //     : `/post/${post.id}`,
  // });
  const authorLink = useLink({
    href: authorName
      ? `/${authorName}`
      : `/user/${authorId}`
  });
  const postLinkProps = isPreview ? postLink : undefined;
  const authorLinkProps = post.author ? authorLink : undefined;
  const showDetailsShadow = isPreview && post.content && post.content.length > 700;
  const detailsMargins = showDetailsShadow ? 20 : 0;
  const footerProps = isPreview ? {
    // ml: -detailsMargins,
    mr: -detailsMargins,
  } : {};
  const contentProps = isPreview ? {
    // ml: detailsMargins,
    // mr: 2 * detailsMargins,
  } : {};
  const detailsProps = isPreview ? showDetailsShadow ? {
    ml: -detailsMargins,
    mr: -2 * detailsMargins,
    pr: 1 * detailsMargins,
    mb: -detailsMargins,
    pb: detailsMargins,
    shadowOpacity: 0.3,
    shadowOffset: { width: -5, height: -5 },
    shadowRadius: 10
  } : {
    mr: -20,
  } : {
    // mr: -2 * detailsMargins,
  };

  const author = useTypedSelector((state: RootState) => authorId ? selectUserById(state.users, authorId) : undefined);
  const authorAvatar = useTypedSelector((state: RootState) => authorId ? state.users.avatars[authorId] : undefined);
  const authorLoadFailed = useTypedSelector((state: RootState) => authorId ? state.users.failedUserIds.includes(authorId) : false);

  const [loadingAuthor, setLoadingAuthor] = useState(false);
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

  function dateView(date: string) {
    return <YStack>
      <Heading size="$2" color={primaryColor} mr='$2'>
        {moment.utc(date).local().format('ddd, MMM Do YYYY')}
      </Heading>
      <Heading size="$4" color={primaryColor}>
        {moment.utc(date).local().format('h:mm a')}
      </Heading>
    </YStack>;
  }

  function dateRangeView(startsAt: string, endsAt: string) {
    const startsAtDate = moment.utc(startsAt).local().format('ddd, MMM Do YYYY');
    const endsAtDate = moment.utc(endsAt).local().format('ddd, MMM Do YYYY');
    if (startsAtDate == endsAtDate) {
      return <YStack>
        <Heading size="$4" color={primaryColor} mr='$2'>
          {moment.utc(startsAt).local().format('ddd, MMM Do YYYY')}
        </Heading>
        <XStack space>
          <Heading size="$3" color={primaryColor}>
            {moment.utc(startsAt).local().format('h:mm a')}
          </Heading>
          <Heading size="$3" color={primaryColor}>
            -
          </Heading>
          <Heading size="$3" color={primaryColor}>
            {moment.utc(endsAt).local().format('h:mm a')}
          </Heading>
        </XStack>
      </YStack>;
    } else {
      return <XStack>
        <View style={{ flex: 1 }}>
          {startsAt ? dateView(startsAt) : undefined}
        </View>
        <View style={{ flex: 1 }}>
          {endsAt ? dateView(endsAt) : undefined}
        </View>
      </XStack>;
    }
  }

  return (
    <>
      <YStack w='100%'>
        <Theme inverse={false}>
          <Card theme="dark" elevate size="$4" bordered
            margin='$0'
            marginBottom='$3'
            marginTop='$3'
            padding='$0'
            f={isPreview ? undefined : 1}
            animation="bouncy"
            pressStyle={preview || post.replyToPostId ? { scale: 0.990 } : {}}
            ref={ref!}
            {...postLinkProps}

          >
            {post.link || post.title
              ? <Card.Header>
                <YStack>
                  <XStack>
                    <View style={{ flex: 1 }}>
                      {post.link
                        ? isPreview
                          ? <Heading size="$7" marginRight='auto' color={navColor}>{post.title}</Heading>
                          : <Anchor href={post.link} onPress={(e) => e.stopPropagation()} target="_blank" rel='noopener noreferrer'
                            color={navColor}><Heading size="$7" marginRight='auto' color={navColor}>{post.title}</Heading></Anchor>
                        :
                        <Heading size="$7" marginRight='auto'>{post.title}</Heading>
                      }
                    </View>
                  </XStack>
                  {startsAtHeader && endsAtHeader ? dateRangeView(startsAtHeader, endsAtHeader) : undefined}
                </YStack>
              </Card.Header>
              : undefined}
            <Card.Footer paddingRight={media.gtXs ? '$3' : '$1'} >

              {/* {...postLinkProps}> */}
              <YStack zi={1000} width='100%' {...footerProps}>
                <YStack maxHeight={isPreview ? 300 : undefined} overflow='hidden' {...contentProps}>
                  {(!isPreview && preview && preview != '') ?
                    <Image
                      mb='$3'
                      width={media.sm ? 300 : 400}
                      height={media.sm ? 300 : 400}
                      resizeMode="contain"
                      als="center"
                      src={preview}
                      borderRadius={10}
                    /> : undefined}
                  {
                    post.content && post.content != '' ? Platform.select({
                      default: <TamaguiMarkdown text={post.content} disableLinks={isPreview} />,
                      // default: post.content ? <NativeMarkdownShim>{cleanedContent}</NativeMarkdownShim> : undefined
                      // default: <Heading size='$1'>Native Markdown support pending!</Heading>
                    }) : undefined
                  }
                </YStack>
                <XStack pt={10} {...detailsProps}>
                  <AuthorInfo {...{ post, isPreview, detailsMargins }} />
                </XStack>
              </YStack>
            </Card.Footer>
            <Card.Background>
              {(isPreview && preview && preview != '') ?
                <FadeInView>
                  <Image
                    pos="absolute"
                    width={300}
                    opacity={0.25}
                    height={300}
                    resizeMode="contain"
                    als="flex-start"
                    src={preview}
                    blurRadius={1.5}
                    // borderRadius={5}
                    borderBottomRightRadius={5}
                  />
                </FadeInView> : undefined}
            </Card.Background>
          </Card >
        </Theme>
      </YStack>
      {
        isPreview ?
          <Anchor {...authorLinkProps} onPress={(e) => e.stopPropagation()}>
            <XStack w={180} h={70}
              // backgroundColor='#42424277' 
              position='absolute' bottom={15} />
          </Anchor >
          : undefined}
      {
        isPreview && post.link ?
          <Anchor href={post.link} target='_blank'>
            <XStack w='100%' h={
              Math.max(1, (post.title?.length ?? 0) / Math.round(
                (media.xxxxxxs ? 15
                  : media.xxxxxs ? 20
                    : media.xxxxs ? 25
                      : media.xxxs ? 30
                        : media.xxs ? 35
                          : media.xs ? 40
                            : media.sm ? 45
                              : media.md ? 50
                                : media.lg ? 55
                                  : 70
                )
              )) * 36}
              // backgroundColor='#42424277' 
              position='absolute' top={15} />
          </Anchor>
          : undefined
      }
    </>
  );
};

export default EventCard;
