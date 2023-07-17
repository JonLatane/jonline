import { loadUser, RootState, selectUserById, useCredentialDispatch, useServerTheme, useTypedSelector } from "app/store";
import React, { useEffect, useState } from "react";
import { Platform, View } from "react-native";
import { useIsVisible } from 'app/hooks/use_is_visible';

import { Event, EventInstance, Group } from "@jonline/api";
import { Anchor, Button, Card, Heading, Image, Paragraph, ScrollView, Theme, useMedia, XStack, YStack } from "@jonline/ui";
import { useMediaUrl } from "app/hooks/use_media_url";
import moment from "moment";
import { useLink } from "solito/link";
import { AuthorInfo } from "../post/author_info";
import { TamaguiMarkdown } from "../post/tamagui_markdown";
import { InstanceTime } from "./instance_time";
import { instanceTimeSort, isNotPastInstance, isPastInstance } from "app/utils/time";
import { History } from "@tamagui/lucide-icons";
import { GroupPostManager } from "../post/group_post_manager";

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

  const { server, primaryColor, navAnchorColor: navColor, backgroundColor: themeBgColor } = useServerTheme();
  const ref = React.useRef() as React.MutableRefObject<HTMLElement | View>;
  const onScreen = useIsVisible(ref);

  const authorId = post.author?.userId;
  const authorName = post.author?.username;
  const instances = event.instances;
  const instance = selectedInstance
    ? selectedInstance
    : instances.length === 1 ? instances[0] : undefined;

  const eventLink = useLink({
    href: instance
      ? groupContext
        ? `/g/${groupContext.shortname}/e/${event.id}/i/${instance!.id}`
        : `/event/${event.id}/i/${instance!.id}`
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
  const postLink = post.link ? useLink({ href: post.link }) : undefined;
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

  const [showPastInstances, setShowPastInstances] = useState(false);
  const displayedInstances = instances
    ? (showPastInstances
      ? [...instances]
      : instances
        .filter(isNotPastInstance)
    ).sort(instanceTimeSort)
    : undefined;
  const hasPastInstances = instances.find(isPastInstance) != undefined;
  const headerLinks = (post.link?.length ?? 0) > 0
    ? <>
      <YStack>
        <Anchor textDecorationLine='none' {...postLink}>
          <XStack>
            <YStack f={1}>
              <Heading size="$7" color={navColor} marginRight='auto'>{post.title}</Heading>
            </YStack>
          </XStack>
        </Anchor>
        {isPreview
          ? <Anchor textDecorationLine='none' {...detailsLink}>
            {instance ? <InstanceTime event={event} instance={instance} /> : undefined}
          </Anchor>
          : instance ? <InstanceTime event={event} instance={instance} /> : undefined}
      </YStack>
    </>
    : isPreview
      ? <Anchor textDecorationLine='none' {...detailsLink}>
        <YStack>
          <XStack>
            <YStack f={1}>
              <Heading size="$7" marginRight='auto'>{post.title}</Heading>
            </YStack>
          </XStack>
          {instance ? <InstanceTime event={event} instance={instance} /> : undefined}
        </YStack>
      </Anchor>
      : <YStack>
        <XStack>
          <YStack f={1}>
            <Heading size="$7" marginRight='auto'>{post.title}</Heading>
          </YStack>
        </XStack>
        {instance ? <InstanceTime event={event} instance={instance} /> : undefined}
      </YStack>;

  const contentView = post.content && post.content != ''
    ? isPreview
      ? <Anchor textDecorationLine='none' {...detailsLink}>
        <TamaguiMarkdown text={post.content} disableLinks={isPreview} />
      </Anchor>
      : <TamaguiMarkdown text={post.content} disableLinks={isPreview} />
    : undefined;
  return (
    <>
      <YStack w='100%'>
        {/* <Theme inverse={false}> */}
        <Card theme="dark" elevate size="$4" bordered
          margin='$0'
          marginBottom='$3'
          marginTop='$3'
          f={isPreview ? undefined : 1}
          // animation="bouncy"
          // pressStyle={previewUrl || post.replyToPostId ? { scale: 0.990 } : {}}
          ref={ref!}
          scale={1}
          opacity={1}
          y={0}
        // enterStyle={{ y: -50, opacity: 0, }}
        // exitStyle={{ opacity: 0, }}
        >
          {post.link || post.title
            ? <Card.Header>
              <YStack>
                {headerLinks}
                {/* <Anchor textDecorationLine='none' {...detailsLink}>
                  <YStack>
                    <XStack>
                      <YStack f={1}>
                        <Heading color={navColor} size="$7" marginRight='auto'>{post.title}</Heading>
                      </YStack>
                    </XStack>
                    {instance ? <InstanceTime event={event} instance={instance} /> : undefined}
                  </YStack>
                </Anchor> */}

                {!isPreview && instances.length > 1
                  ? <XStack w='100%' mt='$2' ml='$4' space>
                    {hasPastInstances
                      ? <Theme inverse={showPastInstances}>
                        <Button mt='$2' mr={-7} size='$3' circular icon={History}
                          // backgroundColor={showPastInstances ? undefined : navColor} 
                          onPress={() => setShowPastInstances(!showPastInstances)} />
                      </Theme>
                      : undefined}
                    <ScrollView f={1} horizontal pb='$3'>
                      <XStack mt='$1'>
                        {displayedInstances?.map((i) =>
                          <InstanceTime key={i.id} linkToInstance
                            event={event} instance={i}
                            highlight={i.id == instance?.id}
                          />)}
                      </XStack>

                    </ScrollView>
                  </XStack>
                  : undefined

                }
              </YStack>
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
                {contentView}
              </YStack>
              <XStack pt={10} ml='auto' mr={0}>
                <GroupPostManager post={post} onScreen={onScreen} />
              </XStack>
              <XStack {...detailsProps}>
                <AuthorInfo {...{ post, detailsMargins, onScreen }} />
                <Anchor textDecorationLine='none' {...{ ...(isPreview ? detailsLink : {}) }}>
                  <YStack h='100%' mr='$3'>
                    <Button opacity={isPreview ? 1 : 0.9} transparent={isPreview || !post?.replyToPostId || post.replyCount == 0}

                      disabled={true}
                      marginVertical='auto'
                      mr={media.gtXs || isPreview ? 0 : -10}
                      // onPress={toggleReplies} 
                      px='$2'
                    >
                      <XStack opacity={0.9}>
                        <YStack marginVertical='auto'>
                          {!post.replyToPostId ? <Heading size="$1" ta='right'>
                            {post.responseCount} comment{post.responseCount == 1 ? '' : 's'}
                          </Heading> : undefined}
                          {(post.replyToPostId) && (post.responseCount != post.replyCount) ? <Heading size="$1" ta='right'>
                            {post.responseCount} response{post.responseCount == 1 ? '' : 's'}
                          </Heading> : undefined}
                          {isPreview || post.replyCount == 0 ? undefined : <Heading size="$1" ta='right'>
                            {post.replyCount} repl{post.replyCount == 1 ? 'y' : 'ies'}
                          </Heading>}
                        </YStack>
                      </XStack>
                    </Button>
                  </YStack>
                </Anchor>
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
      {/* {
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
      } */}
    </>
  );
};

export default EventCard;
