import { loadUser, RootState, selectUserById, useCredentialDispatch, useServerTheme, useTypedSelector } from "app/store";
import React, { useEffect, useState } from "react";
import { Platform, View } from "react-native";

import { Event, EventInstance, Group } from "@jonline/api";
import { Anchor, Card, Heading, Image, Paragraph, useMedia, XStack, YStack } from "@jonline/ui";
import { useMediaUrl } from "app/hooks/use_media_url";
import moment from "moment";
import { useLink } from "solito/link";
import { AuthorInfo } from "../post/author_info";
import { TamaguiMarkdown } from "../post/tamagui_markdown";
import { InstanceTime } from "./instance_time";

interface Props {
  event: Event;
  selectedInstance?: EventInstance;
  isPreview?: boolean;
  groupContext?: Group;
  horizontal?: boolean;
}

export const EventCard: React.FC<Props> = ({ event, selectedInstance, isPreview, groupContext, horizontal }) => {
  const { dispatch, accountOrServer } = useCredentialDispatch();
  const [loadingPreview, setLoadingPreview] = React.useState(false);
  const media = useMedia();
  const post = event.post!;

  // const theme = useTheme();
  // const textColor: string = theme.color.val;
  // const themeBgColor = theme.background.val;
  const { server, primaryColor, navAnchorColor: navColor, backgroundColor: themeBgColor } = useServerTheme();
  // const { luma: themeBgLuma } = colorMeta(themeBgColor);
  // const postsStatus = useTypedSelector((state: RootState) => state.posts.status);
  // const postsBaseStatus = useTypedSelector((state: RootState) => state.posts.baseStatus);
  // const preview: string | undefined = useTypedSelector((state: RootState) => state.posts.previews[post.id]);
  const ref = React.useRef() as React.MutableRefObject<HTMLElement | View>;
  // Call the hook passing in ref and root margin
  // In this case it would only be considered onScreen if more ...
  // ... than 300px of element is visible.
  // const onScreen = useOnScreen(ref, "-1px");
  // useEffect(() => {
  //   if( onScreen) {
  //     onOnScreen?.();
  //   }
  // }, [onScreen]);
  // useEffect(() => {
  //   if (!preview && !loadingPreview && onScreen && post.previewImageExists != false) {
  //     post.content
  //     setLoadingPreview(true);
  //     setTimeout(() => dispatch(loadPostPreview({ ...post, ...accountOrServer })), 1);
  //   }
  // });

  const authorId = post.author?.userId;
  const authorName = post.author?.username;
  const instances = event.instances;
  // const instance = instances[0];
  const instance = selectedInstance
    ? selectedInstance
    : instances.length === 1 ? instances[0] : undefined;
  // const [instance, setInstance] = useState<EventInstance | undefined>(undefined);
  // useEffect(() => {
  //   if (selectedInstance?.id != instance?.id)
  //   setInstance(selectedInstance ?? instances.length === 1 ? instances[0] : undefined);
  // }, [selectedInstance, instances]);
  console.log('EventCard.instance=', instance?.id, 'selectedInstance=', selectedInstance?.id, 'instances=', instances.length);

  const eventLink = useLink({
    href: instance
      ? groupContext
        ? `/g/${groupContext.shortname}/e/${event.id}/${instance!.id}`
        : `/event/${event.id}/${instance!.id}`
      : groupContext
        ? `/g/${groupContext.shortname}/e/${event.id}`
        : `/event/${event.id}`,
  });
  const authorLink = useLink({
    href: authorName
      ? `/${authorName}`
      : `/user/${authorId}`
  });

  const maxContentHeight = isPreview ? horizontal ? 100 : 300 : undefined;
  const detailsLink = isPreview ? eventLink : undefined;
  const authorLinkProps = post.author ? authorLink : undefined;
  const contentLengthShadowThreshold = horizontal ? 180 : 700;
  const showDetailsShadow = isPreview && post.content && post.content.length > contentLengthShadowThreshold;
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
  const previewUrl = useMediaUrl(post?.media[0]);

  const author = useTypedSelector((state: RootState) => authorId ? selectUserById(state.users, authorId) : undefined);
  // const authorAvatar = useTypedSelector((state: RootState) => authorId ? state.users.avatars[authorId] : undefined);
  const authorLoadFailed = useTypedSelector((state: RootState) => authorId ? state.users.failedUserIds.includes(authorId) : false);

  const [loadingAuthor, setLoadingAuthor] = useState(false);
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

  return (
    <>
      <YStack w='100%'>
        {/* <Theme inverse={false}> */}
        <Card theme="dark" elevate size="$4" bordered
          margin='$0'
          marginBottom='$3'
          marginTop='$3'
          f={isPreview ? undefined : 1}
          animation="bouncy"
          pressStyle={previewUrl || post.replyToPostId ? { scale: 0.990 } : {}}
          ref={ref!}
          scale={1}
          opacity={1}
          y={0}
        // enterStyle={{ y: -50, opacity: 0, }}
        // exitStyle={{ opacity: 0, }}
        >
          {post.link || post.title
            ? <Card.Header>
              <Anchor textDecorationLine='none' {...detailsLink}>
                <YStack>
                  <XStack>
                    <YStack f={1}>
                      <Heading color={navColor} size="$7" marginRight='auto'>{post.title}</Heading>
                      {/* {post.link
                        ? isPreview
                          ? <Heading size="$7" marginRight='auto' color={navColor}>{post.title}</Heading>
                          : <Anchor href={post.link} onPress={(e) => e.stopPropagation()} target="_blank" rel='noopener noreferrer'
                            color={navColor}><Heading size="$7" marginRight='auto' color={navColor}>{post.title}</Heading></Anchor>
                        :
                        <Heading size="$7" marginRight='auto'>{post.title}</Heading>
                      } */}
                    </YStack>
                  </XStack>
                  {instance ? <InstanceTime event={event} instance={instance} /> : undefined}
                </YStack>
              </Anchor>
            </Card.Header>
            : undefined}
          <Card.Footer p='$3' pr={media.gtXs ? '$3' : '$1'} >

            {/* {...postLinkProps}> */}
            <YStack zi={1000} width='100%' {...footerProps}>
              <YStack maxHeight={maxContentHeight} overflow='hidden' {...contentProps}>
                {(!isPreview && previewUrl && previewUrl != '') ?
                  <Image
                    mb='$3'
                    width={media.sm ? 300 : 400}
                    height={media.sm ? 300 : 400}
                    resizeMode="contain"
                    als="center"
                    source={{ uri: previewUrl }}
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
                <AuthorInfo {...{ post, detailsMargins }} />
              </XStack>
            </YStack>
          </Card.Footer>
          <Card.Background>
            {(isPreview && previewUrl && previewUrl != '') ?
              // <FadeInView>
              <Image
                pos="absolute"
                width={300}
                opacity={0.25}
                height={300}
                resizeMode="contain"
                als="flex-start"
                source={{ uri: previewUrl }}
                blurRadius={1.5}
                // borderRadius={5}
                borderBottomRightRadius={5}
              />
              // </FadeInView>
              : undefined}
          </Card.Background>
        </Card >
        {/* </Theme> */}
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
